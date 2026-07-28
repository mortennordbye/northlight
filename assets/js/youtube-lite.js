/* Turns the lite YouTube facade into an inline player, on click and not before.

   The server sends a poster image from this site, a play badge and a plain link
   to youtube.com. Nothing has contacted any Google host at that point, which is
   the whole purpose: an ordinary embed is a third-party request every reader
   pays on page view whether or not they ever press play.

   With scripting off the link stands and the video opens on YouTube. That is the
   honest fallback — the alternative is a play button that does nothing.

   youtube-nocookie.com is used for the iframe. It is still a third-party request,
   but only once the reader has asked for it, and it sets no tracking cookie for
   the visit itself. */
(function () {
  var facades = document.querySelectorAll(".yt-lite");
  if (!facades.length) return;

  Array.prototype.forEach.call(facades, function (box) {
    var link = box.querySelector(".yt-facade");
    var id = box.getAttribute("data-yt-id");
    if (!link || !id) return;

    link.addEventListener("click", function (e) {
      /* Let modified clicks through, so open-in-new-tab still does what the
         reader meant. */
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
      e.preventDefault();

      var frame = document.createElement("iframe");
      frame.className = "yt-frame";
      frame.src =
        "https://www.youtube-nocookie.com/embed/" +
        encodeURIComponent(id) +
        "?autoplay=1&rel=0";
      frame.title = link.textContent.trim();
      frame.allow =
        "accelerometer; encrypted-media; gyroscope; picture-in-picture";
      frame.allowFullscreen = true;
      frame.setAttribute("frameborder", "0");

      box.replaceChild(frame, link);
      frame.focus();
    });
  });
})();
