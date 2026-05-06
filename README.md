# matti.dad

Personal site. Built with Jekyll.

## Setup

Requires Ruby 4.0.1 (pinned via `.mise.toml`).

```bash
mise install       # install pinned Ruby version
bundle install     # install gem dependencies
```

## Running locally

```bash
bundle exec jekyll serve --livereload
```

Open `http://localhost:4000`. The site rebuilds automatically on file changes.

To preview drafts:

```bash
bundle exec jekyll serve --livereload --drafts
```

## Building

```bash
bundle exec jekyll build
```

Output goes to `_site/`.

## Writing posts

Add a file to `_posts/` with the format `YYYY-MM-DD-slug.md` and the following front matter:

```yaml
---
layout: post
title: "Post title"
date: YYYY-MM-DD
tags: [tag1, tag2]
---
```

Drafts go in `_drafts/` without a date prefix.
