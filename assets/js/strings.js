/* UI strings for the scripts.

   Most of the theme's text is translated by Hugo at build time, but a few strings only
   exist after a click: the copy button's label, the appearance toggle's tooltip. Those
   cannot be rendered into the markup because they change at runtime, so baseof.html
   serialises them into a JSON block and this reads it once.

   Every call passes an English fallback. A site that has not translated the theme, or
   one where the block is missing entirely, still gets working buttons rather than
   blank ones, so nothing here is load-bearing.

   This must be first in the bundle: the modules that follow call t() at definition
   time. */
var t = (function () {
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
