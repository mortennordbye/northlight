---
title: "Why This Theme Has No Shortcodes"
description: "An audit of the theme this one replaces found roughly two thirds of it unused. Shortcodes were the largest single share of that."
date: 2025-11-12
draft: false
tags: ["design", "example"]
---

The theme Northlight replaces ships about forty-five shortcodes. An audit of every post
on the site using it found that exactly zero appeared in any of them.

## Unused surface is not free

Every shortcode is a template to maintain, a name to document, and a behaviour someone
will eventually depend on. Shipping forty-five of them to cover the handful a given site
might want is a trade that only looks good before the maintenance starts.

## What replaces them

Markdown, and render hooks for the two cases where markdown is not enough: heading
anchors and external link handling. Both apply automatically to content that is already
written, which is the opposite of a shortcode — nothing has to be sprinkled through the
posts to switch it on.

If a post genuinely needs a callout or a figure, raw HTML is enabled and the prose styles
are written not to fight an inline `style` attribute.
