---
title: "Shortcodes"
description: "The shortcodes the theme adds to Markdown, what each one costs you, and when to reach for plain Markdown instead."
weight: 4
date: 2026-07-27
---

{{< lead >}}
Everything on this page is rendered by the theme as you read it. Nothing below is a
screenshot or a code sample pretending to be output.
{{< /lead >}}

## The trade you are making

A shortcode is theme-specific syntax. Content written with one renders correctly inside
this theme and nowhere else — move the post to another theme, or to a plain Markdown
renderer, and you get the raw `{{</* … */>}}` text back. That is a real cost, and it is
why [Writing content]({{< ref "writing" >}}) is the page to read first: admonitions,
responsive images, captions, code filenames and tables are all render hooks over standard
Markdown, so they cost you nothing and they are the better answer wherever they fit.

Reach for a shortcode when Markdown genuinely cannot express the thing. Everything here
is additive: no shortcode replaces a Markdown path, and removing one from your content
leaves the rest of the page working.

## `lead`

An introductory paragraph, set larger and lighter than body text.

A post's `description` in front matter already renders this way at the top of the page,
so most posts do not need this. Use it for a lede *inside* the body, or when the
description is busy being the meta description, the card summary and the feed entry, and
you want different words on the page.

```text
{{</* lead */>}}
Everything on this page is rendered by the theme as you read it.
{{</* /lead */>}}
```

Inner content is Markdown, rendered through the same configuration as the rest of the
page, so links, emphasis and footnotes behave normally:

{{< lead >}}
The soft, even, neutral light from a north-facing window — no glare, and the
same all day. That is the whole [design brief]({{< ref "appearance" >}}).
{{< /lead >}}

## `badge`

A small inline label, for a status or a piece of metadata that belongs in the run of
the text rather than in front matter.

```text
Northlight {{</* badge */>}}0.3.0{{</* /badge */>}} is a theme, not a framework.
```

Northlight {{< badge >}}0.3.0{{< /badge >}} is a theme, not a framework. It takes the
same shape as a tag — chip radius, hairline border — because both are small labels and
a reader should not have to learn two visual languages for that.

Inner content is rendered inline, so emphasis and links work: {{< badge >}}**bold**{{< /badge >}}
and {{< badge >}}[a link]({{< ref "getting-started" >}}){{< /badge >}}. A paragraph does
not, and should not — a badge sits inside a line.
