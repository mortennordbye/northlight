# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

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
