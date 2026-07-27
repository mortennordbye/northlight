/* Keeps giscus in step with the reader's chosen appearance.

   giscus renders in a cross-origin iframe, so no amount of CSS on this page reaches it.
   It is loaded with data-theme="preferred_color_scheme", which follows the operating
   system — correct until the reader uses this site's own toggle, at which point a light
   OS leaves a bright comment box under a dark article. The only fix is to tell the
   iframe, which is what this does.

   No-ops when there is no giscus script on the page, like every other module in the
   bundle. */
(function () {
  var GISCUS_ORIGIN = "https://giscus.app";
  if (!document.querySelector('script[src^="' + GISCUS_ORIGIN + '"]')) return;

  var root = document.documentElement;
  var media = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;

  /* When the reader has not pinned a mode, hand the decision back to giscus rather
     than freezing it on whatever the system happened to be at load. */
  function desiredTheme() {
    var pinned = root.getAttribute("data-theme");
    return pinned === "dark" || pinned === "light" ? pinned : "preferred_color_scheme";
  }

  function send() {
    var frame = document.querySelector("iframe.giscus-frame");
    if (!frame || !frame.contentWindow) return;
    frame.contentWindow.postMessage(
      { giscus: { setConfig: { theme: desiredTheme() } } },
      GISCUS_ORIGIN
    );
  }

  /* giscus announces itself when the discussion has loaded. That message is the only
     reliable signal that the iframe exists and is ready to be configured — it is
     created asynchronously, so querying for it on DOMContentLoaded finds nothing. */
  window.addEventListener("message", function (event) {
    if (event.origin !== GISCUS_ORIGIN) return;
    if (!event.data || !event.data.giscus) return;
    send();
  });

  document.addEventListener("northlight:appearance", send);

  /* A system flip only matters while the reader has no pinned mode, and in that case
     giscus is already following the system itself. Re-sending is still correct and
     costs one postMessage. */
  if (media && media.addEventListener) media.addEventListener("change", send);
})();
