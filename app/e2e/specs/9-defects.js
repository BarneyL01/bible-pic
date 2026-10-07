// WP1 defects: the heart is a button with a tooltip, tap-anywhere still works, the default theme row.
const { launch, enableSemantics, driver } = require('../lib');

module.exports = async ({ url, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);
  await d.click('Add a verse', false); await d.click('Add verse');
  await d.typeVerse('John 3:16', 'For God so loved the world.');
  await d.click('Save'); await d.click('Back', false); await page.waitForTimeout(1500);

  let t = await d.text();
  check('D3: the heart is a button offering to add a favourite', t.includes('Add to favourites'), '');
  await d.click('Add to favourites', false, 900);
  t = await d.text();
  check('D3: pressing it flips the tooltip to "Remove from favourites"', t.includes('Remove from favourites') && !t.includes('Add to favourites'), '');
  await page.mouse.click(195, 300); await page.waitForTimeout(900);
  t = await d.text();
  check('D3: tapping anywhere on the verse still toggles it', t.includes('Add to favourites') && !t.includes('Remove from favourites'), '');

  await d.click('Menu', false); await d.click('Themes', false, 1200);
  t = await d.text();
  check('D2: the default theme says "In use as default"', t.includes('In use as default'), '');
  check('D2: it does not read "Default Default"', !/Default\s+Default/.test(t), '');
  await browser.close();
};
