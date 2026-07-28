---
title: "Integrations"
description: "Comments, analytics, feeds, search, and the two escape hatches for everything else."
weight: 6
date: 2026-07-27
---

The theme makes **no third-party requests by default**. Fonts are self-hosted, there are
no CDN scripts and nothing calls home. Everything below is opt-in, and a site that
configures none of it ships a page that talks to nobody.

## Comments

giscus is built in, driven entirely by params. Comments are GitHub Discussions, so
moderation, threading and reactions are GitHub's rather than yours to run.

```toml {file="hugo.toml"}
[params.article]
  showComments = true

[params.comments.giscus]
  repo = "you/your-repo"
  repoId = "R_..."             # from giscus.app
  category = "Announcements"
  categoryId = "DIC_..."       # from giscus.app
  mapping = "pathname"         # optional
  reactionsEnabled = "1"       # optional
```

Leave any of the four required keys out and nothing loads. A comment system is a
third-party script, and no theme should load one by surprise.

> [!TIP]
> The widget follows **this site's** appearance toggle, not just your operating system.
> giscus renders in a cross-origin iframe that no stylesheet here can reach, so the
> theme messages it directly whenever the mode changes. Without that, switching to dark
> on a light-mode machine leaves a bright comment box under a dark article.

Using utterances, Cusdis, Remark42 or a static form instead? Copy
`layouts/_partials/comments.html` into your own site and replace it wholesale.

## Analytics

**Nothing is sent unless you configure a provider.** With none set the theme makes no
third-party request at all, and that is the shipped default.

Six providers are wired directly. Configure any subset:

```toml {file="hugo.toml"}
[params.analytics.cloudflare]
  token = "your-32-character-beacon-token"

[params.analytics.fathom]
  site = "ABCDEFGH"
  domain = "cdn.example.com"          # optional custom domain

[params.analytics.umami]
  websiteId = "your-uuid"
  domain = "analytics.example.com"    # optional self-hosted instance
  scriptName = "u.js"                 # optional, for ad-block resilience

[params.analytics.plausible]
  domain = "example.com"              # the site being measured
  host = "plausible.example.com"      # optional self-hosted instance

[params.analytics.seline]
  token = "your-token"
```

**Google Analytics uses Hugo's own key, not a theme param.** Hugo ships that template and
reads the ID from its own config, so a theme param here would be a second key that
silently did nothing:

```toml {file="hugo.toml"}
[services.googleAnalytics]
  ID = "G-XXXXXXXXXX"
```

The first five set no cookies and need no consent banner. Google Analytics does, and most
sites using it will be obliged to say so — it is wired for completeness, not preference.

> [!NOTE]
> None of these identifiers is a secret. Every one appears in the page source of every
> site using it and identifies a site rather than authorising anything. They still belong
> in your site's config and never in the theme.

Anything else — a self-hosted instance, a provider not listed, a server-side tag — goes
through `extend-head.html` or `extend-footer.html` below. All six here load at the end of
`<body>` with `defer`, so none can delay the first paint.

## Views and likes

> [!CAUTION]
> **This is the only feature in the theme that records what a reader does.** Everything
> else here either sends nothing or sends it only when you configure a vendor. Turning
> this on is a decision about your readers, not about your build.

Counters are backed by Cloud Firestore and read through its REST API. There is **no
Firebase SDK** — several hundred kilobytes to increment an integer is not a trade worth
making, and `fetch` is built in.

```toml {file="hugo.toml"}
[params.firebase]
  projectId = "your-project"
  apiKey = "your-web-api-key"
  collection = "pages"       # optional, defaults to "pages"

[params.article]
  showViews = true
  showLikes = true
```

Both are per-post overridable in front matter.

**The project id and API key are not secrets.** They identify a project and appear in the
page source of every site using them. What protects your data is Firestore **security
rules**, which are yours to write — at minimum, allow the counter fields to be incremented
and nothing else to be written:

```js {file="firestore.rules"}
match /pages/{page} {
  allow read: if true;
  allow write: if request.resource.data.keys().hasOnly(['views', 'likes']);
}
```

Counts are incremented server-side in a single transaction, so two readers arriving
together both count. A like is remembered in the reader's own browser, not on the server,
so it is per-device rather than per-person — which is the honest limit of a counter with
no accounts behind it.

With JavaScript off, nothing renders. A counter that cannot count should not leave a zero
on the page pretending to be a number.

## The escape hatches

Three partials exist to be overridden, and all three survive theme upgrades.

| Partial | For |
|---|---|
| `_partials/extend-head.html` | Anything in `<head>`: a verification tag, a preconnect, a font. |
| `_partials/extend-footer.html` | Anything at the end of `<body>`: a deferred widget, a script needing the DOM. |
| `_partials/comments.html` | Any comment system. |

Copy one into your site's `layouts/_partials/` and yours wins.

Prefer the footer hook for anything script-shaped. Scripts there do not block the first
paint, which is the difference between a widget that costs a reader nothing and one that
costs them the whole page.

```html {file="layouts/_partials/extend-footer.html"}
<script defer src="https://example.com/widget.js"></script>
```

## Feeds and the search index

| Output | Path | Notes |
|---|---|---|
| RSS | `/index.xml` | Posts in `mainSections`. |
| Search index | `/index.json` | Title, URL, date, tags, summary and a thumbnail. |
| Sitemap | `/sitemap.xml` | Taxonomy and term pages excluded. |
| robots | `/robots.txt` | Needs `enableRobotsTXT = true`. |

Search is a ⌘K modal with no dependency: no Fuse.js, no Lunr. Matching is
field-weighted, with a title prefix scoring highest and a summary match lowest, and
every term must match. For a blog-sized corpus that is enough, and it saves shipping a
search library to every reader.

The index deliberately excludes post bodies. It is downloaded before the first search,
so it pays for every byte, and matching on title, tags and summary covers nearly
everything for a marginal loss in recall.

> [!IMPORTANT]
> Search is the one feature allowed to disappear without JavaScript. Everything else
> degrades: the table of contents is still a list of working links, code is still
> selectable, and the colour mode still follows the system.

Keep a page out of either:

```yaml {file="front matter"}
---
sitemap_exclude: true      # out of sitemap.xml
excludeFromSearch: true    # out of the ⌘K index
---
```

## Structured data

Every page carries JSON-LD: `BlogPosting` for a post, `WebSite` otherwise, plus a
`BreadcrumbList` wherever the page has ancestors. OpenGraph and Twitter card tags are
generated by the theme rather than by Hugo's built-in templates, so tag names appear as
the author wrote them instead of title-cased.
