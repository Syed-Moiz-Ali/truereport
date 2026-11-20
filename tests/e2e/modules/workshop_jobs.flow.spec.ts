import { test, expect } from '@playwright/test';
import { API, APPS, appForProject } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { bootFlutterWeb, reloadAndBoot } from '../flutter';
import { auth, cancelJobViaApi, seedJob } from '../fixtures/jobs';

test.describe('workshop admin — job visibility and consent write path', () => {
  test.beforeEach(async ({ page }, testInfo) => {
    const app = appForProject(testInfo.project.name);
    test.skip(app?.key !== 'workshop', 'workshop-only spec');
    test.skip(!passwordFor(app!), 'missing E2E_WORKSHOP_PASSWORD / E2E_PASSWORD');
    await uiSignIn(page, app!);
  });

  test('API-created job appears in the queue and opens', async ({ page, request }) => {
    const token = (await apiLogin(request, emailFor(APPS.workshop), passwordFor(APPS.workshop)!))
      .accessToken;
    const job = await seedJob(request, token);

    await reloadAndBoot(page);
    await page.getByRole('button', { name: /^Jobs$/ }).first().click({ force: true });
    await expect(page.getByText(job.reference, { exact: false }).first()).toBeVisible({
      timeout: 30_000,
    });

    await page.getByText(job.reference, { exact: false }).first().click({ force: true });
    await expect(page.getByText(/Review & publication/i).first()).toBeVisible({
      timeout: 30_000,
    });

    await cancelJobViaApi(request, token, job.id);
  });

  test('consent can be granted from the job detail and is read back by the API', async ({
    page,
    request,
  }) => {
    const token = (await apiLogin(request, emailFor(APPS.workshop), passwordFor(APPS.workshop)!))
      .accessToken;
    const job = await seedJob(request, token, { consentGranted: false });

    await reloadAndBoot(page);
    await page.getByRole('button', { name: /^Jobs$/ }).first().click({ force: true });
    await page.getByText(job.reference, { exact: false }).first().click({ force: true });

    await expect(page.getByText(/Consent missing/i).first()).toBeVisible({ timeout: 30_000 });
    await page.getByRole('button', { name: /Granted/i }).first().click({ force: true });

    await expect
      .poll(
        async () => {
          const response = await request.get(`${API}/api/v1/workshop/jobs/${job.id}`, {
            headers: auth(token),
          });
          if (!response.ok()) return null;
          return (await response.json()).consentGranted as boolean;
        },
        { timeout: 15_000, intervals: [500, 1000, 2000] },
      )
      .toBe(true);

    await cancelJobViaApi(request, token, job.id);
  });

  test('job counts API matches the queue header after reload', async ({ page, request }) => {
    const token = (await apiLogin(request, emailFor(APPS.workshop), passwordFor(APPS.workshop)!))
      .accessToken;
    const counts = await request.get(`${API}/api/v1/workshop/jobs/counts`, {
      headers: auth(token),
    });
    expect(counts.ok()).toBeTruthy();
    const body = (await counts.json()) as { total: number };

    await reloadAndBoot(page);
    // The status breakdown is on the workshop Overview, not inside the Jobs tab.
    const group = page.getByText(/Jobs by status/i).first();
    await expect(group).toBeVisible({ timeout: 30_000 });
    await expect(page.getByText(String(body.total), { exact: false }).first()).toBeVisible();
  });
});
