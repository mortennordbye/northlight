# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

---

## Config reference in README is a placeholder

**What:** `README.md` has a `<!-- TODO -->` where the full parameter reference belongs — every
param, its default, and what it does.

**Why deferred:** the params do not exist yet. Writing the reference before the templates would
document guesses, and a wrong config reference is worse than none.

**Unblocks it:** finishing build-plan phase 4, at which point the param surface is stable enough
to document.

**Where:** `README.md`, "Configuration" section. Source of truth will be
`exampleSite/hugo.toml`.

---

## Font fallback has no matched metrics

**What:** `CONTRIBUTING.md` calls for fonts to load with `font-display: swap` **and a matched fallback
metric**. Only the first half is done. The `@font-face` blocks in `assets/css/fonts.css` use
`swap`, but the fallback stack is plain `system-ui`, so the swap from fallback to Schibsted
Grotesk shifts text slightly.

**Why deferred:** the fix is an extra `@font-face` block per family declaring `size-adjust`,
`ascent-override`, `descent-override` and `line-gap-override` against a named local fallback, and
the override percentages have to be measured against real rendered text rather than guessed.
There is no styled page to measure against until phase 3 puts prose on the screen.

**Unblocks it:** phase 3 or phase 7. Measure with the two families side by side at
`--text-prose`, then tune `size-adjust` until the line boxes match.

**Where:** `assets/css/fonts.css`, and `--font-sans` / `--font-mono` in `assets/css/tokens.css`.

---

## Bind-mount build race: mitigated, root cause not proven

**What:** on a cold output directory, `make build` / `make check` could die with
`open .../exampleSite/public/robots.txt: no such file or directory` — sometimes also
`mkdir .../exampleSite/resources/_gen: ...`, and the same event surfaces a second time as a
misleading `resource is nil` error pointing at `_partials/head.html`. Hugo prints a successful
page count first, so it is a filesystem error rather than a template one.

**State:** mitigated. `make clean` now deletes from inside the container, so the delete and the
recreate go through the same mount client. Measured over cold builds: **2/12 host-side clean,
0/37 container-side**, then **0/15** end-to-end `make clean && make check` after the change.

**Why still listed:** the sample is small and the underlying cause is inferred, not proven. It
does not explain an earlier window where the same failure appeared across Hugo 0.161.1, 0.163.3
and 0.164.0 and then vanished for 107 consecutive runs. Deleting `public/` from the host by other
means — Finder, `git clean`, a stray `rm -rf` — bypasses the mitigation entirely and should be
expected to reproduce it.

**Unblocks it:** if it recurs, capture `docker version`, the storage driver and whether OrbStack
or Docker Desktop is in use, then compare a build whose destination is inside the container
(`--destination /tmp/public`) with one writing straight to the mount. If it turns out to be real
and Hugo-side, it belongs upstream, not here.

**Where:** `Makefile` — the `clean` target and the `RUN` mount at `/src/northlight`.

---

## --fg-3 fails AA for small text

**What:** `--fg-3`, the muted grey, is `#8a8a92` light and `#71717d` dark. Measured against the
page background that is **3.42:1 and 4.19:1**, below the 4.5:1 AA floor. It is specified for the
meta line, eyebrow labels, the TOC heading, card dates, breadcrumb separators and the footer —
all at 13.5px or smaller, so all of it is small text and none of it qualifies for the 3:1 large-
text exemption.

**Why deferred:** deliberately, in favour of doing it with the rest of the contrast pass. Nothing
renders `--fg-3` yet — the meta line arrives in phase 3 — so there is nothing to eyeball a
correction against, and changing it shifts the muted grey everywhere it will eventually be used.

**Unblocks it:** phase 7, together with the accent verification below. The measuring script used
in phase 2 is the same one to use: walk the tone toward the foreground until it clears 4.6:1.

**Where:** `--fg-3` in `assets/css/tokens.css`, and the base colour table in `docs/DESIGN.md`.

---

## Accent contrast figures are hand-computed, not measured

**What:** the light-mode accent contrast ratios in `docs/DESIGN.md` (periwinkle ≈ 6.0:1, sage ≈
5.1:1, clay ≈ 4.9:1) were calculated by hand from the sRGB values, not measured with a tool.
Clay is the closest to the 4.5:1 AA floor and has the least headroom.

**Why deferred:** nothing renders `--accent` yet. The syntax tokens were measured and corrected
during phase 2; the accents are used by links, eyebrows and the active TOC item, which do not
exist until phases 3 and 4.

**Unblocks it:** build-plan phase 7. If any value lands under 4.5:1, darken that palette's
light-mode `--accent` until it clears.

**Where:** `docs/DESIGN.md` "The two-tone accent"; values live in `assets/css/tokens.css`.

---

## Theme distribution method not decided

**What:** the theme ships as a git submodule in the docs. Hugo Modules is the other option and
gives proper version pinning via `go.mod`.

**Why deferred:** it only matters at first release, and it changes the install instructions and
possibly CI.

**Unblocks it:** deciding before tagging `v0.1.0`. Hugo Modules needs Go available in whatever
builds consuming sites.

**Where:** `README.md` "Install", `theme.toml`, and build-plan phase 8.

---

## Cover art duplicates the post title

**What:** the reference blog's covers are 1200×630 with the post title baked into the artwork,
so any layout showing a cover above a headline renders the title twice.

**Why deferred:** it is a content decision for the site author, not a theme bug. The theme
renders both correctly.

**Unblocks it:** the author either accepts it as a magazine convention or removes text from the
cover art. If neither, the theme could grow a `showTitleOverCover` param — but do not add that
speculatively.

**Where:** noted in `docs/DESIGN.md` "Covers".

---

## Tier 2 features from the audit are unbuilt

**What:** series taxonomy, card-view variants, and `groupByYear` are configured on the site
Northlight replaces but unexercised by any of its content. Math passthrough is enabled and
unused. Draft labels are on and unused.

**Why deferred:** building for zero current usage is exactly the failure mode
`docs/SPEC.md` warns about — two-thirds of the previous theme was unused surface area.

**Unblocks it:** an actual post that needs one of them.

**Where:** `docs/SPEC.md` "Build order", Tier 2.
