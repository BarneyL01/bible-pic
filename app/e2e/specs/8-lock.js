// The lock button locks a photo to a verse and unlocks it again; the icons sit in the menu's row.
const { launch, enableSemantics, driver } = require('../lib');

module.exports = async ({ url, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);
  await d.click('Add a verse', false); await d.click('Add verse');
  await d.typeVerse('John 3:16', 'For God so loved the world.');
  await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);

  const centreY = async (name) => {
    const b = await page.getByRole('button', { name, exact: false }).first().boundingBox();
    return b.y + b.height / 2;
  };
  const menuY = await centreY('Menu');
  const lockY = await centreY('Lock this photo');
  check('the lock icon is in line with the menu button', Math.abs(menuY - lockY) <= 6, `menu ${menuY.toFixed(0)} lock ${lockY.toFixed(0)}`);

  await d.click('Lock this photo', false, 900);
  let t = await d.text();
  check('tapping the lock locks the photo', t.includes('Unlock photo') && !t.includes('Lock this photo to the verse'), '');
  await d.click('Unlock photo', false, 900);
  t = await d.text();
  check('tapping it again unlocks the photo', t.includes('Lock this photo to the verse') && !t.includes('Unlock photo'), '');
  await d.click('Lock this photo', false, 900);
  await d.click('Unlock photo', false, 900);
  await d.click('Lock this photo', false, 900);
  t = await d.text();
  check('it can be locked, unlocked and locked again', t.includes('Unlock photo'), '');
  await browser.close();
};
