import {
  APIRequestContext,
  Locator,
  Page,
  request as pwRequest,
  expect,
} from '@playwright/test';
import { API, AppConfig } from './apps';
import { bootFlutterWeb } from './flutter';

export interface Session {
  accessToken: string;
  refreshToken: string;
  user: { id: string; email: string; displayName: string };
  memberships: Array<{ workshopId: string; workshopName: string; role: string }>;
}

export function passwordFor(app: AppConfig): string | undefined {
  return (
    process.env[app.passwordEnv] ||
    process.env.E2E_PASSWORD ||
    process.env.E2E_SHARED_PASSWORD
  );
}

export function emailFor(app: AppConfig): string {
  return process.env[app.emailEnv] || app.email;
}

export async function apiLogin(
  ctx: APIRequestContext,
  email: string,
  password: string,
): Promise<Session> {
  const response = await ctx.post(`${API}/api/v1/auth/login`, {
    data: { email, password },
  });
  expect(response.ok(), `login ${email}: ${response.status()} ${await response.text()}`).toBeTruthy();
  return (await response.json()) as Session;
}

export async function apiContext(): Promise<APIRequestContext> {
  return pwRequest.newContext({ baseURL: API });
}

/**
 * Flutter web semantics inputs live in the engine, so the DOM value is not a
 * reliable read-back. Click, give the focus transition a moment, then type.
 * The caller retries the whole sign-in when a character is dropped.
 */
async function fillField(page: Page, field: Locator, value: string): Promise<void> {
  await expect(field).toBeVisible({ timeout: 30_000 });
  await field.click({ force: true });
  await page.waitForTimeout(250);
  await page.keyboard.type(value, { delay: 20 });
}

export async function uiSignIn(page: Page, app: AppConfig): Promise<void> {
  const password = passwordFor(app);
  if (!password) {
    throw new Error(
      `Missing ${app.passwordEnv} (or E2E_PASSWORD). The harness never stores passwords.`,
    );
  }
  const home = new RegExp(app.homePath.replace('/', '\\/'));

  for (let attempt = 0; attempt < 2; attempt++) {
    await bootFlutterWeb(page, `${app.baseURL}${app.signInPath}`);

    // Flutter semantics vary per app: platform/workshop use "Email" and
    // "Password", technician uses "Email\nEmail" and "Password\nPassword".
    await fillField(page, page.getByLabel(/email/i).first(), emailFor(app));
    await fillField(page, page.getByLabel(/password/i).first(), password);

    const signIn = page
      .getByRole('button', { name: /sign in/i })
      .filter({ hasNotText: /show|hide/i })
      .first();
    await expect(signIn).toBeEnabled({ timeout: 15_000 });
    await signIn.click({ force: true });

    try {
      await expect(page).toHaveURL(home, { timeout: 45_000 });
      await bootFlutterWeb(page);
      return;
    } catch (error) {
      if (attempt === 1) throw error;
      // A dropped character in the first pass is the known flake; reload cleanly.
      await page.waitForTimeout(1_000);
    }
  }
}
