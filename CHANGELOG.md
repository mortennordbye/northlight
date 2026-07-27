# Changelog

Notable changes to Northlight. The format follows [Keep a Changelog](https://keepachangelog.com/),
and versions follow [semantic versioning](https://semver.org/).

**Config keys are API.** A key is never renamed or repurposed without a major version bump. New
keys are added with defaults that preserve existing behaviour.

## [0.1.0] — 2026-07-27

First release.

### Pages

- Article page: breadcrumbs, meta line, uncropped cover, prose, sticky table of contents, tags,
  sharing, older/newer navigation, related posts, comments hook.
- Home page: intro, byline, featured post, recent cards.
- Post index grouped by year, with pagination.
- Tag listing with counts, and per-tag pages.
- 404.

### Reading

- Two colour modes, designed separately rather than inverted, in three palettes: periwinkle,
  sage and clay.
- Syntax highlighting covering all 84 Chroma classes in both modes, every token measured at
  4.5:1 or better against the code background.
- Self-hosted Schibsted Grotesk and Spline Sans Mono with metric-matched fallbacks: zero layout
  shift when the webfonts arrive.
- Covers render in an exact 1200×630 box and are never cropped.

### Interaction

All of it optional, and all of it degrades — with JavaScript off the site stays readable, the
table of contents is a list of working links, and the colour mode follows the system.

- Appearance toggle, persisted, that hands control back to the system when the choice matches it.
- Copy button on code blocks.
- Scroll-spy table of contents.
- Reading-progress bar and back-to-top button.
- ⌘K search over a JSON index, keyboard navigable, no search library.

### Output and metadata

- RSS with full post content, a JSON search index, a sitemap that excludes taxonomy listings,
  and robots.txt carrying the sitemap URL.
- OpenGraph, Twitter cards, canonical URLs and JSON-LD.
- Favicons and the author avatar linked only when the files actually exist.

### Accessibility

- WCAG AA verified by measurement across three palettes, two modes and six page types: every
  text element meets its threshold, with translucent backgrounds composited before comparison.
- Skip link, visible focus on every interactive element, keyboard-reachable code blocks and
  tables.
- `prefers-reduced-motion` disables every transition and smooth scrolling.
- No horizontal scrolling at 1440, 1024, 768 or 375; code blocks and tables scroll inside
  themselves.

[0.1.0]: https://github.com/mortennordbye/northlight/releases/tag/v0.1.0
