import base from '../playwright.config';
import { defineConfig } from '@playwright/test';

/**
 * QA-only harness config. It does not change application source or the
 * repository's normal test config: it only turns off trace/video capture,
 * whose file writes on this machine fail during teardown (ENOENT) and were
 * masking genuine assertions.
 */
export default defineConfig({
  ...base,
  testDir: '../tests/e2e',
  outputDir: './test-results-clean',
  retries: 0,
  use: {
    ...base.use,
    trace: 'off',
    video: 'off',
    screenshot: 'only-on-failure',
  },
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'qa_audit/playwright-report-clean' }]],
});
