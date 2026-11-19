# Data inventory — technician sign-in (Phase 1)

Scope: `/signin` only. Full per-hop evidence is in
`docs/data/signin_client_trace.md` (client) and
`docs/data/auth_server_contract.md` (server). This file is the gate summary:
what the screen shows or sends, where it comes from, and whether it is proven.

Status: **VERIFIED** = source and definition confirmed at both ends ·
**ASSUMED** = client proven, environment premise not · **SUSPECT** = trace
exists but yields a misleading/incomplete result · **MISSING** = no source.

**Headline: this screen displays no business metrics, no counts, no dates and no
money.** The only values on it are static localized copy, two credential inputs
and one optional code input. There is therefore nothing to fabricate, and no
number can be "wrong" — the trust risk is entirely in auth behaviour and in
copy that promises something the system cannot do.

## 1. Displayed content

| UI element | Displayed as | Source | Definition | Status | Evidence |
|---|---|---|---|---|---|
| App title | `TrueReport` / `ترو ريبورت` | `appTitle` (static l10n) | Product name, not the tenant name | VERIFIED | `sign_in_view.dart:117-123`; `app_en.arb:3` |
| Wordmark above the title | *nothing* — an empty blurred pill | **none** | `_BrandMark` draws a glow; its `label` arg is never read | **MISSING** | `sign_in_view.dart:390-432` |
| Tagline | "Vehicle inspection reports for partner workshops." | `technicianSignInTagline` | Static product line | VERIFIED | `sign_in_view.dart:132-142`; `app_en.arb:446` |
| Language switch | `English` / `العربية` | `localeProvider` + two l10n keys | In-memory locale | VERIFIED | `figma_screen_kit.dart:593-684`; `locale_controller.dart:5-15` |
| Email field label | `Email` | `emailLabel` | Hint only — no persistent label | VERIFIED (copy) | `sign_in_view.dart:155-169` |
| Password field label | `Password` | `passwordLabel` | Hint only; obscured | VERIFIED | `sign_in_view.dart:171-193` |
| 2FA code field label | `Authentication code` | `twoFactorLabel` | Shown only when `challenge` | VERIFIED (copy) | `sign_in_view.dart:194-209` |
| "Password help" | `Password help` | `technicianPasswordHelp` | **No handler, no route, no reset endpoint** | **MISSING (action)** | `sign_in_view.dart:210-222`; `AuthController.java:29-93` |
| Primary button label | `Sign in` → `Verify` | `signInButton` / `verifyButton` | Switches on challenge | VERIFIED | `sign_in_view.dart:248-264` |
| Access / help line | `Need technician login?` + `Get help` | two l10n keys | `Get help` is styled like a link but is a bare `Text` | **MISSING (action)** | `sign_in_view.dart:280-311` |
| Security line | shield + "Authorised workshop staff only" | `technicianSecurityLine` | Static assurance caption, not a computed state | VERIFIED | `sign_in_view.dart:313-336` |
| Numbers / dates / currency | none | — | Nothing to format or mistranslate | VERIFIED (absent) | `sign_in_view.dart:1-5`, no `intl` |

## 2. Inputs and validation

| Item | Rule | Status | Evidence |
|---|---|---|---|
| Email — required | non-empty after trim | VERIFIED | `sign_in_page.dart:94-99` |
| Email — format | `^[^@\s]+@[^@\s]+\.[^@\s]+$` | VERIFIED | `validators.dart:4, 7-16` |
| Password — required | non-empty; **no length or complexity on login** (deliberate: legacy accounts) | VERIFIED | `sign_in_page.dart:130`; `validators.dart:18-23` (unused on login) |
| Password — sent | passed verbatim, never trimmed, never stored | VERIFIED | `auth_repository.dart:60` |
| 2FA code — client | exactly 6 characters of any kind | **SUSPECT** | `sign_in_view.dart:204-207` |
| 2FA code — server | `\d{6}` TOTP **or** an 11-char recovery code `ABCDE-FGHIJ`; request accepts up to 40 chars | **SUSPECT** (contradiction) | `AuthService.java:127-142, 290-300`; `TwoFactorVerifyRequest.java:7-10` |

## 3. Actions

| Action | Behaviour | Status | Evidence |
|---|---|---|---|
| Submit | validates, then `signIn` or `verifyTwoFactor` | VERIFIED | `sign_in_page.dart:33-79` |
| Submit re-entry | button disables, but Enter bypasses the guard; `_submit` has no in-flight check | **SUSPECT** | `sign_in_view.dart:184`; `sign_in_page.dart:33-38` |
| Language toggle | writes `localeProvider`; rebuilds in place | VERIFIED | `sign_in_page.dart:116-119` |
| Help affordances | no tap target, no destination | **MISSING** | see §1 |

## 4. Errors (server code → visible copy)

| Code family | Copy | Status | Evidence |
|---|---|---|---|
| `AUTH_INVALID_CREDENTIALS` | "Email or password is incorrect." | VERIFIED | `sign_in_page.dart:83`; `AuthService.java:83-93` |
| `AUTH_2FA_INVALID` (wrong / expired / forged / disabled / locked) | the **same** credential copy | **SUSPECT** | `sign_in_page.dart:84`; `AuthService.java:110-146` |
| `NETWORK`, `CONNECTIONERROR`, `CONNECTIONTIMEOUT`, `RECEIVETIMEOUT`, `SENDTIMEOUT` | "Cannot reach the server…" | **SUSPECT** — no Dio timeouts are configured, so three of these can never fire | `sign_in_page.dart:85-89`; `api_client.dart:24` |
| `ACCOUNT_DISABLED`, `NO_WORKSHOP_MEMBERSHIP`, `VALIDATION_FAILED`, `AUTH_TOKEN_INVALID`, `UNKNOWN`, `BADRESPONSE`, 429 | "Something went wrong. Try again." | **SUSPECT** — collapsed | `sign_in_page.dart:90` |
| server `messageKey`, `detail`, `errors[]`, `traceId` | never shown | **MISSING** | `app_failure.dart:10-14`; `sign_in_page.dart:63-67` |

## 5. Session values not shown (they drive routing)

| Item | Source | Status | Evidence |
|---|---|---|---|
| `role` | `platformAdmin` flag else **highest-privilege** membership | **SUSPECT** — the token uses the **primary** membership | `session.dart:18-38`; `AuthService.java:330-340` |
| `workshopId` | `memberships.first.workshopId` | **SUSPECT** — no order is promised | `session.dart:40-41` |
| `memberships[]` | server `memberships` array | VERIFIED | `session.dart:47-49`; `AuthResponse.java:11` |
| `tokenType`, `expiresInSeconds` | server sends `Bearer`, 900 s | **MISSING** — never parsed | `AuthResponse.java:7-9`; `session.dart:13-16` |
| Unknown role string | `Role.fromApi(...) ?? technician` | **SUSPECT** — silent privilege downgrade | `role.dart:10-17, 25` |
| Missing/typed-wrong response keys | non-null casts | **SUSPECT** — `TypeError` surfaces as "generic error" | `session.dart:43-50` |
| Stored session | secure storage `truereport.session` | **SUSPECT** — `jsonDecode` unguarded | `session_store.dart:17-36` |

## 6. Totals

| Status | Count |
|---|---|
| VERIFIED | **16** |
| ASSUMED | **1** (2FA reachability for technicians — see `data_gaps.md` G4) |
| SUSPECT | **11** (all root-caused in §2-§5) |
| MISSING | **5** (wordmark, password-help action, help action, server error detail, token lifetime) |
| **Total** | **33** |

Every SUSPECT has a root cause in the table above or in `docs/data_gaps.md`.
Nothing SUSPECT is presented as a designed metric: this screen has none.
