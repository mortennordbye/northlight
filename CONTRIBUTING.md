# Contributing to Northlight

Northlight is a Hugo theme built for other people to use. That single fact drives most of the
rules below: behaviour comes from `site.Params` with sensible defaults, nothing about any
particular author is hardcoded, and every config key is documented and stable.

`docs/SPEC.md` is the requirements document. `docs/DESIGN.md` is the token reference.
`design/northlight.html` is the approved visual target — a single self-contained mockup with both
colour modes and all three palettes.

`docs/AUTOMATION.md` explains the machinery around all of that: which workflows run and when,
which checks are required, how the quality audit is configured, and how a release is cut. Read it
before changing anything under `.github/`, and when a pull request behaves in a way that looks
broken but is not.

## Development

Everything runs through Docker. **Do not install Hugo, Node or npm on the host** — the official
Hugo image is multi-arch, so it works on Apple silicon where the plain `linux-amd64` tarball does
not.

```bash
make serve    # live-reload dev server on http://localhost:1313
make build    # production build of exampleSite
make check    # THE GATE — build, then run the test suite
make test     # the test suite alone, against the current build
make clean    # remove build output and caches
```

`make check` bind-mounts this directory into the container. If your Docker daemon cannot see it —
`DOCKER_HOST` pointing at another machine, or a daemon in its own VM without the repo on a shared
path — the mount lands on an empty directory and the build fails with `failed to open dir
/src/northlight/exampleSite`. `make check-remote` is the same gate for that case: same pinned
image, same flags, same suite, with the source sent over the daemon socket instead of mounted.
Prefer `make check` wherever it works.

The theme is developed against `exampleSite/`, which doubles as the demo site and the integration
test. If a feature cannot be exercised from `exampleSite/`, add content there until it can.

There is no Node toolchain and no CSS framework. CSS is hand-written with custom properties and
served through Hugo's asset pipeline. Keep it that way — it removes an entire class of build
breakage and keeps the theme installable with nothing but Hugo.

## Before opening a pull request

```bash
make check     # build with warnings as errors, then run the suite
make test      # the suite alone, against the current build
```

`make check` builds with warnings treated as errors and then runs `tests/run.sh`, which is
the same suite CI runs before deploying.

It is POSIX `sh` and the tools any Unix already has. This theme has no Node toolchain and no
package manager, and a test suite that reintroduced one would undo the main thing the build is
protecting. `python3` is used only to validate JSON and XML, and those cases skip rather than
fail when it is absent.

The suite asserts what a green build does not: that the output is fingerprinted and
integrity-hashed, that feeds and the sitemap parse and contain the right things, that covers are
never cropped, that syntax and admonition colours exist in both modes, that every custom property
and every i18n key resolves, that no user-facing string is hardcoded, and that the script bundle
declares no bare globals.

When you add a case, check that it can actually fail. Break the thing on purpose and confirm the
suite goes red before you commit it. An assertion that cannot fail is worse than none, because it
reads as coverage. Two of the original cases were wrong in exactly this way: one matched
`northlight.min.css` as though it carried a content hash, and one hardcoded the demo's own
hostname so it would have failed only in CI.

The suite still does not replace looking at the page. Hugo renders broken layouts happily and
nothing here opens a browser, so for any change touching a template or CSS, also:

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
  finished and it is not documented. See the checklist below: "demonstrated" also means a section
  in the docs site.
- **No user-facing string in a template.** Everything a reader can see comes from `i18n/en.toml`.
  A hardcoded string is invisible to translators and cannot be found by grepping the catalogue.

## Shipping a feature

The demo site is also the manual, so a feature is not done when it works. `exampleSite/content/docs/`
builds the documentation you can read at the demo URL, which means a change to the theme and a
change to its documentation are the same pull request.

Work through all of this. Every step is here because skipping it has produced a bug or a gap at
some point.

1. **Resolve the default once.** Add the param to `_partials/init.html` rather than writing
   `| default` inline in a template. Booleans go through `_partials/param-bool.html`, because
   `| default true` silently flips an explicit `false` back to true.
2. **Put strings in `i18n/en.toml`.** Anything a reader sees. Plurals use `one`/`other` rather than
   a conditional in a template, so languages whose plural rules differ from English need no
   template changes. Keep the pluralised `[table]` entries at the **bottom** of the file: in TOML a
   bare key after a table header joins that table, and the build fails with "reserved keys mixed
   with unreserved keys".
   - A string that only exists **after a click** cannot be rendered into the markup. Add it to the
     JSON block in `baseof.html` and read it with `t("key", "English fallback")`. Always pass the
     fallback, so a missing catalogue leaves working buttons rather than blank ones.
3. **Demonstrate it in `exampleSite/`.** Config in `hugo.toml`, commented out if switching it on
   would send data to a third party, plus content if the feature is content-shaped.
4. **Document it in the docs site**, on the page it belongs to under `exampleSite/content/docs/`:
   getting-started, configuration, writing, appearance, integrations or translating. Those pages
   are built by the theme, so write yours so that it *demonstrates* what it describes rather than
   only describing it.
5. **Add a `README.md` row**: key, default, what it changes.
6. **Add a `CHANGELOG.md` entry** under Unreleased, in the right subsection. Say what breaks, if
   anything.
7. **Update `docs/FEATURE-SURVEY.md`.** Set the row's status. If you decided *not* to build
   something, mark it Rejected with the reason rather than leaving it as an open candidate.
8. **Add a case to `tests/run.sh`** for whatever the feature guarantees. Then break the thing on
   purpose and confirm the suite goes red before you commit it.
9. **Verify**, and say in the PR what you actually checked.

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
