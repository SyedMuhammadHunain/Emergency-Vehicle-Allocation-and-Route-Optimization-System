const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function testUrl(name, url, outputDir, options = {}) {
  console.log(`\n========================================`);
  console.log(`[DevTools Audit] Testing: ${name} (${url})`);
  console.log(`========================================`);

  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/google-chrome-stable',
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });

  const consoleMessages = [];
  const networkRequests = [];
  const networkFailures = [];

  page.on('console', msg => {
    const entry = {
      type: msg.type(),
      text: msg.text(),
      location: msg.location(),
    };
    consoleMessages.push(entry);
    console.log(`[Browser Console ${msg.type().toUpperCase()}] ${msg.text()}`);
  });

  page.on('pageerror', error => {
    console.error(`[Page Error] ${error.message}`);
    consoleMessages.push({ type: 'pageerror', text: error.message });
  });

  page.on('request', req => {
    networkRequests.push({
      url: req.url(),
      method: req.method(),
      resourceType: req.resourceType(),
    });
  });

  page.on('requestfailed', req => {
    const failure = req.failure();
    const entry = {
      url: req.url(),
      errorText: failure ? failure.errorText : 'Unknown error',
    };
    networkFailures.push(entry);
    console.warn(`[Network Request Failed] ${req.url()} (${entry.errorText})`);
  });

  page.on('response', res => {
    if (res.status() >= 400) {
      console.warn(`[HTTP Error ${res.status()}] ${res.url()}`);
    }
  });

  const startTime = Date.now();
  try {
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
  } catch (err) {
    console.warn(`[Navigation Warning] ${err.message}. Continuing with inspection...`);
  }
  const loadTimeMs = Date.now() - startTime;

  if (options.waitMs) {
    await new Promise(r => setTimeout(r, options.waitMs));
  }

  // Performance metrics via DevTools
  const metrics = await page.metrics();
  const perfTiming = JSON.parse(
    await page.evaluate(() => JSON.stringify(window.performance.timing))
  );

  // Accessibility / Document checks
  const title = await page.title();
  const bodyTextLength = await page.evaluate(() => document.body.innerText.length);

  // Screenshot
  const screenshotPath = path.join(outputDir, `${name}_screenshot.png`);
  await page.screenshot({ path: screenshotPath, fullPage: false });
  console.log(`[Screenshot Saved] ${screenshotPath}`);

  await browser.close();

  const report = {
    name,
    url,
    title,
    loadTimeMs,
    bodyTextLength,
    consoleSummary: {
      total: consoleMessages.length,
      errors: consoleMessages.filter(m => m.type === 'error' || m.type === 'pageerror'),
      warnings: consoleMessages.filter(m => m.type === 'warning' || m.type === 'warn'),
      logs: consoleMessages.filter(m => m.type === 'log' || m.type === 'info'),
    },
    networkSummary: {
      totalRequests: networkRequests.length,
      failures: networkFailures,
      osmTileRequests: networkRequests.filter(r => r.url.includes('tile.openstreetmap.org')),
    },
    metrics,
    screenshotPath,
  };

  return report;
}

async function run() {
  const outputDir = path.resolve(__dirname, '../shots/browser_audit');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const reports = [];

  // 1. Audit Landing Page
  try {
    const landingReport = await testUrl(
      'landing_page',
      'http://127.0.0.1:8081',
      outputDir,
      { waitMs: 2000 }
    );
    reports.push(landingReport);
  } catch (e) {
    console.error('Failed testing landing page:', e);
  }

  // 2. Audit Flutter Web App
  try {
    const flutterReport = await testUrl(
      'flutter_web_app',
      'http://127.0.0.1:8080',
      outputDir,
      { waitMs: 5000 }
    );
    reports.push(flutterReport);
  } catch (e) {
    console.error('Failed testing flutter web app:', e);
  }

  const reportFile = path.join(outputDir, 'audit_report.json');
  fs.writeFileSync(reportFile, JSON.stringify(reports, null, 2));
  console.log(`\nAudit complete! Full JSON report written to: ${reportFile}`);
}

run().catch(console.error);
