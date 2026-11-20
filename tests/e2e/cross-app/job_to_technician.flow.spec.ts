import { test, expect } from '@playwright/test';
import { API, APPS } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { jobRefVisible, reloadAndBoot } from '../flutter';
import { seedJob } from '../fixtures/jobs';

/**
 * X4: Workshop Admin creates and assigns a job; the Technician must observe it
 * on the next fetch. No realtime channel exists, so the contract is "visible
 * within 10 s of a reload" and we poll with a reload, never sleep.
 */
test.describe('cross-app — workshop job reaches the technician', () => {
  test('API-created assigned job appears in the technician app within 10s', async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== 'technician', 'cross-app runs once');

    const workshopToken = (
      await apiLogin(request, emailFor(APPS.workshop), passwordFor(APPS.workshop)!)
    ).accessToken;
    const job = await seedJob(request, workshopToken);
    expect(job.assignedTechnicianId, 'seeded job must be assigned to a technician').toBeTruthy();
    expect(job.status).toBe('ASSIGNED');

    const technicianToken = (
      await apiLogin(request, emailFor(APPS.technician), passwordFor(APPS.technician)!)
    ).accessToken;
    const apiJobs = await request.get(`${API}/api/v1/technician/jobs?size=50`, {
      headers: { Authorization: `Bearer ${technicianToken}` },
    });
    expect(apiJobs.ok()).toBeTruthy();
    const apiBody = (await apiJobs.json()) as { items: Array<{ reference: string }> };
    expect(apiBody.items.some((item) => item.reference === job.reference)).toBe(true);

    // Observer app: technician.
    await page.goto(`${APPS.technician.baseURL}/signin`);
    await uiSignIn(page, APPS.technician);

    await expect
      .poll(
        async () => {
          await reloadAndBoot(page);
          return await jobRefVisible(page, job.reference);
        },
        { timeout: 10_000, intervals: [500, 1000, 2000] },
      )
      .toBe(true);

    // Verify at the API that the technician can open the same job.
    const detail = await request.get(`${API}/api/v1/technician/jobs/${job.id}`, {
      headers: { Authorization: `Bearer ${technicianToken}` },
    });
    expect(detail.ok()).toBeTruthy();
  });
});
