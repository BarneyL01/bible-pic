// Runs every spec in specs/ against build/web.
//   flutter build web --release --no-web-resources-cdn --base-href /app/
//   cd e2e && npm install && node run.js [name-filter]
// Set E2E_BASE if the build used a different --base-href (e.g. /bible-pic/).
const path = require('path');
const fs = require('fs');
const makeImages = require('./images');
const serve = require('./serve');

(async () => {
  const root = path.resolve(__dirname, '../build/web');
  if (!fs.existsSync(path.join(root, 'index.html'))) {
    console.error('build/web is missing. Build with --base-href /app/ first (see e2e/run.js).');
    process.exit(2);
  }
  const tmp = path.join(__dirname, 'tmp');
  makeImages(tmp);
  const { server, url } = await serve(root, process.env.E2E_BASE || '/app/');
  let failed = 0;
  const ctx = {
    url, tmp,
    check: (name, ok, detail = '') => { console.log(`${ok ? 'PASS' : 'FAIL'} ${name} ${detail}`); if (!ok) failed++; },
  };
  const only = process.argv[2];
  for (const f of fs.readdirSync(path.join(__dirname, 'specs')).sort()) {
    if (only && !f.includes(only)) continue;
    console.log(`\n== ${f}`);
    try { await require(path.join(__dirname, 'specs', f))(ctx); }
    catch (e) { console.log(`FAIL ${f} threw: ${e.message}`); failed++; }
  }
  server.close();
  console.log(failed ? `\n${failed} check(s) failed` : '\nall checks passed');
  process.exit(failed ? 1 : 0);
})();
