// Drives claude-replay iframes from reveal.js fragments.
//
// The claude-replay player listens for hash changes on its own window:
//   #turn=N  -> animate to turn N
//   #turn=Nr -> jump to turn N instantly
//   #turn=0  -> splash screen
//
// Fragment markers (.cr-step[data-turn]) on a slide advance the replay iframe
// on that same slide when shown, and step it back when hidden.

(function () {
  "use strict";

  function stepTurn(span) {
    var t = span.getAttribute("data-turn") || span.getAttribute("turn");
    return t === null ? null : parseInt(t, 10);
  }

  function findIframe(slide) {
    return slide ? slide.querySelector("iframe[data-claude-replay]") : null;
  }

  function setTurn(iframe, turn, instant) {
    if (!iframe) return;
    var hash = "#turn=" + turn + (instant ? "r" : "");
    // reveal.js may not have lazy-loaded the iframe yet (data-src -> src),
    // or the player may still be loading. Stash the target and apply on load.
    var loaded = iframe.getAttribute("src") && iframe.dataset.crLoaded === "1";
    if (!loaded) {
      iframe.dataset.pendingTurn = String(turn) + (instant ? "r" : "");
      return;
    }
    try {
      iframe.contentWindow.location.hash = hash;
    } catch (e) {
      // cross-origin fallback: replace src hash (reloads only if origin differs)
      iframe.src = iframe.src.split("#")[0] + hash;
    }
  }

  function watchLoad(iframe) {
    if (iframe.dataset.crWatched === "1") return;
    iframe.dataset.crWatched = "1";
    iframe.addEventListener("load", function () {
      iframe.dataset.crLoaded = "1";
      var pending = iframe.dataset.pendingTurn;
      if (pending !== undefined && pending !== "") {
        delete iframe.dataset.pendingTurn;
        var instant = /r$/.test(pending);
        setTurn(iframe, parseInt(pending, 10), instant);
      }
    });
  }

  // Turn matching the slide's currently visible fragments (or the initial turn).
  function currentTurnForSlide(slide, iframe) {
    var turn = parseInt(iframe.getAttribute("data-initial-turn") || "0", 10);
    var steps = slide.querySelectorAll(".cr-step");
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].classList.contains("visible")) {
        var t = stepTurn(steps[i]);
        if (t !== null) turn = t;
      }
    }
    return turn;
  }

  function init(Reveal) {
    document
      .querySelectorAll("iframe[data-claude-replay]")
      .forEach(watchLoad);

    Reveal.on("fragmentshown", function (event) {
      var frag = event.fragment;
      if (!frag || !frag.classList.contains("cr-step")) return;
      var slide = frag.closest("section");
      var iframe = findIframe(slide);
      var turn = stepTurn(frag);
      if (iframe && turn !== null) setTurn(iframe, turn, false);
    });

    Reveal.on("fragmenthidden", function (event) {
      var frag = event.fragment;
      if (!frag || !frag.classList.contains("cr-step")) return;
      var slide = frag.closest("section");
      var iframe = findIframe(slide);
      if (!iframe) return;
      // fragmenthidden fires after the class is removed, so recomputing the
      // visible-fragment state yields the previous step's turn.
      setTurn(iframe, currentTurnForSlide(slide, iframe), false);
    });

    Reveal.on("slidechanged", function (event) {
      var slide = event.currentSlide;
      var iframe = findIframe(slide);
      if (!iframe) return;
      watchLoad(iframe);
      // Restore state instantly when jumping into a slide mid-deck.
      setTurn(iframe, currentTurnForSlide(slide, iframe), true);
    });
  }

  function whenRevealReady() {
    if (window.Reveal && typeof window.Reveal.on === "function") {
      if (window.Reveal.isReady && window.Reveal.isReady()) {
        init(window.Reveal);
      } else {
        window.Reveal.on("ready", function () {
          init(window.Reveal);
        });
      }
    } else {
      setTimeout(whenRevealReady, 50);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", whenRevealReady);
  } else {
    whenRevealReady();
  }
})();
