# Feature survey

A survey of the complete feature surface of a mature, widely-used Hugo blog theme, mapped against
what Northlight has today. It is a **menu, not a plan** — `docs/SPEC.md` remains the requirements
document, and the whole premise of this theme is that the surveyed theme is roughly three times
larger than the site it served needs.

Read it to answer two questions: *does the reference theme do something we should?* and *has
this already been decided?* Where a row says **Rejected**, the reason is in `BACKLOG.md` under
"Deliberately not built" or in the notes here — reopening one needs an argument that did not
exist when the decision was made.

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
| TOC hides unfocused children | Rejected | — | Extra motion in a component whose job is to stay still |
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
| Zen / focus mode | Rejected | — | The layout is already the focus mode |
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
| **`excludeFromSearch`** | **Have** | — | Front matter; the search-index counterpart to `sitemap_exclude` |
| **`lastmod` / updated date** | **Have** | — | `showDateUpdated`. Renders only when `lastmod` is genuinely later than `date` |
| **Edit this page link** | **Have** | — | `showEdit`, `editURL`, `editAppendPath` |
| `externalUrl` link posts | **Have** | — | Listing entries link off-site, with an icon before the click |
| Custom `summary` | **Have** | — | Hugo built-in |
| Series / `series_order` | Rejected | — | Zero posts use it. See `BACKLOG.md` |
| Multiple authors | Rejected | — | Single-author theme by design |
| Author taxonomy and badges | Rejected | — | Follows from the above |
| Categories as a second taxonomy | Rejected | — | `taxonomy.html` is generic, so a site can add one in config without theme changes |
| Custom taxonomies | **Have** | — | Hugo config; `taxonomy.html` is generic |

## 3. Layout and navigation

| Feature | Status | Value | Note |
|---|---|---|---|
| Main menu | **Have** | — | |
| Footer menu | **Have** | — | |
| **Nested / dropdown menus** | **Have** | — | One level, as a `<details>` disclosure rather than a hover dropdown |
| Sub-navigation bar | Rejected | Low | Second nav for a six-post blog |
| Header layout variants (fixed, fill, blur) | Rejected | — | Four variants where one considered choice is better |
| Homepage layouts | Gap | High | Reversed on 2026-07-28 — see FLAG-6 in `docs/EXPANSION-PLAN.md`. Ten layouts selected by `home.layout`, defaulting to today's homepage |
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
| Built-in palette count | Rejected | — | Every accent is measured against its own background in both modes. That does not scale to sixteen |
| **User `custom.css` hook** | **Have** | — | Auto-detected, folded into the fingerprinted bundle |
| Custom palettes from the site repo | **Have** | — | Retune tokens in `custom.css` |
| Self-hosted fonts | **Have** | — | Metric-matched fallbacks, zero layout shift |
| Custom fonts from the site repo | **Have** | — | Same hook |
| Styled scrollbars | **Have** | — | |
| Icon set | **Have** | — | Inline SVG, `_partials/icon.html` |
| Custom icons from the site repo | Gap | Low | |
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
| Meta description fallback order | **Partial** | Low | Fixed order; reference theme makes it configurable |
| **Search engine verification tags** | **Have** | — | `[params.verification]`, including `fediverse:creator` |
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
| **Translatable UI strings** | **Have** | — | `i18n/en.toml`. Nothing user-facing is hardcoded, plurals included |
| Multilingual sites | Rejected | — | Full multi-language routing is out of scope per `docs/SPEC.md` |
| RTL support | **Partial** | Low | `rtl = true` sets `dir`. Layout mirrors, but this has had no real-world exercise |
| Configurable date format | **Have** | — | `dateFormat`, a Go reference layout |
| Browser language redirect | Rejected | Low | Client-side redirects on a static site |

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
| Keyword | Gap | Needs the icon shortcode first for its optional icon |
| Icon | **Have** | Exposes the internal icon partial; the names are a public surface from now on |
| Article · List · Figure | Gap | Wrap partials the theme already has |
| Alert | Gap | Only if it can reuse the admonition render hook's colours; a second syntax for the same thing is not worth the surface |
| Accordion · Gallery · Tabs · Timeline | Gap | CSS-driven, JS-optional |
| Carousel | Gap | Lowest priority and a candidate to drop — needs JS, and autoplay fights `prefers-reduced-motion` |
| Video · YouTube Lite | Gap | Local files only; the YouTube one as a click-to-load facade, so nothing is requested on page view |
| Repository cards (six forges) · Ansible · Hugging Face · Code importer · Markdown importer | Rejected | Each calls a third-party API during the build. `docs/SPEC.md` §1 requires the theme to build with no network access |
| Gist | Rejected | Third-party script on page view; the code fence with a filename bar covers it locally |
| Chart · Mermaid · TypeIt | Rejected | Each needs a rendering library shipped to every page that uses it. `extend-head.html` is the route |
| KaTeX | Rejected | Already decided in `BACKLOG.md`, for the same reason |

Of the rejected ones, **diagrams as text** has the strongest claim if this is ever reopened — a
technical blog has a real use for it. It would still put a large renderer on the page.

---

## What is left

Section 8 is tracked separately in `docs/EXPANSION-PLAN.md` and is not counted here. Outside it,
seven rows are still Gap or Partial, all Low value or narrow:

* **RTL** is Partial. `rtl = true` sets `dir` and the layout mirrors, but nothing here has
  been exercised by someone actually reading right to left. That is the row most likely
  to be wrong.
* **Share links** covers LinkedIn and Reddit. More providers are trivial to add and worth
  adding when someone asks for a specific one.
* **Meta description fallback order** is fixed rather than configurable.
* `extend-head-uncached.html`, custom icons from the site repo, reply-by-email, and
  RSSNext ownership tags are all unbuilt and none has been asked for.

Everything else on this page is either built or explicitly rejected with a reason. A row
marked Rejected is a decision, not a backlog item: reopening one needs an argument that
did not exist when it was made.

## Known limitations

Not features, and not on the list above, but worth writing down.

* **Search covers `mainSections` only.** The documentation section is deliberately outside
  it so the manual does not appear in the blog index, the feed or the archive, which also
  means ⌘K does not find it. Widening search without widening the rest would need the
  index and the listing scopes to be separated.
* **Raster images cannot follow the palette on their own.** The `-dark` sibling mechanism
  solves it for images the author controls. Anything hotlinked or in `static/` cannot be
  paired, because Hugo does not manage those files.
