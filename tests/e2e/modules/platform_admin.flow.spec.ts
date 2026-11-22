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

  test('language registry lists the manifest languages', async ({ page }) => {
    await page.goto(`${APPS.platform.baseURL}/settings/languages`);
    await bootFlutterWeb(page);
    await expect(page.getByText(/Translation coverage|Languages/i).first()).toBeVisible();
    await expect(page.getByText(/English/i).first()).toBeVisible();
    await expect(page.getByText(/Español|Spanish/i).first()).toBeVisible();
  });

  test('admin adds a language, opens manual translations, retires it', async ({
    page,
    request,
  }) => {
    // Sign-in + three Flutter boots exceed the suite's 2-minute default.
    test.setTimeout(240_000);
    const session = await apiLogin(request, emailFor(APPS.platform), passwordFor(APPS.platform)!);
    const headers = { Authorization: `Bearer ${session.accessToken}` };
    // Idempotent: a previous run may have left `de` live.
    await request.delete(`${API}/api/v1/platform/i18n/languages/de`, { headers });

    await page.goto(`${APPS.platform.baseURL}/settings/languages`);
    await bootFlutterWeb(page);
    await page.getByRole('button', { name: /^Add language$/i }).first().click({ force: true });
    await bootFlutterWeb(page);

    await page.getByLabel(/Language code/i).first().click({ force: true });
    await page.keyboard.type('de');
    await page.getByLabel(/Native name/i).first().click({ force: true });
    await page.keyboard.type('Deutsch');

    await page.getByRole('button', { name: /^Add language$/i }).last().click({ force: true });
    await expect(page).toHaveURL(/\/settings\/languages\/de/, { timeout: 30_000 });
    await bootFlutterWeb(page);
    await expect(page.getByText(/Deutsch/).first()).toBeVisible({ timeout: 30_000 });

    // New language has no rows yet: the manual screen lists canonical English sources.
    await page.getByRole('button', { name: /Add translations manually/i }).first().click({
      force: true,
    });
    await bootFlutterWeb(page);
    await expect(page.getByRole('heading', { name: /Manual translations/i }).first()).toBeVisible({
      timeout: 30_000,
    });
    await expect(page.getByText(/English source/i).first()).toBeVisible({ timeout: 20_000 });

    await page.goto(`${APPS.platform.baseURL}/settings/languages/de`);
    await bootFlutterWeb(page);
    await page.getByRole('button', { name: /Retire language/i }).first().click({ force: true });
    await bootFlutterWeb(page);
    await page.getByRole('button', { name: /^Retire language$/i }).last().click({ force: true });

    await expect(page).toHaveURL(/\/settings\/languages$/, { timeout: 30_000 });
    await expect(page.getByText(/Deutsch/)).toHaveCount(0);
  });

  test('content review surfaces the machine Spanish queue', async ({ page }) => {
    // Platform Admin is English-only; ?lang selects the language being reviewed.
    await page.goto(`${APPS.platform.baseURL}/configuration/translations?lang=es`);
    await bootFlutterWeb(page);

    await expect(page.getByRole('heading', { name: /Content review/i }).first()).toBeVisible({
      timeout: 30_000,
    });
    // The review selector lists content languages, not the English-only UI registry.
    // The label now sits above the dropdown, so it is a separate text node.
    await expect(page.getByText('Language', { exact: true }).first()).toBeVisible();
    await expect(page.getByRole('button', { name: /Español/i }).first()).toBeVisible();
    await expect(page.getByText(/Pending: \d+/).first()).toBeVisible();
    await expect(page.getByRole('button', { name: /^Approve$/i }).first()).toBeVisible({
      timeout: 30_000,
    });

    // Real machine output from the backfill, not placeholder [[es]] text.
    await expect(
      page.getByRole('group', { name: /Suspensión, dirección y bajo cuerpo/i }).first(),
    ).toBeVisible({ timeout: 30_000 });
    await expect(
      page.getByRole('group', { name: /Provider libretranslate/i }).first(),
    ).toBeVisible();
  });

  test('item editor opens with the served reference data', async ({ page, request }) => {
    const session = await apiLogin(request, emailFor(APPS.platform), passwordFor(APPS.platform)!);
    const headers = { Authorization: `Bearer ${session.accessToken}` };
    const itemsResponse = await request.get(`${API}/api/v1/platform/master/items`, { headers });
    expect(itemsResponse.ok()).toBeTruthy();
    const items = (await itemsResponse.json()) as Array<{ id: string }>;
    test.skip(items.length === 0, 'database not seeded');

    await page.goto(`${APPS.platform.baseURL}/checklist/items/${items[0].id}/edit`);
    await bootFlutterWeb(page);
    await expect(page.getByText(/Step \d+ of \d+/i).first()).toBeVisible({ timeout: 30_000 });
    await expect(page.getByText(/Basics/i).first()).toBeVisible();
  });

  test('a 401 on a protected call leaves the page for sign-in', async ({ page }) => {
    let hits = 0;
    await page.route('**/api/v1/platform/i18n/languages*', async (route) => {
      hits++;
      await route.fulfill({
        status: 401,
        contentType: 'application/problem+json',
        body: JSON.stringify({
          type: 'https://truereport.example/problems/unauthenticated',
          title: 'Unauthorized',
          status: 401,
          detail: 'Request denied',
          instance: '/api/v1/platform/i18n/languages',
          properties: { code: 'UNAUTHENTICATED', messageKey: 'error.unauthenticated' },
        }),
      });
    });

    await page.goto(`${APPS.platform.baseURL}/checklist/categories`);
    await bootFlutterWeb(page);
    await expect(page).toHaveURL(/\/signin/, { timeout: 30_000 });
    expect(hits).toBeGreaterThan(0);
  });

  test('option sets merge statuses, enums and checklist into one screen', async ({ page }) => {
    await page.goto(`${APPS.platform.baseURL}/checklist/option-sets`);
    await bootFlutterWeb(page);
    await expect(page.getByRole('button', { name: /^Checklist/ }).first()).toBeVisible({
      timeout: 30_000,
    });
    await expect(page.getByText(/Issue Type|ISSUE_TYPE/i).first()).toBeVisible();
    await expect(page.getByRole('button', { name: /^Add option set$/i })).toHaveCount(0);

    await page.getByRole('button', { name: /^Statuses/ }).first().click({ force: true });
    await bootFlutterWeb(page);
    await expect(page.getByText(/Job Status|JOB_STATUS/i).first()).toBeVisible({
      timeout: 30_000,
    });
    await expect(page.getByText(/Backend-defined/i).first()).toBeVisible();

    await page.getByRole('button', { name: /^Enums/ }).first().click({ force: true });
    await bootFlutterWeb(page);
    await expect(page.getByText(/Role|ROLE/).first()).toBeVisible({ timeout: 30_000 });
    await expect(page.getByText(/Severity|SEVERITY/).first()).toBeVisible();
    await expect(page.getByText(/Backend-defined/i).first()).toBeVisible();
  });

  test('legacy taxonomy routes redirect into the merged tabs', async ({ page }) => {
    await page.goto(`${APPS.platform.baseURL}/configuration/statuses`);
    await bootFlutterWeb(page);
    await expect(page).toHaveURL(/\/checklist\/option-sets\?tab=statuses/, { timeout: 30_000 });

    await page.goto(`${APPS.platform.baseURL}/configuration/enums`);
    await bootFlutterWeb(page);
    await expect(page).toHaveURL(/\/checklist\/option-sets\?tab=enums/, { timeout: 30_000 });

    await page.goto(`${APPS.platform.baseURL}/configuration/transitions`);
    await bootFlutterWeb(page);
    await expect(page).toHaveURL(/\/configuration\/transitions/, { timeout: 30_000 });
  });

  test('Spanish content has no missing canonical fields', async ({ page }) => {
    await page.goto(`${APPS.platform.baseURL}/settings/languages/es/manual`);
    await bootFlutterWeb(page);
    await page.getByRole('button', { name: /^Missing\b/ }).first().click({ force: true });
    await page.waitForTimeout(1200);
    await expect(
      page.getByText(/Nothing missing for this language/i).first(),
    ).toBeVisible({ timeout: 20_000 });
  });

  test('manual translations edit an existing field and restore it', async ({
    page,
    request,
  }) => {
    test.setTimeout(180_000);
    const session = await apiLogin(request, emailFor(APPS.platform), passwordFor(APPS.platform)!);
    const headers = { Authorization: `Bearer ${session.accessToken}` };

    const unitsResponse = await request.get(
      `${API}/api/v1/platform/i18n/content/units?lang=es&query=Caliper&size=50`,
      { headers },
    );
    expect(unitsResponse.ok()).toBeTruthy();
    const unitsBody = (await unitsResponse.json()) as {
      items: Array<{
        entityType: string;
        entityId: string;
        field: string;
        sourceText: string;
        text: string | null;
      }>;
    };
    const unit =
      unitsBody.items.find(
        (item) => item.entityType === 'OPTION_VALUE' && item.sourceText === 'Caliper',
      ) ?? unitsBody.items[0];
    test.skip(!unit || !unit.text, 'no translated unit to edit');
    const original = unit!.text!;
    const suffix = ` E2E ${Date.now().toString().slice(-6)}`;

    try {
      await page.goto(`${APPS.platform.baseURL}/settings/languages/es/manual`);
      await bootFlutterWeb(page);
      await expect(page.getByText('Manual translations').first()).toBeVisible({ timeout: 30_000 });

      const search = page
        .getByRole('textbox', { name: /Search source or translation/i })
        .first();
      await search.click({ force: true });
      await page.keyboard.type(unit!.sourceText);
      await expect(page.getByText(unit!.sourceText, { exact: false }).first()).toBeVisible({
        timeout: 20_000,
      });
      await expect(page.getByText(/Page \d+ of \d+/).first()).toBeVisible({ timeout: 20_000 });
      await page.waitForTimeout(1500);

      const rowInput = page.getByRole('textbox', { name: /^Translation$/ }).first();
      const viewport = page.viewportSize() ?? { width: 1280, height: 720 };
      for (let attempt = 0; attempt < 8; attempt++) {
        const box = await rowInput.boundingBox();
        if (box && box.y > 0 && box.y + box.height < viewport.height - 20) break;
        await page.mouse.move(900, 400);
        await page.mouse.wheel(0, 350);
        await page.waitForTimeout(300);
      }
      const box = await rowInput.boundingBox();
      expect(box, 'translation input must be in the viewport').not.toBeNull();
      await page.mouse.click(box!.x + box!.width / 2, box!.y + box!.height / 2);
      await page.waitForTimeout(600);
      // Focus lands on the field; append rather than clear, then restore via API.
      await page.keyboard.press('End');
      await page.keyboard.type(suffix, { delay: 25 });
      await page.waitForTimeout(600);
      expect(await search.inputValue()).toBe(unit!.sourceText);

      const save = page.getByRole('button', { name: /^Save$/i }).first();
      await expect
        .poll(async () => (await save.getAttribute('aria-disabled')) !== 'true', {
          timeout: 10_000,
        })
        .toBe(true);
      await save.click({ force: true });

      await expect
        .poll(
          async () => {
            const response = await request.get(
              `${API}/api/v1/platform/i18n/content/units?lang=es&query=${encodeURIComponent(unit!.sourceText)}&entityType=OPTION_VALUE&size=50`,
              { headers },
            );
            if (!response.ok()) return null;
            const body = (await response.json()) as {
              items: Array<{ entityId: string; field: string; text: string | null }>;
            };
            return body.items.find(
              (item) => item.entityId === unit!.entityId && item.field === unit!.field,
            )?.text ?? null;
          },
          { timeout: 30_000, intervals: [500, 1000, 2000] },
        )
        .toBe(`${original}${suffix}`);
    } finally {
      // Leave the content exactly as it was.
      await request.put(
        `${API}/api/v1/platform/i18n/content/${unit!.entityType}/${unit!.entityId}/${unit!.field}?lang=es`,
        { headers, data: { body: original } },
      );
    }
  });
});
