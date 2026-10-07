// Many topics (the plan's WP3): search, sort, the No photo filter, counts and the letter index.
const { launch, enableSemantics, driver } = require('../lib');
const { importTestData } = require('../testdata');

module.exports = async ({ url, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);
  await importTestData(page, d);

  // Give one topic (anxiety) a photo, using the photo library's bulk topics.
  await d.click('Menu', false); await d.click('Photo library', false, 1500);
  await d.click('Select photos', false, 700); await d.click('Photo 1', true, 500);
  await d.click('Set topics', false, 900);
  await page.getByRole('checkbox', { name: /anxiety/ }).click(); await page.waitForTimeout(400);
  await d.click('Apply', true, 1200);
  await d.click('Back', false, 900);

  const rows = async () => (await d.rects(/ verses? · /)).filter((n) => n.role === 'button').sort((a, b) => a.y - b.y).map((n) => n.text.split('\n')[0]);
  const search = () => page.getByRole('textbox').first();

  await d.click('Menu', false); await d.click('Topics', false, 1500);
  const hopeRow = (await d.rects(/^hope\n/))[0];
  check('rows show the verse count and "no photo"', hopeRow && /^hope\n12 verses · no photo$/.test(hopeRow.text), hopeRow ? hopeRow.text : 'no hope row');

  // Search.
  await search().click(); await page.waitForTimeout(300); await page.keyboard.type('grie'); await page.waitForTimeout(900);
  let listed = await rows();
  check('searching "grie" lists only grief', listed.length === 1 && listed[0] === 'grief', listed.join(', '));
  await search().click({ clickCount: 3 }); await page.keyboard.press('Backspace'); await page.waitForTimeout(500);
  await page.keyboard.press('Control+A'); await page.keyboard.press('Backspace'); await page.waitForTimeout(700);

  // Sort.
  await d.click('Most verses', false, 1000);
  listed = await rows();
  check('Most verses lists hope first', listed[0] === 'hope', listed.slice(0, 4).join(', '));
  await d.click('A–Z', false, 1000);
  listed = await rows();
  check('A–Z lists topics alphabetically', listed[0] === 'anxiety', listed.slice(0, 4).join(', '));

  // Letter index.
  check('the letter index is shown for A–Z', (await d.rects('Jump to W')).length > 0, '');
  await d.click('Jump to W', false, 900);
  const worship = (await d.rects(/^worship/)).filter((n) => n.role === 'button')[0];
  check('tapping W jumps to the W topics', worship && worship.y >= 0 && worship.y < 844, worship ? `worship at y=${Math.round(worship.y)}` : 'not built');

  // No photo filter.
  const t = await d.text();
  check('the No photo chip counts topics without a photo (49 of 50)', t.includes('No photo · 49'), '');
  await page.getByRole('checkbox', { name: /No photo/ }).click(); await page.waitForTimeout(1000);
  listed = await rows();
  check('No photo hides the topic that has a photo', !listed.includes('anxiety') && listed.length > 0, `${listed.length} listed`);
  await browser.close();
};
