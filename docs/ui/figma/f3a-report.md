# F3-A report — shared components, P6 endpoint, screens 1–4 (7 November 2026)

**Status: work complete, gate verdict open on one item (screen 1 Level 1:
0.97814 < 0.98). No commit. Stop for owner approval. Screens 5–12, F4, F5
not started.**

## 1. Owner decisions P1–P7 (recorded in `decisions.md`, F3-A section)

- **P1 (D-F3-1):** dashboard shows counts only from existing data — P6
  endpoint + client-side active derivation. Implemented in `dashboard_tab`.
- **P2 (D-F3-2):** bays/shifts/telemetry/utilization/throughput/averages
  omitted (Option A). Implemented; no invented numbers anywhere.
- **P3 (D-F3-3):** Technician-only roles in pickers. Implemented
  (dialog filters `TECHNICIAN` + `ACTIVE`; user chip shows no role).
- **P4 (D-F3-4):** drawer tiers map to real published templates
  (`templateVersionOptions` + item counts). Implemented.
- **P5:** D-F3-5–D-F3-10 approved for later batches as recommended —
  recorded, not built.
- **P6:** read-only `GET /api/v1/workshop/jobs/counts` (counts by status,
  caller's workshop, Workshop Admin only, explicit `@PreAuthorize`,
  no PII, no write, no schema). Implemented + `WorkshopJobCountsIT` 5/5.
- **P7:** tablet/phone derived, labelled derived, fidelity claimed for
  1280 only. Implemented (drawer→sheet <600, header stacking <600,
  wrap layouts; code comments carry the label).

## 2. Shared components (lead, design_system)

`workshop_admin.dart`: WorkshopHeader (floating, blurred, responsive stack
<600), WorkshopUserChip (no role), WorkshopStatCard (icon + LTR value +
caption + track), WorkshopJobCard (neutral tile, keyboard, focus ring),
WorkshopOptionCard (tint + radio + check + focus ring + semantics),
WorkshopDialog (512, Esc, focus return), WorkshopSideSheet (420/sheet
fallback, Esc, focus return). `data_table.dart`: arrow-key row navigation
(guard skips while editing text). Gallery `WorkshopShowcase` section.
`workshop_admin_test` 11/11 (renders EN+AR, keyboard, dialogs, table nav).

## 3. Screens 1–4 (builders + lead wiring)

- **1 Dashboard** (new Overview tab, first): 5 count cards from P6
  (Active = assigned+inProgress client-side — owner to confirm definition),
  recent-job cards, search filters recent list; loading/error/empty states.
- **2 Queue:** restyled JobsTab — header, counted chips
  (All/In progress/Ready to finalize/Completed), WorkshopJobCards, search,
  retained flows. `+ New Job` now opens the schedule drawer (lead wiring).
- **3 Drawer:** 420 drawer (sheet <600) with existing fields + template
  dropdown + real-template tier cards; validation/submit identical to
  JobFormPage; footer helper capped at 2 lines at 2.0x/390 (recorded).
- **4 Dialog:** centred 512 dialog, ACTIVE-technician radio cards,
  optional reason, existing assignJob; `_assign` (jobs + dashboard) now
  opens it (lead wiring). Confirm disabled without selection; finalized
  rejected.

## 4. Fidelity

Level 1 (test-only Figma-structure fixtures, 1280/DPR2, real shadows;
artifacts under `docs/ui/figma/fidelity/f3a/`, fixtures under
`fixtures/f3a/`):

| Screen | SSIM | RMSE | Diff boxes | Met |
|---|---|---:|---|:---|
| 1 dashboard | **0.97814** | 12.088 | 20 | **NOT met** (−0.00186; rasterizer-only, audited) |
| 2 live-job-queue | **0.98194** | 11.380 | 20 | met (auditor-reproduced ×2) |
| 3 create-schedule | **0.98569** | 9.876 | 20 | met (reproduced ×2) |
| 4 assign-technician | **0.99135** | 6.972 | 20 | met (reproduced ×2) |

Level 2 (product screens, FAIL by design; differences → slot-sheet rows):
dashboard 0.88843 (re-measured post-Q3 locale dates; was 0.88768), queue 0.89698, schedule 0.83559, assign 0.82957.
Residuals are slot replacements + raster; no pixel-perfect claim.
Screenshots: `docs/ui/figma/f3a-screenshots/` (EN+AR 1280, EN 390 ×10).

## 5. A11y / privacy / geometry

- A11y review: 63/63 screen tests + 11/11 component tests pass. Three lead
  fixes applied: OptionCard focus ring, side-sheet motion respect, LTR
  wrappers (references, VIN/plate/phone lines, stat values, dialog strip).
  Queue 2.0x scale test added (7/7). Remaining: dialog fade path
  unshortened (framework default, unmeasured).
- Privacy review: PASS, no violations (no sample media in product, masked
  emails, full VIN never public/log/URL, no banned wording, C0 wording).
- Geometry: 12 checks (8 boxes + 4 text styles) at 1280 EN pass;
  Level 1 key boxes all delta 0 (screen 1: max 0.01).

## 6. Subagent work (max 3 at a time honoured)

2 baseline runners, 1 server-engineer (P6), 3 + 1 screen builders,
4 fixture builders (1 with an exact-value iteration round), 4 auditors,
1 a11y + 1 privacy reviewer, 2 Level 2 measurers, screenshot + geometry
authors, 3 final verifiers. Failures/overloads: transient mid-flight
breakage when parallel builders shared the tree (stale-file failures in
concurrent runs; all green at every integration point — lead verified).
Lead did instead of agents: all shared-component work, all ARB additions,
the trigger wiring, all lint/a11y fixes, all doc updates. Two agents never
edited the same file.

## 7. Remaining owner actions

1. Decide screen 1 Level 1 (0.97814): accept the quantified residual
   (as with 09/O1) or fund further work (no fixture-side path left).
2. Confirm `Active = assigned + inProgress` (client-side derivation; the
   endpoint has no `active` field).
3. Decide the raw-ISO `scheduledAt` display (pre-existing admin pattern;
   C0 ICU-formatting follow-up).
4. Real-browser check at 1280 (compare each screen with Figma; keyboard-only
   table/drawer/dialog; EN+AR; narrow widths) + native Arabic review.
5. Provide Docker for a MySQL Testcontainers re-run before any
   server-touching phase.

## 8. Could not verify

See f3a-test-report §5. Gate verdict: **NOT met** (screen 1 Level 1 below
0.98); everything else met. **Stop. Awaiting approval before F3-B.**
