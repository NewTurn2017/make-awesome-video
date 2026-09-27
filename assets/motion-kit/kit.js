/*
 * make-awesome-video motion kit — seek-safe GSAP helpers for HyperFrames compositions.
 *
 * Copy kit.js + kit.css into <project>/assets/motion-kit/ and load them after gsap in <head>
 * (a stylesheet link for kit.css, a script tag with src for kit.js).
 * NOTE: never write a literal closing script tag anywhere in this file (not even in comments):
 * HyperFrames inlines scripts at compile time and that string would end the tag early.
 * Then inside the composition script:
 *   const tl = gsap.timeline({ paused: true });
 *   const K = MAK(tl);
 *   ... K.up(".line", 0.4) ...
 *   window.__timelines["main"] = tl;
 *
 * Every helper only adds tweens/sets to the ONE paused timeline you pass in.
 * No clocks, no Math.random (use K.rand(seed)), finite repeats only.
 */
(function (global) {
  function MAK(tl) {
    const K = {};

    // ---------- deterministic randomness ----------
    K.rand = function (seed) {
      let s = seed >>> 0 || 1;
      return function () {
        s = (s * 1664525 + 1013904223) >>> 0;
        return s / 4294967296;
      };
    };

    // ---------- text splitting (run at build time, before tweens) ----------
    // Wraps each character of every matched element in <span class="mak-ch">.
    // Returns the flat array of char spans (document order).
    K.splitChars = function (sel) {
      const out = [];
      document.querySelectorAll(sel).forEach((el) => {
        const text = el.textContent;
        el.textContent = "";
        for (const ch of text) {
          const s = document.createElement("span");
          s.className = "mak-ch";
          s.textContent = ch === " " ? " " : ch;
          el.appendChild(s);
          out.push(s);
        }
      });
      return out;
    };

    // ---------- layout ----------
    // Scale font-size so each matched element's rendered width equals targetPx (motion-design type fills
    // the frame: 85–95% of width). Run at build time after fonts load and BEFORE measuring char positions.
    // The element must shrink-wrap its text (absolute/inline-block/width:max-content), not a full-width block.
    K.fitWidth = (sel, targetPx) => {
      document.querySelectorAll(sel).forEach((el) => {
        const fs = parseFloat(getComputedStyle(el).fontSize);
        const w = el.getBoundingClientRect().width || el.scrollWidth;
        if (w > 0) el.style.fontSize = (fs * targetPx) / w + "px";
      });
    };

    // ---------- entrances ----------
    K.up = (sel, at, o = {}) =>
      tl.fromTo(sel, { opacity: 0, y: o.y ?? 50 }, { opacity: 1, y: 0, duration: o.d ?? 0.7, ease: o.ease ?? "power3.out", stagger: o.st ?? 0.12 }, at);

    K.pop = (sel, at, o = {}) =>
      tl.fromTo(sel, { opacity: 0, scale: o.from ?? 0.8, y: o.y ?? 20 }, { opacity: 1, scale: 1, y: 0, duration: o.d ?? 0.6, ease: o.ease ?? "back.out(1.7)", stagger: o.st ?? 0.15 }, at);

    // Masked rise: parent needs class "mak-mask" (overflow hidden). Classic kinetic-type line reveal.
    K.maskRise = (sel, at, o = {}) =>
      tl.fromTo(sel, { yPercent: 110 }, { yPercent: 0, duration: o.d ?? 0.6, ease: o.ease ?? "expo.out", stagger: o.st ?? 0.06 }, at);

    // Type-on: chars (from K.splitChars) appear one by one. cps = chars per second.
    K.typeOn = (chars, at, o = {}) => {
      const step = 1 / (o.cps ?? 14);
      chars.forEach((c, i) => tl.fromTo(c, { opacity: 0 }, { opacity: 1, duration: 0.001, immediateRender: true }, at + i * step));
      return at + chars.length * step; // returns end time
    };

    // Slam: big → settle with a short 3-frame shake.
    K.slam = (sel, at, o = {}) => {
      tl.fromTo(sel, { opacity: 0, scale: o.from ?? 1.6 }, { opacity: 1, scale: 1, duration: o.d ?? 0.28, ease: "power4.in" }, at);
      const f = 1 / 30;
      tl.to(sel, { x: 6, duration: f, ease: "none" }, at + (o.d ?? 0.28));
      tl.to(sel, { x: -4, duration: f, ease: "none" }, at + (o.d ?? 0.28) + f);
      tl.to(sel, { x: 0, duration: f, ease: "none" }, at + (o.d ?? 0.28) + 2 * f);
    };

    // ---------- variable type ----------
    // Element must use: font-variation-settings: "wght" var(--wght), "wdth" var(--wdth);
    K.axis = (sel, at, from, to, o = {}) =>
      tl.fromTo(sel, from, { ...to, duration: o.d ?? 0.6, ease: o.ease ?? "power3.inOut", stagger: o.st ?? 0 }, at);

    // ---------- camera ----------
    K.pushIn = (sel, at, dur, o = {}) =>
      tl.fromTo(sel, { scale: o.from ?? 1 }, { scale: o.to ?? 1.08, duration: dur, ease: o.ease ?? "none" }, at);

    // Whip: element leaves with capped horizontal smear (use on a wrapper).
    K.whipOut = (sel, at, o = {}) =>
      tl.to(sel, { xPercent: o.dir === "left" ? -120 : 120, filter: "blur(18px)", duration: o.d ?? 0.28, ease: "power4.in" }, at);
    K.whipIn = (sel, at, o = {}) =>
      tl.fromTo(sel, { xPercent: o.dir === "left" ? 120 : -120, filter: "blur(18px)" }, { xPercent: 0, filter: "blur(0px)", duration: o.d ?? 0.32, ease: "power4.out" }, at);

    // ---------- panels & wipes ----------
    // Solid panel slides across (element: absolute full-bleed div with class mak-panel).
    K.panelWipe = (sel, at, o = {}) => {
      const from = { left: { xPercent: -100 }, right: { xPercent: 100 }, up: { yPercent: 100 }, down: { yPercent: -100 } }[o.from ?? "right"];
      const to = { xPercent: 0, yPercent: 0 };
      return tl.fromTo(sel, from, { ...to, duration: o.d ?? 0.45, ease: o.ease ?? "expo.inOut" }, at);
    };

    // Brand ring iris wipe. Call K.ringWipe.install({accent, fill, symbol}) once (creates #mak-wipe
    // on top of the root), then K.ringWipe.cover(T) / reveal(T) around each cut at time T.
    // Hidden while idle so `hyperframes check` does not report occlusion.
    K.ringWipe = {
      R: 1320,
      install(o = {}) {
        const root = document.querySelector("[data-composition-id]");
        const w = document.createElement("div");
        w.id = "mak-wipe";
        w.style.setProperty("--mak-accent", o.accent ?? "#00ffd7");
        w.style.setProperty("--mak-fill", o.fill ?? "#4c7dff");
        w.innerHTML = '<div class="w-a"></div><div class="w-f"></div>' + (o.symbol ? `<img class="w-sym" src="${o.symbol}" alt="" />` : "");
        root.appendChild(w);
        this.R = o.radius ?? 1320; // must exceed half the frame diagonal (1102px at 1920x1080)
        // Initial state lives inline (NOT a tl.set at 0): GSAP reverts zero-time sets when a render seeks
        // back to t=0, so the element's own style must already be the t=0 state.
        w.style.visibility = "hidden";
      },
      cover(T, d = 0.5) {
        const R = this.R;
        tl.set("#mak-wipe", { "--in": "0px", "--bin": "0px", "--out": "0px", "--bout": "0px", visibility: "visible" }, T - d - 0.02);
        tl.to("#mak-wipe", { "--out": R + "px", duration: d, ease: "power2.in" }, T - d);
        tl.to("#mak-wipe", { "--bout": R - 70 + "px", duration: d * 0.88, ease: "power2.in" }, T - d * 0.88);
        if (document.querySelector("#mak-wipe .w-sym"))
          tl.fromTo("#mak-wipe .w-sym", { opacity: 0, scale: 0.6 }, { opacity: 1, scale: 1, duration: 0.2, ease: "back.out(2)" }, T - 0.2);
      },
      reveal(T, d = 0.6) {
        const R = this.R;
        if (document.querySelector("#mak-wipe .w-sym"))
          tl.to("#mak-wipe .w-sym", { opacity: 0, scale: 1.4, duration: 0.2, ease: "power2.in" }, T + 0.02);
        tl.to("#mak-wipe", { "--bin": R + "px", duration: d, ease: "power3.out" }, T + 0.05);
        tl.to("#mak-wipe", { "--in": R + "px", duration: d, ease: "power3.out" }, T + 0.12);
        tl.set("#mak-wipe", { visibility: "hidden" }, T + d + 0.15);
      },
      // Start the piece fully covered (loop seam): pair with cover(duration - 0.1) at the end.
      coveredAt0() {
        const R = this.R, w = document.getElementById("mak-wipe");
        w.style.setProperty("--in", "0px"); w.style.setProperty("--bin", "0px");
        w.style.setProperty("--out", R + "px"); w.style.setProperty("--bout", R - 70 + "px");
        w.style.visibility = "visible";
        const sym = w.querySelector(".w-sym");
        if (sym) { sym.style.opacity = "1"; }
      },
    };

    // ---------- grids ----------
    // Word wall / checkerboard: fills `container` with rows×cols cells containing `word`,
    // alternating inverted cells. Returns the cells (row-major).
    K.wordWall = (container, word, rows, cols, o = {}) => {
      const el = typeof container === "string" ? document.querySelector(container) : container;
      el.classList.add("mak-wall");
      el.style.gridTemplateColumns = `repeat(${cols}, 1fr)`;
      el.style.gridTemplateRows = `repeat(${rows}, 1fr)`;
      const cells = [];
      for (let r = 0; r < rows; r++)
        for (let c = 0; c < cols; c++) {
          const d = document.createElement("div");
          d.className = "mak-cell" + ((r + c) % 2 === (o.invertOdd ? 1 : 0) ? " inv" : "");
          d.textContent = word;
          el.appendChild(d);
          cells.push(d);
        }
      return cells;
    };

    // Stagger from center of a grid (cells from K.wordWall or any array laid out row-major).
    K.gridStagger = (cells, cols, at, vars, o = {}) =>
      tl.fromTo(cells, vars.from, { ...vars.to, duration: o.d ?? 0.4, ease: o.ease ?? "power3.out", stagger: { each: o.each ?? 0.03, grid: [Math.ceil(cells.length / cols), cols], from: o.fromWhere ?? "center" } }, at);

    // ---------- 3D depth text (layered extrusion, no WebGL) ----------
    // Builds `layers` copies behind .mak-depth > .front. Colors: front, back (rgba base), stripe optional.
    K.depthText = (sel, o = {}) => {
      const host = document.querySelector(sel);
      const text = host.textContent;
      host.textContent = "";
      host.classList.add("mak-depth");
      const n = o.layers ?? 18;
      const layers = [];
      for (let i = n - 1; i >= 0; i--) {
        const l = document.createElement("div");
        l.className = "mak-depth-l" + (i === 0 ? " front" : "");
        l.textContent = text;
        l.style.setProperty("--i", i);
        l.setAttribute("data-layout-allow-overlap", ""); // stacked on purpose; keeps `check` quiet
        if (i > 0) l.style.color = o.back ?? `rgba(0,0,0,${Math.max(0.9 - i * 0.03, 0.35)})`;
        host.appendChild(l);
        layers.push(l);
      }
      return layers; // back-to-front
    };
    // Grow extrusion depth (offset per layer via --dx/--dy on the host).
    K.extrude = (sel, at, o = {}) =>
      tl.fromTo(sel, { "--dx": "0px", "--dy": "0px" }, { "--dx": (o.dx ?? 3) + "px", "--dy": (o.dy ?? 3) + "px", duration: o.d ?? 0.8, ease: o.ease ?? "power3.out" }, at);

    // ---------- deterministic noise field (fluid / domain-warp look, no WebGL) ----------
    // canvas: a <canvas> (e.g. 480x270, CSS-stretched to full frame). Paints a domain-warped value-noise
    // contour pattern in two colors with grain. Pure function of timeline time: seek-safe in any order.
    // o: { a:[r,g,b] base, b:[r,g,b] band, scale:110 (px per noise unit; bigger = softer blobs),
    //      band:0.07 (band width), grain:0.3, speed:1, seed:99 }
    K.noiseField = (canvas, at, dur, o = {}) => {
      const W = canvas.width, H = canvas.height, ctx = canvas.getContext("2d"), img = ctx.createImageData(W, H);
      const P = new Uint8Array(512);
      { const r = K.rand(o.seed ?? 99), p = [...Array(256).keys()];
        for (let i = 255; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [p[i], p[j]] = [p[j], p[i]]; }
        for (let i = 0; i < 512; i++) P[i] = p[i & 255]; }
      const fade = (t) => t * t * (3 - 2 * t), hsh = (x, y) => P[(P[x & 255] + y) & 511] / 255;
      const vn = (x, y) => { const xi = Math.floor(x), yi = Math.floor(y), u = fade(x - xi), v = fade(y - yi);
        const a = hsh(xi, yi), b = hsh(xi + 1, yi), c = hsh(xi, yi + 1), d = hsh(xi + 1, yi + 1);
        return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v; };
      const fbm = (x, y) => vn(x, y) * 0.55 + vn(x * 2.03, y * 2.03) * 0.3 + vn(x * 4.1, y * 4.1) * 0.15;
      const A = o.a ?? [254, 74, 29], B = o.b ?? [240, 236, 230], sc = o.scale ?? 110, bw = o.band ?? 0.07, gr = o.grain ?? 0.3, sp = o.speed ?? 1;
      const proxy = { t: 0 };
      const paint = () => {
        const t = proxy.t * sp;
        for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
          const nx = x / sc, ny = y / sc;
          const qx = fbm(nx + t * 0.6, ny), qy = fbm(nx + 5.2, ny + 1.3 - t * 0.4);
          const v = fbm(nx + 3 * qx, ny + 3 * qy);
          const band = Math.abs(((v * 7 + t * 1.2) % 1) - 0.5);
          const on = band < bw + hsh(x * 7 + ((t * 30) | 0), y * 3) * 0.35 * gr;
          const k = (y * W + x) * 4, c = on ? B : A;
          img.data[k] = c[0]; img.data[k + 1] = c[1]; img.data[k + 2] = c[2]; img.data[k + 3] = 255;
        }
        ctx.putImageData(img, 0, 0);
      };
      return tl.fromTo(proxy, { t: 0 }, { t: 1, duration: dur, ease: "none", onUpdate: paint }, at);
    };

    // ---------- beats ----------
    // beats: array of seconds (from beats/<audio>.json → .beats.map(b => b.time)).
    K.snap = (t, beats) => beats.reduce((best, b) => (Math.abs(b - t) < Math.abs(best - t) ? b : best), beats[0] ?? t);
    // Strong beats only (strength >= min), useful for choosing cut points.
    K.strong = (beatObjs, min = 0.6) => beatObjs.filter((b) => b.strength >= min).map((b) => b.time);

    return K;
  }
  global.MAK = MAK;
})(window);
