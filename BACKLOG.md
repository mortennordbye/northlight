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
