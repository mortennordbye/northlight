/* Zen mode: hide everything that is not the article.
 *
 * Shown only when `article.showZenMode` is on, and only on a page that has an article to
 * strip down to. What it hides is concrete — the header, the table of contents rail, the
 * footer and the article's own footer block — leaving the prose and nothing else.
 *
 * Escape leaves, because a mode with no obvious way out is a trap. The state is not
 * persisted: zen mode is something a reader turns on for one piece, and remembering it
 * across pages would mean arriving at a site with its navigation missing.
 */
(function () {
  "use strict";

  var btn = document.querySelector("[data-toggle-zen]");
  if (!btn || !document.querySelector(".article")) return;

  function set(on) {
    document.documentElement.toggleAttribute("data-zen", on);
    btn.setAttribute("aria-pressed", on ? "true" : "false");
  }

  btn.hidden = false;
  btn.addEventListener("click", function () {
    set(!document.documentElement.hasAttribute("data-zen"));
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && document.documentElement.hasAttribute("data-zen")) {
      set(false);
      btn.focus();
    }
  });
})();
