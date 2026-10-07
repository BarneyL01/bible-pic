const { chromium } = require('playwright-core');
const fs = require('fs');

function chromePath() {
  if (process.env.CHROME_PATH) return process.env.CHROME_PATH;
  const root = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  if (fs.existsSync(root)) {
    const dir = fs.readdirSync(root).find((d) => /^chromium-\d+$/.test(d));
    if (dir) return `${root}/${dir}/chrome-linux/chrome`;
  }
  return undefined; // let Playwright use its own install
}

exports.launch = async (width = 390, height = 844) => {
  const browser = await chromium.launch({
    executablePath: chromePath(),
    args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const ctx = await browser.newContext({ viewport: { width, height }, acceptDownloads: true });
  const page = await ctx.newPage();
  const logs = [];
  page.on('console', (m) => logs.push(`[${m.type()}] ${m.text()}`));
  page.on('pageerror', (e) => logs.push(`[pageerror] ${e.message}`));
  return { browser, page, logs };
};

/** Flutter builds its accessibility tree only after this placeholder is clicked. */
exports.enableSemantics = async (page) => {
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(500);
};

exports.driver = (page) => {
  const btn = (name, exact = true) => page.getByRole('button', { name, exact }).first();
  const click = async (name, exact = true, wait = 900) => {
    await exports.enableSemantics(page);
    await page.waitForTimeout(300);
    try {
      await btn(name, exact).click({ timeout: 4000 });
    } catch {
      // Flutter can leave an empty accessibility node over a button; a focused
      // button still activates from the keyboard.
      await btn(name, exact).focus();
      await page.keyboard.press('Enter');
    }
    await page.waitForTimeout(wait);
  };
  const text = () => page.evaluate(() => [...document.querySelectorAll('flt-semantics')]
    .map((e) => (e.getAttribute('aria-label') || '') + ' ' + (e.textContent || '')).join(' | '));
  /** Fills the verse editor's first two text fields. */
  const typeVerse = async (reference, body) => {
    const fields = await page.getByRole('textbox').all();
    await fields[0].click(); await page.waitForTimeout(150); await page.keyboard.type(reference);
    await fields[1].click(); await page.waitForTimeout(150); await page.keyboard.type(body);
  };
  const drag = async (x, y, dx, dy, steps = 12) => {
    await page.mouse.move(x, y); await page.mouse.down();
    for (let i = 1; i <= steps; i++) { await page.mouse.move(x + dx * i / steps, y + dy * i / steps); await page.waitForTimeout(25); }
    await page.mouse.up(); await page.waitForTimeout(500);
  };
  /** The app ships five default photos; specs that need a known photo delete them first. Ends in the photo library. */
  const clearDefaultPhotos = async () => {
    await click('Menu', false);
    await click('Photo library', false, 1500);
    for (let i = 0; i < 10; i++) {
      const photo = page.getByRole('button', { name: /^Photo \d+$/ }).first();
      if ((await photo.count()) === 0) break;
      await photo.click(); await page.waitForTimeout(900);
      await click('Delete photo', false);
      await click('Delete', true);
    }
  };
  /** Rectangles of the accessibility nodes whose label or text is [match] (a string for an exact match, or a RegExp). */
  const rects = (match) => page.evaluate(({ source, flags, exact }) => {
    const re = source === null ? null : new RegExp(source, flags);
    return [...document.querySelectorAll('flt-semantics')]
      .map((e) => ({ text: (e.getAttribute('aria-label') || e.textContent || '').trim(), role: e.getAttribute('role') || '', r: e.getBoundingClientRect() }))
      .filter((n) => (re ? re.test(n.text) : n.text === exact))
      .map((n) => ({ text: n.text, role: n.role, x: n.r.x, y: n.r.y, w: n.r.width, h: n.r.height }));
  }, typeof match === 'string' ? { source: null, flags: '', exact: match } : { source: match.source, flags: match.flags, exact: null });
  /** Labels of the buttons and chips whose top lies between the nodes labelled [from] and [to], in reading order. */
  const buttonsBetween = async (from, to) => {
    const top = (await rects(from))[0], bottom = (await rects(to))[0];
    const all = await rects(/./);
    return all
      .filter((n) => (n.role === 'button' || n.role === 'checkbox') && n.y > top.y && n.y < bottom.y)
      .sort((a, b) => a.y - b.y || a.x - b.x)
      .map((n) => n.text);
  };
  return { btn, click, text, typeVerse, drag, clearDefaultPhotos, rects, buttonsBetween };
};
