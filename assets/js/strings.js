/* UI strings for the scripts.

   Most of the theme's text is translated by Hugo at build time, but a few strings only
   exist after a click: the copy button's label, the appearance toggle's tooltip. Those
   cannot be rendered into the markup because they change at runtime, so baseof.html
   serialises them into a JSON block and this reads it once.

   Exposed as window.Northlight.t rather than a bare global. The bundle is concatenated,
   so a top-level `var t` would put a single-letter name on window for every site using
   the theme, where anything a site author loads could collide with it. One namespaced
   object is the smallest footprint that still lets the modules share a lookup.

   Every call passes an English fallback, so a site that has not translated the theme, a
   missing block, or a malformed one all still produce working buttons.

   This must be first in the bundle: the modules after it read window.Northlight.t when
   they run. */
window.Northlight = window.Northlight || {};

window.Northlight.t = (function () {
  var strings = {};
  try {
    var el = document.getElementById("northlight-strings");
    if (el) strings = JSON.parse(el.textContent) || {};
  } catch (e) {
    /* A malformed block is not worth breaking the page over. Fallbacks cover it. */
  }
  return function (key, fallback) {
    return Object.prototype.hasOwnProperty.call(strings, key) ? strings[key] : fallback;
  };
})();
