# Changelog

Notable changes to Northlight. The format follows [Keep a Changelog](https://keepachangelog.com/),
and versions follow [semantic versioning](https://semver.org/).

**Config keys are API.** A key is never renamed or repurposed without a major version bump. New
keys are added with defaults that preserve existing behaviour.

## [0.4.0](https://github.com/mortennordbye/northlight/compare/v0.3.0...v0.4.0) (2026-07-28)


### Features

* close the gap list, add RTL support, and a three-layer test suite ([f6b1c65](https://github.com/mortennordbye/northlight/commit/f6b1c65e51263fb174cc18fb979462a516bef848))

## [Unreleased]

### Added

- **Right-to-left layout, measured rather than assumed.** `exampleSite` now carries a full
  Arabic page, and `rtl` works per page as well as per site. Measuring against it found real
  bugs: the blockquote and admonition accent edges sat on the left, list indents were on the
  wrong side, and **code blocks inherited RTL**, which lets the bidirectional algorithm reorder
  punctuation inside lines. Nineteen declarations became logical properties; code is pinned to
  `direction: ltr` with `unicode-bidi: isolate`. Two declarations stay physical on purpose and
  say so at the declaration, in a form the suite reads.
- **Custom icons** — drop `name.svg` into your site's `assets/icons/` and call it by name. A
  site file wins over a built-in of the same name. Inlined, so it takes `currentColor` and sizes
  in `em` like every built-in one.
- **`seo.metaDescriptionOrder`** — which source fills the meta description, first non-empty
  wins. Defaults to the order the theme always used.
- **`author.imageQuality`** — the avatar now goes through Hugo's image pipeline. SVG still
  passes through untouched, because there are no pixels to resample and `.Resize` errors on it.
  **Quality is a lossy-format setting:** a PNG is byte-identical at any value, so the demo uses
  a JPEG, where it is 9057 bytes at q85 and 1209 at q20.
- **`oembed`** — a rich card for any URL with an oEmbed endpoint. **The `html` field is
  deliberately unused**, since it is almost always a third-party iframe or script; the card
  renders the metadata and a thumbnail downloaded at build time and served from your own domain.
  A facade, on the same terms as `youtube-lite`.
- **`header.showSubNav`** — an optional second navigation row from a `subnav` menu, off by
  default. The original objection holds for most sites — a second bar for a six-post blog is
  chrome competing with the writing — but it earns its place on a documentation site.
- **The last twenty rows.** Toggles for chrome the theme rendered unconditionally
  (`footer.showAppearanceSwitcher`, `footer.showScrollToTop`, `enableStyledScrollbar`,
  `disableTextInHeader`), per-page and per-site overrides (`showHeadingAnchors`,
  `showDateOnlyInArticle`, `invertPagination`, `externalLinkForceNewTab`,
  `sitemap.excludedKinds`), image handling (`backgroundImageWidth`, `hotlinkFeatureImage`),
  `fingerprintAlgorithm`, `smartTOCHideUnfocusedChildren`, an `extend-article-link.html` hook,
  a client-side `languageRedirect`, RSSNext feed attribution, AdSense and BuyMeACoffee, the
  `codeimporter` and `mdimporter` shortcodes, and `typeit`.
  **Every one defaults to what the theme already did**, so an existing site is unchanged.
  - `disableTextInHeader` gives the home link an `aria-label`, or a logo-only header would be
    an unlabelled link on every page.
  - `hotlinkFeatureImage` stays off because a remote image is a third-party request on page
    view, and nothing is fetched at build time, so the box cannot be reserved. Both costs are
    stated rather than glossed.
  - `smartTOCHideUnfocusedChildren` is built with `:has()` — no script, no transition. The
    standing objection to it was motion, and this adds none.
  - `languageRedirect` is off by default, runs once, and is home-page-only by default: rewriting
    a deep link that was shared deliberately in one language loses what was shared.
  - **`typeit` ships with no library.** The obvious one is GPL-3.0 and this theme is MIT, so
    vendoring it would push every site using the theme onto a copyleft licence for the sake of a
    decorative animation. The effect is written directly, in about twenty lines, and the suite
    asserts the GPL file never reappears. The finished text is in the markup and the script
    retypes it, so JavaScript-off and `prefers-reduced-motion` readers get the whole sentence.
- **Views and likes** — `[params.firebase]` plus `article.showViews` / `showLikes`, both
  overridable per post. Backed by Cloud Firestore through its **REST API, with no Firebase
  SDK**: several hundred kilobytes to increment an integer is not a trade worth making, and
  `fetch` is built in. Counts increment server-side in one transaction, so simultaneous readers
  both count. **This is the only feature in the theme that records what a reader does**, it
  renders nothing unless configured, and the docs say so plainly — including that the project id
  and API key are not secrets and that Firestore security rules are what actually protect the
  data. With JavaScript off nothing renders, rather than a zero pretending to be a count.
- **Zen mode** — `article.showZenMode` adds a control that hides the header, the table of
  contents rail and both footers, leaving the prose. Escape leaves, and the control itself
  survives the hiding: a mode with no visible way out is a trap. Not persisted, because zen is
  for one piece and remembering it would mean arriving at a site with its navigation gone.
- **`gist`** — a GitHub Gist fetched at build time and rendered as an ordinary code block, so
  the reader loads no GitHub script and the code gets this theme's own highlighting in both
  colour modes, which an embedded Gist does not.
- **`list.orderByWeight`** — sort the section index by weight instead of date. Replaces the date
  sort rather than blending with it; unweighted pages go last.
- **`footer.showMenu`** — the footer menu has always rendered; this is the switch. Default `true`.
- **`imagePosition`** — `object-position` for images that are genuinely cropped: the avatar and
  card thumbnails. It does nothing to a cover, deliberately, because covers are never cropped.
- **`disableImageOptimization`** — hand raster images to the browser unresized, for a site whose
  images are already optimised upstream. Honoured in all six partials that resize a cover.
- **`layoutBackgroundBlur`** and **`layoutBackgroundHeaderSpace`** — background treatments, both
  off by default. The blur is applied to the image rather than the block, so text over it stays
  sharp, and it is static rather than scroll-driven: repainting an image every frame is expensive
  for decoration.
- **Repository cards** — `github`, `gitlab`, `codeberg`, `gitea`, `forgejo`, `huggingface` and
  `ansible`, seven shortcodes over one fetch-and-render mechanism. The Gitea-family three take a
  `host` for a self-hosted instance.
  - **The reader fetches nothing.** Descriptions and counts are read during the build and baked
    into the HTML, so a card costs a visitor no third-party request. That is the whole reason
    this is a build-time fetch rather than a script.
  - **The build does fetch, and a failure is not fatal.** A card that cannot be fetched degrades
    to a plain link carrying the repository's name. Two failures are told apart deliberately: a
    **404** warns, and `make check` turns warnings into failures, so a renamed or deleted
    repository is caught in CI; being **offline** uses a suppressible log instead, because
    failing there would mean the theme could not be built without a network, which
    `docs/SPEC.md` §1 forbids. Verified by building with the container's network disabled.
  - Nothing is requested at all unless a page uses one of these, so a site that does not is
    entirely unaffected. Hugo caches the responses, so a rebuild does not re-fetch.
- **`enableLightbox`** — click a prose image to see it full size. Built on `<dialog>`, so the
  modal semantics, the backdrop, the focus trap and the Escape handler all come from the browser
  rather than from this theme; those four are what hand-rolled lightboxes get wrong. Focus
  returns to the image that opened it. An image that is already a link is left alone, since it
  has a destination the author chose. Off by default — the browser already offers "open image in
  new tab", and a lightbox with a bad focus trap is worse than none.
- **`header.layout`** — `fixed` keeps the header sticky, which is the current behaviour and
  therefore the default; `basic` lets it scroll away. The anchor offset follows the choice, so
  `basic` does not leave a gap above every heading it jumps to.
- **`list.cardView` and `taxonomy.cardView`** — the section index is a list and term pages are
  cards, which is what the approved design shows; each can now be switched to the other. Both
  defaults are unchanged. Year grouping does not apply to a card grid — a grid interrupted by
  full-width headings reads as several grids — so `cardView` wins over `groupByYear`.
- **`enableA11y`** — a control that underlines every link on the page. It is named for what it
  does rather than presented as an "accessibility mode": a control whose effect a reader cannot
  predict is not an accessibility feature. The reason it exists is WCAG 1.4.1 — a link
  distinguished from its text by colour alone is invisible to a reader who cannot separate those
  colours, and the theme's own faint prose rule does not extend to navigation, cards or footers.
  Off by default, since it overrides a deliberate design decision site-wide. Ships `hidden` and
  is revealed by its script, so a reader with no JavaScript is not shown a dead control.
- **Four more analytics providers** — Fathom, Umami (with optional self-hosted domain and
  renamed script for ad-block resilience) and Seline join Cloudflare as first-class config
  blocks, and **Google Analytics** is wired through Hugo's own template. All four of the first
  set cookies nothing and need no consent banner; GA does, and most sites using it will be
  obliged to say so, so it is there for completeness rather than preference.
  **Nothing is emitted unless a provider is configured**, which is still the shipped default and
  is now asserted against the built demo site. GA uses Hugo's `[services.googleAnalytics]` key
  rather than a theme param: Hugo owns that template and reads its own config, so a theme param
  would have been a second key that silently did nothing.
- **Three more colour palettes** — `plum`, `slate` and `rose`, taking the set to six. Each
  accent was **measured before it shipped**, against its own `--accent-tint` rather than the
  page background, which is the case that decided `clay`. Light mode: `plum` 4.82, `rose` 4.63,
  `slate` 4.54, against `periwinkle` 4.90, `sage` 4.17, `clay` 4.16. A fourth candidate measured
  4.40 — below every palette already shipped — and was dropped rather than tuned.
- **`defaultFeaturedImage`, `defaultSocialImage`** — site-wide image fallbacks, so a post with
  no cover of its own is still illustrated and still previews as a card when linked. A post with
  its own cover is unaffected. A configured-but-missing file renders nothing rather than a 404.
- **`taxonomy.showTermCount`** — the article count beside each term was already rendered; this
  adds the switch. Default `true`, so nothing changes for an existing site.
- **Multilingual sites.** Declare `[languages]` and the theme supplies the rest: a language
  switcher in the header, `hreflang` alternates including `x-default` in `<head>`, a search
  index per language, per-language date formats and menus. **The switcher links to the
  translation of the page you are on**, falling back to that language's home page only where no
  translation exists — being sent to the front page for asking to read the same article in
  another language is the single most common thing this control gets wrong. It renders nothing
  on a single-language site, so nothing changes for one. The switcher is a `<details>`
  disclosure, the same mechanism the nested menu uses, so it needs no JavaScript.
- **`article.heroStyle`** — four cover treatments: `basic` (the default, unchanged), `big`,
  `background` and `thumbAndBackground`, overridable per post. **Every one keeps the cover
  uncropped**, which is why this was previously ruled out: a background hero normally fills a
  band and crops to fit, and a Northlight cover has its title in the artwork. Here the box stays
  an exact 1200×630 with `object-fit: contain` and the header sits over a scrim, so the whole
  image is visible. Below 720px the header moves under the image rather than over it. An unknown
  value falls back to `basic`.
- **Maths**, rendered at build time. Hugo has KaTeX built in, so the theme ships **no maths
  library at all** — no JavaScript, no stylesheet, and none of the ~60 font files a client-side
  renderer needs. The equation is in the HTML the server sends, so it is there with scripting
  off, in a feed reader, and anywhere else that reads the page without executing it. Output is
  MathML, which browsers lay out natively. Needs
  `markup.goldmark.extensions.passthrough` enabled in **site** config, which is the site's
  decision — a site that wants no maths configures nothing and pays nothing. A malformed
  expression fails the build rather than rendering as raw LaTeX.
- **`chart`** — a chart drawn from Chart.js configuration given as JSON in the shortcode body.
  Vendored, self-hosted and loaded **only on pages that use it**, on the same terms as `mermaid`.
  The JSON is parsed at build time, so a syntax error fails the build with a position instead of
  rendering an empty rectangle. **`alt` is required and the build fails without it:** a `<canvas>`
  is a picture to anything that is not a sighted reader. The config reaches the browser on a
  `data-` attribute rather than in an inline script, so a strict Content-Security-Policy is
  unaffected. Colours come from the palette tokens, charts follow the colour mode, and the entry
  animation is dropped under `prefers-reduced-motion`.
- **`mermaid`** — diagrams written as text, rendered in the browser. **The library is loaded
  only on pages that contain a diagram**, gated on Hugo's own `.HasShortcode`, because mermaid is
  3.5MB — more than the rest of the theme's assets put together — and it never enters the shared
  bundle. It is **vendored under `assets/js/vendor/` and self-hosted**, not pulled from a CDN,
  since a CDN reference is a third-party request on page view. Fingerprinted and integrity-hashed
  like every other asset. With JavaScript off the reader gets the diagram's source in a code
  block, which for a flowchart is genuinely readable; the script replaces it in place. Diagrams
  follow the colour mode — mermaid bakes its palette into the SVG, so a mode change re-renders
  from the source, driven by the theme's existing `northlight:appearance` event.
  `assets/js/vendor/VENDOR.md` records what is vendored, at what version and under what licence,
  and the suite asserts every file there has a row.
- **Multiple authors** — `authors = ["alice", "bob"]` in front matter credits several people,
  resolved from one file per person in `data/authors/`. The byline names them all, with
  **`article.showAuthorsBadges`** linking each to an author page (register `author = "authors"`
  under `[taxonomies]`), and **`article.showAuthorBottom`** adds a fuller card at the foot with
  avatar, headline and links. **Backward compatible:** a post with no `authors` falls back to the
  single `[params.author]`, so an existing site renders what it always did. A key with no matching
  data file fails the build rather than dropping somebody's name from their own work.
- **Series** — `series` and `series_order` in front matter group a post into a multi-part piece,
  and each part gets a navigation block above its body: which part this is, how many there are,
  and a link to the rest. Needs `series = "series"` under `[taxonomies]`. A `<details>`, so it
  collapses with no JavaScript; **`article.seriesOpened`** sets whether it starts expanded, and
  collapsed is the default because the summary line already says which part you are on. The
  current part renders as text with `aria-current="page"` rather than as a link to itself.
  **`series_order` is required:** Hugo has nothing else to sort on, and a scrambled series is
  worse than none, so a post in a series without it fails the build. A one-post series renders
  nothing.
- **`author.bio`** — a paragraph, rendered as Markdown, on the `profile` home layout. `headline`
  says what you do in one line; this says who you are. Note that a TOML `"""` string keeps its
  indentation and Markdown reads four leading spaces as a code block, so the continuation lines
  have to sit flush left; the suite asserts the bio never renders as a `<pre>`.
- **`author.email`** and **`article.replyByEmail`** — a "reply by email" link at the foot of each
  post. The quiet alternative to a comment system: a `mailto:` with the post title prefilled as
  the subject, so no third party is contacted, no script loads, and it works with JavaScript off.
  Off by default, and renders nothing unless both the flag and an address are set, because a
  reply link with nowhere to reply to is worse than none.
- **`list.showSummary`** — on listings, fall back to a post's summary when it has no
  `description`. A `description` still always wins where one exists, since it is also the meta
  description and the feed entry. The summary is stripped of markup and truncated before it is
  printed, so an unclosed tag cannot leak formatting into the rest of the card. Off by default,
  because turning it on changes every listing on an existing site.
- **Nine more sharing providers**, taking `article.sharingLinks` from two to eleven: Mastodon,
  Bluesky, Hacker News, email, X, Facebook, Telegram, WhatsApp and Pinterest join LinkedIn and
  Reddit. They render in the order you list them. **Every one is a plain link** — no script, no
  SDK, no widget — so nothing is requested from any of these services until a reader clicks; that
  is why the list covers only services with a documented share URL.
  - **`article.mastodonInstance`** — new. Mastodon is federated, so there is no central host to
    share to. Rather than routing through a third-party instance picker, which would be a call to
    somebody else's server on every click, the site names the instance. Listing `mastodon` in
    `sharingLinks` without setting this fails the build rather than dropping the button silently.
  - `email` is the one entry that opens a mail client rather than a website, so it carries no
    `target="_blank"` — a `mailto:` opened in a new tab leaves an empty tab behind.
  - Nine icons added to the set: `mastodon`, `bluesky`, `hackernews`, `email`, `x`, `facebook`,
    `telegram`, `whatsapp`, `pinterest`. Icon names are a stable surface, so these are additive.

- **`video`** — a self-hosted video player, the local-file sibling of `youtube-lite`. Source and
  poster both resolve out of the page bundle or `assets/`, so a page carrying one makes no more
  third-party requests than a page carrying none. Takes `src`, `poster`, `caption`, `ratio`,
  `controls`, `loop`, `muted`, `preload` and `start`/`end` media fragments. The box is an exact
  `aspect-ratio`, so it reserves its space before any video arrives and a clip whose own ratio
  differs letterboxes rather than crops — no `object-fit` needed, since the HTML spec already
  requires that. **There is deliberately no `autoplay`:** CSS cannot stop playback, so honouring
  `prefers-reduced-motion` would take JavaScript, and an autoplay that ignores the reader's
  stated preference whenever scripting is off is not a promise this theme can keep. This closes
  the last unbuilt row of Part A in `docs/EXPANSION-PLAN.md`, which had been blocked on having a
  sample file to demonstrate it with.

### Fixed

- **A rate-limited forge no longer fails the build.** `resources.GetRemote` returns no resource
  for *any* non-2xx and exposes no status, so a deleted repository (404) and a rate-limited one
  (403) are indistinguishable — and GitHub allows sixty unauthenticated calls an hour. The first
  version hard-failed on both, which made the gate depend on someone else's rate limit and did go
  red with nothing wrong in the content. Both now warn under `repo-card-missing`, which a site
  can remove from `ignoreLogs` if it would rather a dead card broke CI.
- **An SVG cover no longer fails the build.** Hugo's `.Width` errors on an SVG rather than
  returning zero, and six partials read it unguarded — `related`, `card`, `post-item` and the
  `hero`, `gallery` and `stack` home layouts. A single vector cover took the whole build down.
  They now emit `width`/`height` only for rasters and let CSS hold the box, so nothing shifts as
  the image loads. Found because the new hero demo posts use SVG covers.
- **`make check` now refuses to run while a dev server is up**, which resolves the intermittent
  large-block failures that had been recorded in `BACKLOG.md` as an unexplained flake. `make
  serve` renders to disk, into the same `exampleSite/public` that `make check` builds and
  `tests/run.sh` reads. With a server running and any file being edited, the watcher rebuilds
  with `--buildDrafts` and a localhost baseURL while the gate rebuilds without them, and the
  suite reads whichever finished last. Measured at **4 failures in 8 runs** with a server up and
  a template being touched, against **0 in 55 runs** with no server — which is why it only ever
  appeared during active development and always went green on a retry. It was never a bind-mount
  race; host writes were separately confirmed visible to the container 5/5 at zero delay.
- **Social link labels no longer come from title-casing either.** The same bug as the sharing
  row, in the three places that render an author's social links: `aria-label="{{ $name | title }}"`
  announced "Linkedin" and "Github". All three now go through one `social-links.html` partial and
  resolve names from the catalogue, so the accessible name cannot drift between them again. The
  `shareName*` keys generalised to `serviceName*` and gained GitHub, RSS and Website; anything
  without an entry still falls back to title-casing, so adding an icon obliges nobody to add a
  string first.
- **Sharing link labels no longer come from title-casing the config key.** `{{ $name | title }}`
  rendered `linkedin` as "Linkedin", and would have rendered `hackernews` as "Hackernews". It was
  also a user-facing string built in a template, which makes it invisible to a translator. Service
  names are now `shareName*` keys in `i18n/en.toml`, on the same reasoning as `themeName`: proper
  nouns that most translations will leave alone but some need to transliterate. Each link also
  gained an `aria-label` ("Share on LinkedIn"), because the visible text is only the service name,
  which out of context reads as a link *to* that service rather than an action.
- **Table cells and the "next" pager now follow the text direction.** `.prose th`, `.prose td`
  and `.pager-next` used physical `text-align: left` / `right`, which ignores `dir`, so on a site
  running `rtl = true` — or inside the `rtl` shortcode — every table cell and the next-post link
  pinned themselves to the wrong edge while the surrounding block flipped. They now use the
  logical `start` / `end`, which is identical under LTR. **Visible change for RTL sites only**,
  and in the direction of correctness; LTR rendering is byte-identical.

### Changed

- `design/northlight.html`, the approved visual reference, now escapes the values its mock search
  interpolates into `innerHTML`, matching what `assets/js/search.js` has always done. The file is
  a local reference and is never served, so nothing shipped was affected, but an unescaped
  `innerHTML` in the artifact people read as the target reads as the pattern to copy.

## [0.3.0](https://github.com/mortennordbye/northlight/compare/v0.2.0...v0.3.0) (2026-07-28)

Shipped in [#18](https://github.com/mortennordbye/northlight/pull/18), [#20](https://github.com/mortennordbye/northlight/pull/20), [#22](https://github.com/mortennordbye/northlight/pull/22).

### Added

- **`footer.themeURL`** — links the theme name in the footer attribution. Unset, it renders as
  plain text, which is what the theme shipped with, so nothing changes for an existing site. The
  theme cannot default it to its own repository: that URL contains the author's name, and no file
  under `layouts/`, `assets/` or `static/` may carry an author-specific value. The `builtWith`
  string now takes both names as values (`.Hugo` and `.Theme`) rather than concatenating one in
  the template, so a translation controls the order of both, and the theme's name moves into its
  own `themeName` key where a translation can transliterate it.
- **Ten home page layouts**, selected by `home.layout`: `stack`, `page`, `profile`, `hero`,
  `card`, `background`, `split`, `gallery`, `archive` and `custom`. This reverses the earlier
  decision to ship one homepage; the reasoning is recorded as FLAG-6 in
  `docs/EXPANSION-PLAN.md`. **Not a breaking change:** `stack` is the arrangement the theme
  shipped with and is the default, and the refactor that moved it into a partial was verified
  to leave the rendered `<main>` byte-identical. `home.html` is now a dispatcher that gathers
  the post list once and hands it to the chosen partial, which is also what lets `custom`
  work without forking the theme. An unknown layout fails the build rather than falling back
  to the default and looking like the setting had no effect. `background` carries a flat scrim
  and fixed light-on-dark text in both colour modes, because the photograph behind it does not
  invert when the palette does.
- **`carousel`** — a horizontally scroll-snapping row of nested `figure` shortcodes. The plan
  listed this as a candidate to drop because it needs JavaScript and autoplay fights
  `prefers-reduced-motion`; CSS scroll-snap answers both. There is **no JavaScript and no
  autoplay at all**, so nothing owes the reader a pause control and there is no motion to
  suppress. The container is focusable and labelled, so keyboard and screen-reader access come
  from the scroll container itself.
- **`youtube-lite`** — a YouTube embed rendered as a facade: a poster image from your own site,
  a play badge and a plain link. **No Google host is contacted on page view**, which an ordinary
  embed cannot say. The poster must be local; pulling the still from `ytimg.com`, as most "lite"
  embeds do, is itself a third-party request and would defeat the point. With JavaScript off it
  stays a link to YouTube; with it on, a click swaps in a `youtube-nocookie.com` player in place.
- **`tabs` and `tab`** — tabbed panels, with an optional `group` so sets sharing a name switch
  together. **The served markup is not a tab strip**: it is a plain sequence of headed
  `<section>` elements with every panel visible, which is a complete document for a reader with
  scripting off. `assets/js/tabs.js` then upgrades it in place to a real tablist with
  `role="tablist"`, `aria-selected`, `aria-controls`, roving `tabindex` and arrow-key, Home and
  End navigation, hiding the headings only once the tab buttons carrying the same text exist.
  Built the other way round, a reader without JavaScript gets a stack of unlabelled boxes.
- **`gallery`** — a responsive grid of images, taking `cols` of 2 or 3. It has no image handling
  of its own: it grids whatever `figure` shortcodes are nested inside it, so a gallery image gets
  the same `srcset`, intrinsic dimensions, dark variants and captions as any other and there is
  no second code path. **Nothing is cropped** — the grid sizes columns and lets rows be as tall
  as their content, rather than forcing a uniform box with `object-fit: cover` the way image
  grids usually do, because a cover is 1200×630 with its title inside the artwork. There is a
  test asserting no `object-fit` declaration ever appears in the shortcode stylesheet.
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
