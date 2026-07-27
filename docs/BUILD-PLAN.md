# Build plan

Ordered phases for building Northlight from an empty `layouts/`. Each phase has a goal, the
work, and a verification step that must pass before moving on. Work the phases in order —
later ones assume earlier ones exist.

**Before you start, read in this order:** `CONTRIBUTING.md`, then `docs/SPEC.md` (what the theme must
do), then `docs/DESIGN.md` (the tokens), then open `design/northlight.html` in a browser and
click through all three views in both colour modes. That mockup is the approved target. When
this plan and the mockup disagree, the mockup wins for *visuals* and this plan wins for
*structure*.

**The single most underestimated item in this build is Chroma syntax highlighting in both
colour modes** (phase 2). The reference blog is 71 code fences across 7 languages. Get it wrong
and the theme looks unfinished no matter how good the rest is.

---

## Phase 0 — Toolchain and skeleton

**Goal:** `make serve` renders a blank-but-valid site.

- `Makefile` with `serve`, `build`, `check`, `clean`, all wrapped in `docker run` against
  `ghcr.io/gohugoio/hugo:v0.164.0` (multi-arch — the plain amd64 Hugo tarball fails on Apple
  silicon). The repo mounts at `/src/northlight`, because Hugo resolves `--themesDir` relative
  to `--source`.
- `theme.toml` with name, licence, min Hugo version, tags, author.
- `LICENSE` — MIT.
- `.gitignore` — `public/`, `resources/`, `.hugo_build.lock`, `exampleSite/public/`.
- `exampleSite/` with `hugo.toml`, one section `content/blog/`, and `content/_index.md`.
- `layouts/baseof.html` rendering nothing but `{{ block "main" . }}{{ end }}`, plus a stub per
  page kind (`home`, `page`, `section`, `taxonomy`, `term`, `404`) so `--panicOnWarning` has no
  missing-layout warning to trip on, and a stub `home.json` so `make check`'s file assertions
  pass from the first commit.

**Verify:** `make serve` starts, `http://localhost:1313` returns 200 with an empty body and no
template errors in the console.

**Note on structure:** this theme uses the template system Hugo introduced in 0.146. Templates
live at the `layouts/` root, not in `_default/`; partials are `_partials/`; render hooks are
`_markup/`; the home page is `home.html`, not `index.html`. Filenames below reflect that.

---

## Phase 1 — Design tokens and base CSS

**Goal:** the token layer exists and both colour modes are switchable.

- `assets/css/tokens.css` — every custom property from `docs/DESIGN.md`: the three palettes,
  both modes, spacing scale, type scale, radii, motion durations.
- `assets/css/base.css` — reset, `body` type, headings, links, focus rings, `::selection`,
  scrollbars.
- `assets/js/appearance.js` — the render-blocking inline script that sets `data-theme` on
  `<html>` before first paint. **This must run before the stylesheet applies or every page
  load flashes.** Reads `localStorage`, falls back to `prefers-color-scheme`.
- Wire the pipeline in `_partials/head.html`: concat → minify → fingerprint (sha512) → integrity.

**Verify:** a page with a coloured background and text switches cleanly between modes with no
flash on reload, in both light-first and dark-first system settings. `curl` the CSS URL and
confirm the filename contains a hash.

---

## Phase 2 — Chroma, both modes

**Goal:** code blocks look finished.

- `assets/css/chroma.css` — every Chroma token class styled for light and dark, driven by the
  tokens from `docs/DESIGN.md`.
- Cover at minimum the languages the reference blog uses: `yaml` (36 fences), `bash` (35),
  `text`, `nginx`, `hcl`, `dockerfile`, `alloy`.
- `markup.highlight.noClasses = false` in `exampleSite/hugo.toml`.

**Scope, measured rather than guessed:** Chroma emits **68 distinct token classes**.
`docs/DESIGN.md` names five. Get the full inventory mechanically rather than by eye:

```bash
docker run --rm ghcr.io/gohugoio/hugo:v0.164.0 gen chromastyles --style=github --mode=light
docker run --rm ghcr.io/gohugoio/hugo:v0.164.0 gen chromastyles --style=github-dark --mode=dark --modeSelector
```

`--mode` and `--modeSelector` are new in Hugo 0.164 and generate light/dark pairs directly.
Use the generated files as the *class checklist*, not as the stylesheet — the colours must come
from the design tokens. Note `--modeSelector` scopes under `.dark`, while this theme keys off
`html[data-theme="dark"]`, so the selectors need rewriting either way.

**Verify:** put one fence of each language into an exampleSite post. Render in both modes.
Every token must be legible; comments in particular must not drop below 4.5:1 against the code
background. No token may be unstyled (falling back to body colour).

---

## Phase 3 — The article page

**Goal:** a post renders completely. This is 90% of the theme's value — the reference blog is
six posts, and readers spend their time here.

- `layouts/page.html` and the partials it needs: breadcrumbs, article meta (date,
  author, reading time, word count), hero cover, prose wrapper, tags, share links, prev/next,
  related, comments hook.
- Render hooks in `layouts/_markup/`: `render-heading.html` (adds the `id` and the hover anchor link) and
  `render-link.html` (external links get `rel="noopener"` and a target rule).
- `_partials/extend-head.html` as an empty, overridable escape hatch.
- `_partials/comments.html` — giscus, driven entirely by params.

**Verify:** an exampleSite post with a cover, 4 heading levels, code, a blockquote, a list, and
raw-HTML `<img style="width:70%">` renders correctly in both modes. **Specifically confirm the
1200×630 cover is uncropped at 1440px, 900px and 375px viewport widths** — this is the bug that
forced a local override in the previous theme.

---

## Phase 4 — Home, list, taxonomy

**Goal:** every route in `docs/SPEC.md` §3 resolves.

- `layouts/home.html` — intro block, featured post, recent cards.
- `layouts/section.html` — the post index, grouped by year, with covers.
- `layouts/taxonomy.html` and `layouts/term.html` — `/tags/` and `/tags/<tag>/`.
- `layouts/404.html`.
- Pagination.

**Verify:** every URL in the SPEC route table returns 200 and renders. Add a seventh dummy post
to exampleSite and confirm pagination appears and works.

---

## Phase 5 — Output formats

**Goal:** the non-HTML outputs are correct.

- `layouts/home.rss.xml`, `sitemap.xml` (excluding `taxonomy` and `term` kinds),
  `home.json` (the search index).
- `enableRobotsTXT` on; confirm `robots.txt` is generated.
- Head metadata: title pattern, description, canonical, OpenGraph, Twitter cards, favicons,
  JSON-LD. Use Hugo's embedded opengraph and twitter templates rather than hand-rolling — called as
  `{{ partial "opengraph.html" . }}` since 0.146 removed the `_internal/` prefix.

**Verify:** `/index.xml` parses as valid RSS. `/index.json` parses as valid JSON and contains
one entry per post. `/sitemap.xml` contains no `/tags/` URLs. Paste a post URL into a social
card validator, or at minimum confirm `og:image` resolves to an absolute URL.

---

## Phase 6 — Interaction

**Goal:** the features that make it feel finished. All are JS; all degrade.

Build in this order, verifying each before the next:

1. **Appearance toggle** — button wired to the phase-1 script, persisted.
2. **Code copy** — button per block, "Copied" feedback, uses the Clipboard API.
3. **Scroll-spy TOC** — `IntersectionObserver` on the rendered headings. Sticky on desktop,
   collapses into the flow on mobile.
4. **Reading progress** — 2px bar, scroll-linked.
5. **Back to top** — appears past 600px.
6. **Search** — the ⌘K modal. Fetches `/index.json`, filters client-side, keyboard navigable
   (↑↓ to move, ↵ to open, Esc to close), shows cover thumbnails. Fuse.js is optional; for six
   posts a substring match is enough and saves a dependency. Decide, and say which you chose.

**Verify:** each feature works, then **disable JavaScript entirely and reload**. The page must
still be readable and navigable: TOC is a plain list of working links, code is selectable, the
theme falls back to `prefers-color-scheme`. Only search may disappear.

---

## Phase 7 — Responsive, accessibility, motion

**Goal:** it holds up outside a 1440px desktop.

- Test at 1440, 1024, 768, 375. No horizontal scroll at any width.
- Tables, code blocks and wide media scroll inside their own container, never the body.
- Keyboard: tab through a full page. Focus visible everywhere, focus order matches visual order.
- Skip-to-content link.
- `prefers-reduced-motion` disables transitions and the progress bar animation.
- Check contrast in both modes with a real tool, not by eye. Body text ≥ 4.5:1, large text ≥ 3:1.

**Verify:** a keyboard-only pass through home → index → article → search with nothing
unreachable, and a contrast report with no failures.

---

## Phase 8 — Make it a public theme

**Goal:** a stranger can install and configure it without reading the source.

- `README.md` — install (submodule and Hugo Module), a **complete config reference** with every
  param, its default and what it does, and a screenshot of both modes.
- `exampleSite/` demonstrates every feature and every param. If it is not in exampleSite, it is
  not finished.
- `theme.toml` complete; `images/screenshot.png` and `images/tn.png` at the sizes the Hugo
  gallery requires.
- `CHANGELOG.md`, and tag `v0.1.0`.
- Fill in `BACKLOG.md` with whatever you deliberately left out.

**Verify:** in a scratch directory, create a brand-new Hugo site, add Northlight as a submodule,
copy `exampleSite/hugo.toml`, add one post, and build. It must work with no edits to the theme.
That test is the whole point of the phase — run it for real, do not reason about it.

---

## Do not build

The audit in `docs/SPEC.md` found roughly two-thirds of the previous theme unused by the site this
replaces. Adding it back "because a theme should have it" is the main way this project fails.

Out of scope unless explicitly asked: shortcodes of any kind, view/like counters, multilingual
and i18n, KaTeX, Mermaid, charts, galleries, carousels, image zoom, an authors taxonomy,
contributors, sponsors, ad slots, analytics providers beyond the `extend-head` hook, alternate
header layouts, alternate homepage layouts, or more than one hero style.

Series taxonomy, card-view variants and `groupByYear` are configured on the old site but
unexercised — treat them as Tier 2 and leave them until asked.

---

## Working notes

- Commit per phase, not per file. Each commit should leave `make check` green.
- When you finish a phase, say which verification steps you actually ran and which you did not.
  "Built and it compiled" is not verification for anything visual.
- If a phase turns out to be wrong — the plan was written before any code existed — say so and
  propose the change rather than silently diverging.
