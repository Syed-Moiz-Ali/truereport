import { APIRequestContext, expect, test } from '@playwright/test';
import { API } from '../apps';

/**
 * Contract sweep: every GET in the OpenAPI document must answer with a
 * non-5xx status for a normal authenticated caller. 401/403/404 are acceptable
 * (role scoping, unknown fixture ids); an unhandled 500 is a defect.
 *
 * Mutating endpoints are exercised by the flow specs, not here, so the sweep
 * never changes data.
 */

interface Fixtures {
  platform: string;
  workshop: string;
  technician: string;
  jobId: string;
  itemId: string;
  itemCode: string;
  templateVersionId: string;
  workshopId: string;
  staffId: string;
  publicToken: string;
  language: string;
}

async function login(ctx: APIRequestContext, email: string, password: string): Promise<string> {
  const response = await ctx.post(`${API}/api/v1/auth/login`, {
    data: { email, password },
  });
  expect(response.ok(), `login ${email}: ${response.status()}`).toBeTruthy();
  return ((await response.json()) as { accessToken: string }).accessToken;
}

async function buildFixtures(request: APIRequestContext): Promise<Fixtures> {
  const password = process.env.E2E_PASSWORD!;
  const platform = await login(request, 'platform@truereport.test', password);
  const workshop = await login(request, 'admin.a@truereport.test', password);
  const technician = await login(request, 'tech.a@truereport.test', password);

  const headers = (token: string) => ({ Authorization: `Bearer ${token}` });
  const json = async (url: string, token: string) => {
    const response = await request.get(`${API}${url}`, { headers: headers(token) });
    return response.ok() ? ((await response.json()) as unknown) : null;
  };

  const workshops = (await json('/api/v1/platform/workshops', platform)) as
    | { items?: Array<{ id: string }> }
    | Array<{ id: string }>
    | null;
  const workshopList = Array.isArray(workshops) ? workshops : workshops?.items ?? [];
  const workshopLogin = await request.post(`${API}/api/v1/auth/login`, {
    data: { email: 'admin.a@truereport.test', password },
  });
  const membershipWorkshop =
    workshopLogin.ok()
      ? ((await workshopLogin.json()) as {
          memberships?: Array<{ workshopId: string }>;
        }).memberships?.[0]?.workshopId
      : undefined;

  const items = (await json('/api/v1/platform/master/items', platform)) as
    | { items?: Array<{ id: string; stableCode: string }> }
    | Array<{ id: string; stableCode: string }>
    | null;
  const item = (Array.isArray(items) ? items : items?.items ?? [])[0];

  const templates = (await json('/api/v1/workshop/template-versions/available', workshop)) as
    | Array<{ versionId: string }>
    | null;

  const jobs = (await json('/api/v1/technician/jobs?size=1', technician)) as
    | { items?: Array<{ id: string; reference: string }> }
    | null;
  const job = jobs?.items?.[0];

  let itemCode = '';
  if (job) {
    const checklist = (await json(`/api/v1/technician/jobs/${job.id}/checklist`, technician)) as
      | { items?: Array<{ itemCode: string }> }
      | null;
    itemCode = checklist?.items?.[0]?.itemCode ?? '';
  }

  let publicToken = '';
  if (job) {
    const link = (await json(`/api/v1/workshop/jobs/${job.id}/public-link`, workshop)) as
      | { publicUrl?: string }
      | null;
    publicToken = (link?.publicUrl ?? '').split('/r/')[1] ?? '';
  }

  const staff = (await json('/api/v1/workshop/staff', workshop)) as
    | Array<{ userId: string }>
    | null;

  return {
    platform,
    workshop,
    technician,
    jobId: job?.id ?? '00000000-0000-0000-0000-000000000000',
    itemId: item?.id ?? '00000000-0000-0000-0000-000000000000',
    itemCode: itemCode || 'UNKNOWN-ITEM',
    templateVersionId: templates?.[0]?.versionId ?? '00000000-0000-0000-0000-000000000000',
    workshopId:
      membershipWorkshop ?? workshopList[0]?.id ?? '00000000-0000-0000-0000-000000000000',
    staffId: staff?.[0]?.userId ?? '00000000-0000-0000-0000-000000000000',
    publicToken: publicToken || 'sweep-unknown-token',
    language: 'es',
  };
}

function tokenFor(path: string, fixtures: Fixtures): string {
  if (path.startsWith('/api/v1/platform/')) return fixtures.platform;
  if (path.startsWith('/api/v1/technician/')) return fixtures.technician;
  return fixtures.workshop;
}

function resolve(path: string, fixtures: Fixtures): string {
  return path.replace(/\{([^}]+)\}/g, (_, raw: string) => {
    const name = raw.toLowerCase();
    if (name === 'jobid') return fixtures.jobId;
    if (name === 'itemid') return fixtures.itemId;
    if (name === 'itemcode') return encodeURIComponent(fixtures.itemCode);
    if (name === 'templateversionid' || name === 'versionid') return fixtures.templateVersionId;
    if (name === 'workshopid') return fixtures.workshopId;
    if (name === 'userid' || name === 'staffid') return fixtures.staffId;
    if (name === 'code' || name === 'lang' || name === 'language') return fixtures.language;
    if (name === 'type' || name === 'statustype') return 'result';
    if (name === 'token') return fixtures.publicToken;
    if (name === 'id') {
      if (path.includes('/jobs/')) return fixtures.jobId;
      if (path.includes('/items/') || path.includes('/master/')) return fixtures.itemId;
      if (path.includes('/templates/')) return fixtures.templateVersionId;
      if (path.includes('/workshops/')) return fixtures.workshopId;
      if (path.includes('/languages/')) return fixtures.language;
      return fixtures.jobId;
    }
    // Unknown identifier params: a random UUID should 404, never 500.
    return '00000000-0000-0000-0000-000000000000';
  });
}

test.describe('API sweep — every GET answers without a server error', () => {
  test('93+ GET endpoints return a non-5xx status', async ({ request }) => {
    test.setTimeout(240_000);
    const fixtures = await buildFixtures(request);

    const docs = await request.get(`${API}/v3/api-docs`);
    expect(docs.ok(), 'OpenAPI document is served in this environment').toBeTruthy();
    const spec = (await docs.json()) as {
      paths: Record<string, { get?: { parameters?: unknown[] } }>;
    };

    const failures: string[] = [];
    const statuses: Record<string, number> = {};
    let checked = 0;

    for (const [path, methods] of Object.entries(spec.paths)) {
      if (!methods.get) continue;
      const url = resolve(path, fixtures);
      const token = tokenFor(path, fixtures);
      const response = await request.get(`${API}${url}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      checked++;
      statuses[String(response.status())] = (statuses[String(response.status())] ?? 0) + 1;
      if (response.status() >= 500) {
        failures.push(`${response.status()} GET ${url}`);
      }
    }

    test.info().annotations.push({
      type: 'api-sweep',
      description: `${checked} GET endpoints; ${JSON.stringify(statuses)}`,
    });
    // eslint-disable-next-line no-console
    console.log(`API sweep: ${checked} GETs`, statuses);
    expect(failures, `5xx responses:\n${failures.join('\n')}`).toEqual([]);
  });
});
