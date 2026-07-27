---
title: "Shipping a Static Site Without a Node Toolchain"
description: "Hugo's asset pipeline covers concatenation, minification and fingerprinting on its own. A third post, so related content has more than one candidate to choose from."
date: 2026-03-22
draft: false
tags: ["example", "build"]
---

The usual static-site build has a Node step in it, and the Node step is where most of the
breakage lives. Hugo's own pipeline covers enough that a content site does not need one.

## What the pipeline already does

Concatenation, minification, fingerprinting and subresource integrity are all built in:

```go-html-template
{{ $css := slice
     (resources.Get "css/tokens.css")
     (resources.Get "css/base.css")
   | resources.Concat "css/site.css" | minify | fingerprint "sha512" }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}" integrity="{{ $css.Data.Integrity }}">
```

That is the whole build. No lockfile, no `node_modules`, nothing to audit.

## What you give up

Autoprefixing, and the ability to use a framework that assumes a bundler. Custom properties
and modern CSS cover most of what a preprocessor was for, and the browsers that needed the
prefixes are gone.

## What you gain

A build that still works in two years. The failure modes of a Hugo-only build are Hugo's,
and there is exactly one binary to upgrade.
