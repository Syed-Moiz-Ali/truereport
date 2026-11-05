# F1.1 fidelity evidence (Figma-exact components)

Tooling: `tools/figma_fidelity/` (see its `README.md`).
Fixtures: `fixtures/`.
Artifacts: one directory per sample (`figma.png`, `render.png`,
`side-by-side.png`, `diff.png`, `metrics.json`, `REPORT.md`, `geometry.json`,
`strings.json`).

The render is produced by
`client/packages/design_system/test/fidelity_capture_test.dart` at DPR 2, using
the real bundled Plus Jakarta Sans fonts. Each crop is the **Figma node
bounding box** from the export JSON, not an arbitrary screen area.

## Fixtures and samples

| Sample | Fixture | Figma node and crop (logical) | Renderer |
|---|---|---|---|
| `primary-button-en-light-1x` | `fixtures/component-samples/primary-button-en-light-1x.json` | Login `Button`, 342 x 56 at (24, 472) | Flutter |
| `delivery-status-card-en-light-1x` | `fixtures/component-samples/delivery-status-card-en-light-1x.json` | `Delivery Status Card`, 350 x 145 at (20, 399.5) | Flutter |
| `inspection-result-selector-en-light-1x` | `fixtures/component-samples/inspection-result-selector-en-light-1x.json` | `Severity Pill-Shaped Toggle Group`, 350 x 70 at (20, 444) | Flutter |
| `synthetic-clean` | `fixtures/synthetic/synthetic-clean.json` | generated | synthetic |
| `synthetic-degraded` | `fixtures/synthetic/synthetic-degraded.json` | generated | synthetic |
| `forbidden-bad-string` | `fixtures/forbidden/bad-string.json` | generated | synthetic |
| `forbidden-safe-string` | `fixtures/forbidden/safe-string.json` | generated | synthetic |

## Validation run (measured, not estimated)

| Sample | SSIM | RMSE | ΔE2000 > 5 | Diff boxes | Key boxes | Text | Deny-list | Gate |
|---|---:|---:|---:|---:|---|---|---|---|
| synthetic-clean | 1.00000 | 0.000 | 0.00% | 0 | n/a | pass | pass | pass |
| synthetic-degraded | 0.89708 | 18.539 | 2.40% | 2 | n/a | pass | pass | fail (expected) |
| forbidden-bad-string | 1.00000 | 0.000 | 0.00% | 0 | n/a | pass | **3 matches** | fail (expected) |
| forbidden-safe-string | 1.00000 | 0.000 | 0.00% | 0 | n/a | pass | pass | pass |
| **primary-button** | **0.99520** | 4.714 | 0.60% | 7 | pass | pass | pass | **pass** |
| **delivery-status-card** | **0.99198** | 7.572 | 1.33% | 20 | pass | pass | pass | **pass** |
| **inspection-result-selector** | **0.98340** | 8.269 | 2.21% | 20 | pass | pass | pass | **pass** |

Threshold: SSIM >= 0.98, key boxes within 1 logical px, expected strings present,
zero forbidden terms. All three Figma-exact components pass.

## Diff-box interpretation

The remaining diff boxes are glyph/icon rasterisation, not geometry or colour:

- **Button:** 7 boxes inside `Sign In` and the 10.67 px arrow; largest 10.5 x 6 px.
- **Card:** 20 boxes inside the two titles, the two chip labels and the two
  36 px icon circles; largest 47.5 x 13 px (the `WhatsApp` glyph run). The text
  widths match the Figma text nodes to 1 px.
- **Selector:** 20 boxes inside the uppercase label and the three option
  labels; largest 9.5 x 9 px.

No box is caused by a moved edge, a wrong radius, a wrong fill or a missing
element. Font rasterisation differs between Figma and Flutter; this is reported
as a residual and not claimed as zero. See `f1-fidelity-audit.md` section 5.

## Fixture content

- The Figma-exact fixtures use Figma's own sample copy (`Sign In`,
  `WhatsApp`/`Sent`, `Fleet Portal`/`Synced`, `Pass`/`Minor`/`Major`).
- These fixtures live under `docs/ui/figma/fidelity/` and the capture test under
  `client/packages/design_system/test/`; they are not product assets.
- The gallery section that renders them is hidden in release builds by
  `FixtureGuard` (`client/apps/ui_gallery/lib/fixture_guard.dart`).

## Goldens

`client/packages/design_system/test/figma_goldens_test.dart` adds 12 goldens for
the three Figma-exact components (primary button, delivery card, result
selector) in English and Arabic, light and dark
(`test/goldens/figma_*_{en,ar}_{light,dark}.png`). The existing 20 product
goldens remain in `components_test.dart`.

## Notes

- No Figma export was modified. Crops are made by the comparison tool from the
  `@2x` previews.
- Arabic is rendered with RTL directionality; there is no Arabic Figma frame,
  so Arabic is structural evidence only, not a pixel target.
- The harness reads text from the test-owned `strings.json`; it does not OCR
  the reference image. This keeps the test-only fixture boundary.
