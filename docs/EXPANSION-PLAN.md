# Expansion plan

An ordered, checkbox-tracked build list drawn from a survey of the feature surface offered by
mature, widely-used Hugo blog themes, filtered down to what Northlight can carry without
breaking its own rules.

**This document is the progress record.** Each item is a checkbox, each checkbox is one branch,
one feature, one commit. If work stops partway through, this file says exactly what shipped and
what did not. Update the box *in the same commit as the feature*, never after.

`docs/FEATURE-SURVEY.md` is the wider menu and stays the record of what was considered and
rejected. This file is the subset that is actually being built, with an order.

---

## Read this first: open decisions

Items flagged here changed something a previous decision had settled, or ran into a question with
no obvious answer. They are resolved as stated so the work can proceed unattended; each says what
was assumed and what it would cost to reverse.

### FLAG-1 — This reverses "shortcodes are out of scope" · **decided: build them**

`docs/SPEC.md` §5 records that the blog Northlight replaces used **zero** shortcodes, and
`docs/FEATURE-SURVEY.md` §8 puts the whole category out of scope on two arguments: shortcodes are
theme-specific syntax that locks content to the theme, and the audit that produced this theme
found two-thirds of the previous one unused.

Both arguments still hold on their own terms. Building the list below deliberately overrides them.

**Decided by the owner, 2026-07-27:** build the shortcodes, and correct the documents that say
otherwise rather than leaving them contradicting the code. That means, as each item lands, its row
in `docs/FEATURE-SURVEY.md` §8 flips from out-of-scope to **Have**, and the scope note in
`docs/SPEC.md` §5 gains a line recording that the audit finding (the previous blog used no
shortcodes) is still true but no longer decides the question, because the theme is published for
other people whose content is not that blog's.

Reasoning behind the reversal: reach for adopters now outweighs the theme-lock argument.
Northlight is published for other people to use, and a shortcode surface is one of the things
adopters compare on.

**Mitigation applied throughout:** nothing below removes or degrades a plain-Markdown path. Every
shortcode is additive. Where a render hook already covers the ground (admonitions, images), the
render hook stays the documented default and the shortcode is the escape hatch, not the
replacement.

**To reverse:** delete `layouts/_shortcodes/`, the shortcode CSS/JS, and the docs page. No
existing template depends on any of it — that is a deliberate constraint on the build order.

### FLAG-2 — No shortcode may call the network at build time · resolved, no action needed

`docs/SPEC.md` §1 requires the theme to build with no network access. That rules out the entire
family of live repository/statistics cards the reference themes ship (six different git forges,
plus package-registry and model-hub cards), the remote code importer, and the remote Markdown
importer. All of them fetch a third-party API during `hugo build`.

**Resolved as:** not built. Listed under *Not building* with the reason. This is the single
largest cut from the surveyed list — roughly nine shortcodes — and it is not a matter of effort.

### FLAG-3 — Three shortcodes need a third-party script · deferred, see Part C

Charts, diagrams and typewriter effects each need a rendering library that would be fetched or
bundled. The security baseline in `CLAUDE.md` forbids third-party requests by default, and
bundling a large renderer for a feature most pages never use fails the same test.

**Resolved as:** not built; `extend-head.html` remains the supported route, which is the decision
already recorded for maths rendering in `BACKLOG.md`. If the owner wants one of these in-theme,
diagrams-as-text is the one with the strongest claim for a technical blog.

### FLAG-4 — Video and lite YouTube embeds are borderline · built, privacy-preserving form only

A local-file video shortcode is self-contained and fine. A YouTube embed is by definition a
third-party request. It is built in the **facade** form only: a static thumbnail plus a play
button, with *no* contact with any third-party host until the reader clicks. Nothing loads on
page view. If even that is unacceptable, delete the one file — nothing else references it.

### FLAG-5 — An icon shortcode exposes the theme's icon set as content API · built, accepted

`_partials/icon.html` is currently internal. A shortcode makes the icon names a public, stable
surface — renaming one becomes a breaking change under the rule in `CLAUDE.md`. Accepted because
the set is small and stable, but it is a commitment, not a free feature.

---

## Ground rules

Every item below is subject to the shipping checklist in `CONTRIBUTING.md`. Restated in short
form, because these are the steps that get skipped:

1. Defaults resolved once in `_partials/init.html`; booleans via `_partials/param-bool.html`.
2. Every reader-visible string in `i18n/en.toml`. Post-click strings go through the JSON block in
   `baseof.html` with an English fallback.
3. Demonstrated in `exampleSite/` — config *and* content.
4. Documented on the right page under `exampleSite/content/docs/`, demonstrating rather than
   describing.
5. `README.md` reference row.
6. `CHANGELOG.md` entry under Unreleased.
7. `docs/FEATURE-SURVEY.md` row updated — §8 in particular, which currently lists most of Part A
   as out of scope.
8. A case in `tests/run.sh`, verified to go red when the feature is broken on purpose.
9. Build gate green.

Plus the invariants that shortcodes are most likely to break:

- **Tokens only.** Shortcode CSS references `var(--x)` from `assets/css/tokens.css`. No hex
  values, no new colours that exist in one mode only.
- **Both modes.** A shortcode styled for light mode alone is an incomplete change.
- **No JavaScript dependency.** Anything with JS degrades to readable HTML with JS off.
- **No emoji.** Icons are inline SVG through `_partials/icon.html`.
- **No horizontal overflow at 375px.** Tabs, tables, timelines and galleries are the usual
  offenders.
- **Escaping.** Shortcode parameters are author-controlled content. Do not reach for `safeHTML`
  on a parameter without being able to say why it is safe.

### Working method per item

```
git switch -c <branch>            # from an up-to-date main
<build the feature + all 9 checklist steps>
make check                        # or check-remote; iterate until green
git add -A && git commit          # one commit, describing the change
git switch main && git merge --ff-only <branch>
```

Everything stays local. **No `git push`, no remote branches, no pull requests, no tags.** The gate
runs locally on each branch; CI is never triggered. Branches are kept after merging, so each
feature stays individually reviewable and revertable.

Commits describe the change and nothing else — no tool attribution of any kind, per `CLAUDE.md`.

**On the gate.** `make check` bind-mounts this directory into the pinned Hugo container. Where the
Docker daemon cannot see the directory — `DOCKER_HOST` pointing at another machine, or a daemon in
its own VM — that mount lands on an empty directory and the build fails before it starts. `make
check-remote` is the same gate for that case: same pinned image, same flags, same `tests/run.sh`,
with the source sent over the daemon socket instead of mounted. Use `check` wherever it works.

---

## Status legend

| Box | Meaning |
|---|---|
| `[ ]` | Not started |
| `[~]` | Started, not finished — the note says where it stopped and which branch holds it |
| `[x]` | Shipped: built, demonstrated, documented, tested, gate green, merged to `main` |
| `[-]` | Dropped during the work — the note says why |

---

## Part A — Shortcodes

Ordered cheapest-and-safest first, so that stopping at any point leaves the most value merged.
Each is independent; none depends on an earlier one except where stated.

### A1 · Presentational primitives

No JavaScript, no new dependencies, small CSS.

- [x] **`lead`** — sets an introductory paragraph in larger, lighter type. Wraps inner Markdown.
      Branch `feat/shortcode-lead`. Smallest possible first item; use it to prove the
      `layouts/_shortcodes/` directory, the shortcode CSS entry point and the docs page all work
      before anything harder lands.
- [x] **`badge`** — small inline pill for metadata. Inner text. Branch `feat/shortcode-badge`.
- [ ] **`keyword` / `keywordList`** — a wrapping row of labelled pills, optionally with an icon.
      Container plus item. Depends on A1 `badge` for its CSS foundation and on A2 `icon` for the
      optional icon. Branch `feat/shortcode-keywords`.
- [x] **`swatches`** — renders colour chips from hex values. Takes up to three positional
      parameters in the surveyed themes; build it variadic instead, there is no reason for the
      limit. Branch `feat/shortcode-swatches`. Genuinely useful in a theme whose docs are about
      design tokens.
- [x] **`button`** — styled call-to-action link. Parameters: `href`, `pageRef`, `target`, `rel`.
      Must set `rel="noopener"` when `target="_blank"`, and must not accept raw HTML.
      Branch `feat/shortcode-button`.
- [x] **`email`** — obfuscated `mailto:` link. Parameters: `email`, `text`, `subject`. Obfuscation
      is build-time, not JS, so it survives with scripting off. Branch `feat/shortcode-email`.
- [ ] **`ltr` / `rtl`** — direction override for a block. Two tiny files. Relevant because the
      theme's RTL support is the row most likely to be wrong (`docs/FEATURE-SURVEY.md` §7).
      Branch `feat/shortcode-direction`.

### A2 · Reusing what the theme already has

These wrap existing partials, so they are mostly plumbing and docs.

- [ ] **`icon`** — exposes `_partials/icon.html` to content, sized in `em` to match surrounding
      text. See FLAG-5. Branch `feat/shortcode-icon`.
- [ ] **`article`** — embeds a single post as a card, given a path. Reuses `_partials/card.html`.
      Must fail loudly on an unresolvable path rather than rendering an empty card.
      Branch `feat/shortcode-article`.
- [ ] **`list`** — embeds N recent posts, optionally filtered by a taxonomy term. Reuses
      `_partials/post-item.html`. Parameters: `limit`, `title`, `where`, `value`.
      Branch `feat/shortcode-list`.
- [ ] **`figure`** — image with caption, link and alt, going through the same Hugo image pipeline
      as `_markup/render-image.html` so it gets identical intrinsic dimensions, `srcset` and lazy
      loading. **Must not crop** — the 1200×630 invariant in `CLAUDE.md` applies here too.
      Branch `feat/shortcode-figure`. Note: the Markdown image render hook stays the documented
      default; this exists for the cases Markdown syntax cannot express (a linked figure, a
      class).
- [ ] **`alert`** — callout box. Branch `feat/shortcode-alert`. **Check before building:**
      admonitions already ship as a render hook over GitHub `> [!NOTE]` syntax, with five types
      and colours in both modes. If this is only a second syntax for the same thing, it is not
      worth the surface — build it as a thin wrapper that reuses the admonition CSS and accepts a
      custom icon, or drop it and say so here.

### A3 · Layout components (CSS-driven, JS-optional)

- [ ] **`timeline` / `timelineItem`** — vertical timeline. Container plus item, item parameters
      `header`, `subheader`, `badge`, `icon`. Pure CSS. Watch the 375px width.
      Branch `feat/shortcode-timeline`.
- [ ] **`accordion` / `accordionItem`** — collapsible panels built on `<details>`/`<summary>`, so
      they work with JS disabled and are keyboard-accessible for free. The `mode` (single vs
      multiple open) behaviour is the only part needing JS, and it degrades to multiple-open.
      Branch `feat/shortcode-accordion`.
- [ ] **`gallery`** — responsive image grid. Reuse the image pipeline; every image needs its
      aspect ratio declared, per the no-layout-shift rule. Branch `feat/shortcode-gallery`.
- [ ] **`tabs` / `tab`** — tabbed panels. Needs real ARIA (`role="tablist"`, arrow-key
      navigation, `aria-selected`) and must render all panels as sequential headed sections with
      JS off. Optional `group` syncs tabs across a page. Branch `feat/shortcode-tabs`.
      The most accessibility-sensitive item in Part A — do not ship a `<div>` soup version.
- [ ] **`carousel`** — sliding image viewer. Branch `feat/shortcode-carousel`.
      **Lowest priority in Part A, and a candidate to drop.** It needs JS, autoplay is hostile to
      `prefers-reduced-motion`, and a gallery covers most of the same ground without the motion.
      Build it last; dropping it costs nothing.

### A4 · Media

- [ ] **`video`** — local or self-hosted video, with `poster`, `caption`, `ratio`, `controls`,
      `loop`, `muted`, `preload`, `start`/`end` fragments. No third-party contact. Autoplay must
      be opt-in *and* must respect `prefers-reduced-motion`. Branch `feat/shortcode-video`.
- [ ] **`youtube-lite`** — facade embed: static thumbnail plus play button, no third-party request
      until the reader clicks. See FLAG-4. The thumbnail must be a local file supplied by the
      author, not fetched from the video host, or the facade is pointless.
      Branch `feat/shortcode-youtube-lite`.

---

## Part B — Configuration and feature gaps

Not shortcodes. These come from diffing the theme's parameter surface against the surveyed
themes, keeping only rows where the gap is real and the feature fits.

Several of these already sit in `docs/FEATURE-SURVEY.md` as Gap or Partial rows; building one
means flipping that row to **Have** in the same commit.

- [ ] **More sharing providers.** Currently LinkedIn and Reddit; the surveyed themes offer around
      eleven. Add the ones with a plain URL scheme and no script: Mastodon, Bluesky, Hacker News,
      email, X, Facebook, Telegram, WhatsApp, Pocket. Each is a URL template and an icon; the
      whole set is one commit. `sharingLinks` already exists as an ordered list, so this is
      additive and breaks nothing. Branch `feat/share-providers`.
- [ ] **`extend-head-uncached.html`.** The uncached twin of the existing head hook, for anything
      that must not be fingerprinted into the cached bundle. One partial, one call site, one docs
      paragraph. Branch `feat/extend-head-uncached`.
- [ ] **Custom icons from the site repo.** Let a site drop SVGs in its own `assets/icons/` and
      have `_partials/icon.html` find them, falling back to the theme's set. Makes the icon
      shortcode (A2) genuinely useful to adopters. Branch `feat/custom-icons`.
- [ ] **Reply by email.** An article-footer link that opens a pre-filled reply, subject set to the
      post title. Needs `author.email`, off unless set. Branch `feat/reply-by-email`.
- [ ] **Configurable meta description fallback order.** Currently a fixed chain; make the order a
      param. Small, and it closes a Partial row. Branch `feat/meta-description-order`.
- [ ] **`taxonomy.showTermCount`.** Post count beside each term on taxonomy pages, on by default.
      Branch `feat/term-count`.
- [ ] **`article.invertPagination`.** Whether prev/next follow reading order or chronology. One
      boolean, one conditional. Branch `feat/invert-pagination`.
- [ ] **External links open in a new tab.** A param on the link render hook, with `rel="noopener
      noreferrer"` applied whenever it is on. Default **off** — forcing new tabs overrides the
      reader's choice, so this is opt-in even though the surveyed themes default it on. Note the
      deviation in the docs. Branch `feat/external-link-target`.
- [ ] **`highlightCurrentMenuArea`.** Marks the active top-level menu entry via `aria-current`,
      styled rather than invented. Check first whether `header.html` already does this — if it
      does, tick this box as already satisfied and say so. Branch `feat/menu-active-state`.
- [ ] **Feed ownership tags.** Verification tags for feed-reader platforms, alongside the existing
      `[params.verification]` block. Two params, two meta tags. Branch `feat/feed-verification`.
- [ ] **`sitemap.excludedKinds` as a param.** Currently hardcoded to exclude taxonomy and term
      pages. Make it configurable, keeping today's behaviour as the default.
      Branch `feat/sitemap-excluded-kinds`.

---

## Part C — Not building

Recorded so the same questions are not reopened from scratch. Each of these appears in the
surveyed themes and is deliberately absent here.

| Feature | Reason |
|---|---|
| Live cards for repositories, package registries and model hubs (~9 shortcodes) | Each calls a third-party API during the build. `docs/SPEC.md` §1 requires the theme to build with no network access. See FLAG-2. |
| Remote code importer, remote Markdown importer | Same: network at build time. |
| Embedded gists | Loads a third-party script on page view. The code-fence path with a filename bar already covers the use case locally. |
| Charts | Needs a charting library on every page that has one. See FLAG-3. |
| Diagrams as text | Same. The strongest candidate of the three if this is reopened. |
| Typewriter effect | An animation library for decoration, and it fights `prefers-reduced-motion`. |
| Maths rendering | Already decided — see `BACKLOG.md`. Site config plus a renderer in `extend-head.html`. |
| View and like counters | Adds a hosted backend to a static site. Already rejected in `docs/FEATURE-SURVEY.md` §6. |
| Donation widget, ad units | Third-party scripts, and not a theme's job. |
| Additional analytics vendors | `extend-head.html` is the supported route. A theme should not ship five vendors. |
| Multiple authors, author taxonomy, author badges | Single-author theme by design. `docs/FEATURE-SURVEY.md` §2. |
| Series taxonomy | Decision recorded in `BACKLOG.md`. Build it when a post needs it. |
| Homepage layout variants, hero style variants, header layout variants, card/list switches | One considered choice each, matching `design/northlight.html`. `docs/FEATURE-SURVEY.md` §3. |
| Image zoom / lightbox | JS weight for a gesture the browser already offers. |
| Zen mode | The layout is already the focus mode. |
| Browser language redirect | Client-side redirects on a static site. |
| Accessibility toggle button | The theme should meet the bar without a toggle; a switch implies the default is worse. |
| Configurable fingerprint algorithm | sha512 everywhere. A param here only creates ways to get it wrong. |

---

## Progress log

Appended as work completes — newest last. One line per merged feature: branch, what shipped, and
anything the next session needs to know. Deviations from the plan above are recorded here, not
silently.

- **`feat/shortcode-lead`** — `lead`, plus the surface every later item builds on: the
  `layouts/_shortcodes/` directory, a **Shortcodes** page in the docs site at weight 4 (which
  pushed appearance/integrations/translating down one each), a **Shortcodes** group in
  `tests/run.sh`, and a README section. `docs/SPEC.md` §5 and `docs/FEATURE-SURVEY.md` §8 were
  corrected per FLAG-1 rather than left contradicting the code.

  No CSS was added: `lead` emits the existing `.lede` class, which is exactly the treatment a
  post's `description` already gets. `assets/css/shortcodes.css` therefore does not exist yet —
  create it with the first item that genuinely needs it, and wire it into the `$sheets` slice in
  `_partials/head.html` *before* the `custom.css` append, so a site's own stylesheet still wins
  on source order.

  Worth knowing for the next items:
  - A missing or misspelled shortcode **fails the build** — Hugo does not leave the call in the
    output as text. So no assertion is needed for that, and one written for it would be an
    assertion that cannot fail.
  - Showing a call in a code fence needs the escaped form `{{</*/* … */*/>}}`. Without it Hugo
    executes the call inside the fence, the example vanishes from the docs, and the build stays
    green. `tests/run.sh` asserts on the literal text for exactly this reason — it is the one
    documentation mistake nothing else catches.
  - The sitemap assertion counts docs pages. Adding another docs page means bumping it.

- **`fix/link-hook-trailing-space`** — not on the plan; found while writing the page above. The
  link render hook ended with a newline after `</a>`, and whitespace between inline elements
  collapses to a visible space, so every sentence ending on a link rendered as "see the docs ."
  The theme's own appearance page showed it. Fixed, with a test that scans the whole build.

- **`feat/shortcode-badge`** — `badge`, plus `assets/css/shortcodes.css` and its wiring into the
  `$sheets` slice in `_partials/head.html`.

  **Every inline shortcode must end with a whitespace-trimming comment.** `badge` shipped the
  same trailing-newline bug as the link hook above, in its first draft, and it rendered as
  "badge ." at the end of a sentence. The test from that fix was broadened to cover `span`,
  `code`, `em`, `strong` and the rest, so it now catches this for any inline shortcode — but the
  cheaper fix is to write the trim in from the start:

  ```
  <span class="badge">…</span>
  {{- /* comment, trimming both sides */ -}}
  ```

  Also worth knowing: `.Page.RenderString` defaults to inline, which is what an inline shortcode
  wants. Passing `(dict "display" "block")` wraps the inner content in a `<p>` and breaks the
  line box.

- **`feat/shortcode-button`** — `button`, reusing the existing `.button`. Two things generalise
  to every later item:

  **A shortcode that reuses a chrome class needs a `.prose` override.** `.prose a` is two classes
  to `.button`'s one, so inside content the button came out accent-coloured and underlined — it
  looked like a link, which defeats having both. `assets/css/shortcodes.css` now carries
  `.prose a.button`. Anything reused from `article.css` inside prose will hit this.

  **Validate parameters with `errorf`, and guard the follow-on checks.** `errorf` logs and
  carries on rather than stopping, so an unresolvable `pageRef` also tripped the separate
  "pageRef or href is required" check and reported two errors for one mistake. Guard later checks
  on the earlier input being absent. All three failure paths — unresolvable `pageRef`, neither
  parameter, both parameters — were confirmed to fail the build.

  Author-supplied URLs are **not** passed through `safeURL`. Go's templates sanitise URLs in an
  `href`, which neutralises `javascript:`; `safeURL` would switch that off. `render-link.html`
  does use `safeURL`, which is a separate and older decision about Markdown links.

- **`feat/shortcode-email`** — `email`. Two deviations from the plan, both deliberate.

  **The work is on a pushed branch and a pull request, not local-only.** The "Working method"
  section above says everything stays local with no remote branches; that was overridden by the
  owner from `feat/shortcodes` onward. Treat the PR flow as current and that paragraph as stale.

  **Obfuscation is percent-encoding, not HTML entities.** Entities are the obvious choice and do
  not work, which cost three iterations to pin down. This is the thing to know before writing any
  shortcode that tries to keep a string out of the output:

  > **Hugo's minifier decodes numeric HTML entities — in attributes *and* in text.** Whatever you
  > encode as `&#121;` lands in `public/` as `y`. `safeHTMLAttr` on the whole attribute does not
  > help; the minifier decodes inside attributes too and emits `href=mailto:you@example.com`.

  The `href` is therefore percent-encoded character by character, which is URL syntax rather than
  markup and so passes through untouched. The link text cannot be — it is text, not a URL — so
  the `@` and the dots are each preceded by an empty `<span>`. That defeats a pattern match
  across the tag boundary while contributing nothing to text content, leaving copy and paste
  intact.

  Also worth knowing for later items:

  - **A "this string is absent" assertion cannot be scoped to a whole documentation page.** The
    first version grepped the page for the plain address and could never pass, because the page
    documents the shortcode and its code fences necessarily show the address as an author types
    it. The check is now scoped to the rendered anchors — split on `<a`, keep the `mailto:` ones,
    cut each at its own `</a>`, since anchors cannot nest. Any later shortcode whose guarantee is
    *absence* will hit the same problem on its own docs page.
  - **Guard a refute on having found anything.** A "no match" assertion over an empty extraction
    passes for the wrong reason and reads as coverage. The email case fails loudly if no `mailto:`
    link is found at all.

- **`feat/shortcode-swatches`** — `swatches`, variadic rather than capped at three. Each chip is
  labelled with its own hex value in visible text, because a bare block of colour carries its
  meaning in the colour alone, which is the one thing a screen reader, a greyscale print and a
  colourblind reader all lose.

  **Do not reach for `safeCSS` on a value going into a `style` attribute.** The first draft used
  it, with a confident comment explaining why the regex above made it safe. Both the comment and
  the `safeCSS` were wrong, and this generalises to every later item that interpolates an author
  parameter into an attribute — `figure`, `gallery` and `video` all will:

  > Go's contextual escaper already guards a `style` attribute, and guards it well. A hex value
  > passes through untouched; a value carrying a semicolon, a `url()` or an `expression()` is
  > replaced wholesale with `ZgotmplZ`. Adding `safeCSS` **switches that off**, leaving whatever
  > validation the template happens to do as the only defence. The built-in is stronger than one
  > we maintain, and it is free.

  Verified by probing: with no `safeCSS` and no validation,
  `red;background-image:url(https://evil.example/x.png)` and `expression(alert(1))` both came out
  as `ZgotmplZ`, while a plain hex came out intact.

  So the regex stayed, but its job changed from safety to **diagnostics**. The escaper's failure
  mode is silent — a mistyped colour becomes `ZgotmplZ`, which renders as a chip with no colour,
  on a green build, on a page nobody re-reads. Validating first turns that into a build failure
  naming the value and its position. `tests/run.sh` also refutes `ZgotmplZ` across the page, which
  catches any *future* shortcode that silently loses a value this way.

  The lesson for the checklist: when a template reaches for a `safe*` function, first check
  whether the escaper was going to do the right thing anyway. Usually it was.
