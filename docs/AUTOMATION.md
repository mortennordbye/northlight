# Automation

How CI, the quality audit, branch protection and releases work in this repository, and why
several of the settings are the way they are. Most of what follows exists because the obvious
configuration was wrong in a way that only showed up once something real ran through it.

`CONTRIBUTING.md` covers how to work on the theme. This file covers the machinery around it.

---

## What runs, and when

| Workflow | Trigger | Purpose |
| -------- | ------- | ------- |
| `ci.yml` | push to `main`, pull request | Build `exampleSite` with `--panicOnWarning`, then `tests/run.sh`. The same gate as `make check`. |
| `audit.yml` | push to `main`, pull request | Lighthouse over five routes, and an offline link and anchor scan. |
| `pages.yml` | push to `main` | Build with the Pages base URL and publish the demo site. |
| `dependency-review.yml` | pull request | Block a pull request introducing a known-vulnerable dependency. |
| `scorecard.yml` | push to `main`, weekly | OpenSSF supply-chain grade, published to the Security tab. |
| `pr-title.yml` | pull request | Enforce Conventional Commits on the title. |
| `release-please.yml` | push to `main` | Open the release pull request; merging it cuts the tag and release. |
| `dependabot-automerge.yml` | pull request | Merge patch and minor action bumps once checks pass. |
| `stale.yml` | daily | Mark and close inactive issues and pull requests. |

CodeQL has no workflow file. It runs through GitHub's default setup, over `javascript-typescript`
and `actions`, and appears on pull requests as `CodeQL / Analyze (...)`.

### Two of these are never exercised by a pull request

`pages.yml` and `scorecard.yml` only run on push to `main`. A pull request that changes either of
them will go green without any of that change having executed. This is the trap that makes a
dependency bump to a Pages action look verified when it is not: read the release notes, then watch
the deploy after merging.

---

## Branch protection

Two rulesets, both active.

**`protect-default-branch`** applies to `main`:

- deletion and non-fast-forward are blocked
- pull requests are required, with **0 required approving reviews**
- squash is the only permitted merge method
- required status checks, with the strict up-to-date policy on
- repository admins can bypass

Required contexts: `Build & test`, `Lighthouse`, `Link check`, `Dependency review`,
`Conventional Commits`.

**`protect-release-tags`** makes `refs/tags/v*` immutable against deletion and update. Tags can
still be created; a published version can never be moved.

### Why 0 required reviews

This is a single-maintainer repository and nobody can approve their own pull request. Requiring
one approval makes every pull request permanently unmergeable. The status checks are what actually
gate a merge here, and they are not optional.

OpenSSF Scorecard marks the repository down for this. That is the correct trade: a scoring rubric
written for multi-maintainer projects should not make the repository unusable.

### Why the strict policy causes rebase cycles

`strict_required_status_checks_policy` requires a branch to be up to date with `main` before it
merges. When several pull requests touch the same file, merging one puts the rest behind, and each
needs a rebase and a fresh set of checks before it can go in. This is expected, not a fault. With
Dependabot, comment `@dependabot rebase`; otherwise use `gh pr update-branch`.

---

## Two settings that look wrong and are not

### `can_approve_pull_request_reviews` is `true`

The security baseline says to turn this off. It is on, deliberately.

That one flag governs whether GitHub Actions may **create** pull requests as well as approve them.
With it off, release-please fails with `GitHub Actions is not permitted to create or approve pull
requests` after it has already created its branch and commit, leaving an orphan branch behind.

Turning it on is safe here specifically because the ruleset requires 0 approving reviews, so the
ability to approve grants nothing that was not already available. The workflow token itself stays
read-only (`default_workflow_permissions: read`); every workflow that needs to write requests it on
the single job that needs it.

If the required review count is ever raised above 0, revisit this: at that point the approve half
of the flag would become a real bypass.

### Admin bypass on the ruleset

Kept so a maintainer can merge something the automation cannot. The release pull request is the
concrete case: see below.

---

## The quality audit

`tests/run.sh` asserts that the SEO furniture **exists** — sitemap, `robots.txt`, `rel=canonical`,
OpenGraph tags, JSON-LD that is not double-encoded, an `alt` on every rendered image. A grep cannot
judge whether any of it is **correct**. That is what `audit.yml` is for.

### Lighthouse

Five routes, chosen to cover a home page, a list, an article with images and admonitions, a
documentation page and a taxonomy:

```
/  /blog/  /blog/measuring/  /docs/writing/  /tags/
```

Thresholds live in `.lighthouserc.json`:

| Category | Rule |
| -------- | ---- |
| SEO | error below 100 |
| Accessibility | error below 100 |
| Best practices | error below 100 |
| Performance | warning below 65 |

The first three are set where the theme already measures, so they are a floor that catches a
regression rather than an aspiration. Performance is a warning because it is timing-sensitive on
shared runners; the home page has been observed anywhere between 71 and 100 across runs of
identical code. A gate that goes red at random is a gate people learn to ignore.

**The audit build uses `--baseURL http://localhost:8080/`.** `exampleSite/hugo.toml` ships
`baseURL = "https://example.com/"`, and auditing a build made with that sends Lighthouse to
example.com for every stylesheet, font and `rel=canonical`, scoring a site that is not this one.
An absolute localhost base URL keeps `rel=canonical` valid, which the SEO audit checks. The build
is served with `python3 -m http.server`, which is already on the runner and avoids reintroducing a
Node toolchain.

One consequence: that server does not gzip, so Lighthouse reports a text-compression opportunity
worth roughly 160ms. GitHub Pages does compress. Real-world performance is better than the number
the audit reports, and this is not worth chasing.

**SEO is not asserted on `/tags/`.** `exampleSite` sets `robots: noindex, follow` on taxonomy
pages, which Lighthouse correctly scores as a crawlability failure. Asserting SEO there would mean
either abandoning that configuration or lying about it, so `.lighthouserc.json` uses an
`assertMatrix` with a pattern that excludes taxonomy pages from the SEO rule only. Accessibility
and best practices still apply.

### Link scan

`lychee` in `--offline` mode over the built HTML, with `--include-fragments`, resolving
root-relative paths through `--root-dir`. That build uses `--baseURL "/"` so every internal link
maps onto a path under the output directory.

Offline means remote URLs are skipped entirely, so an unreachable third-party site can never turn
this red. What it checks is that internal links and heading anchors resolve, including the
fragments the generated table of contents points at. External links are not validated by anything.

---

## The Hugo version has one source of truth

`HUGO_IMAGE` in the `Makefile`. `ci.yml`, `audit.yml` and `pages.yml` each read it out of that file
rather than repeating it:

```sh
v=$(grep -oE 'hugo:v[0-9]+\.[0-9]+\.[0-9]+' northlight/Makefile | head -1 | cut -d: -f2)
```

`pages.yml` used to hold a literal. That meant a `Makefile` bump would leave CI testing one Hugo
version while the live site published on another: green checks, a different binary, and nothing in
the diff to notice.

Two assertions in `tests/run.sh` hold this in place:

- the `Makefile` and `theme.toml`'s `min_version` must agree
- no workflow may contain a literal `HUGO_VERSION:`

Bumping Hugo therefore means the `Makefile`, `theme.toml` and the README requirements section, and
the suite fails if the first two drift apart.

---

## Actions are pinned to commit SHAs

Every `uses:` is a 40-character SHA with the version in a trailing comment:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7
```

A tag is mutable. Whoever controls the action repository can repoint `v7` at different code, and a
workflow holding a write token would run it with nothing in the diff to review. Dependabot updates
the SHA and the comment together, so the cost is a comment rather than a guess.

When adding an action, resolve the SHA rather than typing the tag:

```sh
gh api /repos/<owner>/<repo>/commits/<tag> -q .sha
```

Dependabot covers the `github-actions` ecosystem only, because the theme has no other dependencies
by design. Minor and patch updates are grouped into one weekly pull request and auto-merged once
checks pass; majors arrive individually and need reading.

---

## Releasing

Versions follow semantic versioning, and config keys are treated as API: a key is never renamed or
repurposed without a major bump.

### The normal flow

1. Land work through pull requests. The squash commit inherits the pull request title, and
   `pr-title.yml` has already validated it as a Conventional Commit.
2. release-please reads those commits on `main` and opens a release pull request that bumps
   `.release-please-manifest.json` and prepends to `CHANGELOG.md`.
3. Merging that pull request creates the tag and the GitHub release.

`fix:` produces a patch, `feat:` a minor. Because `bump-minor-pre-major` is set, a breaking change
before 1.0 produces a minor rather than a major.

### The release pull request needs two manual steps

**It has no checks until you approve them.** GitHub gates workflow runs on pull requests opened by
the Actions bot. The pull request shows `N workflows awaiting approval` with an
**Approve workflows to run** button. This is safe to click for a release pull request: the branch
is in this repository rather than a fork, and the diff is limited to
`.release-please-manifest.json` and `CHANGELOG.md`. Confirm both before approving:

```sh
gh pr view <n> --json isCrossRepository,author
gh pr diff <n> --name-only
```

If a release pull request ever proposes a change to anything under `.github/`, do not approve it.

**Squash commits are what release-please reads**, so a pull request title that is not a
Conventional Commit produces a silently wrong version. That is the whole reason `pr-title.yml`
exists and is a required check.

### Why `last-release-sha` is in the config

`release-please-config.json` carries:

```json
"last-release-sha": "91536daca8274de0d4fb06da75f05d409a0d2c76"
```

v0.2.0 was tagged by hand. The 31 entries that had accumulated under `[Unreleased]` were mostly
features, so the correct version was a minor; release-please could only see one parseable commit
since v0.1.0 and proposed a patch. Most of that work had landed with ordinary commit messages, and
its log reported `commit could not be parsed` for each. Cutting a patch would have shipped 18
features as a bug-fix release.

Tagging by hand also meant the hand-written changelog entries became the release notes, rather than
a thin generated list.

The cost is that release-please has no release pull request of its own to anchor on, so it walked
back to v0.1.0 and re-proposed a commit already contained in v0.2.0. `last-release-sha` points it
at the commit v0.2.0 tags, and it now considers only what came after.

This is a one-time reconciliation. Once release-please has cut a release itself, the anchor stops
mattering, and it can be removed the next time this file is touched.

### Before the first release-please release

`Signed-Releases` currently scores `-1` in Scorecard, meaning not applicable, and is excluded. The
moment a release exists without signatures it becomes a scored `0` and the overall grade drops.
Adding build provenance attestation to the release workflow is the fix, and it is easier to do
before there is a release than after.

---

## Things that will confuse you

- **A green pull request says nothing about `pages.yml` or `scorecard.yml`.** Neither runs on pull
  requests. See above.
- **`gh pr checks` shows `CodeQL` as `NEUTRAL`/`skipping` on workflow-only changes.** That is
  normal; it is not a required check.
- **Enabling non-provider secret-scanning patterns and validity checks cannot be done over the
  API.** `PATCH /repos/{owner}/{repo}` returns 200 and silently ignores both fields. They are
  gated at the account level and have to be set in Settings, Code security.
- **Scorecard will not reach a high score here.** `Maintained` is 0 until the repository is 90 days
  old, `Code-Review` needs approvals nobody can give, `Contributors` needs more than one
  organisation, and `Branch-Protection` is capped by the 0-review decision above. `Fuzzing` and
  `CII-Best-Practices` are not being pursued. Roughly 6.5 is the practical ceiling for now.
- **`static/.gitkeep` is not published.** `actions/upload-pages-artifact` v4 stopped including
  dotfiles. It is a placeholder for an otherwise-empty directory and nothing references it, so this
  is harmless. If the theme ever needs a real dotfile in the output, v5 added an
  `include-hidden-files` input.
