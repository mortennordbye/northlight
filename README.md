<div align="center">

# 🪟 Northlight

### A quiet, readable Hugo theme for technical writing.

[![Hugo](https://img.shields.io/badge/Hugo-0.164%2B%20extended-FF4088?logo=hugo&logoColor=white)](https://gohugo.io) [![CSS](https://img.shields.io/badge/CSS-hand--written-1572B6?logo=css&logoColor=white)](assets/css) [![JavaScript](https://img.shields.io/badge/JavaScript-vanilla-F7DF1E?logo=javascript&logoColor=black)](assets/js) [![Docker](https://img.shields.io/badge/Docker-containerised%20build-2496ED?logo=docker&logoColor=white)](Makefile)

[![CI](https://github.com/mortennordbye/northlight/actions/workflows/ci.yml/badge.svg)](https://github.com/mortennordbye/northlight/actions/workflows/ci.yml) [![Audit](https://github.com/mortennordbye/northlight/actions/workflows/audit.yml/badge.svg)](https://github.com/mortennordbye/northlight/actions/workflows/audit.yml) [![Pages](https://github.com/mortennordbye/northlight/actions/workflows/pages.yml/badge.svg)](https://github.com/mortennordbye/northlight/actions/workflows/pages.yml) [![Scorecard](https://api.securityscorecards.dev/projects/github.com/mortennordbye/northlight/badge)](https://scorecard.dev/viewer/?uri=github.com/mortennordbye/northlight)

[![Lighthouse SEO](https://img.shields.io/badge/Lighthouse_SEO-100-brightgreen?style=flat-square&logo=lighthouse&logoColor=white)](#audited-output) [![Accessibility](https://img.shields.io/badge/Accessibility-100-brightgreen?style=flat-square&logo=lighthouse&logoColor=white)](#audited-output) [![Best Practices](https://img.shields.io/badge/Best_Practices-100-brightgreen?style=flat-square&logo=lighthouse&logoColor=white)](#audited-output)

[![License](https://img.shields.io/github/license/mortennordbye/northlight?style=flat-square)](LICENSE) [![Last Commit](https://img.shields.io/github/last-commit/mortennordbye/northlight?style=flat-square)](https://github.com/mortennordbye/northlight/commits/main) [![Stars](https://img.shields.io/github/stars/mortennordbye/northlight?style=flat-square)](https://github.com/mortennordbye/northlight/stargazers)

North light is the soft, even light from a north-facing window — no glare, no hard shadows, the
same all day. That is the whole brief. Northlight has no concept to get between you and the
words: no gradients, no glass, no glow, no decorative motion. What it has instead is a careful
type scale, a spacing rhythm that holds, syntax highlighting that works in both colour modes,
and a dark mode designed rather than inverted.

**[Demo and documentation](https://mortennordbye.github.io/northlight/docs/)** · Screenshots:
[light](images/screenshot.png) · the same page in both modes and all three palettes is in
[`design/northlight.html`](design/northlight.html).

</div>

---

## Overview

| Area | What you get |
| ---- | ------------ |
| Reading | Sticky scroll-spy table of contents, reading progress, heading anchors |
| Code | Chroma class-based highlighting styled for light and dark, filename bar, copy button |
| Search | A ⌘K modal with cover thumbnails and keyboard navigation |
| Covers | Rendered at their exact aspect ratio and never cropped |
| Post furniture | Tags, related posts, prev/next, share links, a comments hook |
| Home page | Ten layouts, from a full archive to a photo grid, chosen with one setting |
| Shortcodes | Eighteen, and a render hook wherever plain Markdown can do the job instead |
| Feeds | RSS, JSON search index, sitemap and robots.txt |
| Palettes | Periwinkle, sage and clay, each in a designed light and dark mode |

Content is enriched through render hooks wherever Markdown can express it, so posts stay
portable: admonitions use GitHub's alert syntax, and prose images get intrinsic dimensions, a
`srcset` and optional captions with nothing theme-specific in the source. A site can add its own
`assets/css/custom.css` and it is folded into the theme's fingerprinted bundle automatically.

Everything interactive degrades. With JavaScript off the site stays readable and navigable, the
table of contents is still a list of working links, tabbed panels become headed sections, and the
colour mode falls back to `prefers-color-scheme`. Only search disappears.

### Design

Open [`design/northlight.html`](design/northlight.html) in a browser. It is a single
self-contained file showing the home page, the post index and a full article, in both colour
modes and three palettes. That mockup is the approved visual target.

Type is **Schibsted Grotesk** with **Spline Sans Mono** for code — chosen over the near-universal
Inter and JetBrains Mono because a theme should not look like every other theme.

Colour is a white and near-black base plus one pastel primary. Each palette carries two accent
tones, a readable one for text and links and a genuinely pastel one for fills and hovers, which is
what lets a pastel work without failing contrast.

---

## Getting started

**Requirements:** Hugo **extended** 0.164.0 or newer. Nothing else — no Node, no npm, no CSS
framework, no build step beyond Hugo itself.

0.164.0 is the floor because the theme is built on the template system Hugo introduced in 0.146
and on the light/dark Chroma style pairs added in 0.164.

1. **Add the theme.** As a git submodule (recommended — no Go toolchain needed):

   ```bash
   git submodule add https://github.com/mortennordbye/northlight.git themes/northlight
   ```

   ```toml
   # hugo.toml
   theme = "northlight"
   ```

   If you build in CI, remember `submodules: recursive` on the checkout step.

   Or as a Hugo Module, which needs Go available wherever you build:

   ```bash
   hugo mod init github.com/you/your-site
   ```

   ```toml
   # hugo.toml
   [module]
     [[module.imports]]
       path = "github.com/mortennordbye/northlight"
   ```

2. **Configure.** Copy [`exampleSite/hugo.toml`](exampleSite/hugo.toml) as your starting point.
   It is a working file with every option in it and a comment on each.

3. **Run.**

   ```bash
   hugo server
   ```

### The config this theme cannot run without

Everything else is optional and has a default. These are not:

```toml
[markup.highlight]
  noClasses = false        # syntax highlighting uses CSS classes, which this theme styles.
                           # Leave it true and code blocks render unstyled.

[outputs]
  home = ["HTML", "RSS", "JSON"]   # JSON is the search index. Drop it and search finds nothing.

[taxonomies]
  tag = "tags"             # the theme reads the `tags` taxonomy for tag rows and related posts

[markup.goldmark.parser]
  wrapStandAloneImageWithinParagraph = false   # lets an image on its own line become a
                                               # <figure> with a caption. Without it, images
                                               # still work — they just never get captions.
```

Add these two if they apply to you:

```toml
[markup.goldmark.renderer]
  unsafe = true            # only if your posts contain raw HTML. Your call, not the theme's.

[related]                  # required for params.article.showRelated — Hugo's default indices
  includeNewer = true      # cover `keywords`, which this theme does not use
  threshold = 80
  toLower = false
  [[related.indices]]
    name = "tags"
    weight = 100
  [[related.indices]]
    name = "date"
    weight = 10
```

**Config keys are API.** Once released, a key is not renamed or repurposed without a major
version bump — see [`CHANGELOG.md`](CHANGELOG.md).

---

## Documentation

**The demo site is the manual: <https://mortennordbye.github.io/northlight/docs/>**

Every page there is built by the theme, so each one *demonstrates* the feature it documents
rather than describing it. It is generated from `exampleSite/content/docs/`, which means a change
to the theme and a change to its documentation are the same pull request — the documentation
cannot drift, because it is the integration test.

That is also why the full configuration reference is not repeated here. A table of parameters in
a README is a second copy that goes stale quietly; the pages below are rendered by the code they
describe.

| Page | What is on it |
| ---- | ------------- |
| [Getting started](https://mortennordbye.github.io/northlight/docs/getting-started/) | Install, required config, first post |
| [Configuration](https://mortennordbye.github.io/northlight/docs/configuration/) | Every `site.Params` key, its default and what it changes |
| [Writing content](https://mortennordbye.github.io/northlight/docs/writing/) | Front matter, admonitions, images, covers, code fences, tables |
| [Shortcodes](https://mortennordbye.github.io/northlight/docs/shortcodes/) | All nineteen, each running live on the page |
| [Appearance](https://mortennordbye.github.io/northlight/docs/appearance/) | Palettes, colour modes, the ten home layouts, custom CSS |
| [Integrations](https://mortennordbye.github.io/northlight/docs/integrations/) | Comments, analytics, verification tags, the head and footer hooks |
| [Translating](https://mortennordbye.github.io/northlight/docs/translating/) | The string catalogue, and adding a language |

---

## Development

Everything runs in a container. Do not install Hugo on your host.

```bash
make serve    # dev server on http://localhost:1313
make build    # production build of exampleSite
make check    # the gate: build with warnings as errors, then run the test suite
make test     # run the test suite against the current build
make clean
```

```text
northlight/
├── layouts/            # the theme: baseof, page templates, _partials/, _markup/ render hooks
├── assets/{css,js}/    # hand-written CSS and small vanilla-JS modules, each optional
├── i18n/               # every user-facing string; en.toml is the catalogue
├── static/             # files copied verbatim
├── exampleSite/        # demo site, documentation and integration test in one
├── tests/run.sh        # the assertion suite `make check` runs against the build
├── design/             # the approved visual target, plus ten rejected explorations
├── docs/               # SPEC, BUILD-PLAN, DESIGN tokens, FEATURE-SURVEY, AUTOMATION
├── Makefile            # every workflow, containerised
└── theme.toml          # Hugo theme gallery metadata
```

---

## Audited output

A theme is only as good as the HTML it emits, so that is measured on every pull request rather
than asserted here. **SEO, accessibility and best practices are required to stay at 100** across
five routes covering a home page, a list, an article with images and admonitions, a documentation
page and a taxonomy. The build fails if any of them drops, so the badges above are an enforced
floor rather than a snapshot of a good day.

Performance is reported but not gated: it is timing-sensitive on shared runners, and a check that
goes red at random is a check people learn to ignore.

A second job runs `lychee` over the built HTML, checking internal links and heading anchors,
including the fragments the generated table of contents points at.

None of it replaces `tests/run.sh`, which asserts the SEO furniture *exists* — sitemap,
`robots.txt`, `rel=canonical`, OpenGraph, JSON-LD that is not double-encoded, an `alt` on every
image. The audit judges whether it is *correct*.

[`docs/AUTOMATION.md`](docs/AUTOMATION.md) documents the workflows, the audit thresholds, the
required checks and how a release is cut.

---

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first. It documents the working rules, including the
invariants that are easy to break by accident: covers are never cropped, Chroma needs both colour
modes, asset fingerprinting is mandatory, and nothing author-specific belongs in theme files.

Known gaps that are deliberately deferred live in [`BACKLOG.md`](BACKLOG.md).

Security issues go through [private vulnerability reporting](SECURITY.md), not a public issue.

## Licence

MIT. See [`LICENSE`](LICENSE).

---

<div align="center">

### ⭐ Star this repo if you find it useful ⭐

<a href="https://www.star-history.com/#mortennordbye/northlight&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=mortennordbye/northlight&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=mortennordbye/northlight&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=mortennordbye/northlight&type=Date" width="600" />
  </picture>
</a>

Made by [Morten Victor Nordbye](https://nordbye.it)

</div>
