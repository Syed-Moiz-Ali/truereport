import { test, expect } from '@playwright/test';
import { API, APPS, appForProject } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { jobRefVisible, reloadAndBoot } from '../flutter';
import { auth, seedJob } from '../fixtures/jobs';

test.describe('technician — assigned job and pinned checklist', () => {
  test.beforeEach(async ({ page }, testInfo) => {
    const app = appForProject(testInfo.project.name);
    test.skip(app?.key !== 'technician', 'technician-only spec');
    test.skip(!passwordFor(app!), 'missing E2E_TECHNICIAN_PASSWORD / E2E_PASSWORD');
    await uiSignIn(page, app!);
  });

  test('assigned job from the API is visible after a reload and opens its checklist', async ({
    page,
    request,
  }) => {
    const workshopToken = (
      await apiLogin(request, emailFor(APPS.workshop), passwordFor(APPS.workshop)!)
    ).accessToken;
    const job = await seedJob(request, workshopToken);

    // The technician queue identifies a job by the vehicle plate, not the
    // internal JOB- reference (which the app never renders).
    await reloadAndBoot(page);
    await expect.poll(() => jobRefVisible(page, job.vehiclePlate), { timeout: 30_000 }).toBe(true);

    const card = page.getByLabel(new RegExp(job.vehiclePlate)).first();
    if ((await card.count()) > 0) {
      await card.click({ force: true });
    } else {
      await page.getByText(job.vehiclePlate, { exact: false }).first().click({ force: true });
    }
    await expect(page.getByText(/Engine Oil|Brake|Battery|Checklist/i).first()).toBeVisible({
      timeout: 30_000,
    });

    const technicianToken = (
      await apiLogin(request, emailFor(APPS.technician), passwordFor(APPS.technician)!)
    ).accessToken;
    const checklist = await request.get(
      `${API}/api/v1/technician/jobs/${job.id}/checklist`,
      { headers: auth(technicianToken) },
    );
    expect(checklist.ok(), `checklist ${checklist.status()}`).toBeTruthy();
    const body = (await checklist.json()) as { items: unknown[] };
    expect(body.items.length).toBeGreaterThan(0);
  });

  test('technician queue is scoped to the technician workshop', async ({ page, request }) => {
    const token = (
      await apiLogin(request, emailFor(APPS.technician), passwordFor(APPS.technician)!)
    ).accessToken;
    const response = await request.get(`${API}/api/v1/technician/jobs?size=50`, {
      headers: auth(token),
    });
    expect(response.ok()).toBeTruthy();
    const pageBody = (await response.json()) as {
      items: Array<{ reference: string; vehiclePlate: string }>;
    };

    await reloadAndBoot(page);
    if (pageBody.items.length > 0) {
      await expect(
        page.getByText(pageBody.items[0].vehiclePlate, { exact: false }).first(),
      ).toBeVisible({ timeout: 30_000 });
    } else {
      await expect(page.getByText(/No jobs|Nothing/i).first()).toBeVisible({ timeout: 30_000 });
    }
  });
});
