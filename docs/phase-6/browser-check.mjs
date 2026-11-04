import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';
import { writeFile } from 'node:fs/promises';

const url = process.env.PUBLIC_REPORT_URL;
if (!url) {
  throw new Error('PUBLIC_REPORT_URL is required');
}
const out = process.env.PUBLIC_REPORT_OUT ?? './samples';
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 390, height: 844 },
  deviceScaleFactor: 2,
  colorScheme: 'dark',
  locale: 'en',
});
const page = await context.newPage();
const external = [];
page.on('request', (request) => {
  const target = new URL(request.url());
  const origin = new URL(url).origin;
  if (target.origin !== origin) {
    external.push(request.url());
  }
});
const started = Date.now();
const response = await page.goto(url, { waitUntil: 'networkidle' });
const loadMs = Date.now() - started;
const html = await page.content();
const title = await page.title();
const robots = await page.locator('meta[name="robots"]').getAttribute('content');
const viewport = await page.locator('meta[name="viewport"]').getAttribute('content');
const axe = await new AxeBuilder({ page }).analyze();
await page.screenshot({ path: `${out}/public-report-dark-phone.png`, fullPage: true });
await page.keyboard.press('Tab');
const focused = await page.evaluate(() => document.activeElement?.tagName ?? '');

const ar = await context.newPage();
await ar.goto(`${url}?lang=ar`, { waitUntil: 'networkidle' });
const dir = await ar.locator('html').getAttribute('dir');
await ar.screenshot({ path: `${out}/public-report-ar-dark-phone.png`, fullPage: true });

const lightContext = await browser.newContext({
  viewport: { width: 390, height: 844 },
  deviceScaleFactor: 2,
  colorScheme: 'light',
  locale: 'en',
});
const lightPage = await lightContext.newPage();
await lightPage.goto(url, { waitUntil: 'networkidle' });
await lightPage.screenshot({
  path: `${out}/public-report-light-phone.png`,
  fullPage: true,
});
await lightContext.close();
await context.close();
await browser.close();

const result = {
  status: response?.status(),
  loadMs,
  title,
  robots,
  viewport,
  dir,
  externalRequests: external,
  focusedElement: focused,
  lightScreenshot: `${out}/public-report-light-phone.png`,
  htmlBytes: Buffer.byteLength(html),
  axeViolations: axe.violations.map((violation) => ({
    id: violation.id,
    impact: violation.impact,
    nodes: violation.nodes.length,
  })),
};
await writeFile(`${out}/public-report-browser-check.json`, JSON.stringify(result, null, 2));
console.log(JSON.stringify(result, null, 2));
if (response?.status() !== 200) process.exit(2);
if (external.length > 0) process.exit(3);
if (dir !== 'rtl') process.exit(4);
if (axe.violations.length > 0) process.exit(5);
