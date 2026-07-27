---
title: "Getting started"
description: "Install the theme, add the config it requires, and publish."
weight: 1
date: 2026-07-27
---

Northlight needs Hugo **extended** 0.164.0 or newer and nothing else. No Node, no npm, no
CSS framework, no build step beyond Hugo itself.

## Install

As a submodule, which is the route that needs no Go toolchain:

```bash {file="terminal"}
hugo new site my-blog
cd my-blog
git init
git submodule add https://github.com/mortennordbye/northlight.git themes/northlight
```

Or as a Hugo Module, if you already use them:

```toml {file="hugo.toml"}
[module]
  [[module.imports]]
    path = "github.com/mortennordbye/northlight"
```

Then point the site at it:

```toml {file="hugo.toml"}
theme = "northlight"
```

## Required configuration

Four settings the theme cannot work without, and each fails in a way that looks like a
theme bug if you skip it.

```toml {file="hugo.toml"}
[markup.highlight]
  noClasses = false          # Chroma emits CSS classes, which the theme styles.
                             # Leave it true and every code block renders unstyled.

[markup.goldmark.parser]
  wrapStandAloneImageWithinParagraph = false   # lets a standalone image become a
                                               # <figure> and carry a caption

[outputs]
  home = ["HTML", "RSS", "JSON"]   # JSON is the search index. Drop it and ⌘K finds nothing.

[taxonomies]
  tag = "tags"               # the theme reads `tags` for tag rows and related posts
```

> [!IMPORTANT]
> `noClasses = false` is the one people miss. Syntax highlighting will appear to be
> broken rather than absent, because Chroma will still emit markup, just with no classes
> for the theme to colour.

Add this if you want related posts, because Hugo's default indices cover `keywords`,
which the theme does not use:

```toml {file="hugo.toml"}
[related]
  includeNewer = true
  threshold = 80
  toLower = false
  [[related.indices]]
    name = "tags"
    weight = 100
  [[related.indices]]
    name = "date"
    weight = 10
```

## Your first post

Covers live in the page bundle beside the content:

```text {file="content structure"}
content/
└── blog/
    └── hello/
        ├── index.md
        └── cover.png     # 1200x630. Never cropped. `featured.*` also works.
```

```yaml {file="content/blog/hello/index.md"}
---
title: "Hello"
description: "One or two sentences. Used as the lede, the meta description, the card summary and the RSS description."
date: 2026-07-27
tags: ["writing"]
---
```

## Publish

The demo you are reading is built and deployed by GitHub Actions on every push. The
workflow is in the repository at `.github/workflows/pages.yml` and is a reasonable
starting point: it pins Hugo to an exact version, builds with `--panicOnWarning` so a
warning fails the build rather than publishing quietly, and deploys to GitHub Pages.

> [!TIP]
> Build with `--panicOnWarning` locally too. Most of what this theme would warn about,
> a missing related-content index or an unknown sharing link, is silent otherwise and
> shows up as something simply not appearing on the page.
