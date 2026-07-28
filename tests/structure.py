#!/usr/bin/env python3
"""Structural and accessibility sweep over every built page.

`tests/run.sh` asserts that particular strings appear in particular files. That catches a
feature disappearing; it cannot catch malformed markup, a duplicate id, an unlabelled
control or a dead internal link, because none of those look different from valid output to
a `grep`. This walks every page instead, so a defect on a page nobody wrote an assertion
for is still found.

Everything here is a whole-site sweep. That is the point: the existing suite spot-checks
one article and one docs page, and the bugs that survive spot-checking are the ones on the
seventh page.

Run with `make check` — it is fast, because it is one pass over files already built.
"""

import collections
import html.parser
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PUBLIC = ROOT / "exampleSite" / "public"

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "source", "track", "wbr"}

# Elements that carry an accessible name from their content or an attribute.
NEEDS_NAME = {"a", "button"}


class Page(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.ids = collections.Counter()
        self.problems = []
        self.headings = []
        self.links = []
        # Track the element currently collecting text, for accessible-name checks.
        self._open = []

    def handle_starttag(self, tag, attrs):
        # A minimised attribute — `alt` with no value, which is what Hugo's minifier emits
        # for alt="" — parses as None rather than "". Normalising here rather than at each
        # read: the first version crashed on every page carrying a decorative image.
        a = {k: (v if v is not None else "") for k, v in attrs}

        if "id" in a:
            self.ids[a["id"]] += 1

        if tag == "img" and "alt" not in a:
            self.problems.append(f"<img> with no alt attribute: {a.get('src', '?')[:60]}")

        if tag == "a":
            href = a.get("href", "")
            if not href:
                self.problems.append("<a> with no href")
            else:
                self.links.append(href)
            if a.get("target") == "_blank" and "noopener" not in a.get("rel", ""):
                self.problems.append(f"target=_blank without rel=noopener: {href[:60]}")

        if re.fullmatch(r"h[1-6]", tag):
            self.headings.append(int(tag[1]))

        # An image inside a link contributes its alt to the link's accessible name, which
        # is what the accname algorithm does and what a screen reader announces. Without
        # this the checker reported every image link as unnamed, including correct ones.
        if tag == "img" and self._open and a.get("alt", "").strip():
            self._open[-1]["text"] += " " + a["alt"]

        if tag in NEEDS_NAME:
            # aria-hidden removes the element from the accessibility tree entirely, so
            # there is no name to require. Paired with tabindex="-1" it is the correct
            # treatment for a second link to a destination already named beside it.
            if a.get("aria-hidden") == "true":
                self._open.append({"tag": tag, "attrs": a, "text": "", "hidden": True})
            else:
                self._open.append({"tag": tag, "attrs": a, "text": "", "hidden": False})

        if tag not in VOID:
            self.stack.append(tag)

    def handle_data(self, data):
        for frame in self._open:
            frame["text"] += data

    def handle_endtag(self, tag):
        if tag in NEEDS_NAME and self._open:
            for i in range(len(self._open) - 1, -1, -1):
                if self._open[i]["tag"] == tag:
                    frame = self._open.pop(i)
                    if frame.get("hidden"):
                        break
                    named = (frame["text"].strip()
                             or frame["attrs"].get("aria-label")
                             or frame["attrs"].get("aria-labelledby")
                             or frame["attrs"].get("title"))
                    if not named:
                        which = frame["attrs"].get("href") or frame["attrs"].get("class") or ""
                        self.problems.append(
                            f"<{tag}> with no accessible name: {str(which)[:60]}")
                    break

        if tag in VOID:
            return
        if tag in self.stack:
            while self.stack and self.stack.pop() != tag:
                pass
        else:
            self.problems.append(f"</{tag}> closes nothing")

    def finish(self):
        for tag in reversed(self.stack):
            if tag not in ("html", "body", "head", "p", "li"):
                self.problems.append(f"<{tag}> is never closed")
        for ident, n in self.ids.items():
            if n > 1:
                self.problems.append(f'id="{ident}" appears {n} times')
        # Heading order: never skip a level going down.
        prev = None
        for h in self.headings:
            if prev is not None and h > prev + 1:
                self.problems.append(f"heading level jumps h{prev} to h{h}")
            prev = h
        return self.problems


def internal(href):
    if href.startswith(("http://", "https://", "mailto:", "tel:", "#", "data:", "javascript:")):
        return None
    return href.split("#", 1)[0].split("?", 1)[0]


def resolves(href, page):
    """Does an internal link land on something that was actually built?"""
    target = internal(href)
    if target in (None, ""):
        return True
    if target.startswith("/"):
        p = PUBLIC / target.lstrip("/")
    else:
        p = page.parent / target
    if p.is_dir() or (p / "index.html").exists():
        return True
    return p.exists() or (p.with_suffix(p.suffix + "/index.html")).exists()


def main():
    pages = sorted(PUBLIC.rglob("index.html")) + sorted(PUBLIC.rglob("404.html"))
    if not pages:
        print("structure: no built pages found — run `make build` first")
        return 1

    findings = collections.defaultdict(list)
    dead = []

    for page in pages:
        rel = page.relative_to(PUBLIC)
        text = page.read_text(errors="replace")
        p = Page()
        try:
            p.feed(text)
        except Exception as e:                       # noqa: BLE001 — report, do not abort
            findings[str(rel)].append(f"failed to parse: {e}")
            continue
        for problem in dict.fromkeys(p.finish()):
            findings[str(rel)].append(problem)
        for href in p.links:
            if not resolves(href, page):
                dead.append(f"{rel} -> {href}")

    total = sum(len(v) for v in findings.values())
    print(f"structure: {len(pages)} pages, {total} problem(s), {len(dead)} dead internal link(s)")

    if findings:
        for rel in sorted(findings):
            for problem in findings[rel][:6]:
                print(f"  {rel}: {problem}")
    for d in dead[:12]:
        print(f"  dead link: {d}")

    return 1 if (findings or dead) else 0


if __name__ == "__main__":
    sys.exit(main())
