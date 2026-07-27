/* Appearance toggle.

   The button ships with a `hidden` attribute and this script removes it, so a reader
   with JavaScript disabled never sees a control that cannot do anything. The mode
   itself is already correct before this runs — appearance.js pinned it inline in
   <head> — so all this does is flip and persist it.

   Clearing the stored value is deliberate: when the chosen mode matches the system,
   the preference is removed rather than pinned, which hands control back to the
   operating system instead of freezing the page on whatever it happened to be. */
(function () {
  var root = document.documentElement;
  var buttons = document.querySelectorAll("[data-toggle-appearance]");
  if (!buttons.length) return;

  var media = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;

  function systemMode() {
    return media && media.matches ? "dark" : "light";
  }

  function currentMode() {
    return root.getAttribute("data-theme") || systemMode();
  }

  function label(mode) {
    return mode === "dark"
      ? t("switchToLightMode", "Switch to light mode")
      : t("switchToDarkMode", "Switch to dark mode");
  }

  function sync() {
    var mode = currentMode();
    buttons.forEach(function (b) {
      b.setAttribute("aria-label", label(mode));
      b.setAttribute("title", label(mode));
    });
    /* Anything that cannot be restyled by CSS alone — a third-party iframe, most
       obviously — needs telling. Broadcasting an event keeps this file from having to
       know who those listeners are. */
    document.dispatchEvent(
      new CustomEvent("northlight:appearance", { detail: { mode: mode } })
    );
  }

  buttons.forEach(function (b) {
    b.hidden = false;
    b.addEventListener("click", function () {
      var next = currentMode() === "dark" ? "light" : "dark";
      try {
        if (next === systemMode()) {
          localStorage.removeItem("northlight-appearance");
          root.removeAttribute("data-theme");
        } else {
          localStorage.setItem("northlight-appearance", next);
          root.setAttribute("data-theme", next);
        }
      } catch (e) {
        root.setAttribute("data-theme", next);
      }
      sync();
    });
  });

  /* Follow the system if it changes while the page is open and the reader has not
     pinned a mode of their own. */
  if (media && media.addEventListener) {
    media.addEventListener("change", sync);
  }

  sync();
})();
