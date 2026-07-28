# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

Empty is the correct state for this file.

---

## Open

### `author.imageQuality` is not implemented

**What.** `bio` and `email` landed as part of the author-fields row in `docs/GAP-LIST.md`.
`imageQuality` did not.

**Why deferred.** The avatar does not go through Hugo's image pipeline at all.
`_partials/image-url.html` resolves a configured path to a URL and returns it untouched,
deliberately: it has to pass an SVG through, and `exampleSite/` uses `profile.svg`. A quality
setting only means something once raster avatars are routed through `.Resize`, which changes
what that partial is for, needs a raster avatar in `exampleSite/` to be exercised, and needs the
SVG path to keep working alongside it. That is a separate change with its own verification, not
a parameter.

**What unblocks it.** Deciding that the avatar should be processed. Then: branch `image-url.html`
on media type, resize rasters at the configured quality, pass SVG through as now, add a raster
avatar to `exampleSite/` so both branches are exercised, and assert both.

**Where.** `layouts/_partials/image-url.html`; callers are `_partials/home/intro.html` and
`_partials/home/profile.html`. Row 3 in `docs/GAP-LIST.md`.

---

### Physical properties other than `text-align` are still an RTL risk

**What.** `text-align: left|right` is gone from the CSS and `tests/run.sh` refuses to let it back
in. The same class of bug remains in the properties nothing is watching: about twenty declarations
of `margin-left`/`right`, `padding-left`/`right`, `border-left`/`right`, bare `left:`/`right:` and
`float`, spread over `article.css` (6), `prose.css` (5), `interaction.css` (4), `chroma.css` (3),
`list.css` (1) and `layout.css` (1). Each is a candidate to pin something to the wrong edge under
`dir="rtl"`, exactly as the table cells did.

**Why deferred.** Not the same job as the fix that was asked for. The `text-align` change was
three declarations with an obvious logical equivalent and no consequence under LTR; this is
roughly twenty, several load-bearing for spacing rather than direction. Converting them wholesale
with no RTL page to check against would be changing rendering by inference, which is how the
original bug got in.

**What unblocks it.** An RTL page in `exampleSite/` to measure against — the `rtl` shortcode
exercises a paragraph, but no table, code block, pager or sidebar. Build that first, then convert
per property with a measurement each, widening the existing assertion as each one lands. One
sweeping `logical-properties` commit is the wrong shape.

**Where.** `assets/css/`, the six files above. The existing guard and its reasoning are in
`tests/run.sh`, beside the gallery's never-crop check. `docs/FEATURE-SURVEY.md` records RTL as
Partial for this reason.

---

## Closed

Kept as a short record so the same questions are not reopened from scratch.

| Was | Outcome |
|---|---|
| Config reference in README was a placeholder | Written. Every param, default and effect, plus front matter and covers. |
| `--fg-3` failed AA for small text | Fixed in phase 7: `#6e6e75` / `#868690`, measured. |
| Accent contrast was hand-computed | Measured across 3 palettes × 2 modes × 6 pages. Clay's light tone darkened to `#b1523d`. |
| Font fallback had no matched metrics | Fixed — and the real cause turned out to be the `ch` measure. Layout shift on font swap went 88px → 0px. |
| Theme distribution undecided | Both routes documented; submodule recommended because it needs no Go toolchain. |
| Highlighted line had a seam under line numbers | Fixed: the gutter moved onto `.lnt`, inside `.hl`. Measured gap is now 0px. |
| OpenGraph `article:tag` was title-cased | Fixed: `opengraph.html` and `twitter_cards.html` are now the theme's own, using `.Data.Term`. |
| Search was substring-only with no ranking | Fixed: field-weighted scoring, and every term must match. Still no library, still no dependency. |
| Draft labels unbuilt | Built, with a draft post in `exampleSite/` to exercise it. |
| Cover art duplicates the post title | Not a bug. Documented in `README.md` under Covers, with `showHero = false` as the per-post escape. |
| Intermittent `make check` failures | **Cause found: `make serve` was running.** It renders to disk, into the same `exampleSite/public` that `check` builds and `tests/run.sh` reads. With a server up and any file being edited, the watcher rebuilds with `--buildDrafts` and a localhost baseURL while the gate rebuilds without them, and the suite reads whichever finished last. Reproduced at 4 failures in 8 runs; 0 in 55 runs with no server. Never a bind-mount race — host writes were confirmed visible to the container 5/5 at zero delay. `make check` now refuses to run while a server is up. |
| `v0.1.0` not tagged | Tagged. |
| `design/northlight.html` reinterpreted DOM text as HTML | Fixed. The mockup's mock search escapes what it interpolates, matching `assets/js/search.js`. Nothing shipped was affected — the file is a local reference and is never served — but an unescaped `innerHTML` in the artifact people read as the target reads as the pattern to copy. |
| The `video` shortcode had no sample file | Built. The blocker was "no encoder on the host", and the answer was the rule the repo already lives by: run it in a container. A one-off `linuxserver/ffmpeg` produced an 8s, 116KB clip, which was then decoded frame by frame and watched playing in a browser before being committed, so "a sample nobody has watched play" stopped applying. |
| Table cells did not follow the text direction | Fixed. `prose.css` and `article.css` use logical `start`/`end`, verified by measurement: cell text moves from the left edge to the right edge when the block flips, and LTR rendering is unchanged. `tests/run.sh` refuses any physical `text-align`. The wider sweep it belongs to is the Open entry above. |

### Deliberately not built

These were the Tier 2 list in `docs/SPEC.md`.

> **Series, card views and maths have since been reopened.** `docs/GAP-LIST.md` is the current
> build order and puts them back in scope, so the reasoning below is history rather than policy —
> worth reading for what the objection was, not as a decision still standing. Each entry gets
> deleted from this list in the commit that builds it. Video autoplay is the one that still holds,
> because its objection is that the promise cannot be kept, not that the feature is unwanted.

- **Series taxonomy.** Configured on the site Northlight replaces, used by zero posts there. This
  theme exists because an audit found two thirds of the previous one to be unused surface; adding
  an unused taxonomy would repeat exactly that mistake. Build it when a post needs it.
- **Card-view variants for the post index.** The index is a list with covers and term pages use
  cards, which is what the approved design shows. A switch between the two is configuration nobody
  asked for.
- **Math passthrough.** Enabled and unused on the reference blog. It is site config
  (`markup.goldmark.extensions.passthrough`) plus a KaTeX or MathJax script, both of which belong
  in `extend-head.html` rather than in a theme that would otherwise load a maths renderer for
  every site using it.
- **Autoplay on the `video` shortcode.** CSS cannot stop playback, so `prefers-reduced-motion`
  could only be honoured with JavaScript, and with scripting off the theme would autoplay straight
  past a reader who asked it not to. An opt-in that silently fails is worse than an absent
  parameter. `tests/run.sh` asserts the parameter stays absent. See `docs/EXPANSION-PLAN.md` §A4.
