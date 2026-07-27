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

## Intermittent "no such file or directory" build failure, unattributed

**What:** `make build` / `make check` occasionally dies mid-render with
`open .../exampleSite/public/<file>: no such file or directory`, on a different file each time
(`index.html`, `robots.txt`), or `mkdir .../exampleSite/resources/_gen: no such file or
directory`. Hugo reports a successful page count first, so it is a filesystem error, not a
template error. Re-running succeeds.

**Why deferred:** it could not be pinned down. Observed 11 failures in ~90 runs during one
window, then **0 failures in 107 consecutive runs** afterwards, across Hugo 0.161.1, 0.163.3 and
0.164.0 and across four different Makefile shapes. Every mitigation tried — pre-creating the
publish directory, `HUGO_NUMWORKERMULTIPLIER=1`, building to the container's own filesystem and
copying the result out, deleting from inside the container rather than the host — appeared to fix
it and then did not survive a larger sample. The failures clustered while the machine was also
pulling container images and running a browser, which points at the macOS bind mount under load
rather than at Hugo. A workaround was written and then reverted rather than ship unexplained
complexity in the Makefile.

**Unblocks it:** a reproduction that survives a 50-run sample on an idle machine. If it recurs,
capture `docker version`, the storage driver, and whether OrbStack or Docker Desktop is in use,
then compare a build whose destination is inside the container (`--destination /tmp/public`)
against one writing straight to the mount. If it turns out to be real and Hugo-side, it belongs
upstream, not in this repo.

**Where:** `Makefile` — the `build` and `check` targets, and the `RUN` mount at
`/src/northlight`.

---

## Contrast figures are hand-computed, not measured

**What:** the light-mode accent contrast ratios in `docs/DESIGN.md` (periwinkle ≈ 6.0:1, sage ≈
5.1:1, clay ≈ 4.9:1) were calculated by hand from the sRGB values, not measured with a tool.
Clay is the closest to the 4.5:1 AA floor and has the least headroom.

**Why deferred:** no build exists to run a contrast checker against.

**Unblocks it:** build-plan phase 7. If any value lands under 4.5:1, darken that palette's
light-mode `--accent` until it clears.

**Where:** `docs/DESIGN.md` "The two-tone accent"; values will live in
`assets/css/tokens.css`.

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
