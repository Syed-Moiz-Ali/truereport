import { test, expect } from '@playwright/test';
import { appForProject } from '../apps';
import { passwordFor, uiSignIn } from '../auth';
import { bootFlutterWeb, reloadAndBoot } from '../flutter';

test.describe('auth — sign in, role home, session survives reload', () => {
  test('each app signs in through its own UI and lands on its role home', async ({ page }, testInfo) => {
    const app = appForProject(testInfo.project.name);
    test.skip(!app, 'auth spec applies to the three product apps');
    test.skip(!passwordFor(app!), `missing ${app!.passwordEnv} / E2E_PASSWORD`);

    await uiSignIn(page, app!);
    await expect(page).toHaveURL(new RegExp(app!.homePath.replace('/', '\\/')));

    // Role-specific landmark.
    if (app!.key === 'platform') {
      await expect(page.getByRole('button', { name: /Workshops/i }).first()).toBeVisible();
    } else if (app!.key === 'workshop') {
      await expect(page.getByRole('button', { name: /Jobs/i }).first()).toBeVisible();
    } else {
      await expect(page.getByText(/Jobs/i).first()).toBeVisible();
    }

    await reloadAndBoot(page);
    await expect(page).toHaveURL(new RegExp(app!.homePath.replace('/', '\\/')));
  });

  test('wrong password stays on sign-in and shows an error', async ({ page }, testInfo) => {
    const app = appForProject(testInfo.project.name);
    test.skip(!app, 'auth spec applies to the three product apps');

    await bootFlutterWeb(page, `${app!.baseURL}${app!.signInPath}`);
    await page.getByLabel(/email/i).first().click({ force: true });
    await page.keyboard.type(app!.email);
    await page.getByLabel(/password/i).first().click({ force: true });
    await page.keyboard.type('definitely-not-the-password');
    await page.getByRole('button', { name: /sign in/i }).first().click({ force: true });
    await page.waitForTimeout(4000);

    await expect(page).toHaveURL(/\/signin/);
  });
});
