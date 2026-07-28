/* Click a prose image to see it at full size.
 *
 * Off unless `enableLightbox` is set. It is opt-in because the browser already offers
 * "open image in new tab", and a lightbox that traps focus badly is worse than no
 * lightbox at all — which is most of the reason this is careful rather than short.
 *
 * A <dialog> does the heavy lifting: the browser gives the modal semantics, the backdrop,
 * the focus trap and the Escape handler for free, and all four are the parts hand-rolled
 * lightboxes get wrong. Nothing here reimplements them.
 *
 * With JavaScript off nothing changes: images are images, and the page never referred to
 * a viewer that was not there.
 */
(function () {
  "use strict";

  var images = document.querySelectorAll(".prose img");
  if (!images.length || typeof HTMLDialogElement === "undefined") return;

  var dialog = null;
  var full = null;
  var caption = null;
  /* Whatever opened the dialog, so focus can go back there when it closes. <dialog>
     restores focus on its own only when the opener had it, and a mouse click does not
     focus a button in every engine — so after closing, focus landed on <body> and a
     keyboard user was returned to the top of the document. */
  var opener = null;

  function build() {
    dialog = document.createElement("dialog");
    dialog.className = "lightbox";
    /* Labelled by its own caption when there is one; the alt text is carried onto the
       enlarged image, so a screen reader gets the same description it had inline. */
    dialog.innerHTML =
      '<button class="lightbox-close" type="button" aria-label="' +
      window.Northlight.t("closeLightbox", "Close image") +
      '">&times;</button><img class="lightbox-image" alt=""><p class="lightbox-caption"></p>';
    full = dialog.querySelector(".lightbox-image");
    caption = dialog.querySelector(".lightbox-caption");
    document.body.appendChild(dialog);

    dialog.querySelector(".lightbox-close").addEventListener("click", function () {
      dialog.close();
    });

    /* Clicking the backdrop closes. The dialog element itself fills the viewport, so the
       test is whether the click landed outside the image rather than on it. */
    dialog.addEventListener("click", function (e) {
      if (e.target === dialog) dialog.close();
    });

    /* Covers every route out — the close button, the backdrop and Escape — because
       `close` fires for all three. */
    dialog.addEventListener("close", function () {
      if (opener) opener.focus();
    });
  }

  Array.prototype.forEach.call(images, function (img) {
    /* An image that is already a link has a destination the author chose; hijacking the
       click to show a bigger copy of it would take that away. */
    if (img.closest("a")) return;

    img.classList.add("is-zoomable");
    /* A real button, not a click handler on the image: the image is not focusable, and a
       control a keyboard cannot reach is not a control. Wrapping preserves the layout
       because the button is display:contents. */
    var trigger = document.createElement("button");
    trigger.type = "button";
    trigger.className = "lightbox-trigger";
    trigger.setAttribute("aria-label", window.Northlight.t("viewFullSize", "View full size"));
    img.parentNode.insertBefore(trigger, img);
    trigger.appendChild(img);

    trigger.addEventListener("click", function () {
      if (!dialog) build();
      opener = trigger;
      full.src = img.currentSrc || img.src;
      full.alt = img.alt || "";
      var fig = img.closest("figure");
      var cap = fig && fig.querySelector("figcaption");
      caption.textContent = cap ? cap.textContent : "";
      caption.hidden = !cap;
      dialog.showModal();
    });
  });
})();
