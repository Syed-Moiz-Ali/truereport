# Proposed build plan (Phase F0)

**Project:** TrueReport
**Date:** 5 November 2026
**Status:** proposal only. No application code has been written. This plan starts only after your decisions in `decisions-needed.md`.

---

## 0. Principles

1. **F0 stays read-only.** No app, server, config, data or existing design doc is changed until you approve a phase.
2. **Design system first.** F1 must land before any screen work. No screen may hardcode a colour, type style, radius, spacing value or endpoint.
3. **Build only what the product has data for.** A screen is in scope only if its existing route/DTO/endpoint can support it. New data/API/DB/feature work is a separate, approved track (F6), never smuggled into a visual refresh.
4. **Remove, do not restyle, locked-rule violations.** Certification/score/portal/approval/PII/telemetry elements are deleted from the designs before a build starts. A beautiful forbidden screen is still forbidden.
5. **No "pixel-perfect" claim.** Fidelity is measured and reported. Residual differences are listed and accepted in writing; they are never described as zero.
6. **Every batch has a gate.** A batch does not open the next batch until its gate passes, with evidence committed under `docs/ui/figma/fidelity/`.

---

## 1. Phase map and dependencies

| Phase | Scope | Depends on | Can run in parallel with |
|---|---|---|---|
| **F1** | Design tokens, shared components, gallery, accessibility baseline | Decisions A1–A8, B1–B5, G1–G3 | — |
| **F2** | Technician app UI refresh (allowlisted screens only) | F1; decisions C1, D1–D6 | F3, F4 |
| **F3** | Workshop Admin UI refresh (allowlisted screens only) | F1; decisions C2, D1–D4, F1–F7 | F2, F4 |
| **F4** | Platform Admin UI refresh (allowlisted screens only) | F1; decisions C2, C4, D1–D4, F1–F5 | F2, F3 |
| **F5** | Public report + bilingual PDF visual refresh (current IA and allowlist only) | F1; decisions E1–E6, D5 | F2–F4 |
| **F6** | Optional new data/server/feature tracks (not approved by F0) | Separate ADR per item | No |

**F1 is the critical path.** F2–F5 can run in parallel after F1 if there are enough people; F5 is independent of the Flutter apps but must use the same tokens.

### 1.1 Decisions required to open each phase

| Phase | Must be answered first |
|---|---|
| F1 | A1–A8 (visual direction, accessible primary, fonts, radii, spacing, dark, component scope, brand); B1–B5 (text size, targets, responsive, focus, Arabic reference); G1–G3 (metric, renderers, thresholds) |
| F2 | C1 (technician feature reject/defer); D1 (allowlist), D2 (bay/fleet), D3 (photos), D4 (measurements), D5 (units/time zone), D6 (fixtures); B6 (consent bug) |
| F3 | C2 (workshop features); D1–D4; F1 (shell), F2 (RQ3), F4 (master editing), F5 (dropdown/equipment UI), F6 (viewer/print), F7 |
| F4 | C2, C4 (TOTP); D1–D4; F1, F3 (audit), F4 (master editing), F5 |
| F5 | E1–E6; D5; B5 |
| F6 | A new ADR and product approval for each item; not covered by this plan |

---

## 2. F1 — Design system and gallery

### 2.1 Batch F1.1 — Token contract

**Work**
- Resolve the design direction (A1), accessible primary (A2), font stack (A3), radii (A4), spacing (A5), dark (A6), brand (A8).
- Write the final token contract in `docs/ui/figma/tokens.md` (or a new ADR) and mirror it in:
  - `client/packages/design_system/lib/src/tokens.dart`;
  - `server/src/main/resources/public-report/report.css` CSS custom properties;
  - the print CSS used by the PDF.
- Define semantic tokens rather than raw values: `brand`, `accent`, `surface`, `on-surface`, `on-surface-variant`, `status.*`, `severity.*`, `focus`, `overlay`, `border`, plus type/spacing/radii/elevation/motion.
- Keep status and severity pairs from Phase 1 unless a measured replacement is approved. Do not introduce a second green with a different meaning.

**Acceptance gate F1.1**
- A single source of truth exists and is named in one place.
- **Every** semantic text pair is measured and passes 4.5:1 (normal) / 3:1 (large); **every** UI-component pair passes 3:1.
- No `Color(0x...)`, raw `EdgeInsets`, raw `BorderRadius` or raw font size in feature code; a source-scan test enforces it.
- The public report CSS and PDF CSS use the same names/values as the app; a token-parity test fails on drift.
- The Figma values that were rejected (e.g. `#10B981` text on white) are documented with the measured ratio and the replacement.

### 2.2 Batch F1.2 — Shared components

**Work (A7-a scope)**
- Buttons (primary/tonal/text, loading/disabled, destructive), icon button.
- Text field (filled, borderless, label/error/helper, direction toggle, character count, numeric/keyboard type).
- Cards (tonal/raised, section header, list row).
- Chips: status, severity, filter; segmented control; pill language switch.
- Navigation: rail/side nav, tabs, bottom bar; no new route semantics.
- Feedback: empty, error, skeleton, offline banner, snackbar.
- Overlays: dialog, bottom sheet, confirmation (action name + consequence).
- Data: progress/coverage bar, stepper, photo grid/thumbnails (evidence derivatives only).
- Focus/keyboard: visible focus ring, logical order, Escape closes overlays.

**Do not build yet:** damage canvas, annotation editor, signature pad, print studio, swipe-to-confirm, 360 vehicle, tree with advanced drag/drop, data-table with column chooser. These belong to F6 or need a dedicated screen decision.

**Acceptance gate F1.2**
- Every component has default/hover/focus/pressed/disabled/loading/error states in the gallery.
- EN + AR RTL variants exist; directional icons mirror; non-directional icons do not.
- 44/48 px targets; 200% text does not clip or overlap.
- Component semantics labels are present and tested.
- Contrast test covers every component fill/text pair.

### 2.3 Batch F1.3 — Gallery and visual baseline

**Work**
- A developer-only gallery (a separate `client/apps/ui_gallery` or a hidden route; choose in implementation) that renders every component and sample screen chrome at 390 / 600 / 900 / 1280 widths, EN/AR, light/dark, 1x/1.5x/2x text.
- Golden baselines for components and chrome.
- Start the fidelity harness (§6) with the component gallery and a small representative screen.

**Acceptance gate F1.3**
- Gallery runs in CI or locally with one command.
- Goldens stable across two runs.
- Accessibility matrix (EN/AR, light/dark, 390/600/900/1280, 1x/1.5x/2x) passes for all components.
- `flutter analyze --fatal-infos` clean; all tests pass.
- Fidelity harness produces a side-by-side and metrics report for at least one screen.

---

## 3. F2 — Technician app UI refresh

### 3.1 In-scope screens (allowlist)

Only the safe subset. The rest are excluded or deferred to F6.

| Figma | Build? | What is in scope | What is removed/deferred |
|---|---|---|---|
| 01 Login & Language Selection | Yes | Brand, language switch, email/password, conditional 2FA code, focus/error/loading; real `TrueReport` name | ISO 27001 claim, "Forgot password?", "Request ID" (no endpoint), "TechInspect" brand |
| 02 Assigned Jobs Dashboard | Yes | Existing jobs list/search/filter/refresh/walk-in/sync/empty states restyled; derived counts only | Bay/shift/avatars, "Scan New VIN Tag", Fleet/Profile nav, new metrics |
| 03 Empty State Dashboard | Yes | Existing empty state restyled | "100% Pass Rate", "14 Completed", fake sync claim, Fleet |
| 04 Job Details & Intake | Yes | Existing job/customer/vehicle/template fields restyled; existing edit sheets | Bay/phase/readiness/fuel/step/owner, new photo, call/message if no endpoint |
| 05 Consent & Signatures | Partial | Existing `PROCESSING` / `PUBLIC_LINK` consent bottom sheet restyled; no pre-selection; public-link consent present | Signature pad, prefilled signature, "Recorded", road-test/data-storage consents, PDF sharing |
| 06 Equipment Checklist | Deferred | — (API returns IDs only; no names/specs) | BLE pairing/calibration, ISO/ISO-9001 claims |
| 07 Main Inspection Hub | Yes | Existing checklist coverage/category progress restyled; counts from existing data | "42 Passed", condition ring, Active Bay, Fleet, "Action Items" unless derived from existing flags |
| 08 360 Exterior Wireframe | No | — | Damage/pin model, geometry, "360", measurements |
| 09 Defect Detail & Evidence | Yes | Existing result/severity/note/reason/photos restyled; exact Phase 1 result vocabulary | Defect taxonomy/pin identity, per-photo tags, "Pass" label, hardcoded "1 of 4" |
| 10 Photo Annotation & Markup | No | — | Annotation model/route, HEIC, measurements |
| 11 Dense Mechanical List | Yes | Existing checklist/assessment data with accordion/inline capture UI | Pass/Marginal/Fail and Normal/Low/Critical vocabulary; fluid/OBD values |
| 12 Final Review (Missing Items) | Yes | Existing coverage/blocking/warnings restyled | Compliance wording, "3 Mandatory Photos Missing", signature gate, "28 Verified Data Points", "91% Complete" |
| 13 Tire Condition Capture | No | — | Tyre/PSI/tread model, brand, legal-minimum claim |
| 14 Offline Sync Queue | Yes | Existing queue/retry/state UI restyled; real states only | Local Engine v4.2, fake MB/KB/s, 60 s policy, Fleet/Profile |
| 15 Finalize & Approval (Swipe) | Yes, restricted | Existing confirm/finalize flow restyled; accessible button alternative | Swipe-only, "Approval"/sign-off, GPS, ledger, signature |
| 16 Post-Finalization Success | Yes | Existing final status/delivery cards restyled | "Locked & Signed", Fleet Portal, PDF size, VIN ending, fake "uploaded" |

### 3.2 Batches

| Batch | Screens | Notes |
|---|---|---|
| **F2.1** | 01, 02, 03, 04 | Auth + jobs list + detail; the highest-traffic path; do this first |
| **F2.2** | 07, 09, 11, 12 | Checklist/assessment/review; preserve existing data and result vocabulary |
| **F2.3** | 14, 15, 16 | Sync queue, finalize, success; preserve server-confirmed finalization and idempotency |
| **F2.4** | 05 | Consent only; fix the `granted = true` bug; add public-link consent; no signature |
| **F2.5** | 06 (optional) | Only if you approve a small equipment display using existing IDs; otherwise defer |

### 3.3 Acceptance gate per batch

- **No new data or API.** Diff shows only UI/widgets/tests; no server, model, endpoint or validation change.
- **Exact result/status vocabulary** from `docs/phase-1/10-design-system.md` §3.3; no "Pass", "Perfect", "Certified", score.
- **Consent** never pre-selected; separate consents; public-link consent retained; the current bug fixed.
- **Finalization** remains server-confirmed; no swipe-only gesture; an accessible button path exists.
- **No forbidden terms** in rendered text (harness deny-list).
- **Fidelity evidence** for each screen: side-by-side image, SSIM/RMSE, diff boxes, accepted residuals.
- **Matrix**: EN/AR RTL, light/dark (if kept), 390/600, 1x/1.5x/2x, reduced motion, offline/error/empty/loading.
- `flutter analyze --fatal-infos` clean; existing technician tests + new tests pass.

---

## 4. F3 — Workshop Admin UI refresh

### 4.1 In-scope screens

| Figma | Build? | In scope | Removed/deferred |
|---|---|---|---|
| 01 Create / Schedule Job | Yes | Existing form (customer/vehicle/scope/template/schedule) restyled; keep `templateVersionId` + `scope`; validation | Bay, fixed 60/110 protocol tiers, auto-assign, telematics |
| 02 Workshop Dashboard | No | — | No dashboard endpoint; metrics/review/accuracy/certificate |
| 03 Live Job Queue | Yes | Existing list/search/status/refresh restyled; batch actions only if existing API exists | Bay/progress/review states, export, live sync |
| 04 Assign Technician | Yes | Existing bottom sheet restyled; show masked email; pass a real reason | Skills/certifications/bay/workload/recall/estimate |
| 05 Workshop Staff Management | Yes, read-only | Existing 5-field staff list restyled | Add Staff, supervisor/lead roles, certifications, hours, NFC, roster PDF |
| 06 Workshop Template List | Yes | Existing template cards/list/create restyled | DOT/ISO claims, custom tags, compliance metrics, "Master Inspector sign-off" |
| 07 Add Staff / Create Account | No | — | RQ3: Platform Admin creates accounts |
| 08 Template Builder | Yes | Existing builder/draft/publish/retire/versions/preview restyled | Custom master item, autosave, Active/Automated, measurement ranges, laser/OBD/AI, ISO-9001 |
| 09 Completed Report Viewer | Yes | Existing report viewer restyled; keep link/PDF/delivery state controls | Certificate seal/score/signature/QR/full VIN/full email/telemetry |
| 10 Share-Link Deactivation | Yes | Existing revoke modal restyled with reason **codes**; add "copies cannot be recalled" copy | IP/browser/activity log, free-text-only reason, guessable URL |
| 11 Workshop Settings | No | — | No settings endpoint/model |
| 12 Print-Ready PDF Preview | No (admin screen) | PDF template visual refresh happens in F5 | Print studio, certificate/APPROVED/ISO/licences, full VIN/plate |

### 4.2 Batches

| Batch | Screens |
|---|---|
| **F3.1** | 01, 03, 04 |
| **F3.2** | 05, 06, 08 |
| **F3.3** | 09, 10 |
| **F3.4** | PDF template refresh is shared with F5 |

### 4.3 Acceptance gate per batch

- Only existing routes/endpoints; no dashboard/settings routes; no dead ends.
- **RQ3** preserved: no workshop-side account creation.
- **No review/approval states** (`PENDING_REVIEW`, `APPROVED`, `REJECTED`, "sign-off", "Master Inspector").
- **Immutability**: published templates are versioned; report viewer is read-only; no "Save Changes"/"Instant Push".
- **Masked recipients only**; no full staff/customer email; no sample password.
- **PDF gate** preserved (`pdfReady` / `pdfDownloadEnabled`), no certificate/download promises.
- Fidelity evidence at 1280 and 900; EN/AR; focus/keyboard; 1.5x/2x.
- `flutter analyze --fatal-infos` clean; admin tests pass.

---

## 5. F4 — Platform Admin UI refresh

### 5.1 In-scope screens

| Figma | Build? | In scope | Removed/deferred |
|---|---|---|---|
| 01 Global Hierarchy & Staff Tree | Yes | Existing hierarchy/accounts restyled; masked email; no photos | Avatars/portraits, bays/shifts, certifications, roster/throughput metrics |
| 02 Add Staff / Create Account | Yes | Existing create/invite drawer restyled; validation/loading/success | "Activation token via secure push", temp password visible by default (keep server behaviour) |
| 03 Register New Workshop | No | — | No create endpoint |
| 04 Workshop Details & Settings | No | — | No detail/update/killswitch endpoint; ISO 26262 claims |
| 05 Shared Master Inspection-Item Library | Yes | Existing item list/editor restyled; cards/filters limited to existing fields | Item type badges, rules matrix, cluster count, Instant Push/sync |
| 06 Master Item Content & Translation Editor | Yes | Existing EN/AR editor, rules, equipment, guide image, draft/publish/versions restyled | Measurement/OEM thresholds, multi-image, sync, "Save Changes" in-place edit |
| 07 Master Dropdowns & Data Catalogues | Yes (UI-only) | List/detail UI for existing dropdown endpoints and fields | Workshop overrides, OEM presets, bulk publish, quick index, severity P0–P3 invention |
| 08 Global Equipment Library | Yes (UI-only) | List/detail UI for existing equipment endpoints and fields | Calibration/telemetry/manufacturer/precision/connection/toggles, ISO/CAT claims |
| 09 Platform Audit Events Log | Yes, read-only | Existing audit list restyled; filters only if API adds them (otherwise no) | Verify/export/integrity/hash/ledger/root CA/block paging |
| 10 Global Platform Settings | No | — | No settings endpoint/model; TOTP/SLA/ED25519 claims |
| 11 Admin 2FA / TOTP | No | — | Missing from export; TOTP default off (ADR-0021) |

### 5.2 Batches

| Batch | Screens |
|---|---|
| **F4.1** | 01, 02 |
| **F4.2** | 05, 06 |
| **F4.3** | 07, 08 |
| **F4.4** | 09 |

### 5.3 Acceptance gate per batch

- No new platform routes/endpoints; no create-workshop/settings/disable actions.
- **RQ3/RQ4** preserved; no hidden-by-default surfaces exposed.
- **Master content** stays draft/version/publish; no live mutation; no "Save Changes" on published content.
- **Audit** is read-only and append-only; no PKI/blockchain/root CA claims; no invented hash.
- **No TOTP UI** while `ADMIN_TOTP_REQUIRED=false`; no 2FA claims.
- **No full PII**: masked email, no staff portraits unless approved.
- Fidelity evidence at 1280 and 900; EN/AR; focus/keyboard; 1.5x/2x.
- `flutter analyze --fatal-infos` clean; admin tests pass.

---

## 6. F5 — Public report and bilingual PDF visual refresh

### 6.1 Scope

**Keep the current information architecture and public allowlist.** Apply the approved visual language to the existing sections; do not adopt the Figma portal, scores, certificate, PDF controls, filters, write actions, VIN/plate/location, or measurements.

| Batch | Existing sections |
|---|---|
| **F5.1** | Header, report identity, language switch, summary/coverage |
| **F5.2** | Vehicle, workshop, technician display name, template/scope |
| **F5.3** | Key findings, category tables, evidence photos, not-checked |
| **F5.4** | Limitations/disclaimer, report details/hash, footer |
| **F5.5** | Print CSS + bilingual PDF template visual refresh (EN/AR grids, without changing content rules) |
| **F5.6** | Desktop/responsive layout at 390/600/900/1280 |

### 6.2 Acceptance gate

- **Allowlist tests** pass: no customer name/phone/email, no full VIN, no plate, no precise location, no internal IDs, no consent/audit/delivery data.
- **No certification/"verified by"/compliance claims**; the existing "Not an official certificate." and "Coverage is not a condition score." survive.
- **No score/percentage condition verdict**; coverage counts only (or a coverage percentage explicitly labelled as coverage, per E3).
- **No PDF control** unless `pdfDownloadEnabled`; default off; no "Official Certificate PDF".
- **No portal/write/quote/approve/sign actions**; only language switch, optional photo zoom, print, and gated PDF.
- **noindex / no-referrer / no-store** behaviour unchanged; invalid/revoked tokens still neutral.
- **No new snapshot fields**; if a section needs data, it is an F6 item, not F5.
- **Bilingual PDF** renders Arabic correctly and matches the public page; `vinMasked`; no plate; disclaimer present.
- **No-JS** page remains usable; text selectable/findable; keyboard/screen-reader pass; 200% zoom.
- **Chromium screenshots** at 390 and 1280 compared with the Figma visual references; residual diffs listed.
- **PDF visual comparison** to the Figma print preview is layout/typography only; no certificate elements.

---

## 7. F6 — Optional feature/data tracks (not approved)

Do not start. If approved, each needs its own ADR, schema/API/security/privacy review, and a separate phase. Candidate order if you choose to pursue them:

1. Bay/station/shift model.
2. Tyre/wheel/tread/PSI measurement model.
3. Damage/pin/panel/annotation model.
4. Dashboard/throughput metrics.
5. Workshop settings + platform settings + workshop create/update/disable.
6. Public access log / view analytics.
7. Print preview studio.
8. Admin TOTP enrolment/recovery (only if enabling `ADMIN_TOTP_REQUIRED`).
9. Hardware/BLE/OBD/NFC/telematics integrations.
10. Customer e-signature/approval (currently excluded).

Each is a product decision, not a UI polish. F0 makes no recommendation to build them.

---

## 8. Verification harness (required)

### 8.1 Purpose

Render every approved screen at the Figma frame size with the same sample data, capture a comparable image, and produce:
- a side-by-side Figma-vs-render image;
- a diff heatmap/overlay;
- measured SSIM, RMSE, ΔE2000 statistics and diff bounding boxes;
- a text/layout/geometry report;
- a pass/fail result against the agreed gate.

This is the only basis on which "matches the design" may be claimed. **We will not say "pixel-perfect".**

### 8.2 Inputs

- `figma/<app>/package-manifest.json` (frame size, preview path, asset counts).
- `figma/<app>/screens/<screen>/<screen>@2x.png` (reference).
- `docs/ui/figma/specs/<app>/<NN-screen>.md` (expected structure/tokens/content).
- A per-screen **fixture** JSON: logical width/height, locale, theme, text-scale, fixture data, expected key boxes (node ids + rects), expected strings, forbidden terms.
- The Figma node JSON for key box extraction (node id, `absoluteBoundingBox`).

Two fixture classes (decision D6):
- **Fidelity fixture** — exact Figma strings in test-only files for layout/text-width comparison; excluded from release bundles; guarded by a scan.
- **Product fixture** — neutral, non-PII sample data used for semantic/behaviour tests.

If you choose sanitized fixtures only, text-width differences are measured and listed as expected residuals; layout geometry remains gated.

### 8.3 Renderers

**Flutter (Technician, Workshop Admin, Platform Admin)**
- Widget/golden test with bundled fonts (F1 must have already bundled the approved stack).
- Exact logical surface: `390 × H` (phone) or `1280 × H` (desktop); device pixel ratio **2**; `MediaQuery` insets zero (the Figma frames have no OS chrome).
- Pump the screen with the fixture, locale (`en`/`ar`), theme (light/dark), text scale (1.0/1.5/2.0).
- Capture a `RepaintBoundary` image at pixel ratio 2.
- Export a render-tree/geometry dump for the key boxes (using widget keys defined in the fixture).

**Chromium (Public report)**
- Use the existing headless Chromium infrastructure (the PDF path already uses it) or the existing browser check.
- Serve/render the report with a fixture snapshot at viewport widths 390 and 1280, DPR 2.
- Screenshot the full page; compare section crops.

### 8.4 Comparison

1. Normalise both images to the same logical size (Figma `@2x` is 2× the frame).
2. Compute:
   - **SSIM** global and per 64×64 tile.
   - **RMSE** and mean absolute error per channel.
   - **ΔE2000** per pixel; report % > 2 (JND) and % > 5.
   - **Diff bounding boxes** for connected regions above a threshold; list each with size and location.
3. Compare **key boxes** (header, cards, buttons, fields, nav) from Figma node ids vs Flutter render rects; tolerance **2 logical px**.
4. Compare **text**: every expected string present exactly (or its AR translation); no missing/extra strings; no forbidden term.
5. Produce artifacts:
   - `docs/ui/figma/fidelity/<batch>/<screen>/figma.png`
   - `render.png`
   - `side-by-side.png`
   - `diff.png` (heatmap)
   - `metrics.json`
   - `REPORT.md` (human summary, accepted residuals, owner, date).

### 8.5 Gate thresholds (proposal G3-a)

- **SSIM ≥ 0.98** global; no unexplained diff box > 4 logical px.
- **Text**: exact match; zero forbidden terms.
- **Geometry**: key boxes within 2 logical px where the design is intentionally copied.
- **Tokens**: zero raw hex/EdgeInsets/fontSize/radius in feature code.
- **Accessibility**: contrast pairs pass; targets ≥44/48; 200% text no clipping; EN/AR RTL; focus/keyboard for web.
- **Behaviour**: existing tests pass; no data/API/server diff outside the approved scope.
- Any residual diff must be recorded with a reason (font rendering, raster provenance, safe copy change) and accepted by you. Without acceptance, the screen fails.

### 8.6 Accessibility matrix per screen

| Dimension | Values |
|---|---|
| Locale | EN, AR (RTL) |
| Theme | Light, dark (if A6 keeps dark) |
| Width | 390, 600, 900, 1280 (app-appropriate subset) |
| Text scale | 1.0×, 1.5×, 2.0× |
| Motion | Normal, reduce-motion |
| Input | Touch, keyboard (admin/web), screen reader (manual) |
| State | Default, empty, error, loading, offline (where applicable), disabled, focus |

Arabic has no Figma reference; the AR gate is RTL lint + structural mirroring + native-speaker manual review, not pixel comparison.

### 8.7 Where it lives

- Tooling (no product code): `tools/figma_fidelity/` (new folder, not inside an app).
- Specs/fixtures: `docs/ui/figma/fidelity/`.
- CI: a non-blocking job that produces artifacts; a blocking job only for the agreed gate on approved screens.

---

## 9. Suggested order (when work is authorised)

1. **Decisions** from `decisions-needed.md` (A, B, C, D, E, F, G).
2. **F1.1** token contract.
3. **F1.2** shared components.
4. **F1.3** gallery + harness baseline.
5. **F2.1** technician auth/jobs/detail.
6. **F5.1** public header/summary (can start in parallel with F2).
7. **F2.2–F2.4** technician inspection/review/consent.
8. **F3.1–F3.3** workshop.
9. **F4.1–F4.4** platform.
10. **F2.3/F3.3/F5.5** finalize/sync/report/PDF.
11. **F5.2–F5.6** remaining public/PDF/responsive.
12. **F6** only by separate approval.

**Why this order:** the design system is shared by all apps; the technician and public report are the highest-value/highest-risk surfaces; admin screens depend on the same components and should not fork the tokens. Public report can run in parallel once F1 is done and does not block the Flutter apps.

---

## 10. Definition of done (per screen)

A screen is done only when:
- it is on the approved allowlist;
- it uses only existing data/API/state (or its F6 approval is recorded);
- it has no forbidden terms/elements;
- it passes the accessibility matrix;
- it has a fidelity report with accepted residuals;
- it has no raw tokens and no dead end;
- existing tests + new tests pass and analyzer is clean;
- the public report/PDF allowlist tests pass (F5);
- the change is reviewed against the locked rules one more time.

---

## 11. What this plan deliberately does not do

- It does not start F6 features.
- It does not change the data model, API, permissions, validation, state management or server.
- It does not add a manager/review/approval role, customer portal, payments, certification, scores or public PII.
- It does not copy the Figma sample data, licences, measurements, avatars, vehicle photos or hashes.
- It does not claim pixel fidelity; it measures it.
- It does not delete or modify the original Figma exports.
