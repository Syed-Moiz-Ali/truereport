# Phase 4-lite — dashboard harness and seams

LITE path, one screen. No new architectural boundary, so no ADR: the dashboard
already sits inside `WorkshopAppShell`, reads Riverpod providers, and routes
through the existing navigator. What it needs is a harness that makes its
evidence real, and seams that can be reverted one at a time.

## Harness (already exists — verified, not re-invented)

| Piece | Path | Verified |
|---|---|---|
| Real fonts in tests | `test/flutter_test_config.dart` → `test/support/real_fonts.dart` | loads every bundled `.ttf`/`.otf` (Plus Jakarta, IBM Plex Arabic, Noto fallbacks) plus MaterialIcons, and exposes `missingFamilies` |
| Font family names | `TrFonts` in `design_system/src/fonts.dart`, consumed by `AppTheme.build` | single source; the harness asserts the same names |
| Direction preview capture | `lib/preview/dashboard_directions.dart`, `test/dashboard_directions_preview_test.dart` | produced the 9 Gate-3 PNGs |
| Screen capture | `test/workshop_real_font_screenshot_test.dart` | writes `test/screenshots/real/workshop_dashboard_*.png` at 1440/1280/768/360/1280 AR |
| Baseline gate | `tool/baseline_check.dart` | green on the repaired tree |

**Smoke proof this phase produced:** the direction renders in
`docs/evidence/dashboard_directions/` were captured through the same loader and
show real glyphs (distinct letterforms, correct tabular figures). Ahem output
would be solid rectangles; none appear.

## Seams (each independently revertible)

| # | Seam | Files | Revert |
|---|---|---|---|
| 1 | Copy | `packages/l10n/lib/l10n/app_{en,ar}.arb` (+ generated) | delete the added keys |
| 2 | Style | `lib/src/features/dashboard/dashboard_style.dart` (new) | delete the file |
| 3 | Primitives | `lib/src/features/dashboard/widgets/*.dart` (new) | delete the folder |
| 4 | Screen | `lib/src/features/dashboard/dashboard_tab.dart` (rewritten) | `git checkout` the file |
| 5 | Tests | `test/dashboard_invariants_test.dart` (new), `test/dashboard_test.dart` (structural half rewritten) | restore from git |

Order of landing: 1 → 2 → 3 → 4 → 5. Each step leaves the tree compiling.

## Gate 4 — self-grade

- Every Phase 0 finding in `docs/audit-dashboard.md` §8 maps to this build:
  R1 → seam 4 (clean providers) · R2 → atlas primitive · R3 → hero region ·
  R4 → no time claim, groups by status · R5 → contract tests in the mini Brief ·
  R6 → invariants/structure test split · R7 → spine on phone · R8 → no greeting
  and no device-date claim.
- No finding is left unmapped; nothing is marked `won't fix`.
- All five seams revert alone.
- Smoke capture renders real glyphs.
- **PASS (self).**
