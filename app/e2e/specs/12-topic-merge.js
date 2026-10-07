// Selecting topics and merging them (the plan's WP4).
const { launch, enableSemantics, driver } = require('../lib');
const { importTestData, topicsOf } = require('../testdata');

module.exports = async ({ url, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);
  await importTestData(page, d);

  const verseSet = (name) => new Set(Array.from({ length: 50 }, (_, k) => k + 1).filter((i) => topicsOf(i).includes(name)));
  const union = new Set([...verseSet('anxiety'), ...verseSet('comfort')]);

  await d.click('Menu', false); await d.click('Topics', false, 1500);
  const row = async (name) => (await d.rects(new RegExp(`^${name}\\n`))).filter((n) => n.role === 'button' || n.role === 'checkbox')[0];

  // Long press selects the first topic.
  const a = await row('anxiety');
  await page.mouse.move(a.x + a.w / 2, a.y + a.h / 2); await page.mouse.down(); await page.waitForTimeout(800); await page.mouse.up();
  await page.waitForTimeout(700);
  check('long pressing a topic selects it', (await d.rects(/Cancel selection1 selected$/)).length > 0, '');
  // A tap adds the second.
  const c = await row('comfort');
  await page.mouse.click(c.x + c.w / 2, c.y + c.h / 2); await page.waitForTimeout(700);
  check('tapping another topic adds it', (await d.rects(/Cancel selection2 selected$/)).length > 0, '');

  // Merge, keeping the first name.
  await d.click('Merge', false, 900);
  check('the merge dialog names the topics', (await d.rects('Merge 2 topics')).length > 0, '');
  await page.getByRole('radio', { name: 'anxiety' }).click(); await page.waitForTimeout(300);
  await page.getByRole('button', { name: 'Merge' }).last().click(); await page.waitForTimeout(1500);

  const merged = await row('anxiety');
  const expected = `anxiety\n${union.size} verses`;
  check('the merged topic holds the union of both topics\' verses', merged && merged.text.startsWith(expected), merged ? merged.text : 'no row');
  check('the other topic is gone', !(await row('comfort')), '');
  check('selection mode has ended', (await d.rects('Cancel selection')).length === 0, '');
  await browser.close();
};
