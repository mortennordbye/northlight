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

Both survive if these ship **opt-in and default-off**, with self-hosted assets where the library
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
| 1 | **Multilingual routing** | Per-language config, menus, `displayName`, `isoCode`, translated content trees. The single biggest audience unlock on the list; `rtl` and `dateFormat` already exist per-language | Large |
| 2 | **Multiple authors** | `authors` array, per-author taxonomy pages, `showAuthorsBadges`, `showAuthorBottom`. Turns a personal theme into one a team can use | Medium |
| 3 | ~~**Author profile fields**~~ **MOSTLY DONE** | `bio` and `email` built. **`imageQuality` deferred** — the avatar deliberately does not go through Hugo's image pipeline, because `image-url.html` also has to pass SVG through untouched, and routing rasters through `.Resize` is a separate change. Tracked in `BACKLOG.md` | Small |
| 4 | **Series** | `series`, `series_order`, `seriesOpened`. Multi-part posts get navigation instead of the reader hunting | Medium |
| 5 | **Mermaid diagrams** `[opt-in]` | Diagrams as text in the post. The most-requested capability on a technical blog after code fences | Medium |
| 6 | **Maths rendering** `[opt-in]` | KaTeX. Site config (`markup.goldmark.extensions.passthrough`) plus a renderer | Medium |
| 7 | **Charts** `[opt-in]` | Chart.js from structured data in the shortcode body | Medium |
| 8 | ~~**Sharing providers**~~ **DONE** | 2 → 11. Every one a plain URL, no script. Added `article.mastodonInstance`, since Mastodon is federated and has no central share host. Also fixed labels coming from `title`-casing the config key, which rendered "Linkedin" | Small |
| 9 | ~~**List summaries**~~ **DONE** | `list.showSummary`. Falls back to the post summary when there is no `description`; a `description` still wins. Stripped and truncated, so markup cannot leak into the card | Small |

## Tier 2 — Medium-high

Substantial author control over presentation, or a visible reader feature.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 10 | **`heroStyle` variants** | `basic`, `big`, `background`, `thumbAndBackground`. Must not break the never-crop rule — the covers are 1200×630 with the title in the artwork | Medium |
| 11 | **`header.layout` variants** | `basic`, `fixed`, and the sticky variants | Medium |
| 12 | **Card-view toggles** | `cardView` / `cardViewScreenWidth` across home, list, taxonomy and term | Medium |
| 13 | **More colour schemes** | 3 → many. One block in `tokens.css` each, per the existing pattern | Small each |
| 14 | **Analytics vendor blocks** | Fathom, Umami (incl. anti-adblock `scriptName`), Seline. Reachable via `extend-head.html` today, so this is convenience, not capability | Small each |
| 15 | **Site-wide image fallbacks** | `defaultFeaturedImage`, `defaultBackgroundImage`, `defaultSocialImage` | Small |
| 16 | **Accessibility toggle** | `enableA11y` — a visible control, not just good defaults | Medium |
| 17 | **Image zoom / lightbox** `[opt-in]` | Click to enlarge. Needs JS and a focus trap to be done properly | Medium |
| 18 | **Views and likes** `[opt-in]` | Firebase-backed counters. The only row needing a backend and credentials; those are site config, never theme files | Large |
| 19 | **Repository cards** `[opt-in]` | GitHub, GitLab, Codeberg, Gitea, Forgejo, Ansible Galaxy, Hugging Face. One fetch-and-render mechanism, seven skins — build the mechanism once | Medium once, Small each |
| 20 | **`taxonomy.showTermCount`** | Article count beside each term | Small |
| 21 | ~~**Reply by email**~~ **DONE** | Built alongside row 3, because `author.email` on its own would have been a param nothing reads | Small |

## Tier 3 — Medium

Useful, narrower toggles.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 22 | **`layoutBackgroundBlur`** | Background image blurs on scroll | Small |
| 23 | **`layoutBackgroundHeaderSpace`** | Space between header and body | Small |
| 24 | **`footer.showMenu`** | A menu in the footer | Small |
| 25 | **Per-page `robots`** | Crawler directives in front matter | Small |
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

## Tier 4 — Low

Cosmetic, one-line, or narrow enough that nobody will notice its absence.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 37 | **`showDateOnlyInArticle`** | Date in the body but not the listing | Small |
| 38 | **`showHeadingAnchors` in front matter** | Per-page override; ours is site-level | Small |
| 39 | **Per-page `xml`** | Per-article sitemap inclusion | Small |
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
| 50 | **Language redirect** | Client-side browser-language redirect. Depends on row 1 | Small |
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
