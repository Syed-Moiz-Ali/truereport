# F2-A.2 report — fix the measurement, close the real gaps

**Project:** TrueReport
**Phase:** F2-A.2 (technician screens 1–7)
**Date:** 6 November 2026
**Status:** implementation complete for review. **The 0.98 gate is not met**;
measured values are reported without lowering the gate. No commit. Stop for
owner approval.

## 1. Was `debugDisableShadows` the cause? Yes.

**Evidence:**

- `C:\Users\sanja\flutter_3.47.9\packages\flutter_test\lib\src\binding.dart`:
  `AutomatedTestWidgetsFlutterBinding.disableShadows => true` (line 2234), and the
  binding assigns `debugDisableShadows = disableShadows` (line 1079).
- The new `f2a2_harness_test.dart` asserts `debugDisableShadows` is `true` before
  the fix and `false` after `enableFidelityShadows()`, and fails if a capture path
  leaves it disabled.
- `f2a_fidelity_capture_test.dart`, the F1.1 `fidelity_capture_test.dart` and both
  F2-A goldens now call `enableFidelityShadows()` and restore the previous value
  before the test body ends (the binding verifies painting variables at that
  point).

A second measurement defect was found during the audits: the `@2x` Figma exports
include an asymmetric shadow margin. Pixel analysis finds the white frame at
`x=60` (or `x=40`) and **`y=14`**, while F2-A.1 used `y=59`/`y=7`. The crops were
corrected. This was the larger cause of the low F2-A.1 numbers.

## 2. Before/after fidelity (measured, not estimated)

Reference: Figma `@2x` export cropped to the true frame origin. Render: 390
logical px, DPR 2, bundled fonts, real shadows, test-only Figma raster photos for
fixture (a). SSIM from `tools/figma_fidelity/compare.mjs`, threshold unchanged at
0.98.

| Screen | F2-A.1 | F2-A.2 Figma text | F2-A.2 product copy | RMSE (a) |
|---|---:|---:|---:|---:|
| Login | 0.97210 | **0.97721** | 0.96039 | 11.88 |
| Assigned jobs | 0.79111 | **0.94907** | 0.89062 | 19.92 |
| Empty state | 0.84140 | **0.96216** | 0.93294 | 19.09 |
| Job intake | 0.80267 | **0.88097** | 0.83288 | 38.16 |
| Consent | 0.80815 | **0.92212** | 0.86533 | 27.17 |
| Equipment | 0.82759 | **0.93352** | 0.91971 | 23.89 |
| Inspection hub | 0.81949 | **0.94963** | 0.92641 | 23.99 |

Login measured **0.98040** after the shadow/crop fixes but before J3; the
approved J3 replacement of the ISO line lowers it to **0.97721**. The gate is
still not met; it was not lowered.

## 3. Corrected shadow verification

Component samples re-measured with real shadows and the corrected reference:

| Sample | F2-A.1 | F2-A.2 |
|---|---:|---:|
| Primary button | 0.99520 | **0.99622** |
| Delivery card | 0.99198 | **0.99261** |
| Result selector | 0.98340 | **0.98756** |

The earlier “shadow blur matches” claims were invalid because they were measured
with solid shadow blocks. They are withdrawn and replaced by these measurements.
No token value changed: the Figma card shadow (`0,2,8` α0.016 + `0,14,40`
α0.043), CTA glow (`0,10,25` emerald 30%), pill and nav shadows are the node
values. The residual is Flutter-vs-Figma shadow rasterisation.

## 4. Region-level diff findings and fixes

Auditors wrote `f2a2-audit-01-…` for login, jobs, empty, consent and hub. The
job-intake and equipment auditor runs were cancelled by an upstream overload; the
lead performed those two region analyses from `metrics.json` and the diff
heatmaps. Findings applied:

- **Reference crop:** corrected to the true frame origin. This alone moved most
  screens from ~0.80–0.85 to ~0.94–0.96.
- **Login (J6):** removed the solid TR tile; only the soft green glow remains.
- **Login (J3):** security line replaced with “Authorised workshop staff only”.
- **Assigned/empty:** Figma raster avatar used in test-only fixtures; avatar glow
  changed to emerald 15% + emerald blur 16/4; queue/Bay/dock icon IDs corrected;
  summary arrow restored; card bottom row top padding 12; per-card Figma
  references/service copy; empty heading punctuation and body copy.
- **Job intake/hub:** Figma raster vehicle photo and avatar used in fixture (a);
  header profile uses the Figma person icon, not the photo; hub/consent/equipment
  headers use the Figma icon slot; equipment now shows the J5 labels/code/status.
- **Consent:** Figma preview state (two switches on) for fixture (a); J4 decision
  slot retained.

Residual causes are dominated by text rasterisation (same metrics, different
anti-aliasing), the J3/J4 slot replacements, and product-data differences. No
large layout offset remains except the approved decision/signature region.

## 5. Text details (4.3)

`f2a1_geometry_test.dart` now asserts font family, size, weight, line height and
letter spacing for the requested nodes, including the login “Forgot password?”
(11/14 w600 ls0.44) and “Sign In” (14/18 w700 ls−0.14), the assigned welcome/name/
section styles, the empty heading, the job-intake title, the consent title, the
equipment title and the hub title/module title. All assertions pass. The full
Figma text-style dump is retained at `docs/ui/figma/f2a1-nodes/text-styles.json`.

## 6. J1–J7 outcomes

| ID | Outcome |
|---|---|
| J1 | Fleet dock maps to **Finalized** jobs; Figma icon/position kept. Product label `Finalized`; fixture label `Fleet`. |
| J2 | **Password help** and **Contact Admin** kept in the same slot/size/style. |
| J3 | Security line is **“Authorised workshop staff only”**; product forbidden-term lint passes; no certification claim. |
| J4 | Signature capture stays out of scope; the decision slot holds Granted/Refused. |
| J5 | Server returns `equipmentIds` plus `items` (`equipmentId`, `code`, `labelEn`, `labelAr`, `status`, `sortOrder`). Flutter model and equipment screen use the real labels/code/status. No schema/write/permission change. |
| J6 | Logo slot is the soft green glow only; no TR tile. Export JSON contains an empty `TechInspect Minimal Logo` frame (`1:7090`, x163 y104, 64×64) with no vector/raster asset. |
| J7 | Figma raster avatar/vehicle PNGs are decoded only by test helpers; they are not in any pubspec asset list and a guard test checks the source and the web asset manifest. |

## 7. Server / Maven

Maven **was available** this session: Maven 3.9.16 on PATH and `JAVA_HOME` pointing
to `C:\Users\sanja\jdk-25.0.5+8` (Java 25.0.5); the previous session’s “Maven not
available” was an environment/PATH issue, not a project defect. No project change
was needed for Maven.

Full server suite after adding the read-only equipment API and disabling the
non-existent SMTP mail health check in the **test profile**:

- `mvn -DskipITs=false test` → **Tests run: 65, Failures: 0, Errors: 0, Skipped: 6; BUILD SUCCESS**.
- The 6 skips are Docker/opt-in MySql/S3/PDF-sample tests (no Docker in this
  environment).
- Focused equipment tests: **7/7** in `TechnicianInspectionIT` (own job, labels,
  EN/AR, ordering, membership, cross-workshop denial, read-only methods).
- `ArchitectureTest` (Spring Modulith boundaries + ArchUnit) passes.

## 8. Tests and builds

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` (technician, design_system, admin, auth) | Clean |
| Technician app tests | **113 passed** |
| Design system tests | **136 passed** |
| Admin tests | **83 passed** |
| F2-A.1 geometry + text-style tests | **7/7 screen cases, 55 geometry checks, 12 style checks passed** |
| Fidelity capture (7 screens × 2 fixtures, real shadows) | 14 passed; artifacts written |
| Goldens EN/AR light + EN dark | Updated with real shadows; passing |
| Screenshots EN/AR 1×/2× | Written to `docs/ui/figma/f2a-screenshots/` |
| Web build | Passed |
| Debug APK | Passed |
| Server suite | **65 run, 0 failures, 6 Docker/opt-in skipped** |

## 9. What still differs and why

- **Text rasterisation:** same family/size/weight/line-height/tracking, different
  anti-aliasing between Figma and Flutter. It dominates the remaining diff boxes.
- **J3:** the shorter security line changes its centred x; the slot/style/height
  are unchanged. Login 0.98040 → 0.97721.
- **J4:** the signature region is replaced by Granted/Refused. Approved residual.
- **J1/product data:** `Finalized` vs `Fleet` and real job data vs Figma samples.
- **Product copy:** fixture (b) intentionally uses real data; its SSIM is lower
  where the slot sheet allows changes.
- **Equipment:** names/labels now come from the server, but verification/pairing
  state is still not modelled, so the status circles stay unticked.

## 10. What could not be verified

- No real-device test (Android/iOS). The builds pass, but camera, keyboard,
  Arabic shaping, sunlight and one-hand reach were not tested.
- No native Arabic review.
- No Docker, so the 6 opt-in MySql/S3/PDF-sample tests remain skipped.
- Shadow colour/alpha exactness against Figma cannot be proven beyond the
  measured SSIM and the node values; Figma and Flutter rasterise shadows
  differently.
- The job-intake and equipment auditor subagent runs were cancelled by an
  upstream overload; the lead did those analyses (no app code was changed by the
  failed runs).

## 11. What the owner should check on a real phone

Compare each screen against its Figma image in English and Arabic:

1. Login: glow-only logo, white fields, emerald CTA and the J3 footer line.
2. Jobs/empty: Finalized dock slot, avatar photo (test-only) vs initials in
   product, card shadows, queue/Bay pills.
3. Job intake: vehicle hero photo in fixture vs product silhouette, VIN copy,
   customer actions and sticky CTA.
4. Consent: two consent cards + disabled data-storage card, Granted/Refused
   decision.
5. Equipment: real names/codes from the J5 API and unticked status circles.
6. Hub: ring coverage, result pills, module progress and vehicle strip.
7. Large text 1.5×/2.0×, sunlight, one-hand reach and Arabic RTL.

**Stop for approval. F2-B was not started.**
