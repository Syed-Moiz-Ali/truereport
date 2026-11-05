# Public-report Chromium capture scaffold

F1 does **not** build a public-report screen. This scaffold only records the
command shape that F5 will use, so the renderer choice and DPR match the
Flutter samples. Compare section crops with the same tool:

```
node tools/figma_fidelity/compare.mjs --fixture <public-report-fixture.json> --threshold-ssim 0.98
```

In the fixture set `"renderer": "chromium"`, `"dpr": 2`, and point
`"reference"` at the public-report `@2x.png` with a `crop` for the section.
The render path should be the screenshot described below.

## Headless screenshot (Windows PowerShell)

Use the existing public report/base URL. `--window-size` is the CSS viewport;
`--force-device-scale-factor=2` produces `@2x` pixels. Make the window tall
enough for the section/full page, or capture section crops after loading.

```powershell
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
& $chrome --headless=new --disable-gpu --hide-scrollbars `
  --force-device-scale-factor=2 --window-size=390,2200 `
  --screenshot="docs/ui/figma/fidelity/chromium/public-390@2x.png" `
  "http://localhost:8080/report/<token>"

& $chrome --headless=new --disable-gpu --hide-scrollbars `
  --force-device-scale-factor=2 --window-size=1280,2200 `
  --screenshot="docs/ui/figma/fidelity/chromium/public-1280@2x.png" `
  "http://localhost:8080/report/<token>"
```

Verify the PNG dimensions: `390 × 2200 × 2 = 780 × 4400`,
`1280 × 2200 × 2 = 2560 × 4400`.

## Notes / limitations

- Chrome's `--screenshot` captures the viewport, not an arbitrary full page.
  For tall reports use a viewport tall enough for the whole page, or drive
  CDP `Page.captureScreenshot` with `captureBeyondViewport: true`.
- Keep `--force-device-scale-factor=2` and compare against Figma `@2x` crops;
  the harness normalises to `logicalWidth × dpr`.
- No public-report fixture is committed in F1 because there is no approved
  screen yet. Do not add one until F5 selects the canonical snapshot and
  allowlist.
- The report must keep its existing `noindex`, `no-referrer`, `no-store`,
  language switch and PDF-gate behaviour; the harness only measures pixels.
