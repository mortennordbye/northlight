---
title: "Configuration"
description: "Every parameter the theme reads, its default, and what it changes."
weight: 2
date: 2026-07-27
---

Config flows one way: `site.Params` into `_partials/init.html`, which resolves defaults
once, and out to the templates. Templates read resolved values and never re-derive a
default inline, so every default below lives in exactly one place in the source.

> [!CAUTION]
> Config keys are API. Once published, a key is never renamed or repurposed without a
> major version bump and a changelog note. If you are reading this from a fork, that
> promise is yours to keep too.

## Site parameters

| Key | Default | What it does |
|---|---|---|
| `description` | — | Site description. Meta tags, the RSS channel, the home page. |
| `colorScheme` | `"periwinkle"` | `periwinkle`, `sage` or `clay`. An unknown value falls back rather than rendering unstyled. |
| `defaultAppearance` | `"light"` | `light` or `dark`. Only applies when `autoSwitchAppearance` is off. |
| `autoSwitchAppearance` | `true` | Follow the reader's operating system. |
| `enableSearch` | `true` | The ⌘K modal. Needs `JSON` in `[outputs].home`. |
| `enableCodeCopy` | `true` | Copy button on code blocks. |
| `mainSections` | `["blog"]` | Which sections count as posts for the home page, index, RSS and search. |
| `dateFormat` | `"2 Jan 2006"` | Go reference layout. |
| `rtl` | `false` | Sets `dir="rtl"` on `<html>`. |
| `logo` | — | Replaces the dot and the wordmark in the header. |
| `logoDark` | — | Optional dark counterpart. With only `logo` set, the same file is used in both modes. |

## `[params.author]`

| Key | Default | What it does |
|---|---|---|
| `name` | — | Article meta line and the home byline. Omit it and both disappear. |
| `headline` | — | One line under the name on the home page. |
| `image` | — | Square avatar, 160px or larger. Looked up in `assets/` then `static/`; a missing file renders nothing rather than a broken image. |
| `links` | — | Array of single-key tables. Supported: `linkedin`, `github`, `rss`, `link`. |

## `[params.home]`

| Key | Default | What it does |
|---|---|---|
| `showFeatured` | `true` | Large card for the newest post. |
| `recentCount` | `3` | Cards below the featured post. |

## `[params.article]`

| Key | Default | What it does |
|---|---|---|
| `showBreadcrumbs` | `true` | Trail above the title. Ancestors only. |
| `showAuthor` | `true` | Author name and avatar in the meta line. |
| `showDate` | `true` | Publication date. |
| `showDateUpdated` | `false` | Updated date. Only renders when `lastmod` is genuinely later than `date`. |
| `showReadingTime` | `true` | Estimated reading time. |
| `showWordCount` | `true` | Word count. |
| `showHero` | `true` | The cover image. |
| `showTableOfContents` | `true` | Sticky TOC rail on desktop, a card above the article on mobile. |
| `showProgress` | `true` | 2px reading-progress bar. |
| `showTaxonomies` | `true` | Tag row at the foot of a post. |
| `showRelated` | `true` | "Read next" block. Needs the `[related]` config. |
| `relatedLimit` | `3` | How many related posts. |
| `showPagination` | `true` | Older and newer post links. |
| `sharingLinks` | `["linkedin", "reddit"]` | Share buttons. An unknown name warns at build time and renders nothing. |
| `showComments` | `false` | Comments. Also needs `[params.comments.giscus]`. |
| `showEdit` | `false` | "Edit this page" link. |
| `editURL` | — | Base URL for that link. Renders nothing when unset. |
| `editAppendPath` | `true` | Append the page's own path to `editURL`. |

The edit link on the page you are reading is live. It points at this file in the theme's
own repository, built from `editURL` plus the content path.

## `[params.list]` and `[params.footer]`

| Key | Default | What it does |
|---|---|---|
| `list.groupByYear` | `true` | Year headings in the post index, grouped within each page of results. |
| `footer.showCopyright` | `true` | Copyright line. |
| `footer.showThemeAttribution` | `true` | The "built with Hugo and the Northlight theme" line. |
| `footer.themeURL` | — | Links the theme name in that line to a URL. Unset, the name is plain text. The theme cannot default this to its own repository, because that URL contains its author's name and no theme file is allowed to carry one. |

## `[params.verification]`

Public ownership tags. Each renders only when its key is set, so a site that verifies
nothing emits nothing.

| Key | What it does |
|---|---|
| `google` | `google-site-verification` |
| `bing` | `msvalidate.01` |
| `pinterest` | `p:domain_verify` |
| `yandex` | `yandex-verification` |
| `fediverse` | `fediverse:creator`, as `@you@instance.tld` |

> [!TIP]
> `fediverse` is the one most worth setting. Mastodon shows a verified author byline on
> a link preview when the page points back at your profile, which is the difference
> between a shared post looking like yours and looking like an unattributed repost.

## Menus

A menu entry with children renders as a disclosure panel rather than a hover dropdown,
because hover menus are unreachable by touch and awkward by keyboard. The **Docs** entry
in the header above is one; open it and look at how it behaves with the keyboard alone.

```toml {file="hugo.toml"}
[[menu.main]]
  identifier = "docs"
  name = "Docs"
  pageRef = "docs"
  weight = 20

[[menu.main]]
  parent = "docs"
  name = "Configuration"
  pageRef = "docs/configuration"
  weight = 2
```

One level only. A blog that needs three wants a landing page, not a bigger menu.
