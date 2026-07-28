/* Draws the charts on a page and keeps them in step with the colour mode.
 *
 * Loaded only on pages that contain a chart — `baseof.html` gates both this and the
 * library on `.HasShortcode "chart"` — so nothing here costs anything elsewhere.
 *
 * The configuration arrives as JSON on the element's `data-chart` attribute, already
 * validated at build time. Nothing is evaluated, so a site running a strict CSP is
 * unaffected.
 */
(function () {
  "use strict";

  var nodes = document.querySelectorAll("canvas.chart");
  if (!nodes.length || typeof Chart === "undefined") return;

  var charts = [];

  /* Chart.js has no notion of the page's colour mode, and its defaults are tuned for a
     light background — near-black text and dark gridlines, which vanish on a dark page.
     Rather than hardcode a second palette, read the theme's own tokens: the chart then
     follows a custom palette from `custom.css` as well as the built-in three.

     Reading the custom property directly does not work. Every colour token in this theme
     is a `light-dark()` pair, and `getPropertyValue` hands back that function as *text* —
     "light-dark(#52525b, #a3a3ad)" — which Chart.js cannot parse, so it silently falls
     back to its own light-mode defaults. Measured before this was fixed: black text and
     a black line on a dark page.

     Resolving it means letting the engine do the work. Applying the token to a real
     element as `color` and reading the computed value back gives a plain `rgb(...)`,
     because `color` is a resolved value at that point. The probe is detached from layout
     and never painted. */
  var probe = document.createElement("span");
  probe.style.cssText = "position:absolute;visibility:hidden;pointer-events:none";
  document.body.appendChild(probe);

  function resolve(token, fallback) {
    probe.style.color = "";
    probe.style.color = "var(" + token + ")";
    var value = getComputedStyle(probe).color;
    return value || fallback;
  }

  function tokens() {
    return {
      fg: resolve("--fg-2", "#666"),
      line: resolve("--line", "#ccc"),
      accent: resolve("--accent", "#4f57c4"),
      pastel: resolve("--accent-pastel", "#a6aef0"),
      font: getComputedStyle(document.body).fontFamily
    };
  }

  function applyTheme() {
    var t = tokens();
    Chart.defaults.color = t.fg;
    Chart.defaults.borderColor = t.line;
    Chart.defaults.font.family = t.font;
    return t;
  }

  function build(el) {
    var cfg;
    try {
      cfg = JSON.parse(el.getAttribute("data-chart"));
    } catch (e) {
      return null;
    }
    var t = tokens();

    /* A chart with no colours of its own gets the palette's accent, so the default case
       looks like the rest of the site rather than like Chart.js. An author who sets
       colours in the config keeps them. */
    (cfg.data && cfg.data.datasets ? cfg.data.datasets : []).forEach(function (d) {
      if (!d.borderColor) d.borderColor = t.accent;
      if (!d.backgroundColor) d.backgroundColor = t.pastel;
    });

    /* The <div> around the canvas owns the aspect ratio, so Chart.js must not impose its
       own or the box and the drawing disagree at some viewport widths. */
    cfg.options = cfg.options || {};
    cfg.options.responsive = true;
    cfg.options.maintainAspectRatio = false;

    /* prefers-reduced-motion covers the entry animation, which is the only motion here.
       Chart.js animates on first draw by default, and a reader who asked for no motion
       should not get a chart that draws itself in. */
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      cfg.options.animation = false;
    }

    return new Chart(el, cfg);
  }

  function render() {
    applyTheme();
    charts.forEach(function (c) {
      if (c) c.destroy();
    });
    charts = Array.prototype.map.call(nodes, build);
  }

  render();

  /* Colours are baked into the drawing, so a mode change means drawing again. */
  document.addEventListener("northlight:appearance", render);
})();
