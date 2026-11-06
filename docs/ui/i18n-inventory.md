# TrueReport client i18n inventory (Phase C0 Workstream C)

Scope: every user-visible string literal in `lib/` of the shipped Flutter
client (`client/apps/technician_app`, `client/apps/admin_app`,
`client/packages/{auth,design_system,l10n,core,domain,api_client,offline_sync}`).
`client/apps/ui_gallery` is dev-only tooling (see §7) and is excluded from the
source-scan gate but listed for completeness.

Conventions: ARB keys are semantic (`photoSourceCamera`), never copied EN
(`cameraButton`). Placeholders (`{count}`, `{done}`, `{total}`, `{verified}`)
are preserved 1:1 between `app_en.arb` and `app_ar.arb`.

## 1. Fixed in this workstream

| # | File:line (post-change) | Was | Now | ARB keys (EN / AR) |
|---|---|---|---|---|
| 1 | `packages/l10n/lib/l10n/app_ar.arb:298-355` | `?????? ???????` mojibake (58 values) + missing `@…` placeholder blocks | Restored MSA Arabic, added 9 `@…` placeholder blocks | — (see §2) |
| 2 | `technician_app/.../f2a/consent_view.dart` (`_DecisionSection`) | `label: 'Required'` | `label: l10n.consentRequired` | `consentRequired`: Required / مطلوب |
| 3 | `technician_app/.../pages/assessment_page.dart:145,150` | `const Text('Camera')`, `const Text('Gallery')` (photo-source sheet) | `Text(l10n.photoSourceCamera)`, `Text(l10n.photoSourceGallery)` | `photoSourceCamera`: Camera / الكاميرا · `photoSourceGallery`: Gallery / المعرض |
| 4 | `admin_app/.../pages/item_form_page.dart`, `template_builder_page.dart`, `template_version_page.dart`, `master_content_tab.dart:71,179` | `'v… · <status>'` with raw `DRAFT`/`PUBLISHED`/`RETIRED` codes (5 sites) | `contentStatusLabel(l10n, status)` (new shared `admin_app/lib/src/labels.dart`) | `draft`/`published`/`retired` (existing) |
| 4b | `admin_app/.../pages/hierarchy_tab.dart:284`, `staff_tab.dart:57,59` | `'${…} · ${role}'` raw role codes, `StatusChip(label: member.status)` raw status | `memberRoleLabel` (`TECHNICIAN/WORKSHOP_ADMIN/PLATFORM_ADMIN`), `memberStatusLabel` (`ACTIVE/DISABLED/PENDING`), same shared file | `roleTechnician`/`roleWorkshopAdmin`/`rolePlatformAdmin`, `filterActive`/`disabled`/`pending` (existing) |
| 5 | `packages/auth/.../sign_in_view.dart` (`SignInCopy`, `copy:`) | Figma strings as constructor defaults (`TrueReport`, `Vehicle Condition & Fleet Diagnostics`, `Password help`, `Sign In`, `Contact Admin`, …) | Removed `SignInCopy`; all copy from `AppLocalizations` | existing keys; language switch now uses `languageEnglish`/`languageArabic` (was Figma default `عربي`) |
| 6 | `packages/design_system/.../figma_screen_kit.dart:544` (`FxLanguageSwitch`) | Default params `englishLabel = 'English'`, `arabicLabel = 'عربي'` | Both labels `required`; sole caller (`sign_in_view.dart`) already passes `l10n` | `languageEnglish`/`languageArabic` |
| 6b | `design_system/.../figma_screen_kit.dart` (`FxLanguageSwitch` segments) | `semanticLabel: 'English'` / `'العربية'` hardcoded while labels are params | `semanticLabel: englishLabel` / `arabicLabel` | caller-passed `l10n` |
| 7 | 5× `technician_app/.../screens/f2a/*.dart` | `figmaText`/`figmaPreview` params + ~100 true-branch Figma literals (`Renault`, `Megane 3`, `TechInspect`, `Bay 3/4/#04`, `Arthur Pendelton`, `David Vance`, `Alex Lindqvist`, VINs, plates, …) | Params removed; product branches kept; Figma wording moved to `technician_app/test/support/figma_l10n_override.dart` + fixture data | existing keys (override serves Figma text through them) |

## 2. `app_ar.arb` mojibake diagnosis

- File is valid UTF-8; corruption is literal ASCII `?` runs (`?????? ???????`),
  not mis-decoded bytes (no `Ø§`-style sequences in the ARB). 58 values
  (`technicianWelcomeBack` … `technicianEquipmentIdsOnly`) were replaced by
  `?` runs — consistent with an ASCII-only export/paste pipeline overwriting
  those values. Surrounding values (incl. Arabic with placeholders such as
  `من {total}`) were intact, and `gen/app_localizations_ar.dart` still held
  the correct Arabic, confirming the loss happened in the ARB only.
- Fix: re-translated all 58 values to MSA Arabic from the EN source
  (placeholders kept, e.g. `{count} في القائمة`, `تم إنجاز {done} من {total} فحوصات`),
  added the 9 missing `@key` placeholder blocks
  (`technicianJobsInQueue`, `technicianCategoriesCount`, `technicianChecksCount`,
  `technicianNoIssueCount`, `technicianAttentionCount`, `technicianDefectsCount`,
  `technicianCoverageSemantics`, `technicianOfTotal`, plus pre-existing ones kept).
- Also added: `consentRequired`, `photoSourceCamera`, `photoSourceGallery`.
- Verified: `en`/`ar` key parity 433/433, placeholder-set parity for all
  parameterized keys, zero `?{3,}` runs, zero empty values, `flutter gen-l10n`
  regenerated, `dart analyze` clean.

## 3. Remaining user-visible literals (with proposed ARB keys)

All are intentionally left in code (see rationale); the source-scan gate
(`technician_app/test/i18n_source_scan_test.dart`) allowlists them explicitly.

| File:line | Literal | Context | Proposed key (not yet added) |
|---|---|---|---|
| `technician_app/lib/app.dart:15` | `'TrueReport Technician'` | `MaterialApp.title` (OS task switcher; never translated on either platform) | — (keep; OS chrome) |
| `admin_app/lib/app.dart:15` | `'TrueReport Admin'` | same | — (keep) |
| `admin_app/.../pages/job_form_page.dart:138` | `hint: '2026-11-05T09:00:00'` | ISO-8601 format example for `scheduledAt`; translating it would break the format | — (keep; format sample, allowlisted) |
| `technician_app/.../screens/f2a/assigned_jobs_view.dart` (`formatOdometer`) | `'KM'`, `','`, `'UTC+4'`, `'$hour:$minute UTC+4'` | Number/date formatting (grouping separator, unit fallback, UTC+4 shift label) | `odometerUnitFallback`, `scheduleTimeUtc` (future; needs ICU — EN/AR digits differ) |
| `technician_app/.../screens/f2a/equipment_view.dart` (`'01'` badge) | `'01'` step badge | Numeric badge, locale-independent | — (keep) |
| `technician_app/.../screens/f2a/*` + `f2b/*` (`initials: 'TR'`) | `'TR'` avatar fallback | Initials placeholder, not a word | — (keep; allowlisted, max 2–3 chars) |
| `design_system/.../technician_shell.dart:43` | `'TrueReport'` | Brand mark | `appTitle` (already exists; shell takes it as data — follow-up) |
| `design_system/.../figma_screen_kit.dart:584,592` | `semanticLabel: 'English'` / `'العربية'` | Segment semantics mirror the (now required) labels | — (keep; mirrors label input) |
| `design_system/.../tree_view.dart:78,79` | `debugLabel: 'AppTreeView…'` | Debug-only, never rendered | — (keep) |
| `admin_app/.../pages/template_version_page.dart:49` | `retryLabel: l10n.search` | **Suspected wrong key**: retry button labelled “Search”. No literal, but user-visible copy bug | Proposed new key `retryAction` (Retry / إعادة المحاولة) — needs design confirm, not changed here |
| `*/models.dart` (`json['…']`, `toJson` keys) | JSON field names | Wire protocol, never displayed | — (keep) |
| `*/lib/src/*router*.dart`, `api_endpoints.dart` | Route/API paths, `locale.languageCode == 'ar'`, `Locale('ar'/'en')` | Routing/plumbing | — (keep) |
| `technician_app/.../offline/sync_service.dart:164,199` | `messageKey: 'error.unknown'` | Internal failure key; surfaces via `l10n.genericError`/`actionFailed` at call sites | — (keep; mapped at UI layer) |
| `auth/.../sign_in_page.dart:74-81` | `'AUTH_INVALID_CREDENTIALS'`, `'NETWORK'`, … codes | Server/transport codes mapped to `invalidCredentials`/`networkError`/`genericError` | — (keep; mapping exists) |

## 4. Server error codes / enums → ARB keys (existing mappings, verified)

| Codes | Mapper | ARB keys |
|---|---|---|
| Job status `DRAFT/SCHEDULED/ASSIGNED/IN_PROGRESS/READY_TO_FINALIZE/FINALIZED/CANCELLED` | `technicianStatusLabel` (`technician_app/lib/src/ui_helpers.dart:4`), `jobStatusLabel` (`admin_app/.../jobs_tab.dart:10`) | `draft`, `statusScheduled`, `statusAssigned`, `statusInProgress`, `statusReadyToFinalize`, `statusFinalized`, `statusCancelled` |
| Master-content status `DRAFT/PUBLISHED/RETIRED` | `contentStatusLabel` (`admin_app/lib/src/labels.dart`) | `draft`, `published`, `retired` |
| Result `NO_ISSUE_OBSERVED/ATTENTION_RECOMMENDED/DEFECT_FOUND/NOT_CHECKED/NOT_APPLICABLE/COULD_NOT_VERIFY` | `resultLabel` (`ui_helpers.dart:24`) | `noIssueObserved`, `attentionRecommended`, `defectFound`, `notChecked`, `notApplicable`, `couldNotVerify` |
| Severity `MINOR/MODERATE/MAJOR/SAFETY_CRITICAL` | `severityLabel` (`ui_helpers.dart:34`) | `minor`, `moderate`, `major`, `safetyCritical` |
| Membership role `TECHNICIAN/WORKSHOP_ADMIN/PLATFORM_ADMIN` | `memberRoleLabel` (`admin_app/lib/src/labels.dart`) | `roleTechnician`, `roleWorkshopAdmin`, `rolePlatformAdmin` |
| Membership status `ACTIVE/DISABLED/PENDING` | `memberStatusLabel` (`admin_app/lib/src/labels.dart`) | `filterActive`, `disabled`, `pending` |
| Auth `AUTH_INVALID_CREDENTIALS/AUTH_2FA_INVALID/NETWORK/CONNECTIONERROR/…` | `_messageFor` (`auth/.../sign_in_page.dart:72`) | `invalidCredentials`, `networkError`, `genericError` |
| Sync `ASSESSMENT_EMPTY/EVIDENCE_UPLOAD_UNAVAILABLE` (`error.unknown`) | UI layer snackbars/dialogs | `genericError`, `actionFailed` |

## 5. Figma sample strings moved to test-only override

`client/apps/technician_app/test/support/figma_l10n_override.dart`
(`FigmaTestStrings` + `FigmaTestLocalizations extends AppLocalizationsEn` +
`figmaLocalizationsDelegates`). Covers: `TechInspect`, `David Vance` (data),
`Renault/Megane 3/2021/VF1…/LV71 XZP/Arthur Pendelton/+44…` (fixture data),
`Bay 04`, `SHIFT 1 · BAY A`, `SHIFT ACTIVE`, `Intake/Fleet`, `Authorizations`,
`Allow PDF sharing`, `Customer road test consent`, `Data storage authorization`,
`Diagnostic Checklist`, `Intake Hub`, `Required Equipment`, `Inspection Modules`,
`PRE-INSPECTION SETUP`, `CHECKS DONE`, `STEP 4 OF 4 • FINAL SIGN-OFF`,
`Vehicle Condition & Fleet Diagnostics`, `Forgot password?`, `Sign In`,
`Request ID`, `Scan New VIN Tag`, `Save Consent`, `1 of 4 Verified`,
`42 Passed`, `3 Action Items`, `Fleet Station Standards`,
`ISO-9001 certified diagnostic requirements`, `100% Pass Rate`, `Queued`,
`Primary Owner`, `Pre-Inspection Ready`, `Start Inspection`, `Digital Signature`,
`Sign Above Line`, `Sign with finger or stylus`, bodies (`Send detailed…`,
`Authorize certified…`, `Encrypt telemetry…`), `عربي` switch label.
Data-driven Figma text that product logic cannot reproduce (`ABC 123 · Bay 4`,
`Porsche Taycan 4S`, `WA1-VAA-Y7890 · 12,480 mi`, `AL`/`Alex Lindqvist`,
`10:42 AM · Bay 3`, `INTAKE PHASE`, `Ready for Check`, `INSPECTION IN PROGRESS`,
`45 min`, `Avg. turnover`, `X Tasks`, `LIVE SYNC`, `28/28 Done` on unfinished
modules) is recorded as expected deltas in the fidelity report (§6).

## 6. Before/after fidelity (screens 1–7)

- Geometry gate (`f2a1_geometry_test.dart`): 7/7 pass before → 7/7 pass after.
  Four expectation updates, boxes unchanged: status-derived pills now assert
  product text (`ASSIGNED`, `Assigned`, `IN PROGRESS`); header-title style
  finder scoped to `FxHeader`; ready-pill `x` relaxed (content-driven position).
- Capture (`f2a_fidelity_capture_test.dart`): 14/14 pass.
  `strings.json` before→after: all 6 non-login `product-copy` variants byte-identical;
  login `product-copy` differs by 1 string (`عربي`→`العربية`, intentional §1.5);
  login `figma-text` byte-identical render; other `figma-text` variants differ
  only by the §5 deltas (string counts identical except job-intake +4 from the
  now-visible product action row).
- `render.png` before→after: all `product-copy` non-login renders byte-identical;
  login `figma-text` identical; remainder differ per §5 deltas.

## 7. Out of scope / follow-ups

- `client/apps/ui_gallery` (~120 EN literals: section titles, control labels such
  as `Locale`, `Text scale`, `A2 strategy`, `TrueReport UI Gallery`) is dev-only
  (never shipped to stores). Proposed: prefix keys `gallery…` if it ever ships;
  intentionally not in the scan gate.
- `retryLabel: l10n.search` (template_version_page.dart:49) needs a real Retry key.
- Odometer/time formatting (`formatOdometer`, `scheduledTimeUtc4`) still hardcodes
  `,`, `KM`, `UTC+4`; Arabic-Indic digits + `intl` formatting is a follow-up.
- `technician_shell.dart` brand takes a literal; could take `l10n.appTitle`.
- Golden PNGs (`technician_app/test/goldens`) pre-date this change and will need
  re-baselining (copy changed); dark goldens are additionally blocked on C0
  Workstream B (light-only tokens migration, `AppTheme.dark` removed).
