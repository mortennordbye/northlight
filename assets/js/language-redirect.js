/* Send a first-time visitor to the language their browser asks for.
 *
 * Off unless `languageRedirect.enabled` is set, and off for good reasons when it is not
 * wanted: a redirect the reader did not ask for is disorienting, it breaks a shared link
 * that was deliberately in one language, and it is invisible to anyone debugging it.
 *
 * Three guards, all of which exist because this feature is easy to get wrong:
 *
 *   1. It runs once. The choice is remembered, so a reader who navigates back to the
 *      original language is not bounced away again on the next click.
 *   2. It only fires on the home page by default. Deep links are usually shared
 *      deliberately, and rewriting one to another language loses what was shared.
 *   3. It never redirects to the page you are already on, which would loop.
 */
(function () {
  "use strict";

  var el = document.querySelector("[data-language-redirect]");
  if (!el) return;

  var available = (el.getAttribute("data-languages") || "").split(",").filter(Boolean);
  var current = el.getAttribute("data-current");
  var homeOnly = el.hasAttribute("data-home-only");
  var isHome = el.hasAttribute("data-is-home");
  var fallback = el.getAttribute("data-fallback") || "";
  var key = el.getAttribute("data-storage-key") || "northlight-language";

  if (homeOnly && !isHome) return;

  var stored = null;
  try { stored = localStorage.getItem(key); } catch (e) {}
  /* Already chosen, by a previous redirect or by using the switcher. Respect it. */
  if (stored) return;

  function pick() {
    var wanted = navigator.languages || [navigator.language];
    for (var i = 0; i < wanted.length; i++) {
      var tag = String(wanted[i]).toLowerCase();
      for (var j = 0; j < available.length; j++) {
        var lang = available[j].toLowerCase();
        /* `nb-NO` should match a site language of `nb`. Exact first, then the base tag. */
        if (tag === lang || tag.split("-")[0] === lang.split("-")[0]) return available[j];
      }
    }
    return fallback;
  }

  var target = pick();
  if (!target || target === current) return;

  var url = el.getAttribute("data-home-" + target);
  if (!url || url === location.pathname) return;

  try { localStorage.setItem(key, target); } catch (e) {}
  location.replace(url);
})();
