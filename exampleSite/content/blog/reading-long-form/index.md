---
title: "Setting Long-Form Text for the Screen"
description: "Measure, leading and scale are the whole job. A second post so prev/next, related content and the post index have something real to work with."
date: 2026-02-08
draft: false
tags: ["typography", "example"]
---

A page of body copy is mostly one decision repeated: how far the eye travels before it
has to find the next line. Everything else in a reading layout is downstream of that.

## Measure comes first

Northlight sets prose at 68 characters. Below about 45 the eye reverses too often and the
rhythm breaks; past about 80 it loses the start of the next line on the return sweep. The
range is wide, and 68 sits where a 17px face with generous leading stays comfortable on a
laptop without stranding a column of whitespace beside it.

The measure is set in `ch` units rather than pixels, so it follows the font size instead of
fighting it.

### Leading follows measure

Longer lines need more leading. At 68 characters, 1.75 keeps the lines distinct without
opening gaps that break the paragraph into stripes.

> The two settings are one setting. Changing the measure without changing the leading is how
> a layout ends up technically correct and unpleasant to read.

## Scale, and how little of it you need

Six sizes cover a blog: a page title, two heading levels, a lede, body, and meta. Anything
more and the steps stop being distinguishable, which defeats the point of having them.

- Page title, fluid between 30 and 46px
- Section heading at 26px
- Subsection at 20px
- Lede at 19px, body at 17px
- Meta at 13.5px

#### A fourth level, for completeness

It exists, it appears in the table of contents, and it is styled — but four levels of
heading in one post usually means the post wanted to be two posts.
