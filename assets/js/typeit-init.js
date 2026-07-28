/* The typewriter effect, written here rather than vendored.
 *
 * The obvious library for this is GPL-3.0 and this theme is MIT. Vendoring copyleft code
 * into a theme that people copy verbatim into their own repositories would force the
 * combined work to GPL — a licence change imposed on every user of the theme, from a
 * decorative animation. The effect is twenty lines; the licence conflict is not worth it.
 *
 * The element arrives with its final text already in it. This removes it and puts it back
 * one character at a time, which means the fallback is not a fallback at all: with no
 * JavaScript, or with reduced motion, the sentence is simply already there and complete.
 */
(function () {
  "use strict";

  var nodes = document.querySelectorAll("[data-typeit]");
  if (!nodes.length) return;

  /* Motion with no information in it, so a reader who asked for less loses nothing by
     keeping the static text. Checked before anything is removed. */
  if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  function type(el) {
    var text = el.textContent;
    var speed = parseInt(el.getAttribute("data-speed"), 10) || 60;
    var i = 0;
    el.textContent = "";
    /* aria-hidden while it runs: a screen reader announcing a partial sentence on every
       character is worse than useless. The finished text is announced once at the end. */
    el.setAttribute("aria-hidden", "true");

    (function step() {
      if (i >= text.length) {
        el.textContent = text;
        el.removeAttribute("aria-hidden");
        return;
      }
      el.textContent = text.slice(0, ++i);
      setTimeout(step, speed);
    })();
  }

  /* Only when it scrolls into view — typing that finished before the reader arrived is
     just text, and typing offscreen wastes timers. */
  if (!("IntersectionObserver" in window)) {
    Array.prototype.forEach.call(nodes, type);
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      io.unobserve(e.target);
      type(e.target);
    });
  }, { threshold: 0.6 });
  Array.prototype.forEach.call(nodes, function (el) { io.observe(el); });
})();
