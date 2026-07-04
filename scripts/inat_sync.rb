# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "yaml"
require "erb"
require "digest"
require "optparse"
require "time"
require "fileutils"

module InatSync
  ROOT = File.expand_path("..", __dir__)
  MANIFEST_PATH = File.join(ROOT, "_data", "inat_published.yml")
  POSTS_DIR = File.join(ROOT, "_posts")
  CONFIG_PATH = File.join(ROOT, "_config.yml")

  USER_AGENT = "matti.dad-inat-sync (https://matti.dad)"
  PER_PAGE = 200
  PAGE_SLEEP = 0.7
  ANTHROPIC_MODEL = "claude-haiku-4-5-20251001"

  POST_TEMPLATE = <<~ERB
    <%= front_matter %>
    <% if intro %>
    <%= intro %>
    <% end %>
    <% observations.each do |obs| %>

    ## <%= obs[:display_name] %>
    <% if obs[:scientific_name] %>
    *<%= obs[:scientific_name] %>*
    <% end %>
    <%= obs[:place_and_date] %>
    <% obs[:photo_urls].each do |url| %>
    ![<%= obs[:display_name] %>](<%= url %>)
    <% end %>
    <% if obs[:attribution] %>
    <small><%= obs[:attribution] %></small>
    <% end %>
    <% if obs[:description] && !obs[:description].empty? %>

    {% raw %}
    <%= obs[:description] %>
    {% endraw %}
    <% end %>

    [view on iNaturalist](<%= obs[:uri] %>)
    <% end %>
  ERB

  Options = Struct.new(:user, :dry_run, :backfill, :photo_size)

  module_function

  def run(argv)
    options = parse_options(argv)

    manifest = load_manifest
    max_id = manifest.empty? ? 0 : manifest.max

    observations = fetch_new_observations(options.user, max_id)
    new_observations = observations.reject { |obs| manifest.include?(obs["id"]) }

    if new_observations.empty?
      puts "nothing new"
      return 0
    end

    puts "new observations: #{new_observations.size}"

    groups = group_observations(new_observations, options)
    puts "groups: #{groups.size}"

    rendered = render_groups(groups, new_observations, options)

    if options.dry_run
      rendered.each do |post|
        puts "would write #{post[:filename]}"
        puts "  title: #{post[:title]}"
        puts "  ids: #{post[:ids].join(", ")}"
      end
      puts "dry run: no files written"
      return 0
    end

    rendered_ids = []
    rendered.each do |post|
      write_post(post)
      rendered_ids.concat(post[:ids])
      puts "wrote #{post[:filename]}"
    end

    save_manifest((manifest + rendered_ids).uniq.sort)
    puts "manifest updated: #{rendered_ids.size} ids appended"

    0
  end

  def parse_options(argv)
    options = Options.new(nil, false, false, "large")

    parser = OptionParser.new do |opts|
      opts.on("--user LOGIN") { |v| options.user = v }
      opts.on("--dry-run") { options.dry_run = true }
      opts.on("--backfill") { options.backfill = true }
      opts.on("--photo-size SIZE") { |v| options.photo_size = v }
    end
    parser.parse!(argv)

    options.user ||= config_inat_user

    if options.user.nil? || options.user.empty?
      warn "error: no --user given and no inat_user found in _config.yml"
      exit 1
    end

    options
  end

  def config_inat_user
    return nil unless File.exist?(CONFIG_PATH)

    config = YAML.load_file(CONFIG_PATH)
    config.is_a?(Hash) ? config["inat_user"] : nil
  end

  def load_manifest
    return [] unless File.exist?(MANIFEST_PATH)

    data = YAML.load_file(MANIFEST_PATH)
    return [] unless data.is_a?(Array)

    data.map(&:to_i)
  end

  def save_manifest(ids)
    FileUtils.mkdir_p(File.dirname(MANIFEST_PATH))
    File.write(MANIFEST_PATH, YAML.dump(ids))
  end

  def fetch_new_observations(user_login, start_id)
    results = []
    id_above = start_id

    loop do
      uri = URI("https://api.inaturalist.org/v1/observations")
      uri.query = URI.encode_www_form(
        user_login: user_login,
        per_page: PER_PAGE,
        order_by: "id",
        order: "asc",
        id_above: id_above
      )

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        warn "error: iNaturalist API request failed: #{response.code} #{response.message}"
        exit 1
      end

      page = JSON.parse(response.body)
      page_results = page["results"] || []
      results.concat(page_results)
      puts "fetched page: #{page_results.size} observations (id_above=#{id_above})"

      break if page_results.size < PER_PAGE

      id_above = page_results.map { |obs| obs["id"] }.max
      sleep PAGE_SLEEP
    end

    results
  end

  def group_observations(new_observations, options)
    use_llm = !options.backfill && ENV["ANTHROPIC_API_KEY"] && !ENV["ANTHROPIC_API_KEY"].empty?

    if use_llm
      groups = llm_group(new_observations)
      return groups if groups
      warn "warning: falling back to deterministic grouping"
    end

    deterministic_group(new_observations)
  end

  def deterministic_group(new_observations)
    new_observations.group_by { |obs| obs["observed_on"] }
                     .sort_by { |date, _| date.to_s }
                     .map do |date, obs_list|
      {
        "ids" => obs_list.map { |obs| obs["id"] },
        "title" => "observations — #{date || "undated"}",
        "intro" => nil
      }
    end
  end

  def llm_group(new_observations)
    compact = new_observations.map do |obs|
      {
        id: obs["id"],
        observed_on: obs["observed_on"],
        time_observed_at: obs["time_observed_at"],
        place_guess: obs["place_guess"],
        common_name: obs.dig("taxon", "preferred_common_name"),
        scientific_name: obs.dig("taxon", "name")
      }
    end

    system_prompt = <<~PROMPT
      You cluster iNaturalist observations into logical outings for a nature
      blog. Group by real observation date and place, NEVER by upload date.
      A single day's uploads may span multiple outings and should be split
      into separate groups when the place or time clearly differs. Give each
      group a short, evocative, lowercase title and a 1-2 sentence intro
      written in a field-notes, woodsy-terminal voice. The blog's tagline is
      "field notes from the woods and the terminal".
    PROMPT

    body = {
      model: ANTHROPIC_MODEL,
      max_tokens: 2048,
      system: system_prompt,
      messages: [
        { role: "user", content: JSON.generate(compact) }
      ],
      tools: [
        {
          name: "report_groups",
          input_schema: {
            type: "object",
            properties: {
              groups: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    ids: { type: "array", items: { type: "integer" } },
                    title: { type: "string" },
                    intro: { type: "string" }
                  },
                  required: %w[ids title intro]
                }
              }
            },
            required: ["groups"]
          }
        }
      ],
      tool_choice: { type: "tool", name: "report_groups" }
    }

    uri = URI("https://api.anthropic.com/v1/messages")
    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"
    request.body = JSON.generate(body)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

    unless response.is_a?(Net::HTTPSuccess)
      warn "warning: Anthropic API request failed: #{response.code} #{response.message}"
      return nil
    end

    parsed = JSON.parse(response.body)
    tool_use = parsed["content"]&.find { |block| block["type"] == "tool_use" }
    return nil unless tool_use

    groups = tool_use.dig("input", "groups")
    return nil unless groups.is_a?(Array)

    validate_groups(groups, new_observations.map { |obs| obs["id"] }) ? groups : nil
  rescue JSON::ParserError, StandardError => e
    warn "warning: LLM grouping failed: #{e.message}"
    nil
  end

  def validate_groups(groups, expected_ids)
    all_ids = groups.flat_map { |g| g["ids"] || [] }

    return false if all_ids.size != all_ids.uniq.size
    return false if all_ids.sort != expected_ids.sort

    true
  end

  def render_groups(groups, new_observations, options)
    by_id = new_observations.each_with_object({}) { |obs, h| h[obs["id"]] = obs }

    groups.map do |group|
      ids = group["ids"]
      obs_list = ids.map { |id| by_id.fetch(id) }
      render_post(group, obs_list, options)
    end
  end

  def render_post(group, obs_list, options)
    ids = group["ids"].sort
    first_obs = obs_list.first

    date = if options.backfill
             obs_list.map { |obs| obs["observed_on"] }.compact.min || Time.now.strftime("%Y-%m-%d")
           else
             Time.now.strftime("%Y-%m-%d")
           end

    slug_source = first_obs.dig("taxon", "preferred_common_name") ||
                  first_obs.dig("taxon", "name") ||
                  "observations"
    slug = slugify(slug_source)
    hash6 = Digest::SHA1.hexdigest(ids.join(","))[0, 6]
    filename = File.join(POSTS_DIR, "#{date}-inat-#{slug}-#{hash6}.md")

    hero_photo = photo_url(first_obs, options.photo_size)

    front_matter_hash = {
      "layout" => "post",
      "title" => group["title"],
      "date" => date,
      "tags" => ["inaturalist"],
      "hero_photo" => hero_photo,
      "inat_obs_count" => obs_list.size,
      "inat_obs_ids" => ids
    }
    front_matter = "#{YAML.dump(front_matter_hash)}---\n"

    rendered_observations = obs_list.map { |obs| observation_view(obs, options.photo_size) }

    content = ERB.new(POST_TEMPLATE, trim_mode: "-").result_with_hash(
      front_matter: front_matter,
      intro: group["intro"],
      observations: rendered_observations
    )

    { filename: filename, title: group["title"], ids: ids, content: content }
  end

  def observation_view(obs, photo_size)
    common_name = obs.dig("taxon", "preferred_common_name")
    scientific_name = obs.dig("taxon", "name")
    display_name = common_name || scientific_name || "unknown organism"

    place_and_date = [obs["place_guess"], obs["observed_on"]].compact.join(" — ")

    photos = obs["photos"] || []
    photo_urls = photos.map { |photo| photo["url"] && photo["url"].sub("square", photo_size) }.compact

    attribution = photos.map { |photo| photo["attribution"] }.compact.first

    {
      display_name: display_name,
      scientific_name: (scientific_name unless scientific_name == display_name),
      place_and_date: place_and_date,
      photo_urls: photo_urls,
      attribution: attribution,
      description: obs["description"],
      uri: obs["uri"]
    }
  end

  def photo_url(obs, photo_size)
    photos = obs["photos"] || []
    url = photos.first && photos.first["url"]
    url&.sub("square", photo_size)
  end

  def slugify(text)
    slug = text.downcase.gsub(/[^a-z0-9]+/, "-").squeeze("-").gsub(/\A-+|-+\z/, "")
    slug.empty? ? "observations" : slug
  end

  def write_post(post)
    FileUtils.mkdir_p(POSTS_DIR)
    File.write(post[:filename], post[:content])
  end
end

exit(InatSync.run(ARGV)) if __FILE__ == $PROGRAM_NAME
