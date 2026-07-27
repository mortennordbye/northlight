---
title: "Measuring Contrast Instead of Guessing"
description: "Four of the theme's own syntax colours failed the 4.5:1 floor. All four had been calculated by hand and looked fine."
date: 2026-05-04
lastmod: 2026-07-20
draft: false
tags: ["accessibility", "design"]
---

The design reference for this theme carried contrast ratios for every accent colour, worked
out by hand from the sRGB values. When they were finally measured against the surfaces they
actually sit on, several were wrong — and the ones that were wrong were the ones nobody
would have questioned.

## What failed

Comments in code blocks measured 3.28:1 in light mode and 3.85:1 in dark, against a floor
of 4.5:1. Light-mode numbers measured between 4.08 and 4.32:1 depending on the palette.

```text
comment  light  #8a8a92  3.28:1  ->  #727278  4.60:1
comment  dark   #71717d  3.85:1  ->  #7e7e89  4.60:1
number   light  #b06a1f  4.08:1  ->  #a4631d  4.60:1
```

## Why hand calculation goes wrong

Relative luminance is not lightness, and the green channel carries 72% of it. Two colours
that look equally dark can differ by a factor of two once weighted, which is exactly the
error that puts a grey at 3.3:1 while it reads as comfortably mid-tone.

## Measure against the real surface

Code sits on `--surface`, not on the page background. A comment grey measured against white
clears the floor; the same grey measured against the code block it actually sits in does
not. Sample the rendered page, not the palette.
