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

## `button`

A link styled as a call to action, for the one thing you actually want the reader to do
next. It reuses the button the 404 page and the share row already use, so a button in
your content and a button in the theme's own chrome cannot drift apart.

| Parameter | Required | What it does |
|---|---|---|
| `pageRef` | one of these | A path to another page on this site |
| `href` | one of these | Any URL, for anything off-site |
| `target` | no | `_blank` to open in a new tab |
| `rel` | no | Extra relationship tokens |

```text
{{</* button pageRef="/docs/getting-started" */>}}Get started{{</* /button */>}}
```

{{< button pageRef="/docs/getting-started" >}}Get started{{< /button >}}

`target="_blank"` adds `rel="noopener"` on its own, so the opened page cannot reach back
through `window.opener`. Anything you pass in `rel` is kept alongside it:

{{< button href="https://gohugo.io/" target="_blank" >}}Hugo documentation{{< /button >}}

An unresolvable `pageRef` fails the build rather than rendering a button that goes
nowhere. A call to action that silently leads to a 404 is worse than a red build.

## `email`

A `mailto:` link with the address obfuscated at build time, so a scraper reading the raw
HTML does not find an address to harvest. Nothing here depends on JavaScript.

| Parameter | Required | What it does |
|---|---|---|
| `email` | yes | The address |
| `text` | no | Link text. Defaults to the obfuscated address |
| `subject` | no | Pre-fills the subject line |

```text
{{</* email email="you@example.com" */>}}
{{</* email email="you@example.com" text="Say hello" subject="About the theme" */>}}
```

{{< email email="you@example.com" >}} · {{< email email="you@example.com" text="Say hello" subject="About the theme" >}}

Both of those behave like ordinary links, and the address copies and pastes normally.
View source and neither is readable as an address.

Two techniques are at work, because the address appears in two places and one method
does not cover both.

The **href** is percent-encoded character by character, so `you@example.com` is written
`%79%6F%75%40…`. That is URL syntax rather than markup, which matters: the browser
decodes it before acting on the link, and nothing in the build rewrites it on the way
out. Numeric HTML entities were the obvious first choice and do not survive — Hugo's
minifier decodes them in attributes and in text alike, putting the address back in clear
exactly where a scraper reads it.

The **link text** cannot be percent-encoded, being text rather than a URL. There the `@`
and the dots are each preceded by an empty `<span>`. A pattern looking for an address
does not match across a tag boundary, while an empty span contributes nothing to the
text content, so selection and copy-paste are unaffected.

Be honest about what this buys: it stops naive address harvesting and nothing more.
Anything that renders the page reads the address fine. The reason to prefer it over the
alternatives is what it does *not* break — obfuscating with JavaScript stops working
with scripting off, and the CSS reversal trick breaks copy and paste.
