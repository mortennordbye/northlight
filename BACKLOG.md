# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

Empty is the correct state for this file. Everything that was in it at the end of the initial
build was either fixed or turned into a decision recorded where the decision lives — see *Closed*
below for what happened to each.

---

## Nothing open

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
