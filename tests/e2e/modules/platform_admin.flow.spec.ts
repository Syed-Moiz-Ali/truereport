import { test, expect } from '@playwright/test';
import { API, APPS, appForProject } from '../apps';
import { apiContext, apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { bootFlutterWeb, reloadAndBoot } from '../flutter';

test.describe('platform admin — workshops and master library read real data', () => {
  test.beforeEach(async ({ page }, testInfo) => {
    const app = appForProject(testInfo.project.name);
    test.skip(app?.key !== 'platform', 'platform-only spec');
    test.skip(!passwordFor(app!), 'missing E2E_PLATFORM_PASSWORD / E2E_PASSWORD');
    await uiSignIn(page, app!);
  });

  test('workshop list matches the API', async ({ page, request }) => {
    const app = APPS.platform;
    const session = await apiLogin(request, emailFor(app), passwordFor(app)!);
    const apiResponse = await request.get(`${API}/api/v1/platform/workshops`, {
      headers: { Authorization: `Bearer ${session.accessToken}` },
    });
    expect(apiResponse.ok()).toBeTruthy();
    const workshops = (await apiResponse.json()) as Array<{ name: string }>;
    expect(workshops.length).toBeGreaterThan(0);

    await page.goto(`${app.baseURL}/workshops`);
    await bootFlutterWeb(page);
    const namedCard = page.getByLabel(new RegExp(workshops[0].name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    if ((await namedCard.count()) > 0) {
      await expect(namedCard.first()).toBeVisible({ timeout: 30_000 });
    } else {
      await expect(page.getByText(workshops[0].name, { exact: false }).first()).toBeVisible();
    }
  });

  test('master library shows the seeded checklist', async ({ page, request }) => {
    const session = await apiLogin(request, emailFor(APPS.platform), passwordFor(APPS.platform)!);
    const items = await request.get(`${API}/api/v1/platform/master/items`, {
      headers: { Authorization: `Bearer ${session.accessToken}` },
    });
    expect(items.ok()).toBeTruthy();
    const list = (await items.json()) as Array<{ stableCode: string; labelEn: string }>;
    test.skip(list.length === 0, 'database not seeded: run POST /platform/seed/default-checklist');

    await page.goto(`${APPS.platform.baseURL}/checklist/items`);
    await bootFlutterWeb(page);
    await expect(page.getByText(/Engine Oil|Brake|Battery/i).first()).toBeVisible({
      timeout: 30_000,
    });
  });

  test('language registry shows English', async ({ page }) => {
    await page.goto(`${APPS.platform.baseURL}/settings/languages`);
    await bootFlutterWeb(page);
    await expect(page.getByText(/English/i).first()).toBeVisible();
  });

  test('language screen exposes coverage for Arabic while the admin UI stays English-only', async ({
    page,
  }) => {
    // Intent (LocalizationService.allLanguages): the Platform Admin registry is
    // manifest-backed and English-only, while content coverage still reports ar.
    await page.goto(`${APPS.platform.baseURL}/settings/languages`);
    await bootFlutterWeb(page);
    await expect(page.getByText(/Translation coverage/i).first()).toBeVisible();
    await expect(page.getByText(/English/i).first()).toBeVisible();
    await expect(page.getByText(/en\s+ar|ar\b/i).first()).toBeVisible();
  });
});
