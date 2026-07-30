/* Upgrades the tab shortcode's markup into a real tablist.

   What the server sends is a sequence of headed <section> elements: every panel
   visible, one after another, each under its own h3. With scripting off that is
   what a reader gets, and it is a complete document rather than a broken control.
   Everything below is the enhancement.

   Built the other way round — shipping a tablist and using script to make it
   usable — a reader with no JavaScript gets a stack of unlabelled boxes. That is
   why the heading exists in the markup at all, and why it is only hidden here,
   after the button that replaces it has been created.

   ARIA follows the tabs pattern: roles, aria-selected, aria-controls, and roving
   tabindex so Tab enters the strip once and the arrow keys move within it. */
(function () {
  var sets = document.querySelectorAll("[data-tabs]");
  if (!sets.length) return;

  var uid = 0;

  /* Tabs sharing a group switch together, so a page documenting two steps of the
     same choice does not make the reader pick "npm" twice. */
  var groups = {};

  function activate(set, index, focus) {
    /* Tracked here rather than at the call sites, so a group sync updates the synced
       set's state too — otherwise its arrow keys start from the stale index. */
    set.current = index;
    set.tabs.forEach(function (tab, i) {
      var selected = i === index;
      tab.setAttribute("aria-selected", selected ? "true" : "false");
      /* Roving tabindex: only the selected tab is in the tab order, so Tab moves
         past the strip rather than through every tab in it. */
      tab.tabIndex = selected ? 0 : -1;
      set.panels[i].hidden = !selected;
    });
    if (focus) set.tabs[index].focus();

    var group = set.el.getAttribute("data-tab-group");
    if (!group || !groups[group]) return;
    var label = set.labels[index];
    groups[group].forEach(function (other) {
      if (other === set) return;
      var match = other.labels.indexOf(label);
      if (match !== -1 && match !== other.current) activate(other, match, false);
    });
  }

  Array.prototype.forEach.call(sets, function (el) {
    var panels = Array.prototype.slice.call(el.querySelectorAll(":scope > .tab-panel"));
    if (panels.length < 2) return;

    var list = document.createElement("div");
    list.className = "tab-list";
    list.setAttribute("role", "tablist");

    var set = { el: el, tabs: [], panels: panels, labels: [], current: 0 };

    panels.forEach(function (panel, i) {
      uid += 1;
      var label = panel.getAttribute("data-tab-label") || "Tab " + (i + 1);
      var panelId = "tabpanel-" + uid;
      var tabId = "tab-" + uid;

      var heading = panel.querySelector(".tab-heading");
      /* Hidden rather than removed: the tab button now carries the same text, and
         removing it would mean the enhancement destroys the fallback it was built
         on if anything later re-reads the markup. */
      if (heading) heading.hidden = true;

      panel.id = panelId;
      panel.setAttribute("role", "tabpanel");
      panel.setAttribute("aria-labelledby", tabId);
      panel.tabIndex = 0;
      panel.hidden = i !== 0;

      var tab = document.createElement("button");
      tab.type = "button";
      tab.className = "tab-button";
      tab.id = tabId;
      tab.setAttribute("role", "tab");
      tab.setAttribute("aria-controls", panelId);
      tab.setAttribute("aria-selected", i === 0 ? "true" : "false");
      tab.tabIndex = i === 0 ? 0 : -1;
      tab.textContent = label;

      tab.addEventListener("click", function () {
        activate(set, i, false);
      });

      list.appendChild(tab);
      set.tabs.push(tab);
      set.labels.push(label);
    });

    el.insertBefore(list, panels[0]);
    el.classList.add("is-enhanced");

    list.addEventListener("keydown", function (e) {
      var key = e.key;
      var last = set.tabs.length - 1;
      var next = null;

      if (key === "ArrowRight") next = set.current === last ? 0 : set.current + 1;
      else if (key === "ArrowLeft") next = set.current === 0 ? last : set.current - 1;
      else if (key === "Home") next = 0;
      else if (key === "End") next = last;
      else return;

      e.preventDefault();
      activate(set, next, true);
    });

    var group = el.getAttribute("data-tab-group");
    if (group) {
      if (!groups[group]) groups[group] = [];
      groups[group].push(set);
    }
  });
})();
