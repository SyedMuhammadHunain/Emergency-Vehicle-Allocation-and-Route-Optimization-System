const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');
const http = require('http');

async function runMapVerification() {
  const outputDir = path.resolve(__dirname, '../shots/map_verification');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  console.log('[DevTools Map Verification] Starting headless Chrome...');

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
  await page.setViewport({ width: 1366, height: 900 });

  const tileRequests = [];
  const networkErrors = [];
  const consoleLogs = [];

  page.on('console', msg => {
    consoleLogs.push({ type: msg.type(), text: msg.text() });
    console.log(`[Browser Console ${msg.type()}] ${msg.text()}`);
  });

  page.on('request', req => {
    const url = req.url();
    if (url.includes('openstreetmap.org') || url.includes('.png')) {
      tileRequests.push({ url, method: req.method() });
      console.log(`[Network Tile Request] ${url}`);
    }
  });

  page.on('response', res => {
    const url = res.url();
    if (url.includes('openstreetmap.org')) {
      console.log(`[Network Tile Response] Status: ${res.status()} for ${url}`);
    }
    if (res.status() >= 400) {
      networkErrors.push({ url, status: res.status() });
      console.warn(`[HTTP Error ${res.status()}] ${url}`);
    }
  });

  page.on('pageerror', err => {
    console.error(`[Page Error] ${err.message}`);
  });

  console.log('[DevTools] Navigating to http://127.0.0.1:8080...');
  await page.goto('http://127.0.0.1:8080/#/login', { waitUntil: 'networkidle0', timeout: 30000 });

  // Wait for Flutter Web initialization
  console.log('[DevTools] Waiting for Flutter app to settle...');
  await new Promise(r => setTimeout(r, 4000));

  await page.screenshot({ path: path.join(outputDir, '01_login_screen.png') });
  console.log('[DevTools Screenshot] 01_login_screen.png captured');

  // Perform login or evaluate localStorage/session to navigate directly to map
  // Let's log in using form inputs or session injection:
  console.log('[DevTools] Logging in as Dispatcher to access Operations Map...');
  
  // Try finding input fields or clicking
  try {
    // In Flutter web with semantics / canvas, we can interact or navigate via URL / hash:
    await page.evaluate(() => {
      // In Flutter Web GoRouter, setting window.location.hash or localStorage
      try {
        localStorage.setItem('flutter.resq_is_logged_in', 'true');
        localStorage.setItem('flutter.resq_user_role', 'dispatcher');
        localStorage.setItem('flutter.resq_user_name', 'Karachi Central Dispatcher');
        localStorage.setItem('flutter.resq_user_email', 'dispatcher@resq.com');
      } catch (e) {
        console.warn('localStorage error', e);
      }
    });

    await page.goto('http://127.0.0.1:8080/#/role-shell', { waitUntil: 'networkidle0', timeout: 30000 });
    await new Promise(r => setTimeout(r, 4000));
    await page.screenshot({ path: path.join(outputDir, '02_role_shell.png') });
    console.log('[DevTools Screenshot] 02_role_shell.png captured');
  } catch (err) {
    console.warn('[DevTools] Navigation via hash exception:', err);
  }

  // Check DOM structure and flt-semantics or canvas
  const domInfo = await page.evaluate(() => {
    const canvases = document.querySelectorAll('canvas').length;
    const fltSemantics = document.querySelectorAll('flt-semantics, flt-glass-pane').length;
    const images = Array.from(document.querySelectorAll('img')).map(img => img.src);
    return {
      canvases,
      fltSemantics,
      imagesCount: images.length,
      sampleImages: images.slice(0, 5),
      bodyChildren: document.body.children.length,
    };
  });

  console.log('[DevTools DOM Info]', JSON.stringify(domInfo, null, 2));

  // Let's also test direct map rendering or standalone report map route if protected
  console.log('[DevTools] Navigating to http://127.0.0.1:8080/#/citizen/report...');
  await page.goto('http://127.0.0.1:8080/#/citizen/report', { waitUntil: 'networkidle0', timeout: 30000 });
  await new Promise(r => setTimeout(r, 5000));
  await page.screenshot({ path: path.join(outputDir, '03_report_map_screen.png') });
  console.log('[DevTools Screenshot] 03_report_map_screen.png captured');

  const finalTileRequests = tileRequests.filter(r => r.url.includes('openstreetmap.org'));
  console.log(`\n========================================`);
  console.log(`[DevTools Result] Total OSM Tile Requests: ${finalTileRequests.length}`);
  console.log(`========================================`);

  await browser.close();

  const summary = {
    domInfo,
    osmTileRequestsCount: finalTileRequests.length,
    osmTileRequestsSample: finalTileRequests.slice(0, 10),
    networkErrors,
    screenshots: [
      path.join(outputDir, '01_login_screen.png'),
      path.join(outputDir, '02_role_shell.png'),
      path.join(outputDir, '03_report_map_screen.png'),
    ],
  };

  fs.writeFileSync(path.join(outputDir, 'summary.json'), JSON.stringify(summary, null, 2));
  console.log('[DevTools] Summary saved to', path.join(outputDir, 'summary.json'));
}

runMapVerification().catch(console.error);
