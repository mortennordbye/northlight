# Security Policy

## Supported Versions

Only the latest release is actively supported with security updates.

## Scope

Northlight is a Hugo theme: templates, CSS and a few vanilla-JS modules. It has no server, no
authentication, no database and no network surface at runtime, so the realistic surface is
small. Reports that do matter here include:

- A template that emits site-author or page content without escaping, producing HTML or script
  injection on a built site.
- A default that causes a site to make a third-party request it did not opt into.
- A supply-chain issue in this repository's own workflows or release process.

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues.

Use the **Report a vulnerability** button under this repository's
[Security tab](https://github.com/mortennordbye/northlight/security) — private vulnerability
reporting is enabled. You will receive an acknowledgement within 48 hours.
