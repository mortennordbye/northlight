# Changelog

Notable changes to Northlight. The format follows [Keep a Changelog](https://keepachangelog.com/),
and versions follow [semantic versioning](https://semver.org/).

**Config keys are API.** A key is never renamed or repurposed without a major version bump. New
keys are added with defaults that preserve existing behaviour.

## [Unreleased]

### Added

- **`timeline` and `timelineItem`** — a vertical sequence of entries, taking `header` plus an
  optional `subheader`, `badge` and `icon`. The marker is a dot unless given an icon, because a
  column of identical icons carries no information. Pure CSS; the connecting line stops at the
  last entry rather than trailing off below it.
- **`accordion` and `accordionItem`** — collapsible panels built on `<details>`/`<summary>`, so
  opening, closing, keyboard operation and the accessibility tree all come from the element
  itself. **No JavaScript at all**, including for the single-open behaviour: `single="true"`
  emits a shared `name` attribute, which browsers make mutually exclusive natively, and one too
  old to support it simply allows several panels open.
- **`figure`** — an image with a caption and optionally a link. Goes through the same
  `_partials/img-attrs.html` the Markdown image render hook uses, so it gets the identical
  `srcset`, `sizes` and intrinsic dimensions, reserves its box before the bytes land, and picks
  up a `-dark` sibling in dark mode. Never cropped: only widths are generated, never a fixed
  box, so a cover with its title baked into the artwork survives. The Markdown render hook
  remains the documented default; this is for a figure that is also a link, or needs a class.
- **`alert`** — a callout box taking `type`, plus an optional `icon` and `title`. A thin wrapper
  over the admonition render hook's own CSS rather than a second callout style, so a callout
  written either way is the same box. It exists for the three things `> [!NOTE]` cannot express:
  a custom icon, a custom title, and a callout nested inside another shortcode. An unknown type
  fails the build rather than falling back to `note`, since a misspelled `warning` rendering as
  a neutral note is a callout quietly saying the wrong thing.
- **`list`** — embeds recent posts using the same row the post index uses, with `limit`, an
  optional `title`, and `where`/`value` to filter on a taxonomy term. Heading levels are chosen
  so the block nests where it lands: items are `h3`, or `h4` under a `title` that takes the
  `h3`. `where` and `value` each fail the build without the other, as does a filter that matches
  no posts, since an empty result is indistinguishable from having forgotten the shortcode.
- **`article`** — embeds one post as a card, given its `link`. Reuses `_partials/card.html`
  rather than growing a second card, so an embedded post and a listed one cannot drift apart:
  the cover at its exact aspect ratio, the draft label, the external-link treatment, the date
  and first tag all come along. A path that resolves to nothing fails the build, because the
  alternative is a card with no title linking nowhere, which reads as a styling bug rather than
  a broken reference.
- **`keyword` and `keywordList`** — a wrapping row of labelled pills, for a set of things listed
  together: the stack behind a project, the topics a post covers. `keyword` takes an optional
  `icon`. It shares a shape with `badge` on purpose, since both are small labels and a reader
  should not have to learn two visual languages for that, but a badge marks one thing inside a
  sentence where a keyword is one of a set. Inner text is required: an icon alone would be a pill
  whose meaning the reader has to guess, so omitting the label fails the build.
- **`icon`** — puts one of the theme's inline SVG icons into content, taking the name
  positionally. No size parameter and none needed: an icon is 1em square, so it takes the size
  of the text around it and its colour from `currentColor`. This makes the icon names a public
  surface, so renaming one is now a breaking change on the same footing as renaming a config
  key; the full set is listed on the Shortcodes page of the demo site. An unknown name fails
  the build rather than leaving a gap.
- **`ltr` and `rtl`** — mark a block as running in the other direction from the page around it,
  as the per-block counterpart to the site-wide `rtl` param. Both set a `dir` attribute rather
  than a CSS `direction` property: `dir` drives the bidirectional algorithm, alignment, list
  markers and punctuation placement together, and it keeps working in a reader-mode view or a
  feed reader that has dropped the stylesheet.
- **`swatches`** — a row of colour chips, each labelled with its own hex value, taking any
  number of colours positionally rather than the three the surveyed themes cap it at. The hex
  is rendered as text beside the chip rather than hidden in a `title`, because a bare block of
  colour carries its meaning in the colour alone and that is what a screen reader, a greyscale
  print and a colourblind reader all lose. A value that is not a hex colour fails the build
  rather than rendering a chip with no colour on a green build.
- **`email`** — a `mailto:` link with the address obfuscated at build time, taking `email` plus
  an optional `text` and `subject`. The obfuscation happens during the build rather than in the
  browser, so it survives with scripting off and does not break copy and paste, which is what
  the JavaScript and CSS-reversal alternatives each give up. The `href` is percent-encoded and
  the link text has its `@` and dots split by empty spans, because the minifier decodes numeric
  HTML entities in attributes and text alike and hands the address straight back. It stops naive
  harvesting and nothing more; anything that renders the page reads the address fine.
- **`button`** — a link styled as a call to action, taking `pageRef` for a page on this site or
  `href` for anything off it. It reuses the `.button` the 404 page and share row already use, so
  a button in content and a button in the chrome cannot drift apart. `target="_blank"` adds
  `rel="noopener"` on its own. An unresolvable `pageRef` fails the build rather than rendering a
  call to action that silently leads nowhere.
- **`badge`** — a small inline label for a status or a piece of metadata, taking the same shape
  as a tag without a tag's link behaviour. Brings `assets/css/shortcodes.css` into the bundle,
  concatenated after the component sheets and before a site's own `custom.css` so it stays
  overridable.
- **Shortcodes**, starting with `lead` — an introductory paragraph in larger, lighter type,
  reusing the same treatment a post's `description` already gets. This reverses an earlier
  decision to ship none: the audit behind the theme found the blog it replaces used no
  shortcodes, which is still true, but it stopped deciding the question once the theme was
  published for other people whose content is not that blog's. Render hooks over standard
  Markdown remain the documented default wherever both would work, because they keep content
  portable and shortcodes do not. Nothing here replaces a Markdown path. See
  `docs/EXPANSION-PLAN.md` for the ordered list and what was deliberately left out.
- **`make check-remote`** — the same gate as `make check` for a Docker daemon that cannot
  bind-mount the working directory, such as `DOCKER_HOST` pointing at another machine. Same
  pinned image, same flags, same suite; the source travels over the daemon socket instead.

### Fixed

- **A space appeared between a link and the punctuation after it.** Any sentence ending on a
  link rendered as `see the docs .` rather than `see the docs.` The link render hook emitted a
  trailing newline, and whitespace between inline elements collapses to a visible space. Present
  since the hook was written, and visible on the theme's own documentation.

## [0.2.0] — 2026-07-27

A minor rather than a patch: most of what follows is new surface. Every key added here has a
default that preserves the previous behaviour, so upgrading from 0.1.0 changes nothing until you
opt in.

### Added

- **Internationalisation.** Every user-facing string now comes from `i18n/en.toml`. There was no
  `i18n/` directory at all, so a non-English site could not use the theme without editing
  templates. Plurals are `one`/`other` rather than a conditional in a template. The handful of
  strings that only exist after a click are serialised into a JSON block that the scripts read,
  each with an English fallback.
- **Dark variants for prose images.** Drop `diagram-dark.png` beside `diagram.png` and it is used
  whenever the dark palette is active. Two `<img>` elements and CSS rather than `<picture>` with a
  `prefers-color-scheme` source, because a media query only knows what the operating system wants
  and this theme lets a reader override that.
- **Updated dates** via `article.showDateUpdated`, rendered only when `lastmod` is genuinely later
  than `date`.
- **Edit links** via `article.showEdit`, `editURL` and `editAppendPath`.
- **Nested menus.** One level, as a `<details>` disclosure rather than a hover dropdown.
- **Logos** via `logo` and optional `logoDark`, replacing the dot and the wordmark together.
- **`[params.verification]`** for Google, Bing, Pinterest, Yandex and `fediverse:creator`.
- **`BreadcrumbList` structured data** alongside the existing page schema.
- **`excludeFromSearch`** front matter, the search-index counterpart to `sitemap_exclude`.
- **`externalUrl`** front matter, so a listing entry can point off-site.
- **`dateFormat`** and **`rtl`** params.
- **A documentation site.** `exampleSite/content/docs/` is a full manual built by the theme
  itself, so every page demonstrates the feature it documents.
- **Admonitions.** Five callout types — note, tip, important, warning and caution — using
  GitHub's `> [!NOTE]` alert syntax rather than a shortcode, so the markdown renders as an
  ordinary blockquote anywhere else. Their colours sit outside the palette system, because a
  caution should read as a caution in every palette. Worst measured contrast is 5.06:1.
- **Image render hook.** Markdown images now carry intrinsic width and height, a `srcset` at
  480/720/1080/1440 capped at the original, `loading="lazy"` and `decoding="async"`. A markdown
  title becomes a caption. This closes a no-layout-shift gap: prose images previously shipped
  with no dimensions and reflowed the article as they loaded.
- **`assets/css/custom.css`.** A site can add its own stylesheet with no configuration. It is
  appended to the theme's bundle, so it is minified and fingerprinted with everything else and
  adds no request.
- **`_partials/extend-footer.html`.** The end-of-body twin of `extend-head.html`, for scripts
  that should not block the first paint.

- **Cloudflare Web Analytics**, via `params.analytics.cloudflare.token`. Chosen as the one
  directly-wired provider because it sets no cookies and needs no consent banner. Set no token and
  the theme still makes no third-party requests.

- **A test suite**, `tests/run.sh`, run by `make check` and by CI before deploying. POSIX `sh`
  and nothing else, so it adds no toolchain. It asserts what a green build does not: asset
  fingerprinting and integrity, feed and sitemap validity and scope, the never-cropped cover, both
  colour modes for every syntax and admonition colour, that every custom property and i18n key
  resolves, that no user-facing string is hardcoded, and that the script bundle declares no bare
  globals.

### Fixed

- **The home page's featured cover loaded without a priority hint.** It is the largest
  contentful paint element on the home page, and it queued behind the stylesheet and the fonts.
  It now carries `fetchpriority="high"`, matching what `cover.html` already did for the article
  hero. No visual change; measured LCP on the home page was 2.2s before.

- **The search button had no accessible name on a phone.** Below 720px both the visible label and
  the `⌘K` hint are `display:none`, leaving an icon-only control that a screen reader announced as
  just "button" on every page. It now carries an `aria-label` as well, matching the appearance
  toggle beside it. Found by the new Lighthouse audit, which scored accessibility at 0.92–0.95
  across every route because of it.
- **The post index skipped a heading level.** Post titles in a section listing were `h3` directly
  under the list's `h1`, with nothing at `h2` in between, because the year rule is deliberately a
  `div` rather than a heading. They are now `h2`. Purely semantic: `base.css` styles `h1`–`h6`
  identically and `.item-title` sets every visual property by class, so nothing moves.

- **Wide media no longer breaks the page.** An embedded `iframe` overflowed by 843px at a 375px
  viewport, so a pasted video embed broke the layout on a phone. `iframe`, `video`, `audio`,
  `embed` and `object` are now contained, with 16/9 assumed for frames and overridable inline.
- **The theme attribution rendered as escaped markup** once it moved into `i18n`, printing the
  anchor tag as text in the footer.
- **The header pushed the page sideways on a phone.** `.header-bar` is a fixed-height row that
  cannot shrink, so a site with more than three menu entries overflowed at 375px. It now wraps
  onto a second row below 720px, and the anchor offset grows to clear the taller bar.
- **The updated date could repeat the publication date.** The comparison was on timestamps, so a
  post published in the morning and corrected that afternoon rendered "27 Jul 2026 · Updated
  27 Jul 2026". It now compares the formatted dates, which is what the reader actually sees.
- **`--shadow-pop` did not exist**, so the nested menu panel rendered with no shadow. The token is
  `--shadow`.
- **The script bundle declared a bare `t` global.** A single-letter global from a theme is a
  collision risk for anything a site author loads. The shared lookup is now `window.Northlight.t`,
  with each module holding a local alias and its own fallback.
- **Section body copy had no paragraph spacing.** `.list-body` is not `.prose`, so the paragraph
  rules never reached it and multi-paragraph section descriptions ran together.

- **giscus now follows the site's appearance toggle**, not only the operating system. It renders
  in a cross-origin iframe, so the theme messages it on every mode change. Previously a reader who
  switched to dark on a light-mode machine got a bright comment box under a dark article. A source
  comment claimed this already worked; it did not.

### Changed

- `wrapStandAloneImageWithinParagraph = false` is documented as required config. Without it
  images still work; they just never get captions.
- The appearance toggle emits a `northlight:appearance` event, so anything that CSS cannot restyle
  can listen instead of being wired into the toggle itself.

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

### Also

- Field-weighted search ranking: a title match outranks a tag match outranks a summary mention,
  and a multi-word query narrows rather than widens. No search library.
- Draft labels, visible only when Hugo is run with `--buildDrafts`.
- Optional filename bar on a code fence via `{file="..."}`.
- The theme owns its OpenGraph and Twitter card partials rather than using Hugo's embedded ones,
  so tags render as written and both agree on which image a page has.

### Accessibility

- WCAG AA verified by measurement across three palettes, two modes and six page types: every
  text element meets its threshold, with translucent backgrounds composited before comparison.
- Skip link, visible focus on every interactive element, keyboard-reachable code blocks and
  tables.
- `prefers-reduced-motion` disables every transition and smooth scrolling.
- No horizontal scrolling at 1440, 1024, 768 or 375; code blocks and tables scroll inside
  themselves.

[Unreleased]: https://github.com/mortennordbye/northlight/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mortennordbye/northlight/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mortennordbye/northlight/releases/tag/v0.1.0
