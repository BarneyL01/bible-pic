// Cropping a landscape photo: it starts centred and can be dragged to either side.
const path = require('path');
const { launch, enableSemantics, driver } = require('../lib');
const m = require('../measure');

// images.js: the landscape photo is blue on its left half and orange on its right half.
const blue = (r, g, b) => b > 150 && r < 100;
const orange = (r, g, b) => r > 180 && b < 100;

module.exports = async ({ url, tmp, check }) => {
  for (const side of ['left', 'right', 'centre']) {
    const { browser, page } = await launch();
    const d = driver(page);
    await page.goto(url); await page.waitForTimeout(6000); await enableSemantics(page);
    await d.click('Menu', false); await d.click('Photo library', false);
    const [fc] = await Promise.all([page.waitForEvent('filechooser'), d.btn('Add photos').click()]);
    await fc.setFiles(path.join(tmp, 'landscape.png')); await page.waitForTimeout(2500);

    const before = path.join(tmp, `crop-${side}-start.png`);
    await page.screenshot({ path: before });
    const start = m.load(before);
    if (side === 'centre') {
      const l = m.pixel(start, 5, 300), r = m.pixel(start, 384, 300);
      check('crop screen starts centred (blue and orange both visible)', blue(...l) && orange(...r), `left ${l} right ${r}`);
    } else {
      // Drag the photo far enough to reach its edge.
      await d.drag(side === 'left' ? 60 : 330, 400, side === 'left' ? 700 : -700, 0, 30);
    }
    await d.click('Crop', true, 3500); await d.click('Back', false);
    await d.click('Menu', false); await d.click('Verses', false); await d.click('Add verse');
    await d.typeVerse('John 3:16', 'For God so loved the world.');
    await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);
    const f = path.join(tmp, `crop-${side}-viewer.png`);
    await page.screenshot({ path: f });
    const png = m.load(f);
    const tl = m.pixel(png, 6, 90), br = m.pixel(png, 383, 830);
    if (side === 'left') check('dragging right crops the left side of the photo', blue(...tl) && blue(...br), `corners ${tl} ${br}`);
    if (side === 'right') check('dragging left crops the right side of the photo', orange(...tl) && orange(...br), `corners ${tl} ${br}`);
    if (side === 'centre') check('an untouched crop is the middle of the photo (blue left, orange right)', blue(...tl) && orange(...br), `corners ${tl} ${br}`);
    await browser.close();
  }
};
