# F3 decisions needed — Workshop Admin screens 1–12 (F3-0 planning only, no build)

**Project:** TrueReport
**Phase:** F3-0 Steps 3–4 (planning only — no code, server, or data change)
**Date:** 6 November 2026
**Sources:** `docs/ui/figma/f3-slot-sheet.md` (34 rows + folder↔screen map + 10 owner decisions + 12-item server-change list + per-screen classifications); `docs/ui/figma/specs/workshop/01–12`; `docs/ui/figma/c0-admin-accounts-slot-sheet.md`; owner decisions O3–O10 (`docs/ui/figma/decisions.md` §F3-0); locked rules master.md §1–2; route inventory `client/apps/admin_app/lib/src/admin_router.dart`, `pages/workshop_admin_home.dart`.
**Cost scale:** S ≤ ~1 dev-week; M ~1–3 dev-weeks; L > 3 dev-weeks or needs server/data/security change.
**Rule:** every decision keeps the Figma slot/size/style; only text or data that would be false or unsafe changes, as a same-slot neutral replacement. No invented versions, licences, measurements, endpoints.

**Current admin_app inventory (grounding):** router exposes only `/signin`, `/platform`, `/workshop`, `/unauthorized` (`admin_router.dart:32-45`). Workshop shell `WorkshopAdminHomePage` has exactly 3 tabs — Jobs, Staff, Templates (`workshop_admin_home.dart:49-69`) — backed by `jobs_tab.dart`, `staff_tab.dart`, `templates_tab.dart`, plus pushed pages `job_form_page.dart`, `template_builder_page.dart`, `template_version_page.dart`, `report_page.dart`. There is **no** `/dashboard` route/tab, **no** `/settings/workshop` route, **no** station/bay/shift/telemetry/dispatch endpoint. Existing endpoints reused below: `GET/POST /api/v1/workshop/jobs`, `POST .../jobs/{id}/assign`, `GET /api/v1/workshop/staff`, `POST /api/v1/workshop/technicians`, template CRUD/publish/retire/versions/preview, `POST .../jobs/{jobId}/deliveries`, `POST .../jobs/{jobId}/link/revoke`, `GET .../jobs/{jobId}/report/pdf`.

---

## D-F3-1 — Dashboard scope (screen 1): O4 subset vs holding the screen

**Slot-sheet rows:** 1-dashboard rows — bay pill (`1:487`), header search, user chip, `TELEMETRICS • REAL-TIME` eyebrow, shift toggle, `Dispatch Bay` CTA, 3 KPI cards, 3 activity rows, telemetry block (`76% CAPACITY`, `45 mins` target, `38 mins` median, `99.4%` compliance, `View Detailed Floor Map`). Classification: "Needs new data or server change / conflicts with locked rule (as drawn)"; O4-compliant subset is UI work only.
**Owner rule:** O4 — dashboard numbers only from existing data (counts by status, in progress, ready-to-finalize, finalized today).

| Option | Cost | Consequence |
|---|---|---|
| **A. Build O4 subset only** (new `/dashboard` route/tab + stat-card composition; status counts from existing `GET /api/v1/workshop/jobs` + client-side aggregation per `WorkshopJobController.java:33`; recent-jobs list; neutral chips) — RECOMMENDED | M (new route/tab + `AppStatCard` composition + aggregation + fixtures/gates) | Honest dashboard; bays/shifts/telemetry/turnaround/compliance/accuracy/dispatch/floor-map/real-time/points/review states and `Reports Sent` aggregate stay out until funded (server-change list items 1, 2, 3, 8, 12) |
| B. Hold the whole dashboard screen (no new route) | S | Zero new surface; queue (Batch A screen 2) remains the landing list; defers even the O4 subset |
| C. Build dashboard as drawn | L + rule change | Requires bay/shift/telemetry/dispatch models + review workflow + metric definitions; violates locked rules (no manager/review, no certification/score, master.md §1–2) — forbidden |

**Recommendation:** A, unless the owner prefers B to avoid a new route in F3. Either way, bay pills, `Bay Order`, shift toggles, `Dispatch Bay`, auto-assign-to-bay, floor map, live-sync strip, `Updated 4 seconds ago`, turnaround/latency/AI percentages are omitted (slot-sheet decision 3).
**Blocks:** Batch A (screens 1–4). Items 1–3 of slot-sheet decision list block dashboard/queue/chrome data work.

## D-F3-2 — Bay / shift / telemetry omission (screens 1–6, 11)

**Slot-sheet rows:** screen 1 bay/shift/telemetry rows; screen 2 `REAL-TIME DISPATCH`, `ACTIVE BAYS 06/08`, `AVG TURNAROUND 42m`, `Bay Order` sort, live-sync/footer strip rows; screen 3 `Select Date & Bay`, auto-assign-to-bay, dispatch/telematics helper; screen 4 base `ACTIVE DISPATCH BOARD / Shift A / 12 Bays Operational`, `#1040 Express`, `Bay 02`; screen 5 `LIVE ROSTER`, `Active Shift 6`, bay/shift metrics; screen 6 `STATION ALLOCATION STN 01–04`, shell `BAY ACTIVE`; screen 11 bay/telemetry/sync metrics. Server-change list items 1–2.

| Option | Cost | Consequence |
|---|---|---|
| **A. Omit everywhere; repurpose slots to existing data or drop** (neutral queue title + existing counts; date picker without bay; no bay pills/sort/shift/dispatch/floor-map/sync strip) — RECOMMENDED | S (copy/layout only, inside batches) | No new entity; some layouts look emptier; accepted residual per screen |
| B. Model bays/stations/shifts/dispatch/telemetry + live-sync channel | L each | New entities, occupancy, sort, sync SLA, hardware scope; separate ADR + F6 track, never smuggled into visual refresh |
| C. Hardcode sample bay/shift/telemetry values | S (forbidden) | Violates "no invented data/measurements"; creates inconsistent counts (`06/08` vs `12/14`) — forbidden |

**Recommendation:** A.
**Blocks:** Batches A and B (screens 1–6 chrome/cards/drawers) and Batch C screen 11 hold.

## D-F3-3 — Role labels: Technician-only per O5 (no Lead/Supervisor/Inspector)

**Slot-sheet rows:** screen 1 user chip `Marcus Vance / Lead Inspector`; screen 4 `certified specialist / Brakes L2 / Lead Tech / Powertrain`; screen 5 `Lead Inspector / Lead Master / Supervisor`, `EV Certified / Level 4`; screen 6 backdrop `(Lead)`, `Master Security Privileges`; screen 12 `Lead Inspector / Master Inspector ASE #40921`; All-family sample-people row. C0 sheet: roles are `WORKSHOP_ADMIN/TECHNICIAN/PLATFORM_ADMIN` (`HierarchyService.java`); workshop dialog fixed to Technician.
**Owner rules:** O5 (Add Staff = Create Technician); locked rules master.md §1–2 (no manager role/review).

| Option | Cost | Consequence |
|---|---|---|
| **A. Neutral same-slot replacements** — signed-in `displayName` + workshop name, no role claim; tech rows `displayName` + `emailMasked` only; omit `certified/Lead/Brakes L2/Powertrain/EV Certified/Level 4/Supervisor/Master` chips — RECOMMENDED | S | Compliant; skill/level/availability chips stay out until a qualification model is approved (server-change item 4) |
| B. Add qualification/skill/level catalogue + workload/availability | L | New model, audit, permission review; F6 track |
| C. Ship Figma role labels as drawn | S (forbidden) | Introduces a manager/certification layer; violates locked rules — forbidden |

**Recommendation:** A.
**Blocks:** Batches A (screen 4 picker) and B (screens 5–6 roster/dialog).

## D-F3-4 — Template tier mapping (screen 3; O7-adjacent)

**Slot-sheet rows:** screen 3 `Inspection Protocol Tier — Standard 60-Point 30m / Full Comprehensive 110-Point 75m` + descriptions; missing-required-fields row (template-version + scope). Spec 03: creation requires published `templateVersionId` (`JobCreateRequest.java`); client `createJob` (`admin_api.dart:761-791`).
**Owner rules:** O7 (builder within existing template rules); O10-adjacent (no fixed catalogue invention).

| Option | Cost | Consequence |
|---|---|---|
| **A. Tier cards select real `templateVersionOptions()` entries** (name + `itemCount` from `TemplateSummaryDto` via `WorkshopTemplateController.java`) in the same 356×72/90 card slots; omit `30m/75m` durations; drawer must add required template-version select + scope (+ keep phone/email/VIN/plate) — RECOMMENDED | M (drawer composition + dropdown wiring + validation states) | Submittable drawer; no fixed 60/110 catalogue; durations never invented |
| B. Add fixed-tier catalogue + duration model + single-field make/model parser | L | New schema/API; single-field parser explicitly not recommended by slot sheet |
| C. Ship 60/110-point + duration copy as drawn | S (forbidden) | Invented tiers/measurements; form still cannot submit without `templateVersionId`/`scope` — forbidden |

**Recommendation:** A.
**Blocks:** Batch A (screen 3 drawer).

## D-F3-5 — Builder scope (screen 8; O7, no autosave / DnD / custom items)

**Slot-sheet rows:** screen 8 `V2.4`, `SEQUENCE TOTAL 3 of 14`, `MANDATORY PHOTOS 1 flagged / Optical AI`, `AVG FIELD TIME 12 min`, `TELEMETRY LINK`, seq `Active/Automated`, `Value Range [0.0–8.5L]`, `Laser Gauge / Tire Quad-Sensor`, QA `ISO-9001 / ACTIVE POLICY`, `Autosave Active`, `Create Custom Diagnostic Item`, DnD drop zone. Server: `WorkshopMasterController` GET-only; `template_builder_page.dart` tap-to-add + move up/down/remove + draft/publish/versions + `_preview` EN/AR sheet.
**Owner rule:** O7.

| Option | Cost | Consequence |
|---|---|---|
| **A. Approved-items-only workbench** — tap-to-add + move-button reorder wired to drop-zone visuals; draft/publish/retire/versions; locked-rule pills from `evidenceRequirement/minPhotos`; `Preview Flow` → existing EN/AR sheet; `Publish` → `POST .../{id}/publish`; omit autosave/DnD-backend/per-item Active-Automated/ranges/AI-telemetry-BT-OBD/QA-engine/time-estimates/custom-item/semver/ISO — RECOMMENDED | M (workbench layout + `SequenceCard` + drop-zone visuals + locked pills) | No new capabilities; `V2.4` stays integer `versionNo`; `of 14` contradiction (`5` catalog / `3` cards) not shipped |
| B. Add autosave + DnD backend + custom-item write + QA engine + numeric ranges + telemetry | L each | State/semantics changes, Platform-only write conflict, policy engine; F6 tracks (server-change items 6, 7) |
| C. Ship AI/telemetry/ISO/autosave/custom-item copy as drawn | S (forbidden) | False capabilities + `WorkshopMasterController` GET-only violation + certification conflict — forbidden |

**Recommendation:** A.
**Blocks:** Batch B (screens 7–8).

## D-F3-6 — Report viewer verdict wording (screen 9; O9 neutral)

**Slot-sheet rows:** screen 9 `Passed Certification Stage`, `102 Cleared / Verified / Passed`, `98.1% Specification Compliance / Target >95.0%`, `Digital Certification Seal` + QR/signature/URN/ledger, `Telematics Protocol v4.8 • ISO/IEC 27001`, second-vehicle line, full VIN, odometer mismatch (`24,812 mi` vs `14,820 mi` screen 12), `HD Scans (18)`, `In Service: 11 Mo`, `Logged in Bay Ledger`, `Read Receipt Confirmed`, `Resend` wording, unconditional `Download PDF`. Existing: `ReportAdminDto/ReportSnapshot` coverage/key-findings/hash, gated PDF (`pdfReady && pdfDownloadEnabled`), send/retry creating a **new** link per ADR-0018, masked recipients.
**Owner rules:** O9 (our report/PDF, same allowlist); O6 (no review/approve/sign-off).

| Option | Cost | Consequence |
|---|---|---|
| **A. Neutral viewer subset** — allowlisted snapshot fields only; coverage counts labelled coverage (never a condition score); neutral status chips (`IN_PROGRESS/READY_TO_FINALIZE/FINALIZED` plain wording); `Send/Retry` (new-link semantics) + gated `Download PDF`; generic locked-state line; omit seal/QR/signature/score/`Passed/Cleared/Verified`/ledger/read-receipt/telematics/ISO/full-VIN/measurements — RECOMMENDED | M (document container + coverage band + finding rows from real fields) | No certificate layer; `Resend` relabelled; second-vehicle/odometer-mismatch samples never ship |
| B. Add compliance-score, verdict, seal/QR/ledger, read-receipt, measurement models | L + legal review | New DTOs, crypto/integrity claims, tracking surface (privacy conflict); F6 only |
| C. Ship certificate/seal/score/`Passed` viewer as drawn | S (forbidden) | Violates locked rules (no certification/score, masked VIN, derivatives-only, `Not an official certificate` posture) — forbidden |

**Recommendation:** A.
**Blocks:** Batch C (screens 9, 12).

## D-F3-7 — Deactivation copy (screen 10; O8)

**Slot-sheet rows:** screen 10 free-text-only `REASON FOR DEACTIVATION (REQUIRED) e.g. Disputed damage markup…`; `This will instantly block customer access`; `Action logged to Shop Audit Trail (ID #ACT-9902)`; `Live Shared / Viewed 14 mins ago`; guessable `share.shopflow.io/r/Taycan-8829`; full VIN/RO/bay; `Client Activity Log (IP 198.51.100.4 / Chrome Mobile / zoom)`; `Customer and fleet manager will no longer…`. Existing contract: `POST .../jobs/{jobId}/link/revoke` with mandatory `RevokeLinkRequest(reasonCode @NotBlank @Size(max=60), note @Size(max=500))`, `REVOCATION_REASONS = PRIVACY, SECURITY, LEGAL, CUSTOMER_REQUEST, OTHER`, `PUBLIC_LINK_REVOKED` audit; revocation immediate at origin across **all ACTIVE links** for the version (ADR-0018); real token is 256-bit random (hash stored, shown once).
**Owner rule:** O8.

| Option | Cost | Consequence |
|---|---|---|
| **A. Keep 5-code selector + optional note + generic `logged` line; copy states deactivation blocks future link access at origin for all active links of the version AND copies/screenshots/PDFs already shared cannot be recalled** (`ConfirmDialog`/`showAppConfirmDialog` + `AppSelectableText` + `AppTextField` restyle) — RECOMMENDED | S (dialog restyle + copy; no new endpoint) | Auditable; no audit-ID display, no IP/device/view tracking, no guessable-URL preview, no portal-role wording |
| B. Expose audit ID + view/IP/device log + human-readable URL + RO/bay fields | M–L + privacy review | New surveillance surface + audit-surface exposure (server-change items 8, 11); customer-portal wording needs product decision — F6 only |
| C. Ship free-text-only reason + `instantly block` + audit ID + activity log as drawn | S (forbidden) | Free-text-only cannot submit (missing mandatory `reasonCode`); tracking violates privacy; guessable URL misrepresents token model — forbidden |

**Recommendation:** A.
**Blocks:** Batch C (screen 10).

## D-F3-8 — Settings screen hold (screen 11; O10 — only existing settings; recommend holding screen 11)

**Slot-sheet rows:** screen 11 whole screen — `Workshop Settings / Save Settings` route; `Workshop Name`, `Contact Phone +1 (555) 382-9011`, `Address 4200 Industrial Parkway`, `Region: Northern Cal/Pacific Sector`, `DOT Certified #99401-AF / LEGAL ENTITY / certified slips / ANSI Tier-4`; `Default Template 100-Point Standard Check v2.0`; toggles `Auto-Send PDF to Customers (SMS+email on sign-off)` + `Mandatory Optical Photo Verification (≥4 photos…)`; metrics `ACTIVE BAYS 08/08 / AUTO-DISPATCH <140ms / OPTICAL AI 99.94% / Sync Status Shop Net Synchronized / zero downtime`; `Standard Flow / CONFIGURATION ENGINE`; sync-pill overflow defect (~68 px column wraps 3 lines). Server: `Workshop` identity fields only (`id/name/status/branchName/timezone = Asia/Dubai`); `WorkshopController` exposes only `GET /api/v1/workshops/{workshopId}` — no settings PUT; `admin_router.dart` has no `/settings/workshop` route.
**Owner rule:** O10.

| Option | Cost | Consequence |
|---|---|---|
| **A. Hold screen 11 entirely (no settings surface in F3)** — RECOMMENDED | S (no build) | Honest; avoids a dead-end route, consent-bypass auto-send, and invented telemetry; overflow defect moot until a settings UI is ever approved |
| B. Show read-only identity card (`name`/`branchName`) behind existing shell | S–M | At most existing fields, read-only; still needs route/permission/validation decision + US-sample cleanup; not a "settings screen" |
| C. Build settings as drawn (PUT, contact/region/default-template/auto-send/photo-policy/bay/telemetry/sync) | L + legal/consent review | Needs route + GET/PUT + permissions + validation + consent-safe automation + schema (server-change item 9); auto-send bypasses explicit per-channel consent gate (`POST .../deliveries`); DOT/licence/compliance claims conflict — forbidden in F3 |

**Recommendation:** A. If the owner wants any identity surface, B is the ceiling, behind a later PUT/permissions/validation approval.
**Blocks:** Batch C (screen 11 hold/decision — blocks nothing else; screen 11 must not open other batches).

## D-F3-9 — PDF preview scope (screen 12; O9 gated download only)

**Slot-sheet rows:** screen 12 `PDF Ready (v2.1) / Generated Oct 24 / 2.4 MB (Vector HQ) / SHA-256 #89c4… / Cryptographically Signed / AUDITED / Prepress Verified`; unconditional `Send Email to Client` + `Download PDF` + `Direct System Print`; `PRINT ORIENTATION A4 Portrait/Landscape`; toggles `Include High-Res Evidence (raw macro)` + `Stamp Physical Seal (ISO 17020)`; paper `TECHINSPECT / CERTIFICATE #1042 / COMPLIANCE CERTIFICATE / Directive 44B / Certified Facility / Licence #DOT-CA-994012 / APPROVED / ISO 17020 / BAY #04 / Cryptographically Signed`; vehicle bar full VIN `1FTBR…` + plate `7XYZ994 (CA)` + `14,820 mi`; pills `104 Checks Passed / 2 Flagged`; evidence `Macro 4K / Pass: 6.2 mm / 42mm paint`; stamp + ink signature `Marcus Vance / Master Inspector ASE #40921`; recipient `Apex Logistics Fleet Ops fleet-compliance@apex.io`; English-only paper. Real product: `ReportAdminDto.pdfReady/version/finalizedAt/snapshotHash`, gated `GET .../jobs/{jobId}/report/pdf` (`pdfReady && pdfDownloadEnabled`, public `/r/{token}/pdf` only if enabled, disabled by default), delivery with channel+language+consent, fixed `@page { size: A4; }` bilingual EN+AR server Chromium template (`print-report.html`, `vinMasked`, omits plate, derivatives EXIF-stripped, `Not an official certificate`).
**Owner rule:** O9.

| Option | Cost | Consequence |
|---|---|---|
| **A. Gated-download-only preview subset** — sidebar metadata from real `pdfReady/version/finalizedAt/snapshotHash` (int version, no `v2.1`); `Download PDF` only when `pdfReady && pdfDownloadEnabled`; `Send/Retry` via existing delivery consent flow with `recipientMasked`; bilingual paper posture; omit orientation/high-res/seal/direct-print/certificate/full-VIN/plate/email/stamp/signature/English-only treatment — RECOMMENDED | S–M (sidebar restyle + gate wiring; no paper canvas) | No print-studio; `2.4 MB/6.2mm/42mm/4K/Page 1 of 1` never invented; odometer-mismatch sample never ships |
| B. Add print studio (orientation switch, high-res originals, seal stamp, direct print, QR/signature/licence fields) | L + template/security review | Rejected O9 surface; high-res originals violate derivatives-only allowlist — F6 only, not recommended |
| C. Ship certificate preview as drawn | S (forbidden) | Certificate/DOT/ISO/licence/signature/full-VIN/plate/email/English-only all violate O9 + locked rules — forbidden |

**Recommendation:** A.
**Blocks:** Batch C (screen 12).

## D-F3-10 — Derived tablet / phone layouts (O3, no fidelity claim)

**Slot-sheet + specs:** all 12 specs use fixed 1280 frames (screens 1–12: 1280×1230.7/1125/1058/1120/1048/1024/1586/1251.5/1680.75-doc/1024/1674-form/1227.6); no tablet/phone/RTL frame in any export; shell rail 96 px + floating 80 px header; drawer 420 (screen 3) / 480 right-sheet (screen 6); modal 512 (screen 4) / 448×576 dialog (screen 10); 3-col grids (screens 5, 7); 404.3+659.7 workbench (screen 8).
**Owner rule:** O3 — 1280 px frames built as drawn; tablet/phone derived from the same tokens, labelled "derived, pending designer review", no fidelity claim.

| Option | Cost | Consequence |
|---|---|---|
| **A. Build 1280 as drawn; derive tablet/phone from the same tokens** (drawer/sheet → `showAppBottomSheet` under ~600–900 px; modal → bottom sheet <600 px; 3-col grid → 2-col/1-col; workbench → stacked) labelled derived, no SSIM gate on derived layouts; AR gate is RTL-lint + structural mirroring + native-speaker review — RECOMMENDED | S–M (responsive rules inside each batch) | Covers overflow matrix without forking tokens; derived layouts never claim pixel fidelity |
| B. Build 1280-only, no derived layouts | S | Fails overflow/a11y matrix (1280/900/600 + phone) and B3 responsive rule — not acceptable |
| C. Claim derived layouts match Figma | S (forbidden) | No Figma reference exists below 1280; any pixel claim is unfalsifiable — forbidden |

**Recommendation:** A.
**Blocks:** All batches (A, B, C) — responsive/overflow rule for every screen.

---

## Blocker map (which decisions block which batch)

| Batch | Screens | Blocking decisions |
|---|---|---|
| A | 1 Dashboard subset, 2 queue, 3 create drawer, 4 assign dialog | D-F3-1 (dashboard scope), D-F3-2 (bay/shift/telemetry), D-F3-3 (role labels), D-F3-4 (tier mapping), D-F3-10 (derived layouts) |
| B | 5 staff, 6 add-staff sheet, 7 template list, 8 builder workbench | D-F3-2 (bay/shift/station), D-F3-3 (role labels), D-F3-5 (builder scope), D-F3-10 (derived layouts) |
| C | 9 viewer subset, 10 deactivation dialog, 12 gated preview, 11 held | D-F3-6 (viewer wording), D-F3-7 (deactivation copy), D-F3-9 (PDF scope), D-F3-8 (settings hold), D-F3-10 (derived layouts) |

No batch starts in F3-0. F3-0 is planning + slot sheet + these decisions + build plan only.

## What was not verified

- Server field inventory beyond the cited controllers/DTOs (no server run; `equipmentIds`-style gaps assumed from specs/slot sheet).
- Metric definitions behind `76%`, `99.4%`, `87.5%`, `14.2 min`, `42m`, `140ms`, turnaround/median/flow, `Reports Sent` denominator.
- Whether `READY_TO_FINALIZE` is the intended meaning of every `Pending Review` slot (assumed per O6 neutral mapping; a new reviewer state would stay banned).
- Reassignment-reason required-vs-optional; audit-ID visibility policy; full-VIN internal permission/audit path; station/bay entity reality; magic-link/invite design; roster-PDF/NFC/shift-rules reality.
- Arabic/RTL paper/form/dialog layouts and 200% text behaviour (no Arabic frame in any export).
- Token hex/contrast re-measurement beyond the cited spec/slot-sheet values; no versions, licences, measurements, or endpoints invented here.
