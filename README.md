# Northlight

A quiet, readable Hugo theme for technical writing.

North light is the soft, even light from a north-facing window — no glare, no hard shadows, the
same all day. That is the whole brief. Northlight has no concept to get between you and the
words: no gradients, no glass, no glow, no decorative motion. What it has instead is a careful
type scale, a spacing rhythm that holds, syntax highlighting that works in both colour modes,
and a dark mode designed rather than inverted.

> **Status: in development.** The design is settled and the specification is written; the
> templates are not built yet. See [`docs/BUILD-PLAN.md`](docs/BUILD-PLAN.md).

## Design

Open [`design/northlight.html`](design/northlight.html) in a browser. It is a single
self-contained file showing the home page, the post index and a full article, in both colour
modes and three palettes. That mockup is the approved visual target.

Type is **Schibsted Grotesk** with **Spline Sans Mono** for code — chosen over the near-universal
Inter and JetBrains Mono because a theme should not look like every other theme.

Colour is a white and near-black base plus one pastel primary, in three palettes: **periwinkle**,
**sage** and **clay**. Each palette carries two accent tones — a readable one for text and links,
and a genuinely pastel one for fills and hovers — which is what lets a pastel work without
failing contrast.

## Features

Long-form reading with a sticky scroll-spy table of contents, reading progress, and heading
anchors. Syntax highlighting via Chroma classes, styled for light and dark, with a filename bar
and copy button. A ⌘K search modal with cover thumbnails and keyboard navigation. Post covers
rendered at their exact aspect ratio and never cropped. Tags, related posts, prev/next, share
links, and a comments hook. RSS, JSON search index, sitemap and robots.txt.

Everything interactive degrades: with JavaScript off the site stays readable and navigable, the
table of contents is still a list of working links, and the colour mode falls back to
`prefers-color-scheme`. Only search disappears.

## Requirements

Hugo **extended** 0.161.0 or newer. Nothing else — no Node, no npm, no CSS framework, no build
step beyond Hugo itself.

## Install

As a git submodule:

```bash
git submodule add https://github.com/mortennordbye/northlight.git themes/northlight
```

Then in your site config:

```toml
theme = "northlight"
```

A complete, working configuration lives in [`exampleSite/`](exampleSite/) — copy its
`hugo.toml` as a starting point.

## Configuration

<!-- TODO: replace this section with the full param reference once the templates exist.
Every param, its default, and what it does. Until then, exampleSite/hugo.toml is the
reference. Renaming a param after release is a breaking change — see CONTRIBUTING.md. -->

The full parameter reference is written as the theme is built. For now,
[`exampleSite/hugo.toml`](exampleSite/hugo.toml) documents every supported option inline.

Two settings are **required** rather than optional, because the theme depends on them:

```toml
[markup.highlight]
  noClasses = false   # syntax highlighting uses CSS classes, not inline styles

[markup.goldmark.renderer]
  unsafe = true       # only if your posts contain raw HTML
```

Site-specific things stay in *your* config, not in the theme. Analytics, comment-system IDs and
similar go through the `extend-head.html` partial, which you override in your own site's
`layouts/_partials/`.

## Development

Everything runs in a container. Do not install Hugo on your host.

```bash
make serve    # dev server on http://localhost:1313
make build    # production build of exampleSite
make check    # the gate: build with warnings as errors, then sanity-check output
make clean
```

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first — it documents the working rules for this repo, including
the invariants that are easy to break by accident (covers are never cropped, Chroma needs both
modes, asset fingerprinting is mandatory, nothing author-specific in theme files).

Known gaps that are deliberately deferred live in [`BACKLOG.md`](BACKLOG.md).

## Licence

MIT. See [`LICENSE`](LICENSE).
