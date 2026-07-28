#!/bin/sh
# Northlight test suite.
#
# Runs against a built exampleSite. `make check` builds first and then calls this, so
# run it that way rather than directly unless you know the output is current.
#
# POSIX sh and the tools any Unix already has, on purpose. This theme has no Node
# toolchain and no package manager, and a test suite that reintroduced one would undo
# the main thing the build is trying to protect. python3 is used only for JSON and XML
# validity, and those checks skip with a warning rather than failing if it is absent.
#
# Every assertion here exists because something broke. Adding a feature means adding a
# case; see "Shipping a feature" in CONTRIBUTING.md.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PUBLIC="$ROOT/exampleSite/public"
PASS=0
FAIL=0
SKIP=0

red()   { printf '\033[31m%s\033[0m\n' "$1"; }
green() { printf '\033[32m%s\033[0m\n' "$1"; }
grey()  { printf '\033[90m%s\033[0m\n' "$1"; }

ok()   { PASS=$((PASS + 1)); grey "  ok    $1"; }
bad()  { FAIL=$((FAIL + 1)); red   "  FAIL  $1"; [ $# -gt 1 ] && printf '        %s\n' "$2"; }
skip() { SKIP=$((SKIP + 1)); grey "  skip  $1"; }

group() { printf '\n%s\n' "$1"; }

# assert_file <path> <label>
assert_file() {
  if [ -f "$1" ]; then ok "$2"; else bad "$2" "missing: ${1#"$ROOT"/}"; fi
}

# assert_grep <pattern> <file> <label>   -- pattern must be present
assert_grep() {
  if grep -q "$1" "$2" 2>/dev/null; then ok "$3"; else bad "$3" "no match for /$1/ in ${2#"$ROOT"/}"; fi
}

# refute_grep <pattern> <file> <label>   -- pattern must be absent
refute_grep() {
  if grep -q "$1" "$2" 2>/dev/null; then bad "$3" "unexpected match for /$1/ in ${2#"$ROOT"/}"; else ok "$3"; fi
}

# without_comments <file>  -- the file with Go template comments stripped
#
# Six assertions in this suite have now been written as "this file must not contain X",
# only to match the comment above the code explaining why X is wrong. Anchoring each one
# to syntax works but has to be remembered every time; stripping the comments first is the
# general fix, and it is what any "the source must not say X" check should read from.
without_comments() {
  sed -e 's|{{- \{0,1\}/\*|\n&|g' "$1" | sed -e '/{{-\{0,1\} *\/\*/,/\*\/ *-\{0,1\}}}/d'
}

# assert_count <expected> <actual> <label>
assert_count() {
  if [ "$1" = "$2" ]; then ok "$3"; else bad "$3" "expected $1, got $2"; fi
}

HAVE_PY=0
command -v python3 >/dev/null 2>&1 && HAVE_PY=1

# --------------------------------------------------------------------------------
group "Build output"

assert_file "$PUBLIC/index.html"   "home page built"
assert_file "$PUBLIC/index.xml"    "RSS feed built"
assert_file "$PUBLIC/index.json"   "search index built"
assert_file "$PUBLIC/sitemap.xml"  "sitemap built"
assert_file "$PUBLIC/404.html"     "404 built"
assert_file "$PUBLIC/robots.txt"   "robots.txt built"

for route in blog tags docs docs/getting-started docs/configuration docs/writing \
             docs/appearance docs/integrations docs/translating; do
  assert_file "$PUBLIC/$route/index.html" "route /$route/ built"
done

# --------------------------------------------------------------------------------
group "Assets: fingerprinting and integrity"
# Sites cache these as immutable for a year on the strength of the hash in the name.
# Losing the fingerprint is a year-long stale-asset bug on every site using the theme.

CSS_REF=$(grep -o 'css/northlight[^"]*\.css' "$PUBLIC/index.html" | head -1)
JS_REF=$(grep -o 'js/northlight[^"]*\.js' "$PUBLIC/index.html" | head -1)

# A long hex run, not merely "has two dots": northlight.min.css would satisfy that and
# carries no hash at all, which is exactly how a dropped fingerprint slips through.
if printf '%s' "$CSS_REF" | grep -qE '[0-9a-f]{40,}\.css$'; then
  ok "CSS filename carries a content hash"
else
  bad "CSS filename carries a content hash" "got: ${CSS_REF:-none}"
fi
if printf '%s' "$JS_REF" | grep -qE '[0-9a-f]{40,}\.js$'; then
  ok "JS filename carries a content hash"
else
  bad "JS filename carries a content hash" "got: ${JS_REF:-none}"
fi

assert_grep 'integrity=' "$PUBLIC/index.html" "subresource integrity present"
[ -n "$CSS_REF" ] && assert_file "$PUBLIC/$CSS_REF" "referenced stylesheet exists"
[ -n "$JS_REF" ]  && assert_file "$PUBLIC/$JS_REF"  "referenced script exists"

# --------------------------------------------------------------------------------
group "Theme purity"
# A theme is copied verbatim into other people's repositories. Nothing about any one
# author may appear in it.
#
# `assets/js/vendor/` is excluded from every scan in this group. It holds third-party
# libraries committed verbatim, which are not ours to edit and are held to their own
# upstream standards — a minified bundle happening to contain one of these words in a
# comment would be a false positive, not a leak. Everything the theme actually authors
# lives outside that directory and is still scanned.
VENDOR_SKIP="--exclude-dir=vendor"

if grep -rqi $VENDOR_SKIP 'nordbye' "$ROOT/layouts" "$ROOT/assets" "$ROOT/static" "$ROOT/i18n" 2>/dev/null; then
  bad "no author-specific values in theme files" "grep -ri nordbye matched"
else
  ok "no author-specific values in theme files"
fi

if grep -rqiE $VENDOR_SKIP 'claude|anthropic|copilot' \
     "$ROOT/layouts" "$ROOT/assets" "$ROOT/i18n" "$ROOT/README.md" 2>/dev/null; then
  bad "no AI tool attribution in theme or docs" "matched a tool name"
else
  ok "no AI tool attribution in theme or docs"
fi

# Vendored code has to be attributable. A minified blob with no record of what it is or
# what licence it carries is the kind of thing that becomes nobody's problem until it is
# everybody's, so each file needs a row in the manifest.
for f in "$ROOT/assets/js/vendor"/*.js; do
  [ -e "$f" ] || continue
  b=$(basename "$f")
  if grep -q "$b" "$ROOT/assets/js/vendor/VENDOR.md" 2>/dev/null; then
    ok "vendored $b is recorded in VENDOR.md"
  else
    bad "vendored $b is recorded in VENDOR.md" "no row for $b"
  fi
done

# --------------------------------------------------------------------------------
group "Feeds and the search index"

if [ "$HAVE_PY" = 1 ]; then
  if python3 -c "import json,sys; json.load(open('$PUBLIC/index.json'))" 2>/dev/null; then
    ok "index.json is valid JSON"
  else
    bad "index.json is valid JSON"
  fi
  for f in index.xml sitemap.xml; do
    if python3 -c "import xml.dom.minidom as m; m.parse('$PUBLIC/$f')" 2>/dev/null; then
      ok "$f is well-formed XML"
    else
      bad "$f is well-formed XML"
    fi
  done
else
  skip "JSON and XML validity (python3 not found)"
fi

# Taxonomies are excluded from the sitemap by design.
refute_grep '/tags/' "$PUBLIC/sitemap.xml" "sitemap excludes taxonomy pages"

# The manual is outside mainSections, so it must not reach blog surfaces.
refute_grep '/docs/' "$PUBLIC/index.json" "docs stay out of the search index"
refute_grep '/docs/' "$PUBLIC/index.xml"  "docs stay out of the RSS feed"
# Host-agnostic: CI builds with the Pages base URL, not the demo's example.com.
#
# On a multilingual site Hugo turns the root sitemap.xml into a *sitemap index* pointing at
# one sitemap per language, so grepping the root file for page URLs finds nothing. Search
# every sitemap rather than the root one: that is what a crawler does, and it keeps this
# assertion true whether or not the site has more than one language.
DOC_URLS=$(find "$PUBLIC" -name 'sitemap.xml' -exec grep -ohE 'https?://[^<]*/docs/[a-z-]+/' {} + | sort -u | wc -l | tr -d ' ')
# Counted from the docs section itself rather than hardcoded: the number went from seven
# to eight when the RTL page landed, and a literal here just moves the maintenance from
# the sitemap to this line.
# -mindepth 2 skips /docs/ itself: the URL pattern above matches sub-pages only, and
# counting the section index made the two disagree by one.
DOC_PAGES=$(find "$PUBLIC/docs" -mindepth 2 -maxdepth 2 -name 'index.html' | wc -l | tr -d ' ')
assert_count "$DOC_PAGES" "$DOC_URLS" "every docs page is in the sitemap"

# excludeFromSearch keeps a page out of the index without keeping it off the site.
refute_grep 'a-link-post' "$PUBLIC/index.json" "excludeFromSearch keeps a post out of the index"
assert_file "$PUBLIC/blog/a-link-post/index.html" "excluded post still builds"

# --------------------------------------------------------------------------------
group "Structured data and head"

assert_grep 'application/ld+json'  "$PUBLIC/blog/measuring/index.html" "JSON-LD emitted on a post"
assert_grep 'BlogPosting'          "$PUBLIC/blog/measuring/index.html" "post uses BlogPosting"
assert_grep 'BreadcrumbList'       "$PUBLIC/blog/measuring/index.html" "BreadcrumbList emitted"
assert_grep 'og:title'             "$PUBLIC/blog/measuring/index.html" "OpenGraph tags emitted"
assert_grep 'rel=canonical'        "$PUBLIC/blog/measuring/index.html" "canonical URL emitted"
# JSON-LD must be a JSON object, not a double-encoded string. This regressed once.
refute_grep 'ld+json">"'           "$PUBLIC/blog/measuring/index.html" "JSON-LD is not double-encoded"

# --------------------------------------------------------------------------------
group "Content rendering"

WRITING="$PUBLIC/docs/writing/index.html"

ADMONITIONS=$(grep -o 'class="admonition admonition-' "$WRITING" | wc -l | tr -d ' ')
assert_count 5 "$ADMONITIONS" "all five admonition types render"
for kind in note tip important warning caution; do
  assert_grep "admonition-$kind" "$WRITING" "admonition type: $kind"
done

# Every prose image must declare its size, or the article reflows as it loads.
assert_grep 'width=1600 height=470' "$WRITING" "prose images carry intrinsic dimensions"
assert_grep 'srcset='               "$WRITING" "prose images carry a srcset"
assert_grep 'loading=lazy'          "$WRITING" "prose images are lazy loaded"
assert_grep 'class=img-light'       "$WRITING" "light image of a dark-variant pair"
assert_grep 'class=img-dark'        "$WRITING" "dark image of a dark-variant pair"
assert_grep '<figcaption>'          "$WRITING" "image captions render"

# Whitespace between inline elements collapses to a visible space. A template that ends
# with a newline after an inline closing tag therefore puts a space between it and
# whatever follows — only noticeable, and then unmissable, when what follows is
# punctuation: "see the docs ." instead of "see the docs."
#
# Every inline-producing template is a candidate, so this checks the whole build rather
# than one page and every inline tag rather than one: it depends on how a sentence was
# written, not on which template rendered it. The link render hook and the badge
# shortcode have each shipped this bug.
DANGLING=$(find "$PUBLIC" -name '*.html' | while read -r f; do
  awk -v f="$f" '
    p && /^[.,;:!?)]/ { print f; exit }
    { p = /<\/(a|span|code|em|strong|abbr|kbd|small|sup|sub)>$/ }
  ' "$f"
done | head -1)
if [ -n "$DANGLING" ]; then
  bad "no space between an inline element and the punctuation after it" "${DANGLING#"$ROOT"/}"
else
  ok "no space between an inline element and the punctuation after it"
fi
assert_grep 'code-bar'              "$WRITING" "code fence filename bar renders"
assert_grep 'table-wrap'            "$WRITING" "tables get a scroll container"
assert_grep 'footnotes'             "$WRITING" "footnotes render"

# An image with no alt attribute at all is a bug; alt="" is a deliberate choice.
# The minifier rewrites alt="" to a bare `alt`, which is still an alt attribute and is
# the correct markup for decorative images.
if grep -o '<img [^>]*>' "$WRITING" | grep -qvE 'alt=|alt[ >]'; then
  bad "every rendered image has an alt attribute" "$(grep -o '<img [^>]*>' "$WRITING" | grep -vE 'alt=|alt[ >]' | head -1)"
else
  ok "every rendered image has an alt attribute"
fi

# --------------------------------------------------------------------------------
group "Shortcodes"

SHORTCODES="$PUBLIC/docs/shortcodes/index.html"

assert_file "$SHORTCODES" "the shortcodes documentation page builds"

# Showing a shortcode call in a code fence needs the escaped form, {{</* … */>}}.
# Without it Hugo executes the call even inside a fence, the example silently vanishes
# from the documentation, and the page renders the feature where it meant to describe
# it. Nothing else catches that: the build stays green and the page still looks fine.
# The escaped form reaches the reader as {{&lt; … &gt;}}, so assert on that.
assert_grep '{{&lt; lead &gt;}}' "$SHORTCODES" "shortcode calls shown in code fences stay literal"

# lead: reuses the article lede class rather than defining a parallel one, so this
# assertion also guards against someone giving it type tokens of its own.
# Three, not two: the page's own `description` renders as a lede above the body, which
# is exactly the overlap the shortcode's documentation warns about.
LEADS=$(grep -o 'class=lede' "$SHORTCODES" | wc -l | tr -d ' ')
assert_count 3 "$LEADS" "lead renders as a lede block"

# badge: inline rendering is the whole point of the RenderString call — without the
# inline display Hugo wraps the inner text in a <p>, which breaks the line box the
# badge sits in. Assert on the markup rather than on the class alone.
assert_grep '<span class=badge>' "$SHORTCODES" "badge renders as an inline chip"

# button: pageRef must resolve to a real URL, not be echoed as written, and _blank must
# bring rel=noopener with it or the opened page can reach back through window.opener.
# Host-agnostic, like the sitemap check above: CI builds with the Pages base URL, which
# has a path prefix, so a leading `/docs/` only matches on a site served from the root.
assert_grep 'class=button href=[^ >]*/docs/getting-started/' "$SHORTCODES" \
  "button resolves pageRef to a URL"

# email: the whole point is that the address is not in the source as an address. Assert
# both halves — the href is percent-encoded, and the link text does not spell the
# address out either.
#
# Percent-escapes rather than HTML entities, because the minifier decodes numeric
# entities in attributes and in text, which hands the address straight back to a
# scraper. Assert the whole encoded string, not a prefix: encoding only the first
# character would pass a looser check.
assert_grep 'href=mailto:%79%6F%75%40%65%78%61%6D%70%6C%65%2E%63%6F%6D' "$SHORTCODES" \
  "email percent-encodes the address in the href"

# The second half cannot be a check over the whole page: this page documents the
# shortcode, so its code-fence examples necessarily show the address the way an author
# types it. Scope it to the rendered anchors — split the markup on <a, keep the mailto
# ones, cut each at its own </a>. Anchors cannot nest, so truncating at the first close
# tag is safe. Guard on having found any: a refute over an empty string passes for the
# wrong reason.
MAILTOS=$(tr '\n' ' ' < "$SHORTCODES" | sed 's|<a |\
<a |g' | grep '^<a [^>]*mailto:' | sed 's|</a>.*|</a>|')
if [ -z "$MAILTOS" ]; then
  bad "email leaves no plain address in the rendered link" "no mailto link on the page"
elif printf '%s\n' "$MAILTOS" | grep -q 'you@example\.com'; then
  bad "email leaves no plain address in the rendered link" \
      "$(printf '%s\n' "$MAILTOS" | grep 'you@example\.com' | head -1)"
else
  ok "email leaves no plain address in the rendered link"
fi
# swatches: the colour has to survive into a style attribute. Go refuses to interpolate
# an unvalidated value into one and emits ZgotmplZ instead, which renders as a chip with
# no colour and no error — so assert the declaration is really there, and assert the
# label separately, since a chip without its hex is a block of colour and nothing else.
assert_grep 'class=swatch-chip style=background:#4f57c4' "$SHORTCODES" \
  "swatches puts the colour in the style attribute"
refute_grep 'ZgotmplZ' "$SHORTCODES" "no value was rejected by the template escaper"
SWATCHES=$(grep -o 'class=swatch-hex>#[0-9a-fA-F]*' "$SHORTCODES" | wc -l | tr -d ' ')
assert_count 3 "$SWATCHES" "swatches labels every chip with its hex value"

# ltr/rtl: the guarantee is a `dir` attribute, not a class that happens to look the same.
# `dir` is real HTML — it drives the bidirectional algorithm, alignment, list markers and
# punctuation placement together, and it survives a reader-mode view or a feed reader that
# has dropped the stylesheet. A CSS class does none of that while looking identical in a
# browser, so it would be an easy and invisible regression. Assert on the attribute.
assert_grep '<div dir=rtl>' "$SHORTCODES" "rtl marks the block with a dir attribute"
assert_grep '<div dir=ltr>' "$SHORTCODES" "ltr marks the block with a dir attribute"

# icon: exposing the partial makes the icon names a public surface, so the documented set
# and the real set have to be the same set. Compare them directly rather than counting:
# a number here would need bumping by hand, and the failure it is guarding against is
# precisely that somebody changed the icons and did not think about the documentation.
#
# This covers the half the build cannot: an icon added to the partial and never written
# up. The other half is already fatal earlier — a documented name that no longer exists
# makes the partial warn, and the gate runs with --panicOnWarning, so the build stops
# before the suite starts. Renaming an icon trips both at once.
#
# Names come from the docs table, where each entry pairs the rendered icon with its label
# as `</span> <code>name</code>`, which also proves the label belongs to a real icon.
ICONS_DEFINED=$(sed -n '/\$icons := dict/,/^-}}/p' "$ROOT/layouts/_partials/icon.html" \
  | grep -oE '^ *"[a-z-]+"' | tr -d ' "' | sort)
ICONS_SHOWN=$(grep -o '</span> <code>[a-z-]*</code>' "$SHORTCODES" \
  | sed 's|</span> <code>||; s|</code>||' | sort)
if [ -z "$ICONS_DEFINED" ]; then
  bad "the documented icon set matches the real one" "read no icon names from the partial"
elif [ "$ICONS_DEFINED" = "$ICONS_SHOWN" ]; then
  ok "the documented icon set matches the real one"
else
  bad "the documented icon set matches the real one" \
      "partial: $(printf '%s' "$ICONS_DEFINED" | tr '\n' ' ') / docs: $(printf '%s' "$ICONS_SHOWN" | tr '\n' ' ')"
fi

# keyword: Hugo wraps the nested shortcodes in a <p>, which would become one flex item
# holding every pill and collapse the row to a single line item. `.keywords > p` is set to
# `display: contents` to let the pills be the flex items instead. Assert the <p> is really
# there, because the CSS rule that neutralises it looks like dead code otherwise and is
# exactly the kind of thing a later cleanup deletes.
assert_grep '<div class=keywords><p><span class=keyword>' "$SHORTCODES" \
  "keywordList wraps its pills in the paragraph the CSS expects"
KEYWORDS=$(grep -o '<span class=keyword>' "$SHORTCODES" | wc -l | tr -d ' ')
assert_count 3 "$KEYWORDS" "keywordList renders every pill"

# article: the point is that it reuses `_partials/card.html` rather than growing a second
# card. Assert the real card markup, not a wrapper class — a hand-rolled lookalike would
# satisfy a check on `.article-embed` alone and then drift from the listing cards, which is
# the whole failure this shortcode exists to avoid.
assert_grep '<div class=article-embed><a class=card href=[^ >]*/blog/' "$SHORTCODES" \
  "article embeds a real post card"
assert_grep 'class=card-cover' "$SHORTCODES" "the embedded card keeps its cover"

# list: reuses the post index row, but at a heading level that nests where it lands. The
# post index keeps h2, because there the only other heading is the list's own h1. Embedded
# in a page whose sections are already h2, an h2 item title reads as *ending* the section
# it sits inside — wrong for anyone navigating by heading, and invisible on screen, which
# is why it needs a test rather than an eyeball.
#
# Untitled: items are h3. Titled: the title takes h3 and the items drop to h4, so the
# block stays internally consistent either way.
assert_grep '<div class=post-list-embed><a class=post-item' "$SHORTCODES" \
  "list reuses the post index row"
assert_grep '<h3 class=item-title' "$SHORTCODES" "an untitled list puts its items at h3"
assert_grep '<h3 class=embed-title>' "$SHORTCODES" "a list title renders at h3"
assert_grep '<h4 class=item-title' "$SHORTCODES" "a titled list drops its items to h4"

# The whole point of the level parameter is that the post index did not move.
assert_grep '<h2 class=item-title' "$PUBLIC/blog/index.html" \
  "the post index keeps its own heading level"

# No heading level may be skipped anywhere on the shortcodes page. This page now carries
# h1 through h4 from three different sources — its own Markdown, the list embeds and the
# icon table — so a skip is easy to introduce and impossible to see.
DOCLEVELS=$(grep -oE '<h[1-6][ >]' "$SHORTCODES" | grep -oE '[1-6]' | sort -u | tr -d '\n')
case "$DOCLEVELS" in
  1234|123|12) ok "heading levels on the shortcodes page descend without a gap" ;;
  *) bad "heading levels on the shortcodes page descend without a gap" "levels present: $DOCLEVELS" ;;
esac

# figure: the whole reason it goes through img-attrs.html is to get the identical srcset,
# sizes and intrinsic dimensions a Markdown image gets. A hand-rolled <img src> would look
# right on a fast desktop connection and cost a phone the full-size file forever, so assert
# the pipeline attributes rather than the tag.
assert_grep '<figure><a href=[^ >]*/docs/writing/><img class=img-light src=[^ >]*/docs/shortcodes/diagram.png srcset=' "$SHORTCODES" \
  "figure runs through the image pipeline and can be a link"
assert_grep 'sizes="(max-width: 47rem) 100vw, 44.2rem" width=1600 height=470' "$SHORTCODES" \
  "figure declares intrinsic dimensions, so it reserves its box"
assert_grep '<figcaption>' "$SHORTCODES" "figure renders its caption"

# Dark variants, on the same terms as the render hook. The shortcode's own documentation
# claims pipeline parity, and without this it would put a light-mode diagram in the middle
# of a dark page — the exact problem the render hook exists to solve. Both images must be
# emitted; CSS decides which is shown, so a media query would not be enough.
assert_grep '<img class=img-light' "$SHORTCODES" "figure emits the light variant"
assert_grep '<img class=img-dark' "$SHORTCODES" "figure picks up a -dark sibling"

# Never cropped, the invariant that forced the previous theme's local override. Only widths
# are generated, so every srcset candidate keeps the source ratio. A fixed box would show up
# here as a height that is not proportional to its width.
assert_grep 'width=1600 height=470' "$SHORTCODES" "figure keeps the source aspect ratio"

# alert: it reuses the admonition render hook's classes rather than introducing a second
# callout style. Assert the shared class, because a parallel `.alert` block would look
# identical on the day it shipped and drift the first time either was restyled.
assert_grep '<div class="admonition admonition-warning"' "$SHORTCODES" \
  "alert reuses the admonition styling"
assert_grep '<span>Reviewed</span>' "$SHORTCODES" "alert accepts a custom title"

# timeline: role=list / role=listitem rather than a real <ol>, because a container whose
# children are shortcodes can end up with a paragraph wrapper and a <p> inside an <ol> is
# invalid. The roles are the semantics, so they are the thing worth asserting.
assert_grep '<div class=timeline role=list><div class=timeline-item role=listitem>' "$SHORTCODES" \
  "timeline exposes list semantics without invalid markup"
assert_grep 'class=timeline-dot' "$SHORTCODES" "a timeline entry without an icon gets a dot"

# accordion: the entire control is <details>/<summary>. No JavaScript, and not as a
# fallback — if this ever becomes a div with a click handler it loses keyboard operation
# and its place in the accessibility tree, and it would still look identical.
assert_grep '<details class=accordion-item' "$SHORTCODES" "accordion is built on <details>"
assert_grep '<summary class=accordion-summary>' "$SHORTCODES" "accordion panels have a real summary"

# single=true is a shared `name` on the <details>, which browsers make mutually exclusive
# natively. Both panels of that accordion must carry the *same* name, and panels of a
# different accordion must not carry one at all, or two accordions on a page would close
# each other's panels.
ACC_NAMES=$(grep -o '<details class=accordion-item name=[a-z0-9-]*' "$SHORTCODES" \
  | sed 's/.*name=//' | sort -u | wc -l | tr -d ' ')
ACC_NAMED=$(grep -c '<details class=accordion-item name=' "$SHORTCODES" | tr -d ' ')
assert_count 1 "$ACC_NAMES" "a single-open accordion shares one group name"
assert_count 2 "$ACC_NAMED" "only the single-open accordion's panels are grouped"

# The shortcodes page must not have grown a script tag for any of this.
refute_grep 'accordion.js' "$SHORTCODES" "accordion ships no JavaScript"

# gallery: it has no image handling of its own, it grids nested `figure` calls. Assert a
# real <figure> with pipeline attributes inside it — a gallery that grew its own <img> tag
# would look identical and quietly lose srcset, intrinsic dimensions and dark variants.
assert_grep '<div class="gallery gallery-3"><figure><img src=[^ >]*/docs/shortcodes/shot-a.png srcset=' "$SHORTCODES" \
  "gallery grids real figures, pipeline included"

# The never-crop invariant, in the place most likely to break it. Every image grid in the
# wild uses object-fit: cover to force a uniform box, and a cover here is 1200×630 with its
# title inside the artwork, so a crop destroys it. Assert the CSS never gains one.
# Anchored to a declaration rather than the bare word, because the comment above the
# gallery rules explains why object-fit is absent and a naive grep matches its own
# documentation.
if grep -qE '^[[:space:]]*object-fit[[:space:]]*:' "$ROOT/assets/css/shortcodes.css"; then
  bad "the gallery never crops its images" "an object-fit declaration appeared in shortcodes.css"
else
  ok "the gallery never crops its images"
fi

# Text direction. `text-align: left|right` is physical: it ignores `dir`, so under the
# site-wide rtl param or the `rtl` shortcode every table cell and the "next" pager pin
# themselves to the wrong edge while the surrounding block flips. `start`/`end` are
# identical under LTR and correct under RTL, so there is no case for the physical pair.
# `center` is direction-neutral and stays allowed.
#
# This is asserted across every stylesheet rather than prose alone because the bug was
# in two files, and the reason it survived is that nothing was watching for it.
# Directional properties, the wider sweep the text-align rule started. Nineteen
# declarations were converted after being measured on the RTL page — the blockquote and
# admonition accent edges sat on the left, and list indents were on the wrong side.
#
# Two files are exempt, and both exemptions are load-bearing rather than convenient:
#   chroma.css  — a code block is left-to-right even on a right-to-left page, so its
#                 line-number gutter belongs on the left in both directions.
#   the caret   — .series-summary::before is two edges of a square rotated 45° into an
#                 arrowhead. Swapping them rotates the caret rather than mirroring layout.
# `border` is in the alternation. The first version left it out to accommodate the caret,
# which meant `border-left` — the exact property the blockquote bug was in — went
# unguarded, and regressing it kept the suite green. Exemptions are now marked at the
# declaration with `/* physical: … */` and say why, rather than being whole-file excludes.
PHYSDIR=$(grep -rnE '^[[:space:]]*(margin|padding|border)-(left|right)[[:space:]]*:|^[[:space:]]*(left|right)[[:space:]]*:' \
  "$ROOT/assets/css/" | grep -v '/\* physical:' || true)
if [ -n "$PHYSDIR" ]; then
  bad "no physical directional properties survive in the CSS" \
      "$(printf '%s' "$PHYSDIR" | head -3 | tr '\n' ' ')"
else
  ok "no physical directional properties survive in the CSS"
fi

# Code stays LTR inside an RTL page. Without this the bidirectional algorithm reorders
# punctuation inside lines — `);` migrating to the wrong end of a statement.
assert_grep 'direction: ltr' "$ROOT/assets/css/chroma.css" "code blocks stay left-to-right on an RTL page"

# The RTL page itself, which is what made the sweep measurable rather than inferred.
assert_grep 'dir=rtl' "$PUBLIC/docs/rtl/index.html" "the RTL demo page renders right-to-left"
refute_grep 'dir=rtl' "$PUBLIC/docs/writing/index.html" "an LTR page is unaffected by the per-page flag"

PHYSALIGN=$(grep -rnE '^[[:space:]]*text-align[[:space:]]*:[[:space:]]*(left|right)' "$ROOT/assets/css/" || true)
if [ -n "$PHYSALIGN" ]; then
  bad "no physical text-align survives in the CSS" "$(printf '%s' "$PHYSALIGN" | head -3 | tr '\n' ' ')"
else
  ok "no physical text-align survives in the CSS"
fi

# tabs: the served markup must be the *fallback*, not the tab strip. A reader with no
# JavaScript gets a sequence of headed <section> elements with every panel visible; the
# script builds the tablist afterwards. These assertions are on the server output, so they
# are checking exactly what that reader receives.
#
# This is the most easily broken thing in the set: someone "tidying" the heading away, or
# moving role=tablist into the template, would look identical in a browser with scripting
# on and silently destroy the no-JavaScript version.
assert_grep '<section class=tab-panel data-tab-label=' "$SHORTCODES" \
  "tabs are served as headed sections, not as a tab strip"
assert_grep '<h3 class=tab-heading>' "$SHORTCODES" \
  "each panel carries a real heading for the no-JavaScript reader"
refute_grep 'role=tablist' "$SHORTCODES" \
  "the tablist is built by script, never served as markup"
refute_grep '<section class=tab-panel[^>]*hidden' "$SHORTCODES" \
  "no panel is hidden before the script runs"

# The panel headings are h3 for the same reason list's items are: a page's own sections
# are h2, and an h2 here would read as ending the section the tabs sit inside.
assert_grep 'class=tab-heading' "$SHORTCODES" "panel headings nest under the page's sections"

# carousel: scroll-snap, no script. Nothing advances on its own, so there is no motion to
# suppress and no pause control owed to anyone. If this ever grows an autoplay timer it
# also grows an obligation to prefers-reduced-motion, so assert the CSS stays declarative.
assert_grep '<div class=carousel tabindex=0 role=group aria-label=' "$SHORTCODES" \
  "the carousel is a labelled, focusable scroll region"
if grep -qE '^[[:space:]]*scroll-snap-type' "$ROOT/assets/css/shortcodes.css"; then
  ok "the carousel scrolls natively rather than by script"
else
  bad "the carousel scrolls natively rather than by script" "no scroll-snap-type declaration"
fi

# README claims a number of shortcodes ("All nineteen"). That number went stale the moment
# this shortcode landed and nothing noticed, which is the same failure the icon check below
# exists for: prose that counts something is a second copy of it. Spelled out rather than
# numeric because that is how the sentence reads.
# Counted from the shortcode files, not from headings on the docs page. The two used to
# agree until the repository cards arrived: seven shortcodes documented under one heading,
# after which a heading count understated the surface by six. The files are what a site
# author can actually call, so they are what the number should mean.
DOCCOUNT=$(ls "$ROOT/layouts/_shortcodes"/*.html | wc -l | tr -d ' ')
DOCWORD=$(awk -v n="$DOCCOUNT" 'BEGIN{
  # Runs to fifty. The list stopped at twenty-five and the shortcode count passed it the
  # moment the repository cards landed, which produced an empty word and a failure that
  # looked like a stale README rather than a short lookup table.
  split("zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twenty-one twenty-two twenty-three twenty-four twenty-five twenty-six twenty-seven twenty-eight twenty-nine thirty thirty-one thirty-two thirty-three thirty-four thirty-five thirty-six thirty-seven thirty-eight thirty-nine forty forty-one forty-two forty-three forty-four forty-five forty-six forty-seven forty-eight forty-nine fifty", w, " ")
  print w[n+1]
}')
# README names the count twice — once in the Overview table and once in the docs links —
# and the second one was missed when the first was fixed. Both are checked, because a
# number that appears twice goes stale in whichever copy nobody remembered.
DOCWORD_CAP=$(printf '%s' "$DOCWORD" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
if grep -q "All $DOCWORD, each running live on the page" "$ROOT/README.md"; then
  ok "README's docs link states the shortcode count"
else
  bad "README's docs link states the shortcode count" \
      "docs page documents $DOCCOUNT ($DOCWORD); README says: $(grep -o 'All [a-z-]*, each running live' "$ROOT/README.md" || echo 'no match')"
fi
if grep -q "| Shortcodes | $DOCWORD_CAP, and a render hook" "$ROOT/README.md"; then
  ok "README's overview table states the shortcode count"
else
  bad "README's overview table states the shortcode count" \
      "expected $DOCWORD_CAP; got: $(grep -o '| Shortcodes | [A-Za-z-]*' "$ROOT/README.md" || echo 'no match')"
fi

# video: the box carries an exact aspect-ratio, which is what reserves the space before any
# video arrives. Asserted on the computed pair rather than the author's string because the
# two are not the same thing — an interpolated *string* in a CSS value is rejected by the
# template escaper and becomes ZgotmplZ, so this also pins the conversion that avoids it.
# (The ZgotmplZ refutation above is the general net; this names the specific box.)
assert_grep 'class=video-box style=aspect-ratio:16/9' "$SHORTCODES" \
  "the video box reserves its space with an exact aspect-ratio"

# The deliberate absence, and the one most likely to be "helpfully" added back. CSS cannot
# stop playback, so an autoplay here could only respect prefers-reduced-motion via
# JavaScript, and it would therefore ignore the reader's stated preference whenever
# scripting is off.
#
# Anchored to the attribute on the tag, not the bare word: the section above documents at
# length why autoplay is absent, so a plain refutation matches its own explanation. Third
# time this trap has been worth writing down — see object-fit and ytimg below.
if grep -oE '<video[^>]*>' "$SHORTCODES" | grep -q 'autoplay'; then
  bad "the video never autoplays" "$(grep -oE '<video[^>]*autoplay[^>]*>' "$SHORTCODES" | head -1)"
else
  ok "the video never autoplays"
fi

# And the parameter does not exist to be turned on. Content that simply never passes
# autoplay would keep the rendered output clean while the parameter sat there working,
# so this reads the template rather than the output. `.Get` is how a shortcode reads a
# parameter, which makes it the thing to look for rather than the word itself.
refute_grep '\.Get "autoplay"' "$ROOT/layouts/_shortcodes/video.html" \
  "the video shortcode has no autoplay parameter to be turned on"

# A browser that cannot decode the container still gets the file, rather than an empty
# player and no way forward.
#
# Host-agnostic, like the sitemap and button checks: CI builds with the Pages base URL,
# which carries a path prefix, so a leading `/docs/` only matches on a site served from
# the root.
assert_grep '<a href=[^ >]*/docs/shortcodes/clip.mp4 download>' "$SHORTCODES" \
  "an unplayable video degrades to a download link"
assert_grep 'poster=[^ >]*/docs/shortcodes/clip.jpg' "$SHORTCODES" \
  "the poster is served, so the player is not a blank rectangle"

# The sample has to actually be a video. A zero-byte or truncated placeholder would satisfy
# every assertion above while demonstrating a broken feature, which is the specific reason
# this shortcode sat in BACKLOG.md unbuilt.
CLIP="$ROOT/exampleSite/content/docs/shortcodes/clip.mp4"
if [ -s "$CLIP" ] && head -c 12 "$CLIP" | grep -q 'ftyp'; then
  ok "the sample clip is a real MP4"
else
  bad "the sample clip is a real MP4" "missing, empty, or no ftyp box: ${CLIP#"$ROOT"/}"
fi

# youtube-lite: the entire point is that no Google host is contacted on page view. This is
# the assertion that matters — a poster fetched from ytimg.com, or an iframe present in the
# markup, would look identical to a reader and silently reintroduce the third-party request
# the facade exists to prevent.
# Scoped to URL attributes rather than the bare host name: the section documenting why the
# poster must be local names ytimg.com in its prose, and a plain refute matches its own
# explanation. Same trap as the object-fit check above.
if grep -oE '(src|srcset|href)="?[^" >]*ytimg[^" >]*' "$SHORTCODES" | grep -q .; then
  bad "the poster is local, never fetched from the video host" \
      "$(grep -oE '(src|srcset|href)="?[^" >]*ytimg[^" >]*' "$SHORTCODES" | head -1)"
else
  ok "the poster is local, never fetched from the video host"
fi
refute_grep '<iframe' "$SHORTCODES" "no iframe is served before the reader clicks"
assert_grep 'class=yt-facade href="https://www.youtube.com/watch' "$SHORTCODES" \
  "the facade is a plain link, so it works with JavaScript off"
assert_grep 'data-yt-id=' "$SHORTCODES" "the video id is available to the click handler"

# Nothing anywhere in the built site may request a third-party host on page view. The
# theme makes no calls home, and this is the check that keeps it that way as shortcodes
# accumulate. Only the facade's own href may name youtube.com, and an href is not a request.
if grep -oE '(src|href)="https?://[^"]+"' "$SHORTCODES" \
     | grep -vE 'youtube\.com/watch|gohugo\.io|github\.com|schema\.org|example\.com' \
     | grep -qE 'src="https?://'; then
  bad "no third-party asset is requested on page view" \
      "$(grep -oE 'src="https?://[^"]+"' "$SHORTCODES" | head -1)"
else
  ok "no third-party asset is requested on page view"
fi

BLANK=$(grep -o '<a class=button[^>]*_blank[^>]*>' "$SHORTCODES" | head -1)
case "$BLANK" in
  *noopener*) ok "button with target=_blank sets rel=noopener" ;;
  "") bad "button with target=_blank sets rel=noopener" "no target=_blank button found" ;;
  *)  bad "button with target=_blank sets rel=noopener" "$BLANK" ;;
esac
if grep -o '<span class=badge>[^<]*<p' "$SHORTCODES" >/dev/null; then
  bad "badge inner content stays inline" "inner content was wrapped in a paragraph"
else
  ok "badge inner content stays inline"
fi

# Every docs page must be reachable from the navigation. The shortcodes page shipped
# without a menu entry and was only findable by typing the URL — the page existed, built,
# and was linked from other pages, so nothing else noticed. This compares the docs pages
# that were built against the links in the rendered Docs dropdown.
DOCS_BUILT=$(find "$PUBLIC/docs" -mindepth 2 -maxdepth 2 -name index.html \
  | sed "s|$PUBLIC/docs/||; s|/index.html||" | sort)
DOCS_IN_NAV=$(grep -o 'href=[^ >]*/docs/[a-z-]*/' "$PUBLIC/index.html" \
  | sed 's|.*/docs/||; s|/$||' | sort -u)
MISSING=$(echo "$DOCS_BUILT" | while read -r d; do
  [ -n "$d" ] || continue
  echo "$DOCS_IN_NAV" | grep -qx "$d" || echo "$d"
done | tr '\n' ' ')
# Distinguish "one page is missing from the menu" from "the menu did not render at all".
# Without this, a broken dropdown reports every page as missing and reads like seven
# separate mistakes rather than one.
if [ -z "$(printf '%s' "$DOCS_IN_NAV" | tr -d ' ')" ]; then
  bad "every docs page is reachable from the navigation" "the Docs menu rendered no links at all"
elif [ -n "$(printf '%s' "$MISSING" | tr -d ' ')" ]; then
  bad "every docs page is reachable from the navigation" "not in the menu: $MISSING"
else
  ok "every docs page is reachable from the navigation"
fi

# --------------------------------------------------------------------------------
group "Home layouts"

# home.html is a dispatcher; the arrangements live in _partials/home/. Only the configured
# one renders in any given build, so the suite checks the default's output and the presence
# of the rest. The unknown-layout path fails the build outright and so cannot be asserted
# from here — it is exercised by hand and recorded in the plan.
for L in stack page profile hero card background split gallery archive custom; do
  assert_file "$ROOT/layouts/_partials/home/$L.html" "home layout exists: $L"
done
assert_file "$ROOT/layouts/_partials/home/intro.html" "the shared home intro block exists"

# The default is `stack`, which is the homepage this theme shipped with. A site that never
# sets the param must see no change, so these assert the original markup specifically. If
# the dispatcher ever defaults to something else, every existing site's homepage silently
# changes and this is what catches it.
assert_grep 'class=intro'      "$PUBLIC/index.html" "the default home layout is still stack"
assert_grep 'class=feature'    "$PUBLIC/index.html" "stack still renders the featured post"
assert_grep 'class=card-grid'  "$PUBLIC/index.html" "stack still renders the recent card grid"

# Covers are never cropped, in the layouts as much as anywhere. Anchored to a declaration
# rather than the bare word, because the comments explaining the rule name it.
# Scoped to the post-cover rules specifically: the profile avatar *is* deliberately
# cropped with object-fit, because a round avatar of an arbitrary photo has to be, and a
# blanket ban would forbid the one legitimate use.
BADCROP=$(awk '/\.home-hero-media img|\.home-gallery-item img/,/}/' "$ROOT/assets/css/home-layouts.css" \
  | grep -cE '^[[:space:]]*object-fit' | tr -d ' ')
assert_count 0 "$BADCROP" "no home layout crops a post cover"

# The stylesheet has to be in the bundle, or every layout but stack renders unstyled.
assert_grep 'home-layouts.css' "$ROOT/layouts/_partials/head.html" \
  "the home layout stylesheet is in the bundle"

# Every layout is rendered live by the example site's layout switcher, one page each, so a
# layout that stopped building would take a route with it. This is what makes the ten
# genuinely exercised rather than merely present as files.
for L in stack page profile hero card background split gallery archive custom; do
  assert_file "$PUBLIC/layouts/$L/index.html" "layout demo page builds: $L"
done

# base.css blockifies every svg, which takes a whole line in running text. Content hit this
# with the icon shortcode and the archive layout hit it again with its external-link mark.
# Any icon sitting inside a line of text needs the .icon-inline wrapper.
assert_grep 'icon-inline' "$PUBLIC/layouts/archive/index.html" \
  "the archive external-link mark stays on its line"

# The hover colour must stay behind :hover. A stray edit once promoted it to an
# unconditional rule, which made every gallery caption read as a visited link.
if grep -qE '^\.home-gallery-title-text \{\s*$' "$ROOT/assets/css/home-layouts.css" \
   && grep -A3 -E '^\.home-gallery-title-text \{' "$ROOT/assets/css/home-layouts.css" | grep -q 'color: var(--accent)'; then
  bad "the gallery caption colour is only applied on hover" "an unconditional accent colour is set"
else
  ok "the gallery caption colour is only applied on hover"
fi

# --------------------------------------------------------------------------------
group "Accessible names and heading order"

# Below 720px both .search-trigger-label and the kbd hint are display:none, so the button
# is reduced to an icon. Without an aria-label it is an unnamed control on every page at
# phone width, which is what Lighthouse scored as a button-name failure.
assert_grep 'class=search-trigger[^>]*aria-label=' "$PUBLIC/index.html" \
  "search trigger carries an accessible name"

# post-item.html is used only by section.html, where the only other heading is the list's
# own h1. An h3 there skips a level. The year rule is deliberately a <div>, so it does not
# fill the gap.
assert_grep '<h2 class=item-title' "$PUBLIC/blog/index.html" \
  "post list titles do not skip a heading level"
refute_grep '<h3 class=item-title' "$PUBLIC/blog/index.html" \
  "post list titles are not h3"

# The card branch of section.html has the same h1-to-h3 problem, and the two assertions
# above cannot see it: `list.cardView` is a site-level param, this demo leaves it off, so
# the post index is always the row list and the card grid in section.html is never built
# here. That made it the one heading-order path with no coverage, and it was wrong —
# `card.html` defaults to level 3, correct under the home page's h2 section-title, and
# section.html was calling it bare.
#
# So this reads the template instead of the output. A source assertion is the weaker kind
# and worth avoiding where an output one will do, but "assert on the built page" is not
# available without turning cardView on for the whole demo and changing the post index
# design to buy a test. Comments are stripped so the explanation above the call cannot
# satisfy the match.
without_comments "$ROOT/layouts/section.html" | grep -q 'partial "card.html" (dict "ctx" . "level" 2)' \
  && ok "section.html asks card.html for h2, not its home-page default of h3" \
  || bad "section.html asks card.html for h2, not its home-page default of h3" \
         "cards on a section index would skip h1 -> h3"

# Every heading level that appears on a list page must be reachable without a jump. This
# catches the general regression rather than the one instance above.
LEVELS=$(grep -oE '<h[1-6][ >]' "$PUBLIC/blog/index.html" | grep -oE '[1-6]' | sort -u | tr -d '\n')
case "$LEVELS" in
  12|1|12345|123|1234) ok "heading levels on the post index descend without a gap" ;;
  *) bad "heading levels on the post index descend without a gap" "levels present: $LEVELS" ;;
esac

# --------------------------------------------------------------------------------
group "Article features"

MEASURING="$PUBLIC/blog/measuring/index.html"
assert_grep 'Updated <time'  "$MEASURING" "updated date renders when lastmod is later"
assert_grep 'class=edit-link' "$WRITING"   "edit link renders when editURL is set"
# The updated date must not appear when lastmod equals date, or every post claims it.
refute_grep 'Updated <time' "$PUBLIC/blog/two-modes/index.html" "no updated date without a real lastmod"
# Nor when lastmod is later but renders as the same day: "27 Jul 2026 - Updated 27 Jul 2026"
# says nothing twice.
refute_grep 'Updated <time' "$WRITING" "no updated date when it renders as the same day"

# --- the last five --------------------------------------------------------------------

# Custom icons: a site file wins over a built-in of the same name, which is what makes it
# an override rather than only an addition.
assert_grep 'resources.Get (printf "icons/%s.svg"' "$ROOT/layouts/_partials/icon.html" \
  "a site can supply its own icons"

# Meta description order is configurable, defaulting to what the theme always did.
# It is resolved in social-meta.html, which head.html and the og/twitter partials all
# read, so the three never disagree about what a page says.
assert_grep 'metaDescriptionOrder' "$ROOT/layouts/_partials/social-meta.html" \
  "the meta description order is configurable"
for f in head opengraph twitter_cards; do
  assert_grep 'social-meta.html' "$ROOT/layouts/_partials/$f.html" \
    "$f.html reads the shared social meta"
done
assert_grep '<meta name=description content="Four of the theme' "$MEASURING" \
  "the default order still prefers the page description"

# author.imageQuality. Both branches of image-url.html are exercised by the demo: Morten's
# avatar is an SVG and passes through, Ada's is a JPEG and goes through the pipeline.
# Quality is a lossy-format setting — a PNG comes out identical at q20 and q85 — so the
# demo uses a JPEG deliberately.
# Literal path, not $COAUTH: that variable is set further down this file, and using it
# here failed with "unbound variable" under `set -u`.
assert_grep 'src=[^ >]*/images/profile.svg' "$PUBLIC/blog/co-authored/index.html" \
  "an SVG avatar passes through unprocessed"
assert_grep 'src=[^ >]*/images/profile-raster_hu_' "$PUBLIC/blog/co-authored/index.html" \
  "a raster avatar goes through the pipeline"
assert_grep 'imageQuality' "$ROOT/layouts/_partials/image-url.html" "the avatar honours imageQuality"

# --- the tail: toggles, hooks, importers, typeit ------------------------------------

# Every one of these defaults to the theme's existing behaviour, so what is asserted is the
# default. A toggle that silently changed what a site already renders is the failure mode.
assert_grep 'class=back-to-top' "$PUBLIC/index.html" "the scroll-to-top control renders by default"
assert_grep 'data-toggle-appearance' "$PUBLIC/index.html" "the appearance switcher renders by default"
# The brand link exists either way; what disableTextInHeader removes is the title inside
# it. Asserting the link kept the assertion green with the wordmark gone.
assert_grep '<span class=brand-dot aria-hidden=true></span>Northlight' "$PUBLIC/index.html" \
  "the header keeps its wordmark by default"
# ...and with the text hidden the link would need its own accessible name, or it becomes an
# unlabelled link on every page.
assert_grep 'disableTextInHeader }} aria-label=' "$ROOT/layouts/_partials/header.html" \
  "a logo-only header still names its home link"
refute_grep 'data-plain-scrollbar' "$PUBLIC/index.html" "scrollbars stay styled by default"
refute_grep 'data-toc-collapse' "$PUBLIC/index.html" "TOC children stay visible by default"
assert_grep 'class=heading-anchor' "$WRITING" "heading anchors render by default"
assert_grep 'rel=noopener target=_blank' "$SHORTCODES" "external links open in a new tab by default"

# showDateOnlyInArticle takes the date off listings only; the article page has its own
# meta line, so the flag is honoured in exactly one partial.
assert_grep 'showDateOnlyInArticle' "$ROOT/layouts/_partials/post-meta.html" \
  "the listing meta honours showDateOnlyInArticle"

# fingerprintAlgorithm has to reach every fingerprint call or assets hash inconsistently.
if without_comments "$ROOT/layouts/baseof.html" | grep -q 'fingerprint "sha512"'; then
  bad "every asset uses the configured fingerprint algorithm" "a hardcoded sha512 remains in baseof.html"
else
  ok "every asset uses the configured fingerprint algorithm"
fi

# invertPagination swaps the links and the labels together, so the arrow and the word
# never disagree.
assert_grep 'invertPagination' "$ROOT/layouts/_partials/pager.html" "the pager can be inverted"

# sitemap.excludedKinds replaces the built-in list rather than adding to it.
assert_grep 'excludedKinds' "$ROOT/layouts/sitemap.xml" "sitemap kinds are configurable"

# The third escape hatch, and the only per-entry one. Empty by default, like the others.
assert_file "$ROOT/layouts/_partials/extend-article-link.html" "the article-link hook exists"
EAL=$(without_comments "$ROOT/layouts/_partials/extend-article-link.html" | tr -d '[:space:]')
if [ -z "$EAL" ]; then
  ok "the article-link hook ships empty"
else
  bad "the article-link hook ships empty" "it has content, so it is a feature rather than a hook"
fi

# Monetisation and RSSNext: opt-in, and absent from the built demo.
# Anchored to the CDN hostnames, not the vendor names: the integrations page documents
# both, and a bare word matches its own documentation. Same trap as the Plausible check.
for host in pagead2.googlesyndication cdnjs.buymeacoffee.com; do
  if grep -rq "$host" "$PUBLIC" 2>/dev/null; then
    bad "no monetisation script fires unconfigured ($host)" "found $host in the built output"
  else
    ok "no monetisation script fires unconfigured ($host)"
  fi
done
refute_grep 'follow_challenge' "$PUBLIC/index.xml" "no RSSNext block without configuration"

# Language redirect: off by default even on the multilingual demo, because a redirect the
# reader did not ask for breaks a deliberately shared link.
refute_grep 'data-language-redirect' "$PUBLIC/index.html" "the language redirect is off by default"

# typeit ships the finished text, so JS-off and reduced-motion readers get the whole
# sentence. An empty element filled by script would fail both.
assert_grep '>This sentence types itself.<' "$SHORTCODES" "typeit ships the finished text"
# ...and no GPL library came with it. The theme is MIT; vendoring copyleft here would push
# every site using it onto GPL for a decorative animation.
if [ -e "$ROOT/assets/js/vendor/typeit.umd.js" ]; then
  bad "no GPL-licensed library is vendored" "typeit.umd.js is GPL-3.0 and this theme is MIT"
else
  ok "no GPL-licensed library is vendored"
fi

# --- this batch: menus, listing order, backgrounds, images, zen, gist, counters ------

# footer.showMenu. The menu has always rendered; only the switch is new, so the default
# is what is asserted.
assert_grep 'class=footer-nav' "$PUBLIC/index.html" "the footer menu renders by default"

# list.orderByWeight replaces the date sort rather than blending with it — a list half
# ordered by weight and half by date is worse than either.
assert_grep 'ByWeight' "$ROOT/layouts/section.html" "orderByWeight sorts the section index"
refute_grep 'data-bg-blur' "$PUBLIC/index.html" "background blur is off by default"
refute_grep 'data-bg-header-space' "$PUBLIC/index.html" "background header space is off by default"

# imagePosition applies where crops actually happen. Covers are never cropped, so the
# property is defined with a default and moves only the avatar and thumbnails.
assert_grep '\-\-image-position: center' "$ROOT/assets/css/tokens.css" \
  "the image position property has a default so it always resolves"
assert_grep 'object-position: var(--image-position)' "$ROOT/assets/css/article.css" \
  "cropped images honour imagePosition"

# disableImageOptimization has to reach every place a cover is resized, or it silently
# half-works. The check lives in thumb.html, and every thumbnail surface must resolve
# through that partial — a template calling .Resize on a cover itself has stepped
# outside the one home the flag reaches.
assert_grep 'disableImageOptimization' "$ROOT/layouts/_partials/thumb.html" \
  "thumb.html honours disableImageOptimization"
for f in card post-item related; do
  assert_grep 'partial "thumb.html"' "$ROOT/layouts/_partials/$f.html" \
    "$f.html resolves covers through thumb.html"
done
for f in hero gallery stack; do
  assert_grep 'partial "thumb.html"' "$ROOT/layouts/_partials/home/$f.html" \
    "home/$f.html resolves covers through thumb.html"
done
assert_grep 'partial "thumb.html"' "$ROOT/layouts/home.json" \
  "the search index resolves covers through thumb.html"

# Zen mode. The toggle itself must survive the hiding, or the mode has no visible way out.
assert_grep 'data-toggle-zen' "$PUBLIC/blog/measuring/index.html" "the zen control renders when enabled"
assert_grep 'data-toggle-zen hidden' "$PUBLIC/blog/measuring/index.html" \
  "the zen control ships hidden, so JS-off readers get no dead control"
assert_grep 'not(\[data-toggle-zen\])' "$ROOT/assets/css/interaction.css" \
  "zen mode keeps its own exit visible"
assert_grep 'e.key === "Escape"' "$ROOT/assets/js/zen.js" "Escape leaves zen mode"

# gist: build-time fetch, so the reader loads no GitHub script and the code gets this
# theme's own highlighting rather than GitHub's stylesheet.
# Either form counts: the highlighted figure when the fetch worked, or the degraded link
# when GitHub was rate-limiting. Asserting only the first made the gate depend on a third
# party's rate limit, which it did fail on. The class is quoted in the degraded form
# (`class="gist gist-offline"`) and bare in the live one, so the pattern allows both.
if grep -qE 'class="?gist' "$SHORTCODES"; then
  ok "the gist renders in one form or the other"
else
  bad "the gist renders in one form or the other"
fi
# Scoped to the gist figure: the page is full of other code blocks, so a bare chroma check
# stayed green with the highlighting removed.
if grep -q '<figure class=gist>' "$SHORTCODES"; then
  if grep -o '<figure class=gist>.\{0,200\}' "$SHORTCODES" | grep -q 'class=chroma'; then
    ok "a fetched gist is highlighted by the theme, not by GitHub"
  else
    bad "a fetched gist is highlighted by the theme, not by GitHub" "no chroma markup inside the gist figure"
  fi
else
  skip "a fetched gist is highlighted by the theme (gist was not fetched this build)"
fi
refute_grep 'gist.github.com/.*\.js' "$SHORTCODES" "no GitHub gist script reaches the reader"

# Counters. The one feature that records reader activity, so the assertion that matters is
# that it is absent unless configured.
refute_grep 'data-counters' "$PUBLIC/blog/measuring/index.html" \
  "no counters render without firebase configured"
refute_grep 'firestore.googleapis.com' "$PUBLIC/blog/measuring/index.html" \
  "no Firestore endpoint reaches an unconfigured page"
assert_grep 'hidden data-counters' "$ROOT/layouts/_partials/counters.html" \
  "the counter block ships hidden until it has a real number"
# No SDK: the whole point of using the REST API.
refute_grep 'firebasejs\|firebase-app' "$ROOT/assets/js/counters.js" \
  "counters use the REST API, not the Firebase SDK"

# Repository cards. Seven shortcodes over one fetch-and-render mechanism.
# Counted, not merely present: with two cards on the page, "a card renders" stayed true
# after one was deleted, so the assertion could not catch a broken shortcode.
# Anchored to the <a>, because `class=repo-card` also prefix-matches repo-card-head,
# -name, -desc and -meta — five hits per card, so the first count said 10.
# `oembed` reuses the repo-card shape, so it matches a bare `repo-card` count too. The
# forge cards carry the class alone; the oembed card carries `repo-card oembed-card`.
# Counted by class list, not by quoting. Hugo quotes a class attribute only when it holds
# more than one value, and whether a card gains `is-offline` depends on whether the forge
# answered — so a pattern keyed on quotes counts differently on a rate-limited build.
ALL_CARDS=$(grep -o '<a class="\?repo-card[^>]*' "$SHORTCODES" | wc -l | tr -d ' ')
OEMBED_CARDS=$(grep -o '<a class="\?repo-card[^>]*' "$SHORTCODES" | grep -c 'oembed-card' | tr -d ' ')
REPO_CARDS=$((ALL_CARDS - OEMBED_CARDS))
assert_count 2 "$REPO_CARDS" "both repository cards render"
assert_count 1 "$OEMBED_CARDS" "the oembed card renders"
assert_grep 'href=https://github.com/gohugoio/hugo' "$SHORTCODES" "the card links to the repository"

# The reader fetches nothing: the counts are baked in at build time, which is the whole
# reason this is a build-time fetch rather than a script. No forge API may appear in a
# src/href in the output.
if grep -oE '(src|href)="?https?://(api\.github\.com|[^" >]*api/v1/repos)[^" >]*' "$SHORTCODES" | grep -q .; then
  bad "repository cards cost the reader no request" "an API URL reached the page"
else
  ok "repository cards cost the reader no request"
fi

# All seven forges exist and share the one mechanism, rather than each hand-rolling a fetch.
for f in github gitlab codeberg gitea forgejo huggingface ansible; do
  if grep -q 'partial "repo-card.html"' "$ROOT/layouts/_shortcodes/$f.html" 2>/dev/null; then
    ok "the $f card uses the shared mechanism"
  else
    bad "the $f card uses the shared mechanism" "missing or hand-rolled"
  fi
done

# A 404 is a content problem and must fail the build; being offline is an environment
# problem and must not, or the theme could not be built without a network — which
# docs/SPEC.md §1 forbids. The two paths are separate in the source.
assert_grep 'warnf "repo-card' "$ROOT/layouts/_partials/repo-card.html" \
  "a missing repository warns, so a dead card fails CI"
assert_grep 'warnidf "repo-card-offline"' "$ROOT/layouts/_partials/fetch-remote.html" \
  "an unreachable network uses a suppressible log, not a hard warning"
assert_grep "ignoreLogs = \['repo-card-offline', 'repo-card-missing'\]" "$ROOT/exampleSite/hugo.toml" \
  "the demo site can be built with no network and under a rate limit"

# Lightbox. The parts that make it a feature rather than an accessibility regression are
# all in the source, since nothing here opens a browser: a real <dialog> (which brings the
# modal semantics, backdrop, focus trap and Escape handler with it), a focusable trigger,
# and focus restored on close.
# The module is concatenated into the shared bundle, so its filename never appears in the
# HTML — assert on the bundle's contents, as the mermaid check does.
if [ -n "$JS_REF" ] && grep -q 'lightbox-trigger' "$PUBLIC/$JS_REF" 2>/dev/null; then
  ok "the lightbox script is in the bundle when enabled"
else
  bad "the lightbox script is in the bundle when enabled" "no lightbox code in $JS_REF"
fi
assert_grep 'document.createElement("dialog")' "$ROOT/assets/js/lightbox.js" \
  "the lightbox is a real dialog, not a hand-rolled overlay"
assert_grep 'opener.focus()' "$ROOT/assets/js/lightbox.js" \
  "focus returns to the trigger when the lightbox closes"

# display:contents on the trigger gives it a 0x0 box and makes it unfocusable, so the
# lightbox becomes unreachable by keyboard — measured, not assumed. The trigger must keep
# a real box.
TRIGGER_RULE=$(awk '/^\.lightbox-trigger \{/,/^\}/' "$ROOT/assets/css/interaction.css")
case "$TRIGGER_RULE" in
  *"display: contents"*) bad "the lightbox trigger is focusable" "display:contents makes the button unfocusable" ;;
  *"display: block"*)    ok "the lightbox trigger is focusable" ;;
  *)                     bad "the lightbox trigger is focusable" "no display declared on .lightbox-trigger" ;;
esac

# An enlarged image exists to be seen whole, so the never-crop rule applies here too.
LB_RULE=$(awk '/^\.lightbox-image \{/,/^\}/' "$ROOT/assets/css/interaction.css")
case "$LB_RULE" in
  *"object-fit: contain"*) ok "the lightbox never crops the image" ;;
  *) bad "the lightbox never crops the image" "the .lightbox-image rule does not use object-fit: contain" ;;
esac

# header.layout. `fixed` is the current sticky header and the default, so this asserts the
# default rather than the option — the risk here is a silent behaviour change for sites
# that set nothing.
assert_grep 'data-header=fixed' "$PUBLIC/index.html" "the header is sticky by default"
assert_grep 'html\[data-header="basic"\] \.site-header' "$ROOT/assets/css/layout.css" \
  "basic makes the header scroll away"

# Card views. The section index is a list by default and term pages are cards, which is
# what the approved design shows; each has a switch to the other. Both defaults asserted,
# because turning either on by accident changes every listing on a site.
assert_grep 'class=post-list' "$PUBLIC/blog/index.html" "the section index is a list by default"
refute_grep 'class=card-grid' "$PUBLIC/blog/index.html" "the section index is not a card grid by default"
assert_grep 'class=card-grid' "$PUBLIC/tags/design/index.html" "term pages are cards by default"

# The underline-links control. Named for what it does; a control whose effect a reader
# cannot predict is not an accessibility feature.
assert_grep 'data-toggle-underline' "$PUBLIC/index.html" "the underline control renders when enabled"
assert_grep 'data-toggle-underline hidden' "$PUBLIC/index.html" \
  "the underline control ships hidden, so JS-off readers get no dead control"
assert_grep 'aria-pressed=false' "$PUBLIC/index.html" "the underline control is a pressed-state toggle"

# The rule has to beat .prose a, which carries its own faux underline as a box-shadow.
# Two underlines on one link is a smudge.
assert_grep 'html\[data-underline-links\] \.prose a' "$ROOT/assets/css/interaction.css" \
  "the underline mode drops the prose link's own rule"

# Analytics. The invariant is not that any provider works but that *none* fires unless it
# is configured — the theme makes no third-party request by default, and exampleSite leaves
# every provider commented out precisely so the built demo proves it.
for host in cloudflareinsights usefathom umami\.is seline\.so plausible\.io/js googletagmanager; do
  # Same label in both branches. The first version said "(usefathom)" on pass and dropped
  # the host on fail, so a red run named a different assertion from the green one it
  # replaced — which made the failure look like a new test rather than a broken one.
  if grep -rq "$host" "$PUBLIC" 2>/dev/null; then
    bad "no analytics provider fires unconfigured ($host)" "found $host in the built output"
  else
    ok "no analytics provider fires unconfigured ($host)"
  fi
done

# Google Analytics has to use Hugo's own services key. A theme param would be a second
# key that silently did nothing, which is what the first draft of the partial did.
assert_grep '_internal/google_analytics.html' "$ROOT/layouts/_partials/analytics.html" \
  "Google Analytics uses Hugo's own template"
if without_comments "$ROOT/layouts/_partials/analytics.html" | grep -q 'analytics\.google'; then
  bad "Google Analytics reads Hugo's config, not a theme param" "found a params.analytics.google read"
else
  ok "Google Analytics reads Hugo's config, not a theme param"
fi

# Site-wide image fallbacks. The point is that a coverless post is still illustrated and
# still previews as a card when linked, without every post needing its own artwork.
COAUTH_PAGE="$PUBLIC/blog/co-authored/index.html"
assert_grep 'figure class=article-cover><img src=[^ >]*/images/example.svg' "$COAUTH_PAGE" \
  "a post with no cover falls back to defaultFeaturedImage"
# og:image is an absolute URL by definition, so the host is whatever built the site — the
# demo's example.com locally, the Pages host in CI. Match the path and leave the origin
# open; pinning example.com asserts the builder rather than the feature.
assert_grep 'og:image" content="[^"]*/images/example.svg"' "$COAUTH_PAGE" \
  "a post with no cover falls back to defaultSocialImage"

# ...and a post with its own cover is untouched, which is what makes this non-breaking.
assert_grep 'og:image" content="[^"]*/blog/measuring/cover.png"' "$MEASURING" \
  "a post with its own cover ignores the fallbacks"

# taxonomy.showTermCount. The count already rendered; only the switch is new, so the
# default is true and this asserts the default rather than the switch.
assert_grep 'class=term-count' "$PUBLIC/tags/index.html" "term counts render by default"

# Palettes. Each accent was measured against its own tint before shipping, which is the
# case that decided clay. Assert the set the theme claims to support matches what
# tokens.css actually defines, so a palette cannot be documented and missing.
PALETTES_CSS=$(grep -oE 'html\[data-palette="[a-z]+"\]' "$ROOT/assets/css/tokens.css" | grep -oE '"[a-z]+"' | tr -d '"' | sort | tr '\n' ' ')
PALETTES_INIT=$(grep -oE 'slice "periwinkle"[^)]*' "$ROOT/layouts/_partials/init.html" | grep -oE '"[a-z]+"' | tr -d '"' | grep -v periwinkle | sort | tr '\n' ' ')
if [ "$PALETTES_CSS" = "$PALETTES_INIT" ]; then
  ok "every accepted palette is defined in tokens.css"
else
  bad "every accepted palette is defined in tokens.css" "css: [$PALETTES_CSS] init: [$PALETTES_INIT]"
fi

# Multilingual. Hugo does the routing; the theme owes the reader a way to switch, and
# owes a crawler the alternates. These assertions cover both, plus the fallbacks.
NB_POST="$PUBLIC/nb/blog/two-modes/index.html"
assert_file "$NB_POST" "the second language builds its own pages"
assert_file "$PUBLIC/nb/index.json" "each language gets its own search index"

# The switcher must link to the *translation of this page*, not to the other language's
# home page. Being sent to the front page for asking to read the same article in another
# language is the single most common thing this control gets wrong.
assert_grep 'lang-switch-items><a href=[^ >]*/blog/two-modes/ hreflang=en' "$NB_POST" \
  "the switcher links to the translation of the current page"

# ...and falls back to that language's home page when there is no translation, rather than
# rendering a dead link. `measuring` exists only in English.
assert_grep 'href=[^ >]*/nb/ hreflang=nb' "$MEASURING" \
  "an untranslated page falls back to the other language's home"

# The language you are reading is text, not a link to the page you are already on.
assert_grep 'class=lang-current aria-current=true' "$NB_POST" \
  "the current language is not a link"

# hreflang alternates, including x-default, so translations are not read as duplicates.
assert_grep 'rel=alternate hreflang=nb' "$PUBLIC/blog/two-modes/index.html" "hreflang alternates are emitted"
assert_grep 'rel=alternate hreflang=x-default' "$PUBLIC/blog/two-modes/index.html" "x-default is emitted"

# The site catalogue wins over the theme's, and anything left out falls back to English
# one string at a time rather than rendering blank.
assert_grep 'Hopp til innhold' "$PUBLIC/nb/index.html" "the site's own catalogue translates the chrome"
assert_grep 'Bytt spr' "$NB_POST" "the switcher's accessible name is translated"

# Date format is a per-language param, not a site-wide one.
assert_grep '<time datetime=2025-09-30>30\. Sep 2025' "$NB_POST" "dates use the language's own format"

# hugo.Sites, not the two deprecated spellings. Both site.Languages and site.Sites were
# deprecated in Hugo 0.156, and the gate turns the warning into a failure — but only the
# gate does, so `make build` alone will not catch a regression here.
for f in language-switcher head; do
  if without_comments "$ROOT/layouts/_partials/$f.html" | grep -qE '\bsite\.(Languages|Sites)\b'; then
    bad "$f.html uses the non-deprecated sites API" "found site.Languages or site.Sites in code"
  else
    ok "$f.html uses the non-deprecated sites API"
  fi
done

# heroStyle. Four treatments, and the invariant that survives all of them is never-crop.
HERO_BG="$PUBLIC/blog/hero-background/index.html"
HERO_TB="$PUBLIC/blog/hero-thumb-and-background/index.html"
assert_grep 'class=article-hero-bg' "$HERO_BG" "background puts the cover behind the header"
assert_grep 'article-head article-head-on-cover' "$HERO_BG" "the header renders on top of the cover"
assert_grep 'article-cover article-cover-big' "$PUBLIC/blog/no-shortcodes/index.html" \
  "big breaks the cover out past the measure"

# thumbAndBackground is the only style that renders the cover twice — behind the header
# and again as a card — so count both rather than assuming one implies the other.
assert_count 1 "$(grep -c 'article-hero-bg' "$HERO_TB" | tr -d ' ')" \
  "thumbAndBackground renders the background hero"
assert_count 1 "$(grep -o 'figure class=article-cover' "$HERO_TB" | wc -l | tr -d ' ')" \
  "thumbAndBackground also renders the cover card"

# The default is unchanged, which is what keeps this non-breaking for existing sites.
assert_grep 'figure class=article-cover>' "$MEASURING" "basic is still the default treatment"
refute_grep 'article-hero-bg' "$MEASURING" "a default post gets no background hero"

# THE INVARIANT, in the new style. A background hero elsewhere fills a band and crops;
# here it must keep the exact ratio and contain, like every other cover in this theme.
HERO_RULE=$(awk '/^\.article-hero-bg > img \{/,/^\}/' "$ROOT/assets/css/article.css")
case "$HERO_RULE" in
  *"object-fit: contain"*) ok "the background hero never crops the cover" ;;
  *) bad "the background hero never crops the cover" "the .article-hero-bg > img rule does not use object-fit: contain" ;;
esac
case "$HERO_RULE" in
  *"aspect-ratio: 1200 / 630"*) ok "the background hero keeps the exact cover ratio" ;;
  *) bad "the background hero keeps the exact cover ratio" "no 1200/630 in the .article-hero-bg > img rule" ;;
esac

# An unknown heroStyle falls back rather than rendering an unstyled header, the same rule
# init.html applies to colorScheme.
assert_grep 'basic" "big" "background" "thumbAndBackground"' "$ROOT/layouts/page.html" \
  "an unknown heroStyle falls back to basic"

# SVG covers. Hugo's .Width errors on an SVG rather than returning zero, so every partial
# that reads dimensions has to guard on the raster flag thumb.html returns. Before the
# guard existed, a single SVG cover failed the whole build in six places. The hero demo
# posts use SVG covers precisely so this stays exercised.
for f in related card post-item; do
  if grep -q 'if \$t.raster' "$ROOT/layouts/_partials/$f.html"; then
    ok "$f.html guards image dimensions for SVG covers"
  else
    bad "$f.html guards image dimensions for SVG covers" "no \$t.raster guard"
  fi
done
for f in hero gallery stack; do
  if grep -q 'if \$t.raster' "$ROOT/layouts/_partials/home/$f.html"; then
    ok "home/$f.html guards image dimensions for SVG covers"
  else
    bad "home/$f.html guards image dimensions for SVG covers" "no \$t.raster guard"
  fi
done

# chart. Same gating as mermaid: the library is only worth vendoring if it is only loaded
# where it is used.
assert_grep 'vendor/chart' "$SHORTCODES" "the chart library loads on a page with a chart"
refute_grep 'vendor/chart' "$PUBLIC/index.html" "the home page loads no chart library"
if [ -n "$JS_REF" ] && grep -q 'Chart' "$PUBLIC/$JS_REF" 2>/dev/null; then
  bad "chart.js is not in the main bundle" "found Chart in $JS_REF"
else
  ok "chart.js is not in the main bundle"
fi

# A <canvas> is a picture to anything that is not a sighted reader, so the alt text is the
# accessible name and the shortcode refuses to build without one.
assert_grep 'canvas class=chart role=img aria-label=' "$SHORTCODES" \
  "the chart canvas carries its text alternative"
assert_grep 'alt is required' "$ROOT/layouts/_shortcodes/chart.html" \
  "a chart with no alt fails the build"

# The config rides on a data- attribute rather than in an inline <script>, so a site with a
# strict Content-Security-Policy is unaffected.
assert_grep 'data-chart=' "$SHORTCODES" "the chart config is a data attribute, not inline script"

# Colour tokens are light-dark() pairs, and reading one with getPropertyValue hands back
# that function as text, which Chart.js cannot parse — it then silently falls back to its
# light-mode defaults and draws black on a dark page. The fix resolves the token through a
# probe element; this stops the direct read coming back.
# Anchored to the *call*, not the bare name — the comment above the fix explains why
# getPropertyValue is wrong, and a plain refutation matches its own explanation. Fifth
# time this trap has bitten in this suite. The rule, again: if a refutation names the
# thing it forbids, anchor it to syntax.
refute_grep '\.getPropertyValue(' "$ROOT/assets/js/chart-init.js" \
  "chart colours are resolved, not read as raw custom properties"

# Maths. Rendered at build time by Hugo's own KaTeX, so the equation is in the HTML the
# server sends and the theme ships no maths library at all. These assertions are what stop
# that quietly regressing into a client-side renderer.
assert_grep 'class="math math-inline"' "$WRITING" "inline maths renders"
assert_grep 'class="math math-block"'  "$WRITING" "display maths renders"
assert_grep '<math xmlns="http://www.w3.org/1998/Math/MathML"' "$WRITING" \
  "maths is real MathML, laid out by the browser"

# No library, no stylesheet, no fonts. `htmlAndMathml` output would need KaTeX's CSS and
# around sixty font files; MathML output needs none of it, and that saving is the reason
# for the choice.
if grep -rq 'katex\.min\.\(js\|css\)\|katex/dist' "$PUBLIC" 2>/dev/null; then
  bad "no KaTeX library or stylesheet is shipped" "found a katex asset in the output"
else
  ok "no KaTeX library or stylesheet is shipped"
fi

# The equation survives with scripting off, which is the whole point of build-time
# rendering. Asserted by there being no script involved in producing it.
refute_grep 'renderMathInElement\|auto-render' "$WRITING" "maths needs no client-side renderer"

# mermaid. The whole justification for vendoring 3.5MB is that it is loaded only where a
# diagram exists. If that gate ever breaks, the theme quietly becomes the heaviest thing on
# the reader's page, on every page — so this is the assertion that matters most here.
assert_grep 'vendor/mermaid' "$SHORTCODES" "the mermaid library loads on a page with a diagram"
refute_grep 'vendor/mermaid' "$PUBLIC/index.html" "the home page loads no mermaid"
refute_grep 'vendor/mermaid' "$MEASURING" "a post with no diagram loads no mermaid"

# And it must never reach the shared bundle, which every page loads.
if [ -n "$JS_REF" ] && grep -q 'mermaid' "$PUBLIC/$JS_REF" 2>/dev/null; then
  bad "mermaid is not in the main bundle" "found mermaid in $JS_REF"
else
  ok "mermaid is not in the main bundle"
fi

# Self-hosted, like every other asset. A CDN reference would be a third-party request on
# page view, which is the one thing this theme does not do.
refute_grep 'cdn\.jsdelivr\|unpkg\.com\|cdnjs' "$SHORTCODES" "mermaid is self-hosted, not from a CDN"

# The source stays in the <pre>, which is the JS-off fallback and the input the theme
# re-renders from when the colour mode changes. An empty container would be neither.
assert_grep '<pre class=mermaid>graph LR' "$SHORTCODES" "the diagram source is served as text"

# Multiple authors. The co-authored post credits two people from data/authors/.
COAUTH="$PUBLIC/blog/co-authored/index.html"
assert_grep 'Morten Victor Nordbye</a><span class=author-sep>, </span>' "$COAUTH" \
  "a co-authored post names both authors"
assert_grep 'href=[^ >]*/authors/ada/>Ada Example' "$COAUTH" \
  "showAuthorsBadges links a byline name to its author page"
assert_file "$PUBLIC/authors/ada/index.html" "the authors taxonomy builds a page per author"

# Two avatars, so the stacked-avatar rule in article.css is exercised by the demo site
# rather than only declared. Both demo authors carry an image for exactly this reason; with
# only one, `.avatar-group .avatar:not(:first-child)` would be dead CSS.
# `class=avatar ` with the trailing space matches only the byline avatars; the card uses
# `author-card-avatar`, which is a different class rather than a modifier, so there is no
# need to carve the byline out of the page first.
COAUTH_AVATARS=$(grep -o 'class=avatar ' "$COAUTH" | wc -l | tr -d ' ')
assert_count 2 "$COAUTH_AVATARS" "a co-authored byline stacks both avatars"

# The separator is an i18n string, not a comma in a template — the punctuation between
# names is not the same in every language.
assert_grep 'authorSeparator' "$ROOT/i18n/en.toml" "the co-author separator is translatable"

# Backward compatibility is the whole risk here: every existing site has one author and no
# data/authors/ directory, and must render exactly what it rendered before. A post with no
# `authors` falls through to [params.author], so it gets a plain name and no separator.
refute_grep 'author-sep' "$PUBLIC/blog/shipping-static/index.html" \
  "a single-author post renders no separator"
assert_grep 'class=author-name>Morten Victor Nordbye</span>' "$PUBLIC/blog/shipping-static/index.html" \
  "a post with no authors falls back to the site-wide author"

# An author key with no data file fails the build rather than dropping somebody's name
# from their own work. Asserted on the template, since exampleSite has no broken key.
assert_grep 'there is no data/authors' "$ROOT/layouts/_partials/authors.html" \
  "an unknown author key fails the build"

# hugo.Data, not site.Data — the latter was deprecated in 0.156 and the gate treats the
# warning as an error, so this would be a build failure rather than a silent fallback.
# Anchored to an assignment rather than the bare name: the comment above the lookup
# explains why site.Data is wrong, and a plain refutation matches its own explanation.
# That trap has now caught four assertions in this suite — object-fit, ytimg, autoplay,
# and this one. If a refutation names the thing it forbids, anchor it to syntax.
assert_grep 'hugo\.Data\.authors' "$ROOT/layouts/_partials/authors.html" \
  "the author lookup uses the non-deprecated data API"
refute_grep ':= site\.Data' "$ROOT/layouts/_partials/authors.html" \
  "the author lookup does not read the deprecated site.Data"

# Service names come from the catalogue in all three places that render a socials row, not
# from title-casing. `title` renders "linkedin" as "Linkedin" and "github" as "Github".
# The author card was where this drifted, which is why the three copies became one partial.
if grep -rqE 'aria-label="?(Linkedin|Github|Hackernews)' "$PUBLIC"; then
  bad "socials rows use catalogue service names" \
      "$(grep -rhoE 'aria-label="?(Linkedin|Github|Hackernews)' "$PUBLIC" | head -1)"
else
  ok "socials rows use catalogue service names"
fi

# Series. The value is entirely in being correct about position: "Part 2 of 3" is the whole
# feature, and an off-by-one or a bad sort makes it actively misleading rather than merely
# absent. `measuring` is series_order 2 of 3.
assert_grep 'Part 2 of 3 in Design decisions' "$MEASURING" "the series line names the right position"

# The series name is the author's, not Hugo's title-cased LinkTitle, which would render
# "Design decisions" as "Design Decisions". Same trap the tag row documents.
refute_grep 'Design Decisions' "$MEASURING" "the series keeps the author's own capitalisation"

# Order comes from series_order, not from date. The three parts are deliberately dated out
# of sequence in exampleSite — two-modes 2025-09-30, reading-long-form 2026-02-08, measuring
# 2026-05-04 — so a date sort produces a visibly different list.
#
# The comparison has to include the *current* part, which renders as text rather than a
# link. Ordering by date would put measuring last instead of in the middle, and looking only
# at the two links misses that entirely: the links come out in the same order either way.
# The first version of this test did exactly that and could not fail.
SERIES_SEQ=$(grep -o 'class=series-list>.*</ol>' "$MEASURING" \
  | sed 's|<li|\n<li|g' | grep '<li' \
  | sed -e 's|.*is-current.*|CURRENT|' -e 's|.*href=[^ >]*/blog/\([a-z-]*\)/.*|\1|' \
  | tr '\n' ' ')
if [ "$SERIES_SEQ" = "two-modes CURRENT reading-long-form " ]; then
  ok "series parts are ordered by series_order, not by date"
else
  bad "series parts are ordered by series_order, not by date" "got: $SERIES_SEQ"
fi

# The current part is text, not a link — a link to the page you are on is a dead end — and
# aria-current is what says "you are here" in its place.
assert_grep 'class="series-item is-current" aria-current=page' "$MEASURING" \
  "the current part is marked and not a link"

# A post in no series renders no series block at all, rather than an empty card.
refute_grep 'class=series' "$PUBLIC/blog/shipping-static/index.html" \
  "a post outside a series gets no series block"

# A series of one is not a series. Guarding this because the partial builds the whole block
# before it knows the length, so the check is easy to drop.
assert_grep 'gt \$total 1' "$ROOT/layouts/_partials/series.html" \
  "a one-part series renders nothing"

# author.bio on the profile layout. Distinct from `headline`, which is one line, and from
# the page's own description.
PROFILE="$PUBLIC/layouts/profile/index.html"
assert_grep 'class=profile-bio>Builds small, boring tools' "$PROFILE" \
  "the author bio renders on the profile layout"

# ...and renders as prose, not as a code block. A TOML """ string keeps its indentation,
# and Markdown reads four leading spaces as a code fence, so a bio indented to line up with
# the keys around it comes out as a grey <pre> slab. That is exactly what the first version
# of the exampleSite config did, and it looks like a styling bug rather than a config one.
if grep -q 'class=profile-bio><pre>' "$PROFILE"; then
  bad "the author bio is prose, not a code block" "indented TOML turned the bio into a <pre>"
else
  ok "the author bio is prose, not a code block"
fi

# reply-by-email: a mailto, so it needs no third party and works with JavaScript off. The
# subject carries the post title so a reply arrives with its context attached.
assert_grep 'class=reply-by-email' "$MEASURING" "the reply-by-email link renders"
assert_grep 'href="mailto:hello@example.com?subject=Re%3A+Measuring' "$MEASURING" \
  "the reply link prefills the subject with the post title"

# It must render nothing when there is no address to reply to, rather than a dead link.
# Asserted on the partial, since the exampleSite always has an address configured.
assert_grep 'with \$cfg.author.email' "$ROOT/layouts/_partials/reply-by-email.html" \
  "the reply link is gated on an address existing"

# list.showSummary: the fallback excerpt for a post with no `description`. Searched across
# every listing page rather than a fixed one, for the same reason as externalUrl below —
# pagination decides where the post lands and content changes move it.
#
# Anchored to `item-text>`, the listing's excerpt element. The first version of this looked
# for the sentence anywhere under blog/, which also matched the post's own page, where the
# sentence is the body copy — so it passed with the feature switched off. It was caught by
# turning showSummary off and finding the test still green.
if grep -rq 'item-text>This post deliberately has no description' "$PUBLIC/blog/"; then
  ok "showSummary falls back to the summary when a post has no description"
else
  bad "showSummary falls back to the summary when a post has no description"
fi

# The summary carries markup and the description does not, so the fallback has to be
# stripped before it is printed. An excerpt that opened a tag it never closed would leak
# formatting into the rest of the card.
#
# The first tag after `item-text>` must be the closing `</p>`, so this looks for an
# *opening* tag instead — `<` followed by a letter. Written that way because the obvious
# version, looking for the <code> that the backticks in the source would produce, could not
# fail: dropping plainify makes .Summary bring its own wrapping <p>, so the very first
# character after `item-text>` is already `<` and a pattern expecting text first never
# matched. This catches that <p> and any other tag equally.
if grep -rq 'item-text>[^<]*<[a-zA-Z]' "$PUBLIC/blog/"; then
  bad "the summary fallback is plain text" \
      "$(grep -rho 'item-text>[^<]*<[a-zA-Z][a-z]*' "$PUBLIC/blog/" | head -1)"
else
  ok "the summary fallback is plain text"
fi

# `description` is the deliberate excerpt and must still win where one exists, or turning
# showSummary on would silently replace every hand-written excerpt with body text. Searched
# across the listing pages for the same pagination reason as above; asserting on a fixed
# page is how the first version of this got it wrong.
if grep -rq 'item-text>Dark mode built by flipping the lightness' "$PUBLIC/blog/"; then
  ok "a post with a description still uses it, not its summary"
else
  bad "a post with a description still uses it, not its summary"
fi

# Sharing links. The guarantee is that the row is *links* — no script, no SDK, no widget —
# so nothing is requested from any of these services until a reader clicks. The theme-purity
# group already refutes third-party <script> tags site-wide; this pins the share row's own
# shape, since a provider needing a script is exactly how that rule would get broken.
SHARE_LINKS=$(grep -oE '<a class=button href="[^"]*" aria-label="Share [^"]*"' "$MEASURING" | wc -l | tr -d ' ')
assert_count 6 "$SHARE_LINKS" "every configured sharing link renders"

# Each provider builds a different URL shape, and getting one wrong produces a button that
# looks right and shares nothing. Assert the host per provider rather than just the count.
assert_grep 'href="https://mastodon.social/share?text=' "$MEASURING" "mastodon posts to the configured instance"
assert_grep 'href="https://bsky.app/intent/compose?text=' "$MEASURING" "bluesky uses the compose intent"
assert_grep 'href="https://news.ycombinator.com/submitlink?u=' "$MEASURING" "hackernews uses submitlink"
assert_grep 'href="https://www.linkedin.com/sharing/share-offsite/?url=' "$MEASURING" "linkedin uses the share-offsite URL"
assert_grep 'href="https://www.reddit.com/submit?url=' "$MEASURING" "reddit uses the submit URL"

# email is the one entry that is not an external site. A mailto opened with target=_blank
# leaves an empty tab behind in most browsers, so it must not carry one.
if grep -oE '<a class=button href="mailto:[^>]*>' "$MEASURING" | grep -q 'target'; then
  bad "the email share link does not open a new tab" "$(grep -oE '<a class=button href="mailto:[^>]*>' "$MEASURING" | head -1)"
else
  ok "the email share link does not open a new tab"
fi

# Service names come from i18n, not from title-casing the config key. `title` renders
# "linkedin" as "Linkedin" and "hackernews" as "Hackernews", both wrong, and a name built
# in a template is invisible to a translator. Assert the two the naive version gets wrong.
assert_grep 'aria-label="Share on LinkedIn"'   "$MEASURING" "LinkedIn keeps its capital I"
assert_grep 'aria-label="Share on Hacker News"' "$MEASURING" "Hacker News keeps its space"
refute_grep 'Linkedin'   "$MEASURING" "no title-cased service name survives"
refute_grep 'Hackernews' "$MEASURING" "no run-together service name survives"

assert_grep 'nav-group'  "$PUBLIC/index.html" "nested menu renders as a disclosure"
assert_grep '<details'   "$PUBLIC/index.html" "nested menu uses details, not a hover dropdown"
# Pagination decides which listing page it lands on, so search all of them rather than
# hardcoding a page number that content changes would invalidate.
if grep -rq 'is-external' "$PUBLIC/blog/"; then
  ok "externalUrl marks the listing entry"
else
  bad "externalUrl marks the listing entry"
fi
if grep -rq 'gohugo.io/documentation' "$PUBLIC/blog/"; then
  ok "externalUrl entry links off-site"
else
  bad "externalUrl entry links off-site"
fi

# --------------------------------------------------------------------------------
group "Internationalisation"

I18N="$ROOT/i18n/en.toml"
assert_file "$I18N" "English catalogue exists"

# Every key a template or script asks for must exist, or the string renders empty.
MISSING=""
for key in $(grep -rhoE 'i18n "[A-Za-z0-9_]+"' "$ROOT/layouts" | sed 's/.*"\(.*\)"/\1/' | sort -u); do
  grep -qE "^${key} =|^\[${key}\]" "$I18N" || MISSING="$MISSING $key"
done
if [ -n "$MISSING" ]; then
  bad "every i18n key used is defined" "missing:$MISSING"
else
  ok "every i18n key used is defined"
fi

# Pluralised tables must sit last: in TOML a bare key after a table header joins that
# table, and the build fails with "reserved keys mixed with unreserved keys".
FIRST_TABLE=$(grep -n '^\[' "$I18N" | head -1 | cut -d: -f1)
LAST_BARE=$(grep -nE '^[a-zA-Z][A-Za-z0-9_]* =' "$I18N" \
  | grep -vE ':(zero|one|two|few|many|other) =' | tail -1 | cut -d: -f1)
if [ -n "$FIRST_TABLE" ] && [ -n "$LAST_BARE" ] && [ "$LAST_BARE" -gt "$FIRST_TABLE" ]; then
  bad "pluralised tables are last in en.toml" "a bare key at line $LAST_BARE follows a table at line $FIRST_TABLE"
else
  ok "pluralised tables are last in en.toml"
fi

# No user-facing string may be hardcoded in a template.
HARDCODED=$(grep -rhoE '(aria-label|placeholder)="[A-Za-z][^"{]*"' "$ROOT/layouts" | sort -u)
if [ -n "$HARDCODED" ]; then
  bad "no hardcoded user-facing strings in templates" "$(echo "$HARDCODED" | tr '\n' ' ')"
else
  ok "no hardcoded user-facing strings in templates"
fi

# The admonition labels are looked up dynamically (`printf "admonition%s"`), which the
# every-key-used check above cannot see, so their existence is asserted by name. Without
# them a translated site shows English callout labels.
ADM_MISSING=""
for key in admonitionNote admonitionTip admonitionImportant admonitionWarning admonitionCaution; do
  grep -q "^${key} =" "$I18N" || ADM_MISSING="$ADM_MISSING $key"
done
if [ -n "$ADM_MISSING" ]; then
  bad "admonition labels are in the catalogue" "missing:$ADM_MISSING"
else
  ok "admonition labels are in the catalogue"
fi

# The search modal's keyboard-hints row once carried literal English next to a proper
# i18n call, invisible to translators.
assert_grep 'searchHintNavigate' "$ROOT/layouts/_partials/search-modal.html" "search hints come from the catalogue"

# related.html once hardcoded both the date format and a literal "min" while every other
# meta line used dateFormat and the readingTime key.
assert_grep 'dateFormat' "$ROOT/layouts/_partials/related.html" "related cards honour dateFormat"
assert_grep 'i18n "readingTime"' "$ROOT/layouts/_partials/related.html" "related cards translate reading time"

# Every runtime lookup needs an English fallback, so a missing catalogue leaves working
# controls rather than blank ones.
# --exclude-dir=vendor for the same reason as the purity group above: a minified
# third-party bundle is full of one-letter function calls, and holding upstream code to
# this theme's i18n conventions produces noise, not coverage.
BAD_T=$(grep -rhoE --exclude-dir=vendor '\bt\("[A-Za-z0-9_]+"\)' "$ROOT/assets/js" | sort -u)
if [ -n "$BAD_T" ]; then
  bad "every t() call passes a fallback" "$(echo "$BAD_T" | tr '\n' ' ')"
else
  ok "every t() call passes a fallback"
fi

# --------------------------------------------------------------------------------
group "Scripts"

if [ -n "$JS_REF" ]; then
  GLOBALS=$(grep -oE '^var [a-zA-Z_$]+' "$PUBLIC/$JS_REF" | sort -u)
  if [ -n "$GLOBALS" ]; then
    bad "bundle declares no bare globals" "found: $(echo "$GLOBALS" | tr '\n' ' ')"
  else
    ok "bundle declares no bare globals"
  fi
  assert_grep 'window.Northlight' "$PUBLIC/$JS_REF" "shared lookup is namespaced"
fi

assert_grep 'northlight-strings' "$PUBLIC/index.html" "runtime string block is emitted"
# It must be a JSON object, not a quoted string. Contextual escaping got this wrong once.
refute_grep 'northlight-strings>"' "$PUBLIC/index.html" "runtime string block is not double-encoded"

# Controls that need JavaScript must ship hidden, so no-JS readers see no dead affordances.
assert_grep 'data-toggle-appearance hidden' "$PUBLIC/index.html" "appearance toggle ships hidden"

# The search field is a real combobox: focus stays in the field while the arrow keys
# move the selection, and aria-activedescendant is how a screen reader hears which
# option is current. Tab must reach the close button rather than being hijacked for
# selection — a visible control keyboard focus cannot reach fails WCAG 2.1.1.
assert_grep 'role="combobox"' "$ROOT/layouts/_partials/search-modal.html" "search input is a combobox"
assert_grep 'aria-activedescendant' "$ROOT/assets/js/search.js" "search selection is announced"
assert_grep 'closeBtn' "$ROOT/assets/js/search.js" "search close button is reachable by keyboard"

# counters.js is gated on firebase alone. counters.html honours page-level front-matter
# overrides, so gating the script on the site-level show flags left an opted-in post with
# markup but no script — invisibly, because the block ships hidden until the script runs.
if without_comments "$ROOT/layouts/baseof.html" | grep 'counters\.js' | grep -q 'showViews'; then
  bad "counters script is gated on firebase alone" "baseof.html gates counters.js on the site-level show flags"
else
  ok "counters script is gated on firebase alone"
fi

# A tab-group sync must update the synced set's state too, or the first arrow-key press
# on the synced strip starts from the stale index and goes nowhere.
assert_grep 'set.current = index' "$ROOT/assets/js/tabs.js" "tab activation tracks its own state"

# Everything interpolated into search-result markup is escaped. readingTime is an integer
# today, but it is one index-schema change away from not being one.
assert_grep 'escape(p.readingTime)' "$ROOT/assets/js/search.js" "search result reading time is escaped"

# --------------------------------------------------------------------------------
group "CSS invariants"

TOKENS="$ROOT/assets/css/tokens.css"

# Every custom property referenced must be defined, or the rule silently does nothing.
UNDEF=""
DEFINED=$(grep -rhoE '^[[:space:]]*--[a-z0-9-]+[[:space:]]*:' "$ROOT/assets/css" | tr -d ' :' | sort -u)
# Block comments are stripped first, across lines, so a custom property named in a
# documentation comment does not register as a use.
strip_comments() {
  awk '
    BEGIN { inc = 0 }
    {
      line = $0; out = ""
      while (length(line)) {
        if (inc) {
          p = index(line, "*/")
          if (p == 0) { line = ""; break }
          line = substr(line, p + 2); inc = 0
        } else {
          p = index(line, "/*")
          if (p == 0) { out = out line; line = ""; break }
          out = out substr(line, 1, p - 1); line = substr(line, p + 2); inc = 1
        }
      }
      print out
    }' "$@"
}

for prop in $(strip_comments "$ROOT"/assets/css/*.css | grep -oE 'var\(--[a-z0-9-]+' | sed 's/var(//' | sort -u); do
  echo "$DEFINED" | grep -qx -- "$prop" || UNDEF="$UNDEF $prop"
done
if [ -n "$UNDEF" ]; then
  bad "every custom property used is defined" "undefined:$UNDEF"
else
  ok "every custom property used is defined"
fi

# Covers are 1200x630 with the title baked in. A crop destroys them.
assert_grep 'aspect-ratio: 1200 */ *630' "$ROOT/assets/css/article.css" "cover keeps its exact aspect ratio"
# Scoped to the cover rule itself: .avatar is a square headshot and is meant to crop.
COVER_RULE=$(awk '/^\.article-cover img \{/,/^\}/' "$ROOT/assets/css/article.css")
case "$COVER_RULE" in
  *"object-fit: contain"*) ok "cover is never cropped" ;;
  *) bad "cover is never cropped" "the .article-cover img rule does not use object-fit: contain" ;;
esac

# Wide media must scroll or shrink inside its own box, never move the body.
assert_grep '\.prose iframe' "$ROOT/assets/css/prose.css" "embedded media is contained"

# The header is a fixed-height row that cannot shrink. Without the wrap it overflowed
# the page sideways on a phone as soon as a site had more than three menu entries.
# Nothing here opens a browser, so this guards the rule rather than the rendered result.
assert_grep 'flex-wrap: wrap' "$ROOT/assets/css/layout.css" "header wraps rather than overflowing"
# The taller two-row header needs a bigger anchor offset, and the rule has to live in
# prose.css: layout.css is concatenated first, so the same rule there silently loses.
assert_grep 'var(--sticky-offset) + var(--header-height)' "$ROOT/assets/css/prose.css" \
  "anchor offset clears the wrapped header"

# Chroma needs both modes. A token coloured in one and not the other is incomplete.
ONE_MODE=""
for tok in tok-com tok-key tok-str tok-num tok-tag; do
  COUNT=$(grep -c -- "--$tok:" "$TOKENS")
  [ "$COUNT" -ge 2 ] || ONE_MODE="$ONE_MODE $tok"
done
if [ -n "$ONE_MODE" ]; then
  bad "syntax colours declare both modes" "single-mode:$ONE_MODE"
else
  ok "syntax colours declare both modes"
fi

# Same for the admonition colours.
ADM_ONE_MODE=""
for tok in adm-note adm-tip adm-important adm-warning adm-caution; do
  COUNT=$(grep -c -- "--$tok:" "$TOKENS")
  [ "$COUNT" -ge 2 ] || ADM_ONE_MODE="$ADM_ONE_MODE $tok"
done
if [ -n "$ADM_ONE_MODE" ]; then
  bad "admonition colours declare both modes" "single-mode:$ADM_ONE_MODE"
else
  ok "admonition colours declare both modes"
fi

# Zen mode hides the TOC by the class the templates actually render. The selector once
# said `.toc-rail`, which matches nothing, so zen left the TOC visible below the article.
assert_grep 'data-zen\] \.toc,' "$ROOT/assets/css/interaction.css" "zen mode hides the TOC"
refute_grep 'toc-rail' "$ROOT/assets/css/interaction.css" "zen selector names a rendered class"

# The blur treatment targets the media layer background.html renders. The selector once
# expected an <img> that never existed, so layoutBackgroundBlur skipped the home background.
assert_grep 'home-bg-media' "$ROOT/layouts/_partials/home/background.html" "home background renders a media layer"
assert_grep 'data-bg-blur\] \.home-bg-media,' "$ROOT/assets/css/home-layouts.css" "background blur targets the media layer"

# The TOC rail declares its edge with logical properties: the theme ships RTL support,
# and a physical border-left paints the accent on the wrong side under dir="rtl".
if strip_comments "$ROOT/assets/css/article.css" "$ROOT/assets/css/interaction.css" | grep -q 'border-left'; then
  bad "TOC rail uses logical borders" "border-left found; use border-inline-start"
else
  ok "TOC rail uses logical borders"
fi

# Print: chrome hidden, code wrapping, links carrying their destination. Asserted in
# the built bundle, not only the source, so dropping the file from the concat list is
# caught too.
assert_grep '@media print' "$ROOT/assets/css/print.css" "print styles exist"
[ -n "$CSS_REF" ] && assert_grep '@media print' "$PUBLIC/$CSS_REF" "print styles reach the bundle"

# theme-color is a copy of the --bg pair from tokens.css (palettes recolour accents,
# not the page). A copy needs an assertion that keeps it honest.
BG_LINE=$(grep -- '--bg: light-dark(' "$TOKENS" | head -1)
BG_LIGHT=$(printf '%s' "$BG_LINE" | sed -E 's/.*light-dark\((#[0-9a-f]+), *(#[0-9a-f]+)\).*/\1/')
BG_DARK=$(printf '%s' "$BG_LINE" | sed -E 's/.*light-dark\((#[0-9a-f]+), *(#[0-9a-f]+)\).*/\2/')
assert_grep "prefers-color-scheme: light) *\" content=\"$BG_LIGHT\"" "$ROOT/layouts/_partials/head.html" \
  "light theme-color matches the --bg token"
assert_grep "prefers-color-scheme: dark) *\" content=\"$BG_DARK\"" "$ROOT/layouts/_partials/head.html" \
  "dark theme-color matches the --bg token"

# --------------------------------------------------------------------------------
group "Template guards"

# An explicit `mainSections = []` must not error the build. `index` on an empty slice
# fails, so the first element is only ever taken inside a `with` on the slice itself.
if grep -rq 'index site\.Params\.mainSections' "$ROOT/layouts"; then
  bad "mainSections is never indexed unguarded" "wrap the index in a with on the slice"
else
  ok "mainSections is never indexed unguarded"
fi

# The hotlink cover URL is escaped like the alt text beside it: both land in the same
# printf that is then marked safeHTML.
assert_grep 'htmlEscape \$hotlink' "$ROOT/layouts/_partials/cover.html" "hotlink cover URL is escaped"

# --------------------------------------------------------------------------------
group "Toolchain pins"

# The Hugo version lives in the Makefile and in theme.toml's min_version, and the two must
# agree: min_version is what a site author is told they need, the Makefile is what this repo
# actually builds with. Claiming one and testing the other is how a theme ships broken to
# everyone on the version it advertises.
MK_VER=$(grep -oE 'hugo:v[0-9]+\.[0-9]+\.[0-9]+' "$ROOT/Makefile" | head -1 | sed 's/.*:v//')
TT_VER=$(grep -oE 'min_version *= *"[0-9.]+"' "$ROOT/theme.toml" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
if [ -n "$MK_VER" ] && [ "$MK_VER" = "$TT_VER" ]; then
  ok "Makefile and theme.toml pin the same Hugo version"
else
  bad "Makefile and theme.toml pin the same Hugo version" "Makefile=$MK_VER theme.toml=$TT_VER"
fi

# Every workflow must derive the version from the Makefile rather than repeat it. A literal
# here means a Makefile bump leaves CI testing one Hugo and the deploy publishing with
# another: green checks, a different binary, nothing visible in the diff.
HARDCODED=$(grep -rlE 'HUGO_VERSION: *[0-9]+\.[0-9]+' "$ROOT/.github/workflows" 2>/dev/null | tr '\n' ' ')
if [ -z "$HARDCODED" ]; then
  ok "no workflow hardcodes the Hugo version"
else
  bad "no workflow hardcodes the Hugo version" "$HARDCODED"
fi

# --------------------------------------------------------------------------------
group "Largest contentful paint"

# The home page featured cover is the LCP element. It must carry a high fetch priority and
# must never be lazy: it is above the fold at every viewport.
FEATURE_IMG=$(grep -o '<img class=feature-cover[^>]*>' "$PUBLIC/index.html" | head -1)
case "$FEATURE_IMG" in
  *fetchpriority=high*) ok "featured cover requests high fetch priority" ;;
  "") bad "featured cover requests high fetch priority" "no feature-cover img found" ;;
  *)  bad "featured cover requests high fetch priority" "$FEATURE_IMG" ;;
esac
case "$FEATURE_IMG" in
  *loading=lazy*) bad "featured cover is not lazy-loaded" "$FEATURE_IMG" ;;
  *) ok "featured cover is not lazy-loaded" ;;
esac

# The article hero is the same story on a post page. The img inside .article-cover carries
# no class of its own, so match it through the figure.
ART_IMG=$(tr '>' '>\n' < "$PUBLIC/blog/measuring/index.html" | sed -n '/<figure class=article-cover/,/<\/figure/p' | grep -o '<img[^>]*>' | head -1)
case "$ART_IMG" in
  *fetchpriority=high*) ok "article cover requests high fetch priority" ;;
  "") bad "article cover requests high fetch priority" "no img found inside .article-cover" ;;
  *)  bad "article cover requests high fetch priority" "$ART_IMG" ;;
esac

# --------------------------------------------------------------------------------
group "Structure and accessibility, every page"

# The assertions above check that particular strings appear in particular files. That
# catches a feature disappearing; it cannot catch malformed markup, a duplicate id, an
# unlabelled control or a dead internal link, because none of those look different from
# valid output to a grep — and it only ever looks at the handful of pages somebody wrote
# an assertion for.
#
# tests/structure.py walks every built page instead. It found real defects the moment it
# was written: twelve term pages skipping from h1 to h3, an image-only link with no
# accessible name, and two demo posts jumping h2 to h4 on a page that is the theme's own
# integration test.
if [ "$HAVE_PY" -eq 1 ]; then
  if STRUCT=$(python3 "$ROOT/tests/structure.py" 2>&1); then
    ok "every page is well formed, named and linked ($(printf '%s' "$STRUCT" | head -1))"
  else
    bad "every page is well formed, named and linked" "$(printf '%s' "$STRUCT" | tail -n +1 | head -4 | tr '\n' ' ')"
  fi
else
  skip "structural sweep (python3 not available)"
fi

# --------------------------------------------------------------------------------
printf '\n'
if [ "$FAIL" -gt 0 ]; then
  red "FAILED  $FAIL failed, $PASS passed, $SKIP skipped"
  exit 1
fi
green "OK  $PASS passed, $SKIP skipped"
