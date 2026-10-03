// Moving and resizing the text box, and that the viewer shows it where it was set.
const path = require('path');
const { launch, enableSemantics, driver } = require('../lib');
const m = require('../measure');
const near = (a, b, tol) => Math.abs(a - b) <= tol;

module.exports = async ({ url, tmp, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(6000); await enableSemantics(page);
  await d.clearDefaultPhotos();
  const [fc] = await Promise.all([page.waitForEvent('filechooser'), d.btn('Add photos').click()]);
  await fc.setFiles(path.join(tmp, 'portrait.png')); await page.waitForTimeout(2500);
  await d.click('No crop', false, 3000); await d.click('Back', false);
  await d.click('Menu', false); await d.click('Verses', false); await d.click('Add verse');
  await d.typeVerse('John 3:16', 'For God so loved the world, that he gave his only Son.');
  await d.click('Move or resize text box', false, 1500);

  const shot = async (n) => { const f = path.join(tmp, n); await page.screenshot({ path: f }); return m.load(f); };
  const d0 = m.dots(await shot('p0.png'));
  await d.drag(d0.x + d0.w / 2, d0.y + d0.h / 2, 0, -250);
  const d1 = m.dots(await shot('p1.png'));
  check('moving follows the finger 1:1', near(d1.x - d0.x, 0, 4) && near(d1.y - d0.y, -250, 4), `dx=${d1.x - d0.x} dy=${d1.y - d0.y} want 0,-250`);

  await d.drag(d1.x + d1.w - 14, d1.y + d1.h - 14, -60, 0);
  const d2 = m.dots(await shot('p2.png'));
  check('bottom-right dot narrows, left edge fixed', near(d2.w - d1.w, -60, 4) && near(d2.x, d1.x, 3), `dw=${d2.w - d1.w} want -60`);

  await d.drag(d2.x + d2.w - 14, d2.y + d2.h - 14, 36, 0);
  const d3 = m.dots(await shot('p3.png'));
  check('bottom-right dot widens, left edge fixed', near(d3.w - d2.w, 36, 4) && near(d3.x, d2.x, 3), `dw=${d3.w - d2.w} want +36`);

  await d.drag(d3.x + 14, d3.y + 14, 30, 0);
  const p4 = await shot('p4.png'); const d4 = m.dots(p4);
  check('top-left dot narrows, right edge fixed', near(d4.w - d3.w, -30, 4) && near(d4.x + d4.w, d3.x + d3.w, 3), `dw=${d4.w - d3.w} want -30`);

  const inner = (png, h) => m.bbox(png, m.isWhite, h.y + 30, h.y + h.h - 30, h.x + 30, h.x + h.w - 30);
  const t4 = inner(p4, d4);
  await d.click('Done'); await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);
  const main = await shot('main.png');
  const tm = m.bbox(main, m.isWhite, d4.y + 30, d4.y + d4.h - 30, d4.x + 30, d4.x + d4.w - 30);
  check('viewer shows the box where it was set', tm && near(tm.x, t4.x, 3) && near(tm.y, t4.y, 3), `set (${t4.x},${t4.y}) shown (${tm && tm.x},${tm && tm.y})`);
  await browser.close();
};
