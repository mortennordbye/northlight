---
title: "Writing content"
description: "Front matter, admonitions, images, code fences, tables and embeds. Every example on this page is live."
weight: 3
date: 2026-07-27
# Deliberately later than `date` but on the same calendar day. This is the fixture for
# the "no updated date when it renders as the same day" case in tests/run.sh: the theme
# compares the formatted dates, not the timestamps, so nothing should render here.
lastmod: 2026-07-27T18:00:00Z
---

The theme adds nothing to Markdown that Markdown cannot already express. There are no
shortcodes, and that is deliberate: a shortcode is theme-specific syntax, so content
written with it only renders correctly inside this theme. Everything below is either
standard Markdown or a render hook that enriches it, so the same files render fine
anywhere, just plainer.

## Front matter

| Key | What it does |
|---|---|
| `title`, `description`, `date`, `draft`, `tags` | The standard set. `description` becomes the lede, the meta description, the card summary and the RSS description. |
| `lastmod` | Updated date. Shown only when `showDateUpdated` is on and this is later than `date`. |
| `showTableOfContents` | Per-post override of the site default. |
| `showHero` | Hide the cover on one post. |
| `coverAlt` | Alt text for the cover. Empty by default, correct for artwork that repeats the title. |
| `robots` | `noindex, follow` and similar. Cascades, so setting it on a section covers everything under it. |
| `sitemap_exclude` | Keep a page out of `sitemap.xml`. |
| `excludeFromSearch` | Keep a page out of the ⌘K index. Separate from the above, because "do not index this" and "do not surface this in site search" are different intentions. |
| `externalUrl` | Point the listing entry at another site. |
| `editURL`, `editAppendPath` | Per-page override of the edit link. |

## Admonitions

Callouts use GitHub's alert syntax. Paste any of these into a GitHub README and they
render as ordinary blockquotes: quieter, but never broken.

```markdown
> [!WARNING]
> Renaming a published config key is a breaking change.
```

All five, live:

> [!NOTE]
> Useful information a reader should notice even when skimming.

> [!TIP]
> Optional, but it will make something easier.

> [!IMPORTANT]
> Necessary to succeed. Not optional.

> [!WARNING]
> Needs immediate attention because of the risk it carries.

> [!CAUTION]
> Consequences of getting it wrong.

Their colours sit outside the palette system, because a caution should read as a caution
whether the site runs periwinkle, sage or clay. Every label and body colour is measured
at 4.5:1 or better against its own tinted background in both modes.

An unrecognised type emits a build warning and falls back to a plain blockquote, so a
typo surfaces at build time rather than in production.

A plain blockquote still looks like a plain blockquote:

> The theme replaces a larger one. An audit found roughly two thirds of that theme
> unused by the site it served, which is the whole reason this one exists.

## Images

Write an ordinary Markdown image. Local images get intrinsic width and height so the
article never reflows as they load, a `srcset` capped at the original, and lazy loading.

```markdown
![A wide diagram of the build pipeline](pipeline.png "How the pieces fit")
```

The quoted title becomes a caption. Captions need
`wrapStandAloneImageWithinParagraph = false` and only apply to an image alone in its own
paragraph, because a `<figure>` inside a `<p>` is invalid HTML.

### Dark variants

Drop `diagram-dark.png` beside `diagram.png` and it is used whenever the dark palette is
active. Toggle the appearance control in the header and watch the diagram below change:

![Markdown passes through a render hook and comes out as themed HTML](render-hooks.png "This image has a dark counterpart. Switch modes and it swaps.")

It is two `<img>` elements and CSS rather than a `<picture>` element with a
`prefers-color-scheme` source. A media query only knows what the operating system wants,
and this theme lets a reader override that, so `<picture>` would show the wrong artwork
to exactly the readers who cared enough to choose.

Remote URLs and anything in `static/` pass through with lazy loading and nothing else.
Hugo cannot measure a file it does not manage, and a made-up width is worse than none.
SVG and GIF skip resizing too: SVG has no raster size, and a resized GIF stops animating.

## Code

Fences work as normal. Add `{file="..."}` and the block grows a filename bar:

````markdown
```go {file="main.go"}
func main() {}
```
````

Which renders as:

```go {file="main.go"}
package main

import "fmt"

// Every Chroma token class is styled for both colour modes. Comments in
// particular are measured, because they are the first thing to fail contrast.
func main() {
	things := map[string]int{"alpha": 1, "beta": 2}
	for name, count := range things {
		fmt.Printf("%s = %d\n", name, count)
	}
}
```

```yaml {file="docker-compose.yml"}
services:
  web:
    image: nginx:1.27-alpine
    ports:
      - "8080:80"
    environment:
      TZ: Europe/Oslo
```

All 84 Chroma token classes are styled for light and dark, and every one is verified at
4.5:1 or better against the code background.

## Tables

Wide tables scroll inside their own container rather than pushing the page sideways. The
container is focusable, because a scrollable region that cannot be focused is
unreachable without a mouse.

| Component | Degrades to | Needs JavaScript |
|---|---|---|
| Table of contents | A plain list of working links | For scroll-spy only |
| Code copy | Selectable code | Yes |
| Appearance toggle | Follows `prefers-color-scheme` | For the override only |
| Search | Nothing. It disappears. | Yes |
| Reading progress | Nothing | Yes |

## Embedded media

Raw HTML never passes through a render hook, so embeds are handled in CSS instead. A
pasted embed carrying `width="1200"` is contained rather than allowed to break the
layout on a phone.

<iframe srcdoc="<div style='font:15px system-ui;display:grid;place-items:center;height:100%;color:#666'>An embedded frame, contained at 16/9</div>" title="An example embed" width="1200" height="675"></iframe>

`iframe` elements have no intrinsic aspect ratio, so 16/9 is assumed because video is
what people actually embed. Anything else overrides it inline:

```html
<iframe src="..." style="aspect-ratio: 4/3"></iframe>
```

## Footnotes

Standard Markdown footnotes work and are linked in both directions.[^1]

[^1]: Which is the point. Nothing here is theme-specific syntax.
