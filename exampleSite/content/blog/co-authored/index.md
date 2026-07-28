---
title: "A Post With Two Authors"
description: "Credited to two people, so the byline, the author pages and the author card at the foot all have something real to render."
date: 2026-03-18
draft: false
tags: ["writing"]
authors: ["morten", "ada"]
---

This post is credited to two people. Its byline names both, each linking to an author
page listing what they wrote, and the card at the foot carries the fuller version with
headlines and links.

Authors come from `data/authors/`, one file per person, keyed by filename. A post lists
the keys it wants in `authors`, and a key with no matching file fails the build rather
than quietly dropping somebody's name from their own work.

A post that says nothing about authors falls back to the single `[params.author]` in
site config, which is what every other post on this site does.
