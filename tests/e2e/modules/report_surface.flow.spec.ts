import { APIRequestContext, expect, test } from '@playwright/test';
import { API, APPS } from '../apps';
import { apiLogin, emailFor, passwordFor, uiSignIn } from '../auth';
import { expectText } from '../flutter';

interface PublishedJob {
  id: string;
  reference: string;
  customerName: string;
  preferredLanguage?: string | null;
}

async function latestPublishedJob(
  request: APIRequestContext,
): Promise<PublishedJob> {
  const session = await apiLogin(
    request,
    emailFor(APPS.workshop),
    passwordFor(APPS.workshop)!,
  );
  const response = await request.get(
    `${API}/api/v1/workshop/jobs?status=PUBLISHED&page=0&size=1`,
    { headers: { Authorization: `Bearer ${session.accessToken}` } },
  );
  expect(response.ok(), `published jobs: ${response.status()}`).toBeTruthy();
  const body = (await response.json()) as {
    items?: PublishedJob[];
    content?: PublishedJob[];
  };
  const job = body.items?.[0] ?? body.content?.[0];
  expect(job, 'the report surface needs one published job').toBeTruthy();
  return job!;
}

test.describe('workshop admin — report and delivery surface', () => {
  test('published job opens the report, the send sheet and the documents list', async ({
    page,
    request,
  }) => {
    const job = await latestPublishedJob(request);

    await uiSignIn(page, APPS.workshop);
    await page.getByRole('button', { name: /^Jobs$/ }).first().click({ force: true });
    // The queue is long and the reference wraps inside its cell, so narrow to
    // the published tab and click the customer name (unique per seeded job).
    await page
      .getByRole('button', { name: /^Published\b/i })
      .first()
      .click({ force: true });
    await page.getByText(job.customerName, { exact: false }).first().click({
      force: true,
    });
    await expect(page.getByText(/JOB-[A-Z0-9]+/).first()).toBeVisible({
      timeout: 20_000,
    });

    // The report/documents actions sit in the Review & publication card, which
    // is below the fold at 1280x720; scroll before reading its semantics.
    await page.mouse.move(960, 520);
    await page.mouse.wheel(0, 700);
    await page.waitForTimeout(400);

    // ---- report page: reachable, with a real PDF and the distribution stub ----
    await page.getByRole('button', { name: /^Report$/ }).first().click({ force: true });
    await expect(page.getByRole('button', { name: /Download PDF/i }).first())
      .toBeEnabled({ timeout: 30_000 });
    await page.mouse.move(640, 480);
    await page.mouse.wheel(0, 900);
    await expectText(page, /Distribution/i);

    // ---- send sheet: languages come from the registry, not a hardcoded pair ----
    const send = page.getByRole('button', { name: /Send report/i }).first();
    await expect(send).toBeVisible({ timeout: 20_000 });
    await send.click({ force: true });
    await expectText(page, /Send report/i);
    await expectText(page, /Español/i);
    await expect(page.getByText(/Arabic|العربية/i)).toHaveCount(0);

    // Dismiss the sheet by tapping the barrier, then leave the report.
    await page.mouse.click(8, 8);
    await page.getByRole('button', { name: /^Back$/ }).first().click({ force: true });

    // ---- documents page: reachable for the same job ----
    await page.getByRole('button', { name: /^Documents$/ }).first().click({ force: true });
    await expectText(page, /Documents/i);
    await expect(page.getByText(job.reference, { exact: false }).first()).toBeVisible({
      timeout: 20_000,
    });
  });
});
