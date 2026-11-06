# F2-A golden re-baseline record (N3, F2-B.3, 6 November 2026)

Owner decision N3 authorises re-baselining the 14 F2-A goldens (plus any other
golden changed intentionally since F2-A.2) after a visual check that each new
render matches its Figma, and recording each here.

## What was re-baselined

All 14 light-only masters under
`client/apps/technician_app/test/goldens/f2a_*_light.png`
(7 screens × EN/AR), regenerated with
`flutter test --update-goldens test/f2a_goldens_test.dart`
and verified with a follow-up `flutter test test/f2a_goldens_test.dart`
→ **14/14 pass**.

| Screen | EN | AR | Visual check |
|---|---|---|---|
| login | `f2a_login_en_light.png` | `f2a_login_ar_light.png` | Both viewed. Layout = Figma (glow, fields, CTA, footer rows). Copy = C0 product strings (TrueReport / partner-workshops tagline / Password help / Contact Admin / Authorised workshop staff only). RTL mirrored, no breakage. Residual R1 below. |
| assigned-jobs | `f2a_assigned-jobs_en_light.png` | `f2a_assigned-jobs_ar_light.png` | Both viewed (EN testImage; AR pair via analyst). Fully localised Arabic incl. Arabic-Indic digits; counts from fixtures; `Not available` pills are the honest `notAvailable` fallback for non-canonical fixture statuses (residual R2). |
| empty-state | `f2a_empty-state_en_light.png` | `f2a_empty-state_ar_light.png` | EN viewed. Real empty state, `Coverage` label, no pass-rate. Header-row edge clip (`0 JOBS`) matches the old golden's `Bay 04` clip pattern (residual R3). |
| job-intake | `f2a_job-intake_en_light.png` | `f2a_job-intake_ar_light.png` | EN viewed. Silhouette media, LTR VIN/odometer, locale time `10:42 UTC+4`. No invented data. |
| consent | `f2a_consent_en_light.png` | `f2a_consent_ar_light.png` | EN viewed. Two active consents + disabled data-storage card, Granted/Refused decision, no signature capture (J4). Card helper text ellipsizes identically to the old golden (residual R4). |
| equipment | `f2a_equipment_en_light.png` | `f2a_equipment_ar_light.png` | EN viewed. Real J5 labels/codes/statuses (`TDG · ACTIVE` etc.). Status circles unticked (no verification state modelled). |
| inspection-hub | `f2a_inspection-hub_en_light.png` | `f2a_inspection-hub_ar_light.png` | Both viewed. Real coverage ring 45/110, vocabulary counts, module cards, Finalized dock. Count pills ellipsize at 390 px (residual R4). |

No other golden changed intentionally since F2-A.2: `design_system`
goldens are untouched and pass; F2-B has golden-*ready* paths but no
`matchesGoldenFile` masters by design (reference renders are the
`docs/ui/figma/fidelity/f2b/` artifacts).

## Why the old goldens failed (cause, not just symptom)

The 14 light masters were created in `a7990ce` and never regenerated
after `90e1df7` (Phase C0) removed the `figmaText` mechanism from every
F2-A view: Figma marketing copy → product `l10n` strings, tofu → real
Arabic, plus HEAD changes (locale-aware `formatOdometer` /
`scheduledTimeUtc4`; `ui_helpers` unknown-code fallback → `notAvailable`).
Masked diffs show text-glyph fringing only — no shifted boxes, no theme
or navigation change. Re-baseline is copy-churn catch-up, not a
fidelity change.

## Residuals carried into the new baselines (layout = Figma, noted openly)

- **R1 — Login footer truncation (EN `Contact …` / AR `تواصل مع…`).**
  The footer keeps the exact Figma slot geometry (fixed 153.53 / 64.94 px
  boxes for the Figma `Request ID` text, J2). The mandated longer
  `Contact Admin` text ellipsizes at 390 px. `find.text` still resolves
  the full string. Owner options: shorter approved copy or a footer
  rework (geometry test `access prompt` x=81.76 would move).
- **R2 — `Not available` pills on assigned-jobs fixtures.** Fixture jobs
  carry non-canonical status codes, so the HEAD `notAvailable` fallback
  renders. Honest product behaviour; golden records it.
- **R3 — Header-row edge clip on empty-state (`0 JOBS`).** Same pattern
  as the old golden (`Bay 04` clipped). Pre-existing, not a regression.
- **R4 — Count/helper ellipsis (hub pills, consent card helpers).**
  Longer product strings in fixed Figma slots clip to ellipsis by design
  (F2-B.1 `maxLines:1`/ellipsis rule). No overflow exception.

## Verification

- `flutter test test/f2a_goldens_test.dart` → 14/14 pass (post-update).
- `flutter test test/f2a1_geometry_test.dart` → 7/7 screen cases pass
  (positions unchanged; the spacing tokenisation `g12→spacing.md`,
  `g8→spacing.sm` is pixel-identical).
- `test/failures/*.png` artifacts in the working tree are stale outputs
  of the pre-baseline failing run, not sources of truth.
