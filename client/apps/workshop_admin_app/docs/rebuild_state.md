# Rebuild state — Workshop Admin

## Wave 5 (current) — jobs module

**Scope locked: jobs module** (2026-11-19, owner). Foundation frozen.

Path:            **full** (module-scoped: audit → data → Brief 1 → directions →
                 Brief 2 → Brief 3 → flow proof)
Target:          `lib/src/features/jobs/**` + the Jobs/Board section host hook;
                 legacy queue family (`jobsProvider`, `WorkshopJob`,
                 `job_counts.dart`, `job_quick_sheet.dart`,
                 `schedule_job_sheet.dart`) is scheduled for deletion
Queue:           `docs/rebuild_queue.md` (J1 queue + detail · J2 write path ·
                 J3 client surface)
Current phase:   3 — three queue directions rendering (isolated); Gate 2b PASS
Gates:           0 **PASS(user, Wave 2 audit)** | 1 **PASS (self, partial by scope)** |
                 2 **PASS (self)** | 2b **PASS (self, artifacts)** |
                 3 **rendering** | 4 **PASS (foundation harness)** |
                 5 **PASS (frozen)** | 6 pending

Gate 1 (2026-11-19): `docs/data/jobs_inventory.md` — 195 elements:
                 119 VERIFIED / 7 ASSUMED / 62 SUSPECT (every one root-caused) /
                 7 MISSING. Consistent for the clean read path; the write path is
                 **not certifiable** (consent/publish contradiction G-J1, checklist
                 bypass F2, optional OCC F3). Filed as CR-1/CR-4; publish flow proof
                 in J2 is blocked until the server decision.

Gate 2b (2026-11-19): `docs/briefs/brief-jobs-1.md` executed —
                 `test/jobs_invariants_characterization_test.dart` 14/14 pass,
                 full suite 575 pass, analyze 0. J6 and J10 pinned; clean-job
                 contract pinned from committed samples; J3/J5 pinned pre-replacement.
                 J8 defect (reason-sheet controller disposed during exit) fixed in
                 `job_widgets.dart` and pinned by a page-level cancel test.

Migration risk resolved (audit F1): `inspection_jobs` is still written by the
                 technician endpoints. The primary queue moves to `CleanJob`, and
                 the legacy family survives only as a read-only
                 `features/jobs/archive/` surface until CR-3 (server backfill).
                 Legacy mutations and UI die in J1.

Resume verification 2026-11-19:
                 - foundation artifacts present (ui_brief, visual_language,
                   invariants, allowlist, contracts, data_gaps, evidence dirs)
                 - `flutter analyze --fatal-infos` → 0 issues (exit 0)
                 - `flutter test` → **562 pass / 0 fail**
                 - working tree carries the Wave 4 shell_dock tweak (uncommitted),
                   frozen with the foundation
                 - `docs/STOP` absent

Artifacts (new):
                 docs/rebuild_queue.md · docs/rebuild_log.md ·
                 docs/rebuild_blocked.md · docs/change_requests.md ·
                 docs/design_decision.md

Next allowed action: pick direction at Gate 3, write `docs/ui_brief_jobs.md`, then J1.

---

## Wave 4 (shell) — proof captured, independent review spawned 2026-11-19

Path:            **lite** (one component: the navigation chrome)
Component:       `packages/design_system/lib/src/components/workshop_shell.dart`
                 + host `apps/workshop_admin_app/lib/src/features/home/workshop_admin_home.dart`
Current phase:   6 — **complete**
Current brief:   `docs/briefs/brief-4-shell-mini.md` (executed; see its process note)
Gates:           0 **PASS(user — audit accepted, ACL lift authorised 2026-11-19)**
                 | 1 **PASS(self)** | 3 **PASS(user — direction C "The dock")**
                 | 4-lite **PASS(self)** | 5 **PASS(user — gallery)**
                 | 6 **PASS (independent, round 2, 2026-11-19)**

Artifacts:
                  docs/audit-shell.md                  (S1–S8, K1–K7, kill list)
                  docs/data/shell_inventory.md         (12 elements; no badge invented)
                  docs/shell_directions.md             (thinking protocol + 3 directions)
                  docs/evidence/shell_directions/      (9 renders + contact sheet)
                  docs/ui_brief.md                     (direction C spec; dashboard brief archived)
                  docs/evidence/gallery/shell_*.png    (8 primitive/state shots)
                  docs/evidence/gallery/shell_index.html
                  docs/evidence/shell_after/           (8 real-screen captures)
                  docs/briefs/brief-4-shell-mini.md
                  docs/evidence/shell_qa.md            (proof sheet)
                  docs/evidence/logs/{analyze,test,design_system_test}.txt

Code:            `components/shell/{shell_destination,shell_identity_strip,shell_dock}.dart`
                 (new); `workshop_shell.dart` rewritten 1 200 → 150 lines;
                 host `_SectionHost` (lazy sections); dashboard eyebrow removed
Tests:           DS `test/shell_test.dart` (8), app `test/shell_gallery_test.dart` (9);
                 obsolete sidebar/rail/More assertions removed from `workshop_kit_test.dart`

Open waivers:    W-LIGHT, W-NOTOTP, W-ROWOPEN (all in force)
Next allowed action: reviewer verdict. If PASS → close the wave. If BLOCK → fix
                 the listed items and re-review (first wave is never self-graded).

### Measured result

App: **575 tests** pass, analyzer clean, baseline_check OK.
Design system: **138 tests** pass (two drifted assertions corrected to the tokens).
No new `RenderFlex overflowed` across 1440/1024/768/390/360, 1.5× and 2×, EN + AR.
14 shell captures (dashboard + board at six widths, staff, jobs, AR).

### Round 3 (after the PASS — self-graded with artifacts)

360 px no longer truncates the active label (the selected item drops its icon
below 384 px and keeps its name); the 3:1 split starts at 384 px; `reserve`
returns 88/78 to match the 44 px items; the brief and the QA sheet say the same.
`dashboard_360.png` reads "Overview", `board_360.png` reads "Job board".

### Round 2 (after the independent review's FAIL)

Blockers closed: the Job board now has captures at six widths + AR through the
dock, and dock items meet the 44 px `touchTarget` (the brief said 40, which
contradicted the token — the brief was amended). Also: `navMain` is localized in
both ARBs and passed by the host; icon-only items carry tooltips; the
notifications action is tested; the dead More fallback is gone. The avatar
disclosure caret is a recorded won't-fix (the trigger lives in the shared
`workshop_ui.dart` used by another app).

### Deviations, recorded

1. **Process order:** the shell foundation was built as the Gate 5 slice and
   approved with the gallery; the mini Brief records the scope afterwards rather
   than before the code. Noted in the brief itself.
2. **`components.dart` is ACL-locked**, so the shell primitives are exported from
   the package barrel (`lib/design_system.dart`) instead of the components barrel.
3. **Two DS tests were already red** before this wave (`pageGutter` expected 24,
   content width expected 1120, tokens are 32/1200). Corrected to the tokens.
4. **Dashboard eyebrow removed** — the strip names the workshop once; keeping the
   page eyebrow would put the same words twice above the fold (audit S1).

---

## Wave 3 (closed) — dashboard only

Path: **lite**. Gate 0 PASS(user) · 1 PASS(self) · 3 PASS(user, direction B) ·
4-lite PASS(self) · 5 PASS(user) · **6 PASS (independent, round 2, 2026-11-18)**.
546 tests, analyzer clean, baseline OK. Follow-ups fixed after the review: the
legend is a content-sized legend (not a positional ruler), the phone primary
action is full width, Arabic digits are pinned to one system, the singular label
is corrected, a group with no rows drops its count, and the row meta is an LTR
data line (the date no longer splits around the reference).
Artifacts: `docs/audit-dashboard.md`, `docs/data/dashboard_inventory.md`,
`docs/ui_brief_dashboard.md`, `docs/visual_language_dashboard.md`,
`docs/evidence/dashboard_*`, `docs/evidence/logs/`.

---

## Wave 2 (paused) — dashboard + jobs

Stopped at Gate 2b FAIL. Phase C's revert left the tree unbuildable (60 analyzer
issues); repaired in Wave 3. Invariants J1–J18 remain valid; the jobs queue still
reads the legacy family (allowlist B4).

## Wave 1 (complete) — sign-in

Gate 6 PASS (independent, round 3). Hand-off: native-speaker Arabic sign-off,
`WorkshopTextField` error outline, DS barrel ACL, four accepted cosmetic residues.

## Verification on resume

Every artifact path above must exist before its gate is trusted. A missing
artifact means the gate did not happen; downgrade it to PENDING and say so.

## Waivers

| ID | Gate | Waives | Why | Owner | Expiry |
|---|---|---|---|---|---|
| W-LIGHT | 5 | Dark-theme evidence | App is light-only by product decision | Syed Moiz | 2027-02-18 |
| W-NOTOTP | 3 | TOTP entry state | `source_scan_test.dart` forbids TOTP UI in the admin app | Syed Moiz | 2027-02-18 |
| W-SCREENSHOTS | 6 | Asserting the 77 committed PNGs as goldens | The suite rewrites them and asserts nothing | Syed Moiz | 2026-12-31 · proposed |
| W-ROWOPEN | 6 | "Dashboard row opens the quick sheet" | The clean world has no quick sheet; the detail page carries the same actions | Syed Moiz | 2027-02-18 |

## Progress log — Wave 4

| Date | Phase | Result |
|---|---|---|
| 2026-11-19 | 0 | `docs/audit-shell.md`: all three shell files were ACL-denied (write probe blocked); S1–S8 structural findings; K1–K7 invariants. **ACL lifted by the owner** (icacls /remove:d on the three files), verified by a byte-identical write probe. |
| 2026-11-19 | 1 | `docs/data/shell_inventory.md`: 12 elements, 10 VERIFIED, 1 ASSUMED (search), 1 MISSING (unread badge — excluded, not invented). |
| 2026-11-19 | 3 | Three structurally different shells rendered at 1440/390 + tiles. |
| 2026-11-19 | 3 GATE | **PASS (user).** Direction **C — "The dock"**. |
| 2026-11-19 | 4-lite / 5 | Identity strip + dock built in `components/shell/`; `workshop_shell.dart` rewritten; dashboard eyebrow removed; 8-shot gallery. |
| 2026-11-19 | 5 GATE | **PASS (user).** Gallery accepted. |
| 2026-11-19 | integration | Lazy sections in the host; DS barrel exports; two drifted DS assertions fixed. |
| 2026-11-19 | 6 | 555 app tests + 136 DS tests, analyzer clean, 8 real-screen captures, logs committed. **Independent review: FAIL** — board had no capture (item 10); dock items 40 px vs the 44 px token; `navigationLabel` unlocalized. |
| 2026-11-19 | 6 (round 2) | Board captured at 6 widths + AR through the dock; items 44 px and tested; `navMain` added to both ARBs and passed by the host; tooltips on icon-only items; notifications tested; dead More fallback removed. 562 app + 138 DS tests, baseline_check OK. **Re-review: PASS (independent, 10/10).** |
| 2026-11-19 | 6 (round 3) | 360 px active label no longer truncates (icon dropped, label kept); split breakpoint 384; `reserve` 88/78 aligned with the 44 px items; docs updated. 575 app + 138 DS tests, analyzer clean, baseline OK. **Wave closed.** |


Path:            **lite** (single screen; full LITE gates)
Screen:          `lib/src/features/dashboard/dashboard_tab.dart`
Current phase:   6 — proof captured, **independent review running**
Current brief:   `docs/briefs/brief-3-dashboard-mini.md` — executed
Gates:           0 **PASS(user, 2026-11-18)** | 1 **PASS(self)** | 3 **PASS(user — direction B)**
                  | 4-lite **PASS(self)** | 5 **PASS(user)** | 6 **pending (independent reviewer)**

Artifacts:
                  docs/audit-dashboard.md              (0-lite audit, R1–R8, kill list)
                  docs/baseline_allowlist.md           (480 pass pre-wave, analyzer 0)
                  docs/baseline_metrics.md
                  docs/invariants.md                   (J1–J18 + J19–J21)
                  docs/data/dashboard_inventory.md     (32 elements; partition verified)
                  docs/api/contracts.md
                  docs/data_gaps.md                    (G1–G13)
                  docs/data/samples/
                  docs/dashboard_directions.md         (thinking protocol + 3 directions)
                  docs/evidence/dashboard_directions/  (9 renders + contact sheet)
                  docs/ui_brief.md                     (direction B spec, amended)
                  docs/phase-4-dashboard-harness.md
                  docs/visual_language_dashboard.md    (committed idea + kill list)
                  docs/evidence/gallery/dashboard_*.png (11 primitives/state shots)
                  docs/briefs/brief-3-dashboard-mini.md
                  docs/evidence/dashboard_states/      (9 state captures)
                  docs/evidence/dashboard_before|after/ + dashboard_compare.html
                  docs/evidence/dashboard_qa.md        (proof sheet)

Code:            `lib/src/features/dashboard/` — dashboard_tab.dart (rewritten) +
                 dashboard_style.dart + widgets/{dashboard_hero,dashboard_groups,
                 dashboard_atlas,dashboard_rows,dashboard_states}.dart
                 `packages/design_system/lib/src/workshop_display.dart` (new display role)
                 ARB: 20 keys added to en + ar (`dash*`), generated l10n refreshed
Tests:           dashboard_test.dart (structural, rewritten), dashboard_invariants_test.dart
                 (new, 48), dashboard_gallery_test.dart (new, 11),
                 dashboard_states_capture_test.dart (new, 9), dashboard_localization_test.dart
                 (rewritten), intl_dates_test.dart (2 cases rewritten), ui_matrix_test.dart
                 (dashboard reference updated)

Open waivers:    W-LIGHT, W-NOTOTP (countersigned 2026-11-18)
                 W-SCREENSHOTS (proposed), W-ROWOPEN (proposed — row opens detail page)

Next allowed action: reviewer verdict. If PASS → user countersigns W-ROWOPEN and
                 the wave closes; if FAIL → fix the listed findings, re-review (the
                 first wave is never self-graded).

### Measured result

527 tests pass / 0 fail · `flutter analyze --fatal-infos` clean · format 0 new ·
`baseline_check` OK · no new `RenderFlex overflowed` across 36 matrix cases.

### Deviations from the approved spec (both recorded, both at the gate)

1. Row tap opens `JobDetailPage` instead of the legacy quick sheet — forced by
   J19 (the sheet only accepts `inspection_jobs`). Waiver W-ROWOPEN.
2. Breakpoints are content-based (the shell sidebar takes 256 px), not
   window-based; the bands are documented in `ui_brief.md` §6 as amended. Without
   this, 1024 px rendered a 6/4 split inside 704 px and collided.

---

## Wave 2 (paused) — dashboard + jobs

Stopped at Gate 2b FAIL. Phase C's revert left the tree unbuildable (60 analyzer
issues); repaired in Wave 3 (see `docs/audit-dashboard.md` §R). Audits, invariants
J1–J18, inventory and contracts remain valid; the jobs queue still reads the
legacy family, which is why B4 in the allowlist is still true.

## Wave 1 (complete) — sign-in

Gate 6 **PASS (independent, round 3)**. Hand-off items: native-speaker Arabic
sign-off, `WorkshopTextField` error outline, DS barrel ACL, four accepted
cosmetic residues.

## Rejection record — why the first sign-in attempt failed

"UI and UX was very bad" → structurally confirmed as a restyle: same 1440/390
composition, no new region files, nothing deleted. The redo (7 region files)
passed. Wave 3 was built to avoid the same failure and the edit-vs-replace test is
in `docs/evidence/dashboard_qa.md`.

## Verification on resume

Every artifact path above must exist before its gate is trusted. A missing
artifact means the gate did not happen; downgrade it to PENDING and say so.

## Waivers

| ID | Gate | Waives | Why | Owner | Expiry |
|---|---|---|---|---|---|
| W-LIGHT | 5 | Dark-theme evidence | App is light-only by product decision | Syed Moiz | 2027-02-18 |
| W-NOTOTP | 3 | TOTP entry state | `source_scan_test.dart` forbids TOTP UI in the admin app | Syed Moiz | 2027-02-18 |
| W-SCREENSHOTS | 6 | Asserting the 77 committed PNGs as goldens | The suite rewrites them and asserts nothing | Syed Moiz | 2026-12-31 · proposed |
| W-ROWOPEN | 6 | "Dashboard row opens the quick sheet" | The clean world has no quick sheet; the detail page carries the same actions | Syed Moiz | 2027-02-18 · proposed |

## Progress log — Wave 3

| Date | Phase | Result |
|---|---|---|
| 2026-11-18 | repair | Tree restored: 60 analyzer issues → 0; 480 tests pass. Exact commands in `docs/audit-dashboard.md` §R. |
| 2026-11-18 | 0 GATE | **PASS (user).** Audit, baseline, J19–J21 (clean source of truth, partition-or-nothing, no time claims) and the inherited font strategy accepted. |
| 2026-11-18 | 1 | `docs/data/dashboard_inventory.md`: 32 elements (23 V / 1 A / 1 S / 7 M); partition verified in server source including its failure mode. **PASS (self).** |
| 2026-11-18 | 3 | Thinking protocol + three structurally different directions rendered at 1440/390 + style tiles (`docs/dashboard_directions.md`, 9 PNGs). |
| 2026-11-18 | 3 GATE | **PASS (user).** Direction **B — "The floor"** chosen. `docs/ui_brief.md` written. |
| 2026-11-18 | 4-lite | Harness verified (fonts, fixtures, baseline gate); 5 revertible seams; every audit finding mapped. **PASS (self).** |
| 2026-11-18 | 5 | `WorkshopDisplay` display role added to the design system; atlas / rows / groups / states built; 11-shot gallery (LTR+RTL, loading, error, remainder, spine). |
| 2026-11-18 | 5 GATE | **PASS (user).** Visual language and primitives approved from the gallery. |
| 2026-11-18 | mini Brief | `docs/briefs/brief-3-dashboard-mini.md` written, then executed: 20 ARB keys, screen rewritten into 6 files, all old widgets deleted, tests rewritten/added. |
| 2026-11-18 | 6 | 527 tests, analyzer clean, baseline_check OK, 36-case overflow matrix, 9 state captures, before/after sheet. **Independent review running.** |
