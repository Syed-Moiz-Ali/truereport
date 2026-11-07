# Build plan F3 — Workshop Admin screens 1–12 (planning only, no build in F3-0)

**Project:** TrueReport
**Phase:** F3-0 Step 4 (plan only — no batch starts in F3-0)
**Date:** 6 November 2026
**Sources:** `docs/ui/figma/f3-slot-sheet.md`; `docs/ui/figma/f3-decisions-needed.md` (D-F3-1–D-F3-10); `docs/ui/figma/specs/workshop/01–12`; `docs/ui/figma/c0-admin-accounts-slot-sheet.md`; O3–O10; master.md §1–2.
**Plain statement:** no batch starts in F3-0. Batches A–C below are sequenced for a future build phase after all blocking decisions are approved in writing.

**Grounding inventory:** `client/apps/admin_app/lib/src/admin_router.dart` exposes only `/signin`, `/platform`, `/workshop`, `/unauthorized`. `WorkshopAdminHomePage` has 3 tabs — Jobs, Staff, Templates (`workshop_admin_home.dart`). There is no `/dashboard` route/tab and no `/settings/workshop` route. Pages on disk: `jobs_tab.dart`, `job_form_page.dart`, `staff_tab.dart`, `templates_tab.dart`, `template_builder_page.dart`, `template_version_page.dart`, `report_page.dart`.

---

## Shared components — build first (per batch), each mapped to design_system or NEW

Build shared chrome/compositions once per batch before the screens that use them. Reuse existing `design_system` components wherever covered; NEW items are compositions of existing tokens/components unless noted.

| # | Shared component | design_system map / verdict | Used by |
|---|---|---|---|
| S1 | Admin chrome: 96 px icon rail + 80 px floating blurred header (status pill slot + search + user chip, same-slot neutral only) | Restyle `AdminSidebar` rail + `AdminTopBar`/`AppBar` (`admin_chrome.dart`, `navigation.dart`); user-chip/bay-pill composite is NEW | Batches A, B, C (all screens) |
| S2 | KPI / stat card (icon tile + status pill + number + caption + progress track) | NEW composition from `AppStatCard`/`AppCard` + `AppCoverageBar` (`cards.dart`, `progress.dart`) | Batch A screen 1; Batch B screens 5, 7 |
| S3 | Job / activity / staff / template row cards (article card 1104×150, activity row, staff card, template grid card 346.7×437) | NEW compositions from `AppCard` + `AppListTile` + `StatusChip` (`cards.dart`, `lists.dart`, `chips.dart`); data-table pattern where tabular (`data_table_2`/pluto choice stays OPEN per build-plan — use existing list/card pattern in F3, no new table component unless approved) | Batch A screens 1–2; Batch B screens 5, 7 |
| S4 | Right drawer / side sheet (420 screen 3; 480 screen 6, pinned footer) + centred dialogs (512 screen 4; 448×576 screen 10) + radio/option cards + tier cards + reason-code selector + warning box | NEW `SideSheet`/`RightDrawer` (no equivalent — `showAppBottomSheet` is bottom sheet only); dialogs covered (`showAppConfirmDialog`/`showDialog`, `overlays.dart`) + NEW destructive red variant; option cards NEW from `FigmaResultOption`-style + `AppSelectableText` + `AppTextField` | Batch A screens 3–4; Batch B screen 6; Batch C screen 10 |
| S5 | Template grid card + dashed create-card + footnote banner; metric pods | NEW (`TemplateCard`, create tile, banner) from `AppCard`/`StatusChip`/`EmptyState` | Batch B screens 7–8 |
| S6 | Sequence card (numbered) + reorder controls (icon buttons + trash + drag handle wired to existing move up/down/remove) + drop zone visuals + locked-rule pills (`noteRequirement/evidenceRequirement · lockedByPlatform`) | NEW compositions; reorder logic stays existing `template_builder_page.dart:210` move buttons (A09 allows drag visuals + accessible buttons); EN/AR preview stays existing `_preview` sheet | Batch B screen 8 |
| S7 | Report document container + coverage band (counts + progress, labelled coverage only) + finding rows + masked delivery rows + gated PDF/download + Send/Retry (new-link semantics) | Compositions of `AppCard` + `SeverityBadge`/`StatusChip` + `AppButton`; QR/seal/paper-canvas/zoom-toolbar/stamp/signature/print-studio/schematic/activity-log rejected — do not build | Batch C screens 9, 12 |

Everything else composes existing `AppButton`, `AppTextField`, `AppCard`, `AppListTile`, `StatusChip`, `AppSelectableText`, `AppSegmentedControl`, `AppProgressRing`/`AppCoverageBar`, `EmptyState`/`ErrorState`/`LoadingSkeleton`, `OfflineBanner`.

---

## Batch A — screens 1–4 (dashboard subset, queue, create drawer, assign dialog)

**Screens:** 1 Dashboard (`1:299`, folder `02_1`), 2 Live Job Queue (`1:529`, folder `03_2`), 3 Create/Schedule (`1:2`, folder `01_3`), 4 Assign Technician (`1:821`, folder `04_4`).
**Blocking decisions:** D-F3-1, D-F3-2, D-F3-3, D-F3-4, D-F3-10.
**Build order:** S1 chrome → S2 stat card → S3 job/activity cards → S4 drawer/dialogs → screens 2, 4, 3, 1 (queue + assign first — highest traffic; drawer next; new-route dashboard last).

| Screen | In scope (existing data only) | Removed / omitted |
|---|---|---|
| 1 Dashboard (new `/dashboard` route/tab) | Status counts from `GET /api/v1/workshop/jobs` + client-side aggregation (in-progress, ready-to-finalize, finalized-today) + recent-jobs list; neutral chips | Bays, shifts, telemetry, turnaround, compliance/accuracy, dispatch, floor map, real-time feed, points-checked, review/sign-off, `Reports Sent` aggregate |
| 2 Queue | Search + raw-status filter chips (`All / In progress / Ready to finalize / Finalized`) + job cards (reference/customer, vehicle, template, `StatusChip`, assignee, chevron) + `+ New Job` → existing `createJob` | Bays, progress %, flags, review states, turnaround, live sync, export, batch reassign, bay matrix, photos (neutral tile) |
| 3 Create drawer | 420 right drawer (O3 desktop; derived bottom sheet mobile) with existing fields (customer, make/model/year, VIN/plate, phone/email, scope, `scheduledAt`, published-template dropdown `templateVersionOptions()`) → existing `createJob`; keep all validation/loading/error/empty states | Bay selection, fixed 60/110 tiers + durations, auto-assign, dispatch/telematics copy |
| 4 Assign dialog | Centred 512 dialog (wide) / derived bottom sheet <600 px; ACTIVE technicians (`displayName` + `emailMasked`) single-select; vehicle strip from existing job fields; Cancel/Confirm → existing `assignJob` + optional reason input | Skills, bays, workload, availability, estimates, stages, `#1042` renumbering (keep `JOB-…`), recall claims, `certified/Lead/Brakes L2/Powertrain` wording |

**Gates (must all pass before Batch B opens):**
- Level 1 fixtures: test-only Figma-structure fixture per screen (exact Figma strings, guarded from release) reaches **SSIM ≥ 0.98** with no unexplained diff > 4 px, measured at **1280** logical width, DPR 2, zero OS chrome.
- Level 2 product diffs: real product screens measured against the same frames; every difference is listed and each traces to a slot-sheet row (no unexplained region).
- Geometry + text-style tests: key boxes (header, cards, buttons, fields, nav) within 2 logical px where intentionally copied; every expected string present (or AR translation); zero forbidden terms (deny-list lint).
- Overflow matrix: **1280 / 900 / 600** + phone derived layout where applicable (<600 sheet fallback); EN + AR (RTL lint + structural mirroring + native-speaker review; AR has no pixel gate); 1.0×/1.5×/2.0× text; reduced motion; touch + keyboard + screen-reader pass; empty/error/loading/offline/disabled/focus states.
- Contrast: every semantic text pair ≥ 4.5:1 (normal) / 3:1 (large); UI-component pairs ≥ 3:1; no raw hex/EdgeInsets/fontSize/radius in feature code (scan test).
- Full suites: `flutter analyze --fatal-infos` clean; existing admin tests + new tests pass; artifacts committed under `docs/ui/figma/fidelity/f3a/<screen>/` (`figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json`, `REPORT.md` with accepted residuals, owner, date).

## Batch B — screens 5–8 (staff, add-staff sheet, template list, builder workbench)

**Screens:** 5 Staff Management (`1:1026`, folder `05_5`), 6 Add Staff (`1:1642`, folder `07_6`), 7 Template List (`1:1307`, folder `06_7`), 8 Template Builder (`1:1882`, folder `08_8`).
**Blocking decisions:** D-F3-2, D-F3-3, D-F3-5, D-F3-10 (plus D-F3-1 chrome follow-on).
**Build order:** S1 chrome → S2 metric/stat card → S3 staff/template cards → S4 480 right-sheet → S5 grid cards → S6 sequence/workbench → screens 5, 6, 7, 8.

| Screen | In scope (existing data only) | Removed / omitted |
|---|---|---|
| 5 Staff (read-only roster) | Existing `GET /api/v1/workshop/staff` list + client-side role/status counts; filter chips (`All / Technicians / Admins` from real `StaffDto.role/status`); restyled cards (`displayName` + `emailMasked` only) | Shift/live counts, bay/shift/skills/certifications/levels/hours/NFC/terminal/roster-export/shift-rules/availability toggle + all three metric computations; `Lead Inspector/Supervisor/Lead Master` titles |
| 6 Add-staff sheet | Fixed-Technician 480 right-sheet: Full Name → `displayName`, Email → `email`, Temporary Password → `initialPassword` (12–128 `PasswordPolicy`) + Cancel/Create → existing `createTechnician` + `accountCreated`/`actionFailed` ARB | Role picker (Admin creation), station allocation, magic-link/invite flow, permissions setup, backdrop bay/accuracy metrics, full-email display, sample password |
| 7 Template list | List (name · `serviceType` · `v{versionNo}` int · `itemCount` · status chip), open/create, versions/audit, Edit→new-draft; 3-col grid restyle; `Total Checkpoints ΣitemCount` + `updatedAt` relative labels | Custom tags/descriptions/photo-gate/cycle/PPE/bay fields, completion/compliance/audit metrics, list/grid preference, JSON export, bay binding, DOT/ISO/certification/`Master Inspector` gate, semver, hardware claims |
| 8 Builder workbench | Master catalog browse (approved items only) + tap-to-add + move-button reorder (drag visuals wired to existing actions) + save draft/publish/retire/versions + locked pills + EN/AR preview sheet + `Publish` → `POST .../{id}/publish` | Autosave, DnD backend, per-item Active/Automated, numeric ranges, AI/telemetry/BT/OBD, QA/ISO engine, time estimates, `of 14`, custom-item creation, semver |

**Gates (must all pass before Batch C opens):** same gate family as Batch A — Level 1 SSIM ≥ 0.98 per screen at 1280; Level 2 product diffs vs slot sheet; geometry + text-style tests; overflow matrix 1280/900/600 + phone derived; EN+AR; a11y; full suites after the batch; artifacts under `docs/ui/figma/fidelity/f3b/<screen>/`. Screen 6 sheet side in RTL and mobile-sheet behaviour recorded as derived (no fidelity claim).

## Batch C — screens 9–10 + 12 viewer/preview subset and 11 hold/decision

**Screens:** 9 Report Viewer (`1:2236`, folder `09_9`), 10 Share-Link Deactivation (`1:2502`, folder `10_10`), 12 PDF Preview (`1:2857`, folder `12_12`), 11 Settings (`1:2645`, folder `11_11`) — **held per D-F3-8**.
**Blocking decisions:** D-F3-6, D-F3-7, D-F3-9, D-F3-8, D-F3-10.
**Build order:** S1 chrome → S7 report container/coverage/findings → screen 10 dialog → screen 9 subset → screen 12 gated preview → screen 11 decision record (no build).

| Screen | In scope | Removed / held |
|---|---|---|
| 9 Viewer subset | Allowlisted snapshot fields; coverage counts (labelled coverage); key-findings list; masked delivery status; `Send/Retry` (new-link semantics); gated `Download PDF` (`pdfReady && pdfDownloadEnabled`); factual locked-state line | Certification/seal/QR/signature/score/`Passed/Cleared/Verified` verdicts, full VIN, measurements, ledger/scheduling, read receipts, `Resend` wording, second-vehicle line, telematics/ISO/URN claims |
| 10 Deactivation dialog | 448×576 dialog restyle (`ConfirmDialog` + 5 `AppSelectableText` reason codes + optional note + destructive confirm); mandatory O8 copy: blocks future link access at origin for all active links of the version **and copies/screenshots/PDFs already shared cannot be recalled**; generic `logged` line | Free-text-only reason, audit-ID display, IP/device/view tracking, guessable-URL preview, portal-role wording |
| 12 Gated preview | Sidebar metadata from real `pdfReady/version/finalizedAt/snapshotHash` (int version); gated download + consent-flow send/retry with `recipientMasked`; bilingual posture | Orientation switch, high-res-originals toggle, seal stamp, direct print, certificate branding, full VIN/plate/email, stamp/signature, English-only treatment, invented sizes/measurements/page counts |
| 11 Settings | **HELD — do not build.** At most existing identity (`name`/`branchName`) read-only behind a later-approved PUT/permissions/validation design; fix the sync-pill overflow defect only if a settings UI is ever approved | Whole settings surface as drawn (route, PUT, contact/region/default-template/auto-send/photo-policy/bay/telemetry/sync, DOT/licence/compliance claims, US-sample defaults) |

**Gates (must all pass to close F3):** same gate family — Level 1 SSIM ≥ 0.98 per built screen (9, 10, 12) at 1280 (screen 11 has no fixture — held); Level 2 product diffs vs slot sheet; geometry + text-style tests; overflow matrix 1280/900/600 + phone derived; EN+AR; a11y; full suites after the batch; artifacts under `docs/ui/figma/fidelity/f3c/<screen>/`. Screen 11 gate is the signed hold decision (D-F3-8), not a fidelity report.

---

## Verification harness (shared, all batches)

- Renderers: Flutter widget/golden tests with bundled fonts at logical 1280 (derived 900/600/phone via responsive rules), DPR 2, `MediaQuery` insets zero; no OS chrome in captures.
- Fixture classes: Level 1 test-only Figma-structure fixtures (exact Figma strings, guarded from release bundles, PII/scan-guarded) for the SSIM gate; Level 2 product fixtures (neutral, non-PII) for semantic/behaviour tests.
- Comparison: SSIM global + per-64×64 tile, RMSE + mean absolute error per channel, ΔE2000 (% > 2 JND, % > 5), diff bounding boxes, key-box geometry (2 logical px), exact text/translation presence, zero forbidden terms.
- No "pixel-perfect" claim. Every residual lists cause (font rendering, raster provenance, safe copy change) and needs written owner acceptance; without acceptance the screen fails.
- Tooling (no product code): `tools/figma_fidelity/`; specs/fixtures under `docs/ui/figma/fidelity/`.

## What was not verified

- Server field inventory beyond cited controllers/DTOs (no server run).
- Metric/formula definitions behind dashboard/telemetry/compliance/timing values.
- `Pending Review` → `READY_TO_FINALIZE` intent for every slot (a new reviewer state stays banned regardless).
- Reassignment-reason required-vs-optional; audit-ID policy; full-VIN internal path; station/bay reality; magic-link design; roster-PDF/NFC reality.
- Arabic/RTL layouts and 200% text (no Arabic frame in exports); token re-measurement beyond cited values.
- No versions, licences, measurements, or endpoints invented here. No batch starts in F3-0.
