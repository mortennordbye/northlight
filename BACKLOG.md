# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

Empty is the correct state for this file. Everything that was in it at the end of the initial
build was either fixed or turned into a decision recorded where the decision lives — see *Closed*
below for what happened to each.

---

## Open

### `design/northlight.html` reinterprets DOM text as HTML

**What.** CodeQL reports `js/xss-through-dom` (high) at `design/northlight.html:774`. The mockup's
search box interpolates `q.value` straight into `innerHTML` without escaping.

**Why deferred.** It is the approved visual target, not shipped code. Nothing under `layouts/`,
`assets/` or `static/` is affected, and the file is opened as a local reference rather than
served. The shipped implementation is not affected: `assets/js/search.js` escapes every
interpolated value, which is why CodeQL flags only the mockup. Editing the approved reference
artifact is also not something to do casually.

**What unblocks it.** A decision that changing the mockup is acceptable. The fix is to escape
`q.value` in the empty-state branch and the post fields in the results branch, matching what
`assets/js/search.js` already does.

**Where.** `design/northlight.html:768-775`; compare `assets/js/search.js:82-95`.

---

### The bind-mount build race is not as mitigated as *Closed* claims

**What.** `make check` intermittently reports a large block of failures — 18, 22, 33, 39 and 40
in separate runs on 2026-07-28 — where an immediately repeated run with no change is green. The
signature is a stale or partial `exampleSite/public`, not a real regression. It happened roughly
one run in four while the shortcode work was going on.

**Why this entry exists.** The *Closed* table below records this as "Mitigated and held: 0
failures in 62 cold container-side builds". That measurement was of cold builds. What is failing
now is the warm, repeated `make check` loop during active development, which the sampling did
not cover, so the row is not wrong so much as measuring something else.

**Why deferred.** It is a build-environment flake rather than a defect in the theme, every
observed occurrence was resolved by re-running, and chasing it would have stopped the feature
work. It is recorded because a red gate that goes green on retry teaches people to re-run
instead of reading failures, which is how a real regression eventually gets waved through.

**What unblocks it.** Sampling the warm loop rather than cold builds: run `make check` in a loop
against an unchanged tree and count. If it reproduces, the likely fixes are removing
`exampleSite/public` before each build so a partial write cannot be read as a complete one, or
using `make check-remote`, which ships the source over the daemon socket and does not bind-mount
at all.

**Where.** `Makefile`, the `RUN` variable and the `check` target; `tests/run.sh` reads
`exampleSite/public`.

---

### The `video` shortcode has no sample file to be demonstrated with

**What.** `video` is the last unbuilt row of Part A in `docs/EXPANSION-PLAN.md`. The template
work is straightforward — a `<video>` with `poster`, `caption`, `controls`, `loop`, `muted`,
`preload` and a `ratio` box — but the theme's own rule is that a feature is not finished until
`exampleSite/` demonstrates it, and demonstrating a video player needs a video file.

**Why deferred.** There is no encoder on the build machine (no `ffmpeg`), and hand-assembling
an MP4 byte by byte would put a binary into the repository that nobody has watched play. A
sample that turns out to be corrupt is worse than no sample: it demonstrates a broken feature
and the test suite cannot tell the difference.

**What unblocks it.** A small, freely-licensed sample video committed to
`exampleSite/content/docs/shortcodes/` — a few seconds, a few hundred kilobytes, MP4/H.264 for
the widest support. Then build the shortcode against it. Note the deliberate decision to make
alongside it: **autoplay cannot respect `prefers-reduced-motion` without JavaScript**, since CSS
cannot stop playback, so the options are to omit autoplay entirely (recommended, and consistent
with the theme refusing to promise what it cannot deliver with scripting off) or to accept a
JavaScript guard that does nothing when scripting is off.

**Where.** `docs/EXPANSION-PLAN.md` Part A §A4; the sibling `youtube-lite` shortcode is at
`layouts/_shortcodes/youtube-lite.html` and shows the poster and aspect-ratio handling to match.

---

### Table cells do not follow the text direction

**What.** `.prose th, .prose td` sets `text-align: left` outright, so cells stay left-aligned
inside a right-to-left context instead of following it. Measured in the browser: a `<td>` inside
a `dir="rtl"` block computes to `text-align: left`. This affects the site-wide `rtl = true`
param as much as the new `rtl` shortcode — every table on an RTL site is aligned the wrong way.

**Why deferred.** It is a pre-existing bug in the prose stylesheet rather than part of the
shortcode being added, and it changes rendering for any site already running `rtl = true`. That
makes it someone's decision rather than a drive-by edit inside a shortcode commit.

**What unblocks it.** Agreement that the change is wanted. The fix is one word — `left` becomes
`start`, the logical equivalent, which is identical under LTR and correct under RTL. The same
question applies to `article.css:313` (`text-align: right`) and `article.css:415`, which should
probably become `end` and `start` for the same reason. Worth a test asserting no physical
`text-align` survives in prose, so it cannot creep back.

**Where.** `assets/css/prose.css:290-295`; also `assets/css/article.css:313` and `:415`.

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
| Bind-mount build race | Mitigated and held: 0 failures in 62 cold container-side builds across three sampling runs. The explanation lives in the `Makefile`, beside the code that depends on it. |
| `v0.1.0` not tagged | Tagged. |

### Deliberately not built

These were the Tier 2 list in `docs/SPEC.md`. They are not deferred work — they are decisions, and
reopening one needs a reason that did not exist when it was made.

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
