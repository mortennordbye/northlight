---
title: "Translating"
description: "Every string the theme puts on screen lives in one file. Translating it means copying that file."
weight: 7
date: 2026-07-27
---

No user-facing string is hardcoded in a template. They all live in `i18n/en.toml`, so
translating the theme means copying that file to your language code and translating the
values. Nothing else changes.

```bash {file="terminal"}
cp themes/northlight/i18n/en.toml i18n/nb.toml
```

Then set the language:

```toml {file="hugo.toml"}
locale = "nb"
defaultContentLanguage = "nb"
```

Your site's `i18n/` wins over the theme's, and any key you leave out falls back to the
theme's English, so a partial translation degrades one string at a time rather than
producing blanks.

## Several languages at once

Translating the chrome is one thing; running the site in more than one language is another,
and Hugo does most of it. Declare the languages and the theme supplies the rest — a
switcher in the header, `hreflang` alternates in `<head>`, a search index per language, and
per-language date formats.

```toml {file="hugo.toml"}
[languages]
  [languages.en]
    label = "English"
    weight = 1
    [languages.en.params]
      displayName = "English"

  [languages.nb]
    label = "Norsk bokmål"
    weight = 2
    [languages.nb.params]
      displayName = "Norsk"
      dateFormat = "2. Jan 2006"
```

> [!CAUTION]
> **Put this block at the end of your config.** In TOML every key after a `[table]` header
> belongs to that table, so a `[languages]` block near the top silently swallows `theme`,
> your whole `[params]` and your menus into `languages.<last>.params`. The build then fails
> with something like *"template for shortcode button not found"*, which says nothing about
> the real cause.

`displayName` is what the switcher shows, and it should be each language's name **in that
language** — a reader looking for Norwegian is looking for "Norsk", not "Norwegian".

**The switcher links to the translation of the page you are on**, not to the other
language's home page. Where a page has no translation it falls back to that language's home
page, because the alternative is a dead link. The language you are already reading renders
as text rather than as a link to the page you are on.

Menus are per-language as well. Defining `[languages.nb.menus]` **replaces** the top-level
`[menu]` for that language rather than adding to it, which is usually what you want: a
language with fewer translated pages should have a shorter menu.

Content is paired by filename — `index.md` and `index.nb.md` in the same page bundle are
two translations of one page, and that pairing is what the switcher and the `hreflang`
alternates both read.

## Plurals

Entries with `one` and `other` are pluralised by Hugo from the count passed in, rather
than by a conditional buried in a template. A language whose plural rules differ from
English is expressible here without touching any Go template.

```toml {file="i18n/nb.toml"}
[postCount]
one = "{{ . }} innlegg"
other = "{{ . }} innlegg"
```

`{{ . }}` is the value passed to the call. Keep it in the translation.

> [!WARNING]
> Ordering matters. In TOML, every bare key after a `[table]` header belongs to that
> table, so all the pluralised entries sit at the bottom of the file. Add a simple key
> below them and it silently becomes part of the last table, and the build fails with
> "reserved keys mixed with unreserved keys".

## Strings that only exist after a click

A few strings are not in the markup at all, because they appear in response to something
the reader does: the copy button changing to "Copied", the appearance toggle's tooltip.
Those are serialised into a small JSON block that the scripts read once.

You do not have to do anything about this. They come from the same `i18n` file, and
every lookup carries an English fallback, so a missing or malformed block leaves working
buttons rather than blank ones.

## Right to left

```toml {file="hugo.toml"}
[params]
  rtl = true
```

Sets `dir="rtl"` on `<html>`. The layout is built with logical properties in most
places, so it mirrors, but this has had far less real-world exercise than the rest of
the theme.

> [!CAUTION]
> If you run the theme in a right-to-left language, please report what breaks. It is
> the part of the theme least likely to be correct, because it is the part nobody has
> yet used in anger.

## Dates

Date formatting is a separate setting, because "2 Jan 2006" is an English convention
rather than a universal one:

```toml {file="hugo.toml"}
[params]
  dateFormat = "2006-01-02"
```

The value is a Go reference-time layout, the same as anywhere else in Hugo.
