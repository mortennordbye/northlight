/* Initialises mermaid and keeps it in step with the colour mode.
 *
 * Loaded only on pages that contain a diagram — `baseof.html` gates both this and the
 * library itself on `.HasShortcode "mermaid"` — so nothing here costs anything on a page
 * without one.
 *
 * The source sits in the <pre> as text. Until this runs, that text *is* the fallback, and
 * it stays the fallback if the library fails to load. Nothing is emptied before there is
 * something to put in its place.
 */
(function () {
  "use strict";

  var nodes = document.querySelectorAll("pre.mermaid");
  if (!nodes.length || typeof mermaid === "undefined") return;

  /* The diagram source, kept per element. Mermaid replaces the element's content with
     rendered SVG, so re-rendering on a theme change needs the original text back — read
     it once, before the first render destroys it. */
  var sources = [];
  Array.prototype.forEach.call(nodes, function (el) {
    sources.push(el.textContent);
  });

  function themeName() {
    return document.documentElement.getAttribute("data-theme") === "dark"
      ? "dark"
      : "default";
  }

  function render() {
    Array.prototype.forEach.call(nodes, function (el, i) {
      el.textContent = sources[i];
      el.removeAttribute("data-processed");
    });
    mermaid.initialize({
      startOnLoad: false,
      theme: themeName(),
      /* The diagram inherits the page's own type stack rather than mermaid's default,
         so a flowchart does not arrive set in a different family from the prose. */
      fontFamily: getComputedStyle(document.body).fontFamily,
      securityLevel: "strict"
    });
    try {
      mermaid.run({ nodes: nodes });
    } catch (e) {
      /* A diagram with a syntax error should not take the page down with it. Mermaid
         writes its own error into the element; leaving that visible is more useful to
         whoever wrote the diagram than a silent blank. */
    }
  }

  render();

  /* Mermaid bakes the palette into the SVG it generates, so switching colour mode means
     rendering again from the source rather than restyling what is already there. */
  document.addEventListener("northlight:appearance", render);
})();
