// Photo library: multi-select, topics, theme and delete on several photos at once.
const { launch, enableSemantics, driver } = require('../lib');

const photos = (page) => page.getByRole('button', { name: /^Photo \d+$/ }).count();

module.exports = async ({ url, check }) => {
  const { browser, page } = await launch();
  const d = driver(page);
  await page.goto(url); await page.waitForTimeout(7000); await enableSemantics(page);

  // A topic and a second theme to choose from.
  await d.click('Menu', false); await d.click('Topics', false, 1200);
  await d.click('New topic', false);
  await page.getByRole('textbox').first().click(); await page.keyboard.type('peace');
  await d.click('Save', true, 900); await d.click('Back', false);
  await d.click('Menu', false); await d.click('Themes', false, 1200);
  await d.click('Add theme', false, 1200); await d.click('Save', true, 1200); await d.click('Back', false);

  await d.click('Menu', false); await d.click('Photo library', false, 1500);
  check('the library starts with the five default photos', (await photos(page)) === 5, `found ${await photos(page)}`);

  // Long-press starts selecting; taps add to the selection.
  const box = await page.getByRole('button', { name: 'Photo 1', exact: true }).first().boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down(); await page.waitForTimeout(900); await page.mouse.up(); await page.waitForTimeout(600);
  let t = await d.text();
  check('a long press starts selecting with that photo', t.includes('1 selected'), '');
  await d.click('Photo 2', true, 500); await d.click('Photo 3', true, 500);
  t = await d.text();
  check('tapping adds photos to the selection', t.includes('3 selected'), '');

  // Topics on all three at once.
  await d.click('Set topics', false, 900);
  await page.getByRole('checkbox', { name: /peace/ }).click(); await page.waitForTimeout(400);
  await d.click('Apply', true, 1000);
  t = await d.text();
  check('topics are applied to the selected photos', t.includes('Topics updated on 3 photo'), '');

  const peaceChecked = async (names) => {
    await d.click('Select photos', false, 700);
    for (const n of names) await d.click(n, true, 400);
    await d.click('Set topics', false, 900);
    const checked = await page.getByRole('checkbox', { name: /peace/ }).isChecked();
    await d.click('Cancel', true, 600);
    await d.click('Cancel selection', false, 600);
    return checked;
  };
  check('all three photos now have the topic', (await peaceChecked(['Photo 1', 'Photo 2', 'Photo 3'])) === true, '');
  check('the other photos do not', (await peaceChecked(['Photo 4', 'Photo 5'])) === false, '');

  // Theme on two photos.
  await d.click('Select photos', false, 700);
  await d.click('Photo 1', true, 400); await d.click('Photo 2', true, 400);
  await d.click('Set theme', false, 900); await d.click('New theme', true, 1000);
  t = await d.text();
  check('a theme is set on the selected photos', t.includes('Theme set on 2 photo'), '');
  await d.click('Photo 1', true, 1200);
  t = await d.text();
  check('the photo shows the theme it was given', t.includes('New theme'), '');
  await d.click('Back', false, 900);
  await d.click('Photo 3', true, 1200);
  t = await d.text();
  check('an unselected photo has no theme', t.includes('No theme') && !t.includes('New theme'), '');
  await d.click('Back', false, 900);

  // Delete two at once.
  await d.click('Select photos', false, 700);
  await d.click('Photo 4', true, 400); await d.click('Photo 5', true, 400);
  await d.click('Delete selected', false, 900);
  t = await d.text();
  check('delete asks first, with the count', t.includes('Delete 2 photos?'), '');
  await d.click('Delete', true, 1500);
  check('both selected photos are deleted', (await photos(page)) === 3, `found ${await photos(page)}`);
  await browser.close();
};
