# Data gaps — Workshop Admin sign-in (Phase 1)

No designed element on this screen depends on MISSING data, because the screen shows no live data
at all. The gaps below are the ones that will block or distort the rebuild.

| ID | Gap | Class | Consequence | Fix in | Blocking? |
|---|---|---|---|---|---|
| G1 | The preview card is entirely fabricated (car, plate, customer, checklist 18/24, technician, "45m ago"). No endpoint produces it. | FABRICATED | A user could read it as a live job. Keeping it (Gate 0 decision) requires it to be **localized and labelled as an example**, and it must never drive layout differently from real data. | mini Brief | No — decision made |
| G2 | Numbers are built by string concatenation: `'18 / 24 items (75%)'` (`workshop_login_page.dart:546`). | PRESENTATION | Arabic renders `items (75%) 24 / 18` (visible in `workshop_signin_1280_ar.png`). No `NumberFormat`, no plural rules. | mini Brief | Yes for AR acceptance |
| G3 | `AuthChallenge` returned by the API is discarded; the screen shows nothing. | **MISSING BRANCH** | With `ADMIN_TOTP_REQUIRED=true` the user cannot sign in and is never told why. | Brief 1 | Yes — invariant I6 |
| G4 | `Session.role` returns `memberships.first.role` (`session.dart:18-26`). Server order is not guaranteed (a user with memberships in two workshops can be a technician in one and an admin in the other). | **SUSPECT** | A workshop admin can be redirected to `/unauthorized` after a *successful* sign-in. Root cause identified; not yet reproduced live. | Brief 1 (characterization test + explicit membership selection) | Yes — it changes where sign-in lands |
| G5 | An unknown `role` string silently becomes `Role.technician` (`membership.dart:17`, `role.dart:10-17`). | ASSUMED SAFE | New server roles degrade to technician instead of failing loudly; a legit admin gets locked out with no message. | Brief 1 (explicit unknown-role handling + test) | No |
| G6 | The workshop app never sets `ApiClient.acceptLanguage` or `clientName` (platform app does, `platform_admin_app/lib/main.dart:38-39`). | **MISSING** | Server `detail`/`messageEn`/`messageAr` come back in the server default locale; audit loses `X-Client`. Invisible on this screen today (the banner is built from `code` + `l10n`), but any screen that renders `AppFailure.detail` will show the wrong language. | Brief 1 (shared bootstrap) | No for sign-in, yes before any screen renders `detail` |
| G7 | No live contract capture. All samples are constructed from code. | **EVIDENCE GAP** | A producer/consumer drift would pass Gate 1 undetected. | Gate 2b verification step | Yes for Gate 2b |
| G8 | `signInHelp` promises "Contact your platform administrator for access." No support address, no mailto. | COPY | Users without access have no actionable path. Acceptable if the platform admin is internal; otherwise it is dead-end copy. | Gate 3 (spec) | No |

## Dispositions

- G1 — **kept** per Gate 0. Must be labelled `Example` and read as decorative by a screen reader,
  so it is never announced as the user's actual job.
- G2 — **fixed**, localized message with placeholders.
- G3 — **fixed**, localized message, no TOTP input.
- G4/G5 — **fixed** with characterization tests first (they currently pass by accident; the tests
  must pin today's behaviour, then the fix changes it deliberately).
- G6 — **deferred** to the shared bootstrap; recorded so it is not forgotten.
- G7 — **scheduled** at Gate 2b.
- G8 — **decided at Gate 3** (spec).

## Gate 1 self-grade

| Criterion | Result |
|---|---|
| Every designed element classified | ✅ 22 elements, table in `docs/data/inventory.md` |
| Zero SUSPECT left unexplained | ✅ 2 SUSPECTs (plate tofu, membership ordering) — both root-caused |
| Every metric VERIFIED, relabeled, or removed | ✅ the only number (18/24 = 75%) is arithmetically verified and marked FABRICATED-DECORATIVE by decision |
| Missing data never estimated to fill a mock | ✅ no mock was invented; the existing mock is kept knowingly, not accidentally |
| Live confirmation | ❌ not possible this session → G7 carried into Gate 2b |

**Gate 1 verdict: PASS with one evidence gap (G7) that Gate 2b must close.** No app code changed.
