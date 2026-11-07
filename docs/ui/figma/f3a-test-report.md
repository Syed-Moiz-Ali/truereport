# F3-A test report (7 November 2026)

F3-A builds shared admin components, one read-only server endpoint, and
Workshop Admin screens 1–4. No screens 5–12. No F4/F5. No commit. Stop at gate.

## 1. Baseline (Step 0, before changes)

| Suite | Result |
|---|---|
| `design_system` | 88/88 pass |
| technician_app | 178/178 pass |
| admin_app | 93/93 pass |
| ui_gallery | 5/5 pass |
| auth | 0 tests (no `test/` dir, confirmed) |
| Server `mvn -DskipITs=false test` | 89 run / 0 fail / 6 skipped (3 Docker-unavailable MySQL + 3 conditional) |
| Docker | NOT available (Docker Desktop not installed; npipe missing). P6 verified on H2; MySQL suites need Docker + a follow-up run. |

## 2. Changes (in order)

1. **Step 1 (lead):** `design_system` `workshop_admin.dart` (WorkshopHeader/UserChip/StatCard/JobCard/OptionCard/Dialog/SideSheet + arrow-key table nav in `data_table.dart`), `workshop_admin_test` 11/11, gallery `WorkshopShowcase` section.
2. **Step 2 (server-engineer):** `GET /api/v1/workshop/jobs/counts` + `JobCountsDto` + `WorkshopJobCountsIT` 5/5; L7 inventory 4/4.
3. **Step 3 (builders):** dashboard tab + Overview tab + counts client wiring (19 tests), queue restyle (6+1 tests), schedule drawer content (15 tests), assign dialog (23 tests).
4. **Lead wiring:** "+ New Job" → schedule drawer; `_assign` (jobs + dashboard) → assign dialog. `AppListTile`/`SectionHeader` gained optional direction params; LTR wrappers on references/VIN-plate/phone lines; OptionCard focus ring; side-sheet motion respect.
5. **Step 4:** Level 1 fixtures + audits; Level 2 product captures; geometry (12 checks) + screenshots (10 PNGs); a11y + privacy reviews.

## 3. Final verification (after the last change, in order)

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` (client) | clean — `No issues found!` |
| `design_system` full | 100/100 pass (incl. new `workshop_admin_test` 11) |
| technician_app full | 178/178 pass |
| admin_app full | 179/179 pass (incl. dashboard 19, queue 7, schedule 15, dialog 23, 8 f3a captures, geometry 4, screenshots 10) |
| ui_gallery full | 5/5 pass (incl. new Workshop section) |
| auth | 0 tests |
| Client total | **462 pass / 0 fail** |
| Server `mvn -DskipITs=false test` (full) | **94 run / 0 fail / 6 skipped / BUILD SUCCESS** (`WorkshopJobCountsIT` 5/5, `SecurityEndpointInventoryIT` 4/4 green) |
| `tokens generate --check` / `print-tokens --check` | pass / pass |
| Web build technician_app / admin_app | success / success |
| Debug APK technician_app | success (~237.5 MB) |

Server skips (6, all conditional): 3 MySQL Testcontainers (Docker unavailable
— needs a Docker follow-up run before any server-touching phase), 1 POSIX
assumption, 1 PDF-sample property, 1 S3 endpoint. No server code changed
after the P6 endpoint; the suite above ran after all server changes.

## 4. Fidelity summary (measured)

Level 1 (1280, gate 0.98): dashboard **0.97814 NOT MET** (−0.00186,
rasterizer-only, audited, no missed fixable error); queue **0.98194 PASS**;
schedule **0.98569 PASS**; assign **0.99135 PASS**. All reproduced
deterministically (auditors ×2, lead re-run post-lint).
Level 2 (product screens, FAIL by design): dashboard 0.88768, queue
0.89698, schedule 0.83559, assign 0.82957 — every difference traced to a
slot-sheet row (see f3a-report + per-screen METHOD.md).

## 5. Could not verify

Real devices/browsers; native Arabic review (incl. 11 new ARB keys);
MySQL Testcontainers (Docker); Figma blur-kernel mapping (1:1 assumed);
live server data; dialog/drawer drag states; <600 sheet beyond 390 test.
No pixel-perfect claim. No real-device testing claimed.
