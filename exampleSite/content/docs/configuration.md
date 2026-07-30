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
| `colorScheme` | `"periwinkle"` | `periwinkle`, `sage`, `clay`, `plum`, `slate` or `rose`. An unknown value falls back rather than rendering unstyled. |
| `defaultAppearance` | `"light"` | `light` or `dark`. Only applies when `autoSwitchAppearance` is off. |
| `autoSwitchAppearance` | `true` | Follow the reader's operating system. |
| `enableSearch` | `true` | The ⌘K modal. Needs `JSON` in `[outputs].home`. |
| `enableCodeCopy` | `true` | Copy button on code blocks. |
| `fingerprintAlgorithm` | `"sha512"` | `md5`, `sha256`, `sha384` or `sha512`. Changing it renames every asset at once — a cache bust, not a stale asset, but worth knowing. |
| `disableTextInHeader` | `false` | Logo-only header. The home link keeps an `aria-label`, or it would be unlabelled on every page. |
| `enableStyledScrollbar` | `true` | Hand the scrollbar back to the operating system when off. |
| `smartTOCHideUnfocusedChildren` | `false` | Collapse TOC child lists except under the current heading. Off by default: extra motion in a component whose job is to stay still. |
| `backgroundImageWidth` | `1600` | Scale target for the full-bleed background image, the largest image on any page that uses one. |
| `hotlinkFeatureImage` | `false` | Allow `featureImageURL` in front matter to point at a remote image. Off, because that is a third-party request on page view. |
| `defaultFeaturedImage` | — | Site-wide cover for posts that have none. A configured-but-missing file renders nothing rather than a 404 on every page. |
| `defaultSocialImage` | — | The OpenGraph/Twitter card image for pages without a cover of their own. |
| `seo.metaDescriptionOrder` | `["description", "summary", "siteDescription"]` | Which source fills the meta description, first non-empty wins. An unknown name is skipped rather than failing the build. |
| `header.showSubNav` | `false` | A second navigation row from the `subnav` menu. Renders only when that menu has entries. |
| `imagePosition` | `"center"` | `object-position` for cropped images — the avatar and card thumbnails. Covers are never cropped, so it does not affect the hero. |
| `disableImageOptimization` | `false` | Hand raster images to the browser unresized. For a site whose images are already optimised upstream. |
| `layoutBackgroundBlur` | `false` | Blurs background and hero artwork. Applied to the image, not the block, so text over it stays sharp. |
| `layoutBackgroundHeaderSpace` | `false` | Extra room between the header and the body. |
| `enableLightbox` | `false` | Click a prose image to see it full size. Uses a `<dialog>`, so the modal semantics, backdrop, focus trap and Escape handling come from the browser. Images that are already links are left alone. |
| `enableA11y` | `false` | Shows a control that underlines every link on the page. Named for what it does: a control whose effect a reader cannot predict is not an accessibility feature. |
| `accentEmphasis` | `false` | Lets the palette reach five surfaces the theme otherwise leaves neutral: section headings, the year rules on the post index, tag chips, a card's hover border and the blockquote edge. Invents no colours, so every palette gets it. See [Appearance]({{< relref "/docs/appearance" >}}#more-of-it-accentemphasis). |
| `header.layout` | `"fixed"` | `fixed` keeps the header sticky (the current behaviour); `basic` lets it scroll away. |
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
| `bio` | — | A paragraph, rendered as Markdown, shown on the `profile` home layout. The headline says what you do; this says who you are. |
| `email` | — | Used by the reply-by-email link. Nothing renders unless `article.replyByEmail` is also on. |
| `imageQuality` | `85` | JPEG/WebP quality for the avatar. **Lossless formats ignore it** — a PNG is byte-identical at any value; only the resize applies there. |
| `image` | — | Square avatar, 160px or larger. Looked up in `assets/` then `static/`; a missing file renders nothing rather than a broken image. |
| `links` | — | Array of single-key tables. Supported: `linkedin`, `github`, `rss`, `link`. |

### Several authors

`[params.author]` is the single, site-wide author, and a site that only ever has one needs
nothing else. For more than one, put a file per person in `data/authors/` and name the keys
in a post's front matter:

```toml
# data/authors/ada.toml
name = "Ada Example"
headline = "Invented the demo co-author"
image = "images/ada.png"
links = [{ link = "https://example.com" }]
```

```yaml
# in the post
authors: ["morten", "ada"]
```

A post that says nothing about `authors` falls back to `[params.author]`, which is what
keeps this backward compatible: an existing site renders exactly what it rendered before.

A key with no matching file **fails the build**. A post crediting somebody who then does
not appear is the kind of bug nobody notices until the person asks why their name is
missing.

Registering `author = "authors"` under `[taxonomies]` gives each author a page listing
what they wrote; `showAuthorsBadges` then links the byline names to them.

**Writing a `bio` in TOML has one trap.** A `"""` string keeps its indentation, and
Markdown reads four leading spaces as a code block, so a bio indented to line up with the
keys around it renders as a grey `<pre>` slab rather than as prose. Keep the continuation
lines flush left — `exampleSite/hugo.toml` shows the shape, and the test suite asserts the
bio never renders as a code block.

## `[params.home]`

| Key | Default | What it does |
|---|---|---|
| `layout` | `"stack"` | Which homepage arrangement to render: `stack`, `page`, `profile`, `hero`, `card`, `background`, `split`, `gallery`, `archive` or `custom`. An unknown value fails the build. The Appearance page shows each one. |
| `showFeatured` | `true` | Large card for the newest post. |
| `recentCount` | `3` or `6` | Recent posts below. Layouts that lead with a feature (`stack`, `hero`) default to 3; the rest to 6. |
| `backgroundImage` | — | Only read by `layout = "background"`. Without it that layout renders the ordinary intro. |

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
| `heroStyle` | `"basic"` | `basic`, `big`, `background` or `thumbAndBackground`. Overridable per post. An unknown value falls back to `basic`. **Every style keeps the cover uncropped** — see below. |
| `showTableOfContents` | `true` | Sticky TOC rail on desktop, a card above the article on mobile. |
| `showProgress` | `true` | 2px reading-progress bar. |
| `showTaxonomies` | `true` | Tag row at the foot of a post. |
| `showRelated` | `true` | "Read next" block. Needs the `[related]` config. |
| `relatedLimit` | `3` | How many related posts. |
| `showPagination` | `true` | Older and newer post links. |
| `sharingLinks` | `["linkedin", "reddit"]` | Share buttons, rendered in the order you list them. See the eleven supported names below. An unknown name warns at build time and renders nothing. |
| `mastodonInstance` | — | The Mastodon instance to post to, e.g. `mastodon.social`. Required if `sharingLinks` includes `mastodon`. |
| `showComments` | `false` | Comments. Also needs `[params.comments.giscus]`. |
| `showAuthorsBadges` | `false` | Link each byline name to its author page. Needs `author = "authors"` under `[taxonomies]`. |
| `showAuthorBottom` | `false` | Author card at the foot of a post: avatar, name, headline, links. Adds to the byline rather than replacing it. |
| `showDateOnlyInArticle` | `false` | Date on the article page but not on listings. |
| `showHeadingAnchors` | `true` | Anchor links beside headings. Overridable per page. |
| `invertPagination` | `false` | Swap which side older and newer land on. Labels swap with the links. |
| `externalLinkForceNewTab` | `true` | External links open in a new tab. `rel="noopener"` is kept either way. |
| `showZenMode` | `false` | A control that hides the header, the TOC rail and both footers, leaving the prose. Escape leaves. Not persisted. |
| `showViews` | `false` | View counter. Needs `[params.firebase]`. |
| `showLikes` | `false` | Like button. Needs `[params.firebase]`. |
| `seriesOpened` | `false` | Whether the series navigation starts expanded. Collapsed by default: the summary line already says which part you are on. |
| `replyByEmail` | `false` | A "reply by email" link at the foot of each post. Needs `[params.author].email`; renders nothing without it. No third party, no script, and it works with JavaScript off. |
| `showEdit` | `false` | "Edit this page" link. |
| `editURL` | — | Base URL for that link. Renders nothing when unset. |
| `editAppendPath` | `true` | Append the page's own path to `editURL`. |

The edit link on the page you are reading is live. It points at this file in the theme's
own repository, built from `editURL` plus the content path.

### Sharing links

Eleven services are supported. Any post on this site shows the row live at the foot of
the article.

| Name | Goes to |
|---|---|
| `linkedin` | LinkedIn's share dialogue |
| `reddit` | Reddit's submit page, with the title prefilled |
| `mastodon` | Your configured instance's compose page |
| `bluesky` | Bluesky's compose intent |
| `hackernews` | Hacker News' submit page |
| `email` | The reader's own mail client, via `mailto:` |
| `x` | X's post intent |
| `facebook` | Facebook's sharer |
| `telegram` | Telegram's share URL |
| `whatsapp` | WhatsApp's share URL |
| `pinterest` | Pinterest's pin builder |

**Every one of these is a plain link.** No script, no SDK and no widget is loaded, so
nothing is requested from any of these services until a reader actually clicks. That is
why the list is limited to services with a documented share URL — a provider needing a
script would put a third-party request on every article page for a button most readers
never press.

**`mastodon` needs `mastodonInstance`.** Mastodon is federated, so there is no central
host to post to: the share URL belongs to an instance. A static site cannot know the
reader's own instance, and routing through a third-party instance picker would be a call
to somebody else's server on every click, so the site names the instance instead.
Listing `mastodon` without setting `mastodonInstance` fails the build rather than quietly
dropping the button.

**`email` opens a mail client**, not a website, so it is the one entry with no
`target="_blank"` — opening a `mailto:` in a new tab leaves an empty tab behind in most
browsers.

## `[params.list]` and `[params.footer]`

| Key | Default | What it does |
|---|---|---|
| `list.groupByYear` | `true` | Year headings in the post index, grouped within each page of results. |
| `list.orderByWeight` | `false` | Sort the section index by weight instead of date. Replaces the date sort entirely; unweighted pages go last. |
| `footer.showMenu` | `true` | The footer menu. |
| `footer.showAppearanceSwitcher` | `true` | The light/dark control. |
| `footer.showScrollToTop` | `true` | The back-to-top button. |
| `sitemap.excludedKinds` | `["taxonomy", "term"]` | Which page kinds stay out of `sitemap.xml`. Replaces the list rather than adding to it. |
| `list.cardView` | `false` | Render the section index as a card grid instead of a list. Year grouping does not apply to a grid, so this wins over `list.groupByYear`. |
| `taxonomy.showTermCount` | `true` | Article count beside each term. |
| `taxonomy.cardView` | `true` | Term pages as a card grid. Set `false` for the same row list the section index uses. |
| `list.showSummary` | `false` | On listings, fall back to the post's summary when it has no `description`. A `description` always wins where one exists. Off by default, because turning it on changes every listing on an existing site. |
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
