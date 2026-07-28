---
title: "Why This Theme Has No Shortcodes"
description: "An audit of the theme this one replaces found roughly two thirds of it unused. Shortcodes were the largest single share of that."
date: 2025-11-12
draft: false
heroStyle: "big"
tags: ["design", "example"]
---

The theme Northlight replaces ships about forty-five shortcodes. An audit of every post
on the site using it found that exactly zero appeared in any of them.

## Unused surface is not free

Every shortcode is a template to maintain, a name to document, and a behaviour someone
will eventually depend on. Shipping forty-five of them to cover the handful a given site
might want is a trade that only looks good before the maintenance starts.

## What replaces them

Markdown, and render hooks for the cases where markdown alone is not enough. A hook
applies automatically to content that is already written, which is the opposite of a
shortcode: nothing has to be sprinkled through the posts to switch it on.

![Markdown passes through a render hook and comes out as themed HTML](render-hooks.png "The same three steps apply to headings, links, tables, images and code fences.")

The distinction that matters is portability. A shortcode is theme-specific syntax, so
content written with it only renders correctly inside this theme. A render hook enriches
standard markdown, so the same file renders fine anywhere — just plainer.

## Admonitions

Callouts use GitHub's alert syntax rather than a shortcode, for exactly that reason:

> [!NOTE]
> The source for this block is four ordinary lines of markdown. Paste it into a GitHub
> README or a plain markdown previewer and it renders as a blockquote — quieter, but
> never broken.

> [!TIP]
> Give a code fence a `{file="path/to/thing.yaml"}` attribute and it grows a filename
> bar. Another hook, same idea.

> [!IMPORTANT]
> Five types are recognised: note, tip, important, warning and caution. Their colours sit
> outside the palette system, because a caution should be red whether the site is running
> periwinkle, sage or clay.

> [!WARNING]
> An unrecognised alert type is not silently ignored. It emits a build warning and falls
> back to a plain blockquote, so a typo surfaces at build time rather than in production.

> [!CAUTION]
> Renaming a published config param is a breaking change. Once a theme is public, its
> config keys are API.

## Images

The image hook does the unglamorous work. Every local image ships with its intrinsic
width and height, so the article never reflows as pictures arrive, and it generates a
`srcset` — the prose column is 44.2rem wide, so serving a 2400px screenshot at full size
costs a reader roughly three times the bytes they can actually use.

A markdown title becomes the caption, as on the diagram above.
