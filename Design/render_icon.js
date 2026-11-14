const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1024, height: 1024 }, deviceScaleFactor: 1 });
  await p.goto('file://' + process.argv[2]);
  await p.screenshot({ path: process.argv[3], clip: { x: 0, y: 0, width: 1024, height: 1024 } });
  await b.close();
})();
