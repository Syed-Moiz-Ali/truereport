import { defineConfig, devices } from '@playwright/test';

/**
 * TrueReport E2E harness.
 *
 * Three Flutter web builds are served statically; the Spring server and MySQL
 * are expected on E2E_API_URL (default http://localhost:8080). Passwords are
 * supplied through the environment and never committed.
 */
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 120_000,
  expect: { timeout: 20_000 },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'playwright-report' }]],
  use: {
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
    actionTimeout: 20_000,
    navigationTimeout: 60_000,
    reducedMotion: 'reduce',
  },
  projects: [
    {
      name: 'platform-admin',
      testMatch: /modules\/(auth|platform_admin)\.flow\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], baseURL: 'http://127.0.0.1:5301' },
    },
    {
      name: 'workshop-admin',
      testMatch: /modules\/(auth|workshop_jobs)\.flow\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], baseURL: 'http://127.0.0.1:5302' },
    },
    {
      name: 'technician',
      testMatch: /(modules\/(auth|technician)\.flow\.spec\.ts|cross-app\/.*\.spec\.ts)/,
      use: { ...devices['Desktop Chrome'], baseURL: 'http://127.0.0.1:5303' },
    },
    {
      name: 'public-report',
      testMatch: /modules\/public_report\.flow\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], baseURL: 'http://localhost:8080' },
    },
  ],
  webServer: [
    {
      command: 'node tests/e2e/static-server.js 5301 client/apps/platform_admin_app/build/web',
      url: 'http://127.0.0.1:5301',
      reuseExistingServer: true,
      timeout: 30_000,
    },
    {
      command: 'node tests/e2e/static-server.js 5302 client/apps/workshop_admin_app/build/web',
      url: 'http://127.0.0.1:5302',
      reuseExistingServer: true,
      timeout: 30_000,
    },
    {
      command: 'node tests/e2e/static-server.js 5303 client/apps/technician_app/build/web',
      url: 'http://127.0.0.1:5303',
      reuseExistingServer: true,
      timeout: 30_000,
    },
  ],
});
