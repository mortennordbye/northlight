# Design reference

Every token in `design/northlight.html`, extracted so the theme can be built without
reverse-engineering the mockup. Values here are the source of truth for `assets/css/tokens.css`.

The brief in one sentence: **north light** — the soft, even, neutral light from a north-facing
window, which has no glare, casts no hard shadows, and stays consistent all day.

---

## Typography

Two families, both self-hosted. Do not load them from a CDN; see the security note in
`CONTRIBUTING.md`.

| Role | Family | Weights |
|---|---|---|
| Everything | Schibsted Grotesk | 400, 500, 600, 700, 800 |
| Code | Spline Sans Mono | 400, 500 |

Schibsted Grotesk was drawn for a Norwegian media group and handles dense UI and long-form
reading equally well. It was chosen over Inter deliberately — Inter is the most-used stack on
the web and reads anonymous.

### Scale

| Use | Size | Weight | Tracking | Leading |
|---|---|---|---|---|
| Home h1 | `clamp(30px, 4vw, 42px)` | 700 | -0.03em | 1.18 |
| Article h1 | `clamp(30px, 4.4vw, 46px)` | 700 | -0.032em | 1.18 |
| Prose h2 | 26px | 650 | -0.021em | 1.18 |
| Prose h3 | 20px | 600 | -0.021em | 1.18 |
| Index item h3 | 21px | 600 | -0.024em | 1.32 |
| Card h3 | 17px | 600 | -0.02em | 1.32 |
| Lede | 19px | 400 | — | 1.58 |
| Prose body | 17px | 400 | — | 1.75 |
| UI body | 16px | 400 | — | 1.6 |
| Meta | 13.5px | 400 | — | 1.6 |
| Eyebrow | 12px | 600 | 0.06em, uppercase | — |
| Code block | 13.5px | 400 | — | 1.68 |
| Inline code | 0.855em | 400 | — | inherit |

Prose measure is **68ch**. Body text never goes below 16px.

---

## Colour

One base — white and near-black — plus a pastel primary. Light and dark are designed as
separate palettes, **not inverted**: dark sits on `#0b0b0e` rather than pure black and text
drops to `#f2f2f5` rather than pure white.

### Base

| Token | Light | Dark |
|---|---|---|
| `--bg` | `#ffffff` | `#0b0b0e` |
| `--surface` | `#fafafa` | `#131317` |
| `--surface-2` | `#f4f4f5` | `#1a1a20` |
| `--line` | `#e8e8ea` | `#26262d` |
| `--line-strong` | `#d5d5da` | `#3b3b45` |
| `--fg` | `#16161a` | `#f2f2f5` |
| `--fg-2` | `#52525b` | `#a3a3ad` |
| `--fg-3` | `#6e6e75` | `#868690` |

Shadow, light: `0 1px 2px rgba(0,0,0,.04), 0 10px 30px -14px rgba(0,0,0,.14)`
Shadow, dark: `0 1px 2px rgba(0,0,0,.35), 0 10px 34px -16px rgba(0,0,0,.8)`

### The two-tone accent

This is the part that makes a pastel work. A true pastel used as link text fails contrast on
white, so each palette carries **two tones** and swaps which is which between modes:

- `--accent` is the readable one — text, links, active TOC item, the progress bar.
- `--accent-pastel` is the soft one — fills, hover borders, decorative edges. Contrast rules do
  not apply to it, so it may stay genuinely pastel in both modes.
- `--accent-tint` is a very low-alpha wash for tinted surfaces.

| Palette | Mode | `--accent` | `--accent-pastel` | `--accent-tint` |
|---|---|---|---|---|
| Periwinkle *(default)* | light | `#4f57c4` | `#a6aef0` | `rgba(79,87,196,.07)` |
| Periwinkle | dark | `#a6aef0` | `#6f78d8` | `rgba(166,174,240,.11)` |
| Sage | light | `#3f7a5c` | `#a2cdb2` | `rgba(63,122,92,.08)` |
| Sage | dark | `#a2cdb2` | `#548f6f` | `rgba(162,205,178,.11)` |
| Clay | light | `#b1523d` | `#f0a894` | `rgba(182,84,63,.08)` |
| Clay | dark | `#f0a894` | `#c4634c` | `rgba(240,168,148,.11)` |

Contrast of `--accent`, measured during phase 7 against both the page background and the
palette's own `--accent-tint` — the tint matters because that is what a featured card's eyebrow
sits on. Worst case, light mode: periwinkle 5.45:1, sage 4.57:1, clay 4.55:1.

**Clay's light tone was darkened from `#b6543f` to `#b1523d`.** The original cleared 4.9:1 on
white but only 4.37:1 on its own tint. `--fg-3` was darkened from `#8a8a92` / `#71717d` for the
same reason: 3.43:1 on the page and 3.08:1 on a tinted card, against a 4.5:1 requirement it
cannot escape, since everything it is used for is 13.5px or smaller.

The audit that produced these figures walks every text-bearing element on every page, composites
translucent backgrounds down to the root, and applies the large-text exemption only where the
computed size and weight actually earn it. It runs over three palettes × two modes × six pages.

Selection uses `--accent-tint` with `--fg` text.

### Where the accent is used

Not only links. Category eyebrows, the featured card's tint background, the blockquote wash and
left border, tag hover state, card and pager hover borders, the halo behind the brand dot, the
active TOC item, and the reading-progress bar.

### Chroma tokens

| Token class | Light | Dark | Contrast on the code surface |
|---|---|---|---|
| comment (`.c`) | `#727278` | `#7e7e89` | 4.60:1 / 4.60:1 |
| keyword (`.kc`, `.nb`) | `#7c4bc4` | `#c8aaf5` | 5.50:1 / 9.29:1 |
| string (`.s`) | `#2c7d6a` | `#86d6bd` | 4.74:1 / 10.91:1 |
| number (`.m`) | `#a4631d` | `#f0bd85` | 4.60:1 / 10.87:1 |
| name/tag (`.nt`) | `#3b5bc4` | `#a3b6f5` | 5.78:1 / 9.32:1 |

Ratios are periwinkle, measured against `--surface` (`#fafafa` light, `#131317` dark), which is
the code-block background. Sage and clay were measured too and clear 4.5:1 on every token.

**Comment and number were darkened from the mockup during phase 2.** As built,
`design/northlight.html` uses `#8a8a92` / `#71717d` for comments, which measure 3.28:1 and
3.85:1 — below the 4.5:1 floor the build plan sets for them — and `#b06a1f` / `#a8681c` for
light-mode numbers at 4.08:1 and 4.32:1. The replacements are the smallest hue-preserving shift
that clears 4.5:1. Everything else in the mockup measured clean and is unchanged.

Sage and clay override keyword/string/number/tag to sit in their own hue family; see
`design/northlight.html` for the exact per-palette values. The full Chroma class set is 81
classes, far larger than these five — `assets/css/chroma.css` maps every one of them.

---

## Space, shape, motion

**Spacing scale:** 4, 8, 12, 16, 20, 24, 32, 44, 56. Nothing off-scale.

**Layout:** page container 1120px with 24px gutters. Article body is a two-column grid —
`minmax(0,1fr)` prose plus a 216px TOC rail, 56px gap. The TOC collapses above the content
below 960px.

**Radii:** 6px tags and small chips · 8–9px buttons and icon buttons · 10–12px thumbnails and
pager cards · 14px post cards · 16px feature card, article cover and the search modal. Nothing
is fully rounded except the avatar and the brand dot.

**Borders:** 1px `--line` at rest, `--line-strong` or `--accent-pastel` on hover. Borders do the
work that shadows do in other themes; shadow is reserved for genuinely floating things (the
search modal, the back-to-top button, a card on hover).

**Motion** is deliberately small. Colour and border transitions 160ms. Shadow and border on
cards 180–200ms. Transforms 200ms on `cubic-bezier(.2,.8,.3,1)`. The reading-progress bar is
80ms linear. Card hover lifts 2px; the "view all" arrow nudges 3px. Everything is wrapped in
`@media (prefers-reduced-motion: reduce)`.

**Deliberately absent:** gradients, glass, glow, marquees, parallax, animated dividers,
decorative motion of any kind. Ten earlier directions leaned on those and were rejected for it —
see `design/explorations/` if you want to know what not to do.

---

## Covers

Post covers are **1200×630 with the title baked into the artwork**. They must render in an
exact `aspect-ratio: 1200/630` box and are never cropped. This is not a preference: cropping
cuts the title off, and it is the specific bug that forced a local hero override on the
previous theme.

Consequence worth flagging to the site author rather than solving in the theme: because the
title is in the image, a cover shown above a headline displays the title twice. The theme
renders both; the author decides whether to strip text from their cover art.

---

## Components in the mockup

`design/northlight.html` is self-contained and shows all three views. Reference it for exact
composition of: the sticky header with ⌘K search affordance, home intro with byline row,
featured card, three-up card grid, index list with covers grouped by year, article header and
meta row, sticky scroll-spy TOC, code block with filename bar and copy button, blockquote, tag
row, share buttons, prev/next pager, three-up related, footer, the search modal, and the
back-to-top button.

The mockup's bottom-right control strip (view switcher and palette swatches) is scaffolding for
reviewing the design. **It is not part of the theme** — do not port it.
