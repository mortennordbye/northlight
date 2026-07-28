# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

Empty is the correct state for this file.

---

## Open

### `list.cardView` is not exercised anywhere in `exampleSite`

**What.** The param is read by `section.html` and documented, but no page in the demo turns it
on, so the card branch of `section.html` is never built by `make check`. Nothing in
`tests/run.sh` or `tests/structure.py` can see that path.

**Why deferred.** The obvious fix — set `list.cardView = true` in `exampleSite/hugo.toml` —
changes the post index from the row list with covers to a card grid for the whole demo. The row
list is a deliberate design decision and the docs describe it, so flipping it to gain test
coverage trades the wrong thing. The alternative, a per-section override so one section could use
cards, is new config surface added to serve a test, which is worse.

This is not hypothetical: it is why the section index shipped with cards skipping `h1` to `h3`
through 0.4.0. That bug is fixed and now has a source assertion in `tests/run.sh`, but a source
assertion is the weaker kind and the underlying gap is still here.

**What unblocks it.** A decision on one of: accept a card grid as the demo's post index; add a
second content section to the demo whose only purpose is to demonstrate cards, and accept that it
appears in the nav; or extend the test harness to build a variant site with cardView on, the way
`tests/fuzz.py` already builds a site per case. The third is the most honest and the most work.

**Where.** `layouts/section.html:22-29`, `layouts/_partials/init.html:69`,
`exampleSite/hugo.toml` (`[params.list]`), `tests/run.sh` (the *Accessible names and heading
order* group).

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
| `author.imageQuality` unimplemented | Built. The avatar goes through Hugo's pipeline for raster formats and still passes SVG through untouched. Quality turned out to be lossy-format-only — a PNG is byte-identical at q20 and q85 — so the demo avatar is a JPEG and the docs say so. |
| Physical properties beyond `text-align` | Swept. An Arabic page was added to `exampleSite` first, so the conversion was measured rather than inferred — and it found three real bugs the inference would have missed, including code blocks inheriting RTL. Nineteen declarations converted; two stay physical and say why at the declaration. |
| Table cells did not follow the text direction | Fixed. `prose.css` and `article.css` use logical `start`/`end`, verified by measurement: cell text moves from the left edge to the right edge when the block flips, and LTR rendering is unchanged. `tests/run.sh` refuses any physical `text-align`. The wider sweep it belongs to is the row above. |

### Deliberately not built

These were the Tier 2 list in `docs/SPEC.md`. Series, card views and maths were on it too and
have since been built (`list.cardView`, the series taxonomy, and build-time KaTeX via the
passthrough render hook) — deleted from here per this section's own rule. One entry stands:

- **Autoplay on the `video` shortcode.** CSS cannot stop playback, so `prefers-reduced-motion`
  could only be honoured with JavaScript, and with scripting off the theme would autoplay straight
  past a reader who asked it not to. An opt-in that silently fails is worse than an absent
  parameter. `tests/run.sh` asserts the parameter stays absent. See `docs/EXPANSION-PLAN.md` §A4.
