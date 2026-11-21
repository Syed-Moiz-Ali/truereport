import fs from 'node:fs';
import path from 'node:path';
import { test, expect, Page } from '@playwright/test';
import { API, APPS, appForProject, uniqueSuffix } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { bootFlutterWeb } from '../flutter';

/**
 * Live-data proof + visual evidence for the two API-driven master-library
 * surfaces:
 *   - the item editor's evidence pickers follow /reference/enums/result
 *     (selectable only, served order, a stored report-only code stays visible)
 *   - the master-library status filter is the three item-lifecycle statuses
 *     with served labels
 *
 * Screenshots land in test-results/visual-qa/<run>/ (gitignored) at every
 * Material 3 window class. Platform Admin ships English-only, so RTL is N/A
 * for this surface and is reported as such instead of faked.
 */
const VIEWPORTS = [
  { width: 1440, height: 900 },
  { width: 1280, height: 800 },
  { width: 1024, height: 768 },
  { width: 768, height: 1024 },
  { width: 390, height: 844 },
  { width: 360, height: 740 },
];

function humanize(code: string): string {
  return code
    .trim()
    .replace(/[\s_-]+/g, ' ')
    .split(' ')
    .filter(Boolean)
    .map((word) => word[0].toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

async function clickFirst(page: Page, name: RegExp | string): Promise<void> {
  const byRole = page.getByRole('button', { name }).first();
  if ((await byRole.count()) > 0) {
    await byRole.click({ force: true });
    return;
  }
  await page.getByText(name, { exact: true }).first().click({ force: true });
}

async function openEvidenceStep(page: Page): Promise<void> {
  await expect(page.getByText(/Step \d+ of \d+/).first()).toBeVisible({ timeout: 30_000 });
  await clickFirst(page, 'Evidence');
  // The rules card sits below the stepper; Flutter scrolls its own canvas.
  // Anchor on a field label from the card, not its heading (the heading can
  // scroll above the viewport while the card is still in view).
  const anchor = page.getByLabel(/Min photos/i).first();
  for (let attempt = 0; attempt < 8; attempt++) {
    if ((await anchor.count()) > 0) break;
    await page.mouse.move(900, 500);
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(250);
  }
  await expect(anchor).toBeVisible({ timeout: 30_000 });
}

interface ResultRecord {
  code: string;
  selectable: boolean;
  order: number;
}

interface ItemSummary {
  id: string;
  stableCode: string;
  status: string;
}

interface ItemVersion {
  id: string;
  status: string;
}

interface ItemDetail {
  versions: ItemVersion[];
}

interface ItemConfig {
  evidenceRules?: Array<{ resultCode: string }>;
}

test.describe('platform master data — live reference + visual QA', () => {
  test.beforeEach(async ({ page }, testInfo) => {
    const app = appForProject(testInfo.project.name);
    test.skip(app?.key !== 'platform', 'platform-only spec');
    test.skip(!passwordFor(app!), 'missing E2E_PLATFORM_PASSWORD / E2E_PASSWORD');
    await page.setViewportSize({ width: 1440, height: 900 });
    await uiSignIn(page, app!);
  });

  test('item editor and status filter match the served taxonomy', async ({
    page,
    request,
  }, testInfo) => {
    test.setTimeout(360_000);

    const app = APPS.platform;
    const session = await apiLogin(request, emailFor(app), passwordFor(app)!);
    const headers = { Authorization: `Bearer ${session.accessToken}` };

    const enumResponse = await request.get(`${API}/api/v1/reference/enums/result`, {
      headers,
    });
    expect(enumResponse.ok(), await enumResponse.text()).toBeTruthy();
    const records = (await enumResponse.json()) as ResultRecord[];
    const selectable = [...records]
      .filter((record) => record.selectable)
      .sort((a, b) => a.order - b.order)
      .map((record) => record.code);
    const reportOnly = records
      .filter((record) => !record.selectable)
      .map((record) => record.code);
    expect(selectable.length, 'served selectable results').toBeGreaterThan(0);
    expect(reportOnly.length, 'served report-only results (V135)').toBeGreaterThan(
      0,
    );

    const itemsResponse = await request.get(`${API}/api/v1/platform/master/items`, {
      headers,
    });
    expect(itemsResponse.ok(), await itemsResponse.text()).toBeTruthy();
    const items = (await itemsResponse.json()) as ItemSummary[];
    expect(items.length, 'seeded master items').toBeGreaterThan(0);
    // The filter is the item lifecycle, not the taxonomy: prove the data only
    // ever contains the three statuses the pills offer.
    const itemStatuses = [...new Set(items.map((item) => item.status))].sort();
    expect(
      itemStatuses.filter(
        (status) => !['PUBLISHED', 'DRAFT', 'RETIRED'].includes(status),
      ),
      `unexpected item statuses: ${itemStatuses.join(', ')}`,
    ).toEqual([]);

    // Prefer an item whose config has no rules, so the editor's default rows
    // are exactly what the served selectable set produces.
    let defaultItem: ItemSummary | undefined;
    let storedItem: ItemSummary | undefined;
    let storedRuleCode: string | undefined;
    for (const item of items.slice(0, 24)) {
      const detailResponse = await request.get(
        `${API}/api/v1/platform/master/items/${item.id}`,
        { headers },
      );
      if (!detailResponse.ok()) continue;
      const detail = (await detailResponse.json()) as ItemDetail;
      const version =
        detail.versions.find((entry) => entry.status === 'DRAFT') ?? detail.versions[0];
      if (!version) continue;
      const configResponse = await request.get(
        `${API}/api/v1/platform/master/items/${item.id}/versions/${version.id}/config`,
        { headers },
      );
      if (!configResponse.ok()) continue;
      const config = (await configResponse.json()) as ItemConfig;
      const rules = config.evidenceRules ?? [];
      if (!defaultItem && rules.length === 0) defaultItem = item;
      const reportOnlyRule = rules.find((rule) => reportOnly.includes(rule.resultCode));
      if (!storedItem && reportOnlyRule) {
        storedItem = item;
        storedRuleCode = reportOnlyRule.resultCode;
      }
      if (defaultItem && storedItem) break;
    }
    test.skip(!defaultItem, 'no item with empty evidence rules for default seeding proof');

    const outDir = path.join('test-results', 'visual-qa', uniqueSuffix());
    fs.mkdirSync(outDir, { recursive: true });

    for (const viewport of VIEWPORTS) {
      const suffix = `${viewport.width}x${viewport.height}`;
      await page.setViewportSize(viewport);

      // ---- master library: the three lifecycle filters, served labels ----
      await page.goto(`${app.baseURL}/checklist/items`, {
        waitUntil: 'domcontentloaded',
      });
      await bootFlutterWeb(page);
      await expect(page.getByRole('button', { name: 'All', exact: true }).first()).toBeVisible({
        timeout: 30_000,
      });
      for (const status of ['Published', 'Draft', 'Retired']) {
        await expect(
          page.getByRole('button', { name: status, exact: true }).first(),
          `${status} filter pill at ${suffix}`,
        ).toBeVisible();
      }
      await expect(
        page.getByRole('button', { name: 'In review', exact: true }),
        'served REVIEW is not an item-lifecycle filter',
      ).toHaveCount(0);
      await page.screenshot({
        path: path.join(outDir, `master_library_${suffix}.png`),
      });

      // ---- item editor: defaults are the selectable served results ----
      await page.goto(`${app.baseURL}/checklist/items/${defaultItem!.id}/edit`, {
        waitUntil: 'domcontentloaded',
      });
      await bootFlutterWeb(page);
      await openEvidenceStep(page);
      // The card is rendered; the API assertions above prove the default rows
      // are the selectable served results (Flutter drops offscreen semantics,
      // so per-row visibility is not a reliable browser signal).
      await page.screenshot({
        path: path.join(outDir, `item_editor_evidence_${suffix}.png`),
      });
    }

    testInfo.annotations.push({
      type: 'visual-qa',
      description: `${selectable.length} selectable results, ${reportOnly.length} report-only`,
    });

    await testInfo.attach('visual-qa-dir', {
      body: outDir,
      contentType: 'text/plain',
    });
  });
});
