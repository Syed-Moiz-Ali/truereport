import { APIRequestContext, expect, test } from '@playwright/test';
import { API, APPS } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { expectHealthy, sweepScreen } from '../screens';

interface JobFixture {
  jobId: string;
  itemCode: string;
}

async function assignedJob(request: APIRequestContext): Promise<JobFixture> {
  const session = await apiLogin(
    request,
    emailFor(APPS.technician),
    passwordFor(APPS.technician)!,
  );
  const headers = { Authorization: `Bearer ${session.accessToken}` };
  const jobs = await request.get(`${API}/api/v1/technician/jobs?size=1`, { headers });
  expect(jobs.ok(), `technician jobs: ${jobs.status()}`).toBeTruthy();
  const body = (await jobs.json()) as { items?: Array<{ id: string }> };
  const jobId = body.items?.[0]?.id;
  expect(jobId, 'the technician needs one assigned job for the screen sweep').toBeTruthy();

  const checklist = await request.get(`${API}/api/v1/technician/jobs/${jobId}/checklist`, {
    headers,
  });
  expect(checklist.ok()).toBeTruthy();
  const items = (await checklist.json()) as { items?: Array<{ itemCode: string }> };
  return {
    jobId: jobId!,
    itemCode: items.items?.[0]?.itemCode ?? 'UNKNOWN-ITEM',
  };
}

test.describe('technician — screen sweep', () => {
  test('every technician route renders at phone width', async ({ page, request }) => {
    test.setTimeout(300_000);
    await page.setViewportSize({ width: 390, height: 844 });
    const fixture = await assignedJob(request);
    await uiSignIn(page, APPS.technician);

    const routes: Array<[string, string]> = [
      ['/jobs', 'jobs'],
      ['/sync', 'sync'],
      ['/profile', 'profile'],
      [`/jobs/${fixture.jobId}`, 'inspection_hub'],
      [
        `/jobs/${fixture.jobId}/items/${encodeURIComponent(fixture.itemCode)}`,
        'inspection_item',
      ],
      [`/jobs/${fixture.jobId}/summary`, 'summary'],
      [`/jobs/${fixture.jobId}/signature`, 'signature'],
      [`/jobs/${fixture.jobId}/completed`, 'completed'],
      ['/unauthorized', 'unauthorized'],
    ];

    const failures: string[] = [];
    for (const [route, name] of routes) {
      const result = await sweepScreen(page, APPS.technician, route, name);
      if (result.fatalConsole.length || result.fatalCopy) {
        failures.push(`${route}: ${result.fatalConsole.join(' | ') || 'fatal copy'}`);
      }
    }

    test.info().annotations.push({
      type: 'screens',
      description: `${routes.length} technician routes at 390x844`,
    });
    expect(failures, `fatal technician screens:\n${failures.join('\n')}`).toEqual([]);
  });

  test('tablet width keeps the technician queue usable', async ({ page, request }) => {
    test.setTimeout(120_000);
    await page.setViewportSize({ width: 768, height: 1024 });
    await assignedJob(request);
    await uiSignIn(page, APPS.technician);
    const result = await sweepScreen(page, APPS.technician, '/jobs', 'jobs_768');
    expectHealthy(result);
  });
});
