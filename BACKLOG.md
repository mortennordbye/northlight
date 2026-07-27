# Backlog

Known gaps deliberately left for later. Not work-in-progress — WIP belongs on a branch. Each
entry states what, why it was deferred, what would unblock it, and where the code lives.

---

## v0.1.0 is not tagged yet

**What:** `CHANGELOG.md` documents 0.1.0 and the theme is feature-complete against
`docs/BUILD-PLAN.md`, but no git tag exists.

**Why deferred:** the work is on the `build/theme` branch. Tagging a release on an unmerged
branch points `v0.1.0` at a commit that is not on `main`, which is worse than not tagging.

**Unblocks it:** merging `build/theme` into `main`, then `git tag -a v0.1.0`. The install
instructions and `theme.toml` already reference the tag's URL shape.

**Where:** `CHANGELOG.md`, `theme.toml`.

---

## Highlighted line has a seam under line numbers

**What:** on a fence using `linenos=table` *and* `hl_lines`, the highlighted row's background
stops at the edge of the line-number cell and resumes in the code cell, leaving a hairline gap
between the two columns. Chroma emits `.hl` separately inside each table cell and the cell
padding sits between them.

**Why deferred:** cosmetic, and it needs both features on the same fence — a combination the
reference blog never uses. Fixing it properly means restyling the `lntable` layout so the row is
one background rather than two.

**Unblocks it:** a post that actually uses line numbers with highlighted lines.

**Where:** `.chroma .hl` and the `.lntd` rules in `assets/css/chroma.css`.

---

## OpenGraph article:tag is title-cased

**What:** `<meta property="article:tag">` renders `Accessibility` rather than `accessibility`.
Hugo's embedded `opengraph.html` uses `.LinkTitle` for terms, which is Hugo's title-cased form.
Tags elsewhere in the theme render as the author wrote them, via `.Data.Term`.

**Why deferred:** fixing it means replacing the whole embedded OpenGraph partial with a
hand-rolled copy, and then owning every future change Hugo makes to it — a large maintenance
surface for the casing of one social meta tag no human reads.

**Unblocks it:** Hugo exposing the raw term to the embedded template, or a decision that the
casing matters enough to fork the partial.

**Where:** `layouts/_partials/head.html`, the `partial "opengraph.html"` call.

---

## Search is substring-only

**What:** `assets/js/search.js` lowercases the query and tests it against title, tags and summary
with `indexOf`. There is no ranking, no fuzzy matching and no typo tolerance, and the index
carries no post bodies.

**Why deferred:** deliberate, not an oversight. For a blog-sized corpus it finds what people look
for, and a matching library would cost more over the wire than the entire index does. It is
recorded here because it is the first thing that stops scaling — at a few hundred posts, ranked
matching starts to earn its keep.

**Unblocks it:** a site large enough that substring matching returns too much or the wrong order.
`search.js` is the only file that would change; the index format already carries what a ranker
needs.

**Where:** `assets/js/search.js`, `layouts/home.json`.

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
