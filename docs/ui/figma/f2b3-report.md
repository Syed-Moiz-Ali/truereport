# F2-B.3 report — green suites, Level 1 Figma-structure fixtures, close of F2 (6 November 2026)

**Status: work complete, gate verdict open on one item (screen 09 Level 1:
0.97362 < 0.98). No commit. Stop for owner approval. F3/F4/F5 not started;
screens 8/10/12 untouched.**

## 1. Owner decisions N1–N5 (recorded in `decisions.md`, F2-B.3 section)

- **N1 (two-level fidelity, gate 0.98 kept):** implemented. Level 1 =
  per-screen fixture in `test/support/` (or self-contained capture test)
  using the shared `Fx*` kit with the Figma's exact structure/data.
  Level 2 = the real product screens, measured, differences listed
  against the slot sheet. Gate not lowered.
- **N2 (visual waiver):** not waived (no owner statement on record).
  Part 2 was executed in full.
- **N3 (re-baseline):** done — 14 F2-A goldens regenerated after visual
  check; recorded in `docs/ui/figma/golden-rebaseline.md`.
- **N4 (delete dark-only tests):** no dark-only test exists in any client
  suite (verified by search); nothing removed.
- **N5 (VIN scope):** unchanged — full VIN only in the finalize slot;
  no VIN change in this phase.

## 2. Part 1: everything green

Client **361/361** (design_system 88, technician 175 incl. 6 new f2b3
captures, admin 93, gallery 5; auth 0 tests), server **89/0/3**
(Testcontainers green), `analyze` clean, both token checks pass, both web
builds + debug APK succeed. Details in `f2b3-test-report.md`.

## 3. Part 2: Level 1 (Figmastructure fixtures)

All fixtures test-only (`client/apps/technician_app/test/`), release guard
green, production never imports them. Captured 390 px / DPR 2 with
`enableFidelityShadows()`; Figma status-bar furniture cropped/masked
identically on both sides (per-screen METHOD.md). Artifacts per screen
under `docs/ui/figma/fidelity/f2b3/<screen>/`
(`figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json`,
`REPORT.md`, `METHOD.md`); fixtures under
`docs/ui/figma/fidelity/fixtures/f2b3/*-level1.json`.

| Screen | Level 1 SSIM | RMSE | Diff boxes | Met |
|---|---|---:|---:|:---:|
| 09 defect-detail | **0.97362** | 10.974 | 20 | **NOT met** (short 0.0064) |
| 11 dense-mechanical | **0.98311** | 13.197 | 20 | met (audited, reproduced ×2) |
| 13 final-review | **0.98209** | 10.991 | 20 | met (audited, reproduced ×2) |
| 14 finalize | **0.98312** | 10.307 | 20 | met (audited, reproduced ×2) |
| 15 offline-sync | **0.98039** | 11.657 | 20 | met (audited, reproduced ×2; thin margin +0.00039) |
| 16 success | **0.99075** | 7.123 | 20 | met (audited, reproduced ×2) |

Residuals on passing screens are font/vector rasterisation only (thin
glyph/SVG edges; no layout, colour, copy, radius, spacing or geometry
error; no unexplained diff > 4 px). Screen 09 after two fixture rounds
(exact Figma values everywhere, 1:1 rasters): positions/fills/tracking
exact ≤ 0.05 px, SVGs byte-identical; remaining 0.0233 gap = text glyph
AA/phase ≈ 0.014 + photo/wireframe resample + shadow approx ≈ 0.009
(per-zone cost table in its METHOD.md; a ±0.5 px global resample shift was
tested and deliberately NOT applied). Nothing further reachable from the
fixture side; no shared-kit change would help (geometry already exact —
kit changes would only move product screens).

## 4. Level 2 (product screens vs Figma, slot-sheet differences)

Existing `docs/ui/figma/fidelity/f2b/<screen>/product-copy/` artifacts,
current on disk (regenerated after the finalize Flexible fix — finalize
Level 2 unchanged at 1.0x, confirming the no-visual-change claim):

| Screen | Level 2 SSIM | RMSE | Reading |
|---|---|---:|---|
| 09 defect-detail | 0.82509 | 68.575 | Slot replacements (reference pill, severity/result vocabulary, silhouette, neutral repair/note slots) + raster + furniture |
| 11 dense-mechanical | 0.82944 | 49.308 | Same + real instruction copy, ARB result pills, neutral barcode slot |
| 13 final-review | 0.78379 | 55.740 | Real blocking rows, coverage % only, approved limitation copy |
| 14 finalize | 0.74529 | 59.294 | Real summary/VIN-in-slot/odometer/flagged/limitation copy + invisible a11y slide alternative |
| 15 offline-sync | 0.81609 | 57.917 | Real counts/states, no invented sizes/speeds/versions, no Fleet/Profile nav |
| 16 success | 0.86443 | 64.671 | Real job/report/delivery rows, last-4, version (no Fleet Portal, no size claim) |

Each difference is a slot-sheet row (M1–M8) with a numeric effect in the
per-screen Level 1 METHOD.md / Level 2 REPORT.md. No pixel-perfect claim.

## 5. Subagent work (max 3 at a time honoured)

12 subagent runs: 3 baseline runners, 1 spacing/overflow fixer, 1 server
baseline, 1 golden analyst, 1 mvn re-run, 1 harness researcher,
6 fixture builders (09 ×2 rounds, 11, 13, 14, 15, 16), 5 fidelity auditors
(11, 13, 14, 15, 16), 3 final verifiers. Two runs needed lead rescue:
(1) the overflow fixer clamped text scaling — the lead replaced it with
the structural `Flexible` fix in `finalize_view.dart` and removed the
clamp; (2) fixture files broke `analyze --fatal-infos` (173 issues) —
the lead ran `dart fix --apply` + removed 7 unused declarations, then
re-ran captures and all six compares (SSIMs bit-identical). No other
failures or overloads.

## 6. Remaining owner actions

1. Decide screen 09 Level 1 (0.97362): accept the quantified residual or
   fund further work (no further fixture-side path identified).
2. Note screen 15 margin (+0.00039 over gate; deterministic as archived,
   fragile to re-capture).
3. Decide the login `Contact Admin` truncation (R1) and consent/hub
   ellipsis (R4) — accept or fund copy/layout rework.
4. Real-device check (EN+AR, 2.0x, touch/keyboard/reader) incl. the
   finalize→success flow; native Arabic review (still blocking real
   Arabic customers per L2).

## 7. Could not verify

See `f2b3-test-report.md` §5. No real-device testing is claimed; no
"pixel-perfect" is claimed (screen 09 explicitly below gate).
