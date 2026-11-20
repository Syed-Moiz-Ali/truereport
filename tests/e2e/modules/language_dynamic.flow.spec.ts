import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { API, APPS } from '../apps';
import { passwordFor, uiSignIn } from '../auth';
import { bootFlutterWeb } from '../flutter';

const root = process.cwd();

/** Both the source tree and the compiled classpath the server actually reads. */
function i18nRoots(): string[] {
  return [
    path.join(root, 'server/src/main/resources/i18n'),
    path.join(root, 'server/target/classes/i18n'),
  ].filter((dir) => fs.existsSync(path.join(dir, 'languages.json')));
}

function readJson<T>(file: string): T {
  return JSON.parse(fs.readFileSync(file, 'utf8')) as T;
}

function writeJson(file: string, value: unknown): void {
  fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n', 'utf8');
}

const SPANISH = {
  code: 'es',
  name: 'Spanish',
  nativeName: 'Español',
  direction: 'ltr',
};

const SCOPES = ['common', 'platform_admin', 'workshop_admin', 'technician'];

/**
 * Adds or removes Spanish in the single language registry plus the per-scope
 * catalogs, which is the only thing a backend language change is allowed to be.
 */
function setSpanish(enabled: boolean): void {
  for (const dir of i18nRoots()) {
    const registryPath = path.join(dir, 'languages.json');
    const registry = readJson<{
      defaultLanguage: string;
      languages: Array<{ code: string }>;
    }>(registryPath);

    if (enabled) {
      if (!registry.languages.some((language) => language.code === 'es')) {
        registry.languages.push(SPANISH);
      }
    } else {
      registry.languages = registry.languages.filter(
        (language) => language.code !== 'es',
      );
    }
    writeJson(registryPath, registry);

    for (const scope of SCOPES) {
      const active = path.join(dir, scope, 'es.json');
      const parked = path.join(dir, scope, 'es.json.disabled');
      if (!enabled && fs.existsSync(active)) fs.renameSync(active, parked);
      if (enabled && fs.existsSync(parked)) fs.renameSync(parked, active);
    }
  }
}



test.describe('backend-driven language catalog', () => {
  test.afterAll(() => setSpanish(true));

  test('English only until Spanish is added, then Spanish appears and applies', async ({
    page,
    request,
  }, testInfo) => {
    test.skip(testInfo.project.name !== 'workshop-admin', 'workshop UI only');
    test.skip(
      !passwordFor(APPS.workshop),
      'missing E2E_WORKSHOP_PASSWORD / E2E_PASSWORD',
    );

    const api = (client: string) =>
      `${API}/api/v1/i18n/ui-messages/${client}`;

    // 0. A previously persisted language must not leak into this run.
    await page.addInitScript(() => window.localStorage.clear());

    // 1. Spanish removed at the backend: every client advertises English only.
    setSpanish(false);
    for (const client of ['platform_admin', 'workshop_admin', 'technician']) {
      const response = await request.get(`${api(client)}/manifest`);
      expect(response.ok()).toBeTruthy();
      expect(response.headers()['cache-control'] ?? '').toContain('no-store');
      const body = await response.json();
      expect(body.languages.map((l: { code: string }) => l.code)).toEqual(['en']);
    }

    // 2. The workshop selector shows English only.
    await uiSignIn(page, APPS.workshop);
    await page.getByRole('button', { name: /^Settings$/ }).first().click({
      force: true,
    });
    await bootFlutterWeb(page);
    await expect(page.getByText('English', { exact: false }).first()).toBeVisible();
    await expect(page.getByText('Español', { exact: false })).toHaveCount(0);

    // 3. Spanish added at the backend only — no Flutter rebuild.
    setSpanish(true);
    const manifest = await request.get(`${api('workshop_admin')}/manifest`);
    expect(manifest.ok()).toBeTruthy();
    const manifestBody = await manifest.json();
    expect(
      manifestBody.languages.map((l: { code: string }) => l.code),
    ).toEqual(['en', 'es']);

    const bundle = await request.get(
      `${api('workshop_admin')}/bundle?lang=es`,
    );
    expect(bundle.ok()).toBeTruthy();
    const bundleBody = await bundle.json();
    expect(Object.keys(bundleBody.catalogs)).toEqual([
      'common',
      'workshop_admin',
    ]);
    expect(bundleBody.messages.signInTitle).toBe('Iniciar sesión');

    // 4. Re-open Settings so the manifest is fetched again.
    await page.reload({ waitUntil: 'domcontentloaded' });
    await bootFlutterWeb(page);
    if (page.url().includes('/signin')) await uiSignIn(page, APPS.workshop);
    await page.getByRole('button', { name: /^Settings$/ }).first().click({
      force: true,
    });
    await bootFlutterWeb(page);
    const spanish = page.getByText('Español', { exact: false }).first();
    await expect(spanish).toBeVisible({ timeout: 20_000 });

    // 5. Selecting it changes the UI text, still with no rebuild.
    await spanish.click({ force: true });
    await expect(
      page.getByText('Idioma', { exact: false }).first(),
    ).toBeVisible({ timeout: 20_000 });
    await expect(
      page.getByText('Trabajos', { exact: false }).first(),
    ).toBeVisible();
  });
});
