# Northlight

A quiet, readable Hugo theme for technical writing.

North light is the soft, even light from a north-facing window — no glare, no hard shadows, the
same all day. That is the whole brief. Northlight has no concept to get between you and the
words: no gradients, no glass, no glow, no decorative motion. What it has instead is a careful
type scale, a spacing rhythm that holds, syntax highlighting that works in both colour modes,
and a dark mode designed rather than inverted.

Screenshots: [light](images/screenshot.png) · the same page in both modes and all three palettes
is in [`design/northlight.html`](design/northlight.html).

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

Hugo **extended** 0.164.0 or newer. Nothing else — no Node, no npm, no CSS framework, no build
step beyond Hugo itself.

0.164.0 is the floor because the theme is built on the template system Hugo introduced in 0.146
and on the light/dark Chroma style pairs added in 0.164. If you are on an older Hugo, upgrade
before installing the theme.

## Install

**As a git submodule** (recommended — no Go toolchain needed):

```bash
git submodule add https://github.com/mortennordbye/northlight.git themes/northlight
```

```toml
# hugo.toml
theme = "northlight"
```

If you build in CI, remember `submodules: recursive` on the checkout step.

**As a Hugo Module** (needs Go available wherever you build):

```bash
hugo mod init github.com/you/your-site
```

```toml
# hugo.toml
[module]
  [[module.imports]]
    path = "github.com/mortennordbye/northlight"
```

Then copy [`exampleSite/hugo.toml`](exampleSite/hugo.toml) as your starting config — it is a
working file with every option in it, and the reference below matches it exactly.

## Configuration

Everything is optional except the three settings under **Required** below. Defaults are what you
get if you omit the key entirely.

Config keys are API. Once released, a key is not renamed or repurposed without a major version
bump — see [`CHANGELOG.md`](CHANGELOG.md).

### Required

```toml
[markup.highlight]
  noClasses = false        # syntax highlighting uses CSS classes, which this theme styles.
                           # Leave it true and code blocks render unstyled.

[outputs]
  home = ["HTML", "RSS", "JSON"]   # JSON is the search index. Drop it and search finds nothing.

[taxonomies]
  tag = "tags"             # the theme reads the `tags` taxonomy for tag rows and related posts
```

Add these two if they apply to you:

```toml
[markup.goldmark.renderer]
  unsafe = true            # only if your posts contain raw HTML. Your call, not the theme's.

[related]                  # required for params.article.showRelated — Hugo's default indices
  includeNewer = true      # cover `keywords`, which this theme does not use
  threshold = 80
  toLower = false
  [[related.indices]]
    name = "tags"
    weight = 100
  [[related.indices]]
    name = "date"
    weight = 10
```

### Site parameters

| Key | Default | What it does |
|---|---|---|
| `description` | — | Site description. Used for meta tags, the RSS channel and the home page. |
| `colorScheme` | `"periwinkle"` | Palette: `periwinkle`, `sage` or `clay`. An unknown value falls back to periwinkle rather than rendering unstyled. |
| `defaultAppearance` | `"light"` | `light` or `dark`. Only applies when `autoSwitchAppearance` is off. |
| `autoSwitchAppearance` | `true` | Follow the reader's operating system. When on, the theme sets nothing and lets CSS track the system, so it keeps up if the system flips mid-session. |
| `enableSearch` | `true` | The ⌘K modal. Needs `JSON` in `[outputs].home`. |
| `enableCodeCopy` | `true` | Copy button on code blocks. |
| `mainSections` | `["blog"]` | Which sections count as posts for the home page, index, RSS and search. |

### `[params.author]`

| Key | Default | What it does |
|---|---|---|
| `name` | — | Shown in the article meta line and the home byline. Omit it and both disappear. |
| `headline` | — | One line under the name on the home page. |
| `image` | — | Square avatar, 160px or larger. Looked up in `assets/` first, then `static/`; if the file is not there, nothing is rendered rather than a broken image. |
| `links` | — | Array of single-key tables. Supported keys: `linkedin`, `github`, `rss`, `link`. |

### `[params.home]`

| Key | Default | What it does |
|---|---|---|
| `showFeatured` | `true` | Large card for the newest post. |
| `recentCount` | `3` | Cards below the featured post. |

### `[params.article]`

| Key | Default | What it does |
|---|---|---|
| `showBreadcrumbs` | `true` | Trail above the title. Ancestors only — the post's own title is the h1 right below it. |
| `showAuthor` | `true` | Author name and avatar in the meta line. |
| `showDate` | `true` | Publication date. |
| `showReadingTime` | `true` | Estimated reading time. |
| `showWordCount` | `true` | Word count. Shown in the post index; the article meta line uses date and reading time only. |
| `showHero` | `true` | The cover image. |
| `showTableOfContents` | `true` | Sticky TOC rail on desktop, a card above the article on mobile. |
| `showProgress` | `true` | 2px reading-progress bar. |
| `showTaxonomies` | `true` | Tag row at the foot of a post. |
| `showRelated` | `true` | "Read next" block. Needs the `[related]` config above. |
| `relatedLimit` | `3` | How many related posts. |
| `showPagination` | `true` | Older/newer post links. |
| `sharingLinks` | `["linkedin", "reddit"]` | Share buttons. Supported: `linkedin`, `reddit`. An unknown name logs a build warning and renders nothing. |
| `showComments` | `false` | Comments. Also needs `[params.comments.giscus]` filled in, or an override — see below. |

### `[params.list]` and `[params.footer]`

| Key | Default | What it does |
|---|---|---|
| `list.groupByYear` | `true` | Year headings in the post index, grouped within each page of results. |
| `footer.showCopyright` | `true` | Copyright line. |
| `footer.showThemeAttribution` | `true` | "built with Hugo and the Northlight theme". |

### `[params.comments.giscus]`

Only read when `article.showComments` is true. Leave it out and no third-party script loads.

| Key | Default | What it does |
|---|---|---|
| `repo` | — | `you/your-repo`. Required. |
| `repoId` | — | From giscus.app. Required. |
| `category` | — | Discussion category. Required. |
| `categoryId` | — | From giscus.app. Required. |
| `mapping` | `"pathname"` | How a page maps to a discussion. |
| `reactionsEnabled` | `"1"` | Reactions on the main post. |
| `lang` | site language | giscus UI language. |

Using something else — utterances, Cusdis, a static form? Copy
`layouts/_partials/comments.html` into your own site and replace it. That is the supported path
and it survives theme upgrades.

### Front matter

| Key | What it does |
|---|---|
| `title`, `description`, `date`, `draft`, `tags` | The standard set. `description` becomes the lede, the meta description, the card summary and the RSS description. |
| `showTableOfContents` | Per-post override of the site default. |
| `showHero` | Per-post override — hide the cover on one post. |
| `coverAlt` | Alt text for the cover. Empty by default, which is correct for artwork that repeats the title. |
| `robots` | `noindex, follow` and similar. Cascades, so setting it on a section covers everything under it. |
| `sitemap_exclude` | Keep a page out of the sitemap. |

### Covers

Put `cover.png` (or `.jpg`, `.webp`) beside `index.md` in a page bundle. `featured.*` also works,
for sites migrating from a theme that used that name.

**Covers are never cropped.** They render in an exact 1200×630 box, so a cover of a different
shape letterboxes rather than losing its edges. This is deliberate: cover art with the title baked
into it loses the title to a crop, and a visible letterbox is a better failure than silent
destruction.

### Overriding anything

Two partials exist purely as escape hatches, and both survive theme upgrades:

- `layouts/_partials/extend-head.html` — anything you need in `<head>`: an analytics beacon, a
  verification tag, a preconnect.
- `layouts/_partials/comments.html` — any comment system.

Copy either into your own site's `layouts/_partials/` and yours wins.

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
