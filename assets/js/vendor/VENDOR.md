# Vendored libraries

Third-party code, committed verbatim. **Do not edit anything in this directory** — it is
replaced wholesale on upgrade, and a local change would be silently lost.

Everything here is self-hosted rather than pulled from a CDN, because a CDN reference is a
third-party request on page view and this theme does not make one on anybody's behalf. Each
file is fingerprinted and integrity-hashed by Hugo like every other asset, and each is
loaded only on pages that use the feature it belongs to — never from the main bundle.

`tests/run.sh` excludes this directory from the theme-authoring scans, and asserts that
every file here has a row below.

| File | Version | Licence | Upstream | Loaded by |
|---|---|---|---|---|
| `chart.umd.min.js` | 4.5.1
version | MIT | https://github.com/chartjs/Chart.js | `_shortcodes/chart.html`, gated on `.HasShortcode` in `baseof.html` |
| `mermaid.min.js` | 11.16.0
version | MIT | https://github.com/mermaid-js/mermaid | `_shortcodes/mermaid.html`, gated on `.HasShortcode` in `baseof.html` |

## Upgrading

Replace the file, update its row, and rebuild. The fingerprint changes on its own, so no
cache-busting is needed. Check the diagram on the shortcodes page in **both** colour modes
afterwards — mermaid bakes its palette into the SVG, so a theme regression there is
invisible in one mode.
