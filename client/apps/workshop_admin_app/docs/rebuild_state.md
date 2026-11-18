# Rebuild state — Workshop Admin sign-in

Path:            **lite** (single screen scope, full LITE gates; not a pilot)
Screen:          `lib/src/features/auth/workshop_login_page.dart` (`/signin`)
Current phase:   6 — PROOF complete (independently passed)
Current brief:   `docs/briefs/brief-2-mini.md` executed and proven
Gates:           0 PASS(user) | 1 PASS(self) | 2 PASS(user) | 2b PASS(self)
                 | 3 PASS(user — direction B "The bay")
                 | 4 PASS(self) — architecture/harness, no new boundary
                 | 5 PASS(user — gallery + slice)
                 | 6 **PASS (independent reviewer, round 3, 2026-11-18)**
Artifacts:       docs/invariants.md
                 docs/baseline_allowlist.md
                 docs/baseline_allowlist.json
                 docs/baseline_metrics.md
                 docs/data/inventory.md
                 docs/data_gaps.md
                 docs/api/contracts.md
                 docs/data/samples/
                 docs/briefs/brief-1.md
                 docs/briefs/brief-1-results.md
                 docs/briefs/brief-2-mini.md
                 docs/directions.md
                 docs/ui_brief.md
                 docs/visual_language.md
                 docs/evidence/directions/*.png
                 docs/evidence/gallery/gallery_{ltr,rtl}_light.png
                 docs/evidence/states/*.png
                 lib/src/features/auth/signin/*.dart
                 test/flutter_test_config.dart
                 test/support/real_fonts.dart
                 tool/baseline_check.dart
Open waivers:    W-LIGHT, W-NOTOTP — countersigned (Syed Moiz, expiry 2027-02-18)
Next allowed action: none in this pipeline. Hand-off items below.

## Hand-off items (non-blocking, before a bilingual release)

1. Native-speaker sign-off on the Arabic copy, especially `twoFactorRequired`
   (reconstructed after the ARB incident, now captured in
   `docs/evidence/states/signin_twofactor_390_ar.png`).
2. `WorkshopTextField` still cannot draw an error outline (write-locked
   primitive). Component debt, not this screen.
3. Design-system barrel is write-locked by ACL; the two new sign-in primitives
   are app-local. Promote them only if that freeze is lifted deliberately.
4. Four cosmetic residues accepted by the reviewer: 4 px band/form axis at ≥600,
   gallery tile alignment, no focused-state capture of the screen itself,
   `P8` validation-message proximity.

## Rejection record — why Phase 6 failed (2026-11-18)

User verdict: "UI and UX was very bad". Confirmed structurally, not as taste alone:

- 1440 and 390 compositions are identical to `HEAD` (50/50 panel split, centred
  form, card on the panel). Only colour, type sizes, spacing and one label moved.
- The "rebuild" made no new per-region widget files and deleted nothing.
- Therefore the edit-vs-replace test fails on three of four clauses → restyle.

Evidence and the three replacement directions: `docs/directions.md`.
Old renders: `git show HEAD:...workshop_signin_1440.png` vs
`test/screenshots/real/workshop_signin_1440.png`.


## Verification on resume

Every artifact path above must exist before its gate is trusted. If one is missing,
downgrade that gate to PENDING and say so.

## Progress log

| Date | Phase | Result |
|---|---|---|
| 2026-11-18 | 0 | Audit complete: 0 analyzer issues, 393/396 tests pass, 3 allowlisted failures (all `workshop_login_page.dart`), build 60.99 MB. 10 findings + 3 open questions. |
| 2026-11-18 | 0 GATE | **PASS (user).** Invariants, allowlist and font strategy accepted. User decision: **keep the brand-panel product mock and localize it** (not drop, not replace with live data). 2FA copy → "contact your platform administrator"; light-only confirmed as the product stance. |
| 2026-11-18 | 1 | **PASS (self).** 22 visible elements inventoried (14 VERIFIED, 4 FABRICATED-decorative by decision, 2 SUSPECT both root-caused, 1 MISSING copy). Contracts derived from server code. 8 data gaps. One evidence gap (G7: no live capture) carried to Gate 2b. |
| 2026-11-18 | 2 | Brief 1 written: 11 requirements, 4 phases, engineering only. **Awaiting Gate 2 approval.** |
| 2026-11-18 | 2 GATE | **PASS (user).** Brief 1 approved as written. |
| 2026-11-18 | W1 | Phases A-D executed. 406 tests (403 pass, 3 allowlisted), analyzer 0, format 0 new, build untouched. Sign-in page coverage 96.9%. Gate proven red on an injected failure and on a stale allowlist entry. |
| 2026-11-18 | 2b GATE | **PASS (self).** Characterization tests green before any lib change; injection proof + revert recorded; contract fixes match `docs/api/contracts.md`. Open risk: G7 (no live server — no Docker, Java 17 only) carried forward; no W1 metric depended on it. |
| 2026-11-18 | 3 | `docs/ui_brief.md` written: feeling, anti-goals, signature idea (proposed), IA, 2-step flow, per-breakpoint layout, 12 states, microcopy, a11y, 10-point acceptance checklist. **Awaiting Gate 3 approval.** |
| 2026-11-18 | 3 GATE | **PASS (user).** Spec approved as written: labelled example job as hero, panel dropped below 900 px, top-weighted phone form. |
| 2026-11-18 | 4 | `docs/phase-4-target-map.md`: no new boundary (argued), 10 findings + 5 green-lies mapped, 6 revertible steps, harness verified. Smoke capture `docs/evidence/phase-4-signin-smoke.png` renders real glyphs (and shows the plate tofu, i.e. the capture is real). **PASS (self).** |
| 2026-11-18 | 5 | `docs/visual_language.md` committed: signature "One job, mid-inspection", tokens, motion, RTL isolation rule. `WorkshopGridPainter` added to the design system. Gallery captured: `docs/evidence/gallery/gallery_{ltr,rtl}_light.png`. Gallery exposed 3 real issues (error border limitation, bidi reordering, flat texture) — recorded. |
| 2026-11-18 | 5 GATE | **PASS (user).** Visual language approved; waivers W-LIGHT and W-NOTOTP countersigned (owner Syed Moiz, expiry 2027-02-18). |
| 2026-11-18 | 6 | Mini Brief executed: page rebuilt on tokens (A1–A3 now green and deleted from the allowlist), signature panel, mobile top-weighted form, bidi isolation, motion, semantics. 414 tests pass / 0 fail; analyzer 0; format 0 new; no `RenderFlex overflowed`. Evidence in `docs/evidence/`. Independent review running. |
| 2026-11-18 | 6 GATE | **FAIL (user).** "UI and UX was very bad." Re-checked structurally: the built screen is the original composition with new paint — no new region files, nothing deleted, same 1440/390 structure. Restyle, not a rebuild. |
| 2026-11-18 | 3 (reopened) | `docs/directions.md`: thinking protocol + three structurally different directions (A work order / B the bay / C the pass), each with 1440 + 390 + style-tile real-font renders in `docs/evidence/directions/`. **Awaiting Gate 3.** |
| 2026-11-18 | 3 GATE | **PASS (user).** Direction **B — "The bay"** chosen. Spec rewritten as `docs/ui_brief.md`; structural departures and acceptance criteria listed. |
| 2026-11-18 | 5 | Primitive kit (`signin_primitives.dart`: chassis mark, 24-tick spine), gallery re-captured at 1280×1240 LTR + RTL, `docs/visual_language.md` committed with kill list. DS barrel is write-locked → primitives stay app-local. |
| 2026-11-18 | W2 slice | Screen rewritten as 7 region files + page. 433 tests pass, analyzer 0, baseline_check OK, format 0 new. Evidence: `docs/evidence/states/` (14 PNGs incl. 2FA, 200 % at 360, AR error). **Gate 5 approval pending.** |
| 2026-11-18 | 5 GATE | **PASS (user).** Visual language and the reference slice approved. |
| 2026-11-18 | 6 GATE | **FAIL (independent).** B1 no desktop language toggle; B2 Arabic counts bidi-inverted; B3 submitting state invisible/unnannounced; B4 768 px on two axes. Six further polish items. All fixed; two regression tests added (AR base direction, in-flight announcement). |
| 2026-11-18 | 6 (re-review) | Fixed B1–B4 + P1/P2/P3/P9; deleted `lib/preview/` (rejected directions). **Second review: FAIL** — B1/B3/B4 pass; B2 half fixed: the Arabic percent was dropped in paint (the now-pointless LRI/PDI isolate), and the added direction test could not see it. |
| 2026-11-18 | 6 (round 3) | Isolate removed from the AR figure; percent verified painted at 1280 and 390 AR. Phone/tablet band no longer duplicates "Workshop Admin"; gallery gained Submit idle/focused/in-flight and an LTR-pinned RTL example tile; focus ring restored on the new button; CTA weight back to w600; 3 Arabic phone captures added. 428 tests pass, analyzer clean, baseline_check OK. **Third review: PASS (independent), 10/10 acceptance items, no blocking findings.** |
| 2026-11-18 | post-pass | Reviewer's one-line ring fix applied (`tapTargetSize: shrinkWrap`, full-height fill) — the 1 px top/bottom ring gap is gone (verified by pixel scan). Band padding symmetrised (4 px axis residue), gallery RTL tile aligned. Final: 428 tests pass, analyzer clean, baseline_check OK. |
| 2026-11-18 | incident | `git checkout` on the two ARB files destroyed uncommitted locale keys. EN restored verbatim from generated output; AR reconstructed from pre-loss screenshots. Arabic `twoFactorRequired` copy is unreviewed — flagged in `brief-2-mini-results.md`. |

## Waiver candidates (need a human owner + expiry — not yet approved)

| ID | Gate | Would waive | Why | Owner | Expiry |
|---|---|---|---|---|---|
| W-LIGHT | 5 | Dark-theme evidence | App is light-only by an earlier product decision (`tokens.dart:736-748`, `app.dart:18`); rebuilding one screen must not invent a dark theme | _unassigned_ | _unassigned_ |
| W-NOTOTP | 3 | TOTP entry state | `source_scan_test.dart:248-264` forbids TOTP UI in the admin app; `ADMIN_TOTP_REQUIRED` defaults false. The screen must show a localized message instead of an input | _unassigned_ | _unassigned_ |

Neither waiver is used yet. If the user rejects either, the pipeline does not start Phase 3.
