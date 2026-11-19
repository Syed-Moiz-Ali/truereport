# Data gaps — technician sign-in (Phase 1)

Nothing here is fixed in Phase 1. Each row says what the UI wants, what exists,
what is missing, and the honest interim behaviour for the rebuild. Proposed
backend changes are suggestions for the owning team, not edits made here.

| ID | UI need | Why it matters | What exists today | What is missing | Proposed backend change | Interim UI behaviour |
|---|---|---|---|---|---|---|
| **G1** | A real way to get help / reset a password | The screen says "Password help" and shows a link-styled "Get help", but neither does anything. A promise with no channel erodes trust more than no line at all | Copy keys `technicianPasswordHelp`, `technicianNeedTechnicianAccess`, `technicianContactAdmin`; admin-initiated reset endpoint `/platform/users/{id}/password-reset` only | Any technician-accessible reset or contact channel; any tap handler or destination | Product decision: a support URL/mailto, or a self-service reset flow | **Remove "Password help"** (dead). Keep the access line as **static, non-link** text (no green link styling). Recorded as a deliberate deletion |
| **G2** | Server error detail, field errors, support trace | A user or support agent cannot tell a 422 from a 500 from a network fault; `traceId` is discarded | `AppFailure` carries `messageKey`, `detail`, `traceId`; RFC-7807 body provides them | Nothing surfaces them; the page reads only `code` | None (client change) | Keep code-based copy; **do not invent** detail. Log `traceId` only in debug |
| **G3** | Distinct copy for disabled account / no membership / validation / rate limit | "Something went wrong" for all of them hides an actionable state (e.g. "ask your admin to activate you") | Codes exist and are mapped to `genericError` | ARB keys for these states — and this wave is **ARB-neutral** by Gate 0 decision | None | Generic copy. Recorded as a follow-up that needs new l10n keys (and therefore a new ARB owner window) |
| **G4** | Know whether the 2FA state is real for technicians | The design must not spend a hero moment on an unreachable state | Login challenges only when `ADMIN_TOTP_REQUIRED=true` **and** the user has TOTP enabled (`AuthService.java:97`); enrollment is restricted to workshop/platform admins (`AuthController.java:47-67`); default is `false` (`application.yml:80-81`) | A technician path to enroll; a confirmed production value of `ADMIN_TOTP_REQUIRED` | Product: confirm whether technicians ever get 2FA | Preserve the code path (**behaviour**), design it as a calm secondary state, not the signature. **Fix the validator to accept 6 digits or the 11-char recovery code** (`AuthService.java:127-142, 290-300`) |
| **G5** | Role routing that matches the token | Client role = highest-privilege membership (`session.dart:18-32`); token role = primary membership (`AuthService.java:330-340`). A technician who is an admin elsewhere is sent to `/unauthorized`; an admin who is a technician elsewhere reaches the technician app with a token that disagrees | Both derivations | One definition of "the active role" | Preferred: return the resolved role + workshop in `AuthResponse`/`MeResponse` and have the client use it verbatim (the server already resolves it) | **Do not change.** Preserve the current guard. Record as G5; it is a contract finding, not a UI fix |
| **G6** | Fail closed on an unknown role | `Role.fromApi(...) ?? technician` presents an unknown role as a technician while the token keeps the real role → login "succeeds", every API call 403s | `role.dart:10-17, 25` | An explicit unknown/fail-closed branch | None | No change this wave (behaviour preservation). Note it in the brief as a known risk |
| **G7** | Session lifetime and refresh | Access token 15 min (`application.yml:74`), refresh 30 days; `expiresInSeconds` is never parsed and `refresh()` has no callers. Sessions silently die mid-use | Refresh endpoint + repository method exist | Client parsing, pre-emptive refresh, 401 interceptor | None | No change this wave. Record as an auth-layer gap |
| **G8** | Reachable network error state | Three timeout codes are dead because no Dio timeouts are configured; a hung request leaves the button disabled forever | Error copy for 5 transport codes | `connectTimeout`/`sendTimeout`/`receiveTimeout` | None | Keep the copy; do not claim a timeout state until timeouts exist |
| **G9** | Production build points at production | Default base URL is a dev tunnel compiled into every build (`api_config.dart:7-8`); no CI job passes `API_BASE_URL` | Env-based override via `--dart-define-from-file` | A CI/release guard | CI: fail a release build without `API_BASE_URL` | No UI change. Record as release risk |
| **G10** | Role/permissions refreshed on restore | `restore()` calls `/auth/me` and **discards the body**, trusting the stored JSON (stale roles survive) | Endpoint returns `MeResponse(user, memberships)` | Client use of the response | None | No change this wave |
| **G11** | Language choice persists | The locale is memory-only and resets to English on cold start | `locale_controller.dart:9-15` | Persistence | None | No change (would be a behaviour change) |
| **G12** | A real brand mark | The "wordmark" is an empty blurred pill — there is no logo asset in the screen | Product name string only | A brand asset or an approved typographic lockup | None | Use a **typographic lockup** of `appTitle` (no invented logo); record as a design decision in `ui_brief.md` |
| **G13** | Server-localized error detail | The technician app never sets `Accept-Language`/`X-Client`; server `detail`/`errors` would arrive in English | Header plumbing exists in `ApiClient` | App-level assignment | None | Not shown today; low priority |
| **G14** | One error→copy map | The same switch is duplicated in three apps | Three copies | A shared mapping | None | Out of scope; do not refactor shared packages in this wave |

## Gate 1 consequence

No designed number depends on MISSING data — the screen has no numbers. The
only MISSING items are **affordances** (help/reset) and **brand**; the honest
interim is to remove the dead affordances and use a typographic lockup, never
to simulate them.

The two SUSPECT items with a concrete client fix inside this wave are:

1. **G4** — accept the server's 11-char recovery code (validator widening,
   pinned by a test).
2. **G1** — remove the dead "Password help" and de-link "Get help".

Everything else is recorded and deliberately not changed.
