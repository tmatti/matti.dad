# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`matti.dad` is a personal static site built with Jekyll.

## Commands

```bash
# Install dependencies
bundle install

# Serve locally with live reload
bundle exec jekyll serve --livereload

# Build for production
bundle exec jekyll build

# Run with drafts visible
bundle exec jekyll serve --drafts
```

## Runtime

Ruby version is pinned via `.mise.toml`. Run `mise install` after cloning.
