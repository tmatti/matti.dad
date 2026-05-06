# Migration Plan: SCSS → Tailwind CSS v4

## Project context

`matti.dad` is a personal Jekyll blog at `/Users/tim/dev/github/tmatti/matti.dad`. It has a
woodsy-terminal aesthetic: JetBrains Mono font, OKLCH color palette (parchment light / deep loam
dark), sidebar nav layout, and a light/dark toggle stored in localStorage. The site was just
scaffolded and never published — there is no backwards-compatibility requirement.

**Goal:** Replace the entire `_sass/` directory and `assets/css/main.scss` with Tailwind CSS v4,
using its default conventions (utility-first markup, default spacing/type scale, `@theme` for brand
colors). Visual result should look roughly the same.

---

## Step 0 — Delete the old CSS

Remove these paths entirely before creating any new files:

```
_sass/          (whole directory)
_site/          (build artifact)
.jekyll-cache/  (build artifact)
assets/css/main.scss
```

---

## Step 1 — Create `package.json`

Create `/Users/tim/dev/github/tmatti/matti.dad/package.json`:

```json
{
  "private": true,
  "scripts": {
    "css:watch": "tailwindcss -i src/input.css -o assets/css/main.css --watch",
    "css:build": "tailwindcss -i src/input.css -o assets/css/main.css --minify",
    "dev": "concurrently -k -n css,jekyll -c green,blue \"npm:css:watch\" \"bundle exec jekyll serve --livereload\"",
    "build": "npm run css:build && bundle exec jekyll build"
  },
  "devDependencies": {
    "@tailwindcss/cli": "^4.1.0",
    "@tailwindcss/typography": "^0.5.16",
    "concurrently": "^9.1.0",
    "tailwindcss": "^4.1.0"
  }
}
```

Then run: `npm install`

---

## Step 2 — Create `src/input.css`

Create `/Users/tim/dev/github/tmatti/matti.dad/src/input.css`:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@source "../_layouts/**/*.html";
@source "../_includes/**/*.html";
@source "../*.{html,md}";
@source "../_posts/**/*.md";

/* ── Brand tokens ────────────────────────────────────────────────────────── */
@theme {
  --color-bg:      oklch(97% 0.012 95);
  --color-surface: oklch(94% 0.016 95);
  --color-ink:     oklch(22% 0.020 60);
  --color-muted:   oklch(48% 0.018 60);
  --color-rule:    oklch(86% 0.014 95);
  --color-accent:  oklch(42% 0.085 145);
  --color-warm:    oklch(50% 0.090 55);

  --font-mono: "JetBrains Mono", ui-monospace, "Cascadia Code", monospace;
}

/* Dark mode — override custom props; no dark: prefixes needed in markup */
[data-theme="dark"] {
  --color-bg:      oklch(18% 0.012 60);
  --color-surface: oklch(22% 0.016 60);
  --color-ink:     oklch(92% 0.012 95);
  --color-muted:   oklch(66% 0.018 95);
  --color-rule:    oklch(30% 0.014 60);
  --color-accent:  oklch(72% 0.10 145);
  --color-warm:    oklch(74% 0.10 60);
}

/* ── Base layer ──────────────────────────────────────────────────────────── */
@layer base {
  html {
    background-color: var(--color-bg);
    color: var(--color-ink);
    font-family: var(--font-mono);
    font-feature-settings: "liga" 1, "calt" 1, "ss01" 1;
  }

  ::selection {
    background: color-mix(in oklch, var(--color-accent) 25%, transparent);
  }
}

/* ── Typography plugin theme ─────────────────────────────────────────────── */
@layer components {
  .prose {
    --tw-prose-body:         var(--color-ink);
    --tw-prose-headings:     var(--color-ink);
    --tw-prose-lead:         var(--color-muted);
    --tw-prose-links:        var(--color-accent);
    --tw-prose-bold:         var(--color-ink);
    --tw-prose-counters:     var(--color-muted);
    --tw-prose-bullets:      var(--color-rule);
    --tw-prose-hr:           var(--color-rule);
    --tw-prose-quotes:       var(--color-muted);
    --tw-prose-quote-borders:var(--color-rule);
    --tw-prose-captions:     var(--color-muted);
    --tw-prose-code:         var(--color-ink);
    --tw-prose-pre-code:     var(--color-ink);
    --tw-prose-pre-bg:       var(--color-surface);
    --tw-prose-th-borders:   var(--color-rule);
    --tw-prose-td-borders:   var(--color-rule);
  }
}

/* ── Rouge syntax highlighting ───────────────────────────────────────────── */
/* Rouge injects class-based selectors; these can't be replaced with utilities */
@layer components {
  .highlight,
  .highlighter-rouge { background: var(--color-surface); border-radius: 0.25rem; }

  .highlight .c,  .highlight .cm, .highlight .c1,
  .highlight .cs  { color: var(--color-muted); font-style: italic; }

  .highlight .k,  .highlight .kd, .highlight .kn, .highlight .kp,
  .highlight .kr, .highlight .kt { color: var(--color-accent); font-weight: 500; }

  .highlight .s,  .highlight .sb, .highlight .sc, .highlight .sd,
  .highlight .s2, .highlight .sh, .highlight .si, .highlight .sx,
  .highlight .sr, .highlight .s1, .highlight .ss { color: var(--color-warm); }

  .highlight .m,  .highlight .mf, .highlight .mh,
  .highlight .mi, .highlight .mo { color: oklch(58% 0.09 80); }

  .highlight .nv, .highlight .vc, .highlight .vg,
  .highlight .vi  { color: oklch(55% 0.08 130); }

  .highlight .o,  .highlight .ow { color: var(--color-muted); }
  .highlight .p   { color: var(--color-ink); }

  .highlight .n,  .highlight .na, .highlight .nb, .highlight .nc,
  .highlight .nd, .highlight .ne, .highlight .nf, .highlight .ni,
  .highlight .nl, .highlight .nn, .highlight .nx { color: var(--color-ink); }

  .highlight .nt  { color: var(--color-accent); }
  .highlight .bp  { color: var(--color-muted); }
  .highlight .err { color: oklch(55% 0.12 25); }
  .highlight .gd  { color: oklch(55% 0.12 25); }
  .highlight .gi  { color: var(--color-accent); }
  .highlight .ge  { font-style: italic; }
  .highlight .gs  { font-weight: 700; }
}
```

---

## Step 3 — Create `bin/dev`

Create `/Users/tim/dev/github/tmatti/matti.dad/bin/dev`:

```sh
#!/usr/bin/env sh
exec npm run dev
```

Make it executable: `chmod +x bin/dev`

---

## Step 4 — Create `.gitignore`

Create `/Users/tim/dev/github/tmatti/matti.dad/.gitignore`:

```
node_modules/
_site/
.jekyll-cache/
assets/css/main.css
```

---

## Step 5 — Update `_config.yml`

The `sass:` block is no longer needed. Update the file to:

```yaml
title: matti.dad
tagline: "field notes from the woods and the terminal"
description: "A blog by Tim Matti — Ruby, Rails, AI, bowhunting, archery, and being a dad in the woods."
url: "https://matti.dad"
baseurl: ""

author:
  name: Tim Matti
  email: tmatti56@gmail.com
  github: tmatti

permalink: /:year/:month/:slug/

plugins:
  - jekyll-feed
  - jekyll-seo-tag

markdown: kramdown
kramdown:
  input: GFM
  syntax_highlighter: rouge
  syntax_highlighter_opts:
    block:
      line_numbers: false

exclude:
  - Gemfile
  - Gemfile.lock
  - CLAUDE.md
  - AGENTS.md
  - README.md
  - .mise.toml
  - .ruby-lsp/
  - .claude/
  - node_modules/
  - package.json
  - package-lock.json
  - src/
  - bin/
```

---

## Step 6 — Rewrite all templates

### `_includes/head.html` — NO CHANGES NEEDED

The file already loads `/assets/css/main.css` which is where Tailwind outputs. Leave it exactly as-is.

---

### `assets/js/theme.js` — NO CHANGES NEEDED

The JS toggles `data-theme` on `<html>` and `is-open`/`is-visible` classes on the sidebar/overlay.
These are all still used. Leave it exactly as-is.

---

### `_layouts/default.html`

Full rewrite. Key decisions:
- Site wrapper uses `lg:grid lg:grid-cols-[260px_1fr]` — sidebar appears at 1024px (Tailwind default `lg:`).
- Topbar (mobile brand + menu button) is `lg:hidden`.
- Sidebar defaults to a fixed off-canvas drawer; at `lg:` it becomes sticky in the grid column.
- The `[&.is-open]:translate-x-0` arbitrary variant reacts to JS adding the `is-open` class.

```html
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  {% include head.html %}
</head>
<body class="font-mono antialiased">
  <div id="site" class="min-h-dvh lg:grid lg:grid-cols-[260px_1fr]">

    <!-- Mobile topbar -->
    <header class="sticky top-0 z-[100] flex h-12 items-center justify-between border-b border-rule bg-bg px-6 lg:hidden">
      <a href="{{ '/' | relative_url }}" class="text-sm font-bold tracking-tight text-ink no-underline hover:text-accent">~/matti.dad</a>
      <button id="menu-toggle"
              class="cursor-pointer border-0 bg-transparent px-3 py-2 font-mono text-xs font-medium text-muted hover:text-ink"
              aria-label="Toggle navigation" aria-expanded="false" aria-controls="sidebar">
        [ menu ]
      </button>
    </header>

    <!-- Sidebar: off-canvas on mobile, sticky column on desktop -->
    <aside id="sidebar"
           class="fixed top-0 bottom-0 left-0 z-[200] w-[min(260px,85vw)] -translate-x-full overflow-y-auto border-r border-rule bg-bg transition-transform duration-200 [&.is-open]:translate-x-0 lg:sticky lg:bottom-auto lg:z-auto lg:h-dvh lg:w-auto lg:translate-x-0 lg:transition-none"
           aria-label="Site navigation">
      {% include sidebar.html %}
    </aside>

    <!-- Mobile overlay -->
    <div id="sidebar-overlay"
         class="fixed inset-0 z-[150] hidden bg-black/50 [&.is-visible]:block"
         aria-hidden="true"></div>

    <!-- Main content -->
    <main id="main" class="min-w-0 px-8 py-12 lg:max-w-[820px] lg:px-12 lg:py-16">
      {{ content }}
    </main>

  </div>
  <script src="{{ '/assets/js/theme.js' | relative_url }}"></script>
</body>
</html>
```

---

### `_layouts/page.html`

```html
---
layout: default
---
<article>
  <header class="mb-12">
    <h1 class="text-3xl font-bold leading-tight tracking-tight text-ink">{{ page.title }}</h1>
    {% if page.subtitle %}<p class="mt-3 text-sm text-muted">{{ page.subtitle }}</p>{% endif %}
  </header>
  <div class="prose">
    {{ content }}
  </div>
</article>
```

---

### `_layouts/post.html`

```html
---
layout: default
---
<article>
  <header class="mb-12">
    <div class="mb-4 flex flex-wrap items-center gap-3">
      <time class="text-xs font-medium text-muted" datetime="{{ page.date | date_to_xmlschema }}">{{ page.date | date: "%Y-%m-%d" }}</time>
      {% if page.tags.size > 0 %}
        <span class="flex flex-wrap gap-1">
          {% for tag in page.tags %}{% include tag-chip.html tag=tag %}{% endfor %}
        </span>
      {% endif %}
    </div>
    <h1 class="text-3xl font-bold leading-tight tracking-tight text-ink">{{ page.title }}</h1>
  </header>

  <div class="prose">
    {{ content }}
  </div>

  <footer class="mt-16 border-t border-rule pt-8">
    <nav class="flex gap-8" aria-label="Post navigation">
      {% if page.previous %}
        <a href="{{ page.previous.url | relative_url }}" class="group flex max-w-[45%] flex-col gap-1 no-underline">
          <span class="text-xs font-medium text-muted">← prev</span>
          <span class="text-sm font-medium text-ink transition-colors group-hover:text-accent">{{ page.previous.title }}</span>
        </a>
      {% endif %}
      {% if page.next %}
        <a href="{{ page.next.url | relative_url }}" class="group ml-auto flex max-w-[45%] flex-col gap-1 text-right no-underline">
          <span class="text-xs font-medium text-muted">next →</span>
          <span class="text-sm font-medium text-ink transition-colors group-hover:text-accent">{{ page.next.title }}</span>
        </a>
      {% endif %}
    </nav>
  </footer>
</article>
```

---

### `_includes/sidebar.html`

Active state: Liquid appends ` active` to the class string when the link is current. The
`[&.active]:text-accent` arbitrary variant reacts to that class. Same for the `$` prompt via
`[.active_&]:text-accent` (matches when an ancestor has `.active`).

```html
<div class="flex h-full flex-col gap-12 p-8">

  <div>
    <a href="{{ '/' | relative_url }}" class="text-sm font-bold tracking-tight text-ink no-underline hover:text-accent">~/matti.dad</a>
  </div>

  <nav aria-label="Main navigation">
    <ul class="flex flex-col gap-2">
      <li>
        <a href="{{ '/about/' | relative_url }}"
           class="flex items-center gap-2 py-1 text-sm font-medium no-underline transition-colors text-muted hover:text-ink [&.active]:text-accent{% if page.url contains '/about' %} active{% endif %}">
          <span class="w-3 shrink-0 select-none text-rule transition-colors [.active_&]:text-accent" aria-hidden="true">$</span> about
        </a>
      </li>
      <li>
        <a href="{{ '/' | relative_url }}"
           class="flex items-center gap-2 py-1 text-sm font-medium no-underline transition-colors text-muted hover:text-ink [&.active]:text-accent{% if page.url == '/' or page.layout == 'post' %} active{% endif %}">
          <span class="w-3 shrink-0 select-none text-rule transition-colors [.active_&]:text-accent" aria-hidden="true">$</span> blog
        </a>
      </li>
      <li>
        <a href="{{ '/tools/' | relative_url }}"
           class="flex items-center gap-2 py-1 text-sm font-medium no-underline transition-colors text-muted hover:text-ink [&.active]:text-accent{% if page.url contains '/tools' %} active{% endif %}">
          <span class="w-3 shrink-0 select-none text-rule transition-colors [.active_&]:text-accent" aria-hidden="true">$</span> tools
        </a>
      </li>
      <li>
        <a href="{{ '/now/' | relative_url }}"
           class="flex items-center gap-2 py-1 text-sm font-medium no-underline transition-colors text-muted hover:text-ink [&.active]:text-accent{% if page.url contains '/now' %} active{% endif %}">
          <span class="w-3 shrink-0 select-none text-rule transition-colors [.active_&]:text-accent" aria-hidden="true">$</span> now
        </a>
      </li>
      <li>
        <a href="{{ '/tags/' | relative_url }}"
           class="flex items-center gap-2 py-1 text-sm font-medium no-underline transition-colors text-muted hover:text-ink [&.active]:text-accent{% if page.url contains '/tags' %} active{% endif %}">
          <span class="w-3 shrink-0 select-none text-rule transition-colors [.active_&]:text-accent" aria-hidden="true">$</span> tags
        </a>
      </li>
    </ul>
  </nav>

  <div class="mt-auto flex flex-col gap-4">
    <div class="flex gap-4">
      <a href="{{ site.feed.path | default: '/feed.xml' | prepend: site.baseurl }}" class="text-xs font-medium text-muted no-underline transition-colors hover:text-accent">rss</a>
      {% if site.author.github %}
        <a href="https://github.com/{{ site.author.github }}" class="text-xs font-medium text-muted no-underline transition-colors hover:text-accent" target="_blank" rel="noopener noreferrer">github</a>
      {% endif %}
      {% if site.author.email %}
        <a href="mailto:{{ site.author.email }}" class="text-xs font-medium text-muted no-underline transition-colors hover:text-accent">email</a>
      {% endif %}
    </div>
    {% include theme-toggle.html %}
  </div>

</div>
```

---

### `_includes/theme-toggle.html`

The `[` and `]` brackets come from `before:`/`after:` pseudo-elements. The `aria-pressed:` variant
is built into Tailwind v4.

```html
<div class="flex items-center text-xs before:mr-[0.15em] before:text-rule before:content-['['] after:ml-[0.15em] after:text-rule after:content-[']']"
     role="group" aria-label="Color theme">
  <button data-theme-value="light"
          class="cursor-pointer border-0 bg-transparent px-[0.15em] font-mono text-xs font-medium text-muted transition-colors hover:text-ink aria-pressed:text-accent aria-pressed:underline aria-pressed:underline-offset-[3px] aria-pressed:decoration-accent"
          aria-pressed="false">light</button>
  <span class="select-none text-xs text-rule" aria-hidden="true">|</span>
  <button data-theme-value="dark"
          class="cursor-pointer border-0 bg-transparent px-[0.15em] font-mono text-xs font-medium text-muted transition-colors hover:text-ink aria-pressed:text-accent aria-pressed:underline aria-pressed:underline-offset-[3px] aria-pressed:decoration-accent"
          aria-pressed="false">dark</button>
</div>
```

---

### `_includes/post-list.html`

The `$` prefix is a `before:` pseudo-element on the meta row. The title indents `pl-6` (1.5rem)
to visually align under the date text that follows the `$`.

```html
{% assign posts = include.posts | default: site.posts %}
<ol class="flex flex-col gap-6" reversed>
  {% for post in posts %}
  <li class="flex flex-col gap-1">
    <div class="flex flex-wrap items-center gap-3 before:select-none before:text-xs before:font-medium before:text-rule before:content-['$']">
      <time class="text-xs font-medium text-muted" datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y-%m-%d" }}</time>
      {% if post.tags.size > 0 %}
        <span class="flex flex-wrap gap-1">
          {% for tag in post.tags %}{% include tag-chip.html tag=tag %}{% endfor %}
        </span>
      {% endif %}
    </div>
    <a href="{{ post.url | relative_url }}" class="pl-6 text-base font-medium text-ink no-underline transition-colors hover:text-accent">{{ post.title }}</a>
  </li>
  {% endfor %}
</ol>
```

---

### `_includes/tag-chip.html`

```html
<a href="{{ '/tags/' | relative_url }}#{{ include.tag | slugify }}" class="inline-block rounded-sm border border-rule px-1.5 py-px text-xs font-normal text-muted no-underline transition-colors hover:border-accent hover:text-accent">{{ include.tag }}</a>
```

---

### `index.html`

```html
---
layout: default
title: matti.dad
---
<div class="mb-16">
  <h1 class="mb-4 text-3xl font-bold leading-tight tracking-tight text-ink">field notes.</h1>
  <p class="max-w-[52ch] text-base leading-loose text-muted">From the woods and the terminal — Ruby, Rails, AI, bowhunting, archery, and being a dad.</p>
</div>
<hr class="mb-12 border-rule">
{% include post-list.html %}
```

---

### `tags.html`

```html
---
layout: default
title: tags
permalink: /tags/
---
<div class="mb-12">
  <h1 class="text-3xl font-bold leading-tight tracking-tight text-ink">tags</h1>
</div>

{% assign sorted_tags = site.tags | sort %}
{% for tag in sorted_tags %}
  {% assign tag_name = tag[0] %}
  {% assign tag_posts = tag[1] %}
  <section class="mb-16" id="{{ tag_name | slugify }}">
    <h2 class="mb-6 flex items-center gap-3 text-base font-bold">
      {% include tag-chip.html tag=tag_name %}
      <span class="text-sm font-normal text-muted">({{ tag_posts.size }})</span>
    </h2>
    <ol class="flex flex-col gap-6" reversed>
      {% for post in tag_posts %}
      <li class="flex flex-col gap-1">
        <div class="flex flex-wrap items-center gap-3 before:select-none before:text-xs before:font-medium before:text-rule before:content-['$']">
          <time class="text-xs font-medium text-muted" datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y-%m-%d" }}</time>
        </div>
        <a href="{{ post.url | relative_url }}" class="pl-6 text-base font-medium text-ink no-underline transition-colors hover:text-accent">{{ post.title }}</a>
      </li>
      {% endfor %}
    </ol>
  </section>
{% endfor %}
```

---

### `404.html`

```html
---
layout: default
title: "404 — lost in the woods"
permalink: /404.html
---
<div class="mb-12">
  <h1 class="text-3xl font-bold leading-tight tracking-tight text-ink">404</h1>
  <p class="mt-3 text-sm text-muted">you wandered off the trail.</p>
</div>
<div class="prose">
  <p>The page you're looking for doesn't exist here.</p>
  <p><a href="{{ '/' | relative_url }}">← back to camp</a></p>
</div>
```

---

### Content pages — NO CHANGES NEEDED

`about.md`, `tools.md`, `now.md`, and `_posts/2026-05-03-hello.md` are unchanged. They use the
`page` or `post` layout which wraps content in `<div class="prose">`. The typography plugin styles
the markdown output inside that wrapper.

---

## Step 7 — Build and verify

```bash
# 1. Build the CSS
npm run css:build

# 2. Build Jekyll
bundle exec jekyll build

# 3. Serve for visual inspection
npm run dev
# Visit http://localhost:4000
```

Check each route:
- `/` — home feed with `$` prefixed rows and tag chips
- `/about/` — prose page
- `/2026/05/hello/` — post with header, prose body, prev/next nav
- `/tags/` — tags index grouped by tag
- `/feed.xml` — resolves (jekyll-feed)
- `/404.html` — resolves

Check both themes:
- Click `[ light | dark ]` toggle — swaps instantly
- Reload page — theme persists from localStorage
- On a fresh browser (no localStorage) — follows system preference

Check mobile (resize to 600px wide):
- Topbar visible, sidebar hidden
- `[ menu ]` button opens drawer, overlay dims content
- Clicking a nav link or the overlay closes drawer

---

## What changed vs. the SCSS version

| Thing | SCSS version | Tailwind version |
|---|---|---|
| Sidebar breakpoint | 900px | 1024px (Tailwind `lg:`) |
| Heading sizes | custom scale (2rem, 1.5rem…) | Tailwind defaults (~1.875rem, 1.5rem…) — slightly smaller |
| Prose styles | custom `.prose` in `_typography.scss` | `@tailwindcss/typography` plugin with color overrides |
| Spacing | custom semantic names (`--space-md`) | Tailwind default numbers (`p-4`, `gap-3`) |
| Colors | identical OKLCH values | identical OKLCH values (only things kept exactly) |
| Font | JetBrains Mono | JetBrains Mono (kept) |
| Dark mode | CSS var override at `[data-theme=dark]` | same — no `dark:` prefixes needed |
| Build | `bundle exec jekyll serve` | `npm run dev` (runs Tailwind watch + Jekyll concurrently) |
