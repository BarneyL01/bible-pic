// Draws the Bible Pic icon and writes every size the app needs:
//   web/favicon.png, web/icons/*            browser tab, PWA, apple-touch
//   android_icons/mipmap-*                  launcher icons (copied by tool/setup_android.*)
//   assets/icon/icon-1024.png               preview / store artwork
// Run from app/ after `cd e2e && npm install`:  node tool/make_icons.js
// The artwork is the SVG below; edit it and re-run. Needs Chromium (see e2e/lib.js).
const fs = require('fs');
const path = require('path');
const { launch } = require('../e2e/lib');

const SKY = `
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#26337F"/>
      <stop offset="0.45" stop-color="#6A55B0"/>
      <stop offset="0.75" stop-color="#F2955A"/>
      <stop offset="1" stop-color="#F7C27A"/>
    </linearGradient>
    <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFF1C9"/>
      <stop offset="0.7" stop-color="#FFD99A"/>
      <stop offset="1" stop-color="#FFD99A" stop-opacity="0"/>
    </radialGradient>
  </defs>`;

// Full-bleed layer: sky, sun, two mountain ridges.
const BACKGROUND = `${SKY}
  <rect width="1024" height="1024" fill="url(#sky)"/>
  <circle cx="512" cy="650" r="300" fill="url(#sun)"/>
  <circle cx="512" cy="650" r="190" fill="#FFE2A8"/>
  <path d="M0 780 L180 610 L330 710 L520 520 L720 700 L860 620 L1024 740 L1024 1024 L0 1024Z" fill="#4A3F94" opacity="0.92"/>
  <path d="M0 880 L200 750 L400 850 L600 730 L800 840 L1024 770 L1024 1024 L0 1024Z" fill="#231F5E"/>`;

// Centred layer: a cross above a translucent verse panel with two lines of text.
const FOREGROUND = `
  <g>
    <rect x="466" y="120" width="92" height="320" rx="16" fill="#FFFFFF"/>
    <rect x="392" y="204" width="240" height="88" rx="16" fill="#FFFFFF"/>
    <rect x="212" y="690" width="600" height="224" rx="44" fill="#000000" opacity="0.5"/>
    <rect x="268" y="742" width="488" height="36" rx="18" fill="#FFFFFF" opacity="0.96"/>
    <rect x="268" y="808" width="330" height="36" rx="18" fill="#FFFFFF" opacity="0.8"/>
  </g>`;

const scaled = (s) => `<g transform="translate(512 512) scale(${s}) translate(-512 -512)">${FOREGROUND}</g>`;

/** layers: 'all' | 'bg' | 'fg'. shape: 'rounded' clips the corners, 'full' is square. */
function svg({ size, layers = 'all', shape = 'full', fgScale = 1 }) {
  const body = (layers !== 'fg' ? BACKGROUND : '') + (layers !== 'bg' ? scaled(fgScale) : '');
  const clip = shape === 'rounded'
    ? '<clipPath id="r"><rect width="1024" height="1024" rx="224"/></clipPath>' : '';
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024">
    ${clip}<g ${shape === 'rounded' ? 'clip-path="url(#r)"' : ''}>${body}</g></svg>`;
}

const out = (...p) => path.join(__dirname, '..', ...p);
const ensure = (f) => fs.mkdirSync(path.dirname(f), { recursive: true });

const MASKABLE_SCALE = 0.76;   // keeps the panel inside the 80% maskable safe zone
const ADAPTIVE_SCALE = 0.62;   // keeps it inside the 66 dp safe zone of a 108 dp layer

const jobs = [];
const add = (file, opts) => jobs.push({ file: out(file), opts });
add('web/favicon.png', { size: 32, shape: 'rounded' });
add('web/icons/Icon-192.png', { size: 192, shape: 'rounded' });
add('web/icons/Icon-512.png', { size: 512, shape: 'rounded' });
add('web/icons/Icon-maskable-192.png', { size: 192, fgScale: MASKABLE_SCALE });
add('web/icons/Icon-maskable-512.png', { size: 512, fgScale: MASKABLE_SCALE });
add('assets/icon/icon-1024.png', { size: 1024, shape: 'rounded' });
// Android: legacy launcher icons (48 dp) and adaptive layers (108 dp), per density.
const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [name, scale] of Object.entries(densities)) {
  add(`android_icons/mipmap-${name}/ic_launcher.png`, { size: 48 * scale, shape: 'rounded' });
  add(`android_icons/mipmap-${name}/ic_launcher_background.png`, { size: 108 * scale, layers: 'bg' });
  add(`android_icons/mipmap-${name}/ic_launcher_foreground.png`, { size: 108 * scale, layers: 'fg', fgScale: ADAPTIVE_SCALE });
}

(async () => {
  const { browser, page } = await launch();
  for (const { file, opts } of jobs) {
    await page.setViewportSize({ width: opts.size, height: opts.size });
    await page.setContent(`<html><body style="margin:0;background:transparent">${svg(opts)}</body></html>`);
    ensure(file);
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width: opts.size, height: opts.size }, omitBackground: true });
    console.log('wrote', path.relative(out(), file), `${opts.size}px`);
  }
  await browser.close();

  const xml = out('android_icons/mipmap-anydpi-v26/ic_launcher.xml');
  ensure(xml);
  fs.writeFileSync(xml, `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`);
  console.log('wrote android_icons/mipmap-anydpi-v26/ic_launcher.xml');
})();
