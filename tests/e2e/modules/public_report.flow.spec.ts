import { test, expect } from '@playwright/test';

const API = process.env.E2E_API_URL || 'http://localhost:8080';

test.describe('public report — token gate and real data', () => {
  test('unknown token returns the neutral 404 page', async ({ page }) => {
    const response = await page.goto(`${API}/r/e2e-unknown-token-${Date.now()}`);
    expect(response?.status()).toBe(404);
    await expect(page.getByText(/available|unavailable|not found/i).first()).toBeVisible();
  });

  test('active report renders real vehicle data and no demo facts', async ({ page }) => {
    const token = process.env.E2E_PUBLIC_REPORT_TOKEN;
    test.skip(!token, 'E2E_PUBLIC_REPORT_TOKEN not supplied; no stable active link to verify');

    const response = await page.goto(`${API}/r/${token}`);
    expect(response?.status()).toBe(200);

    const expectedMake = process.env.E2E_PUBLIC_VEHICLE_MAKE;
    if (expectedMake) {
      await expect(page.getByText(expectedMake).first()).toBeVisible();
    }
    // Demo constants that must never be fabricated on a real report.
    await expect(page.getByText(/Precious Silver Metallic/i)).toHaveCount(0);
    await expect(page.getByText(/Scratch: 42mm/i)).toHaveCount(0);
  });
});
