---
title: "Appearance"
description: "Palettes, colour modes, your own CSS, custom fonts and logos."
weight: 4
date: 2026-07-27
---

The theme is named after north light: the soft, even, neutral light from a north-facing
window that has no glare and stays consistent all day. That is the whole design brief.

## Colour modes

Two modes, designed separately rather than one inverted into the other. Mode switching
uses `color-scheme` plus the CSS `light-dark()` function, so each mode-dependent colour
is declared once with both values rather than being repeated in an override block.

A reader with JavaScript disabled still follows their operating system, because that
mechanism is pure CSS. The toggle in the header only exists to override it, and it
removes the stored preference when your choice matches the system again, handing control
back rather than freezing the page.

> [!NOTE]
> There is no flash on load. A small render-blocking script in `<head>` pins the mode
> before first paint. It is the only script the theme loads that way, and it is worth
> the cost precisely once.

## Palettes

Three, set with `colorScheme`:

| Value | Character |
|---|---|
| `periwinkle` | The default. Cool, quiet blue-violet. |
| `sage` | Muted green. |
| `clay` | Warm terracotta. |

Three considered palettes rather than sixteen. Every accent is measured against its own
background in both modes, which is work that does not scale to a colour picker.

## Your own CSS

Create `assets/css/custom.css` in your site. The theme picks it up automatically, with
nothing to configure, and appends it to its own stylesheet, so it is minified and
fingerprinted with everything else and costs no extra request. Being last in the
cascade, a plain rule beats the theme's equivalent at the same specificity.

Retuning a token is usually tidier than overriding a rule:

```css {file="assets/css/custom.css"}
:root {
  --measure: 40rem;             /* a narrower prose column */
}

html[data-palette="clay"] {
  --accent: #9c4737;            /* your own take on clay */
}
```

Every token is a custom property in `assets/css/tokens.css`. Colour, spacing, type
scale, radii and motion durations all live there, and component CSS references
`var(--x)` rather than hardcoding a value. Adding a palette means adding one block.

This very site uses the hook twice: for the documentation index cards on `/docs/`, which
are a layout the theme does not have, and for print styles, which the theme has no
opinion about.

## Custom fonts

Same hook. Put the files in your site's `assets/` or `static/`, declare the faces in
`custom.css`, and point the type tokens at them:

```css {file="assets/css/custom.css"}
@font-face {
  font-family: "Your Face";
  src: url("/fonts/your-face.woff2") format("woff2");
  font-display: swap;
}

:root {
  --font-sans: "Your Face", system-ui, sans-serif;
}
```

> [!WARNING]
> The theme's own faces ship with metric-matched fallbacks so the page does not reflow
> when the webfont arrives. A replacement without matched metrics reintroduces that
> shift. The measure is deliberately a fixed length rather than `ch` for the same
> reason: `ch` depends on the current font, so the column itself moves when the font
> swaps.

## Logos

```toml {file="hugo.toml"}
[params]
  logo = "images/logo.svg"
  logoDark = "images/logo-dark.svg"   # optional
```

A logo replaces the dot and the wordmark together, because a mark next to a name next to
a dot is three brand elements competing. With only `logo` set, the same file is used in
both modes, which is right for anything with transparency and enough contrast either
way.

## Overriding a template

Hugo's lookup order means any theme file can be replaced by putting a file of the same
name at the same path in your own site. Nothing needs patching and nothing is lost on
upgrade.

The page listing at `/docs/` is a live example: the theme's `section.html` is a post
index with covers and year headings, which is right for a blog and wrong for a manual.
This site ships `layouts/docs/section.html` and it wins. Deleting that one file restores
the theme's behaviour.

Two partials exist purely as escape hatches and are meant to be overridden:
`extend-head.html` and `extend-footer.html`. See [Integrations](../integrations/).
