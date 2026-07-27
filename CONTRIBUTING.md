# Contributing to Northlight

Northlight is a Hugo theme built for other people to use. That single fact drives most of the
rules below: behaviour comes from `site.Params` with sensible defaults, nothing about any
particular author is hardcoded, and every config key is documented and stable.

`docs/SPEC.md` is the requirements document. `docs/DESIGN.md` is the token reference.
`design/northlight.html` is the approved visual target — a single self-contained mockup with both
colour modes and all three palettes.

## Development

Everything runs through Docker. **Do not install Hugo, Node or npm on the host** — the official
Hugo image is multi-arch, so it works on Apple silicon where the plain `linux-amd64` tarball does
not.

```bash
make serve    # live-reload dev server on http://localhost:1313
make build    # production build of exampleSite
make check    # THE GATE — see below
make clean    # remove build output and caches
```

The theme is developed against `exampleSite/`, which doubles as the demo site and the integration
test. If a feature cannot be exercised from `exampleSite/`, add content there until it can.

There is no Node toolchain and no CSS framework. CSS is hand-written with custom properties and
served through Hugo's asset pipeline. Keep it that way — it removes an entire class of build
breakage and keeps the theme installable with nothing but Hugo.

## Before opening a pull request

```bash
make check
```

That builds with warnings treated as errors, then sanity-checks the output. A green build is
necessary but not sufficient — Hugo renders broken layouts happily. For any change touching a
template or CSS, also:

1. `make serve` and load the affected page.
2. Check it in **both** colour modes. A change that only looks right in light mode is not done.
3. Check one unrelated page for regressions.
4. Say in the PR which pages you looked at and which you did not.

Doc-only changes can skip the browser step. Say that you skipped it.

## Invariants

These are specific to this project. Breaking one is a bug even if the build passes.

- **Covers are never cropped.** Post covers are 1200×630 with the title baked into the artwork, so
  any crop destroys them. They render in an exact `aspect-ratio: 1200/630` box with
  `object-fit: contain`. Do not reintroduce a fixed-height band with `object-fit: cover`.
- **Chroma needs both modes.** Syntax highlighting uses CSS classes, not inline styles. All 84
  Chroma classes are styled, and every token is verified at 4.5:1 or better against the code
  background in both modes. A colour added to one mode and not the other is an incomplete change.
- **Asset fingerprinting is mandatory.** Sites cache CSS and JS as immutable for a year on the
  strength of the hash in the filename. Removing `resources.Fingerprint` turns that into a
  year-long stale-asset bug on every site using the theme.
- **Nothing about the author is hardcoded.** No personal domains, analytics tokens or comment
  system IDs anywhere under `layouts/`, `assets/` or `static/`. If you need a value, add a param
  with a default and document it. `make check` enforces this.
- **Renaming a param is a breaking change.** Once published, config keys are API. Add new keys; do
  not rename or repurpose existing ones without a major version bump and a changelog note.
- **The escape hatches stay.** `_partials/extend-head.html` and `_partials/comments.html` are how
  site authors inject analytics and comment systems without forking. Keep them overridable and
  documented.
- **No feature without a home in `exampleSite/`.** If it is not demonstrated there, it is not
  finished and it is not documented.

## Architecture

Targets **Hugo extended 0.164+**. No JavaScript framework, no CSS framework, no build step beyond
Hugo itself.

- **Templates** — Go templates under `layouts/`, using the template system Hugo introduced in
  0.146: page-level templates at the `layouts/` root, composable pieces in `layouts/_partials/`,
  render hooks in `layouts/_markup/`. There is no `_default/` directory and no `index.html`.
- **Styles** — hand-written CSS under `assets/css/`, concatenated, minified and fingerprinted by
  Hugo. Design tokens are custom properties; see `docs/DESIGN.md`.
- **Scripts** — small vanilla-JS modules under `assets/js/`, bundled and deferred. Every one is
  optional: the site works with JavaScript disabled, minus search.

### Config flows one way

`site.Params` → `_partials/init.html` (which resolves defaults once) → templates. Templates read
resolved values; they do not re-derive defaults inline.

Every param needs a default, and page-level front matter overrides site-level where that makes
sense. Booleans go through `_partials/param-bool.html` — `| default true` is wrong for a boolean,
because `false` is a zero value and `default` would silently flip an explicit `false` back to true.

Never read a param that is not documented in `README.md` and demonstrated in
`exampleSite/hugo.toml`.

### Patterns

- **Partials take a dict** when they have options: `partial "x.html" (dict "ctx" . "size" "sm")`.
  Page-only partials with no options may take `.` directly.
- **Tokens live in one file.** All colour, spacing and type tokens are custom properties in
  `assets/css/tokens.css`. Component CSS references `var(--x)` and never hardcodes a hex value.
  Adding a palette means adding one block there and nothing else.
- **Mode switching** uses `color-scheme` plus `light-dark()`. Each mode-dependent colour is
  declared twice: a plain light value, then `light-dark()` carrying both. A dark value is never
  written in two places, and a no-JS page follows the system with no extra CSS.
- **Progressive enhancement.** Search, the scroll-spy TOC, code copy, the appearance toggle and
  the progress bar are all JS. Controls that need JavaScript ship with `hidden` and are revealed
  by their own script, so a reader without JS sees no dead affordances.
- **No emoji in the UI.** Icons are inline SVG from a single set in `_partials/icon.html`, sized
  by `em`.
- **No layout shift.** Every image declares its aspect ratio. Fonts are self-hosted with
  metric-matched fallbacks, and the prose measure is a fixed length rather than `ch` — `ch`
  depends on the current font and reflows the column when a webfont swaps in.

### Code quality

- **Reuse before adding** — check `layouts/_partials/` before writing a new one. The theme is
  small on purpose.
- **Prefer Hugo's built-ins** — `.TableOfContents`, `.Summary`, `.ReadingTime`, `.WordCount`,
  `resources.*`. Do not hand-roll what Hugo ships, unless you can say why, in a comment, in the
  file that does it.
- **No dead code** — a partial nothing calls, a param nothing reads, or a CSS class nothing uses
  should be deleted, not left "for later".
- **No premature abstraction** — extract a partial when it is used in two places, not before. The
  audit in `docs/SPEC.md` found two thirds of the previous theme unused; that is the failure mode
  to avoid.

## Scope

`BACKLOG.md` records anything deliberately left undone, and the "Deliberately not built" section
records what was considered and rejected, with reasons. Read it before proposing a feature — the
answer may already be there.
