/* View and like counters, backed by Cloud Firestore.
 *
 * **This is the only feature in the theme that sends a reader's activity anywhere.** It is
 * off unless configured, and the configuration is a deliberate act: a site turning it on
 * is choosing to record that a page was read. Nothing else here phones out at all.
 *
 * No SDK. The Firebase JavaScript SDK is several hundred kilobytes to increment an
 * integer; Firestore has a REST API and `fetch` is built in, so this talks to it directly.
 * The whole module is smaller than the SDK's loader.
 *
 * The project id and API key are not secrets — they identify a project and are visible in
 * the page source of every site using them. What actually protects the data is Firestore
 * security rules, which are the site's to write; the docs page says so plainly.
 *
 * With JavaScript off, nothing renders. A counter that cannot count should not leave a
 * zero on the page pretending to be a number.
 */
(function () {
  "use strict";

  var root = document.querySelector("[data-counters]");
  if (!root || !window.fetch) return;

  var project = root.getAttribute("data-project");
  var key = root.getAttribute("data-api-key");
  var collection = root.getAttribute("data-collection") || "pages";
  var id = root.getAttribute("data-page-id");
  if (!project || !key || !id) return;

  var base =
    "https://firestore.googleapis.com/v1/projects/" + project +
    "/databases/(default)/documents/" + collection + "/" + encodeURIComponent(id);

  var viewsEl = root.querySelector("[data-views]");
  var likeBtn = root.querySelector("[data-like]");
  var likesEl = root.querySelector("[data-likes]");
  var LIKED = "northlight-liked-" + id;

  function read(doc, field) {
    var f = doc && doc.fields && doc.fields[field];
    return f ? parseInt(f.integerValue || "0", 10) : 0;
  }

  /* One transaction rather than read-then-write: two readers landing together would
     otherwise both read n and both write n+1, losing a count. `increment` is applied
     server-side, so concurrent hits add up. */
  function bump(field, by) {
    return fetch(
      "https://firestore.googleapis.com/v1/projects/" + project +
        "/databases/(default)/documents:commit?key=" + encodeURIComponent(key),
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          writes: [
            {
              transform: {
                document: "projects/" + project + "/databases/(default)/documents/" +
                  collection + "/" + id,
                fieldTransforms: [
                  { fieldPath: field, increment: { integerValue: String(by) } }
                ]
              }
            }
          ]
        })
      }
    );
  }

  function show() {
    fetch(base + "?key=" + encodeURIComponent(key))
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (doc) {
        if (!doc) return;
        if (viewsEl) viewsEl.textContent = read(doc, "views");
        if (likesEl) likesEl.textContent = read(doc, "likes");
        root.hidden = false;
      })
      .catch(function () {
        /* Offline, blocked, or rules refusing the read. The block stays hidden rather
           than showing a zero that is not a count. */
      });
  }

  if (root.hasAttribute("data-count-views")) {
    bump("views", 1).then(show).catch(show);
  } else {
    show();
  }

  if (likeBtn) {
    var liked = false;
    try { liked = localStorage.getItem(LIKED) === "1"; } catch (e) {}
    likeBtn.setAttribute("aria-pressed", liked ? "true" : "false");

    likeBtn.addEventListener("click", function () {
      var now = !(likeBtn.getAttribute("aria-pressed") === "true");
      likeBtn.setAttribute("aria-pressed", now ? "true" : "false");
      /* Optimistic: the number moves immediately and the write follows. A like that
         waits for a round trip feels broken. */
      if (likesEl) likesEl.textContent = Math.max(0, parseInt(likesEl.textContent || "0", 10) + (now ? 1 : -1));
      try { localStorage.setItem(LIKED, now ? "1" : "0"); } catch (e) {}
      bump("likes", now ? 1 : -1).catch(function () {});
    });
  }
})();
