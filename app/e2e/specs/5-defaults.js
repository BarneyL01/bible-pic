// The five bundled photos: added once on first launch, shown, deletable, never re-added.
const { launch, enableSemantics, driver } = require('../lib');
const m = require('../measure');
const path = require('path');

const photos = (page) => page.getByRole('button', { name: /^Photo \d+$/ }).count();

module.exports = async ({ url, tmp, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);

  // A verse gets a default photo on the very first screen.
  await d.click('Add a verse', false); await d.click('Add verse');
  await d.typeVerse('John 3:16', 'For God so loved the world.');
  await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);
  const f = path.join(tmp, 'defaults-viewer.png'); await page.screenshot({ path: f });
  const png = m.load(f);
  const margin = (p) => p[0] === 17 && p[1] === 17 && p[2] === 17;
  check('the first verse is shown on a default photo', !margin(m.pixel(png, 195, 120)) && !margin(m.pixel(png, 195, 700)), '');

  await d.click('Menu', false); await d.click('Photo library', false, 1500);
  check('five default photos are in the library', (await photos(page)) === 5, `found ${await photos(page)}`);

  await page.reload(); await page.waitForTimeout(7000); await enableSemantics(page);
  await d.click('Menu', false); await d.click('Photo library', false, 1500);
  check('a second launch does not add them again', (await photos(page)) === 5, `found ${await photos(page)}`);

  await d.click('Photo 1', true); await d.click('Delete photo', false); await d.click('Delete', true, 1200);
  check('a default photo can be deleted', (await photos(page)) === 4, `found ${await photos(page)}`);

  await page.reload(); await page.waitForTimeout(7000); await enableSemantics(page);
  await d.click('Menu', false); await d.click('Photo library', false, 1500);
  check('a deleted default photo does not come back', (await photos(page)) === 4, `found ${await photos(page)}`);
  await browser.close();
};
