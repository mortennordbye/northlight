---
title: "Everything the Theme Has to Render"
description: "A kitchen-sink post used as the integration test. If a feature is not exercised here, it is not finished."
date: 2026-01-15
draft: false
tags: ["example", "kitchen-sink"]
---

This post exists to exercise every element the theme renders. Keep it in sync with the
build plan: when you add a feature, add the markup that proves it works.

## A second-level heading

Body copy sets the measure at 68ch. Here is an [external link](https://gohugo.io/) and some
`inline code` in a sentence.

### A third-level heading

- A list item
- Another one, with `code` inside it
- A third

> A blockquote. Used sparingly, and styled with the accent wash rather than a grey box.

## Code, in the languages that matter

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example
  namespace: default
data:
  key: "value"
```

```bash
# A comment, which must stay legible in both colour modes
find . -name '*.md' | sort -u
```

```dockerfile
FROM alpine:3.20
RUN apk add --no-cache ca-certificates
```

## Raw HTML

The site config enables `unsafe` HTML, so posts may contain markup like this:

<img src="/images/example.svg" alt="An example image" style="width:70%;" />

## Fourth level

#### This is an h4

It should render, and it should appear in the table of contents, which is configured for
levels 2 through 4.
