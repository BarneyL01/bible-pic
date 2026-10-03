// Wide window: the app sits in a centred portrait frame. Crop fills the screen.
const path = require('path');
const { launch, enableSemantics, driver } = require('../lib');
const m = require('../measure');

module.exports = async ({ url, tmp, check }) => {
  // Crop: a landscape photo cropped to the screen must fill the whole viewer.
  let s = await launch(); let page = s.page; let d = driver(page);
  await page.goto(url); await page.waitForTimeout(6000); await enableSemantics(page);
  await d.clearDefaultPhotos();
  const [fc] = await Promise.all([page.waitForEvent('filechooser'), d.btn('Add photos').click()]);
  await fc.setFiles(path.join(tmp, 'landscape.png')); await page.waitForTimeout(2500);
  await d.click('Crop', true, 3500); await d.click('Back', false);
  await d.click('Menu', false); await d.click('Verses', false); await d.click('Add verse');
  await d.typeVerse('John 3:16', 'For God so loved the world.');
  await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);
  const f = path.join(tmp, 'cropped-viewer.png'); await page.screenshot({ path: f });
  const png = m.load(f);
  const margin = (r, g, b) => r === 17 && g === 17 && b === 17;
  const corners = [[4, 70], [385, 70], [4, 838], [385, 838]];
  const photoCorners = corners.filter(([x, y]) => { const [r, g, b] = m.pixel(png, x, y); return !margin(r, g, b); });
  check('cropped photo fills the screen (no margin at the corners)', photoCorners.length === 4, `${photoCorners.length}/4 corners are photo`);
  await s.browser.close();

  // Wide desktop window.
  s = await launch(1280, 800); page = s.page; d = driver(page);
  await page.goto(url); await page.waitForTimeout(6000); await enableSemantics(page);
  const g = path.join(tmp, 'wide.png'); await page.screenshot({ path: g });
  const wide = m.load(g);
  const outside = m.pixel(wide, 100, 400), inside = m.pixel(wide, 640, 700);
  check('outside the frame is black', outside.every((v) => v === 0), JSON.stringify(outside));
  check('the frame is a centred portrait column', inside.some((v) => v > 0) && m.pixel(wide, 420, 400).some((v) => v > 0) && m.pixel(wide, 860, 400).some((v) => v > 0) && m.pixel(wide, 410, 400).every((v) => v === 0), '');
  await s.browser.close();
};
