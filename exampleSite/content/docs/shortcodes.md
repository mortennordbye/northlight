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

## `swatches`

A row of colour chips, each labelled with its own hex value. Takes as many colours as
you give it, positionally.

```text
{{</* swatches "#4f57c4" "#a6aef0" "#f4f4f5" */>}}
```

{{< swatches "#4f57c4" "#a6aef0" "#f4f4f5" >}}

The hex value is rendered as text beside each chip rather than tucked into a `title`.
A bare block of colour carries its meaning in the colour alone, which is the one thing
that does not survive a screen reader, a greyscale print, or a reader who cannot tell
the two chips apart. The label is the feature.

Values must be hex — three, four, six or eight digits. Anything else fails the build
rather than rendering a chip with no colour, on the same reasoning as `button` and its
unresolvable `pageRef`: a swatch that silently shows nothing is worse than a red build,
because nobody notices it.

The chips wrap onto a second line on a narrow screen instead of scrolling sideways.
A row of swatches has no reading order to preserve, so there is nothing to be gained by
keeping it on one line.

## `ltr` and `rtl`

Marks a block as running in the other direction from the page around it.

These are the per-block counterpart to the site-wide `rtl` setting in
[Configuration]({{< ref "configuration" >}}), which turns the whole site right-to-left.
Reach for that one for a site written in Arabic, Hebrew, Persian or Urdu; reach for these
for a quotation, an address or an example in the other direction on a page that is not.

```text
{{</* rtl */>}}
هذا النص يعمل من اليمين إلى اليسار، والترقيم في نهايته يقع على اليسار.
{{</* /rtl */>}}
```

{{< rtl >}}
هذا النص يعمل من اليمين إلى اليسار، والترقيم في نهايته يقع على اليسار.
{{< /rtl >}}

`ltr` is the mirror. On a left-to-right page it does nothing visible, which is why the
example below nests it inside an `rtl` block: a command line or a citation is the case
where you need to opt back out of the surrounding direction, and it is the only case
where you can see it working.

```text
{{</* rtl */>}}
لتثبيت السمة، شغّل الأمر التالي:
{{</* ltr */>}}
`git submodule add https://github.com/you/northlight themes/northlight`
{{</* /ltr */>}}
{{</* /rtl */>}}
```

{{< rtl >}}
لتثبيت السمة، شغّل الأمر التالي:
{{< ltr >}}
`git submodule add https://github.com/you/northlight themes/northlight`
{{< /ltr >}}
{{< /rtl >}}

Without the inner `ltr`, the trailing path and punctuation of that command get pulled
around by the bidirectional algorithm and the line becomes unreadable.

## `article`

Embeds one post as a card, given its path.

```text
{{</* article link="/blog/hello-northlight" */>}}
```

{{< article link="/blog/hello-northlight" >}}

| Parameter | Required | What it does |
|---|---|---|
| `link` | yes | Path to the page, as `ref` understands it |

The card is the same one the home page and taxonomy pages use, so an embedded post cannot
drift away from a listed one. The cover renders at its exact aspect ratio, and a draft, an
external link post or a post with no cover all behave here as they do in a listing.

A path that resolves to nothing fails the build. The alternative is a card with no title
linking nowhere, which reads as a styling bug rather than a broken reference and survives
every review, including the one where somebody renames the post it pointed at.

## `list`

Embeds recent posts, using the same row the post index uses.

```text
{{</* list limit="2" */>}}
```

{{< list limit="2" >}}

| Parameter | Required | What it does |
|---|---|---|
| `limit` | no | How many to show. Default 3 |
| `title` | no | A heading above the list |
| `where` | no | A taxonomy to filter on, such as `tags` |
| `value` | with `where` | The term to match within that taxonomy |

Filtered to one term, with a heading:

```text
{{</* list where="tags" value="example" title="More on this" limit="2" */>}}
```

{{< list where="tags" value="example" title="More on this" limit="2" >}}

Posts come from `mainSections`, so this lists what your site calls posts rather than every
page in the build.

Heading levels are chosen so the block nests wherever you put it. A page's own sections
are `h2`, so the items are `h3`; given a `title`, that becomes the `h3` and the items drop
to `h4`. Left at the level the post index uses, the items would read as *ending* the
section they sit inside, which matters to anyone navigating by heading.

`where` and `value` go together, and each without the other fails the build. So does a
filter that matches no posts: an empty result renders as nothing at all, which is
indistinguishable from having forgotten the shortcode, and it is almost always a typo or a
term that was renamed out from under the reference.

## `keyword` and `keywordList`

A wrapping row of labelled pills, for a set of things listed together: the stack behind a
project, the topics a post covers, the tools a piece of work used.

```text
{{</* keywordList */>}}
{{</* keyword icon="github" */>}}Open source{{</* /keyword */>}}
{{</* keyword */>}}Hugo{{</* /keyword */>}}
{{</* keyword */>}}No JavaScript framework{{</* /keyword */>}}
{{</* /keywordList */>}}
```

{{< keywordList >}}
{{< keyword icon="github" >}}Open source{{< /keyword >}}
{{< keyword >}}Hugo{{< /keyword >}}
{{< keyword >}}No JavaScript framework{{< /keyword >}}
{{< /keywordList >}}

| Parameter | Required | What it does |
|---|---|---|
| `icon` | no | An icon name from the [`icon`](#icon) set, shown before the label |

A keyword deliberately shares a shape with [`badge`](#badge), because both are small
labels and a reader should not have to learn two visual languages for that. They are not
interchangeable though: a badge marks one thing inside a sentence, a keyword is one of a
set. Neither is a tag — tags carry link behaviour and a taxonomy behind them.

The inner text is required. An icon on its own would be a pill whose meaning the reader
has to guess, so leaving the label out fails the build rather than rendering it.

The row wraps at narrow widths rather than scrolling.

## `icon`

Puts one of the theme's inline SVG icons into your content.

```text
Built with {{</* icon "github" */>}} and hosted anywhere.
```

Built with {{< icon "github" >}} and hosted anywhere.

No size parameter, and none is needed: an icon is 1em square, so it takes the size of
whatever text it sits in and follows body copy, a heading or a caption without being
told. Colour comes from `currentColor` for the same reason.

### The full set

These names are the whole set, and they are a stable surface — the theme treats renaming
one as a breaking change, the same as renaming a config key.

| | | | |
|---|---|---|---|
| {{< icon "github" >}} `github` | {{< icon "linkedin" >}} `linkedin` | {{< icon "reddit" >}} `reddit` | {{< icon "rss" >}} `rss` |
| {{< icon "link" >}} `link` | {{< icon "external" >}} `external` | {{< icon "search" >}} `search` | {{< icon "pencil" >}} `pencil` |
| {{< icon "arrow-left" >}} `arrow-left` | {{< icon "arrow-right" >}} `arrow-right` | {{< icon "arrow-up" >}} `arrow-up` | {{< icon "chevron-down" >}} `chevron-down` |
| {{< icon "moon" >}} `moon` | {{< icon "sun" >}} `sun` | {{< icon "copy" >}} `copy` | {{< icon "check" >}} `check` |
| {{< icon "info" >}} `info` | {{< icon "bulb" >}} `bulb` | {{< icon "megaphone" >}} `megaphone` | {{< icon "alert" >}} `alert` |
| {{< icon "octagon" >}} `octagon` | | | |

The last five are the admonition marks, and they are drawn to be told apart by outline
alone rather than by the colour beside them.

A name that is not on this list fails the build rather than rendering an empty gap.

The icon is marked `aria-hidden`, which is right for what it is: decoration next to a
word. There is no parameter for a text alternative, deliberately. An icon that carries
meaning on its own needs the word written next to it, and an icon whose meaning a reader
has to guess is a problem for sighted readers too.

Both set a `dir` attribute rather than a CSS `direction` property, which is the part
worth understanding. `dir` is real HTML, not a styling convention: it drives the
bidirectional algorithm, text alignment, list markers and punctuation placement all at
once, and it keeps working in a reader-mode view or a feed reader that has thrown the
stylesheet away. A CSS property would only handle the first of those, and only while the
stylesheet loads.
