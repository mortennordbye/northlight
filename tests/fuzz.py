#!/usr/bin/env python3
"""Fuzz the shortcode parameter surface.

Shortcodes are the only place in this theme where a *content author's* text reaches a
template as a parameter rather than as Markdown. Everything else the reader sees is either
site config, which the site owner controls, or prose, which Goldmark escapes. So this is
where escaping bugs live, and a `grep`-for-a-string suite cannot find them: the failures
look like valid output.

Two passes, because there are two correct behaviours and only one wrong one.

  ACCEPT  Text parameters — alt, caption, title, label. These must never fail a build, and
          whatever goes in must come out inert: escaped, not executing, not `ZgotmplZ`.

  REJECT  Validated parameters — a ratio, a hex colour, an enum. These must fail the build
          loudly. A shortcode that silently renders a collapsed box for `ratio="banana"` is
          the exact failure `video` shipped with before it was measured.

The wrong behaviour, and the only thing this reports as a failure, is a build that
*succeeds with broken or unsafe output*.

Shortcodes that fetch at build time are excluded and listed at the bottom of this file:
fuzzing them means hammering GitHub with generated repository names, and their failure
handling is already covered by the suite.

Run with `make fuzz`. Not part of `make check` — it builds a site per rejection case, which
is slower than the gate should be.
"""

import html.parser
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
HUGO_IMAGE = "ghcr.io/gohugoio/hugo:v0.164.0"

# --------------------------------------------------------------------------------------
# The corpus. Every entry is something that has broken a templating system somewhere.

HOSTILE = [
    ('<script>alert(1)</script>',        "script tag"),
    ('"><script>alert(1)</script>',      "attribute break-out"),
    ("'\"><img src=x onerror=alert(1)>", "quote break-out with handler"),
    ('javascript:alert(1)',              "javascript scheme"),
    ('{{ .Site.Params }}',               "Go template injection"),
    # Shortcode syntax is deliberately absent from this corpus. Hugo resolves it wherever
    # it appears in content — inner text and quoted parameters alike — before any template
    # in this theme is reached, so a nested `{{< figure >}}` executes and fails on a missing
    # image. That is Hugo's parser under test rather than this theme's escaping, and the
    # build failing loudly is the correct outcome either way. Three iterations were spent
    # rediscovering that; it is written down so a fourth is not.
    ('</p><div>escaped out',             "tag balance break"),
    ('&lt;already escaped&gt;',          "double-escaping probe"),
    ('a" onmouseover="alert(1)',         "unquoted attribute injection"),
    ('../../etc/passwd',                 "path traversal"),
    ('\\x00\\x01control',                "control characters"),
    ('“smart” ‘quotes’ — em dash',       "typographic punctuation"),
    ('🙂 emoji ZWJ 👩‍💻',                  "astral plane and ZWJ"),
    ('عربي مختلط with latin',            "bidirectional text"),
    ('A' * 2000,                         "very long value"),
    # Empty and whitespace-only are deliberately not in this corpus.
    #
    # Whether empty is *hostile* depends entirely on whether the parameter is required,
    # and a corpus cannot know that. `alert title=""` is correct — the title is optional
    # and falls back to the type name. `accordionItem title=""` and `keyword` with no
    # inner text are both correctly refused. Same input, three shortcodes, two right
    # answers. So the required ones are enumerated in REJECT below, where the expectation
    # can be stated per shortcode instead of guessed.
    ('%s %d %q',                         "format specifiers"),
    ('expression(alert(1))',             "CSS expression"),
    ('red;background:url(//evil/x)',     "CSS injection"),
]

# Shortcodes whose text parameters must survive the corpus intact-but-inert.
# {V} is the fuzzed value.
ACCEPT = [
    ("alert",         '{{< alert title="{V}" >}}body{{< /alert >}}'),
    ("accordion",     '{{< accordion >}}{{< accordionItem title="{V}" >}}b{{< /accordionItem >}}{{< /accordion >}}'),
    ("badge",         '{{< badge >}}{V}{{< /badge >}}'),
    ("button",        '{{< button href="https://example.com" >}}{V}{{< /button >}}'),
    ("keyword",       '{{< keywordList >}}{{< keyword >}}{V}{{< /keyword >}}{{< /keywordList >}}'),
    ("lead",          '{{< lead >}}{V}{{< /lead >}}'),
    ("tabs",          '{{< tabs >}}{{< tab label="{V}" >}}b{{< /tab >}}{{< /tabs >}}'),
    ("timeline",      '{{< timeline >}}{{< timelineItem header="{V}" >}}b{{< /timelineItem >}}{{< /timeline >}}'),
    ("typeit",        '{{< typeit >}}{V}{{< /typeit >}}'),
    ("ltr",           '{{< ltr >}}{V}{{< /ltr >}}'),
    ("rtl",           '{{< rtl >}}{V}{{< /rtl >}}'),
    ("email-text",    '{{< email email="a@b.com" text="{V}" >}}'),
    ("email-subject", '{{< email email="a@b.com" subject="{V}" >}}'),
]

# Validated parameters. Each of these must fail the build.
REJECT = [
    ("video ratio",        '{{< video src="clip.mp4" ratio="banana" >}}'),
    ("video preload",      '{{< video src="clip.mp4" preload="metadta" >}}'),
    ("video no src",       '{{< video >}}'),
    ("chart no alt",       '{{< chart >}}{"type":"line"}{{< /chart >}}'),
    ("chart bad json",     '{{< chart alt="x" >}}{not json{{< /chart >}}'),
    ("chart ratio",        '{{< chart alt="x" ratio="4:3" >}}{"type":"line"}{{< /chart >}}'),
    ("swatches bad hex",   '{{< swatches "notahex" >}}'),
    ("swatches injection", '{{< swatches "red;background:url(//x)" >}}'),
    ("icon unknown",       '{{< icon "definitely-not-an-icon" >}}'),
    ("button no target",   '{{< button >}}x{{< /button >}}'),
    ("button bad pageRef", '{{< button pageRef="/nowhere/at/all" >}}x{{< /button >}}'),
    ("figure no src",      '{{< figure >}}'),
    # The missing file *is* the parameter under test here, so these opt out of the
    # isolation check below rather than being reported by it.
    ("figure missing src", '{{< figure src="nope.png" >}}', "missing-ok"),
    ("video missing src",  '{{< video src="nope.mp4" >}}', "missing-ok"),
    ("youtube no id",      '{{< youtube-lite >}}'),
    ("youtube no poster",  '{{< youtube-lite id="abc" >}}'),
    ("typeit bad tag",     '{{< typeit tag="script" >}}x{{< /typeit >}}'),
    ("huggingface kind",   '{{< huggingface id="x" kind="weights" >}}'),
    ("gist no id",         '{{< gist user="x" >}}'),
    ("oembed no endpoint", '{{< oembed url="https://example.com" >}}'),
    ("codeimporter no url",'{{< codeimporter >}}'),
    ("mdimporter no url",  '{{< mdimporter >}}'),
    ("ansible no name",    '{{< ansible namespace="x" >}}'),
    # Required parameters given an empty value. Found by the accept pass rather than
    # written from the outset: it failed on an empty accordion title, which turned out to
    # be the shortcode correctly refusing input rather than a bug.
    ("accordion empty title", '{{< accordion >}}{{< accordionItem title="" >}}b{{< /accordionItem >}}{{< /accordion >}}'),
    ("keyword empty",         '{{< keywordList >}}{{< keyword >}}{{< /keyword >}}{{< /keywordList >}}'),
    ("tab empty label",       '{{< tabs >}}{{< tab label="" >}}b{{< /tab >}}{{< /tabs >}}'),
    ("email empty address",   '{{< email email="" >}}'),
    ("video empty src",       '{{< video src="" >}}'),
]

# Excluded, with the reason, so nobody has to rediscover it.
EXCLUDED = {
    "github/gitlab/codeberg/gitea/forgejo/huggingface/ansible":
        "fetches at build time — fuzzing means generating repository names and hammering a "
        "forge's API. Their failure handling is covered by the suite instead.",
    "gist/oembed/codeimporter/mdimporter":
        "same: a build-time fetch. Their *missing-parameter* rejection is fuzzed above, "
        "which is the part that does not touch the network.",
    "mermaid":
        "takes no parameters; its body is passed through verbatim by design, and the "
        "renderer is a vendored library rather than this theme's escaping.",
}


# --------------------------------------------------------------------------------------

class Structure(html.parser.HTMLParser):
    """Checks the fragment is well formed and carries no live script or handler."""

    VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input",
            "link", "meta", "source", "track", "wbr"}

    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.stack = []
        self.problems = []

    def handle_starttag(self, tag, attrs):
        if tag == "script":
            self.problems.append("a <script> element was produced from input")
        for name, value in attrs:
            if name.startswith("on"):
                self.problems.append(f"event handler {name}= was produced from input")
            if value and name in ("href", "src") and value.strip().lower().startswith("javascript:"):
                self.problems.append(f"{name}= carries a javascript: URL")
        if tag not in self.VOID:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if tag in self.VOID:
            return
        if tag in self.stack:
            while self.stack and self.stack.pop() != tag:
                pass
        else:
            self.problems.append(f"</{tag}> closes nothing")


def build(site, expect_ok):
    """Build a scratch site. Returns (ok, combined output)."""
    r = subprocess.run(
        ["docker", "run", "--rm",
         "-v", f"{ROOT}:/src/northlight",
         "-v", f"{site}:/src/site",
         "-w", "/src/northlight",
         HUGO_IMAGE, "--source", "/src/site", "--themesDir", "/src",
         # --panicOnWarning because that is what `make check` does. Without it a
         # shortcode that rejects input with warnf — `icon` does — builds cleanly and
         # looks like it accepted the value. The gate is the contract; match it.
         "--minify", "--gc", "--panicOnWarning"],
        capture_output=True, text=True)
    return r.returncode == 0, (r.stdout + r.stderr)


# Real media, so a rejection case fails for the reason under test and not because the file
# was missing. `{{< video src="c.mp4" ratio="banana" >}}` with no c.mp4 fails on the missing
# source before the ratio is ever looked at — the harness saw a failed build and called it a
# pass, and a silent ratio fallback went undetected. Measured: introducing exactly that
# fallback produced "no findings" until this was fixed.
FIXTURES = {
    "clip.mp4": ROOT / "exampleSite/content/docs/shortcodes/clip.mp4",
    "shot.png": ROOT / "exampleSite/content/docs/shortcodes/shot-a.png",
}


def scratch(pages):
    """A minimal site carrying `pages` as {name: markdown}.

    Each page is a leaf bundle with the fixtures beside it, so a shortcode that resolves a
    page resource finds one.
    """
    d = pathlib.Path(tempfile.mkdtemp(prefix="northlight-fuzz-"))
    (d / "content").mkdir()
    (d / "hugo.toml").write_text(
        'baseURL = "https://example.com/"\n'
        'title = "fuzz"\n'
        'theme = "northlight"\n'
        'disableKinds = ["taxonomy", "term", "RSS", "sitemap"]\n'
        # Goldmark warns when it refuses raw HTML in content — which is exactly what should
        # happen to a fuzzed <script>, and exactly what this is checking for. The warning is
        # the desired behaviour reporting itself, so it is silenced rather than counted as a
        # failure. Everything else still fails the build.
        #
        # It sits *above* every [table] header on purpose: in TOML a bare key after a table
        # header belongs to that table, so putting it lower made it
        # markup.goldmark.renderer.ignoreLogs and silenced nothing.
        "ignoreLogs = ['warning-goldmark-raw-html']\n"
        '[markup.highlight]\n  noClasses = false\n'
        '[markup.goldmark.renderer]\n  unsafe = false\n'
        '[taxonomies]\n  tag = "tags"\n'
    )
    for name, body in pages.items():
        bundle = d / "content" / name
        bundle.mkdir()
        (bundle / "index.md").write_text(
            f'---\ntitle: "{name}"\n---\n\n{body}\n')
        for fname, src in FIXTURES.items():
            if src.exists():
                shutil.copy(src, bundle / fname)
    return d


def run_accept():
    """Every hostile value through every text parameter, in one build."""
    pages, index = {}, {}
    for si, (label, tmpl) in enumerate(ACCEPT):
        quoted = 'V}"' in tmpl          # {V} sits inside a param="..."
        for vi, entry in enumerate(HOSTILE):
            value, why = entry[0], entry[1]
            scope = entry[2] if len(entry) > 2 else "both"
            if scope == "params" and not quoted:
                continue
            name = f"a{si}x{vi}"
            # A bare " inside a quoted shortcode parameter is rejected by Hugo's own
            # shortcode parser, before any template sees it — "unrecognized character in
            # shortcode action". That is a real defence and not something this theme can
            # get wrong, so the value is escaped the way an author would have to escape
            # it. Inner content takes the value raw, where the quote is just text.
            v = value.replace('\\', '\\\\').replace('"', '\\"') if quoted else value
            pages[name] = tmpl.replace("{V}", v)
            index[name] = (label, why, value)

    site = scratch(pages)
    try:
        ok, out = build(site, True)
        if not ok:
            # A text parameter must never fail a build. Report what did.
            m = re.search(r'content/(a\d+x\d+)\.md', out)
            which = index.get(m.group(1), ("?", "?", "?")) if m else ("?", "?", "?")
            return [f"build failed on a text parameter — {which[0]} with {which[1]}",
                    out.strip().splitlines()[-1] if out.strip() else ""]

        problems = []
        for name, (label, why, value) in index.items():
            f = site / "public" / name / "index.html"
            if not f.exists():
                problems.append(f"{label} / {why}: no page was built")
                continue
            page = f.read_text()
            body = re.search(r'<div class="?prose"?>(.*?)</div>', page, re.S)
            frag = body.group(1) if body else page

            if "ZgotmplZ" in page:
                problems.append(f"{label} / {why}: ZgotmplZ — a value was rejected by the "
                                f"escaper and silently blanked")

            s = Structure()
            s.feed(frag)
            for p in dict.fromkeys(s.problems):
                problems.append(f"{label} / {why}: {p}")
        return problems
    finally:
        shutil.rmtree(site, ignore_errors=True)


def run_reject():
    """Each invalid parameter, in its own build, all of which must fail."""
    problems = []
    for entry in REJECT:
        label, tmpl = entry[0], entry[1]
        missing_ok = len(entry) > 2 and entry[2] == "missing-ok"
        site = scratch({"p": tmpl})
        try:
            ok, out = build(site, False)
            if not ok:
                # It failed — but for the right reason? A case that fails on a missing
                # file rather than on the parameter under test proves nothing.
                if not missing_ok and ("no such file" in out or "no video found" in out
                                       or "no image found" in out):
                    problems.append(f"{label}: failed on a missing fixture, not on the "
                                    f"parameter under test — the case is not isolated")
            if ok:
                page = site / "public" / "p" / "index.html"
                rendered = page.read_text() if page.exists() else ""
                detail = "ZgotmplZ in output" if "ZgotmplZ" in rendered else "built silently"
                problems.append(f"{label}: accepted invalid input ({detail})")
        finally:
            shutil.rmtree(site, ignore_errors=True)
    return problems


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    failures = []

    if which in ("all", "accept"):
        n = len(ACCEPT) * len(HOSTILE)
        print(f"accept: {n} cases ({len(ACCEPT)} parameters x {len(HOSTILE)} values), one build")
        f = run_accept()
        failures += f
        print(f"        {'FAIL ' + str(len(f)) if f else 'ok'}")

    if which in ("all", "reject"):
        print(f"reject: {len(REJECT)} cases, one build each")
        f = run_reject()
        failures += f
        print(f"        {'FAIL ' + str(len(f)) if f else 'ok'}")

    if failures:
        print("\nfindings:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("\nno findings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
