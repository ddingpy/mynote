---
title: "Building an Apple-style Scroll Experience (Like the MacBook Neo Page)"
date: 2026-03-05 10:19:00 +0900
tags: [css, frontend, scroll-animation, ux, guide]
---

Apple product pages are famous for “scroll storytelling”: as you scroll, content reveals, images subtly transform, sections pin in place, and sometimes a product animation “scrubs” forward/backward with the scrollbar (e.g., laptops unfolding, phones rotating). ([CSS-Tricks][1])

This document explains the patterns behind that effect and gives copy/paste starting code (vanilla HTML/CSS/JS), plus modern native CSS options and a GSAP alternative.

---

## 0) What you’re trying to recreate (the core patterns)

Apple-style pages are usually a combination of these patterns:

1. **Scroll-triggered reveals**
   Elements fade/slide in when they enter the viewport (play once, or reverse on exit).

2. **Pinned (“sticky”) scenes**
   A section stays fixed for a while as you scroll, while its internal content changes.

3. **Scroll-driven (“scrubbed”) animation**
   Scroll position directly controls animation progress (scroll up = animation rewinds). This is different from “triggered” animations that just start on scroll and finish on their own. ([Chrome for Developers][2])

4. **Parallax / depth cues**
   Backgrounds and foregrounds move at different rates.

5. **High-fidelity product motion** (optional)
   Often done using **image sequences** or **video frame control**. Apple even uses an internal technique (“Flow”) to compress/stream image sequences efficiently. You don’t need Flow, but you *do* need to plan assets carefully. ([Graydon Pleasants: Engineering Portfolio][3])

---

## 1) Choose your implementation approach

You can build this three ways. Pick based on browser support needs and how complex your animations are.

### Option A — Modern native CSS (best performance, newest APIs)

Use **CSS Scroll-Driven Animations** (`animation-timeline`, `scroll()`, `view()`, `animation-range`, etc.).
Pros: can run smoother because it avoids heavy main-thread scroll handlers. ([Chrome for Developers][2])
Cons: **limited availability** across some widely-used browsers. ([MDN Web Docs][4])

### Option B — Vanilla JS (most control, good compatibility)

Use:

* `position: sticky` for pinned scenes
* `IntersectionObserver` for reveals (recommended vs raw scroll events) ([MDN Web Docs][5])
* `requestAnimationFrame` to throttle updates cleanly ([MDN Web Docs][6])

### Option C — GSAP ScrollTrigger (fastest to build, widely used)

GSAP ScrollTrigger gives you **pin**, **scrub**, **snap**, and robust scroll timelines with less custom math. ([gsap.com][7])

---

## 2) A practical “Apple-like” page architecture

Think in **Scenes**:

* Each scene has a **scroll length** (often `150vh`–`400vh`)
* Inside is a **sticky stage** (`height: 100vh; position: sticky; top: 0`)
* You compute a scene **progress** value `p` from `0 → 1`
* You map `p` to transforms, opacity, and text states

### Typical layout

```txt
Scene (height: 250vh)
 └─ Sticky stage (100vh pinned)
     ├─ Product visual (image/canvas/video)
     └─ Copy that changes (step 1 → step 2 → step 3)
```

---

## 3) Copy/paste starter (Vanilla HTML/CSS/JS)

This starter gives you:

* Reveal-on-scroll blocks
* A pinned sticky scene
* Scroll progress → CSS variable (`--p`)
* A text “stepper” that changes copy as you scroll

### 3.1 `index.html`

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Apple‑style Scroll Demo</title>
  <link rel="stylesheet" href="styles.css" />
</head>
<body>

  <!-- Optional: reading progress bar -->
  <div class="progress"></div>

  <header class="hero">
    <h1>Scroll‑Driven Product Story</h1>
    <p class="sub">Pinned scenes, reveals, and scroll‑scrubbed transforms.</p>
  </header>

  <!-- REVEAL SECTION -->
  <section class="content">
    <div class="card reveal">
      <h2>Reveal on scroll</h2>
      <p>This block fades/slides in when it enters the viewport.</p>
    </div>
    <div class="card reveal">
      <h2>Another reveal</h2>
      <p>Use this for feature callouts, spec lists, etc.</p>
    </div>
  </section>

  <!-- PINNED / SCRUBBED SCENE -->
  <section class="scene" data-scene="product">
    <div class="scene__sticky">
      <div class="stage">
        <div class="product" aria-hidden="true"></div>

        <div class="copy" data-step="0">
          <div class="copy__item copy__item--0">
            <h2>Light. Fast. Calm.</h2>
            <p>Scroll down to “unfold” the story.</p>
          </div>
          <div class="copy__item copy__item--1">
            <h2>Display pops</h2>
            <p>Transforms + opacity create depth without heavy layout changes.</p>
          </div>
          <div class="copy__item copy__item--2">
            <h2>Performance scene</h2>
            <p>Swap copy at progress thresholds for a narrative feel.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- MORE REVEALS -->
  <section class="content">
    <div class="card reveal">
      <h2>Keep it smooth</h2>
      <p>Prefer compositor-friendly properties: <code>transform</code> and <code>opacity</code>.</p>
    </div>
    <div class="card reveal">
      <h2>Respect accessibility</h2>
      <p>Disable or reduce motion when the user requests it.</p>
    </div>
  </section>

  <footer class="footer">
    <p>End.</p>
  </footer>

  <script type="module" src="main.js"></script>
</body>
</html>
```

### 3.2 `styles.css`

```css
/* Basic page styling */
:root {
  --bg: #0b0b0c;
  --fg: #f4f4f5;
  --muted: #b8b8bf;
}

* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: var(--bg); color: var(--fg); font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }

.hero {
  padding: 72px 20px 24px;
  max-width: 980px;
  margin: 0 auto;
}
.hero h1 { font-size: clamp(32px, 4vw, 54px); margin: 0 0 12px; }
.hero .sub { color: var(--muted); margin: 0; }

.content {
  max-width: 980px;
  margin: 0 auto;
  padding: 32px 20px 72px;
  display: grid;
  gap: 18px;
}

.card {
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 16px;
  padding: 18px 18px;
  background: rgba(255,255,255,0.03);
}

/* Progress bar (optional) */
.progress {
  position: fixed;
  z-index: 9999;
  top: 0; left: 0; height: 3px; width: 100%;
  transform-origin: 0 50%;
  transform: scaleX(var(--read, 0));
  background: rgba(255,255,255,0.75);
}

/* Reveal-on-scroll */
.reveal {
  opacity: 0;
  transform: translateY(18px);
  transition: opacity 600ms ease, transform 600ms ease;
}
.reveal.is-visible {
  opacity: 1;
  transform: translateY(0);
}

/* Scene: make it long to create scroll room */
.scene {
  height: 260vh; /* adjust for longer/shorter pin time */
  margin: 0;
}

/* Sticky container pins to viewport */
.scene__sticky {
  position: sticky;
  top: 0;
  height: 100vh;
  display: grid;
  place-items: center;
}

/* Stage contains product + copy */
.stage {
  width: min(980px, calc(100% - 40px));
  height: min(640px, calc(100vh - 120px));
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 24px;
  align-items: center;
  border-radius: 22px;
  border: 1px solid rgba(255,255,255,0.12);
  background: rgba(255,255,255,0.03);
  padding: 24px;
}

/* Product visual (replace with real image/video/canvas later) */
.product {
  width: 100%;
  aspect-ratio: 4 / 3;
  border-radius: 18px;
  background:
    radial-gradient(80% 80% at 30% 20%, rgba(255,255,255,0.28), transparent 60%),
    radial-gradient(70% 70% at 70% 70%, rgba(255,255,255,0.14), transparent 55%),
    linear-gradient(135deg, rgba(255,255,255,0.06), rgba(255,255,255,0.01));
  border: 1px solid rgba(255,255,255,0.14);

  /* Scroll-driven transforms via CSS variable --p (0..1) */
  transform:
    translateY(calc((1 - var(--p, 0)) * 28px))
    scale(calc(0.92 + var(--p, 0) * 0.10))
    rotate(calc((var(--p, 0) - 0.5) * 2deg));
  opacity: calc(0.65 + var(--p, 0) * 0.35);

  /* Use carefully: can help, but don't abuse. */
  will-change: transform, opacity;
}

/* Copy stepper */
.copy { position: relative; min-height: 200px; }
.copy__item { position: absolute; inset: 0; opacity: 0; transform: translateY(10px); transition: 450ms ease; }
.copy__item h2 { margin: 0 0 10px; font-size: clamp(22px, 2.3vw, 34px); }
.copy__item p { margin: 0; color: var(--muted); }

/* Show the active step */
.copy[data-step="0"] .copy__item--0,
.copy[data-step="1"] .copy__item--1,
.copy[data-step="2"] .copy__item--2 {
  opacity: 1;
  transform: translateY(0);
}

.footer {
  padding: 60px 20px;
  text-align: center;
  color: var(--muted);
}

/* Accessibility: reduce motion when user requests it */
@media (prefers-reduced-motion: reduce) {
  .reveal { opacity: 1; transform: none; transition: none; }
  .product { transform: none; opacity: 1; will-change: auto; }
  .copy__item { transition: none; transform: none; }
}
```

Why the accessibility part matters: `prefers-reduced-motion` allows users to request less motion at OS level, and the media query lets you honor it. ([MDN Web Docs][8])
Also: `will-change` can help but should be used carefully as a “last resort” hint because it can increase memory/layer costs. ([MDN Web Docs][9])

### 3.3 `main.js`

```js
// main.js

// ----------------------------
// 1) Reveal-on-scroll (triggered) using IntersectionObserver
// ----------------------------
const revealEls = Array.from(document.querySelectorAll(".reveal"));

const io = new IntersectionObserver(
  (entries) => {
    for (const e of entries) {
      if (e.isIntersecting) e.target.classList.add("is-visible");
      // If you want reverse-on-exit, uncomment:
      // else e.target.classList.remove("is-visible");
    }
  },
  { root: null, threshold: 0.15 }
);

revealEls.forEach((el) => io.observe(el));

// IntersectionObserver is designed for observing visibility changes without
// constantly polling on the main thread.


// ----------------------------
// 2) Pinned scene progress (scrubbed)
// ----------------------------
const scene = document.querySelector('.scene[data-scene="product"]');
const product = scene?.querySelector(".product");
const copy = scene?.querySelector(".copy");

let metrics = null;
let ticking = false;

function clamp01(n) {
  return Math.max(0, Math.min(1, n));
}

function measure() {
  if (!scene) return;

  const rect = scene.getBoundingClientRect();
  const top = rect.top + window.scrollY;
  const height = rect.height;
  const vh = window.innerHeight;

  // Progress runs from when the scene hits the top until its sticky phase ends.
  // Sticky phase length is (sceneHeight - viewportHeight).
  const scrollable = Math.max(1, height - vh);

  metrics = { top, height, vh, scrollable };
}

function update() {
  ticking = false;
  if (!scene || !metrics) return;

  const y = window.scrollY;
  const raw = (y - metrics.top) / metrics.scrollable;
  const p = clamp01(raw);

  // Feed CSS variable for transforms (0..1)
  scene.style.setProperty("--p", p.toFixed(5));

  // Step the copy (3 steps)
  const step = Math.min(2, Math.floor(p * 3)); // 0,1,2
  if (copy) copy.dataset.step = String(step);

  // Optional: reading progress bar for entire document
  const doc = document.documentElement;
  const docScrollable = Math.max(1, doc.scrollHeight - window.innerHeight);
  const read = clamp01(window.scrollY / docScrollable);
  doc.style.setProperty("--read", read.toFixed(5));
}

function onScroll() {
  if (!ticking) {
    ticking = true;
    // Use rAF to avoid running update logic too frequently.
    requestAnimationFrame(update);
  }
}

// requestAnimationFrame schedules work before the next repaint.

window.addEventListener("scroll", onScroll, { passive: true });
window.addEventListener("resize", () => {
  measure();
  update();
});

// Init
measure();
update();
```

---

## 4) How to turn this into “real Apple-like” scenes

Once the starter works, you scale it up like this:

### 4.1 Add more scenes

Duplicate:

```html
<section class="scene" data-scene="camera">...</section>
<section class="scene" data-scene="battery">...</section>
```

Then in JS, loop over all scenes, compute each scene’s progress, and set each scene’s `--p`.

### 4.2 Use transforms + opacity as your default animation tools

For smoothness, animate mostly **`transform`** and **`opacity`** (they’re the classic “compositor-friendly” properties). ([web.dev][10])

Avoid animating layout-heavy properties (`top`, `left`, `width`, `height`) inside scroll loops unless you really need them.

---

## 5) High-fidelity product motion (image sequence / video scrubbing)

This is the “wow” part on many Apple pages.

### 5.1 Approach 1: Image sequence on a `<canvas>` (best scroll sync, heavier assets)

**How it works:** preload frames → map scroll progress to frame index → draw onto canvas.

Apple historically uses image sequences heavily and even created “Flow” to compress and reconstruct them efficiently in-browser. ([Graydon Pleasants: Engineering Portfolio][3])

#### Copy/paste example (canvas sequence)

**HTML**

```html
<section class="scene" data-scene="sequence">
  <div class="scene__sticky">
    <canvas id="seq" width="1600" height="900" style="width: min(980px, 95vw); height: auto;"></canvas>
  </div>
</section>
```

**JS (add to `main.js`)**

```js
const seqScene = document.querySelector('.scene[data-scene="sequence"]');
const canvas = document.getElementById("seq");
const ctx = canvas?.getContext("2d");

const frameCount = 120;
const frames = [];
let seqMetrics = null;

function pad4(n) { return String(n).padStart(4, "0"); }

function preload() {
  for (let i = 0; i < frameCount; i++) {
    const img = new Image();
    // Put your frames in: /frames/frame_0000.webp ... frame_0119.webp
    img.src = `/frames/frame_${pad4(i)}.webp`;
    frames.push(img);
  }
}

function measureSeq() {
  if (!seqScene) return;
  const rect = seqScene.getBoundingClientRect();
  const top = rect.top + window.scrollY;
  const height = rect.height;
  const vh = window.innerHeight;
  const scrollable = Math.max(1, height - vh);
  seqMetrics = { top, scrollable };
}

function drawFrame(i) {
  if (!ctx || !frames[i] || !frames[i].complete) return;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(frames[i], 0, 0, canvas.width, canvas.height);
}

function updateSeq() {
  if (!seqScene || !seqMetrics) return;
  const p = clamp01((window.scrollY - seqMetrics.top) / seqMetrics.scrollable);
  const idx = Math.floor(p * (frameCount - 1));
  drawFrame(idx);
}

// Init sequence scene
if (seqScene && canvas && ctx) {
  preload();
  measureSeq();
  drawFrame(0);

  window.addEventListener("scroll", () => requestAnimationFrame(updateSeq), { passive: true });
  window.addEventListener("resize", () => { measureSeq(); updateSeq(); });
}
```

**Asset tips (important):**

* Prefer modern formats (AVIF/WebP) and keep frame count reasonable.
* Consider multiple resolutions for responsive loading.
* If you need *very long* sequences, consider video or advanced compression techniques (Apple’s “Flow” exists largely because raw sequences get huge). ([Graydon Pleasants: Engineering Portfolio][3])

### 5.2 Approach 2: Video scrubbing (`video.currentTime`) (lighter assets, trickier seeking)

This is listed as a common approach, but seeking can be imperfect if keyframes are sparse. ([Graydon Pleasants: Engineering Portfolio][3])
You can still use it for many “scroll story” effects if you encode appropriately.

---

## 6) Native CSS Scroll‑Driven Animations (modern, minimal JS)

If your target browsers support it, you can do a lot with pure CSS:

* `animation-timeline: scroll()` to drive animations by page scroll
* `animation-timeline: view()` to drive by element visibility
* `animation-range` to control *when* in the viewport the animation starts/ends ([MDN Web Docs][4])

### 6.1 Scroll progress bar (pure CSS)

```css
@keyframes fill {
  from { transform: scaleX(0); }
  to   { transform: scaleX(1); }
}

.progress {
  transform-origin: 0 50%;
  animation: fill linear both;
  animation-timeline: scroll();
}
```

`animation-timeline` is part of scroll-driven animations, but note it’s **limited availability** in some widely used browsers. ([MDN Web Docs][4])

### 6.2 Reveal while entering viewport (pure CSS)

```css
@keyframes rise {
  from { opacity: 0; transform: translateY(18px); }
  to   { opacity: 1; transform: translateY(0); }
}

.reveal {
  animation: rise linear both;
  animation-timeline: view();
  animation-range: entry 15% cover 35%;
}
```

`animation-range` exists to precisely define what “visible in the viewport” means for your animation. ([WebKit][11])

### Why this can feel smoother than JS scroll handlers

Traditional scroll-driven animations were often implemented using main-thread scroll events, but scrolling can be asynchronous and main-thread work can introduce jank. Scroll-driven animation APIs were introduced to help with smoother off-main-thread style-driven animation. ([Chrome for Developers][2])

---

## 7) GSAP ScrollTrigger alternative (fastest to build complex pages)

If you want Apple-like pin + scrub quickly and don’t want to write your own progress math, GSAP ScrollTrigger is a common choice. It explicitly supports **scrub** and **pin** behaviors. ([gsap.com][7])

### Example: pin a section and scrub a tween

```js
import gsap from "gsap";
import ScrollTrigger from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

gsap.to(".product", {
  scale: 1.02,
  y: -20,
  opacity: 1,
  scrollTrigger: {
    trigger: ".scene[data-scene='product']",
    start: "top top",
    end: "bottom top",
    scrub: true,
    pin: true
  }
});
```

(You’d include GSAP + ScrollTrigger via your bundler or script tags depending on setup.)

---

## 8) Accessibility and “premium feel” checklist

### Must-do

* **Respect reduced motion** with `@media (prefers-reduced-motion: reduce)` and provide a calmer experience. ([MDN Web Docs][8])
* Ensure content is readable/usable **even if animations are disabled** (no critical info hidden behind animation states).

### Nice-to-have

* Keep animations mostly to **transform/opacity** for performance. ([web.dev][10])
* Use `IntersectionObserver` for reveal triggers instead of manual scroll polling. ([MDN Web Docs][5])
* If using `will-change`, apply it sparingly and remove it when not needed. ([MDN Web Docs][9])

---

## 9) Quick local dev setup (optional but recommended)

If you want a clean dev server + module support, Vite is a common lightweight option.

```bash
npm create vite@latest apple-scroll-demo -- --template vanilla
cd apple-scroll-demo
npm install
npm run dev
```

Vite’s official getting-started guide documents `npm create vite@latest`. ([vitejs][12])

Then drop `index.html / styles.css / main.js` into the scaffolded project.

---

## 10) Where to go next (how Apple pages scale this up)

When you’re ready to get closer to Apple-level polish:

1. **Storyboard scenes** (literally draw the scroll progression and key moments)
2. **Define keyframes** for each scene (p=0, 0.25, 0.5, 0.75, 1)
3. **Choose asset strategy**

   * small effects → CSS transforms
   * medium complexity → 2D canvas sequences
   * heavy product motion → carefully optimized sequences or video
4. **Add responsive breakpoints** (often Apple uses different compositions for mobile vs desktop)
5. **Performance budget** (frame count, image sizes, decode costs)
6. **Fallback plan** for browsers that don’t support `animation-timeline` yet ([MDN Web Docs][4])

---

## Key references (for deeper learning)

* CSS Scroll-Driven Animations overview (MDN) ([MDN Web Docs][13])
* `animation-timeline` syntax + support notes (MDN) ([MDN Web Docs][4])
* Scroll-driven animations explanation + why main-thread scroll events can jank (Chrome DevRel) ([Chrome for Developers][2])
* IntersectionObserver for viewport-based triggers (MDN) ([MDN Web Docs][5])
* GSAP ScrollTrigger (pin/scrub) docs ([gsap.com][7])
* Apple “Flow” analysis (why image sequences are hard at scale) ([Graydon Pleasants: Engineering Portfolio][3])
* `prefers-reduced-motion` (MDN) ([MDN Web Docs][8])

---

If you paste your own “scene plan” (e.g., “Scene 1: laptop zoom + rotate, Scene 2: ports highlight, Scene 3: color lineup”), I can rewrite the starter into a multi-scene structure with a clean timeline mapping (still copy/paste) and show exactly how to wire each scene’s progress into transforms/text swaps.

[1]: https://css-tricks.com/lets-make-one-of-those-fancy-scrolling-animations-used-on-apple-product-pages/?utm_source=chatgpt.com "Let's Make One of Those Fancy Scrolling Animations Used on Apple ..."
[2]: https://developer.chrome.com/docs/css-ui/scroll-driven-animations "Animate elements on scroll with Scroll-driven animations  |  CSS and UI  |  Chrome for Developers"
[3]: https://graydonpleasants.com/posts/flow-apples-secret-weapon/ "Flow: Apple's Animation Secret Weapon | Graydon Pleasants: Engineering Portfolio"
[4]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/animation-timeline "animation-timeline - CSS | MDN"
[5]: https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API "Intersection Observer API - Web APIs | MDN"
[6]: https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame?utm_source=chatgpt.com "Window: requestAnimationFrame () method - Web APIs | MDN"
[7]: https://gsap.com/docs/v3/Plugins/ScrollTrigger/ "ScrollTrigger | GSAP | Docs & Learning"
[8]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion "prefers-reduced-motion - CSS | MDN"
[9]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/will-change?utm_source=chatgpt.com "will-change - CSS | MDN"
[10]: https://web.dev/articles/stick-to-compositor-only-properties-and-manage-layer-count?utm_source=chatgpt.com "Stick to Compositor-Only Properties and Manage Layer Count - web.dev"
[11]: https://webkit.org/blog/17184/so-many-ranges-so-little-time-a-cheatsheet-of-animation-ranges-for-your-next-scroll-driven-animation/ "  So many ranges, so little time: A cheatsheet of animation-ranges for your next scroll-driven animation | WebKit"
[12]: https://vite.dev/guide/?utm_source=chatgpt.com "Getting Started | Vite"
[13]: https://developer.mozilla.org/docs/Web/CSS/Guides/Scroll-driven_animations "CSS scroll-driven animations - CSS | MDN"
