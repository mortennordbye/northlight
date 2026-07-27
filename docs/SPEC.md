# Feature inventory — what a replacement theme must do

Source of truth: `blog/` at commit `0d44fb6e` (2026-07-27).
Previous theme pinned at `v2.104.0` (submodule `1f14448`), Hugo extended `0.161.1`.

The point of this document: everything below is *in use today*. Anything not listed is
machinery carried by the previous theme and not used.

## Scope: this is a public theme

The replacement is **open source, in its own repo, meant for other people to use** — not a
private layer for blog.nordbye.it. The feature set is driven by what this blog needs (the
inventory below), but the implementation has to survive being handed to a stranger.

What that changes:

- Behaviour comes from `site.Params` with sensible defaults. No `nordbye.it` values,
  giscus repo IDs, Cloudflare token, menu entries, or palette hardcoded in templates.
- Site-specific things stay in the *site's* config and in escape hatches
  (`extend-head.html`-style partial hooks), not in theme files.
- Needs the public-repo furniture: `theme.toml`, LICENCE, README with install +
  configuration reference, a working `exampleSite/`, screenshots, and a version tag.
- Config keys should be documented and stable — once someone else pins the theme, renaming
  a param is a breaking change.

What it does **not** change: the audit found two-thirds of the previous theme unused. The goal is a
small theme that is configurable where it matters, not another kitchen sink. Resist adding
a param for something neither you nor a plausible user needs; features earn their way in.

Practical consequence for build order: Tier 0 and Tier 1 below are unchanged, but every
hardcoded value you are tempted to write during them should become a param with a default
instead. Doing that as you go is cheap; retrofitting it across finished templates is not.

---

## 1. The environment the theme has to fit into

| Thing | Value | Consequence for the new theme |
|---|---|---|
| Hugo | extended 0.161.1 (`blog/Dockerfile`) | extended = SCSS/asset pipeline available. **Northlight requires 0.164.0**, so `blog/Dockerfile` needs the bump before the blog can adopt it. |
| Languages | `en` only, no translations | drop all i18n, `language-redirect`, hreflang |
| baseURL | `https://blog.nordbye.it/` | — |
| Build | `hugo --minify --gc`, alpine → nginx | theme must build with no network at build time |
| CI | `.github/workflows/build-blog.yaml`, `submodules: recursive` | if the theme moves to a Hugo Module instead of a submodule, this checkout step changes |
| Serving | nginx, pretty URLs, `error_page 404 /404.html` | `404.html` must exist at site root |
| Cache | `*.css`/`*.js` cached 1 year `immutable` | **asset fingerprinting is mandatory**, not optional |

`resources.Fingerprint` is currently sha512 and the nginx rule assumes a hash in the
filename. Keep fingerprinting or the year-long cache header becomes a bug.

---

## 2. Content shape — what the templates actually receive

Six posts, all page bundles: `content/blog/<slug>/{index.md, featured.png, source.svg}`.

Front matter keys used across all six — **this is the complete list**:

```
title, description, date, draft, tags
```

That is it. No `series`, no `authors`, no `featureimage`, no `externalUrl`, no
`showTableOfContents` overrides, no `weight`, no `categories`.

Section index pages (`content/{_index,series/_index,tags/_index}.md`) add:
`cascade.robots` / `robots` = `"noindex, follow"` on tags and series.

### Markdown features actually used

Used:

- Headings `#` through `####` (`tableOfContents` is `startLevel 2, endLevel 4`)
- Fenced code: `yaml` (36), `bash` (35), `text`, `nginx`, `hcl`, `dockerfile`, `alloy`
- Bullet lists, including nested
- Blockquotes — 2 total, plain, no GitHub `> [!NOTE]` alert syntax
- Inline links — 74 external `https://` links
- Raw HTML `<img src="/images/..." alt title style="width:70%" />` — 12 of them

Not used, at all:

- **Shortcodes — zero. Not one of the previous theme's ~45 shortcodes appears in any post.**
- Markdown images `![]()` — zero (every image is raw HTML)
- Tables, footnotes, task lists, mermaid, KaTeX/math, charts

> **Superseded for shortcodes, 2026-07-27.** The finding above is still accurate, and it was
> the reason this theme shipped none. It no longer decides the question. This is an audit of
> *one blog*, and Northlight is published for other people whose content is not that blog's —
> a shortcode surface is one of the things adopters compare on. `docs/EXPANSION-PLAN.md` holds
> the ordered list being built and, more usefully, the table of what is still deliberately
> absent and why. The audit's other findings stand unchanged.

The raw-HTML images mean `markup.goldmark.renderer.unsafe = true` must stay, and your
`prose` styles must not fight an inline `style="width:70%"`. It also means the
`render-image.html` hook is dead weight — nothing routes through it.

The math `passthrough` config in `markup.toml` is enabled but no post contains math.
Same for the `series` taxonomy: declared in `config.toml`, zero posts use it.

Post length: 1300–3600 words. Long enough that the TOC earns its place.

---

## 3. Routes the theme must produce

| Route | Template | Notes |
|---|---|---|
| `/` | `index.html` → `home/background.html` | background-image hero layout |
| `/blog/` | `_default/list.html` | paginated 10/page, cards, grouped by year |
| `/blog/<slug>/` | `_default/single.html` | the article page |
| `/tags/` | `_default/terms.html` | with term counts |
| `/tags/<tag>/` | `_default/term.html` | cards |
| `/series/`, `/series/<x>/` | same | configured, currently empty |
| `/404.html` | `404.html` | nginx depends on it |
| `/index.xml` | `rss.xml` | `outputs.home = [HTML, RSS, JSON]` |
| `/index.json` | `index.json` | **the search index** |
| `/sitemap.xml` | `sitemap.xml` | `excludedKinds = ["taxonomy", "term"]` |
| `/robots.txt` | built-in | `enableRobotsTXT = true` |

---

## 4. Features in use, by area

### Global

- `colorScheme = "github"` — one palette: neutral / primary / secondary as RGB triplets.
  You need **one** scheme file, not the 16 the previous theme ships.
- `defaultAppearance = "dark"` + `autoSwitchAppearance = true` — dark default, follows
  system preference, user toggle persisted. Needs the render-blocking inline script that
  sets `html.dark` before first paint, or you get a flash.
- `enableSearch = true` — Fuse.js over `/index.json`, search box in the header.
- `enableCodeCopy = true` — hover copy button on every code block.
- `highlight.noClasses = false` — **Chroma emits CSS classes, not inline styles.** You
  must ship a syntax-highlighting stylesheet with light *and* dark variants. This is the
  single most-underestimated item on the list.
- `mainSections = ["blog"]`
- `disableImageOptimization = false` — Hugo `.Resize` / `.Fill` / `.Crop` are in play
  (hero images, avatar).
- `smartTOC = true` + `smartTOCHideUnfocusedChildren = true` — scroll-spy TOC that
  highlights the current section and collapses siblings.
- `highlightCurrentMenuArea = true` — active state on the nav link for the current section.

### Header (`layout = "basic"`)

Static (not sticky/fixed), desktop menu + mobile hamburger, search input.
Menu from `menus.en.toml`: Blog (internal), Portfolio (external), GitHub (external).

### Homepage (`layout = "background"`)

Full-bleed `images/background.png` behind a two-layer gradient fade, circular avatar
(`images/profile.png`, cropped square then filled 288×288), name, headline, three social
icons (linkedin / github / generic link), then `content/_index.md` body, then
**recent articles: 5, list style (not cards), with a "More" link to `/blog`**.

`layoutBackgroundBlur = false` on the homepage — the blur-on-scroll JS is not needed here.

### Article page (`single.html`)

In render order:

1. Hero, `heroStyle = "basic"` — **already locally overridden**, see §5
2. Breadcrumbs
3. Title
4. Meta line: date, author, word count, reading time (reading time defaults on and is
   not disabled)
5. Sticky TOC in a left/right sidebar (`lg:` and up), collapses into the flow on mobile
6. Author card (name, image, headline, bio, links) above the content
7. Content, `layoutBackgroundBlur = true` — background blur active on article pages
8. Sharing links: **linkedin and reddit only**
9. Related content, limit 3
10. Prev/next pagination
11. Giscus comments

Also on: `showDraftLabel`, `showSummary`, `showTaxonomies`.
Off, and can be deleted outright: views, likes (Firebase), dateUpdated, edit link,
author badges.

### List page (`/blog`)

Hero with `heroStyle = "background"` + blur, no breadcrumbs, no summaries,
**cards + `groupByYear = true`**, 10 per page.

### Taxonomy pages

`/tags/`: term counts, background hero, text-style term links, no cards.
`/tags/<tag>/`: background hero, cards, TOC on.

### Footer

Menu (GitHub, LinkedIn), copyright, theme attribution, appearance switcher,
scroll-to-top button.

---

## 5. Local overrides — these port over unchanged

Three files in `blog/layouts/partials/`. They are yours already and are theme-agnostic
enough to lift straight into the new theme (or keep as site-level overrides):

- **`hero/basic.html`** — the important one. Replaces the previous theme's fixed-height
  `h-36/h-56/h-72` + `object-cover` band, which cropped the top and bottom off the
  1200×630 covers described in `blog/IMAGE-STYLE.md`. The override keeps
  `aspect-ratio: 1200 / 630` so covers render uncropped at every width.
  **Build this behaviour into the new theme from day one** rather than re-overriding it.
- **`comments.html`** — giscus, driven by `params.comments.giscus.*`.
- **`extend-head.html`** — Cloudflare Web Analytics beacon. Keep an `extend-head`-style
  escape hatch in the new theme so this stays a site file, not a theme edit.

---

## 6. What you can drop

Roughly two-thirds of the previous theme. Not used by a single page of this site:

All ~45 shortcodes · Firebase views/likes · multilingual + language-redirect + all i18n
files · KaTeX · Mermaid · Chart.js · gallery · carousel · TypeIt · zen mode · a11y module ·
RTL · authors data files and authors taxonomy · contributors · sponsors ·
buy-me-a-coffee · AdSense · GA / Fathom / Umami / Seline analytics · 15 of 16 colour
schemes · image zoom (medium-zoom, disabled) · edit-this-page link · `simple.html` ·
the four fixed header variants · the four other homepage layouts · the three other hero
styles · `render-image.html` (no markdown images) · series partials (until you use series).

---

## 7. Build order

### Tier 0 — the site renders and is deployable

1. `baseof.html` + `head.html`: title pattern `Page · Site`, meta description, canonical,
   OpenGraph, Twitter cards, favicons (`static/` already holds the full set + webmanifest),
   JSON-LD.
2. **Chroma stylesheet, light + dark.** Blocked on nothing, needed by every post, and the
   thing that will make a hand-rolled theme look unfinished if skipped.
3. Colour tokens + `html.dark` + the no-FOUC inline appearance script.
4. `page.html` — six posts; this is 90% of the site's value.
5. `section.html` for `/blog` with pagination.
6. `home.html` homepage.
7. `taxonomy.html` + `term.html` for `/tags`.
8. `404.html`, `rss.xml`, `sitemap.xml` (excluding taxonomy/term kinds), `index.json`.

At the end of Tier 0 the site is publishable. Everything below is polish you would miss.

### Tier 1 — feature parity with what you run today

Hero at 1200×630 aspect ratio · smart scroll-spy TOC · code-copy button · Fuse.js search ·
article meta line · breadcrumbs · related content · linkedin + reddit sharing ·
prev/next · appearance switcher · scroll-to-top · recent-articles block on the homepage ·
`extend-head` hook · giscus partial.

### Tier 2 — currently configured but unexercised; defer or delete

Series taxonomy · card views on list/term pages · `groupByYear` · draft labels ·
math passthrough.

---

## 8. Decisions to make before writing template one

- **Tailwind or hand-written CSS.** The previous theme is Tailwind 4 with a pre-compiled
  `main.css` and a `tailwind.config.js`; the Dockerfile's `npm install` step exists only
  for that. Hand-written CSS deletes the Node dependency from the build entirely — for a
  6-post single-author blog that is a real simplification, and it removes the
  no-native-node friction locally. Tailwind gets you further faster if you plan to iterate
  on layout a lot.
- **Distribution: git submodule vs Hugo Module.** Currently a submodule, and CI depends on
  `submodules: recursive`. A Hugo Module needs Go in the build image but gives you version
  pinning in `go.mod` and no submodule sharp edges.
- **Icons.** The previous theme inlines SVGs from `assets/icons/` through a partial. You need about
  a dozen: linkedin, github, link, reddit, sun, moon, search, bars (mobile menu),
  arrow-up, chevron-down, copy/check.
- **Render hooks to keep.** Heading anchors (the TOC links to them) and external-link
  handling (74 external links) are worth having. Image and blockquote hooks are not,
  given the content.

---

## 9. Known trap

`blog/Dockerfile` pulls `hugo_extended_..._linux-amd64`. Local builds under OrbStack on
Apple silicon fail on the x86 loader — verify with an arm64 Hugo + `gcompat` instead
(this is already recorded as a working note). Budget for it when you first build the new
theme locally.
