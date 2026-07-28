# Feature survey

A survey of the complete feature surface of a mature, widely-used Hugo blog theme, mapped against
what Northlight has today. It is a **menu, not a plan** — `docs/SPEC.md` remains the requirements
document, and the whole premise of this theme is that the surveyed theme is roughly three times
larger than the site it served needs.

Read it to answer two questions: *does the reference theme do something we should?* and *has
this already been decided?* Where a row says **Rejected**, the reason is in `BACKLOG.md` under
"Deliberately not built" or in the notes here.

> **The reopening is finished.** `docs/GAP-LIST.md` was the build order for the expansion
> rounds, and everything it put in scope has landed; the tables below were corrected as each
> feature shipped and are current. A row marked Rejected is again a standing decision, not a
> queue.

**Before building anything off this page**, read "Shipping a feature" in `CONTRIBUTING.md`. A
feature here is not done when it works: it needs its default resolved in `init.html`, its strings
in `i18n/en.toml`, a demonstration in `exampleSite/`, a section in the docs site under
`exampleSite/content/docs/`, a `README.md` row, a `CHANGELOG.md` entry, and its row below updated.
That last step is what keeps this document true.

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
| TOC hides unfocused children | **Have** | — | `smartTOCHideUnfocusedChildren`, off by default. Built with `:has()` — no script and no transition, so the original objection (extra motion) does not apply |
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
| Share links | **Have** | — | Eleven providers, all plain URLs with no script. Mastodon needs `article.mastodonInstance`, since it is federated |
| **Admonitions / callouts** | **Have** | — | Five types via GitHub `> [!NOTE]` syntax, colours outside the palette system |
| **Responsive images in prose** | **Have** | — | `render-image.html`: intrinsic dimensions, srcset, lazy, async |
| Image captions | **Have** | — | Markdown title becomes a `<figcaption>` |
| Image zoom / lightbox | **Have** | — | `enableLightbox`, off by default. A `<dialog>`, so the focus trap and Escape handling are the browser's rather than hand-rolled |
| Zen / focus mode | **Have** | — | `article.showZenMode`. Escape leaves; the toggle survives the hiding |
| Reply by email link | **Have** | — | `article.replyByEmail` plus `author.email`. A `mailto:` with the title prefilled: no third party, no script, works with JS off |
| oEmbed rich cards | **Have** | — | Metadata and a build-time thumbnail, not the `html` field — that is almost always a third-party iframe. A facade, like `youtube-lite` |

## 2. Content model and front matter

| Feature | Status | Value | Note |
|---|---|---|---|
| `title` `description` `date` `draft` `tags` | **Have** | — | |
| Draft label | **Have** | — | |
| Per-post `showHero`, `showTableOfContents` | **Have** | — | |
| `coverAlt` | **Have** | — | |
| `robots` | **Have** | — | Cascades |
| `sitemap_exclude` | **Have** | — | |
| **`excludeFromSearch`** | **Have** | — | Front matter; the search-index counterpart to `sitemap_exclude` |
| **`lastmod` / updated date** | **Have** | — | `showDateUpdated`. Renders only when `lastmod` is genuinely later than `date` |
| **Edit this page link** | **Have** | — | `showEdit`, `editURL`, `editAppendPath` |
| `externalUrl` link posts | **Have** | — | Listing entries link off-site, with an icon before the click |
| Custom `summary` | **Have** | — | Hugo built-in |
| Series / `series_order` | **Have** | — | Navigation block above the body, a `<details>` so it needs no JS. `series_order` is required; a post missing it fails the build |
| Multiple authors | **Have** | — | `authors` front matter resolved from `data/authors/`. Falls back to the single `[params.author]`, so existing sites are unaffected |
| Author taxonomy and badges | **Have** | — | `author = "authors"` under `[taxonomies]` plus `showAuthorsBadges` |
| Categories as a second taxonomy | Rejected | — | `taxonomy.html` is generic, so a site can add one in config without theme changes |
| Custom taxonomies | **Have** | — | Hugo config; `taxonomy.html` is generic |

## 3. Layout and navigation

| Feature | Status | Value | Note |
|---|---|---|---|
| Main menu | **Have** | — | |
| Footer menu | **Have** | — | |
| **Nested / dropdown menus** | **Have** | — | One level, as a `<details>` disclosure rather than a hover dropdown |
| Sub-navigation bar | **Have** | — | `header.showSubNav`, off by default. Renders only when the `subnav` menu has entries |
| Header layout variants | **Have** | — | Two, not four: `fixed` (sticky, the default) and `basic`. The fill and blur variants were not built — they are decoration on a bar that exists to stay out of the way |
| Homepage layouts | **Have** | — | Ten, selected by `home.layout`. Defaults to `stack`, the original homepage, verified byte-identical |
| Hero styles (basic/big/background/thumb) | **Have** | — | All four, with the never-crop rule intact in every one. `background` suits textless artwork, since it puts the title over the image |
| Card vs list view switches | **Have** | — | `list.cardView` and `taxonomy.cardView`, both defaulting to current behaviour |
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
| Built-in palette count | **Have** | — | Six. Each accent measured against its own tint before shipping; a seventh candidate was dropped for measuring below every existing palette |
| **User `custom.css` hook** | **Have** | — | Auto-detected, folded into the fingerprinted bundle |
| Custom palettes from the site repo | **Have** | — | Retune tokens in `custom.css` |
| Self-hosted fonts | **Have** | — | Metric-matched fallbacks, zero layout shift |
| Custom fonts from the site repo | **Have** | — | Same hook |
| Styled scrollbars | **Have** | — | |
| Icon set | **Have** | — | Inline SVG, `_partials/icon.html` |
| Custom icons from the site repo | **Have** | — | `assets/icons/name.svg`; a site file wins over a built-in of the same name |
| Tailwind rebuild pipeline | Rejected | — | There is no Tailwind. That is the point |
| Logo / secondary logo | **Have** | — | `logo` and optional `logoDark`, replacing the dot and wordmark together |

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
| **BreadcrumbList schema** | **Have** | — | Emitted alongside the page schema wherever the page has ancestors |
| Meta description fallback order | **Have** | — | `seo.metaDescriptionOrder`, defaulting to the order the theme always used |
| **Search engine verification tags** | **Have** | — | `[params.verification]`, including `fediverse:creator` |
| Canonical URL | **Have** | — | |
| Favicons | **Have** | — | Overridable partial |

## 6. Integrations

| Feature | Status | Value | Note |
|---|---|---|---|
| Comments (giscus) | **Have** | — | GitHub Discussions, params-driven, follows the appearance toggle, partial overridable |
| `extend-head.html` | **Have** | — | |
| **`extend-footer.html`** | **Have** | — | End-of-body twin of the head hook |
| `extend-head-uncached.html` | Not applicable | — | The reference theme needs an uncached variant because its `extend-head` is cached. Ours is called with plain `partial` from an uncached `head.html`, so per-page injection already works and a second hook would be two names for one behaviour |
| Analytics: Cloudflare · Fathom · Umami · Seline · Plausible · Google | **Have** | — | Six providers as config blocks; GA through Hugo's own `[services.googleAnalytics]`. Nothing is emitted unless configured |
| Analytics: Fathom · Umami · Seline · Plausible · GA | **Have** | — | All wired as config blocks. Anything else still goes through `extend-head.html` |
| Firebase view and like counters | **Have** | — | Firestore REST, no SDK. Off unless configured; the only feature that records reader activity |
| Buy Me A Coffee widget | **Have** | — | `buymeacoffee`, opt-in global widget |
| AdSense | **Have** | — | `advertisement.adsense`, opt-in. Documented as profiling readers across sites and needing a consent banner the theme does not ship |
| RSSNext / Follow ownership tags | **Have** | — | `rssnext.feedId` / `userId`, emitted only when set |

## 7. Internationalisation

| Feature | Status | Value | Note |
|---|---|---|---|
| **Translatable UI strings** | **Have** | — | `i18n/en.toml`. Nothing user-facing is hardcoded, plurals included |
| Multilingual sites | **Have** | — | Switcher, `hreflang` + `x-default`, per-language index, menus and date formats. Renders nothing on a single-language site |
| RTL support | **Have** | — | Per site and per page. Measured against a full Arabic page in `exampleSite`: nineteen declarations converted to logical properties, code pinned LTR. Two deliberate exceptions marked in the source |
| Configurable date format | **Have** | — | `dateFormat`, a Go reference layout |
| Browser language redirect | **Have** | Low | `languageRedirect`, off by default, runs once, home-page-only by default — rewriting a deliberately shared deep link loses what was shared |

## 8. Shortcodes

The reference theme ships **34**. This theme shipped none until 2026-07-27, on the grounds that
`docs/SPEC.md` puts them out of scope and the audit behind this theme found the reference blog
used none of them.

**That decision was reversed.** The audit finding is still true, but it describes one blog, and
this theme is published for other people whose content is not that blog's. `docs/EXPANSION-PLAN.md`
is the ordered build list and the progress record; the table below is the status.

The distinction that drove the original decision still holds and still shapes the work: a
shortcode is theme-specific syntax that locks content to the theme, while a **render hook**
enriches standard Markdown that renders fine anywhere. So render hooks stay the documented default
wherever both would work — admonitions and responsive images remain render hooks and are not being
duplicated as shortcodes — and every shortcode is additive, replacing no Markdown path.

| Shortcode | Status | Note |
|---|---|---|
| Lead | **Have** | Reuses the `.lede` treatment rather than defining a parallel one |
| Badge | **Have** | Same shape as a tag, without a tag's link behaviour |
| Button | **Have** | Reuses the `.button` already used by the 404 page and the share row |
| Email | **Have** | Obfuscated at build time, so it works with scripting off and keeps copy and paste |
| Swatches | **Have** | Variadic rather than the three the reference caps at; each chip labelled with its hex |
| LTR/RTL | **Have** | A `dir` attribute rather than a CSS property, so it survives without the stylesheet |
| Keyword | **Have** | Shares `badge`'s shape; inner text required so a pill always carries a label |
| Icon | **Have** | Exposes the internal icon partial; the names are a public surface from now on |
| Article | **Have** | Reuses `_partials/card.html`; an unresolvable path fails the build |
| List | **Have** | Reuses `_partials/post-item.html`, at a heading level that nests where it lands |
| Figure | **Have** | Same pipeline as the render hook, dark variants included; never cropped |
| Alert | **Have** | A thin wrapper over the admonition CSS, adding a custom icon and title. The render hook stays the default |
| Timeline | **Have** | Pure CSS; `role=list` semantics without invalid markup |
| Accordion | **Have** | `<details>`/`<summary>`; single-open is a native shared `name`, no JavaScript |
| Gallery | **Have** | Grids nested `figure` calls, so one image path; never crops |
| Tabs | **Have** | Headed sections upgraded to an ARIA tablist; full keyboard support, readable with JS off |
| Carousel | **Have** | Built with CSS scroll-snap instead: no JavaScript, no autoplay, so neither objection applies |
| Video · YouTube Lite | **Have** | `video` for local files, `youtube-lite` as a click-to-load facade. Neither requests anything on page view; `video` has no autoplay, because CSS cannot honour `prefers-reduced-motion` for playback |
| Repository cards (seven services) | **Have** | — | One build-time fetch mechanism; the reader requests nothing. A 404 fails the gate, offline does not |
| Gist | **Have** | — | Fetched at build time and highlighted by the theme, so the reader loads no GitHub script |
| Chart · Mermaid · TypeIt | **Have** | — | Chart and mermaid vendored and gated on `.HasShortcode`, so nothing loads on a page without one. TypeIt written directly: the library is GPL-3.0 and this theme is MIT |
| KaTeX | **Have** | — | Rendered at build time by Hugo's own KaTeX into MathML. No library, no stylesheet, no fonts shipped |

Of the rejected ones, **diagrams as text** has the strongest claim if this is ever reopened — a
technical blog has a real use for it. It would still put a large renderer on the page.

---

## What is left

Nothing open. Every row on this page is either **Have** or explicitly Rejected with a reason;
the last Gap/Partial rows closed with the gap-list rounds (CHANGELOG 0.4.0) and the audit
cleanup that followed. Worth keeping from that work:

* **RTL** is Have, and it earned the status by being measured: table cells and the "next"
  pager used physical `text-align` and stayed pinned to the left edge while everything
  around them flipped. Fixed, and `tests/run.sh` refuses any `text-align: left|right` in
  the CSS so it cannot creep back. The same failure mode surfaced once more after that —
  the TOC scroll-spy accent used a physical `border-left-color` — and the suite now
  refuses `border-left` in those files too. The lesson generalises: the remaining RTL risk
  is always another physical property, not `dir` itself.
* **Share links** covers eleven providers. The limit is not effort but the no-script rule:
  a provider needing an SDK would put a third-party request on every article page for a
  button most readers never press.

A row marked Rejected is a decision, not a backlog item: reopening one needs an argument
that did not exist when it was made.

## Known limitations

Not features, and not on the list above, but worth writing down.

* **Search covers `mainSections` only.** The documentation section is deliberately outside
  it so the manual does not appear in the blog index, the feed or the archive, which also
  means ⌘K does not find it. Widening search without widening the rest would need the
  index and the listing scopes to be separated.
* **Raster images cannot follow the palette on their own.** The `-dark` sibling mechanism
  solves it for images the author controls. Anything hotlinked or in `static/` cannot be
  paired, because Hugo does not manage those files.
