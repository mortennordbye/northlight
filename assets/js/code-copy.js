/* Copy button on code blocks.

   The buttons are created here rather than in the template because Chroma's output
   is generated markup with no hook to inject into. With JavaScript off there is no
   button, and the code is still selectable — which is what people did before copy
   buttons existed. */
(function () {
  var blocks = document.querySelectorAll(".highlight");
  if (!blocks.length || !navigator.clipboard) return;

  blocks.forEach(function (block) {
    var code = block.querySelector("pre > code");
    if (!code) return;

    /* With line numbers Chroma emits two columns; the second holds the code. Copying
       the first would paste the line numbers along with it. */
    var cells = block.querySelectorAll(".lntd");
    if (cells.length === 2) code = cells[1].querySelector("pre > code");
    if (!code) return;

    var button = document.createElement("button");
    button.className = "copy-button";
    button.type = "button";
    button.setAttribute("aria-label", "Copy code to clipboard");
    button.innerHTML = '<span class="copy-label">Copy</span>';

    var reset;
    button.addEventListener("click", function () {
      navigator.clipboard.writeText(code.innerText).then(
        function () {
          button.classList.add("is-copied");
          button.querySelector(".copy-label").textContent = "Copied";
          button.setAttribute("aria-label", "Code copied to clipboard");
          clearTimeout(reset);
          reset = setTimeout(function () {
            button.classList.remove("is-copied");
            button.querySelector(".copy-label").textContent = "Copy";
            button.setAttribute("aria-label", "Copy code to clipboard");
          }, 1800);
        },
        function () {
          button.querySelector(".copy-label").textContent = "Failed";
        }
      );
    });

    /* A fence with a filename renders a bar; the button belongs in it rather than
       floating over the first line of code. */
    var bar = block.closest(".code-figure") && block.closest(".code-figure").querySelector(".code-bar");
    (bar || block).appendChild(button);
  });
})();
