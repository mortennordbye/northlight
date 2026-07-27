/* Sets the colour mode before first paint. Inlined into <head> ahead of the
   stylesheet — as an external file it would load too late and every page would
   flash the wrong mode.

   It only ever *pins* a mode. When the reader has expressed no preference and the
   theme is set to follow the system, it deliberately sets nothing at all: tokens.css
   declares `color-scheme: light dark` on :root, so CSS follows the operating system
   on its own, and keeps following it if the system flips while the page is open.
   That is also why the page still works with JavaScript disabled. */
(function () {
  var root = document.documentElement;
  var stored = null;

  try {
    stored = localStorage.getItem("northlight-appearance");
  } catch (e) {
    /* Storage can throw in private mode or with cookies blocked. Not fatal:
       fall through to the configured behaviour. */
  }

  if (stored === "light" || stored === "dark") {
    root.setAttribute("data-theme", stored);
    return;
  }

  if (root.getAttribute("data-appearance-auto") !== "true") {
    root.setAttribute(
      "data-theme",
      root.getAttribute("data-appearance-default") === "dark" ? "dark" : "light"
    );
  }
})();
