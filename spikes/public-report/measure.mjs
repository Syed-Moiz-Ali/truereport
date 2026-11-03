import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';
import { startServer } from './static-server.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(__dirname, 'results');
fs.mkdirSync(outDir, { recursive: true });

const servers = await Promise.all([
  startServer(path.join(__dirname, 'ssr'), 8091),
  startServer(path.join(__dirname, 'flutter', 'build', 'web'), 8092),
  startServer(path.join(__dirname, 'flutter', 'build', 'web-semantics'), 8093),
]);

const variants = [
  { name: 'ssr', url: 'http://127.0.0.1:8091/' },
  { name: 'flutter', url: 'http://127.0.0.1:8092/' },
  { name: 'flutter_semantics', url: 'http://127.0.0.1:8093/' },
];

const browser = await chromium.launch({ headless: true });

async function run(variant, profile, runIndex) {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36',
  });
  const page = await context.newPage();
  const responses = [];
  page.on('response', async (r) => {
    try {
      const h = await r.allHeaders();
      responses.push({ url: r.url(), status: r.status(), bytes: Number(h['content-length'] || 0), type: h['content-type'] || '' });
    } catch (_) {}
  });
  await page.addInitScript(() => {
    window.__perf = { fcp: 0, lcp: 0, cls: 0 };
    try {
      new PerformanceObserver((list) => {
        for (const e of list.getEntries()) if (e.name === 'first-contentful-paint') window.__perf.fcp = e.startTime;
      }).observe({ type: 'paint', buffered: true });
      new PerformanceObserver((list) => {
        for (const e of list.getEntries()) window.__perf.lcp = Math.max(window.__perf.lcp, e.startTime);
      }).observe({ type: 'largest-contentful-paint', buffered: true });
      new PerformanceObserver((list) => {
        for (const e of list.getEntries()) if (!e.hadRecentInput) window.__perf.cls += e.value;
      }).observe({ type: 'layout-shift', buffered: true });
    } catch (_) {}
  });

  const client = await context.newCDPSession(page);
  await client.send('Network.enable');
  await client.send('Network.setCacheDisabled', { cacheDisabled: true });
  const down = profile === '4g' ? 1_600_000 / 8 : 700_000 / 8;
  const up = profile === '4g' ? 750_000 / 8 : 300_000 / 8;
  const latency = profile === '4g' ? 150 : 400;
  await client.send('Network.emulateNetworkConditions', {
    offline: false, latency, downloadThroughput: down, uploadThroughput: up,
  });
  await client.send('Emulation.setCPUThrottlingRate', { rate: 4 });
  try { await client.send('Performance.enable'); } catch (_) {}

  const started = Date.now();
  let ready = false;
  let error = null;
  try {
    await page.goto(variant.url, { waitUntil: 'load', timeout: 180000 });
    await page.waitForFunction(() => document.body?.getAttribute('data-report-ready') === 'true', null, { timeout: 180000 });
    ready = true;
    await page.waitForLoadState('networkidle', { timeout: 180000 }).catch(() => {});
    await page.waitForTimeout(1200);
  } catch (e) {
    error = String(e.message || e);
  }
  const wallMs = Date.now() - started;

  const data = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0];
    const resources = performance.getEntriesByType('resource').map(r => ({
      name: r.name,
      type: r.initiatorType,
      transferSize: r.transferSize || 0,
      encodedBodySize: r.encodedBodySize || 0,
      decodedBodySize: r.decodedBodySize || 0,
      duration: r.duration,
    }));
    const sum = (key) => resources.reduce((a, r) => a + (r[key] || 0), 0);
    const byType = {};
    for (const r of resources) {
      byType[r.type] = byType[r.type] || { count: 0, transferSize: 0, decodedBodySize: 0 };
      byType[r.type].count++;
      byType[r.type].transferSize += r.transferSize;
      byType[r.type].decodedBodySize += r.decodedBodySize;
    }
    const meta = Array.from(document.querySelectorAll('meta')).map(m => ({
      name: m.getAttribute('name'),
      property: m.getAttribute('property'),
      content: m.getAttribute('content'),
    })).filter(m => m.name || m.property);
    return {
      title: document.title,
      nav: nav ? {
        domContentLoaded: nav.domContentLoadedEventEnd,
        loadEventEnd: nav.loadEventEnd,
        transferSize: nav.transferSize || 0,
        encodedBodySize: nav.encodedBodySize || 0,
      } : null,
      resourceCount: resources.length,
      transferSize: sum('transferSize'),
      encodedBodySize: sum('encodedBodySize'),
      decodedBodySize: sum('decodedBodySize'),
      byType,
      perf: window.__perf,
      innerTextLength: document.body?.innerText?.trim().length || 0,
      textContentLength: document.body?.textContent?.trim().length || 0,
      canvasCount: document.querySelectorAll('canvas').length,
      shadow: (() => { const host = document.querySelector('flt-glass-pane'); const root = host && host.shadowRoot; return { host: !!host, canvases: root ? root.querySelectorAll('canvas').length : 0, semantics: root ? root.querySelectorAll('flt-semantics').length : 0, text: root ? (root.textContent || '').trim().length : 0 }; })(),
      semanticsNodes: document.querySelectorAll('flt-semantics').length,
      headings: document.querySelectorAll('h1,h2,h3').length,
      paragraphs: document.querySelectorAll('p').length,
      tableRows: document.querySelectorAll('tr').length,
      meta,
      url: location.href,
    };
  }).catch(e => ({ error: String(e.message || e) }));

  let axe = { violations: [], error: null };
  try {
    axe = await new AxeBuilder({ page }).analyze();
  } catch (e) {
    axe = { violations: [], error: String(e.message || e) };
  }

  let cdpMetrics = {};
  try {
    const m = await client.send('Performance.getMetrics');
    for (const x of m.metrics) cdpMetrics[x.name] = x.value;
  } catch (_) {}

  const shot = path.join(outDir, `${variant.name}-${profile}-${runIndex}.png`);
  try { await page.screenshot({ path: shot, fullPage: false }); } catch (_) {}

  await context.close();
  return {
    variant: variant.name,
    profile,
    run: runIndex,
    ready,
    error,
    wallMs,
    ...data,
    serverBytes: responses.reduce((a, r) => a + r.bytes, 0),
    responseCount: responses.length,
    responses,
    axeViolations: axe.violations.map(v => ({ id: v.id, impact: v.impact, nodes: v.nodes.length, help: v.help })),
    axeError: axe.error,
    cdpMetrics: {
      JSHeapUsedSize: cdpMetrics.JSHeapUsedSize,
      Nodes: cdpMetrics.Nodes,
      LayoutCount: cdpMetrics.LayoutCount,
      RecalcStyleCount: cdpMetrics.RecalcStyleCount,
    },
    screenshot: shot,
  };
}

const all = [];
for (const variant of variants) {
  for (let i = 1; i <= 3; i++) {
    const r = await run(variant, '4g', i);
    all.push(r);
    console.log(`${variant.name} 4g #${i}: ready=${r.ready} wall=${r.wallMs}ms transfer=${Math.round(r.transferSize / 1024)}KB decoded=${Math.round(r.decodedBodySize / 1024)}KB innerText=${r.innerTextLength} axe=${r.axeViolations.length}`);
  }
  const r = await run(variant, '3g', 1);
  all.push(r);
  console.log(`${variant.name} 3g #1: ready=${r.ready} wall=${r.wallMs}ms transfer=${Math.round(r.transferSize / 1024)}KB decoded=${Math.round(r.decodedBodySize / 1024)}KB innerText=${r.innerTextLength} axe=${r.axeViolations.length}`);
}

fs.writeFileSync(path.join(outDir, 'results.json'), JSON.stringify(all, null, 2), 'utf8');

function median(nums) {
  const a = [...nums].sort((x, y) => x - y);
  return a[Math.floor(a.length / 2)];
}
const summary = variants.map(v => {
  const runs = all.filter(r => r.variant === v.name && r.profile === '4g' && r.ready);
  const vals = (key) => median(runs.map(r => r[key]));
  return {
    variant: v.name,
    runs: runs.length,
    medianWallMs: vals('wallMs'),
    medianTransferKB: Math.round(vals('serverBytes') / 1024),
    medianPerfTransferKB: Math.round(vals('transferSize') / 1024),
    medianDecodedKB: Math.round(vals('decodedBodySize') / 1024),
    medianFcpMs: Math.round(vals('perf')?.fcp || 0),
    medianLcpMs: Math.round(vals('perf')?.lcp || 0),
    medianInnerText: vals('innerTextLength'),
    medianCanvas: vals('canvasCount'),
    medianTableRows: vals('tableRows'),
    axeViolationIds: [...new Set(runs.flatMap(r => r.axeViolations.map(x => x.id)))],
  };
});
fs.writeFileSync(path.join(outDir, 'summary.json'), JSON.stringify(summary, null, 2), 'utf8');
console.log(JSON.stringify(summary, null, 2));

await browser.close();
await Promise.all(servers.map(s => new Promise(resolve => s.close(resolve))));
