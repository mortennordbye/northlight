/* Reading-progress bar and the back-to-top button. Both are scroll-driven, so they
   share one passive listener and one rAF, rather than each installing their own.

   Both elements are inert without JavaScript: the bar has zero width and the button
   ships hidden. */
(function () {
  var bar = document.getElementById("reading-progress");
  var toTop = document.getElementById("back-to-top");
  if (!bar && !toTop) return;

  var ticking = false;

  function update() {
    ticking = false;
    var doc = document.documentElement;

    if (bar) {
      var scrollable = doc.scrollHeight - window.innerHeight;
      var ratio = scrollable > 0 ? window.scrollY / scrollable : 0;
      bar.style.transform = "scaleX(" + Math.min(1, Math.max(0, ratio)) + ")";
    }

    if (toTop) {
      toTop.classList.toggle("is-visible", window.scrollY > 600);
    }
  }

  function onScroll() {
    if (ticking) return;
    ticking = true;
    window.requestAnimationFrame(update);
  }

  if (toTop) {
    toTop.hidden = false;
    toTop.addEventListener("click", function () {
      /* Honour a reduced-motion preference here too: smooth-scrolling the length of a
         long article is exactly the kind of movement that setting exists to stop. */
      var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      window.scrollTo({ top: 0, behavior: reduce ? "auto" : "smooth" });
    });
  }

  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onScroll, { passive: true });
  update();
})();
