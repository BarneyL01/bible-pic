// Bulk import, persistence across reload, backup download, restore into a fresh profile.
const path = require('path');
const { launch, enableSemantics, driver } = require('../lib');

module.exports = async ({ url, tmp, check }) => {
  const zip = path.join(tmp, 'backup.zip');
  let s = await launch(); let page = s.page; let d = driver(page);
  await page.goto(url); await page.waitForTimeout(6000); await enableSemantics(page);
  await d.click('Menu', false); await d.click('Photo library', false);
  const [fc] = await Promise.all([page.waitForEvent('filechooser'), d.btn('Add photos').click()]);
  await fc.setFiles(path.join(tmp, 'portrait.png')); await page.waitForTimeout(2500);
  await d.click('No crop', false, 3000); await d.click('Back', false);
  await d.click('Menu', false); await d.click('Bulk import', false);
  await page.getByRole('textbox').first().click();
  await page.keyboard.type('Psalm 23:1 (ESV)\nThe Lord is my shepherd; I shall not want.\n# comfort, trust');
  await page.keyboard.press('Enter'); await page.keyboard.press('Enter');
  await page.keyboard.type('Isaiah 41:10\nFear not, for I am with you.\n# comfort');
  await d.click('Import pasted text', false, 1500);
  await d.click('Back', false); await d.click('Menu', false); await d.click('Verses', false);
  let t = await d.text();
  check('bulk import created 2 verses', t.includes('Psalm 23:1') && t.includes('Isaiah 41:10'));
  await d.click('Back', false); await d.click('Menu', false); await d.click('Topics', false, 1200);
  t = await d.text();
  check('bulk import created topics', t.includes('comfort') && t.includes('trust'));

  await page.reload(); await page.waitForTimeout(6000); await enableSemantics(page);
  await d.click('Menu', false); await d.click('Verses', false);
  t = await d.text();
  check('data persists after a page reload', t.includes('Psalm 23:1') && t.includes('Isaiah 41:10'));

  await d.click('Back', false); await d.click('Menu', false); await d.click('Settings', false);
  await d.click('Backup & new phone', false, 1200);
  const [dl] = await Promise.all([page.waitForEvent('download'), d.btn('Back up now').click()]);
  await dl.saveAs(zip);
  check('backup downloads a zip', /^bible-pic-backup-\d{4}-\d{2}-\d{2}\.zip$/.test(dl.suggestedFilename()), dl.suggestedFilename());
  await s.browser.close();

  s = await launch(); page = s.page; d = driver(page);
  await page.goto(url); await page.waitForTimeout(6000); await enableSemantics(page);
  check('a fresh profile starts empty', (await d.text()).includes('No verses yet'));
  await d.click('Restore from a backup', false); await d.click('Restore', true);
  await page.getByRole('button', { name: /Replace — wipe/ }).first().click(); await page.waitForTimeout(900);
  const [fc2] = await Promise.all([page.waitForEvent('filechooser'), d.btn('Replace', true).click()]);
  await fc2.setFiles(zip); await page.waitForTimeout(2500);
  t = await d.text();
  check('restore reports 2 verses and 1 photo', /2 verses/.test(t) && /1 photos/.test(t));
  await d.click('OK', true, 800); await d.click('Back', false, 1200);
  await d.click('Menu', false); await d.click('Photo library', false, 1200);
  await page.screenshot({ path: path.join(tmp, 'restored-library.png') });
  await s.browser.close();
};
