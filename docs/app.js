(function () {
  var cfg = window.DAILY_CASH || {};
  var reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Download buttons: linked when the APK link is set, visibly disabled when it is not.
  var buttons = document.querySelectorAll("[data-download]");
  buttons.forEach(function (a) {
    var label = a.querySelector("[data-label]");
    if (cfg.apkUrl) {
      var url = cfg.apkUrl;
      if (url.indexOf("supabase.co") !== -1 && url.indexOf("?") === -1) url += "?download=daily-cash.apk";
      a.setAttribute("href", url);
      a.removeAttribute("aria-disabled");
      a.removeAttribute("tabindex");
    } else {
      a.setAttribute("aria-disabled", "true");
      a.setAttribute("tabindex", "-1");
      if (label) label.textContent = label.getAttribute("data-soon");
    }
  });

  // Version and checksum, only when provided.
  var metaRows = document.querySelectorAll("[data-meta]");
  metaRows.forEach(function (row) {
    var show = false;
    var v = row.querySelector("[data-version]");
    var s = row.querySelector("[data-sha]");
    if (v && cfg.version) { v.hidden = false; v.querySelector("span").textContent = cfg.version; show = true; }
    if (s && cfg.sha256) { s.hidden = false; s.querySelector("span").textContent = cfg.sha256; show = true; }
    if (show) row.classList.add("show");
  });

  var year = document.querySelector("[data-year]");
  if (year) year.textContent = String(new Date().getFullYear());

  if (!("IntersectionObserver" in window)) {
    document.querySelectorAll(".reveal").forEach(function (el) { el.classList.add("in"); });
    document.querySelectorAll(".tagline .w").forEach(function (el) { el.classList.add("on"); });
    return;
  }

  // Sections rise and fade in once.
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); }
    });
  }, { threshold: 0.12 });
  document.querySelectorAll(".reveal").forEach(function (el) { io.observe(el); });

  // Tagline: split into words, then switch each word on as it crosses the trigger line.
  var t = document.querySelector(".tagline .t");
  if (t) {
    var lines = t.getAttribute("data-text").split("|");
    t.textContent = "";
    var words = [];
    lines.forEach(function (line, li) {
      line.trim().split(/\s+/).forEach(function (w, i, arr) {
        var s = document.createElement("span");
        s.className = "w";
        s.textContent = w;
        t.appendChild(s);
        words.push(s);
        if (!(li === lines.length - 1 && i === arr.length - 1)) t.appendChild(document.createTextNode(" "));
      });
    });
    if (reduced) {
      words.forEach(function (w) { w.classList.add("on"); });
    } else {
      var wo = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { e.target.classList.add("on"); wo.unobserve(e.target); }
        });
      }, { rootMargin: "0px 0px -35% 0px", threshold: 0 });
      words.forEach(function (w) { wo.observe(w); });
    }
  }
})();
