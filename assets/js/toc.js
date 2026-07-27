/* Scroll-spy for the table of contents.

   Without this the TOC is still a working list of links — that is the whole point of
   rendering it as plain nested lists in the template. This only adds the highlight
   that tracks where you are.

   IntersectionObserver rather than a scroll handler: no work happens on frames where
   nothing crossed the threshold. The rootMargin pushes the trigger line to just below
   the sticky header and up from the bottom, so a heading becomes current when it
   reaches reading position rather than when it first peeks into view. */
(function () {
  var links = Array.prototype.slice.call(document.querySelectorAll(".toc a[href^='#']"));
  if (links.length < 2) return;

  if (!("IntersectionObserver" in window)) return;

  var byId = {};
  var headings = [];
  links.forEach(function (link) {
    var id = decodeURIComponent(link.getAttribute("href").slice(1));
    var heading = document.getElementById(id);
    if (!heading) return;
    byId[id] = link;
    headings.push(heading);
  });
  if (!headings.length) return;

  var current = null;
  function setCurrent(id) {
    if (id === current) return;
    current = id;
    links.forEach(function (l) {
      l.classList.remove("is-current");
      l.removeAttribute("aria-current");
    });
    var link = byId[id];
    if (link) {
      link.classList.add("is-current");
      link.setAttribute("aria-current", "true");
    }
  }

  var visible = new Set();
  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) visible.add(entry.target);
        else visible.delete(entry.target);
      });

      if (visible.size) {
        /* Topmost heading currently in the band wins. */
        var best = null;
        visible.forEach(function (h) {
          if (!best || h.getBoundingClientRect().top < best.getBoundingClientRect().top) best = h;
        });
        setCurrent(best.id);
        return;
      }

      /* Nothing in the band — between two headings, or past the last one. Fall back to
         the last heading scrolled above the trigger line, so the highlight never blanks
         out mid-section. */
      var above = null;
      headings.forEach(function (h) {
        if (h.getBoundingClientRect().top < 100) above = h;
      });
      if (above) setCurrent(above.id);
    },
    { rootMargin: "-84px 0px -70% 0px", threshold: 0 }
  );

  headings.forEach(function (h) {
    observer.observe(h);
  });
})();
