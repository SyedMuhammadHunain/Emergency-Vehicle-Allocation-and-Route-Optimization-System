const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function testMap() {
  const outputDir = path.resolve(__dirname, '../shots/map_verification');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  console.log('[DevTools] Starting browser to inspect map display...');

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
  await page.setViewport({ width: 1400, height: 900 });

  const tileRequests = [];
  const tileResponses = [];

  page.on('console', msg => {
    console.log(`[Browser Console ${msg.type()}] ${msg.text()}`);
  });

  page.on('request', req => {
    const url = req.url();
    if (url.includes('openstreetmap.org')) {
      tileRequests.push({ url, method: req.method() });
      console.log(`[OSM Tile Request] ${url}`);
    }
  });

  page.on('response', res => {
    const url = res.url();
    if (url.includes('openstreetmap.org')) {
      tileResponses.push({ url, status: res.status() });
      console.log(`[OSM Tile Response] HTTP ${res.status()} -> ${url}`);
    }
  });

  // Pre-seed localStorage before document loads so restore() picks up Dispatcher session
  await page.evaluateOnNewDocument(() => {
    localStorage.setItem('flutter.resq_is_logged_in', JSON.stringify(true));
    localStorage.setItem('flutter.resq_demo_role', JSON.stringify('dispatcher'));
    localStorage.setItem('flutter.resq_user_name', JSON.stringify('Karachi Central Dispatcher'));
    localStorage.setItem('flutter.resq_user_email', JSON.stringify('dispatcher@resq.com'));
    localStorage.setItem('flutter.resq_user_phone', JSON.stringify('+92 321 9876543'));
    localStorage.setItem('flutter.resq_user_id', JSON.stringify('USR-DIS-001'));
  });

  console.log('[DevTools] Navigating to http://127.0.0.1:8080/#/role-shell...');
  await page.goto('http://127.0.0.1:8080/#/role-shell', { waitUntil: 'networkidle0', timeout: 30000 });

  console.log('[DevTools] Waiting 5 seconds for Flutter role shell to mount...');
  await new Promise(r => setTimeout(r, 5000));

  await page.screenshot({ path: path.join(outputDir, '04_dispatcher_dashboard.png') });
  console.log('[Screenshot] 04_dispatcher_dashboard.png captured');

  // Now click on Operations Map tab (or click in the bottom navigation / sidebar)
  // Let's inspect the semantic tree or click coordinates for 'Operations Map' tab
  // In 1400x900 viewport:
  // Let's find coordinates or click tab:
  // On Desktop/tablet role_shell uses NavigationRail or BottomNavigationBar:
  // Let's check role_shell layout in role_shell.dart!
  
  // Also test direct standalone route: /citizen/report
  console.log('[DevTools] Navigating to http://127.0.0.1:8080/#/citizen/report...');
  await page.goto('http://127.0.0.1:8080/#/citizen/report', { waitUntil: 'networkidle0', timeout: 30000 });
  console.log('[DevTools] Waiting 6 seconds for Map & OSM tiles to stream...');
  await new Promise(r => setTimeout(r, 6000));

  await page.screenshot({ path: path.join(outputDir, '05_citizen_report_map.png') });
  console.log('[Screenshot] 05_citizen_report_map.png captured');

  // Also test detail screen map: /citizen/details/EM-2026-0001
  console.log('[DevTools] Navigating to http://127.0.0.1:8080/#/citizen/details/EM-2026-0001...');
  await page.goto('http://127.0.0.1:8080/#/citizen/details/EM-2026-0001', { waitUntil: 'networkidle0', timeout: 30000 });
  await new Promise(r => setTimeout(r, 6000));

  await page.screenshot({ path: path.join(outputDir, '06_emergency_detail_map.png') });
  console.log('[Screenshot] 06_emergency_detail_map.png captured');

  console.log(`\n========================================`);
  console.log(`[DevTools Verification Summary]`);
  console.log(`Total OSM Tile Requests: ${tileRequests.length}`);
  console.log(`Total OSM Tile Responses: ${tileResponses.length}`);
  console.log(`Successful Tile Downloads (HTTP 200): ${tileResponses.filter(r => r.status === 200).length}`);
  console.log(`========================================`);

  await browser.close();
}

testMap().catch(console.error);
