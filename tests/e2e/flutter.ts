import { expect, Page } from '@playwright/test';

/**
 * Flutter web renders to a canvas. Nothing is in the DOM until the semantics
 * tree is enabled. Click the semantics placeholder and wait for the glass pane.
 */
export async function bootFlutterWeb(page: Page, url?: string): Promise<void> {
  if (url) {
    await page.goto(url, { waitUntil: 'domcontentloaded' });
  }
  await expect(page.locator('flutter-view, flt-glass-pane').first()).toBeVisible({
    timeout: 90_000,
  });
  const placeholder = page.locator('flt-semantics-placeholder');
  if ((await placeholder.count()) > 0) {
    // The placeholder is a 1x1 off-viewport node: a real click fails, but a
    // dispatched click enables semantics exactly as the engine expects.
    await placeholder.first().evaluate((el) => (el as HTMLElement).click());
    await page.waitForTimeout(800);
  }
  // The engine sometimes paints before semantics attaches. Give it one tick.
  await expect(page.locator('flt-semantics, flt-semantics-host, [role]').first()).toBeVisible({
    timeout: 15_000,
  }).catch(() => undefined);
}

/** Type into a Flutter text field: click the semantics node, then type. */
export async function typeInto(page: Page, label: RegExp | string, value: string): Promise<void> {
  const field = page.getByLabel(label).first();
  await field.click({ force: true });
  await page.keyboard.type(value);
}

export async function clickLabel(page: Page, label: RegExp | string): Promise<void> {
  const target = page.getByRole('button', { name: label }).first();
  if ((await target.count()) > 0) {
    await target.click({ force: true });
    return;
  }
  await page.getByLabel(label).first().click({ force: true });
}

export async function expectText(page: Page, text: RegExp | string): Promise<void> {
  await expect(page.getByText(text, { exact: false }).first()).toBeVisible({ timeout: 20_000 });
}

/** Job cards in the technician queue expose the reference in aria-label. */
export async function jobRefVisible(page: Page, reference: string): Promise<boolean> {
  const escaped = reference.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const byRole = page.getByRole('button', { name: new RegExp(escaped) });
  if ((await byRole.count()) > 0) {
    return byRole.first().isVisible().catch(() => false);
  }
  const byLabel = page.getByLabel(new RegExp(escaped));
  if ((await byLabel.count()) > 0) {
    return byLabel.first().isVisible().catch(() => false);
  }
  return page
    .getByText(reference, { exact: false })
    .first()
    .isVisible()
    .catch(() => false);
}

export async function reloadAndBoot(page: Page): Promise<void> {
  await page.reload({ waitUntil: 'domcontentloaded' });
  await bootFlutterWeb(page);
}
