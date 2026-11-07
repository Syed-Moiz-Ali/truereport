# Screen 11 — Workshop Settings (F3-0 group C)

- Figma source: `docs/ui/figma-export/Workshop_admin_figma/screens/11_11._Workshop_Settings/11._Workshop_Settings.json` (node `1:2645`, `serializedNodeCount: 212`), visual ref `11._Workshop_Settings@2x.png`
- Prior spec (read, not edited): `docs/ui/figma/specs/workshop_admin/11-workshop-settings.md`
- Frame: **1280 × 1674**, `VERTICAL`, white — width 1280 confirmed as drawn (O3). Long height = form scroll; save bar sits at form end, not fixed.
- Root children: `Background` (`1:2646`, 1280×1674, left pad 96) → `Header` (`1:2815`, 1184×80) → `Aside` (`1:2838`, 96 wide).

## Node-level layout (as drawn)
- `Main` 1184×1674 at x=96, padding 80 top / 80 sides / 48 bottom; centered content 1024 wide, gap 48.
- Title block: `CONFIGURATION ENGINE` badge, H1 `Workshop Settings`, subtitle `Configure shop telemetry, compliance protocols, and customer dispatch.`; right `Quick Facility Snapshot Pill` (`Sync Status`, `Shop Net Synchronized` — wraps to 3 lines in a ~68px column, an overflow defect).
- Metrics row (1024×96, 3 × 325.3 cards, radius 24): `ACTIVE INSPECTION BAYS 08 / 08 Operational`, `AUTO-DISPATCH LATENCY < 140 ms`, `OPTICAL AI INTEGRITY 99.94%`.
- `Business Profile` card (1024×479, radius 24, padding 40): `Public credentials stamped on certified vehicle inspection slips`, `LEGAL ENTITY` pill; fields `Workshop Name = Apex Fleet Hub — Bay District`, `Contact Phone = +1 (555) 382-9011`, `Address = 4200 Industrial Parkway, Suite 4B`; chips `Region: Northern Cal/Pacific Sector`, `DOT Certified #99401-AF`.
- `Preferences` card (1024×540): `Inspection routines, optical validation, and distribution rules`, `Standard Flow` chip; `Default Template = 100-Point Standard Check v2.0` (`Compliant with ANSI Tier-4 EV & Combustion Fleet standards`); toggle `Auto-Send PDF to Customers` (`Immediately deliver cryptographic-stamped PDF summaries via SMS & email upon technician sign-off.`); toggle `Mandatory Optical Photo Verification` (`Forces technicians to capture at least 4 high-resolution angle photos before clearing safety critical faults.`). Both toggles drawn ON.
- Bottom row: helper `All changes sync to shop fleet nodes instantly with zero downtime.` + `Save Settings` (emerald, ~200×56).

## Components → `design_system`
- Form cards → `AppCard` + `SectionHeader`; text inputs → `AppTextField`; default-template row → dropdown/`AppListTile` pattern; toggles → Material `Switch` (no dedicated token); save → `AppButton` primary; metric/sync/licence chips → `StatusChip`. All are composable from existing components — but there is **no settings route, model, or endpoint** behind them.

## Assets
- 26 assets per JSON: 24 single SVG icons + 2 composed (`Nav`, `Aside`). **0 raster.** All non-shell graphics are 16–20px icons.

## States shown / not shown
- Shown: populated defaults, template selected, both toggles on, green sync status.
- Not shown: loading, empty/no-default-template, validation errors, save in-progress/success/failure/conflict, disabled/read-only fields, offline, unsaved-changes, Platform-Admin-vs-Workshop-Admin split, 200% text, RTL/Arabic, phone/tablet.

## Element → data/endpoint/state mapping
| Figma element | Maps to | Verdict |
|---|---|---|
| `Workshop Settings` route + `Save Settings` | No `/settings/workshop` route (`client/.../admin_router.dart` exposes only `/workshop` shell); `WorkshopController` exposes only `GET /api/v1/workshops/{workshopId}` | DATA GAP — needs new route + GET/PUT, permissions, validation |
| `Workshop Name` | `Workshop.name` / `branchName` (`server/.../tenancy/Workshop.java`: only `id/name/status/branchName/timezone = Asia/Dubai`) | Matches existing feature (identity fields only) |
| `Contact Phone`, `Address`, `Region` | No phone/address/region columns on `Workshop` | DATA GAP (business contact data; US sample must not become default) |
| `DOT Certified #99401-AF`, `LEGAL ENTITY`, `certified vehicle inspection slips`, `ANSI Tier-4…`, `compliance protocols` | No licence/compliance fields | LOCKED-RULE conflict (O6/O10: certification/licence/compliance claims without a verified source) |
| `Default Template 100-Point Standard Check v2.0` | `TemplateSummary.name/currentVersion` (integer versions; no `v2.0` format; no stored workshop default) | Needs new data (default-template setting does not exist) |
| `Auto-Send PDF to Customers` + SMS+email on sign-off | Explicit `POST /api/v1/workshop/jobs/{jobId}/deliveries` with per-channel consent (`report_page.dart` `_send`; `docs/phase-7/00-decisions.md` §2) | LOCKED-RULE conflict — auto-send bypasses the consent gate and the deliberate manual flow; needs new automation + consent design, not a toggle |
| `Mandatory Optical Photo Verification ≥4 photos before clearing safety-critical faults` | Per-item `evidenceRequirement/minPhotos` with master-lock rule (master can only be strengthened, never weakened) | Needs server change with master-lock validation; `clearing` wording is unsafe |
| `ACTIVE INSPECTION BAYS 08/08`, `AUTO-DISPATCH LATENCY <140ms`, `OPTICAL AI INTEGRITY 99.94%`, `Sync Status / Shop Net Synchronized`, `zero downtime` | No bay/sync/latency/AI/fleet-node concepts in server or client | DATA GAP + never-invent-measurements rule |
| `Standard Flow`, `CONFIGURATION ENGINE` | No stored setting | DATA GAP (label only) |

## Classification
**Needs new data or server change — do not build as a settings screen.** Per O10 only settings that exist may be shown: workshop identity (`name`/`branchName`) is the sole mappable surface, and even it has no PUT endpoint. Business credentials, DOT licensing, region, default template, auto-send/dispatch triggers, telemetry, and sync claims are all data gaps or locked-rule conflicts.

## Locked rules applied (O10)
- Ship at most the fields that exist (`name`, `branchName`); everything else stays out until schema, API, permissions, validation, and (for delivery) consent-safe automation exist.
- No DOT/licence/compliance stamps, no `certified` slip copy, no US-sample defaults in a UAE-first product (`timezone = Asia/Dubai`).
- No auto-send toggle; delivery stays explicit per-send with channel consent.
- No invented telemetry (`08/08`, `<140 ms`, `99.94%`, sync, zero-downtime).

## New-component list
- None approved. Metric pods, sync pill, licence chips, template-selector row, settings toggles, and save bar are all **rejected** until the backing model/endpoints exist. If identity editing is later approved, compose it from `AppCard` + `AppTextField` + `AppButton`.

## Could not verify
- Which fields (if any) Platform Admin vs Workshop Admin may edit — no permission model found in this pass.
- Whether contact phone/address are required business fields — needs schema/retention decision.
- Template-version display format and the real default-template source — not resolved in this pass.
- Save/sync/conflict/unsaved-changes behaviour and Arabic/RTL form layout — not in the export.
