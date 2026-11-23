// Compact route sweep: boots every platform route (and the technician static
// routes) in a real Chromium, enables Flutter semantics, and reports fatal
// console errors / fatal copy / HTTP failures. No tracing, no videos.
import { chromium } from '@playwright/test';
import { writeFileSync } from 'node:fs';

const API = 'http://localhost:8080';
const PASSWORD = process.env.QA_PASSWORD;
if (!PASSWORD) { console.error('QA_PASSWORD is required.'); process.exit(2); }
const FATAL = [
  /Unhandled Exception/i, /RenderFlex overflowed/i, /is not a subtype of type/i,
  /NoSuchMethodError/i, /RangeError/i, /setState\(\) called after dispose/i,
];
const results = [];

async function boot(page) {
  await page.locator('flutter-view, flt-glass-pane').first().waitFor({ timeout: 90_000 });
  const ph = page.locator('flt-semantics-placeholder');
  if (await ph.count()) { await ph.first().evaluate((el) => el.click()); }
  await page.waitForTimeout(1200);
}

async function signIn(page, base, email) {
  await page.goto(`${base}/signin`, { waitUntil: 'domcontentloaded' });
  await boot(page);
  const mail = page.getByLabel(/email/i).first();
  await mail.click({ force: true });
  await page.waitForTimeout(300);
  await page.keyboard.type(email, { delay: 35 });
  const pass = page.getByLabel(/password/i).first();
  await pass.click({ force: true });
  await page.waitForTimeout(300);
  await page.keyboard.type(PASSWORD, { delay: 45 });
  await page.getByRole('button', { name: /sign in/i }).first().click({ force: true });
  await page.waitForTimeout(3000);
  await boot(page);
}

async function sweep(page, base, routes) {
  for (const [path, name] of routes) {
    const errors = [];
    const listener = (m) => { if (m.type() === 'error' && FATAL.some((r) => r.test(m.text()))) errors.push(m.text().slice(0, 200)); };
    page.on('console', listener);
    let status = null; let body = '';
    try {
      const resp = await page.goto(`${base}${path}`, { waitUntil: 'domcontentloaded', timeout: 60_000 });
      status = resp?.status() ?? null;
      await boot(page);
      await page.waitForTimeout(700);
      body = await page.evaluate(() => document.body.innerText);
    } catch (e) {
      errors.push(`navigation: ${String(e).slice(0, 160)}`);
    }
    page.off('console', listener);
    const fatalCopy = /Something went wrong|Unhandled Exception|RenderFlex overflowed/i.test(body);
    results.push({ app: base.includes('5301') ? 'platform' : 'technician', route: path, name, status, fatalConsole: errors, fatalCopy, chars: body.length });
    console.log(`${errors.length || fatalCopy ? 'FAIL' : 'PASS'} ${base}${path} status=${status} chars=${body.length}${errors.length ? ' errors=' + errors.join(' | ') : ''}${fatalCopy ? ' FATAL_COPY' : ''}`);
  }
}

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await ctx.newPage();
await signIn(page, 'http://127.0.0.1:5301', 'platform@truereport.test');

// resolve ids from the API
const login = await fetch(`${API}/api/v1/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'platform@truereport.test', password: PASSWORD }) }).then((r) => r.json());
const H = { Authorization: `Bearer ${login.accessToken}` };
const items = await fetch(`${API}/api/v1/platform/master/items`, { headers: H }).then((r) => r.json());
const itemId = (Array.isArray(items) ? items : items.items)[0].id;
const workshops = await fetch(`${API}/api/v1/platform/workshops`, { headers: H }).then((r) => r.json());
const wsId = workshops[0].id;

const platformRoutes = [
  ['/dashboard', 'dashboard'], ['/workshops', 'workshops'], ['/workshops/new', 'workshops_new'],
  [`/workshops/${wsId}`, 'workshops_detail'], [`/checklist/items/${itemId}/edit`, 'item_edit'],
  ['/checklist/items', 'items'], ['/checklist/items/new', 'item_new'], ['/checklist/categories', 'categories'],
  ['/checklist/option-sets', 'option_sets'], ['/checklist/health', 'health'],
  ['/configuration/transitions', 'transitions'], ['/configuration/translations', 'translations_review'],
  ['/reports/document-types', 'document_types'], ['/settings', 'settings'],
  ['/settings/languages', 'languages'], ['/settings/languages/es', 'language_ws'],
  ['/settings/languages/es/translations', 'translations'], ['/settings/languages/es/manual', 'manual'],
  ['/audit-log', 'audit_log'], ['/master-library', 'legacy_master'], ['/config-health', 'legacy_health'],
  ['/data-catalogues', 'legacy_catalogues'], ['/document-types', 'legacy_doc_types'],
];
await sweep(page, 'http://127.0.0.1:5301', platformRoutes);

// technician static routes (tech login)
await signIn(page, 'http://127.0.0.1:5303', 'tech.a@truereport.test');
await sweep(page, 'http://127.0.0.1:5303', [['/jobs', 'tech_jobs'], ['/profile', 'tech_profile'], ['/sync', 'tech_sync']]);

await browser.close();
const summary = {
  generatedAt: new Date().toISOString(),
  total: results.length,
  pass: results.filter((r) => !r.fatalConsole.length && !r.fatalCopy).length,
  fail: results.filter((r) => r.fatalConsole.length || r.fatalCopy).length,
  results,
};
writeFileSync('qa_audit/evidence/route-sweep.json', JSON.stringify(summary, null, 2));
console.log(`ROUTE_SWEEP total=${summary.total} pass=${summary.pass} fail=${summary.fail}`);
