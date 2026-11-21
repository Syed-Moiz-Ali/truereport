import { ConsoleMessage, expect, test } from '@playwright/test';
import { APPS } from '../apps';
import { uiSignIn } from '../auth';
import { bootFlutterWeb, expectText } from '../flutter';

/**
 * Workshop Admin is a shell with in-page sections (no deep links), so the sweep
 * clicks each section and the job-detail surfaces, capturing a screenshot per
 * stop and failing on a fatal client error.
 */

const FATAL_CONSOLE = [
  /Unhandled Exception/i,
  /RenderFlex overflowed/i,
  /is not a subtype of type/i,
  /NoSuchMethodError/i,
  /RangeError/i,
  /type 'Null' is not a subtype/i,
];

test.describe('workshop admin — screen sweep', () => {
  test('every shell section and job surface renders at 1280', async ({ page }) => {
    test.setTimeout(300_000);
    await page.setViewportSize({ width: 1280, height: 800 });

    const fatal: string[] = [];
    const listener = (message: ConsoleMessage) => {
      if (message.type() !== 'error') return;
      const text = message.text();
      if (FATAL_CONSOLE.some((pattern) => pattern.test(text))) {
        fatal.push(text.slice(0, 300));
      }
    };
    page.on('console', listener);

    const shot = async (name: string) => {
      await page.screenshot({
        path: `test-results/screens/workshop/${name}.png`,
        fullPage: false,
      });
    };
    // Pushed screens can hide the shell rail; reload the shell between
    // secondary surfaces instead of guessing at each page's back affordance.
    const resetShell = async () => {
      await page.goto(`${APPS.workshop.baseURL}/workshop`, { waitUntil: 'domcontentloaded' });
      await bootFlutterWeb(page);
      await page.waitForTimeout(800);
    };

    await uiSignIn(page, APPS.workshop);
    await shot('dashboard');

    for (const [label, name] of [
      ['Jobs', 'jobs'],
      ['Staff', 'staff'],
      ['Templates', 'templates'],
      ['Settings', 'settings'],
    ] as Array<[string, string]>) {
      await page.getByRole('button', { name: new RegExp(`^${label}\\b`) }).first().click({
        force: true,
      });
      await page.waitForTimeout(1500);
      await shot(name);
    }

    // Staff detail: open the first member row when the list has one.
    await page.getByRole('button', { name: /^Staff\b/ }).first().click({ force: true });
    await page.waitForTimeout(1200);
    const staffRow = page.getByText(/Technician A|Workshop Admin/i).first();
    if ((await staffRow.count()) > 0) {
      await staffRow.click({ force: true });
      await page.waitForTimeout(1500);
      await shot('staff_member');
      await resetShell();
    }

    // Template detail: open the first template card when present.
    await page.getByRole('button', { name: /^Templates\b/ }).first().click({ force: true });
    await page.waitForTimeout(1200);
    const templateCard = page.getByText(/Comprehensive|Point|Inspection/i).first();
    if ((await templateCard.count()) > 0) {
      await templateCard.click({ force: true });
      await page.waitForTimeout(1500);
      await shot('template_detail');
      await resetShell();
    }

    // Create wizard: open it and walk the steps without submitting.
    await page.getByRole('button', { name: /^Jobs\b/ }).first().click({ force: true });
    await page.waitForTimeout(800);
    const newJob = page.getByRole('button', { name: /New job/i }).first();
    if ((await newJob.count()) > 0) {
      await newJob.click({ force: true });
      await page.waitForTimeout(1500);
      for (let step = 1; step <= 4; step++) {
        await shot(`create_step_${step}`);
        const next = page.getByRole('button', { name: /^Next$/ }).first();
        if ((await next.count()) === 0) break;
        await next.click({ force: true });
        await page.waitForTimeout(900);
      }
      const back = page.getByRole('button', { name: /^Back$|Cancel/i }).first();
      if ((await back.count()) > 0) await back.click({ force: true });
      await page.waitForTimeout(600);
      await resetShell();
    }

    // Back to jobs, narrow to published, open a job and its report/documents.
    await page.getByRole('button', { name: /^Jobs\b/ }).first().click({ force: true });
    await page.waitForTimeout(800);
    await page
      .getByRole('button', { name: /^Published\b/i })
      .first()
      .click({ force: true });
    await page.waitForTimeout(1200);
    await shot('jobs_published');

    const firstCustomer = page.getByRole('button', { name: /JOB-/ }).first();
    if ((await firstCustomer.count()) === 0) {
      const row = page.getByText(/JOB-/).first();
      await expect(row).toBeVisible({ timeout: 20_000 });
      await row.click({ force: true });
    } else {
      await firstCustomer.click({ force: true });
    }
    await page.waitForTimeout(1500);
    await shot('job_detail');

    await expectText(page, /Customer/i);
    await page.mouse.move(960, 520);
    await page.mouse.wheel(0, 700);
    await page.waitForTimeout(500);
    await shot('job_detail_actions');

    for (const [label, name] of [
      ['Report', 'report'],
      ['Documents', 'documents'],
    ] as Array<[string, string]>) {
      const action = page.getByRole('button', { name: new RegExp(`^${label}$`) }).first();
      if ((await action.count()) === 0) continue;
      await action.click({ force: true });
      await page.waitForTimeout(1800);
      await shot(name);
      const back = page.getByRole('button', { name: /^Back$/ }).first();
      if ((await back.count()) > 0) {
        await back.click({ force: true });
        await page.waitForTimeout(800);
      }
    }

    page.off('console', listener);
    expect(fatal, `fatal workshop console errors:\n${fatal.join('\n')}`).toEqual([]);
  });

  test('mobile viewport keeps the shell usable', async ({ page }) => {
    test.setTimeout(120_000);
    await page.setViewportSize({ width: 390, height: 844 });
    await uiSignIn(page, APPS.workshop);
    await bootFlutterWeb(page);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: 'test-results/screens/workshop/jobs_390.png' });
    await expect(page.locator('flutter-view, flt-glass-pane').first()).toBeVisible();
  });
});
