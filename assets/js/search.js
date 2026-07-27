/* The ⌘K search modal.

   No Fuse.js. For a blog-sized index, matching a lowercased substring against title,
   tags and summary finds what people are looking for, and the library would cost more
   over the wire than the whole index does. If a site grows to the point where ranked
   fuzzy matching earns its keep, this is the file to replace.

   The index is fetched on first open, not on page load, so a reader who never
   searches never pays for it.

   Search is the one feature allowed to disappear without JavaScript, so the trigger
   ships hidden and is revealed here. */
(function () {
  var trigger = document.querySelector("[data-search-trigger]");
  var modal = document.getElementById("search-modal");
  if (!trigger || !modal) return;

  var input = modal.querySelector("[data-search-input]");
  var results = modal.querySelector("[data-search-results]");
  var endpoint = modal.getAttribute("data-search-index");
  var posts = null;
  var selected = 0;
  var lastFocused = null;

  trigger.hidden = false;

  function load() {
    if (posts) return Promise.resolve(posts);
    return fetch(endpoint)
      .then(function (r) { return r.json(); })
      .then(function (data) { posts = data; return posts; })
      .catch(function () { posts = []; return posts; });
  }

  function escape(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function render(term) {
    var q = term.trim().toLowerCase();
    var hits = !q
      ? posts.slice(0, 8)
      : posts.filter(function (p) {
          return (p.title + " " + (p.tags || []).join(" ") + " " + (p.summary || ""))
            .toLowerCase()
            .indexOf(q) !== -1;
        });

    selected = 0;

    if (!hits.length) {
      results.innerHTML = '<p class="search-empty">No posts match &ldquo;' + escape(term) + '&rdquo;.</p>';
      return;
    }

    results.innerHTML = hits
      .map(function (p, i) {
        return (
          '<a class="search-result' + (i === 0 ? " is-selected" : "") + '" href="' + escape(p.url) + '" role="option" aria-selected="' + (i === 0) + '">' +
          (p.thumb ? '<img class="search-thumb" src="' + escape(p.thumb) + '" alt="" loading="lazy">' : '<span class="search-thumb"></span>') +
          '<span class="search-text"><b>' + escape(p.title) + "</b>" +
          '<span class="search-meta">' + escape(p.date || "") + (p.readingTime ? " &middot; " + p.readingTime + " min" : "") + "</span></span></a>"
        );
      })
      .join("");
  }

  function items() {
    return Array.prototype.slice.call(results.querySelectorAll(".search-result"));
  }

  function select(next) {
    var list = items();
    if (!list.length) return;
    selected = (next + list.length) % list.length;
    list.forEach(function (el, i) {
      el.classList.toggle("is-selected", i === selected);
      el.setAttribute("aria-selected", i === selected);
    });
    list[selected].scrollIntoView({ block: "nearest" });
  }

  function open() {
    lastFocused = document.activeElement;
    modal.hidden = false;
    document.body.classList.add("is-modal-open");
    input.value = "";
    results.innerHTML = "";
    load().then(function () { render(""); });
    input.focus();
  }

  function close() {
    modal.hidden = true;
    document.body.classList.remove("is-modal-open");
    if (lastFocused && lastFocused.focus) lastFocused.focus();
  }

  trigger.addEventListener("click", open);

  modal.addEventListener("click", function (e) {
    if (e.target === modal) close();
  });

  modal.querySelectorAll("[data-search-close]").forEach(function (b) {
    b.addEventListener("click", close);
  });

  input.addEventListener("input", function () {
    if (posts) render(input.value);
  });

  document.addEventListener("keydown", function (e) {
    var key = e.key.toLowerCase();

    if ((e.metaKey || e.ctrlKey) && key === "k") {
      e.preventDefault();
      modal.hidden ? open() : close();
      return;
    }

    if (modal.hidden) {
      /* `/` is a search shortcut everywhere else; skip it while typing in a field. */
      if (key === "/" && !/^(input|textarea|select)$/i.test(document.activeElement.tagName)) {
        e.preventDefault();
        open();
      }
      return;
    }

    if (key === "escape") { e.preventDefault(); close(); return; }
    if (key === "arrowdown") { e.preventDefault(); select(selected + 1); return; }
    if (key === "arrowup") { e.preventDefault(); select(selected - 1); return; }
    if (key === "enter") {
      var list = items();
      if (list[selected]) { e.preventDefault(); window.location = list[selected].href; }
      return;
    }

    /* Keep focus in the dialog: tab cycles between the field and the results. */
    if (key === "tab") {
      e.preventDefault();
      select(selected + (e.shiftKey ? -1 : 1));
    }
  });
})();
