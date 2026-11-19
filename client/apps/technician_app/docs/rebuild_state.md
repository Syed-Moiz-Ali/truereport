# Rebuild state — technician_app sign-in

Path:            **lite** (one screen, full LITE gates)
Screen:          `/signin` — `client/apps/technician_app`
Direction:       **C "The dock"** (Gate 3, user, 2026-11-19)
Current phase:   **6 — complete**
Current brief:   `docs/briefs/brief-signin-mini.md` — executed
Gates:           0 **PASS (user, 2026-11-19)** | 1 **PASS (self, artifacts)**
                 | 3 **PASS (user, direction C)** | 4-lite **PASS (self)**
                 | 5 **PASS (user, 2026-11-19)**
                 | 6 **PASS (independent r2, PASS WITH FIXES; owner endorsed
                   §15, 2026-11-19)**

Artifacts:
                 docs/audit-signin.md · docs/invariants.md
                 docs/baseline_allowlist.md · docs/baseline_metrics.md
                 docs/evidence/logs/ · docs/data/inventory.md
                 docs/data/signin_client_trace.md
                 docs/data/auth_server_contract.md · docs/data/samples/
                 docs/api/contracts.md · docs/data_gaps.md
                 docs/data/gate1_grade.md
                 docs/design_thinking.md · docs/concepts/{a,b,c}/wireframe.md
                 docs/evidence/signin_directions/ (12 PNGs + index.html + README)
                 docs/ui_brief.md · docs/adr/0002-signin-ownership.md
                 docs/visual_language.md · docs/waivers.md
                 docs/evidence/gallery/signin_*.png + signin_index.html
                 docs/evidence/signin/ (20 assembled-screen state renders)
                 docs/evidence/signin/qa_checklist.md
                 docs/evidence/signin/qa_verdict.md (r1 FAIL)
                 docs/evidence/signin/qa_verdict_round2.md (r2 PASS WITH FIXES)
                 docs/evidence/logs/after_{analyze,test}.txt
                 docs/evidence/logs/after_analyze_auth.txt

Code (new, routed at `/signin`):
                 lib/src/features/auth/signin/signin_tokens.dart
                 lib/src/features/auth/signin/technician_sign_in_page.dart
                 lib/src/features/auth/signin/technician_sign_in_view.dart
                 lib/src/features/auth/signin/widgets/ (8 region widgets)
                 lib/src/technician_router.dart (route + pure guard)
Tests:
                 test/features/auth/signin/signin_behaviour_test.dart (18)
                 test/features/auth/signin/signin_gallery_test.dart (7)
                 test/src/technician_router_test.dart (4)
                 test/support/font_harness_smoke_test.dart (2)
                 test/f2a1_geometry_test.dart, test/o2_copy_fit_test.dart (rewritten)
                 test/widget_test.dart, test/support/f2a_views.dart (repointed)
                 test/goldens/f2a_login_{en,ar}_light.png (regenerated)
Deleted:
                 packages/auth/lib/src/{sign_in_page,sign_in_view,
                   true_report_app,router}.dart + their barrel exports

Open waivers:    W-LIGHT (approved at Gate 5, 2027-02-18)
                 W-SIGNIN-WEB (approved with Gate 6 closure, 2026-12-19)

Measured result: app analyzer **0**; auth analyzer **0**; tests **263 pass /
                 19 fail** (the exact baseline 19, no new failure); workspace
                 analyze red only for 11 issues in untracked preview files of
                 concurrent waves (documented in `baseline_allowlist.md` §E).

Next allowed action: **ship** (merge/deploy by the owner). A live-device
                 spot-check is the only optional follow-up (W-SIGNIN-WEB).

## Gate log

| Gate | Date | Result |
|---|---|---|
| 0 | 2026-11-19 | PASS (user): invariants, allowlist, font strategy, kill plan |
| 1 | 2026-11-19 | PASS (self): 16 V / 1 A / 11 S / 5 M, every SUSPECT root-caused |
| 3 | 2026-11-19 | PASS (user): direction **C — The dock** |
| 4-lite | 2026-11-19 | PASS (self): ADR + 6 revertible seams + real-glyph smoke test |
| 5 | 2026-11-19 | PASS (user): visual language + gallery (W-LIGHT) |
| 6 r1 | 2026-11-19 | **FAIL (independent)**: B1 keyboard-up, B2 keyboard language, M1 evidence claims |
| 6 r2 | 2026-11-19 | **PASS WITH FIXES (independent)**: no blockers/majors; §15 endorsed by the owner |

## Resume rule

On resume, verify every artifact path above exists before trusting this file.
A missing artifact means its gate did not happen; downgrade it to PENDING.
