import { ConsoleMessage, Page, expect } from '@playwright/test';
import { AppConfig } from './apps';
import { bootFlutterWeb } from './flutter';
import * as path from 'path';

/** Console lines that always mean a real client defect. */
const FATAL_CONSOLE = [
  /Unhandled Exception/i,
  /RenderFlex overflowed/i,
  /is not a subtype of type/i,
  /NoSuchMethodError/i,
  /RangeError/i,
  /type 'Null' is not a subtype/i,
  /setState\(\) called after dispose/i,
];

/** Copy that only appears when the app fell into a fatal error surface. */
const FATAL_COPY = /Something went wrong|Unhandled Exception|RenderFlex overflowed|is not a subtype of type/i;

export interface ScreenResult {
  route: string;
  url: string;
  fatalConsole: string[];
  fatalCopy: boolean;
  screenshot: string;
}

/**
 * Boot a route, wait for the Flutter semantics tree, and report anything that
 * indicates a fatal client defect. Screenshots land in test-results/screens so
 * every screen exercised by a sweep leaves evidence.
 */
export async function sweepScreen(
  page: Page,
  app: AppConfig,
  route: string,
  name: string,
): Promise<ScreenResult> {
  const fatalConsole: string[] = [];
  const listener = (message: ConsoleMessage) => {
    if (message.type() !== 'error') return;
    const text = message.text();
    if (FATAL_CONSOLE.some((pattern) => pattern.test(text))) {
      fatalConsole.push(text.slice(0, 400));
    }
  };
  page.on('console', listener);

  await page.goto(`${app.baseURL}${route}`, { waitUntil: 'domcontentloaded' });
  await bootFlutterWeb(page);
  // bootFlutterWeb already waits for the semantics tree; one paint tick is
  // enough for providers to replace skeletons.
  await page.waitForTimeout(600);

  const bodyText = await page.evaluate(() => document.body.innerText);
  const screenshot = path.join('test-results', 'screens', app.key, `${name}.png`);
  await page.screenshot({ path: screenshot, fullPage: false });
  page.off('console', listener);

  return {
    route,
    url: page.url(),
    fatalConsole,
    fatalCopy: FATAL_COPY.test(bodyText),
    screenshot,
  };
}

export function expectHealthy(result: ScreenResult): void {
  expect(
    result.fatalConsole,
    `${result.route} console errors:\n${result.fatalConsole.join('\n')}`,
  ).toEqual([]);
  expect(result.fatalCopy, `${result.route} rendered a fatal error surface`).toBe(false);
}
