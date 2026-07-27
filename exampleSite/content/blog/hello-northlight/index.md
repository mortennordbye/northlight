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

Seven languages, because those are the seven the reference blog uses. Every one of them
has to be legible in both colour modes, comments included.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example
  namespace: default
data:
  # Comments must clear 4.5:1 against the code background
  replicas: 3
  key: "value"
  enabled: true
```

```bash
# A comment, which must stay legible in both colour modes
find . -name '*.md' -mtime -7 | sort -u | head -20
export COUNT="$(grep -c . < list.txt)"
```

```dockerfile
FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --chown=1000:1000 . /srv
EXPOSE 8080
```

```nginx
server {
    listen       443 ssl;
    server_name  example.com;

    # Cache immutable assets for a year
    location ~* \.(css|js|woff2)$ {
        expires    1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "example-assets"
  tags = {
    Environment = "production"
    Managed     = true
  }
}
```

```alloy
prometheus.scrape "default" {
  targets    = discovery.kubernetes.pods.targets
  forward_to = [prometheus.remote_write.default.receiver]
}
```

```text
NAME                     READY   STATUS    RESTARTS   AGE
northlight-7d9f8c6b-x2k  1/1     Running   0          14d
```

Line numbers and a highlighted line are configured per fence rather than globally, so
both need styling even though the reference blog uses neither:

```yaml {linenos=table,hl_lines=[3]}
metadata:
  name: example
  namespace: highlighted
  labels:
    app: northlight
```

## Raw HTML

The site config enables `unsafe` HTML, so posts may contain markup like this:

<img src="/images/example.svg" alt="An example image" style="width:70%;" />

## Fourth level

#### This is an h4

It should render, and it should appear in the table of contents, which is configured for
levels 2 through 4.
