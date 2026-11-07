# F3-0 test report (7 November 2026)

F3-0 is audit + decide only, plus the two O1/O2 code fixes. No Workshop
Admin screen was built; no F4/F5; no technician screens 8/10/12. No server
change. No commit. Stop at gate.

## 1. Step 0 changes (only code changes in F3-0)

- **O1:** recorded the screen-09 Level 1 waiver (SSIM 0.97362) with date in
  `decisions.md`. Docs only.
- **O2a — login footer copy:** `technicianNeedTechnicianAccess` EN
  "Need technician access?" → "Need technician login?" (measured 139.78 px
  in the 153.53 px Figma slot), `technicianContactAdmin` EN "Contact Admin"
  (90.26 px, truncated) → "Get help" (51.36 px in the 64.94 px slot); AR
  "تحتاج إلى وصول فني؟" → "تحتاج إلى دخول؟" (105.78/153.53),
  "تواصل مع المسؤول" (116.92, truncated) → "مساعدة" (40.36/64.94).
  Widths measured with real bundled fonts + shipped styles via a scratch
  widget test (deleted after use). ARB EN+AR edited, `flutter gen-l10n`
  regenerated (6-line diff in `gen/`), `widget_test` EN+AR expectations
  updated, `f2a1_geometry` prompt string updated (x unchanged — LTR
  start-aligned in the fixed box), new `test/o2_copy_fit_test.dart` (3/3:
  EN fit, AR fit, empty-state clip). Login goldens EN+AR re-baselined after
  visual check (new goldens show the full untruncated strings).
- **O2b — empty-state header clip:** `assigned_jobs_view.dart`
  `_M.contentWidth` 350 → 334 (header viewport is 350 − 16 end-pad = 334;
  the trailing pill was clipped 16 px). One-number fix, no geometry change
  at 1.0x otherwise. `f2a1_geometry` bay-pill x 317.98 → 301.98 (pill 1 x
  unchanged). Empty-state goldens EN+AR re-baselined after visual check
  ("0 JOBS" fully visible). F2-B.3 `golden-rebaseline.md` R1/R3 are
  superseded by these two fixes.

## 2. Final verification (after the last change, in order)

| Check | Result |
|---|---|
| `flutter analyze --fatal-infos` (client) | clean — `No issues found!` |
| `design_system` full | 88/88 pass |
| auth | 0 tests (no `test/` dir, confirmed) |
| technician_app full (incl. new `o2_copy_fit_test` 3/3) | **178/178 pass** |
| admin_app full | 93/93 pass |
| ui_gallery full | 5/5 pass |
| Client total | **364 pass / 0 fail / 364 total** |
| Server `mvn -DskipITs=false test` (full) | **89 run / 0 fail / 6 skipped / BUILD SUCCESS** |
| `tokens generate --check` / `print-tokens --check` | pass / pass |
| Web build technician_app / admin_app | success / success |
| Debug APK technician_app | success |

Server skips (6, all conditional — 0 failures): POSIX-assumption
(`FileSystemObjectStorageTest`), PDF-sample opt-in property
(`ReportPdfSampleTest`), S3 endpoint (`S3ObjectStorageIT`), plus the 3
MySQL Testcontainers suites skipped because Docker was unavailable in
this run (`MySqlImmutabilityIT`, `MySqlMigrationIT`, `MySqlPiiMigrationIT`
— "Could not find a valid Docker environment"). Prior F2-B.3 runs with
Docker available had these 3 green; no server code changed since.

## 3. Could not verify

Real devices; native Arabic review (new AR strings are translations by
the implementer, pending native review per TR-R009); Docker-gated MySQL
suites this run; anything outside Step 0 + F3-0 docs.
