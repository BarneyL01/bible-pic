// Many topics (the plan's WP2): the verse editor's topic section and the topic picker.
const { launch, enableSemantics, driver } = require('../lib');
const { importTestData } = require('../testdata');

module.exports = async ({ url, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);
  await importTestData(page, d);

  const openVerse = async (reference) => {
    await d.click('Menu', false); await d.click('Verses', false, 1200);
    await d.click(reference, false, 1500);
  };
  const removeButtons = async () =>
    (await d.rects(/^Remove /)).filter((n) => n.role === 'button').map((n) => n.text.replace(/^Remove /, '')).sort();

  await openVerse('Psalm 1:1');
  const names = await removeButtons();
  check("the editor names exactly the verse's four topics", JSON.stringify(names) === JSON.stringify(['faith', 'hope', 'love', 'strength']), names.join(', '));
  // The section is one accessibility group ("Topics / 4 of 50 / Used most"); take the smallest node that starts with it.
  const heading = (await d.rects(/^Topics(\s|$)/)).sort((a, b) => a.h - b.h)[0];
  const pinned = (await d.rects(/^Pinned photo/))[0];
  check('the topic section leaves Pinned photo on screen (within 320 px of its heading)', heading && pinned && pinned.y - heading.y <= 320, `${pinned && heading ? Math.round(pinned.y - heading.y) : '?'} px`);
  check('the section says how many of the topics are chosen', (await d.text()).includes('4 of 50'), '');

  // Picker, first visit: search, Clear, then dismiss; the verse keeps its four topics.
  await d.click('Choose from all 50 topics', false, 1200);
  let search = page.getByRole('textbox').last();
  await search.click(); await page.waitForTimeout(300); await page.keyboard.type('pea'); await page.waitForTimeout(800);
  let t = await d.text();
  check('searching "pea" shows peace and one match', t.includes('peace') && t.includes('1 match'), '');
  await d.click('Clear search', false, 700);
  t = await d.text();
  check('Clear search empties the search and brings back the full list', !t.includes('1 match') && t.includes('anxiety'), '');
  await page.mouse.click(195, 30); await page.waitForTimeout(900); // the scrim: dismisses the sheet
  check('dismissing the picker leaves the verse with its four topics', (await removeButtons()).length === 4, '');

  // Picker, second visit: create a topic.
  await d.click('Choose from all 50 topics', false, 1200);
  search = page.getByRole('textbox').last();
  await search.click(); await page.waitForTimeout(300); await page.keyboard.type('lament'); await page.waitForTimeout(900);
  await d.click('Create topic', false, 900);
  t = await d.text();
  check('creating "lament" selects it (5 selected)', t.includes('5 selected for Psalm 1:1'), '');
  await d.click('Done', true, 900);
  check('the editor now shows five topics out of 51', (await removeButtons()).length === 5 && (await d.text()).includes('5 of 51'), '');

  // Saved, and still five when reopened.
  await d.click('Save', true, 1200);
  await d.click('Psalm 1:1', false, 1500);
  const again = await removeButtons();
  check('after Save and reopening, five topics are shown', again.length === 5 && again.includes('lament'), again.join(', '));
  await d.click('Back', false, 900);

  // Used most: Psalm 11:1 does not have hope, the topic with the most verses.
  await d.click('Psalm 11:1', false, 1500);
  // The chosen topics (chips and their Remove buttons) sit in the rows above "Used most"; take what lies below them.
  const nodes = await d.rects(/./);
  const lastChosenRow = Math.max(...nodes.filter((n) => /^Remove /.test(n.text)).map((n) => n.y));
  const choose = (await d.rects(/^Choose from all/))[0];
  const chips = nodes
    .filter((n) => (n.role === 'button' || n.role === 'checkbox') && n.y > lastChosenRow + 20 && n.y < choose.y)
    .sort((a, b) => a.y - b.y || a.x - b.x)
    .map((n) => n.text);
  check('the first "Used most" chip is hope', chips[0] === 'hope', chips.join(', '));
  check('"Used most" offers at most four topics', chips.length > 0 && chips.length <= 4, chips.join(', '));
  await browser.close();
};
