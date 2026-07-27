# Design explorations

> **The approved design is [`../design/northlight.html`](northlight.html)** — referred to below
> as direction 11, "Clarity", which was its working name before the theme was named Northlight.
> The other ten directions live in [`explorations/`](explorations/) and are kept only as context
> for *why* the final one looks the way it does. Do not build from them.
>
> For the tokens extracted from the approved design, see [`../docs/DESIGN.md`](../docs/DESIGN.md).

Standalone HTML mockups for the Blowfish replacement. Open any file directly in a browser.
Each one carries a floating control in the bottom-right: **Home / Index / Article** switches
view, and the last button toggles light and dark. Content is the real six posts, real titles,
dates, tags and word counts, so the layouts are judged against what the site actually holds.

Every file also demonstrates the Tier 0 item that is easiest to underestimate: Chroma-class
syntax highlighting in both light and dark, using the real class names (`.nt`, `.s`, `.c`,
`.kc`, `.nb`). Fonts load from Google Fonts for preview convenience; the real theme should
self-host them.

## Batch one — conventional directions

| # | File | Idea | Type | Palette |
|---|---|---|---|---|
| 1 | `1-broadsheet.html` | Editorial. Serif display, drop cap, wide margins, rules between sections | Fraunces + Inter | Warm paper, rust accent |
| 2 | `2-console.html` | Terminal. Prompt nav, directory-listing index, `├─` TOC tree, window-chrome code blocks | JetBrains Mono | OLED black, green + amber |
| 3 | `3-grid.html` | Swiss. Strict 12-column grid, hairline rules, numbered entries, zero rounding, zero shadow | Inter + IBM Plex Mono | Black/white, orange-red |
| 4 | `4-aurora.html` | Bento. Rounded glass cards on a gradient mesh, pill tags, stat tiles | Plus Jakarta Sans + Inter | Indigo → cyan |
| 5 | `5-manual.html` | Docs. Persistent sidebar, dense table index, right TOC, callouts, filename code tabs | IBM Plex Sans/Mono | GitHub-ish blue |

Direction 5 is the closest to what a code-heavy long-form blog usually wants, and the closest
to your current `github` colour scheme.

## Batch two — deliberately off the beaten path

Uncommon typefaces, unusual palettes, and interaction patterns that are not the default
fade-up-on-scroll and rounded gradient pill.

| # | File | Idea | Type | Palette | The unusual part |
|---|---|---|---|---|---|
| 6 | `6-blueprint.html` | Drafting / CAD sheet. Dimension-line dividers, title block, sheet numbering | Familjen Grotesk + Azeret Mono | Blueprint navy, cyan, orange | Corner brackets that grow to enclose a card on hover; dimension lines that draw themselves; cursor crosshair with live x/y readout over the drawing |
| 7 | `7-risograph.html` | Two-ink zine print. Halftone paper texture, overprint, marquee ticker | Bricolage Grotesque + Instrument Sans | Fluoro pink + teal on newsprint cream | Deliberate misregistration — ink layers offset on hover using `steps()` so it snaps like a press, never eases. Hard-offset shadows with no blur |
| 8 | `8-transit.html` | Wayfinding. Index is a route line, posts are stations, tags are route badges | Unbounded + Archivo | Deep green, amber, signal red | Route line draws down the page; station dots spring on hover and slide a platform sign out; buttons wipe colour from a leading stripe |
| 9 | `9-strata.html` | Geological core sample. Posts are layers with depth markers; article TOC is a depth column sized by section length | Gloock + Figtree + Martian Mono | Clay, ochre, petrol, moss on sand | Layers expand with the `grid-template-rows: 0fr → 1fr` technique; buttons are stacked slabs whose strata separate on hover |
| 10 | `10-marginalia.html` | Tufte-style sidenotes. Real margin notes aligned to their own paragraph, not footnotes at the bottom | Newsreader + Literata + Kode Mono | Graphite with citron | Notes resolve from blur as they scroll into view via `animation-timeline: view()`; hovering a paragraph draws a hairline connecting it to its note |

## Batch three — the restrained one

Directions 1–10 were all concept-led, and the concept is the problem: they read as themed
rather than as a blog. Direction 11 drops the concept entirely.

| # | File | Idea | Type | Palettes |
|---|---|---|---|---|
| 11 | `northlight.html` | No concept. Modern, quiet, content-first. The craft is in the spacing rhythm, type scale and restraint | Schibsted Grotesk + Spline Sans Mono | Periwinkle / sage / clay, each with a separate light and dark |

### Type

**Schibsted Grotesk** for everything, **Spline Sans Mono** for code. Both are on Google Fonts
and both are uncommon on the web — the first draft used Inter Tight + Inter + JetBrains Mono,
which is the single most-used stack on the modern web and reads anonymous as a result.
Schibsted Grotesk was drawn for a Norwegian media group, is built for dense UI and long-form
reading at the same time, and has enough character in the `g`, `a` and `y` to not look like a
system font.

### Colour

One base — white and near-black — plus a pastel primary. Two accent tones per mode:

- `--accent` is the readable one, used for text, links and the active TOC item.
- `--accent-pastel` is the soft one, used for fills, borders and hovers, where WCAG contrast
  rules do not apply.

That split is what lets a pastel work at all. A true pastel used for link text fails contrast
on white, so light mode uses the deeper tone of the same hue for text and keeps the pastel for
surfaces; dark mode swaps them. Computed contrast against the page background: periwinkle
`#4f57c4` ≈ 6.0:1, sage `#3f7a5c` ≈ 5.1:1, clay `#b6543f` ≈ 4.9:1 — all clear AA for body text.
Calculated by hand, not verified with a tool.

The accent now does real work rather than only colouring links: category eyebrows, the featured
card's tint, blockquote wash, tag hovers, card and pager hover borders, the brand dot's halo.

Light and dark are **designed as separate palettes, not inverted** — dark uses `#0b0b0e` rather
than pure black and text drops to `#f2f2f5` rather than pure white.

### Beyond the first draft

Added after the first pass: a ⌘K search modal with cover thumbnails and keyboard navigation, a
scroll-spy TOC wired to real heading IDs via IntersectionObserver, a 2px reading-progress bar,
a back-to-top button, hover anchor links on headings, a skip-to-content link, `::selection`
colour, and styled scrollbars.

Deliberately absent: gradients, glass, glow, marquees, misregistration, animated dividers,
route lines, corner brackets. Motion is limited to 160–200ms colour transitions, a 2px card
lift, and an arrow nudge on hover.

## Covers

All ten use the **real post covers** from `blog/content/blog/*/featured.png`, not placeholder
art. They are embedded as base64 JPEG data URIs in CSS custom properties (`--cov-cilium`,
`--cov-waf`, …), so every file is still a single portable document with no external requests.
Each file is around 315 KB as a result.

Every listing on every page now shows its cover — home, index, and article hero — at the exact
**1200×630 box with no cropping**, which is the same problem your local
`blog/layouts/partials/hero/basic.html` override exists to solve. To re-generate after changing
a cover, resize to 800px wide and re-embed; the helper class is `.cov .cov-<name>`.

Note the covers have the post title baked into the artwork, so in the designs that show a cover
and a headline together the title appears twice. That is worth deciding on deliberately: either
lean into it as a magazine would, or drop the text from the cover art.

## Verified

Rendered at 1440×1000 in Chromium after the cover work: directions 1, 2, 3, 5, 6, 7, 8, 9, 10
confirmed visually, and the view switcher confirmed working. **4-aurora was verified before the
cover change but not after** — its change was small (two thumbnails added, one column widened).

Known rough edges, all cosmetic:

- `4-aurora.html` — the bento feature card's 1200×630 thumbnail makes that cell very tall, so
  the profile tile beside it leaves dead space.
- `8-transit.html`, `9-strata.html` — `align-items: end` on the hero grid drops a visible gap
  between the headline and the paragraph beneath it.
- `6-blueprint.html` — the dimension label reads "1200 × 630" above a drawing whose viewBox is
  1200 × 460.
- `7-risograph.html` — the dark navy covers fight the two-ink pink/teal concept. This direction
  needs either lighter covers or a cover treatment (duotone filter) to stay coherent.

Fixed along the way: `5-manual.html` had `.ti` and `.ds` as inline spans, so every table row ran
the title and description together on one line. Both are now `display:block`.

## Accessibility notes

All ten respect `prefers-reduced-motion`, keep visible focus rings, use SVG icons rather than
emoji, and were built to keep body text at or above 4.5:1 in both themes. The accents are
decorative or used on large text; body copy is always the ink colour. Contrast has not been
measured with a tool.
