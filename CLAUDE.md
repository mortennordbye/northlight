# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**Northlight** is a Hugo theme. It is **open source and built for other people to use**, not a
private layer for one blog. That single fact drives most of the rules below: behaviour comes
from `site.Params` with sensible defaults, nothing about any particular author is hardcoded,
and every config key is documented and stable.

The theme replaces the one previously used on `blog.nordbye.it`. `docs/SPEC.md` is the audit of
what that blog actually uses — it is the requirements document, and it is deliberately a
*smaller* surface than what it replaces. Read it before adding anything.

The name refers to north light: the soft, even, neutral light from a north-facing window that
has no glare and stays consistent all day. That is the design brief in three words.

**Start here:** `docs/BUILD-PLAN.md` is the ordered, verifiable build plan. `docs/DESIGN.md` is
the token reference. `design/northlight.html` is the approved visual target — a single-file
mockup with the real content, both colour modes, and three palettes.

## Working approach

These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical changes

Touch only what you must. Clean up only your own mess.

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### Goal-driven execution

Define success criteria. Loop until verified.

Transform tasks into verifiable goals:
- "Add the TOC" → "Build exampleSite, confirm the TOC renders with the right nesting, then confirm it still renders when a post has no h2"
- "Fix the hero crop" → "Render a 1200×630 cover at 3 viewport widths, confirm zero crop at each"
- "Refactor X" → "Ensure `make check` passes before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### Track unfinished work in BACKLOG.md

If you leave anything unfinished, partially implemented, or explicitly defer it, add an entry to `BACKLOG.md` in the repo root before reporting the task done. Don't bury deferrals in chat — they vanish next session.

Each entry needs four things: **what** the work is, **why** it was deferred, **what would unblock it**, and **where** the relevant code lives (file paths). Read existing entries for the format.

Don't put work-in-progress on `BACKLOG.md` — WIP belongs on a branch. The backlog is for *known gaps the team has agreed to leave for later*. If you finish an item, delete it.

What counts as "unfinished":
- Tier 1 / Tier 2 splits where you only shipped Tier 1.
- Out-of-scope items you noticed but didn't fix.
- Features behind a feature flag that still need ramping or cleanup.
- Tests skipped, mocks left in, debug logging not yet stripped.
- TODO comments you wrote (write the entry instead — TODOs rot in code).

What does NOT belong:
- Forward-looking ideas the user didn't agree to defer ("we could also..."). Either do them or drop them.
- Codebase-wide debts that pre-existed your work and the user didn't ask you to track.

### No AI attribution in commits

Commits and PRs read as the human author's. No AI fingerprint, ever.

- No `Co-Authored-By` trailer naming Claude or any AI.
- No session links or IDs (e.g. a `Claude-Session:` trailer).
- No "Generated with Claude Code", 🤖 emoji, or similar tool signatures in commit messages, PR descriptions, or issue bodies.
- Describe the change, not the tool that produced it.

These guidelines are working if: fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Development

Everything runs through Docker. **Do not install Hugo, Node, or npm on the host** — the official
`ghcr.io/gohugoio/hugo` image is multi-arch, so it works on Apple silicon where the plain
`linux-amd64` Hugo tarball does not. It is pinned to an exact version rather than a floating tag,
so builds are reproducible and an upgrade is a reviewable one-line change. Bumping it means
bumping three places together: `HUGO_IMAGE` in the `Makefile`, `min_version` in `theme.toml`, and
"Requirements" in `README.md`.

```bash
make serve    # live-reload dev server on http://localhost:1313 (exampleSite + this theme)
make build    # production build of exampleSite into exampleSite/public
make check    # THE GATE — see "Before reporting a task complete"
make clean    # remove build output and Hugo caches
```

The theme is developed against `exampleSite/`, which doubles as the demo site and the
integration test. If a feature cannot be exercised from `exampleSite/`, add content there
until it can.

There is no Node toolchain and no CSS framework. CSS is hand-written with custom properties
and served through Hugo's asset pipeline. Keep it that way — it removes an entire class of
build breakage and keeps the theme installable with nothing but Hugo.

## Before reporting a task complete

```bash
make check
```

That runs, in order: `hugo --source exampleSite --themesDir ../.. --minify --gc` with warnings
treated as failures, then an HTML sanity pass over the output.

A green build is necessary but not sufficient. Hugo renders broken layouts happily, so for any
change that touches a template or CSS, also:

1. `make serve` and load the affected page.
2. Check it in **both** colour modes. Dark mode is not an afterthought here; a change that only
   looks right in light mode is not done.
3. Check one unrelated page for regressions.
4. State plainly in your report which pages you looked at and which you did not.

Skip the browser step for doc-only changes (`*.md`, `LICENSE`), and say that you skipped it.

## Security baseline

**Mostly not applicable, and here is why.** This is a static site theme. It has no server, no
auth, no database, no user input, and no network surface at runtime. A general security baseline
targets projects with a network or data surface; most of it has nothing to bite on here.

What does still apply:

- **No secrets, ever.** A theme is copied verbatim into other people's repos. No tokens, no
  analytics IDs, no author emails, no `nordbye.it` values in theme files. Those belong in the
  *site's* config, which is why `extend-head.html` exists as an escape hatch.
- **Treat content as untrusted when it comes from config.** Hugo escapes by default. Do not
  reach for `| safeHTML`, `| safeJS`, or `| safeCSS` on anything a site author controls unless
  you can state why it is safe. `markup.goldmark.renderer.unsafe` is enabled at the *site*
  level for raw HTML in posts — that is the site author's decision, not the theme's.
- **No third-party requests by default.** No CDN fonts, no remote scripts, no calls home. Fonts
  are self-hosted, everything is bundled through Hugo's pipeline. A theme that phones out
  imposes that on every user of it.
- **Subresource integrity stays on.** Assets are fingerprinted and integrity-hashed; see the
  cache rule under *Safety rules* below.

## Architecture

A Hugo theme, targeting **Hugo extended 0.164+**. No JavaScript framework, no CSS framework, no
build step beyond Hugo itself.

- **Templates** — Go templates under `layouts/`, using the template system Hugo introduced in
  0.146: page-level templates sit at the `layouts/` root (`baseof.html`, `home.html`, `page.html`,
  `section.html`, `taxonomy.html`, `term.html`), composable pieces in `layouts/_partials/`, render
  hooks in `layouts/_markup/`. There is no `_default/` directory and no `index.html`.
- **Styles** — hand-written CSS under `assets/css/`, concatenated, minified and fingerprinted by
  Hugo. Design tokens are CSS custom properties; see `docs/DESIGN.md`.
- **Scripts** — small vanilla-JS modules under `assets/js/`, bundled and deferred. Every one of
  them must be optional: the site works with JavaScript disabled, minus search.
- **Demo and test bed** — `exampleSite/`.
- **Distribution** — git submodule or Hugo Module, consumed as `theme = "northlight"`.

### Data flow rules

Config flows one way: `site.Params` → `_partials/init.html` (which resolves defaults once) →
templates. Templates read resolved values; they do not re-derive defaults inline.

Every param needs a default. The pattern is `site.Params.x | default "y"`, and page-level front
matter overrides site-level where that makes sense (`.Params.showToc | default site.Params.article.showToc`).
Never read a param that has not been documented in `README.md` and demonstrated in
`exampleSite/hugo.toml`.

### Safety rules for AI-assisted changes

These are the invariants specific to this project. Breaking one is a bug even if the build
passes.

- **Nothing about the author is hardcoded.** No `nordbye`, no `blog.nordbye.it`, no giscus repo
  IDs, no analytics tokens anywhere under `layouts/`, `assets/` or `static/`. If you need a
  value, add a param with a default and document it. `grep -ri nordbye layouts assets static`
  must return nothing.
- **Covers are never cropped.** Post covers are 1200×630 with the title baked into the artwork,
  so any crop destroys them. Hero and card images render in an exact `aspect-ratio: 1200/630`
  box. This is the single reason the previous theme needed a local override — do not
  reintroduce a fixed-height band with `object-cover`.
- **Chroma needs both modes.** Syntax highlighting uses CSS classes, not inline styles
  (`markup.highlight.noClasses = false`). Every token class must be styled for light *and* dark.
  A new token colour added to one mode and not the other is an incomplete change.
- **Asset fingerprinting is mandatory.** Sites cache CSS and JS as immutable for a year on the
  strength of the hash in the filename. Removing `resources.Fingerprint` turns that into a
  year-long stale-asset bug on every site using the theme.
- **Renaming a param is a breaking change.** Once published, config keys are API. Add new keys;
  do not rename or repurpose existing ones without a major version bump and a note in the
  changelog.
- **The escape hatches stay.** `_partials/extend-head.html` and `_partials/comments.html` are how
  site authors inject their own analytics and comment systems without forking. Keep them
  overridable and keep them documented.
- **No feature without a home in `exampleSite/`.** If it is not demonstrated there, it is not
  finished and it is not documented. See the checklist below — "demonstrated" now also means a
  section in the docs site.
- **No user-facing string in a template.** Everything a reader can see comes from `i18n/en.toml`.
  A hardcoded string is invisible to translators and cannot be found by grepping the catalogue.

### Shipping a feature: the checklist

The demo site is also the manual, so a feature is not done when it works. Work through all of
this before reporting it complete. Every step exists because skipping it has produced a bug or a
gap at some point.

1. **Default resolved once.** Add the param to `_partials/init.html`, never `| default` inline in
   a template. Booleans go through `_partials/param-bool.html`, because `| default true` silently
   flips an explicit `false`.
2. **Strings into `i18n/en.toml`.** Anything a reader sees. Plurals use `one`/`other` rather than
   a conditional in a template. Keep the pluralised `[table]` entries at the *bottom* of the file:
   in TOML a bare key after a table header joins that table, and the build fails with "reserved
   keys mixed with unreserved keys".
   - A string that only exists *after a click* cannot be rendered into the markup. Add it to the
     JSON block in `baseof.html` and read it via `t("key", "English fallback")`. Always pass the
     fallback.
3. **Demonstrate it in `exampleSite/`.** Config in `hugo.toml` (commented out if it would send
   data to a third party), and content if the feature is content-shaped.
4. **Document it in the docs site**, on the page it belongs to under
   `exampleSite/content/docs/`: getting-started, configuration, writing, appearance, integrations
   or translating. The docs are built by the theme, so write the page such that it *demonstrates*
   what it describes rather than only describing it.
5. **`README.md` config reference.** One row: key, default, what it changes.
6. **`CHANGELOG.md`** under Unreleased, in the right subsection. Say what breaks, if anything.
7. **`docs/FEATURE-SURVEY.md`.** Update the row's status. If you decided *not* to build
   something, mark it Rejected with the reason rather than leaving it as an open candidate.
8. **Add a case to `tests/run.sh`** for whatever the feature guarantees, then break the thing on
   purpose and confirm the suite goes red. An assertion that cannot fail reads as coverage and is
   worse than none.
9. **Verify.** `make check`, then the page in **both** colour modes, then one unrelated page for
   regressions. Say plainly which pages you looked at and which you did not.

A feature that changes anything visual also needs measuring rather than eyeballing: contrast in
both modes, and no horizontal overflow at 375px.

### Environment variables

Not applicable. A Hugo theme has no runtime environment and reads no secrets. Configuration is
`site.Params`, documented in `README.md`. If you find yourself wanting an env var, you are
solving the wrong problem — surface it as a param instead.

### Directory layout

```
.
├── CLAUDE.md              # this file
├── README.md              # public docs: install + full config reference
├── BACKLOG.md             # known gaps deliberately left for later
├── theme.toml             # Hugo theme gallery metadata
├── Makefile               # every workflow, containerised
├── docs/
│   ├── SPEC.md            # what the theme must do, from the audit of the previous theme
│   ├── BUILD-PLAN.md      # ordered build phases with verification steps
│   ├── DESIGN.md          # design tokens: type, colour, spacing, motion
│   ├── FEATURE-SURVEY.md  # candidate features, with status and rejections
│   └── AUTOMATION.md      # CI, the quality audit, branch protection, releases
├── design/
│   ├── northlight.html    # the approved visual target (single file, self-contained)
│   └── explorations/      # ten rejected directions, kept for context
├── layouts/               # the theme itself
├── assets/{css,js}/       # hand-written CSS and vanilla JS
├── static/                # files copied verbatim
└── exampleSite/           # demo site and integration test
```

### Key patterns

- **Partials take a dict, not a page.** Anything reusable is called as
  `partial "x.html" (dict "ctx" . "size" "sm")` so it can be composed. Page-only partials may
  take `.` directly.
- **One resolve point for defaults.** `_partials/init.html` runs once per site and stashes
  resolved config in `site.Store`. Templates read from there rather than repeating
  `| default` chains.
- **Tokens live in one file.** All colour, spacing and type tokens are custom properties in
  `assets/css/tokens.css`. Component CSS references `var(--x)` and never hardcodes a hex value.
  Adding a palette means adding one block there, nothing else.
- **Progressive enhancement.** Search, the scroll-spy TOC, code-copy, the theme toggle and the
  reading-progress bar are all JS. Each degrades to something sane: the TOC is still a list of
  links, code is still selectable, and the theme falls back to `prefers-color-scheme`.
- **No emoji in the UI.** Icons are inline SVG from a single set, sized by `em`.
- **No layout shift.** Every image declares its aspect ratio. Fonts load with `font-display: swap`
  and a matched fallback metric.

### Code quality

- **Reuse before adding** — check `layouts/_partials/` before writing a new one; the theme is
  small on purpose.
- **Prefer Hugo's built-ins** — `.TableOfContents`, `.Summary`, `.ReadingTime`, `.WordCount`,
  `resources.*`, and the embedded opengraph/twitter templates, which are now called as
  `{{ partial "opengraph.html" . }}` — the `_internal/` prefix was removed in Hugo 0.146. Do not
  hand-roll what Hugo ships.
- **Use current, supported versions** — target a recent Hugo extended release and say which
  minimum you support in `theme.toml`.
- **No dead code** — a partial nothing calls, a param nothing reads, or a CSS class nothing
  uses should be deleted, not left "for later".
- **No premature abstractions** — extract a partial when it is used in 2+ places, not before.
  The audit in `docs/SPEC.md` found two-thirds of the previous theme unused; that is the failure
  mode to avoid.
