/* The underline-links toggle.
 *
 * Off by default and shown only when `enableA11y` is set, because the theme's own link
 * styling is a deliberate design decision and this overrides it site-wide.
 *
 * What it does is exactly what it says: underlines every link. That is WCAG 1.4.1 — a link
 * distinguished from its surrounding text by colour alone is invisible to a reader who
 * cannot separate those two colours. The theme's prose links already carry a faint rule,
 * but navigation, cards and footers do not, and this puts one under all of them.
 *
 * It is deliberately not a vague "accessibility mode". A control whose effect a reader
 * cannot predict is not an accessibility feature.
 *
 * The button ships `hidden` and is revealed here, so a reader with no JavaScript is not
 * shown a control that cannot work.
 */
(function () {
  "use strict";

  var KEY = "northlight-underline-links";
  var btn = document.querySelector("[data-toggle-underline]");
  if (!btn) return;

  function apply(on) {
    document.documentElement.toggleAttribute("data-underline-links", on);
    btn.setAttribute("aria-pressed", on ? "true" : "false");
  }

  var stored = null;
  try {
    stored = localStorage.getItem(KEY);
  } catch (e) {
    /* Private mode, or storage disabled. The control still works for this page view;
       it just will not be remembered, which is better than not working at all. */
  }

  apply(stored === "on");
  btn.hidden = false;

  btn.addEventListener("click", function () {
    var on = !document.documentElement.hasAttribute("data-underline-links");
    apply(on);
    try {
      localStorage.setItem(KEY, on ? "on" : "off");
    } catch (e) {
      /* As above. */
    }
  });
})();
