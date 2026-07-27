# Feature survey

A survey of the complete feature surface of a mature, widely-used Hugo blog theme, mapped against
what Northlight has today. It is a **menu, not a plan** — `docs/SPEC.md` remains the requirements
document, and the whole premise of this theme is that the surveyed theme is roughly three times
larger than the site it served needs.

Read it to answer two questions: *does the reference theme do something we should?* and *has
this already been decided?* Where a row says **Rejected**, the reason is in `BACKLOG.md` under
"Deliberately not built" or in the notes here — reopening one needs an argument that did not
exist when the decision was made.

## Legend

| Status | Meaning |
|---|---|
| **Have** | Built and demonstrated in `exampleSite/` |
| **Partial** | Some of it exists; the note says what is missing |
| **Gap** | Not built, not decided against — a genuine candidate |
| **Rejected** | Considered and deliberately not built |

Value is judged against Northlight's actual purpose: a fast, quiet, accessible theme for a
technical blog that other people can install. "High" means it changes what a reader or a site
author can do. It is not a measure of effort.

---

## 1. Reading experience

| Feature | Status | Value | Note |
|---|---|---|---|
| Table of contents | **Have** | — | Scroll-spy, sticky rail on desktop, card on mobile |
| TOC hides unfocused children | Gap | Low | Extra motion in a component whose job is to stay still |
| Reading time | **Have** | — | |
| Word count | **Have** | — | |
| Reading progress bar | **Have** | — | 2px, respects `prefers-reduced-motion` |
| Back to top | **Have** | — | Appears past 600px |
| Code copy button | **Have** | — | |
| Code block filename bar | **Have** | — | `{file="..."}` on the fence |
| Syntax highlighting, both modes | **Have** | — | All 84 Chroma classes, measured ≥4.5:1 |
| Heading anchor links | **Have** | — | |
| Breadcrumbs | **Have** | — | |
| Prev/next pagination | **Have** | — | |
| Related content | **Have** | — | |
| Tag display | **Have** | — | |
| Share links | **Partial** | Low | LinkedIn and Reddit. Reference theme offers 11 |
| **Admonitions / callouts** | **Have** | — | Five types via GitHub `> [!NOTE]` syntax, colours outside the palette system |
| **Responsive images in prose** | **Have** | — | `render-image.html`: intrinsic dimensions, srcset, lazy, async |
| Image captions | **Have** | — | Markdown title becomes a `<figcaption>` |
| Image zoom / lightbox | Rejected | Low | JS weight for a gesture the browser already offers |
| Zen / focus mode | Gap | Low | The layout is already the focus mode |
| Reply by email link | Gap | Low | |
| oEmbed rich cards | Rejected | Low | Remote requests at build time |

## 2. Content model and front matter

| Feature | Status | Value | Note |
|---|---|---|---|
| `title` `description` `date` `draft` `tags` | **Have** | — | |
| Draft label | **Have** | — | |
| Per-post `showHero`, `showTableOfContents` | **Have** | — | |
| `coverAlt` | **Have** | — | |
| `robots` | **Have** | — | Cascades |
| `sitemap_exclude` | **Have** | — | |
| **`excludeFromSearch`** | **Gap** | Medium | Sitemap exclusion exists; the search index has no equivalent |
| **`lastmod` / updated date** | **Partial** | **High** | Emitted in sitemap, OpenGraph and JSON-LD, but never shown to a reader. A corrected post looks stale |
| **Edit this page link** | **Gap** | **High** | Standard for an open-source or docs-shaped site; cheap and it invites contribution |
| `externalUrl` link posts | Gap | Medium | For syndicated or link-blog entries |
| Custom `summary` | **Have** | — | Hugo built-in |
| Series / `series_order` | Rejected | — | Zero posts use it. See `BACKLOG.md` |
| Multiple authors | Rejected | — | Single-author theme by design |
| Author taxonomy and badges | Rejected | — | Follows from the above |
| Categories as a second taxonomy | Gap | Low | Tags alone have been sufficient |
| Custom taxonomies | **Have** | — | Hugo config; `taxonomy.html` is generic |

## 3. Layout and navigation

| Feature | Status | Value | Note |
|---|---|---|---|
| Main menu | **Have** | — | |
| Footer menu | **Have** | — | |
| **Nested / dropdown menus** | **Gap** | Medium | `site.Menus.main` is ranged one level deep; `.Children` is ignored |
| Sub-navigation bar | Rejected | Low | Second nav for a six-post blog |
| Header layout variants (fixed, fill, blur) | Gap | Low | Four variants where one considered choice is better |
| Homepage layouts (profile/hero/card/background/custom) | Rejected | — | One homepage, matching the approved design |
| Hero styles (basic/big/background/thumb) | Rejected | — | Covers are 1200×630 with the title baked in; only one treatment is correct |
| Card vs list view switches | Rejected | — | See `BACKLOG.md` |
| `groupByYear` on the index | **Have** | — | |
| Pagination | **Have** | — | |
| Constrain item width | **Have** | — | Fixed measure, not configurable |
| 404 page | **Have** | — | |
| Skip to content | **Have** | — | |

## 4. Appearance and theming

| Feature | Status | Value | Note |
|---|---|---|---|
| Light / dark modes | **Have** | — | `light-dark()`, no flash, follows system |
| Appearance toggle | **Have** | — | |
| Colour palettes | **Have** | — | Three: periwinkle, sage, clay |
| Built-in palette count | Gap | Low | Reference theme ships 16. Three considered ones beat sixteen |
| **User `custom.css` hook** | **Have** | — | Auto-detected, folded into the fingerprinted bundle |
| Custom palettes from the site repo | **Have** | — | Retune tokens in `custom.css` |
| Self-hosted fonts | **Have** | — | Metric-matched fallbacks, zero layout shift |
| Custom fonts from the site repo | **Have** | — | Same hook |
| Styled scrollbars | **Have** | — | |
| Icon set | **Have** | — | Inline SVG, `_partials/icon.html` |
| Custom icons from the site repo | Gap | Low | |
| Tailwind rebuild pipeline | Rejected | — | There is no Tailwind. That is the point |
| Logo / secondary logo | Gap | Medium | Header is text-only; a site author with a wordmark has no route |

## 5. Discovery, SEO and feeds

| Feature | Status | Value | Note |
|---|---|---|---|
| Client-side search | **Have** | — | ⌘K modal, field-weighted, no dependency |
| RSS | **Have** | — | |
| JSON search index | **Have** | — | |
| Sitemap, taxonomies excluded | **Have** | — | |
| `robots.txt` | **Have** | — | |
| OpenGraph / Twitter cards | **Have** | — | Theme-owned, correct tag casing |
| JSON-LD article schema | **Have** | — | |
| **BreadcrumbList schema** | **Gap** | Medium | Breadcrumbs render but emit no structured data |
| Meta description fallback order | **Partial** | Low | Fixed order; reference theme makes it configurable |
| **Search engine verification tags** | **Gap** | Medium | Google, Bing, and notably `fediverse:creator` for Mastodon attribution |
| Canonical URL | **Have** | — | |
| Favicons | **Have** | — | Overridable partial |

## 6. Integrations

| Feature | Status | Value | Note |
|---|---|---|---|
| Comments (giscus) | **Have** | — | GitHub Discussions, params-driven, follows the appearance toggle, partial overridable |
| `extend-head.html` | **Have** | — | |
| **`extend-footer.html`** | **Have** | — | End-of-body twin of the head hook |
| `extend-head-uncached.html` | Gap | Low | |
| Analytics: Cloudflare Web Analytics | **Have** | — | `params.analytics.cloudflare.token`. Cookieless, so no consent banner |
| Analytics: Fathom, Umami, Seline, GA, Plausible | Rejected | — | `extend-head.html` is the supported route. A theme should not ship five vendors |
| Firebase view and like counters | Rejected | — | Adds a backend to a static site |
| Buy Me A Coffee widget | Rejected | — | |
| AdSense | Rejected | — | |
| RSSNext / Follow ownership tags | Gap | Low | |

## 7. Internationalisation

| Feature | Status | Value | Note |
|---|---|---|---|
| **Translatable UI strings** | **Gap** | **High** | There is no `i18n/` directory. Every string is hardcoded English inside templates, so a non-English site cannot use this theme without editing it |
| Multilingual sites | Rejected | — | Full multi-language routing is out of scope per `docs/SPEC.md` |
| RTL support | Gap | Medium | Follows from the strings work |
| Configurable date format | **Partial** | Medium | Uses the site language default; not a param |
| Browser language redirect | Rejected | Low | Client-side redirects on a static site |

## 8. Shortcodes

The reference theme ships **34**. `docs/SPEC.md` puts shortcodes out of scope, and the audit
behind this theme found the reference blog used none of them.

The distinction that matters: a shortcode is theme-specific syntax that locks content to the
theme, while a **render hook** enriches standard Markdown that renders fine anywhere. Admonitions
and responsive images are listed as gaps above precisely because they can be render hooks. The
following would all require inventing syntax:

Alert · Accordion · Article · Badge · Button · Carousel · Chart · Code importer · Email · Figure ·
Gallery · Gist · Repository cards for six different forges · Hugging Face card · Icon · KaTeX ·
Keyword · Lead · List · LTR/RTL · Markdown importer · Mermaid · Swatches · Tabs · Timeline ·
TypeIt · Video · YouTube Lite

Two are worth naming individually because a technical blog has a real claim on them:

- **Mermaid** — diagrams as text. Would pull a large JS renderer onto every page that has one.
  Belongs in `extend-head.html` for the sites that want it.
- **KaTeX** — already decided in `BACKLOG.md` for the same reason.

---

## Ranked build order

Ordered by value to a reader or a site author, divided by the surface it adds. Everything here is
a render hook, a partial, or a param — nothing invents syntax and nothing adds a dependency.

1. ~~**Responsive images in prose**~~ — **done.** `_markup/render-image.html`. Fixed an existing
   invariant violation rather than adding a feature: prose images shipped with no intrinsic size
   and reflowed the article as they loaded.
2. ~~**Admonitions**~~ — **done.** `_markup/render-blockquote.html`, GitHub `> [!NOTE]` syntax.
3. ~~**`custom.css` hook**~~ — **done.** Appended to the theme bundle, so it stays fingerprinted
   and costs no extra request.
4. ~~**`extend-footer.html`**~~ — **done.** Completes the escape-hatch pair.
5. **Updated date and edit link.** `lastmod` is already computed and thrown away; surfacing it plus
   an edit URL makes a maintained post look maintained.
6. **Translatable UI strings.** Move every hardcoded string into `i18n/en.toml`. Mechanical, wide,
   and it is the single thing most likely to stop a stranger using the theme.
7. **Small SEO batch.** BreadcrumbList schema, verification tags including `fediverse:creator`,
   `excludeFromSearch`.
8. **Nested menus.** Honour `.Children` in the header.
9. **Logo support.** A wordmark or mark in place of the site title, both modes.
