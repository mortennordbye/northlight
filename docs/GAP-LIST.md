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

`docs/FEATURE-SURVEY.md` and `BACKLOG.md` recorded some of these as Rejected while the decision
was fresh; both have since been brought in line with it (see the note at the foot).

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
| 11 | ~~**`header.layout` variants**~~ **DONE** | `fixed` (sticky, the default and current behaviour) and `basic` (scrolls away). The anchor offset follows the choice | Medium |
| 12 | ~~**Card-view toggles**~~ **DONE** | `list.cardView` and `taxonomy.cardView`, both defaulting to current behaviour. `cardViewScreenWidth` dropped: the grid is already fluid, so a width switch would be a knob with nothing behind it | Medium |
| 13 | ~~**More colour schemes**~~ **DONE** | 3 → 6: `plum`, `slate`, `rose`. Each measured against its own tint before shipping; a fourth candidate was dropped for measuring below every existing palette | Small each |
| 14 | ~~**Analytics vendor blocks**~~ **DONE** | Fathom, Umami (with self-hosted domain and renamed script), Seline. Nothing fires unless configured, asserted against the built demo | Small each |
| 15 | ~~**Site-wide image fallbacks**~~ **DONE** | `defaultFeaturedImage` and `defaultSocialImage`. `defaultBackgroundImage` folded in: `home.backgroundImage` already covers it | Small |
| 16 | ~~**Accessibility toggle**~~ **DONE** | `enableA11y` shows an underline-links control, named for its actual effect. WCAG 1.4.1: the theme's faint prose rule does not reach nav, cards or footers | Medium |
| 17 | ~~**Image zoom / lightbox**~~ **DONE** | Built on `<dialog>`, so the focus trap, backdrop and Escape handling are the browser's. Focus returns to the opener; linked images are left alone | Medium |
| 18 | ~~**Views and likes**~~ **DONE** | Firestore **REST API, no SDK** — the Firebase SDK is hundreds of kilobytes to increment an integer. Off unless configured; the only feature that records reader activity, and documented as such | Large |
| 19 | ~~**Repository cards**~~ **DONE** | All seven over one mechanism. Build-time fetch, so the reader requests nothing; a 404 fails CI while being offline does not, which keeps SPEC §1 true | Medium once, Small each |
| 20 | ~~**`taxonomy.showTermCount`**~~ **DONE** | The count already rendered; this is the switch. Default true | Small |
| 21 | ~~**Reply by email**~~ **DONE** | Built alongside row 3, because `author.email` on its own would have been a param nothing reads | Small |

## Tier 3 — Medium

Useful, narrower toggles.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 22 | ~~**`layoutBackgroundBlur`**~~ **DONE** | Static blur on the image, not the block, so text over it stays sharp. Not scroll-driven: repainting an image every frame is expensive for decoration | Small |
| 23 | ~~**`layoutBackgroundHeaderSpace`**~~ **DONE** | | Small |
| 24 | ~~**`footer.showMenu`**~~ **DONE** | The menu already rendered; this is the switch, defaulting to true | Small |
| 25 | ~~**Per-page `robots`**~~ **ALREADY HAD IT** | `robots` in front matter, and it cascades from a section. Was in the scrape by mistake | Small |
| 26 | ~~**`menu` in front matter**~~ **ALREADY HAD IT** | Hugo native; verified by putting a docs page into the footer menu from its own front matter | Small |
| 27 | ~~**`orderByWeight`**~~ **DONE** | `list.orderByWeight`. Replaces the date sort rather than blending with it | Small |
| 28 | ~~**`highlightCurrentMenuArea`**~~ **ALREADY HAD IT** | `header.html` has marked the active entry and its ancestors since it was written | Small |
| 29 | ~~**Zen mode**~~ **DONE** | Hides header, TOC rail and both footers. Escape leaves, and the toggle survives the hiding — a mode with no visible way out is a trap. Not persisted | Medium |
| 30 | ~~**`imagePosition`**~~ **DONE** | Applies to the avatar and thumbnails, which are real crops. Inert on covers by design, since those are never cropped | Small |
| 31 | ~~**Image optimisation toggles**~~ **DONE** | `disableImageOptimization`, honoured in all six partials that resize a cover. The MD variant was dropped: prose images go through one render hook, so the single flag already covers them | Small |
| 32 | ~~**Gist embed**~~ **DONE** | Fetched at build time, so the reader loads no GitHub script and the code gets this theme's highlighting in both colour modes | Small |
| 33 | ~~**BuyMeACoffee**~~ **DONE** | Global widget, opt-in, in `monetisation.html` alongside AdSense | Small |
| 34 | ~~**`externalLinkForceNewTab`**~~ **DONE** | Default true, which is what the link hook already did. `rel="noopener"` is kept either way | Small |
| 35 | ~~**`invertPagination`**~~ **DONE** | Labels swap with the links, so the arrow and the word never disagree | Small |
| 36 | ~~**`hotlinkFeatureImage`**~~ **DONE** | Off by default: a remote image is a third-party request on page view. Nothing is fetched at build time, so the box cannot be reserved — the cost is stated | Small |

## The tail, closed

Five rows that lived only in `docs/FEATURE-SURVEY.md` rather than in this list, plus the
`extend-article-link` hook from the second pass. All built.

| Feature | Outcome |
|---|---|
| Custom icons from the site repo | `assets/icons/name.svg`, overriding built-ins of the same name |
| Meta description fallback order | `seo.metaDescriptionOrder` |
| `author.imageQuality` | Avatar through the image pipeline; SVG still passes through. Quality is lossy-format-only, which is now stated |
| RTL physical properties | Nineteen converted, measured against a real Arabic page. Code pinned LTR |
| oEmbed rich cards | Metadata facade, not the `html` field |
| Sub-navigation bar | `header.showSubNav`, off by default |

**One row is refused, and it is not a licence question.** The *Tailwind rebuild pipeline*
cannot be built without adding Tailwind, and this theme's premise is that it has no CSS
framework. Building it would not extend the theme; it would replace it. That is a
contradiction rather than a disagreement, which is why it is the only thing on this page
left undone.

## Found on the second pass

Re-scraped 2026-07-28 after the top ten landed, covering the docs pages the first pass
missed: Partials, Thumbnails and Homepage Layout. Two genuinely new rows, and two
non-findings worth recording so nobody re-checks them.

| # | Feature | What it gives you | Effort |
|---|---|---|---|
| 53 | ~~**Google Analytics**~~ **DONE** | Through Hugo's own `[services.googleAnalytics]` key and template, not a theme param — a theme param would be a second key that does nothing | Small |
| 54 | ~~**`extend-article-link.html`**~~ **DONE** | The third escape hatch, and the only per-entry one. Ships empty, and the suite asserts it stays empty | Small |

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
| 37 | ~~**`showDateOnlyInArticle`**~~ **DONE** | Honoured in `post-meta.html`, which is the listing meta; the article page has its own | Small |
| 38 | ~~**`showHeadingAnchors` in front matter**~~ **DONE** | Per-page override of the site default | Small |
| 39 | ~~**Per-page `xml`**~~ **ALREADY HAD IT** | Same capability under a different key: `sitemap_exclude`. Was in the scrape by mistake | Small |
| 40 | ~~**`sitemap.excludedKinds`**~~ **DONE** | Replaces the built-in list rather than adding to it, so taxonomies can be put back in | Small |
| 41 | ~~**`footer.showAppearanceSwitcher` / `showScrollToTop`**~~ **DONE** | Both default true | Small |
| 42 | ~~**`disableTextInHeader`**~~ **DONE** | The home link gains an `aria-label`, or it would be unlabelled on every page | Small |
| 43 | ~~**`backgroundImageWidth`**~~ **DONE** | Resizes the full-bleed background, which is the largest image on any page that has one. SVG and remote URLs pass through | Small |
| 44 | ~~**`enableStyledScrollbar`**~~ **DONE** | Off hands the scrollbar back to the OS | Small |
| 45 | ~~**`fingerprintAlgorithm`**~~ **DONE** | Reaches all six fingerprint calls; asserted, since a missed one would hash inconsistently | Small |
| 46 | ~~**`smartTOCHideUnfocusedChildren`**~~ **DONE** | Built with `:has()`, no script and no transition — the objection to it was motion, and this adds none | Small |
| 47 | ~~**TypeIt**~~ **DONE, WITHOUT THE LIBRARY** | TypeIt is GPL-3.0 and this theme is MIT, so vendoring it would push every site using the theme onto copyleft for a decorative animation. Written directly instead, in ~20 lines | Small |
| 48 | ~~**Code importer**~~ **DONE** | Build-time fetch with `lines` range; out-of-range bounds clamp rather than erroring | Small |
| 49 | ~~**Markdown importer**~~ **DONE** | Rendered through the page's own `RenderString`. Documented as rendering somebody else's content as your own | Small |
| 50 | ~~**Language redirect**~~ **DONE** | Off by default; runs once; home-page-only by default, because rewriting a deliberately shared deep link loses what was shared | Small |
| 51 | ~~**RSSNext**~~ **DONE** | Emitted only when configured | Small |
| 52 | ~~**AdSense**~~ **DONE** | Opt-in, and documented as needing a consent banner the theme does not ship | Small |

---

## Suggested build order notes

- **Rows 3 → 2 → 21** are one chain. Do the author fields first; multiple authors and reply-by-email both sit on top of them.
- **Row 19** is seven features wearing one coat. Build the fetch-cache-render mechanism once and the six remaining skins are configuration.
- **Rows 5, 6, 7, 17, 47** each add a JavaScript library. Self-host every one of them; a CDN reference breaks the no-third-party-requests rule even when the feature is opt-in, because the request happens on page view rather than on use.
- **Rows 10, 30 and 36** all touch feature images, and all three can break the never-crop invariant. Do them together with one set of measurements rather than three.
- **Row 1** is the largest single item on the page and touches every template. It is ranked first on value, not on sequence — there is a reasonable argument for clearing Tier 2's cheap rows first to keep momentum.

## Keeping the repo honest

Done. `docs/FEATURE-SURVEY.md`'s tables were flipped as features landed and its prose caught up
in the audit cleanup; `BACKLOG.md`'s "Deliberately not built" section now carries only video
autoplay, the one objection that still stands; and `docs/EXPANSION-PLAN.md`'s checkboxes and
Part D were corrected in the same pass. No document on this repo should now disagree with the
code about whether something was decided against.
