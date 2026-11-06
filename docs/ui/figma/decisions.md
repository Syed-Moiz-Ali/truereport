# F1 design decisions (owner-approved)

**Project:** TrueReport
**Phase:** F1 — design system, shared components, gallery, fidelity harness
**Date:** 5 November 2026
**Status:** accepted for implementation. Anything left as "recommended" in `decisions-needed.md` is approved as written.

This file records the owner decisions supplied for F1. The ADRs are in `docs/ui/figma/adr/`.

| ID | Decision | ADR / note |
|---|---|---|
| A1 | **Hybrid** direction: Figma layout, shapes, type and component structure; our accessible colour/semantic rules | ADR-F1-001 |
| A2 | Emerald `#10B981` as a **fill only**, with a dark ink label (never a white label on `#10B981`). Deep green `#006C49` fill + white label is available behind one switch and shown side by side in the gallery. | ADR-F1-001 |
| A3 | Bundle Plus Jakarta Sans (Latin) and an Arabic sans (Noto Sans Arabic and IBM Plex Sans Arabic candidates; gallery shows both; native reviewer picks later). Noto Sans SC for `zh-Hans` only. Cyrillic fallback required. Licences and coverage recorded. | ADR-F1-002 |
| A4/A5 | Hybrid radii and spacing: add large-card radii 24/32 and extend spacing modestly. Outliers map to the nearest token and are listed. | ADR-F1-003 |
| A6 | Light-first. Dark mode is a derived theme from the same tokens; it is not a Figma fidelity target. | ADR-F1-001 |
| A7 | Build only components used by approved screens. | ADR-F1-004 |
| A8 | Brand: **TrueReport**. | ADR-F1-001 |
| B1 | Minimum text: 12 px labels, 14 px body, 16 px body for the technician flow. No 11 px text. | ADR-F1-002 |
| B2 | Targets at least 48 dp; 56 dp for primary technician actions. | ADR-F1-004 |
| B3–B5 | Responsive scrolling layouts, visible focus tokens, Arabic design pass before Arabic fidelity. | ADR-F1-004 |
| B6 | Consent switches must not be pre-ticked. A consent record is created only after an explicit action. Separate small privacy fix. | ADR-F1-005 |
| C1–C4 | Defer all: 360 pins, photo markup, tyre PSI/tread, BLE/OBD/NFC/hardware, signature pad, dashboards, settings screens, TOTP screen. None is built in any UI phase. | `gap-report.md`; F6 only by separate approval |
| D1–D3 | Safe subset only. Omit anything the model does not have. km, UTC+4 and AED via locale formatting. | `gap-report.md` |
| D6-a | Approved: test-only fidelity fixtures with Figma-like sample text, guarded from release builds. | ADR-F1-004 |
| E1–E6 | Public report: keep our information structure and allowlist; apply the Figma look. PDF download off by default. Coverage counts only (no score). No vehicle hero photo. Factual report fingerprint only, no tamper-proof/ledger/certificate claims. Keep light and dark. | ADR-F1-001, ADR-F1-003 |
| F1–F7 | Restyle current shells. Account creation stays Platform-Admin-only. Audit stays read-only. Master content stays draft/version/publish. Build dropdown and equipment UI with existing fields. Restyle the report viewer. | `gap-report.md`; no server/business changes |
| G1–G3 | Fidelity gate: structural + measured visual; SSIM ≥ 0.98; no unexplained difference > 4 px; every residual listed and accepted in writing. | ADR-F1-004 |

## Defaults adopted where the owner table says "recommended"

These are implementation defaults, not new product decisions:

- `A2` default = emerald fill `#10B981` + ink label `#1A1B1F`; alternative = deep green fill `#006C49` + white label.
- `A3` default Arabic face = Noto Sans Arabic for the first gallery build; IBM Plex Sans Arabic is shown next to it.
- `A4/A5` large-card radii = 24 and 32; spacing scale = 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Other Figma values are mapped to the nearest token and listed in `tokens.md`/the F1 report.
- `A6` light is the fidelity target; dark is a derived, tested theme.
- `B1` body = 14; technician body = 16; labels = 12 minimum.
- `B2` target = 48 minimum; primary technician action = 56.
- `G1` harness metric = SSIM + RMSE + ΔE2000 + key-box geometry, with a JSON and Markdown report per sample.

## Locked constraints for F1

- No change to business logic, API contracts, models, validation, permissions, state management or the server, except the approved consent default fix (B6).
- Locked rules still apply: immutability, public-report allowlist, no certification claims, no single score, Arabic RTL, WCAG 2.2 AA, no hardcoded colours/sizes/radii/shadows/endpoints in widgets.
- No runtime font downloads. No invented versions, licences, measurements or results.
- No commit in F1.
---

## F1 implementation status (5 November 2026)

- A1, A2, A3, A4/A5, A6, A7, A8, B1–B6 and D6-a are implemented as described above.
- C1–C4 remain deferred; no deferred feature component was built.
- E1–E6 and F1–F7 remain the rules for F5/F3/F4; F1 did not build those screens.
- G1–G3: the harness, gallery and measured reports exist. Three component-level samples are below the 0.98 SSIM threshold and are listed as residuals in 1-report.md; they are **not** accepted as passing yet.
- Owner decisions still pending: (1) accept or reject the 14 contrast exceptions, (2) accept or rework the three fidelity residuals, (3) choose the Arabic font after native review, (4) accept or reduce the 15.68 MiB Noto Sans SC cost, (5) decide whether PDF fonts must match the HTML stack.

---

## F2-A technician decisions (owner supplied, 5 November 2026)

These decisions apply to F2-A (technician screens 1 to 7). They are recorded here before implementation; unedited lines are approved.

| ID | Decision | Implementation evidence |
|---|---|---|
| P1 | **Primary button:** large primary CTAs (56 px, 19 px bold label) use option 2 (`#059669` fill, white label); smaller emerald buttons use option 3 (ink label `#1A1B1F` on `#10B981`). Figma-exact variants stay in the gallery only. | `AppButton.large` uses `brand.largeFill/onLargeFill` and `TrType.largeButton` 19/24 w700. Measured: white on `#059669` = **3.77:1**, which passes the 3:1 large-text threshold because the label is 19 px bold (>= 18.66 px bold). Ink on `#10B981` = **6.78:1**. `#059669` against white = **3.77:1** (UI boundary passes 3:1). Derived dark: `#002113` on `#34D399` = **8.90:1**; `#34D399` against `#121114` = **9.79:1**. |
| P2 | Borderless filled text fields approved as designed, with a visible label above the field and the F1 focus ring. | `AppTextField(labelAbove: true)` is used on every F2-A field. Measured field-fill boundary (`#F4F3F8` on white) = **1.10:1** light / **1.18:1** dark, below 3:1. It is listed in `deviations.md` as an accepted accessibility risk; the visible label and focus ring carry the affordance. |
| P3 | Remaining contrast exceptions accepted: 12 decorative divider tokens and 2 emerald fill-boundary pairs. | `contrast-after.md`: the F1 exceptions remain accepted. F2-A adds 2 field-fill failures under P2. F2-A's own 18 pairs per theme pass except the field-fill pair. |
| P4 | One `admin_app` stays. | No admin restructuring in F2-A. |
| P5 | Noto Sans SC stays bundled for now; verify and report whether Flutter web would otherwise download fallback fonts at runtime. | Verified in the technician web build: `FontManifest.json` lists MaterialIcons, Plus Jakarta Sans, Noto Sans Arabic, IBM Plex Sans Arabic, Noto Sans and Noto Sans SC; every file is under `assets/packages/design_system/assets/fonts/` (Noto Sans SC is 16,437,364 B in the web build). There is no `google_fonts` dependency and no network font request. Flutter web therefore does **not** download fallback fonts at runtime; missing glyphs use the browser's local system fallback. |
| P6 | Arabic font default: Noto Sans Arabic until a native reviewer decides. | `AppTheme.build(...)` default `AppArabicFont.notoSansArabic`; IBM Plex Sans Arabic remains selectable in the gallery. Arabic is marked derived, pending native review. |
| P7 | The Figma dock shows Intake / Fleet / Sync / Profile. We have no fleet feature: propose **Jobs, Sync, Profile**. Show both the 3-item product dock and the Figma 4-item layout in the gallery. | `TechnicianDock` is the product 3-item dock. `TechnicianFigmaDockPreview` is gallery-only, behind `FixtureGuard`. The gallery section is "Technician dock decision (P7)". No Fleet route or feature was added. |
| P8 | Fidelity gate: SSIM >= 0.98 and no unexplained difference > 4 px, using test-only Figma-text fixtures; a second measurement uses real product copy and lists copy-driven differences as residuals. Never claim "pixel-perfect". | 12 measured fixtures (6 screens x 2 variants) under `docs/ui/figma/fidelity/f2a/`. **The 0.98 gate was not reached on any screen** because P1/P2, the required removals and the screen-6 data gap change large regions. Measured values and residuals are in `f2a-report.md` and each per-screen `REPORT.md`. No "pixel-perfect" claim is made. |

### F2-A implementation status

- Screens 1, 2, 3, 4, 5 and 7 are implemented.
- Screen 6 (equipment checklist) is **not implemented**: the technician endpoint returns `equipmentIds` only (`EquipmentListDto`), with no names, descriptions, verification or pairing state. The existing equipment sheet now states that names are unavailable; no names/specs were invented.
- No server, API contract, model, validation, permission or state-management change was made.
- The screen-1 brand is TrueReport; the Figma `TechInspect` name, ISO claim, forgot-password and request-ID links are removed.

---

## C0 Workstream B — light-only theme (6 November 2026)

C0 supersedes decision `A6` (light-first with a derived, tested dark theme) and
the dark-theme half of `G1` (dark golden/fidelity/contrast coverage). The
product ships one theme: light. Details in
`docs/ui/figma/adr/ADR-F1-006-light-only-theme.md`. Historical rows above are
kept as record and are superseded for all new work, including the `A6` default
(`A6` light is the fidelity target; dark is a derived, tested theme), the
`E1–E6` "keep light and dark" rule for the public report, and any dark golden
or fidelity-variant coverage under `G1`.

---

## F2-A.1 technician decisions (owner supplied, 6 November 2026)

This phase supersedes P1, P2, P7 and every "deviation by default" from F1.1/F2-A.
The owner requirement is a 100% identical UI, UX, style and layout; only text or
data that would be false or unsafe may change, and each change keeps the same
slot, size, style, colour and position unless the owner approves otherwise.

| ID | Decision | Implementation evidence |
|---|---|---|
| I1 | **Primary button = Figma exact:** `#10B981` fill, white label, Figma size/weight, emerald glow, pill radius, label + arrow positions. Accessible alternatives stay behind one token switch that is off; the white-on-emerald contrast is an owner-accepted risk. | `FxButton` (primary) uses `Fx.emerald`, `Fx.white`, `Fx.label14`, `Fx.ctaShadow`; measured white on `#10B981` = **2.54:1** (below 4.5:1; listed in `contrast-after.md` and `deviations.md`). |
| I2 | **Fields = Figma exact:** white cards, soft shadow, icon + placeholder inside, 48 px height, 16 px radius, no label above, no filled lavender. | `FxTextField` draws the 48 px white shadowed card; `Semantics(label:)` supplies the field name invisibly; the whole card is the hit area. |
| I3 | **Targets:** keep Figma visual sizes; enlarge only the invisible hit area where the control is smaller than 48 dp. | Language segments use a 24 px visual with a 44 px hit row; password reveal uses a 44 px hit box; dock/icon buttons use a 44 px hit box around the Figma glyph. |
| I4 | **Bottom dock = Figma 4 slots** (Intake / Fleet / Sync / Profile) with Figma icons, positions and shadow. Fleet maps to a **Completed/Finalized** jobs list from existing finalized jobs. Owner must approve the mapping. | `FxDock` is four slots with the exported SVGs; the second slot opens finalized jobs through `onCompleted`. Label is `Finalized` in the product build; `Fleet` only in the test-only Figma fixture. **Pending owner approval.** |
| I5 | Fonts: **Plus Jakarta Sans** at the exact Figma sizes/weights/line heights/letter spacing; Arabic fallback Noto Sans Arabic. | All F2-A.1 styles read `Fx.text(...)` with the Figma metrics; the fonts are bundled (no runtime download). |
| I6 | Brand text `TechInspect` becomes `TrueReport` in the same slot/style. The logo slot keeps the Figma glow/layout; own mark used. | Login title is `TrueReport` at 26/32 w800; the 64 px mark sits in the same glow slot. The Figma `TechInspect` string is fixture-only. |
| I7 | Shadows, radii, spacing, colours and component structure = Figma values exactly; F1.1 shadow tests extended to every shadow used. | `Fx.cardShadow`, `Fx.pillShadow`, `Fx.ctaShadow`, `Fx.navShadow`, `Fx.upShadow`, `Fx.headerShadow`, `Fx.panelShadow` match the node effects; all screens use them. |

### F2-A.1 implementation status

- Screens 1–7 are rebuilt; screen 6 is now a full screen but still shows IDs only
  because the API has no names/specs/verification.
- 7/7 geometry test cases pass. 55 key nodes are asserted; text nodes are checked
  for position/line box, and three card heights whose finder includes the parent
  gap are checked for position only. Intrinsic text width is font-metric
  dependent and is recorded as a residual.
- Visual fidelity: measured SSIM is **0.79111–0.97210** (fixture a) and
  **0.79974–0.95233** (fixture b). The **0.98 gate is not met**; every residual is
  listed in `deviations.md` and each per-screen `REPORT.md`.
- No server, API contract, model, validation, permission or state-management
  change was made.
---

## F2-A.2 owner decisions and measurement correction (6 November 2026)

The owner confirmed the identical-first rule from F2-A.1 and added these decisions.

| ID | Decision | Implementation |
|---|---|---|
| J1 | Fleet dock slot maps to **Finalized** jobs, using existing finalized-job data; Figma icon and position kept. | `FxDock` keeps four slots; the second slot opens finalized jobs (`onCompleted`). Product label is `Finalized`; the test-only Figma fixture keeps `Fleet`. |
| J2 | Keep neutral **Password help** and **Contact Admin**, same slot/size/style as the Figma text. | `SignInCopy` defaults and the Figma fixture use those strings. |
| J3 | Replace the security line with **“Authorised workshop staff only”**, same slot, icon, size and style. No security or certification claim. | `SignInCopy.securityLabel` default and the Figma fixture use the new line. The forbidden-term product lint passes. |
| J4 | Signature capture stays out of scope. | The 350×176 decision slot holds explicit Granted/Refused, not a signature pad. Recorded as an approved residual. |
| J5 | Add a small read-only equipment API extension: `labelEn`, `labelAr`, `code`, `status`, `sortOrder`, from existing master equipment data. No schema/write/permission change. | Server returns `equipmentIds` plus `items`; Flutter parses `EquipmentItem` and shows the real label/code/status. Server tests pass (65 run, 0 failures, 6 Docker-skipped). |
| J6 | Logo slot matches the preview: soft green glow only; no solid TR tile. Report the export JSON node. | Login now renders only the blurred emerald glow in the 80×80 slot. The export JSON contains an empty `TechInspect Minimal Logo` frame at x163,y104,64×64 (no vector/raster asset); the preview shows only the glow. |
| J7 | Fidelity harness may use the Figma exported raster photos/avatars in test-only fixtures, guarded from release builds. | Capture decodes the exported avatar/vehicle PNGs into `ui.Image`s passed only by test helpers; the images are not in any pubspec asset list and not referenced from `lib/`. A guard test proves this and checks the web asset manifest. |

### Measurement correction (F2-A.2)

- `debugDisableShadows` **was true** during the F2-A.1 captures and goldens. Evidence: `AutomatedTestWidgetsFlutterBinding.disableShadows => true` in the pinned Flutter 3.47.9 SDK; the F2-A.2 harness test asserts the default and the override.
- F2-A.2 sets it to false for capture/goldens, guards every capture path, and restores the previous value before the test body ends (the binding verifies painting variables at that point).
- The reference crop origin was also wrong: the Figma export adds an asymmetric shadow margin. Pixel analysis finds the white frame at x=60 (or 40) and **y=14**; the F2-A.1 crops used y=59 (or 7). Fixtures were corrected to y=14.
- The earlier "shadow blur matches" claims were invalid. Component samples re-measured with real shadows: primary button 0.99520→0.99622; delivery card 0.99198→0.99261; result selector 0.98340→0.98756.

---

## C0 cross-cutting decisions (6 November 2026; supersedes A6, G1-dark half, RQ3, ADR-0011)

| ID | Decision | Implementation |
|---|---|---|
| C-A1 | Strict chain: Platform Admin creates Workshop Admins; Workshop Admin creates Technicians own workshop only. Platform cannot create technicians. | `HierarchyService.createUser/createTechnician`, `StaffController`, role matrix tests. See `ADR-C0-001`. |
| C-A2 | No invitations: endpoints/tokens/acceptance/pending filter removed. ACTIVE on creation. Tables retained, drop proposed separately. | `POST /platform/invitations` 404, `POST /auth/invitations/acceptance` 401 anon/404 authed; `pendingInvitations` dropped. |
| C-A3 | Admin password reset same scoping, revokes sessions, audited without passwords. | `POST .../password-reset` x2; `ACCOUNT_PASSWORD_RESET`. |
| C-A6 | No forced password change at first login (owner-accepted risk). | Recorded in risk register; designed screen deferred. |
| C-B | Light only: dark ThemeData/tokens/goldens/CSS removed; `color-scheme: light`. | `ADR-F1-006`; generator `--check` light-only; `contrast-after.md` light-only. |
| C-C | Full localization: no hardcoded visible/accessibility text in `lib/`; EN+AR full, ru/zh-Hans ready; server bundles EN+AR; ARB mojibake fixed; figmaText removed to test-only override. | `i18n-inventory.md`, `i18n_source_scan_test`, `ReportDeliveryBundleParityTest`, `ApiErrorContractTest`, `figma_l10n_override`. |

---

## F2-B.2 owner decisions (6 November 2026)

### L1–L8 (from F2-B.1, recorded here for F2-B.2 traceability)

| ID | Decision |
|---|---|
| L1 | Dedicated retry ARB key; fix wrong `retryLabel:l10n.search` reuse. |
| L2 | Remove Arabic-pending-review sentence from customer messages/PDF; keep in docs/risk only. Arabic blocked for real customers until native review. |
| L3 | Each bilingual-PDF language section purely one language. |
| L4 | Delete unused dark values from `tokens.json`; remove light alias. |
| L5 | GET responses keep emails masked. |
| L6 | First-login forced password change stays deferred (risk A6). |
| L7 | Method-level authorization on all controllers incl. `GET /api/v1/workshops/{id}`; inventory test fails on unauthorised method. |
| L8 | Same-slot neutral replacement (hide only if unsafe); screen 11 three-way pill + secondary row; screen 14 slide exact + invisible alternative; screen 16 real report + delivery; finalize full VIN only where slot requires, else last-4. |

### M1–M8 (F2-B.2)

| ID | Decision |
|---|---|
| M1 | Four severities; no P0–P3 mapping; same slot/style. |
| M2 | Finalize gate = server-enforced only. |
| M3 | Same-slot neutral localized legal text; no GPS. |
| M4 | Full VIN on technician-side screens; last-4 on success; never public. |
| M5 | Tick/coverage = answered, never passed/compliant. |
| M6 | Raw statuses to plain ARB wording. |
| M7 | Fleet/avatar/bay/hardware same-slot neutral or real same-shape data; hide only if unsafe. |
| M8 | Barcode slot = neutral open-item action. |

### Conflict check vs `f2b-slot-sheet.md`

NO conflict found (sheet already implements M1–M8; triage verified).

Nuance: M4 broadly says full VIN on technician-side screens while sheet row 89
keeps full VIN to the finalize slot only (other tech screens show reference) —
sheet-wins per instructions + owner note that broadening M4 needs approval.

---

## F2-B.3 owner decisions (6 November 2026; unedited lines approved)

| ID | Decision | Implementation |
|---|---|---|
| N1 | Two-level fidelity: Level 1 test-only Figma-structure fixture per screen (Fx kit, exact Figma structure/data) must reach SSIM ≥ 0.98 with no unexplained diff > 4 px; Level 2 real product screens measured, differences only where the slot sheet says so, each with a numeric effect. Gate not lowered. | Level 1 fixtures + artifacts under `docs/ui/figma/fidelity/f2b3/` (11: 0.98311, 13: 0.98209, 14: 0.98312, 15: 0.98039, 16: 0.99075 pass; 09: 0.97362 below gate with quantified residual). Level 2 product-copy artifacts under `fidelity/f2b/` with slot-sheet differences. See `f2b3-report.md`. |
| N2 | Visual waiver (owner option): waived only if the owner states in writing that screens 9/11/13/14/15/16 look identical on device; default not waived. | No waiver statement on record — Part 2 executed in full. |
| N3 | Re-baseline the 14 F2-A goldens (and any other intentionally changed golden) after a visual check of each new render against its Figma; record each in `golden-rebaseline.md`. | Done: 14/14 regenerated + passing; record in `docs/ui/figma/golden-rebaseline.md` (copy-churn cause, residuals R1–R4). |
| N4 | Delete dark-only tests (light-only decided); do not delete any other failing test. | Verified by search across all client suites: no dark-only test exists (removals already in the committed tree). Nothing deleted. |
| N5 | M4 VIN scope not broadened: full VIN only in the Figma slot recorded in the slot sheet. | No VIN change in F2-B.3; finalize slot only, last-4 elsewhere. |