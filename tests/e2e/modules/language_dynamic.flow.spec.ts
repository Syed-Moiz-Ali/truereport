import { test, expect } from '@playwright/test';
import { API } from '../apps';
import { APPS } from '../apps';
import { passwordFor, uiSignIn } from '../auth';
import { bootFlutterWeb } from '../flutter';

/**
 * Backend-driven language catalog.
 *
 * The language registry is a JSON manifest synchronized into `platform_languages`
 * at server start; adding a language is a backend change (manifest + restart),
 * never a Flutter rebuild. These tests pin the served contract and prove the
 * selector applies Spanish at runtime.
 */
function manifestUrl(client: string): string {
  return `${API}/api/v1/i18n/ui-messages/${client}/manifest`;
}

function bundleUrl(client: string, lang: string): string {
  return `${API}/api/v1/i18n/ui-messages/${client}/bundle?lang=${lang}`;
}

test.describe('backend-driven language catalog', () => {
  test('workshop manifest and Spanish bundle come from the backend', async ({ request }) => {
    const manifest = await request.get(manifestUrl('workshop_admin'));
    expect(manifest.ok()).toBeTruthy();
    expect(manifest.headers()['cache-control'] ?? '').toContain('no-store');

    const body = (await manifest.json()) as {
      defaultLanguage: string;
      client: string;
      namespaces: string[];
      languages: Array<{ code: string; nativeName: string }>;
    };
    expect(body.defaultLanguage).toBe('en');
    expect(body.client).toBe('workshop_admin');
    expect(body.namespaces).toEqual(['common', 'workshop_admin']);
    expect(body.languages.map((language) => language.code)).toEqual(['en', 'es']);
    expect(body.languages.find((language) => language.code === 'es')?.nativeName).toBe('Español');

    const bundle = await request.get(bundleUrl('workshop_admin', 'es'));
    expect(bundle.ok()).toBeTruthy();
    const bundleBody = (await bundle.json()) as {
      catalogs: Record<string, unknown>;
      messages: Record<string, string>;
    };
    expect(Object.keys(bundleBody.catalogs).sort()).toEqual(['common', 'workshop_admin']);
    expect(bundleBody.messages.signInTitle).toBe('Iniciar sesión');
    expect(bundleBody.messages.settingsLanguage).toBe('Idioma');
    expect(bundleBody.messages.jobsTab).toBe('Trabajos');
  });

  test('platform admin UI catalog stays English-only by design', async ({ request }) => {
    const manifest = await request.get(manifestUrl('platform_admin'));
    expect(manifest.ok()).toBeTruthy();
    const body = (await manifest.json()) as { languages: Array<{ code: string }> };
    expect(body.languages.map((language) => language.code)).toEqual(['en']);
  });

  test('technician catalog offers Spanish', async ({ request }) => {
    const manifest = await request.get(manifestUrl('technician'));
    expect(manifest.ok()).toBeTruthy();
    const body = (await manifest.json()) as { languages: Array<{ code: string }> };
    expect(body.languages.map((language) => language.code)).toEqual(['en', 'es']);
  });

  test('selecting Español changes the workshop UI and survives a reload', async ({
    page,
  }, testInfo) => {
    test.skip(testInfo.project.name !== 'workshop-admin', 'workshop UI only');
    test.skip(!passwordFor(APPS.workshop), 'missing E2E_WORKSHOP_PASSWORD / E2E_PASSWORD');

    // Each Playwright test already gets a fresh context (empty storage); an
    // addInitScript would also clear it on the reload and kill the session.
    await uiSignIn(page, APPS.workshop);

    await page.getByRole('button', { name: /Settings/i }).first().click({ force: true });
    await bootFlutterWeb(page);

    const spanish = page.getByText('Español', { exact: false }).first();
    await expect(spanish).toBeVisible({ timeout: 20_000 });
    await spanish.click({ force: true });

    await expect(page.getByText('Idioma', { exact: false }).first()).toBeVisible({
      timeout: 20_000,
    });
    await expect(page.getByText('Trabajos', { exact: false }).first()).toBeVisible();

    // The selection is persisted: it must survive a full reload. A reload may
    // land on the home route, so re-open Settings before checking its copy.
    await page.reload({ waitUntil: 'domcontentloaded' });
    await bootFlutterWeb(page);
    await expect(page.getByText('Trabajos', { exact: false }).first()).toBeVisible({
      timeout: 30_000,
    });
    await page.getByRole('button', { name: /Ajustes|Settings/i }).first().click({ force: true });
    await bootFlutterWeb(page);
    await expect(page.getByText('Idioma', { exact: false }).first()).toBeVisible({
      timeout: 20_000,
    });
  });
});
