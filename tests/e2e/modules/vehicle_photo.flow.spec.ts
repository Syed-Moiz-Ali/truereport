import { expect, test } from '@playwright/test';
import { API, APPS } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { expectText, reloadAndBoot } from '../flutter';
import { auth, seedJob } from '../fixtures/jobs';

/**
 * Vehicle cover photo: the technician is asked for one photo before the
 * inspection starts, it is uploaded through init → PUT → complete, and the API
 * reports it READY afterwards.
 */
test.describe('technician — vehicle cover photo before inspection', () => {
  test('the hub blocks until a vehicle photo is uploaded', async ({ page, request }) => {
    test.setTimeout(240_000);
    await page.setViewportSize({ width: 390, height: 844 });

    const workshopToken = (
      await apiLogin(request, emailFor(APPS.workshop), passwordFor(APPS.workshop)!)
    ).accessToken;
    const job = await seedJob(request, workshopToken);

    await uiSignIn(page, APPS.technician);
    await page.goto(`${APPS.technician.baseURL}/jobs/${job.id}`, { waitUntil: 'domcontentloaded' });
    await reloadAndBoot(page);

    // No photo and nothing completed: the gate must block the deck.
    await expectText(page, /Report cover photo/i);
    await expect(page.getByText(/front three-quarter/i).first()).toBeVisible({
      timeout: 30_000,
    });

    // Gallery opens the browser file chooser; the app compresses and uploads.
    const chooserPromise = page.waitForEvent('filechooser', { timeout: 20_000 });
    await page.getByRole('button', { name: /^Gallery$/i }).first().click({ force: true });
    const chooser = await chooserPromise;
    await chooser.setFiles('tests/e2e/fixtures/vehicle-photo.png');

    // The deck replaces the gate once the upload completes; its header shows
    // the vehicle plate, which the gate does not.
    await expect(page.getByText(job.vehiclePlate, { exact: false }).first()).toBeVisible({
      timeout: 60_000,
    });

    const technicianToken = (
      await apiLogin(request, emailFor(APPS.technician), passwordFor(APPS.technician)!)
    ).accessToken;
    await expect
      .poll(
        async () => {
          const response = await request.get(
            `${API}/api/v1/technician/jobs/${job.id}/vehicle-photo`,
            { headers: auth(technicianToken) },
          );
          if (!response.ok()) return null;
          return ((await response.json()) as { status: string }).status;
        },
        { timeout: 30_000, intervals: [500, 1000, 2000] },
      )
      .toBe('READY');

    const photo = await request.get(`${API}/api/v1/technician/jobs/${job.id}/vehicle-photo/content`, {
      headers: auth(technicianToken),
    });
    expect(photo.ok()).toBeTruthy();
    const bytes = await photo.body();
    expect(bytes.subarray(0, 4).toString('hex')).toBe('89504e47');
  });
});
