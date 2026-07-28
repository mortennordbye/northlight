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

if grep -rqi 'nordbye' "$ROOT/layouts" "$ROOT/assets" "$ROOT/static" "$ROOT/i18n" 2>/dev/null; then
  bad "no author-specific values in theme files" "grep -ri nordbye matched"
else
  ok "no author-specific values in theme files"
fi

if grep -rqiE 'claude|anthropic|copilot' \
     "$ROOT/layouts" "$ROOT/assets" "$ROOT/i18n" "$ROOT/README.md" 2>/dev/null; then
  bad "no AI tool attribution in theme or docs" "matched a tool name"
else
  ok "no AI tool attribution in theme or docs"
fi

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
DOC_URLS=$(grep -oE 'https?://[^<]*/docs/[a-z-]+/' "$PUBLIC/sitemap.xml" | sort -u | wc -l | tr -d ' ')
assert_count 7 "$DOC_URLS" "all seven docs pages are in the sitemap"

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
assert_grep 'class=button href=/docs/getting-started/' "$SHORTCODES" "button resolves pageRef to a URL"

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
assert_grep '<div class=article-embed><a class=card href=/blog/' "$SHORTCODES" \
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

# Every runtime lookup needs an English fallback, so a missing catalogue leaves working
# controls rather than blank ones.
BAD_T=$(grep -rhoE '\bt\("[A-Za-z0-9_]+"\)' "$ROOT/assets/js" | sort -u)
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
printf '\n'
if [ "$FAIL" -gt 0 ]; then
  red "FAILED  $FAIL failed, $PASS passed, $SKIP skipped"
  exit 1
fi
green "OK  $PASS passed, $SKIP skipped"
