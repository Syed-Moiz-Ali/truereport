# F2-A report: Technician app, screens 1 to 7

**Project:** TrueReport
**Phase:** F2-A (Technician app, Figma screens 1 to 7)
**Date:** 5 November 2026
**Status:** implementation complete for screens 1, 2, 3, 4, 5 and 7. **Screen 6 is blocked by a data gap.** The fidelity gate is measured and **not met**; every residual is explained below. No commit was made.

---

## 1. What was completed

| Figma screen | Product screen | Status | Main files |
|---|---|---|---|
| 01 Login & Language Selection | `/signin` | Done | `client/packages/auth/lib/src/sign_in_page.dart`, `sign_in_view.dart` |
| 02 Assigned Jobs Dashboard | `/jobs` | Done (populated) | `client/apps/technician_app/lib/src/pages/technician_jobs_page.dart`, `screens/f2a/assigned_jobs_view.dart` |
| 03 Empty State Dashboard | `/jobs` empty | Done | `screens/f2a/assigned_jobs_view.dart` (`EmptyJobsView`) |
| 04 Job Details & Intake | `/jobs/:id` | Done | `pages/job_detail_page.dart`, `screens/f2a/job_intake_view.dart` |
| 05 Consent & Signatures | Consent sheet | Done without signature pad | `screens/f2a/consent_view.dart`, `pages/job_detail_page.dart` |
| 06 Equipment Checklist | `/jobs/:id/equipment` (sheet) | **Blocked** | Existing sheet only; no names/specs/verification data |
| 07 Main Inspection Hub | `/jobs/:id/hub` | Done | `pages/inspection_hub_page.dart`, `screens/f2a/inspection_hub_view.dart` |

**Shared design-system work (lead-owned):** P1 large primary action (`AppButton.large`, 19 px bold, `#059669` fill, white label) and P2 label-above fields (`AppTextField.labelAbove`); technician components in `design_system/lib/src/components/technician_shell.dart` (brand mark, initials avatar, app bar, dock, vehicle silhouette, labeled values, section title, meta pill, coverage ring, module card, consent card, result chip); new sizing/type/colour tokens; localisation keys in English and Arabic.

**Routing:** added `/jobs/:id/hub`. The existing `/jobs/:id/checklist` route is unchanged. The product dock is Jobs / Sync / Profile; Profile is a bottom sheet with the technician's own name/email, language switch and sign-out (existing state only).

**No server, API contract, model, validation, permission or state-management change was made.** The only behavioural change is the already-approved F1 consent default (nothing selected until the technician saves).

---

## 2. Fidelity measurements (measured, not estimated)

Command: `node tools/figma_fidelity/compare.mjs --fixture docs/ui/figma/fidelity/fixtures/f2a/<id>.json`. Each sample renders 390 logical width at DPR 2 with the bundled fonts. `figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json` and `REPORT.md` are in `docs/ui/figma/fidelity/f2a/<screen>/<variant>/`.

| Screen | Variant | SSIM | RMSE | dE2000 > 5 | Diff boxes | Strings | Deny-list | Gate |
|---|---|---:|---:|---:|---:|---|---|---|
| 01 Login | Figma-text | **0.8860** | 47.90 | 13.51% | 20 | pass | pass | **fail** |
| 01 Login | Product copy | **0.8860** | 47.90 | 13.51% | 20 | pass | pass | **fail** |
| 02 Jobs | Figma-text | **0.7723** | 68.76 | 22.36% | 20 | pass | pass | **fail** |
| 02 Jobs | Product copy | **0.7949** | 67.37 | 22.63% | 20 | pass | pass | **fail** |
| 03 Empty | Figma-text | **0.8535** | 44.37 | 11.45% | 20 | pass | pass | **fail** |
| 03 Empty | Product copy | **0.8534** | 44.44 | 11.47% | 20 | pass | pass | **fail** |
| 04 Job intake | Figma-text | **0.8068** | 54.58 | 19.85% | 20 | pass | pass | **fail** |
| 04 Job intake | Product copy | **0.8075** | 54.27 | 19.77% | 20 | pass | pass | **fail** |
| 05 Consent | Figma-text | **0.7960** | 57.38 | 18.54% | 20 | pass | pass | **fail** |
| 05 Consent | Product copy | **0.7960** | 57.38 | 18.54% | 20 | pass | pass | **fail** |
| 07 Hub | Figma-text | **0.8081** | 60.80 | 18.97% | 20 | pass | pass | **fail** |
| 07 Hub | Product copy | **0.8099** | 60.62 | 18.82% | 20 | pass | pass | **fail** |

- **P8 gate verdict: not met on any screen.** The 0.98 SSIM threshold and the â€œno unexplained difference > 4 pxâ€ rule are contradicted by the mandatory P1/P2 changes and by the required removals of Figma-only elements (40+ removed/replaced blocks). The harness reports 20 diff boxes per sample; 20 is the report cap, not the true count.
- **What passed:** every fixtureâ€™s expected strings are present, and the product-copy deny-list has zero matches. No certification, score, compliance, fleet, BLE/pairing, bay/shift or live-sync wording is rendered.
- **What the residuals are:** font rasterisation (Plus Jakarta Sans vs Figma), P1 button (19 px bold on `#059669` vs 14 px white on `#10B981`), P2 labels above fields and 56 px inputs vs 48 px, removed avatar photo / vehicle photo / signature pad / scan VIN / Fleet dock / bay / shift / pass-rate / summary strip, and copy differences from the approved product vocabulary.
- **No â€œpixel-perfectâ€ claim is made.** The per-screen `REPORT.md` files list the specific residuals for that screen.

The Figma-text fixtures use Figma-like sample copy under `test/` only (`F2AFixtureData`), are not product assets, and are excluded from release builds. The product-copy fixtures use neutral test data and the real English product copy.

---

## 3. Deviations and removals

The full table is in `docs/ui/figma/deviations.md` (F2-A section). Summary:

- **Login:** removed TechInspect, ISO 27001, Forgot password, Request ID and the 202 px pad; TrueReport wordmark + drawn TR monogram; no logo asset exists in the export.
- **Jobs:** removed avatar photo (initials), shift/bay, LIVE SYNC, Scan New VIN Tag, Fleet dock, avg-turnover metric; kept search, filters, refresh, walk-in and sync; counts are derived from the existing list.
- **Empty:** removed SHIFT/Bay, TODAY'S SUMMARY, 14 Completed, 100% Pass Rate, â€œSynced just nowâ€; kept refresh, walk-in and a real pending-sync line.
- **Job intake:** vehicle photo replaced by an original silhouette; removed phase/readiness/fuel/step/owner, bay, call/message and the scan icon; kept real customer/vehicle/template fields, edit sheets, consent/equipment actions and Start.
- **Consent:** no signature pad, no prefilled signature, no Recorded badge/EST timestamp, no PDF/road-test/data-storage consents; only PROCESSING and PUBLIC_LINK, unselected, saved explicitly.
- **Equipment:** **not built** â€” the API returns IDs only. The existing sheet shows the IDs and an explicit note that names are unavailable. No names/specs/verification were invented.
- **Hub:** coverage ring is â€œN of M checks doneâ€, never a score; counts use the approved result vocabulary; removed bay/VIN fragment/vehicle photo/Active Bay/Queued; module states are derived.
- **Targets:** 48 dp minimum and 56 dp primary actions (Figma uses 24/32/36/40 px controls in several places).
- **Dock:** product 3-item Jobs/Sync/Profile; the Figma 4-item layout is shown in the gallery only (P7).
- **Arabic:** derived RTL from the same tokens; VIN/plate/numerals LTR. No Arabic Figma frame; pending native review.

---

## 4. Contrast audit

`docs/ui/figma/contrast-after.md` now includes an **F2-A technician screens** section for light and dark (18 pairs per theme). Summary: **174 pass, 16 fail** across all audited token pairs.

F2-A-specific results:
- **Pass:** primary large label white on `#059669` = **3.77:1** (19 px bold, large text); ink on `#10B981` = **6.78:1**; primary-large boundary on white = **3.77:1**; focus ring **5.69:1**; body/muted text **6.47:1â€“21:1**; status pairs **7.97:1â€“9.68:1**; error text **7.45:1**.
- **Fail (accepted under P2):** borderless field fill boundary, `#F4F3F8` on white = **1.10:1** light / **1.18:1** dark, below the 3:1 UI boundary target. The visible label above the field and the F1 focus ring carry the affordance. It is listed in `deviations.md`.
- **Existing exceptions (P3):** 12 decorative `outlineVariant` divider tokens and 2 emerald fill-boundary pairs remain accepted. No text pair fails 4.5:1.
- **P5 font check:** the technician web buildâ€™s `FontManifest.json` lists MaterialIcons, Plus Jakarta Sans, Noto Sans Arabic, IBM Plex Sans Arabic, Noto Sans and Noto Sans SC, all bundled under `assets/packages/design_system/assets/fonts/`. There is no `google_fonts` dependency or network font request, so Flutter web does not download fallback fonts at runtime; missing glyphs use the browserâ€™s local fallback. Noto Sans SC is 16,437,364 B in the web build.

---

## 5. Tests, analyze and builds

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` (design_system) | No issues |
| `flutter analyze --fatal-infos` (auth) | No issues |
| `flutter analyze --fatal-infos` (technician_app) | No issues |
| `flutter analyze --fatal-infos` (ui_gallery) | No issues |`n| `flutter analyze --fatal-infos` (admin_app) | No issues |
| `design_system` tests | 136 passed |
| `technician_app` tests | 92 passed (existing + F2-A matrix, 18 goldens, 12 captures, 24 screenshots, source scan, forbidden terms) |
| `ui_gallery` tests | 5 passed |
| `admin_app` tests | 83 passed |
| Token generator `--check` | pass |
| Print token block `--check` | pass |
| `flutter build web --release` (technician) | success (`build/web`) |
| `flutter build apk --debug` (technician) | success (`app-debug.apk`) |
| Server `mvn -B test` | 62 run, 0 failures, 0 errors, 6 skipped with `-Dmanagement.health.mail.enabled=false` (see note) |
| `flutter test test/f2a_fidelity_capture_test.dart` | 12/12 captured |
| `flutter test test/f2a_screenshots_test.dart` | 24/24 screenshots |

**Server-test note:** a plain `mvn -B test` in this environment returns 503 from `/actuator/health` because the mail health indicator cannot reach `localhost:1025` (no local SMTP/MailHog is running). Running the same suite with `-Dmanagement.health.mail.enabled=false` gives **62 run, 0 failures, 0 errors, 6 skipped**. This is an environment dependency, not a code change; no server code was modified. The F1 baseline reported 3 skipped; the extra skips are the MySQL/S3/PDF sample tests in this environment.

**New F2-A tests:**
- `test/f2a_screens_test.dart`: EN/AR at 360/390/600/900 widths and 1.0x/1.5x/2.0x text; reduce-motion; 56 dp primary action; 48 dp dock; source scan (no raw colours/sizes/radii/shadows/URLs/endpoints); product forbidden-term lint.
- `test/f2a_goldens_test.dart`: 12 goldens (6 screens x EN/AR, light).
- `test/f2a_goldens_dark_test.dart`: 6 derived dark goldens (EN), separate file.
- `test/f2a_fidelity_capture_test.dart`: 12 fidelity captures.
- `test/f2a_screenshots_test.dart`: EN/AR at 1.0x and 2.0x in `docs/ui/figma/f2a-screenshots/`.
- Existing consent tests still pass (F1 B6 behaviour preserved).

---

## 6. Privacy and safety

- No new data collected, stored or transmitted; no new endpoint or model.
- Consent is still explicit and separate; both choices start unselected; no record is created before Save; the public-link consent is retained.
- No Figma sample names, vehicles, VINs, photos or avatars ship in release builds. The test fixtures are under `test/` and the gallery dock comparison is behind `FixtureGuard`.
- No certification, â€œverifiedâ€, score, pass-rate, compliance, approval/sign-off, GPS or tamper-proof wording is rendered. The product deny-list is clean.
- The equipment sheet states that names are unavailable rather than inventing them.
- Public surfaces (public report, PDF, admin apps, server) are untouched.
- **Privacy review:** `docs/ui/figma/f2a-privacy-review.md` — pass with no blockers. Fixed during review: the P7 gallery comparison is now wired inside `FixtureGuard.enabled`, the customer email was removed from the intake card (still editable), and the unused consent component was deleted. Remaining low/info items: user-initiated VIN clipboard, the technician's own email in the profile sheet, raw equipment IDs.
- **A11y/i18n review:** `docs/ui/figma/f2a-a11y-i18n-review.md` — conditional. Automated EN/AR + 360/390/600/900 + 1.0/1.5/2.0 + reduce-motion matrix passes; real-device screen readers and native Arabic review remain outstanding.

---

## 7. What could not be verified

- Real Android/iOS rendering, sunlight legibility, one-hand reach and keyboard behaviour.
- Real TalkBack/VoiceOver screen-reader traversal.
- Native Arabic review and Arabic shaping/line-breaking on a real device.
- The 0.98 fidelity gate (not met; see section 2).
- Screen 6 equipment UI (data gap).
- Cross-platform golden stability (goldens generated and passed on Windows only).
- Real offline drift database behaviour in widget tests (the existing in-memory store is used).

---

## 8. Decisions needed

1. **Screen 6:** approve a small server/API change to return equipment names (and optionally status), or keep the equipment screen deferred. F2-A did not fake it.
2. **Fidelity gate:** accept the measured residuals for these six screens (they are caused by P1/P2 and the required removals), or change P1/P2/removals. The 0.98 threshold cannot coexist with the current removal list.
3. **Dock:** confirm Jobs / Sync / Profile (P7 default) or choose another 3-item set. The Figma 4-item layout is in the gallery only.
4. **Arabic:** confirm Noto Sans Arabic after native review.
5. **Field fill:** confirm P2 acceptance of the 1.10:1/1.18:1 field boundary.

---

## 9. What the owner should check on a real phone

1. English and Arabic at 1.0x and 2.0x; confirm no clipping in the login, job cards, intake cards, consent and hub grid.
2. One-hand reach for the primary CTA and the bottom dock.
3. Sunlight legibility of muted text, status chips and the coverage ring.
4. Offline: jobs list from cache, pending-sync chip, consent saved on phone, sync queue.
5. Arabic RTL: mirrored rows, LTR VIN/plate/odometer numerals, Arabic keyboard switching.
6. TalkBack/VoiceOver on the consent choices, result counts, module cards and dock.
7. The equipment sheet: confirm the â€œnames unavailableâ€ note is acceptable until the API gap is closed.






