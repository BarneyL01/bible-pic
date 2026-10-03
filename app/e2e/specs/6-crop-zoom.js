// Crop screen: zoom out to see the whole photo, move it vertically, and reset.
const path = require('path');
const { launch, enableSemantics, driver } = require('../lib');
const m = require('../measure');

const MARGIN = [17, 17, 17];
const isMargin = (p) => p[0] === MARGIN[0] && p[1] === MARGIN[1] && p[2] === MARGIN[2];

/** Opens the crop screen on the landscape photo, runs [act], crops, and returns the viewer screenshot. */
async function cropAndShow({ url, tmp }, name, act) {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);
  await d.clearDefaultPhotos();
  const [fc] = await Promise.all([page.waitForEvent('filechooser'), d.btn('Add photos').click()]);
  await fc.setFiles(path.join(tmp, 'landscape.png')); await page.waitForTimeout(2500);
  await act(page, d);
  await d.click('Crop', true, 3500); await d.click('Back', false);
  await d.click('Menu', false); await d.click('Verses', false); await d.click('Add verse');
  await d.typeVerse('John 3:16', 'For God so loved the world.');
  await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);
  const f = path.join(tmp, `crop-zoom-${name}.png`);
  await page.screenshot({ path: f });
  await browser.close();
  return m.load(f);
}

/** Vertical extent of the photo along a column right of the verse panel (x=375), below the heart icon. */
function photoExtent(png, x = 375) {
  let top = null, bottom = null;
  for (let y = 100; y < png.height; y++) {
    if (!isMargin(m.pixel(png, x, y))) { if (top === null) top = y; bottom = y; }
  }
  return { top, bottom };
}

const zoomOut = async (page) => {
  await page.mouse.move(195, 400);
  await page.mouse.wheel(0, 4000);
  await page.waitForTimeout(600);
};

module.exports = async (ctx) => {
  const { check } = ctx;

  const zoomed = await cropAndShow(ctx, 'out', async (page) => { await zoomOut(page); });
  const a = photoExtent(zoomed);
  const height = a.bottom - (a.top ?? a.bottom);
  check('zooming out shows the whole landscape photo with margin above and below',
    a.top !== null && a.top > 150 && a.bottom < 700 && height > 200 && height < 330, `photo rows ${a.top}..${a.bottom}`);
  check('the zoomed-out photo still has both halves (blue left, orange right)',
    m.pixel(zoomed, 15, Math.round((a.top + a.bottom) / 2))[2] > 150 &&
    m.pixel(zoomed, 375, Math.round((a.top + a.bottom) / 2))[0] > 180, '');

  const moved = await cropAndShow(ctx, 'moved', async (page, d) => {
    await zoomOut(page);
    // Many small steps, like a finger: a few large synthetic steps are over-counted by Flutter's slop handling.
    await d.drag(195, 500, 0, -250, 100);
  });
  const b = photoExtent(moved);
  check('dragging up moves the zoomed-out photo up by the distance dragged',
    b.bottom !== null && Math.abs((b.bottom - a.bottom) - -250) < 8, `bottom ${a.bottom} -> ${b.bottom} (want -250)`);

  const reset = await cropAndShow(ctx, 'reset', async (page, d) => {
    await zoomOut(page);
    // Many small steps, like a finger: a few large synthetic steps are over-counted by Flutter's slop handling.
    await d.drag(195, 500, 0, -250, 100);
    await d.click('Reset', false, 700);
  });
  const corners = [[4, 75], [385, 75], [4, 835], [385, 835]];
  const filled = corners.filter(([x, y]) => !isMargin(m.pixel(reset, x, y))).length;
  check('Reset fills the screen with the photo again', filled === 4, `${filled}/4 corners are photo`);
};
