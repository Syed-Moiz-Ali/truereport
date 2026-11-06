# C0 report — account model, light-only, full localization (6 November 2026)

## What changed
- **A server:** strict admin-created accounts (A1–A8). New `POST /platform/users` (WORKSHOP_ADMIN only), `POST /workshop/technicians`, `POST /platform/users/{id}/password-reset`, `POST /workshop/technicians/{id}/password-reset`. Argon2, policy 12–128 + 4 classes, Idempotency-Key, neutral EMAIL_EXISTS, last-admin guards (+ lead transfer LAST_WORKSHOP_ADMIN fix), session revocation, tenant isolation + neutral 404. Removed invite endpoints (404/401), pending filter (400), pendingInvitations fields. Invitation tables kept. Migration V18 idempotency keys (H2 + MySQL 8.4.13 verified). Idempotency canonical excludes passwords (lead fix for F3).
- **A clients:** admin_app invite UI + pending filters removed; minimal create/reset dialogs per role (fixed role, no workshop picker for technicians); `Idempotency-Key` via Uuid v7; technician login help = localized contact-admin text; no signup UI. `c0-admin-accounts-slot-sheet.md` covers Figma fields. Lead fixed dialog controller dispose-after-pop crash + dark breakage.
- **B light-only:** dark ThemeData/tokens/goldens/CSS removed; `color-scheme: light` + meta; generator + print-tokens `--check` light-only; `contrast-after.md` light-only; gallery light-only; ADR-F1-006 supersedes A6/G1-dark. Lead migrated `app.dart` call sites, removed dark test, fixed tokens tests.
- **C localization:** `app_ar.arb` ?????? (58 values) restored to MSA Arabic, 433/433 key parity + placeholder parity; `i18n-inventory.md`; 3 literals + admin enum mappers fixed; server `report_*/delivery_*` bundles EN+AR + parity test + template literal scan; `ApiErrorContractTest` pins code→ARB; `figmaText` deleted from `lib/`, moved to `test/support/figma_l10n_override.dart`; `i18n_source_scan_test` gates Figma terms/raw literals/ARB integrity.

## Endpoints
Added 4 (above). Removed 2 (platform invitations, auth accept). Kept disable/reactivate (platform-only) + transfer (platform-only + new last-admin guard).

## Tests / builds
- `flutter analyze --fatal-infos`: clean.
- Client: `i18n_source_scan` 3/3, `f2a_screens` 44/44, `tokens` 19+ (light-only), `staff_account` 10/10 EN+AR (after lead dialog fix), `f2a1_geometry` 7/7, `f2a2_harness` pass. Full client suite not run (time); dark tests deleted by design.
- Server: `mvn test` 88 run, 0 failures, 3 skipped (S3/PDF-sample/POSIX env). Includes PlatformHierarchyIT 13/13, bundles 10/10, contract 4/4, H2 + MySQL 8.4.13 migrations.
- Generators: `generate.mjs --check`, `wire-print-tokens.mjs --check` pass. Web + debug APK build pass.
- Fidelity screens 1–7: geometry 7/7 before→after (4 expectation updates, boxes unchanged); capture 14/14 (6 non-login product-copy + login figma identical; other figma diffs documented data/structural only). No regression.

## Remaining gaps
- `retryLabel: l10n.search` looks wrong (needs real Retry key + design confirm).
- ICU date/number localization, `MaterialApp.title`s, `'TR'/'01'`, `UTC+4` formatting follow-ups (see inventory §3/7).
- `ui_gallery` ~120 EN literals treated dev-only, excluded from gate.
- Token `tokens.json` dark values ignored, not deleted (lead proposal).
- Defense-in-depth `@PreAuthorize` on platform endpoints (F2) open; drop-invitation-tables migration proposed separately.
- Arabic pending native review; no real-device testing claimed.

## Decisions needed
Confirm Retry key, PDF EN sentence on AR-review, bilingual PDF per-language purity, tokens.json dark deletion, `[data-theme=light]` alias retention, server GET masked-email for create confirm, forced-password-change design (A6 risk accepted for v1).

## Check on a real phone
Create Workshop Admin as Platform Admin → create technician as Workshop Admin → login as technician → reset password (old session revoked) → EN/AR everywhere (no English leftovers, no ??????), no dark mode incl. system dark, report/PDF bilingual, offline queue real counts, 2.0x no truncation, VIN LTR in RTL.
