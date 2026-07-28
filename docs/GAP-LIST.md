# Gap list

Every feature the reference theme has that Northlight does not, ordered high value to low.
Scraped 2026-07-28 from its published documentation (configuration, shortcodes, front matter and
advanced customisation).

**This is the build order.** Work top to bottom. Value is judged the way
`docs/FEATURE-SURVEY.md` judges it: *High* means it changes what a reader or a site author can
do, not how much effort it takes. Effort is called out separately where it is large, because a
cheap Tier 2 row is often worth doing before an expensive Tier 1 one.

Every row here is in scope. Nothing on this page is rejected.

## The one policy decision to make first

Fourteen rows marked **[opt-in]** contact a third party or the network. Two standing rules bear
on them:

- CLAUDE.md: *"No third-party requests **by default**. A theme that phones out imposes that on
  every user of it."*
- `docs/SPEC.md` §1: the theme must build with no network access.

**Decided: vendor and self-host, loaded lazily.** `mermaid` is the worked example — see
`assets/js/vendor/VENDOR.md` and the `.HasShortcode` gate in `baseof.html`. Both rules survive if
these ship **opt-in and default-off**, with self-hosted assets where the library
allows it — the first rule already says "by default", and a build-time fetch only happens on a
page that uses the shortcode. What does not survive is a default-on version of any of them.
Decide this once, here, and every `[opt-in]` row below inherits it.

`docs/FEATURE-SURVEY.md` and `BACKLOG.md` still record some of these as Rejected. Those rows are
now stale and contradict this page. They need updating in whichever commit first proves the
decision — see the note at the foot.

---

## Tier 1 — High

Unlocks content, audiences or authorship that is impossible today.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 1 | ~~**Multilingual routing**~~ **DONE** | Language switcher linking to the *translation of the current page*, `hreflang` alternates with `x-default`, per-language search index, menus and date formats. Renders nothing on a single-language site | Large |
| 2 | ~~**Multiple authors**~~ **DONE** | `authors` front matter resolved from `data/authors/`, author taxonomy pages, `showAuthorsBadges`, `showAuthorBottom`. Falls back to the single `[params.author]`, so existing sites render unchanged | Medium |
| 3 | ~~**Author profile fields**~~ **MOSTLY DONE** | `bio` and `email` built. **`imageQuality` deferred** — the avatar deliberately does not go through Hugo's image pipeline, because `image-url.html` also has to pass SVG through untouched, and routing rasters through `.Resize` is a separate change. Tracked in `BACKLOG.md` | Small |
| 4 | ~~**Series**~~ **DONE** | Navigation block above the body, `<details>` so no JS. `series_order` required — a scrambled series is worse than none, so a post missing it fails the build. A one-post series renders nothing | Medium |
| 5 | ~~**Mermaid diagrams**~~ **DONE** | Vendored and self-hosted, loaded only on pages with a diagram via `.HasShortcode` — never in the shared bundle. JS-off fallback is the diagram source; follows the colour mode | Medium |
| 6 | ~~**Maths rendering**~~ **DONE** | Hugo's built-in KaTeX renders it at build time to MathML. **No library, no stylesheet, no fonts shipped** — better than the reference theme's client-side version, and it works with JS off | Medium |
| 7 | ~~**Charts**~~ **DONE** | Vendored Chart.js, gated on `.HasShortcode`. JSON parsed at build time; `alt` required; config on a data attribute so a strict CSP is unaffected; colours from the palette | Medium |
| 8 | ~~**Sharing providers**~~ **DONE** | 2 → 11. Every one a plain URL, no script. Added `article.mastodonInstance`, since Mastodon is federated and has no central share host. Also fixed labels coming from `title`-casing the config key, which rendered "Linkedin" | Small |
| 9 | ~~**List summaries**~~ **DONE** | `list.showSummary`. Falls back to the post summary when there is no `description`; a `description` still wins. Stripped and truncated, so markup cannot leak into the card | Small |

## Tier 2 — Medium-high

Substantial author control over presentation, or a visible reader feature.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 10 | ~~**`heroStyle` variants**~~ **DONE** | All four, and the never-crop rule survives all of them: the box stays an exact 1200×630 `contain`, so `background` shows the whole cover under a scrim rather than filling a band | Medium |
| 11 | **`header.layout` variants** | `basic`, `fixed`, and the sticky variants | Medium |
| 12 | **Card-view toggles** | `cardView` / `cardViewScreenWidth` across home, list, taxonomy and term | Medium |
| 13 | ~~**More colour schemes**~~ **DONE** | 3 → 6: `plum`, `slate`, `rose`. Each measured against its own tint before shipping; a fourth candidate was dropped for measuring below every existing palette | Small each |
| 14 | **Analytics vendor blocks** | Fathom, Umami (incl. anti-adblock `scriptName`), Seline. Reachable via `extend-head.html` today, so this is convenience, not capability | Small each |
| 15 | ~~**Site-wide image fallbacks**~~ **DONE** | `defaultFeaturedImage` and `defaultSocialImage`. `defaultBackgroundImage` folded in: `home.backgroundImage` already covers it | Small |
| 16 | **Accessibility toggle** | `enableA11y` — a visible control, not just good defaults | Medium |
| 17 | **Image zoom / lightbox** `[opt-in]` | Click to enlarge. Needs JS and a focus trap to be done properly | Medium |
| 18 | **Views and likes** `[opt-in]` | Firebase-backed counters. The only row needing a backend and credentials; those are site config, never theme files | Large |
| 19 | **Repository cards** `[opt-in]` | GitHub, GitLab, Codeberg, Gitea, Forgejo, Ansible Galaxy, Hugging Face. One fetch-and-render mechanism, seven skins — build the mechanism once | Medium once, Small each |
| 20 | ~~**`taxonomy.showTermCount`**~~ **DONE** | The count already rendered; this is the switch. Default true | Small |
| 21 | ~~**Reply by email**~~ **DONE** | Built alongside row 3, because `author.email` on its own would have been a param nothing reads | Small |

## Tier 3 — Medium

Useful, narrower toggles.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 22 | **`layoutBackgroundBlur`** | Background image blurs on scroll | Small |
| 23 | **`layoutBackgroundHeaderSpace`** | Space between header and body | Small |
| 24 | **`footer.showMenu`** | A menu in the footer | Small |
| 25 | ~~**Per-page `robots`**~~ **ALREADY HAD IT** | `robots` in front matter, and it cascades from a section. Was in the scrape by mistake | Small |
| 26 | **`menu` in front matter** | A page pushes itself into a menu | Small |
| 27 | **`orderByWeight`** | Sort listings by weight rather than date | Small |
| 28 | **`highlightCurrentMenuArea`** | Mark the active menu section | Small |
| 29 | **Zen mode** | Distraction-free reading toggle | Medium |
| 30 | **`imagePosition`** | `object-position` on feature images. Interacts directly with the never-crop rule | Small |
| 31 | **Image optimisation toggles** | `disableImageOptimization`, `disableImageOptimizationMD` | Small |
| 32 | **Gist embed** `[opt-in]` | GitHub Gist in a post | Small |
| 33 | **BuyMeACoffee** `[opt-in]` | Global widget: message, colour, position | Small |
| 34 | **`externalLinkForceNewTab`** | External Markdown links open in a new tab | Small |
| 35 | **`invertPagination`** | Swap next/previous direction | Small |
| 36 | **`hotlinkFeatureImage`** `[opt-in]` | Use a remote URL as the feature image | Small |

## Found on the second pass

Re-scraped 2026-07-28 after the top ten landed, covering the docs pages the first pass
missed: Partials, Thumbnails and Homepage Layout. Two genuinely new rows, and two
non-findings worth recording so nobody re-checks them.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 53 | **Google Analytics** | Hugo ships the template, so this is a config block and two lines. The theme currently wires Cloudflare only, on the stated grounds that shipping five vendors makes four of them dead weight — that reasoning is now superseded by this page | Small |
| 54 | **`extend-article-link.html`** | A hook to inject content after each entry in a listing, the way `extend-head` and `extend-footer` work for the page | Small |

**Not gaps, checked and dismissed:**

- **`extend-head-uncached.html`.** Theirs needs an uncached variant because its
  `extend-head` is cached. Ours is called with plain `partial` from a `head.html` that is
  itself uncalled-cached, so per-page injection already works and a second hook would be
  two names for one behaviour.
- **Homepage layouts.** Theirs documents six; this theme has ten, including a `custom`
  escape hatch. Already ahead.
- **Thumbnails.** Naming (`feature*`/`cover*`), per-page `showHero`, and hero override are
  all present. Their page documents no optimisation or responsive behaviour; ours does
  both.

## Tier 4 — Low

Cosmetic, one-line, or narrow enough that nobody will notice its absence.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 37 | **`showDateOnlyInArticle`** | Date in the body but not the listing | Small |
| 38 | **`showHeadingAnchors` in front matter** | Per-page override; ours is site-level | Small |
| 39 | ~~**Per-page `xml`**~~ **ALREADY HAD IT** | Same capability under a different key: `sitemap_exclude`. Was in the scrape by mistake | Small |
| 40 | **`sitemap.excludedKinds`** | Exclude whole content kinds | Small |
| 41 | **`footer.showAppearanceSwitcher` / `showScrollToTop`** | Toggles for chrome we render unconditionally | Small |
| 42 | **`disableTextInHeader`** | Logo-only header | Small |
| 43 | **`backgroundImageWidth`** | Scale target for background images | Small |
| 44 | **`enableStyledScrollbar`** | A toggle; we already style it unconditionally | Small |
| 45 | **`fingerprintAlgorithm`** | Choose the asset hash algorithm | Small |
| 46 | **`smartTOCHideUnfocusedChildren`** | Collapse unfocused TOC levels | Small |
| 47 | **TypeIt** `[opt-in]` | Typewriter animation. Owes `prefers-reduced-motion` a static fallback | Small |
| 48 | **Code importer** `[opt-in]` | Pull code from a URL at build time | Small |
| 49 | **Markdown importer** `[opt-in]` | Pull Markdown from a URL at build time | Small |
| 50 | **Language redirect** | Client-side browser-language redirect. Row 1 is now done, so this is unblocked | Small |
| 51 | **RSSNext** | `feedId` / `userId` in the feed | Small |
| 52 | **AdSense** `[opt-in]` | `advertisement.adsense` publisher ID | Small |

---

## Suggested build order notes

- **Rows 3 → 2 → 21** are one chain. Do the author fields first; multiple authors and reply-by-email both sit on top of them.
- **Row 19** is seven features wearing one coat. Build the fetch-cache-render mechanism once and the six remaining skins are configuration.
- **Rows 5, 6, 7, 17, 47** each add a JavaScript library. Self-host every one of them; a CDN reference breaks the no-third-party-requests rule even when the feature is opt-in, because the request happens on page view rather than on use.
- **Rows 10, 30 and 36** all touch feature images, and all three can break the never-crop invariant. Do them together with one set of measurements rather than three.
- **Row 1** is the largest single item on the page and touches every template. It is ranked first on value, not on sequence — there is a reasonable argument for clearing Tier 2's cheap rows first to keep momentum.

## Keeping the repo honest

`docs/FEATURE-SURVEY.md` marks several rows above as **Rejected**, and `BACKLOG.md` has a
"Deliberately not built" section covering series, card views, maths and video autoplay. Those
records now contradict this page. Whichever commit first lands an `[opt-in]` feature should also
flip the corresponding rows, so the repo does not carry two documents disagreeing about whether
something was decided against.
