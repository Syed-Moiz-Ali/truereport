import { APIRequestContext, expect, test } from '@playwright/test';
import { API, APPS } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { expectHealthy, sweepScreen } from '../screens';

/**
 * Platform Admin screen sweep: every deep-linkable route boots, hydrates and
 * renders without a fatal surface. Dynamic ids come from the live API so the
 * screens show real data, not 404 states.
 */

interface Fixtures {
  itemId: string;
  workshopId: string;
  optionSetCode: string;
}

async function fixtures(request: APIRequestContext): Promise<Fixtures> {
  const session = await apiLogin(request, emailFor(APPS.platform), passwordFor(APPS.platform)!);
  const headers = { Authorization: `Bearer ${session.accessToken}` };
  const get = async (url: string) => {
    const response = await request.get(`${API}${url}`, { headers });
    expect(response.ok(), `${url}: ${response.status()}`).toBeTruthy();
    return (await response.json()) as unknown;
  };
  const asList = <T,>(value: unknown): T[] =>
    Array.isArray(value) ? (value as T[]) : ((value as { items?: T[] })?.items ?? []);

  const items = asList<{ id: string }>(await get('/api/v1/platform/master/items'));
  const workshops = asList<{ id: string; name?: string }>(
    await get('/api/v1/platform/workshops'),
  );
  const sets = asList<{ code: string }>(await get('/api/v1/platform/master/option-sets'));
  const workshop =
    workshops.find((entry) => /workshop a/i.test(entry.name ?? '')) ?? workshops[0];

  return {
    itemId: items[0]?.id ?? '00000000-0000-0000-0000-000000000000',
    workshopId: workshop?.id ?? '00000000-0000-0000-0000-000000000000',
    optionSetCode: sets[0]?.code ?? 'RESULT',
  };
}

const STATIC_ROUTES: Array<[string, string]> = [
  ['/dashboard', 'dashboard'],
  ['/workshops', 'workshops'],
  ['/workshops/new', 'workshops_new'],
  ['/workshops/details', 'workshops_details'],
  ['/checklist/items', 'checklist_items'],
  ['/checklist/items/new', 'checklist_items_new'],
  ['/checklist/categories', 'checklist_categories'],
  ['/checklist/option-sets', 'option_sets'],
  ['/checklist/health', 'checklist_health'],
  ['/configuration', 'configuration'],
  ['/configuration/statuses', 'configuration_statuses'],
  ['/configuration/enums', 'configuration_enums'],
  ['/configuration/dropdowns', 'configuration_dropdowns'],
  ['/configuration/transitions', 'configuration_transitions'],
  ['/configuration/translations', 'configuration_translations'],
  ['/reports/document-types', 'document_types'],
  ['/settings', 'settings'],
  ['/settings/languages', 'languages'],
  ['/settings/languages/es', 'language_workspace_es'],
  ['/settings/languages/es/translations', 'language_translations_es'],
  ['/settings/languages/es/manual', 'language_manual_es'],
  ['/audit-log', 'audit_log'],
  ['/master-library/categories', 'master_categories'],
  ['/master-library/option-sets', 'master_option_sets'],
  ['/master-library/new', 'master_new'],
  ['/data-catalogues', 'data_catalogues'],
];

test.describe('platform admin — screen sweep', () => {
  test('every platform route renders without a fatal error', async ({ page, request }) => {
    test.setTimeout(900_000);
    await page.setViewportSize({ width: 1440, height: 900 });
    const data = await fixtures(request);
    await uiSignIn(page, APPS.platform);

    const failures: string[] = [];
    for (const [route, name] of STATIC_ROUTES) {
      const result = await sweepScreen(page, APPS.platform, route, name);
      if (result.fatalConsole.length || result.fatalCopy) {
        failures.push(`${route}: ${result.fatalConsole.join(' | ') || 'fatal copy'}`);
      }
    }

    const dynamic: Array<[string, string]> = [
      [`/checklist/items/${data.itemId}/edit`, 'item_editor'],
      [`/workshops/${data.workshopId}`, 'workshop_detail'],
      [`/master-library/${data.itemId}/edit`, 'master_item_editor'],
    ];
    for (const [route, name] of dynamic) {
      const result = await sweepScreen(page, APPS.platform, route, name);
      if (result.fatalConsole.length || result.fatalCopy) {
        failures.push(`${route}: ${result.fatalConsole.join(' | ') || 'fatal copy'}`);
      }
    }

    test.info().annotations.push({
      type: 'screens',
      description: `${STATIC_ROUTES.length + dynamic.length} platform routes`,
    });
    expect(failures, `fatal screens:\n${failures.join('\n')}`).toEqual([]);
  });

  test('narrow viewport still renders every platform route', async ({ page, request }) => {
    test.setTimeout(600_000);
    await page.setViewportSize({ width: 768, height: 1024 });
    await fixtures(request);
    await uiSignIn(page, APPS.platform);

    const failures: string[] = [];
    for (const [route, name] of STATIC_ROUTES.slice(0, 14)) {
      const result = await sweepScreen(page, APPS.platform, route, `${name}_768`);
      if (result.fatalConsole.length || result.fatalCopy) {
        failures.push(`${route}: ${result.fatalConsole.join(' | ') || 'fatal copy'}`);
      }
    }
    expect(failures, `fatal narrow screens:\n${failures.join('\n')}`).toEqual([]);
    expectHealthy({ route: 'sweep', url: page.url(), fatalConsole: [], fatalCopy: false, screenshot: '' });
  });
});
