# F1.1 deviations from the Figma

**Project:** TrueReport
**Date:** 5 November 2026
**Rule:** a deviation is allowed only for (1) content/privacy, (2) a measured
text-contrast failure, or (3) language coverage/RTL. Everything else must equal
the Figma value. This file lists every deviation; `owner-approved: no` items are
open and must not be presented as accepted.

**Exact matches are not listed here.** The token revert (surface, shadows,
radii, spacing, type metrics), the button border/dividers removal and the
component structure rebuilds are exact Figma values; they are recorded in
`f1-fidelity-audit.md`.

---

## Approved deviations

| ID | Area | Figma value | Our value | Reason (allowed category) | Measured effect on fidelity | Owner-approved |
|---|---|---|---|---|---|---|
| D-01 | Product type scale | 11/14 w600 captions; 13/18 w400 body (371 + 289 uses) | 12/16 w600 labels; 12/18 w400 body; 14/20 body | Accessibility/language: F1 decision **B1** sets a 12 px product minimum | None on the exact samples: `FigmaType` uses the Figma 11/13 metrics for the exact variants. Product copy is 1-2 px different. | **yes** (`decisions.md` B1) |
| D-02 | Primary button label (product) | White `#FFFFFF` on `#10B981` | Ink `#1A1B1F` on `#10B981` | Measured contrast: white is 2.54:1; ink is 6.78:1. F1 decision **A2** | Exact variant (option 1) measures SSIM **0.99520**. The product label colour is an intentional, unmeasured deviation. | **yes** (`decisions.md` A2), but the final button choice is **re-opened** (section 3.4) |
| D-03 | Emerald fill as a control fill | `#10B981` fill | `#10B981` fill | Measured contrast: 2.54:1 against white, below 3:1 for a UI boundary; A2 approves it as a fill only | The exact sample is the Figma fill; the ink label (6.78:1) and the Figma shadow carry the affordance. Never used as text/icon. | **yes** (A2) |
| D-04 | Result vocabulary (product) | `Pass` / `Minor` / `Major` | `No issue observed` / `Attention recommended` / `Defect found` | Content/privacy: locked Phase 1 result vocabulary; "Pass"/"Minor"/"Major" are not the approved product vocabulary | None on the exact sample: it uses the Figma labels. Product labels are longer; the toggle text widths change. | **yes** (Phase 1 vocabulary, `decisions.md`) |
| D-05 | Three extra result states | Not drawn in the Figma toggle | Secondary chip row: `Not checked`, `Not applicable`, `Could not verify` | Content/data: the product has six results; Figma draws three. The owner instructed the extra three as a secondary row | No effect on the Figma node crop (the extra row is below the 350 x 70 node). Visual language is the same fill/radius/type. | **yes** (F1.1 instruction) |
| D-06 | Delivery card copy (product) | `WhatsApp` / `Sent`; `Fleet Portal` / `Synced` | `Report link` / `Sent`; `Workshop copy` / `Synced` | Content/privacy: no portal feature; public-report allowlist. Figma sample copy is test-only | Exact fixture uses the Figma copy and measures SSIM **0.99198**. The product card differs only in text runs. | **yes** (locked public-report/portal rules) |
| D-07 | Product result option height | 40 px option inside a 52 px pill | 48 px option inside a 60 px pill | Accessibility: F1 decision **B2** requires 48 dp targets | Exact variant keeps 40 px and measures SSIM **0.98340**. Product pill is 8 px taller. | **yes** (B2) |
| D-08 | Product delivery/status chip | 28 px neutral pill with an 8 px emerald dot | Same structure; `StatusChip` remains available for other screens with a 20 px icon | Content: not all product status chips are the Figma delivery chip | No effect on the exact card sample (it uses `FigmaStatusPill`). Other screens are an F2 mapping task. | **yes for the exact card; other screens open** |

---

## Open deviations (owner decision required)

| ID | Area | Figma value | Our value | Reason | Measured effect | Owner-approved |
|---|---|---|---|---|---|---|
| O-01 | Text field boundary | Filled `#F4F3F8`, no stroke | Filled `#F4F3F8`, no stroke (F1's 1.5 dp `outline` border removed) | Figma-exact, but the fill against white is **1.09:1**, below WCAG 2.2 1.4.11 (3:1) for an input boundary | Exact to Figma. The accessibility failure is measured and listed here. Choice: accept Figma (borderless) or restore the 1.5 dp `outline` border (F1 behaviour). | **no** |
| O-02 | Primary button final colour | Option 1 (white on `#10B981`, 2.54:1) | Product default stays option 3 (ink on `#10B981`, 6.78:1) | The owner re-opened A2 and asked for four options | Options measured: 2.54 / 3.77 / 6.78 / 6.48. Option 2 needs >= 18.66 px bold. | **no** (choice pending) |
| O-03 | Workshop admin header height | 80 px | Shared `AdminTopBar` default 64 px | App-structure/skin decision, not a component token | No component sample measures the admin header. Needs a role skin if A is kept. | **no** |
| O-04 | Large-card radius in product screens | 32 or 48 for large cards | `AppCard` default 24; optional `radius` now exists | F2 screen mapping has not happened | No measured screen yet. The delivery card exact uses 32. | **no** (F2 mapping) |
| O-05 | General `StatusChip` composition on non-delivery screens | Figma status pills are 28 px dot pills | General `StatusChip` is a 20 px icon chip | F2 has not mapped every status use | Not measured. The delivery card exact uses the Figma pill. | **no** (F2 mapping) |
| O-06 | Motion tokens | Not present in the Figma export | 120/220/320 ms, 0.98 press scale | No Figma source to compare | Cannot be measured against Figma | **no** (unverifiable) |

---

## Notes

- **Nothing else was left changed.** The F1-added button border, the
  filter/segment/result option borders, the admin chrome borders, the offline
  banner border and the 1.5 dp data-table separators were removed or reverted
  to the Figma values.
- The **Figma exports were not modified** and the Figma sample copy stays in
  test-only fixtures guarded by `FixtureGuard`.
- The **product default** for the primary button is still option 3 (ink label)
  as F1 left it. Option 1 is used only by the Figma-exact gallery/harness
  variants.

---

## F2-A technician screens 1 to 7 (5 November 2026)

The rule is unchanged: a deviation is allowed only for (1) content/privacy, (2) a measured text-contrast failure, or (3) language coverage/RTL. Everything else must equal the Figma value. The P1 and P2 owner decisions are recorded in `decisions.md`.

### Removed or replaced Figma-only elements

| ID | Screen | Figma element | What we shipped | Reason | Residual |
|---|---|---|---|---|---|
| F2A-01 | 01 Login | `TechInspect`, "Vehicle Condition & Fleet Diagnostics", missing logo asset, "Forgot password?", "Request ID", "ISO 27001 Certified Fleet Security", 202 px bottom pad, 24 px language buttons | TrueReport wordmark + drawn TR monogram, factual workshop tagline, no unreachable links, no certification claim, responsive padding, 48 px language targets | Brand/content/privacy (no certification, no endpoint); F1-B1/B2 targets | Copy, removal and target-size differences; all intentional |
| F2A-02 | 02 Jobs | Avatar photo, SHIFT 1 / BAY A, LIVE SYNC, Scan New VIN Tag, Fleet tab, 45 min Avg. turnover, 3 tasks/45 min snapshot, bay/plate meta, chevrons | Initials avatar, derived pending/in-progress counts, existing Walk-in job CTA, Jobs/Sync/Profile dock, reference/time/odometer meta, car icon + chevron, search in the app bar | No avatar asset/consent, no shift/bay/turnover data, VIN scanning deferred, no Fleet feature, offline-first (no live-sync claim) | Large: removed header badge, avatar photo, scan CTA, 4th dock item and card content |
| F2A-03 | 03 Empty | SHIFT ACTIVE, Bay 04, "Queue is current • Synced just now", TODAY'S SUMMARY, "14 Completed", "100% Pass Rate" | Real empty state, refresh + walk-in, real pending-sync line | No shift/bay/daily aggregate; pass rate is a forbidden score; no sync receipt timestamp | Removed summary strip; intentional blank space |
| F2A-04 | 04 Job intake | Vehicle hero photo, INTAKE PHASE, Ready for Check, Bay, Keys received / Fuel at 70%, Step 1 of 4, Primary Owner chip, call/message buttons, scan icon | Original vehicle-type silhouette, real status + scheduled time (UTC+4) + template version, real make/model/year/odometer/VIN/plate/customer/template/scope, copy-VIN action, edit/consent/equipment actions | Photo provenance/plate risk; no phase/readiness/fuel/step/owner fields; no call/SMS endpoint; VIN scanning deferred | Photo and invented measurements are the largest residuals |
| F2A-05 | 05 Consent | Three switches pre-set, signature pad with a sample signature, "Recorded" badge, "Today 14:38 EST", PDF-sharing/road-test/data-storage consents | Two real consents (PROCESSING, PUBLIC_LINK), unselected by default, explicit Granted/Refused choices, save disabled until both are chosen, no record before save | F1 B6/T07 explicit consent; signature capture and the extra consents are not in the model; EST is wrong for UAE | Signature block and third consent removed; switches become explicit choices so REFUSED is representable |
| F2A-06 | 06 Equipment | Equipment names/specs, 1 of 4 Verified, Bluetooth pairing, calibration, ISO-9001 | **Screen not built.** Existing equipment sheet lists the server IDs and states that names are unavailable | Server returns `equipmentIds` only (`EquipmentListDto`); names, verification and pairing are not modelled; no fake data allowed | Screen 6 remains blocked; see `f2a-report.md` |
| F2A-07 | 07 Hub | "42 Passed", "3 Action Items", Bay #04/VIN 8492, vehicle photo, Active Bay/Queued, fixed 45%/110 ring | Coverage ring "45 / 110 checks done", counts in result vocabulary ("no issue observed", "attention", "defects"), car icon instead of a photo, template-driven category cards, Done/In progress/Not started derived from assessments | No "Pass"; no bay or VIN fragment; photo provenance; coverage not a score | Ring/card copy and removed status elements differ from Figma |
| F2A-08 | All | 24/32 px controls (language 24, status dots 32, chevrons 32, copy 36, call 40) | 48 dp minimum, 56 dp primary technician actions | F1 B2 / WCAG 2.2 target size | Controls are larger than Figma |
| F2A-09 | All | Figma 4-item dock (Intake / Fleet / Sync / Profile) | Product 3-item dock (Jobs / Sync / Profile); the Figma 4-item layout is gallery-only | P7; no Fleet feature/route | Dock width/position differs |
| F2A-10 | All | English LTR only | Arabic derived RTL from the same tokens; VIN/plate/numerals LTR | Language coverage/RTL | Arabic is derived, pending native review; no Arabic Figma frame |

### Accepted risks and open items

| ID | Item | Measured/observed | Status |
|---|---|---|---|
| F2A-R1 | Field fill boundary | 1.10:1 light / 1.18:1 dark vs 3:1 | Accepted under P2; visible label + F1 focus ring; listed in `contrast-after.md` |
| F2A-R2 | Large primary label | white on `#059669` = 3.77:1 | Accepted under P1 because the label is 19 px bold (large text >= 3:1) |
| F2A-R3 | Fidelity gate | SSIM 0.7723 to 0.8860; 20 diff boxes per sample (the harness caps at 20) | **Not met**; every residual is explained by P1/P2 or a required removal. See `f2a-report.md` |
| F2A-R4 | Screen 6 data | `equipmentIds` only | Blocked, not faked |
| F2A-R5 | Arabic | Derived, no native review, no Arabic Figma frame | Pending native review |
| F2A-R6 | Real-device checks | Not performed | Owner to verify on a real phone |

---

## F2-A.1 technician screens 1 to 7 (6 November 2026)

The rule is the owner's identical-first rule (see `decisions.md` I1–I7). This
section supersedes the F2-A deviation list where it conflicts with that rule.
Everything that could be reproduced exactly is exact; the rows below are the only
remaining differences, each with a stated cause.

### Owner-accepted risks

| ID | Item | Measured | Status |
|---|---|---|---|
| F2A1-R1 | Primary button label | White `#FFFFFF` on `#10B981` = **2.54:1** (WCAG 2.2 AA normal text needs 4.5:1; large text 3:1) | Owner-accepted under **I1**; alternative ink/`#059669`/`#006C49` tokens remain available behind one switch that is off |
| F2A1-R2 | Field boundary | White field on white page with only the Figma `0,1,2` shadow; the visible boundary is below 3:1 | Owner-accepted under **I2**; invisible semantic label + focus ring carry the affordance |
| F2A1-R3 | Visual gate | Best measured SSIM **0.97210** (login, fixture a); 0.98 not reached on any screen | **Not met**; see the per-screen numbers below and `f2a1-report.md` |

### Content and data changes (same slot, size, style, position)

| ID | Screen | Figma element | Product rendering | Reason | Residual |
|---|---|---|---|---|---|
| F2A1-01 | 01 | `TechInspect` | `TrueReport` | I6 brand | Text only |
| F2A1-02 | 01 | Logo mark (other brand) | TR monogram in the same glow slot | I6 / no Figma mark asset | Mark artwork |
| F2A1-03 | 01 | `Forgot password?` | `Password help` | No reset endpoint | Text only, non-interactive |
| F2A1-04 | 01 | `Need technician access? Request ID` | `Need technician access? Contact Admin` | No request-ID endpoint | Text only |
| F2A1-05 | 01 | `ISO 27001 Certified Fleet Security` | `Secure report delivery` | Certification claim | Text only; ISO string is fixture-only |
| F2A1-06 | 02 | Avatar photo | Initials avatar | No sample-person consent/asset | Photo replaced by initials |
| F2A1-07 | 02 | `LIVE SYNC` | `ONLINE/OFFLINE SYNC` | No live-sync state | Two-line text only |
| F2A1-08 | 02 | `SHIFT 1 • BAY A` | `TODAY • N JOBS` | No shift/bay data | Text only |
| F2A1-09 | 02 | `45 min / Avg. turnover` | In-progress count | No turnover data | Value/label only |
| F2A1-10 | 02 | `Scan New VIN Tag` | `Walk-in job` | VIN scan deferred | Label/icon |
| F2A1-11 | 02/07 | Dock `Fleet` | `Finalized` (mapping pending) | No fleet feature | Label only; owner approval needed |
| F2A1-12 | 03 | `SHIFT ACTIVE`, `Bay 04` | `QUEUE EMPTY`, `0 JOBS` | No shift/bay data | Text only |
| F2A1-13 | 03 | `Queue is current • Synced just now` | Real pending-sync state | No sync receipt | Text only |
| F2A1-14 | 03 | `100% Pass Rate` | `Coverage` | Forbidden score | Text only |
| F2A1-15 | 04 | Vehicle photo | Vehicle-type silhouette | No photo provenance | Image region |
| F2A1-16 | 04 | `INTAKE PHASE`, `Ready for Check`, `Bay 3`, `Step 1 of 4`, `Keys received • Fuel at 70%` | Real status/time/template version | Fields not modelled | Text only |
| F2A1-17 | 04 | `Primary Owner` | `Customer` | Owner type not modelled | Text only |
| F2A1-18 | 04 | Call/message buttons | Same icons, no false action | No endpoint in V1 | Interaction only |
| F2A1-19 | 04 | Scan icon | Copy-VIN action | Scan deferred | Icon/action |
| F2A1-20 | 05 | Three Figma consents | Public-link + processing active; data storage visible but disabled | Only two consent types exist | Third card disabled |
| F2A1-21 | 05 | Signature pad + `Recorded` | Explicit Granted/Refused decision, “No signature captured” | Signature capture out of scope | Large region |
| F2A1-22 | 05 | `14:38 EST` | `Not recorded yet` | Wrong timezone / no record before save | Text only |
| F2A1-23 | 05 | `Alex Lindqvist / VIN 4782` | Authorized representative / recorded status | Sample person/VIN | Text only |
| F2A1-24 | 06 | Equipment names/specs/verification/ISO | ID + “Name unavailable”; no verified state | API returns IDs only | Text/data region; API change proposed |
| F2A1-25 | 07 | `Bay #04 • VIN 8492` | Job reference • template version | No bay; VIN fragment privacy | Text only |
| F2A1-26 | 07 | `42 Passed`, `3 Action Items` | No issue observed / attention counts | Product result vocabulary | Text only |
| F2A1-27 | 07 | Vehicle photo + plate/VIN | Car icon + reference/odometer | No provenance/privacy | Image region |
| F2A1-28 | 07 | `Active Bay` | `In progress` | No bay field | Text only |
| F2A1-29 | 07 | Fixed `45/110` ring and sample model | Real coverage / real vehicle | Sample data | Values only |

### Residual measured differences (not lowered)

| Screen | SSIM fixture (a) Figma text | SSIM fixture (b) product copy | Main residual causes |
|---|---|---|---|
| 01 Login | 0.97210 | 0.95233 | Working font rasterisation, TR mark vs missing Figma mark, footer wording |
| 02 Assigned jobs | 0.79111 | 0.79974 | Avatar photo, live-sync/shift labels, service copy, snapshot labels, card shadow rasterisation |
| 03 Empty state | 0.84140 | 0.84202 | Avatar photo, shift/bay labels, sync copy, summary/score replacement |
| 04 Job intake | 0.80267 | 0.80741 | Hero photo replaced, metadata/readiness/step/fuel copy, customer actions |
| 05 Consent | 0.80815 | 0.80194 | Signature region replaced by explicit decision, third consent disabled, timestamp/signer copy |
| 06 Equipment | 0.82759 | 0.81890 | Names/specs/verification/ISO replaced with IDs and neutral copy |
| 07 Inspection hub | 0.81949 | 0.82169 | Vehicle photo/plate/VIN, pass/action vocabulary, bay label, sample ring values |

No claimed difference is larger than the slot sheet allows. The gate is reported
as **not met**; it was not lowered and no "pixel-perfect" claim is made.

### Geometry

`test/f2a1_geometry_test.dart` asserts 55 key nodes at 390 logical width against
the Figma `absoluteBoundingBox` with a 1 px tolerance. All 7 screen cases pass on
the asserted dimensions. Text nodes are compared for position and line box; their
intrinsic width is font-metric dependent and is not asserted as a hard box. Three
job/equipment card heights whose finder includes the parent gap are asserted for
position only. No screen overflows at 360/390/600/900 and 1.0/1.5/2.0 text.
---

## F2-B technician screens 9, 11, 13, 14, 15, 16 (6 November 2026)

Rule: only owner-approved or rule-mandated deviations are listed here
(content/privacy, measured text-contrast failure, language coverage/RTL).
Everything else is exact per `f2b-slot-sheet.md`.

### Owner-accepted risk

| ID | Item | Measured/observed | Status |
|---|---|---|---|
| F2B-R1 | Primary button label white on `#10B981` | ~2.3:1 | Owner-accepted under **I1**; deeper-green pairings pass; carried over from F2-A.1/F2-A.2 |

### Same-slot neutral replacements (rule-mandated, exact slot/style)

| ID | Screen | Figma element | Product rendering | Cause |
|---|---|---|---|---|
| F2B-01 | All | Sample people/avatars, sample vehicle photos, bay labels | Initials disc / vehicle-type silhouette / reference + localized status | No avatar consent/provenance; no bay field (M7) |
| F2B-02 | All | Fleet / Fleet Portal / Fleet Ledger / compliance / GPS / ledger / specialist-ID / verified-tick-as-approval / customer-notified / hardware-BLE / pass-rate % | Same-slot neutral copy or real same-shape data; hide only if unsafe with no neutral form | L8; no such feature/data (M7) |
| F2B-03 | 09/11 | Damage type / `Cosmetic / Structural` / `mm` length / repair tags / invented fluid/tyre measurements | Severity chips + real master instruction/note; no invented taxonomy | No defect-type/measurement model (M1) |
| F2B-04 | 09/11 | `P0–P3` priority labels | Four ARB severities, no P0–P3 mapping, same pill slots | M1 |
| F2B-05 | 11 | Screen-11 three-way pill | Same geometry pill with 3 main ARB results + secondary row for other 3 | L8; result vocabulary |
| F2B-06 | 13 | `%` / `Pass` / score wording | Coverage % only (`completed/total`), never passed/compliant | M5 |
| F2B-07 | 14 | Slide to finalize | Figma slide exact (64 px track / 52 px thumb) + invisible semantic/keyboard alternative, same idempotent finalize | L8 a11y |
| F2B-08 | 14 | Full VIN | Full VIN only in the finalize internal card slot; last-4 on success; never public/logs/URLs/shares | M4 |
| F2B-09 | 15/16 | Raw `SENT/FAILED/DEAD_LETTER/generationStatus` | Plain ARB wording + tone in same slots | M6 |
| F2B-10 | 16 | Delivery card `Fleet Portal / Sent/Synced` | Real `TechnicianDelivery` channel + server status (max 2 rows); real report status | M6; no Fleet Portal |
| F2B-11 | 11 | Barcode slot | Same 48 px slot opening the same item (no fake pairing claim) | M8 |
| F2B-12 | All | Legal/compliance disclaimer + GPS/signature block | Same centered block with approved limitation copy; no GPS | M3 |

Gate: 0.98 NOT met on any screen; residuals = slot replacements + raster +
status-bar furniture; no pixel-perfect claim. Reference renders:
`docs/ui/figma/fidelity/f2b/<screen>/figma-text|product-copy/render.png`
(12 fidelity `render.png` artifacts; EN+AR light-only). See `f2b2-report.md`.
---

## F2-B.3 technician screens 9, 11, 13, 14, 15, 16 (6 November 2026)

Rule unchanged (N1 two-level fidelity; gate 0.98 not lowered; N5 VIN scope
unchanged). Level 1 fixtures prove the kit reproduces the Figma; Level 2
lists product-screen differences against the slot sheet. Full tables in
`f2b3-report.md`; re-baseline record in `golden-rebaseline.md`.

### Level 1 outcome (measured)

| Screen | SSIM | Gate |
|---|---|---|
| 09 defect-detail | 0.97362 | NOT met (short 0.0064; quantified rasterisation + pipeline residual) |
| 11 dense-mechanical | 0.98311 | met |
| 13 final-review | 0.98209 | met |
| 14 finalize | 0.98312 | met |
| 15 offline-sync | 0.98039 | met (thin margin +0.00039) |
| 16 success | 0.99075 | met |

### New product-rendering residuals (carried, not new violations)

| ID | Item | Measured/observed | Status |
|---|---|---|---|
| F2B3-R1 | Login footer `Contact Admin` truncates (`Contact …` EN / `تواصل مع…` AR at 390 px) | Fixed Figma slot geometry (153.53/64.94 px boxes for the shorter `Request ID`); J2 text kept | Open; owner options: shorter approved copy or footer rework (geometry test x would move) |
| F2B3-R2 | `Not available` pills on assigned-jobs golden fixtures | Fixture jobs carry non-canonical statuses; HEAD `notAvailable` fallback renders honestly | Recorded in `golden-rebaseline.md`; accepted product behaviour |
| F2B3-R3 | Empty-state header-row edge clip (`0 JOBS`) | Same pattern as the old golden (`Bay 04` clipped) | Pre-existing, not a regression |
| F2B3-R4 | Count/helper ellipsis (hub pills, consent card helpers, review numerals) | Longer product strings in fixed Figma slots; `maxLines:1`/ellipsis by design | Accepted pattern (F2-B.1 rule); owner phone check listed |
| F2B3-R5 | Screen 09 Level 1 0.97362 < 0.98 | Per-zone cost table in `f2b3/defect-detail/METHOD.md`; geometry exact, no kit change helps | Gate item open; owner decision required |
| F2B3-R6 | Screen 15 Level 1 margin +0.00039 | Deterministic as archived; fragile to re-capture | Recorded; treat re-captures with care |
---

## F3-0 Step 0 fixes (6/7 November 2026)

UI/test changes only (O2). No server change.

| ID | Item | Change | Status |
|---|---|---|---|
| F30-01 | Login footer truncation (was F2B3-R1) | ARB copy shortened to fit the exact Figma slots: EN "Need technician login?" (139.78/153.53) + "Get help" (51.36/64.94); AR "تحتاج إلى دخول؟" (105.78/153.53) + "مساعدة" (40.36/64.94). Measured with real fonts. New `o2_copy_fit_test` gates the slots. | Fixed; login goldens EN+AR re-baselined |
| F30-02 | Empty-state header clip (was F2B3-R3) | `_M.contentWidth` 350 → 334 (viewport is 350 − 16 end-pad). Trailing pill now ends at x=354 exactly; pill-1 x unchanged. | Fixed; empty-state goldens EN+AR re-baselined |
| F30-03 | Screen 09 Level 1 residual (was F2B3-R5) | Accepted by written owner waiver O1 (recorded in `decisions.md` with date). | Waived; measurement unchanged (0.97362) |
---

## F3-A Workshop Admin screens 1 to 4 (7 November 2026)

Rule unchanged (N1 two-level fidelity; gate 0.98 not lowered). Level 1
fixtures are test-only; Level 2 lists product differences vs the slot
sheet. Full tables in `f3a-report.md`.

### Level 1 outcome (measured, 1280)

| Screen | SSIM | Gate |
|---|---|---|
| 1 dashboard | 0.97814 | NOT met (short 0.00186; rasterizer-only per audit, no missed fixable error) |
| 2 live-job-queue | 0.98194 | met |
| 3 create-schedule | 0.98569 | met |
| 4 assign-technician | 0.99135 | met |

### Product rendering notes (owner-approved or rule-mandated)

| ID | Item | Measured/observed | Status |
|---|---|---|---|
| F3A-R1 | WorkshopHeader blur 24 vs Figma 48 background blur | Approximated at half strength for raster cost; recorded in code | Open; exact value is a one-line change if the owner wants it |
| F3A-R2 | Schedule footer helper capped at 2 lines at 2.0x/390 | Bottom-sheet space; full text reachable by scroll | Accepted behaviour; recorded |
| F3A-R3 | `technicianItemsCount` ARB key reused for template tier counts | Generic "$count items" text; key name is technician-scoped | Accepted; rename only with an ARB refactor |
| F3A-R4 | Dashboard `Active = assigned + inProgress` derived client-side | Endpoint exposes per-status counts, no `active` field | Open; owner to confirm definition |
| F3A-R5 | Product assign dialog is content-sized (466.5 h) vs Figma 660 | Fewer rows (real data); x/w exact, centred | Accepted layout consequence of real data |
| F3A-R6 | Admin `scheduledAt` shown as raw ISO in details/cards | Pre-existing pattern; C0 ICU-formatting follow-up | Open; needs locale date formatting decision |
| F3A-R7 | Screen 1 Level 1 0.97814 < 0.98 | Per-zone table in `f3a/dashboard/METHOD.md`; geometry exact, no kit change helps | Gate item open; owner decision required |
---

## F2-A.2 measurement correction and residuals (6 November 2026)

### Measurement defect found and fixed

The F2-A.1 fidelity captures and goldens ran under
`AutomatedTestWidgetsFlutterBinding`, whose `disableShadows` is `true` in the
pinned Flutter 3.47.9 SDK. All blurred shadows were therefore rendered as solid
blocks. The reference crops were also offset: the `@2x` exports include an
asymmetric shadow margin, and pixel analysis places the white frame at
`x=60` (or `x=40`) and **`y=14`**, not the F2-A.1 values `y=59`/`y=7`.

F2-A.2 fixes both, adds a guard test that fails if shadows are disabled during
capture, and restores the flag before each test body ends. See `decisions.md`
(J7 / measurement correction) and `f2a2-report.md`.

### Before/after SSIM (Figma-text fixture unless stated)

| Screen | F2-A.1 (shadows off, old crop) | F2-A.2 (real shadows, correct crop) | Product copy (F2-A.2) |
|---|---:|---:|---:|
| Login | 0.97210 | **0.97721** | 0.96039 |
| Assigned jobs | 0.79111 | **0.94907** | 0.89062 |
| Empty state | 0.84140 | **0.96216** | 0.93294 |
| Job intake | 0.80267 | **0.88097** | 0.83288 |
| Consent | 0.80815 | **0.92212** | 0.86533 |
| Equipment | 0.82759 | **0.93352** | 0.91971 |
| Inspection hub | 0.81949 | **0.94963** | 0.92641 |

Login measured **0.98040** after the shadow/crop fixes but before J3; the
approved J3 replacement of the ISO line lowers it to **0.97721**. The 0.98 gate
is still **not met**; it was not lowered.

### Corrected shadow verification

With real shadows enabled and the correct crop, the three F1.1 component samples
measure: primary button **0.99622** (was 0.99520), delivery card **0.99261**
(was 0.99198), result selector **0.98756** (was 0.98340). The earlier statement
that the shadow blur matched was based on the disabled-shadow render and is
withdrawn. The Figma card shadow (`0,2,8` α0.016 + `0,14,40` α0.043) and CTA
glow (`0,10,25` emerald 30%) are now the values used and the residual difference
is Flutter-vs-Figma shadow rasterisation, not a token mismatch.

### Remaining F2-A.2 residuals

| ID | Screen | Residual | Numeric effect |
|---|---|---|---|
| F2A2-R1 | All | Text rasterisation: Flutter and Figma anti-alias the same Plus Jakarta Sans metrics differently | Dominates most remaining diff boxes; no layout offset |
| F2A2-R2 | Login | J3 line is shorter than the Figma ISO line, so its centred x differs; the slot/style/height are unchanged | SSIM 0.98040→0.97721 |
| F2A2-R3 | Assigned/Empty | J1 label `Finalized` vs fixture `Fleet`; product data copy | Product fixture 0.89062/0.93294 |
| F2A2-R4 | Job intake | Figma vehicle photo is now matched in fixture (a); product still uses the neutral silhouette | Fixture (a) 0.88097 vs product 0.83288 |
| F2A2-R5 | Consent | J4 decision slot replaces the signature pad; J3/J4 text | 0.92212 fixture; the signature region is an approved residual |
| F2A2-R6 | Equipment | J5 supplies names, but the product has no verification/pairing state; the card status circles stay unticked | Product copy 0.91971 |
| F2A2-R7 | Hub | Fixed 45/110 sample ring values and sample vehicle copy are replaced by real coverage/data | 0.94963 fixture |
| F2A2-R8 | All | No native Arabic review; no real-device pass | Not measurable here |

Geometry remains 7/7 screens at 1 px on the asserted nodes (55 geometry checks
plus 12 text-style assertions). Text intrinsic width remains font-metric
dependent and is not asserted as a hard box.