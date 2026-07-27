---
title: "Two Modes, Not One Inverted"
description: "Dark mode built by flipping the lightness of a light palette looks like a light palette with the lights off. The two are designed separately here."
date: 2025-09-30
draft: false
tags: ["design", "colour"]
---

Inverting a palette is the cheapest way to get a dark mode and the easiest one to spot.
Pure white text on pure black vibrates; mid greys that read as calm on white read as murky
on black; and a saturated accent that was comfortable at 6:1 becomes a glare at 15:1.

## What changes between the modes

Dark sits on `#0b0b0e` rather than `#000000`, and text drops to `#f2f2f5` rather than
`#ffffff`. Both decisions reduce the contrast between the extremes from punishing to
comfortable without going anywhere near the AA floor.

## The accent swaps roles

Each palette carries two tones. The readable one carries text and links; the soft one
carries fills, hover borders and washes, where contrast rules do not apply. Between light
and dark the two swap places, which is the only reason a genuine pastel can be the primary
colour of a theme at all.

> A pastel used as link text on white fails contrast every time. Used as a fill behind
> dark text, the same colour is fine. The trick is never asking one tone to do both.
