/* Click a prose image to open it, then zoom and pan around it.
 *
 * Off unless `enableLightbox` is set. It is opt-in because the browser already offers
 * "open image in new tab", and a lightbox that traps focus badly is worse than no
 * lightbox at all — which is most of the reason this is careful rather than short.
 *
 * A <dialog> does the heavy lifting: the browser gives the modal semantics, the backdrop,
 * the focus trap and the Escape handler for free, and all four are the parts hand-rolled
 * lightboxes get wrong. Nothing here reimplements them. The dialog's markup comes from
 * lightbox.html so its controls carry real icons and translated labels; this file only
 * fills it in and drives it.
 *
 * With JavaScript off nothing changes: images are images, the dialog never opens, and the
 * page never referred to a viewer that was not there.
 */
(function () {
  "use strict";

  var dialog = document.querySelector(".lightbox");
  var images = document.querySelectorAll(".prose img");
  if (!dialog || !images.length || typeof HTMLDialogElement === "undefined") return;

  var t = (window.Northlight || {}).t || function (key, fallback) { return fallback; };

  var stage = dialog.querySelector(".lightbox-stage");
  var full = dialog.querySelector(".lightbox-image");
  var caption = dialog.querySelector(".lightbox-caption");
  var zoomButtons = dialog.querySelectorAll("[data-lightbox-zoom]");

  var MIN = 1;
  var MAX = 6;
  var STEP = 1.5;      /* one button press or key press, as a multiplier */
  var DOUBLE = 2.5;    /* where a double-click lands, when starting from fit */

  var scale = 1;
  var x = 0;
  var y = 0;
  /* Whatever opened the dialog, so focus can go back there when it closes. <dialog>
     restores focus on its own only when the opener had it, and a mouse click does not
     focus a button in every engine — so after closing, focus landed on <body> and a
     keyboard user was returned to the top of the document. */
  var opener = null;

  var reduceMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* Live pointers, by id. One is a drag, two is a pinch. Pointer events rather than
     separate mouse and touch paths, so a trackpad, a mouse and a finger are one code
     path and a phone gets pinch-zoom without a second implementation. */
  var pointers = Object.create(null);
  var pinchStart = 0;
  var pinchScale = 1;
  var dragged = false;

  function clamp(value, low, high) {
    return Math.min(high, Math.max(low, value));
  }

  /* Keep the image overlapping the stage. Without this you can fling a zoomed image off
     screen and be left staring at an empty backdrop with no way back except Escape.
     The bound is half the overflow on each axis, which lets every edge reach the middle
     of the stage and no further. */
  function clampOffset() {
    var box = stage.getBoundingClientRect();
    var limitX = Math.max(0, (full.clientWidth * scale - box.width) / 2);
    var limitY = Math.max(0, (full.clientHeight * scale - box.height) / 2);
    x = clamp(x, -limitX, limitX);
    y = clamp(y, -limitY, limitY);
  }

  function apply(animate) {
    clampOffset();
    /* Transitions only on the discrete steps — a button, a key, a double-click. A wheel
       or a drag is already continuous, and easing it makes the image lag the finger. */
    full.style.transition = animate && !reduceMotion
      ? "transform var(--dur-transform) var(--ease)"
      : "none";
    full.style.transform = "translate3d(" + x + "px, " + y + "px, 0) scale(" + scale + ")";
    dialog.dataset.zoomed = scale > MIN ? "true" : "false";
    Array.prototype.forEach.call(zoomButtons, function (button) {
      var kind = button.dataset.lightboxZoom;
      button.disabled =
        (kind === "in" && scale >= MAX) ||
        (kind === "out" && scale <= MIN) ||
        (kind === "reset" && scale === MIN && x === 0 && y === 0);
    });
  }

  /* Zoom about a point rather than about the centre, so the thing under the cursor stays
     under the cursor. Without it, zooming into a detail means zoom, drag, overshoot,
     drag back. `origin` is in client coordinates; omit it to zoom about the middle. */
  function zoomTo(next, origin, animate) {
    next = clamp(next, MIN, MAX);
    if (next === scale) return;
    if (origin) {
      var box = stage.getBoundingClientRect();
      var ox = origin.clientX - (box.left + box.width / 2);
      var oy = origin.clientY - (box.top + box.height / 2);
      var ratio = next / scale;
      x = ox - (ox - x) * ratio;
      y = oy - (oy - y) * ratio;
    }
    scale = next;
    if (scale === MIN) { x = 0; y = 0; }
    apply(animate);
  }

  function reset(animate) {
    scale = MIN;
    x = 0;
    y = 0;
    apply(animate);
  }

  Array.prototype.forEach.call(zoomButtons, function (button) {
    button.addEventListener("click", function () {
      var kind = button.dataset.lightboxZoom;
      if (kind === "reset") reset(true);
      else zoomTo(kind === "in" ? scale * STEP : scale / STEP, null, true);
    });
  });

  dialog.querySelector(".lightbox-close").addEventListener("click", function () {
    dialog.close();
  });

  /* Clicking the backdrop closes. The stage fills the dialog, so the test is whether the
     click landed on the image itself. A click that ended a drag is not a click for this
     purpose, or panning to the edge of a zoomed image would dismiss it. */
  dialog.addEventListener("click", function (e) {
    if (dragged) return;
    if (e.target === dialog || e.target === stage) dialog.close();
  });

  full.addEventListener("dblclick", function (e) {
    if (scale > MIN) reset(true);
    else zoomTo(DOUBLE, e, true);
  });

  full.addEventListener("wheel", function (e) {
    e.preventDefault();
    /* A trackpad pinch arrives as a wheel event with ctrlKey set. Both it and a plain
       wheel mean the same thing here, so they differ only in how hard they pull. */
    var factor = Math.exp(-e.deltaY * (e.ctrlKey ? 0.01 : 0.0025));
    zoomTo(scale * factor, e, false);
  }, { passive: false });

  full.addEventListener("pointerdown", function (e) {
    pointers[e.pointerId] = e;
    dragged = false;
    if (Object.keys(pointers).length === 2) {
      pinchStart = spread();
      pinchScale = scale;
    } else if (scale > MIN) {
      /* Only capture when there is somewhere to pan to. At fit, the pointer belongs to
         the click that closes the dialog. */
      full.setPointerCapture(e.pointerId);
      dialog.dataset.dragging = "true";
    }
  });

  full.addEventListener("pointermove", function (e) {
    var previous = pointers[e.pointerId];
    if (!previous) return;
    var ids = Object.keys(pointers);
    pointers[e.pointerId] = e;

    if (ids.length === 2) {
      var now = spread();
      if (pinchStart) zoomTo(pinchScale * (now / pinchStart), midpoint(), false);
      dragged = true;
      return;
    }
    if (scale <= MIN) return;
    var dx = e.clientX - previous.clientX;
    var dy = e.clientY - previous.clientY;
    if (Math.abs(dx) > 2 || Math.abs(dy) > 2) dragged = true;
    x += dx;
    y += dy;
    apply(false);
  });

  function release(e) {
    delete pointers[e.pointerId];
    if (Object.keys(pointers).length < 2) pinchStart = 0;
    if (!Object.keys(pointers).length) dialog.dataset.dragging = "false";
  }
  full.addEventListener("pointerup", release);
  full.addEventListener("pointercancel", release);

  function each() {
    return Object.keys(pointers).map(function (id) { return pointers[id]; });
  }
  function spread() {
    var p = each();
    return Math.hypot(p[0].clientX - p[1].clientX, p[0].clientY - p[1].clientY);
  }
  function midpoint() {
    var p = each();
    return {
      clientX: (p[0].clientX + p[1].clientX) / 2,
      clientY: (p[0].clientY + p[1].clientY) / 2
    };
  }

  /* Escape is the browser's. These are the rest, and they are the reason a keyboard user
     gets the same viewer everyone else does rather than a picture they cannot move. */
  dialog.addEventListener("keydown", function (e) {
    var pan = scale > MIN ? 60 : 0;
    if (e.key === "+" || e.key === "=") zoomTo(scale * STEP, null, true);
    else if (e.key === "-" || e.key === "_") zoomTo(scale / STEP, null, true);
    else if (e.key === "0") reset(true);
    else if (e.key === "ArrowLeft" && pan) x += pan;
    else if (e.key === "ArrowRight" && pan) x -= pan;
    else if (e.key === "ArrowUp" && pan) y += pan;
    else if (e.key === "ArrowDown" && pan) y -= pan;
    else return;
    e.preventDefault();
    if (e.key.indexOf("Arrow") === 0) apply(true);
  });

  /* A resize changes what counts as off screen, so the offsets have to be re-clamped
     against the new stage or a zoomed image can end up stranded outside it. */
  window.addEventListener("resize", function () {
    if (dialog.open) apply(false);
  });

  /* Covers every route out — the close button, the backdrop and Escape — because
     `close` fires for all three. */
  dialog.addEventListener("close", function () {
    reset(false);
    if (opener) opener.focus();
  });

  Array.prototype.forEach.call(images, function (img) {
    /* An image that is already a link has a destination the author chose; hijacking the
       click to show a bigger copy of it would take that away. */
    if (img.closest("a")) return;

    /* A real button, not a click handler on the image: the image is not focusable, and a
       control a keyboard cannot reach is not a control. The button is display:block (a
       display:contents version was unfocusable — see .lightbox-trigger in
       interaction.css for the record) and carries the zoom cursor. */
    var trigger = document.createElement("button");
    trigger.type = "button";
    trigger.className = "lightbox-trigger";
    trigger.setAttribute("aria-label", t("viewFullSize", "View full size"));
    img.parentNode.insertBefore(trigger, img);
    trigger.appendChild(img);

    trigger.addEventListener("click", function () {
      opener = trigger;
      full.src = img.currentSrc || img.src;
      full.alt = img.alt || "";
      var fig = img.closest("figure");
      var cap = fig && fig.querySelector("figcaption");
      caption.textContent = cap ? cap.textContent : "";
      caption.hidden = !cap;
      reset(false);
      dialog.showModal();
    });
  });
})();
