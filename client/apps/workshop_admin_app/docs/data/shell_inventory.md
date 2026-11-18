# Data inventory — app shell (Phase 1, investigate-only)

The shell displays no metric, no count and no date. It is entirely identity and
navigation, which makes this phase short and every element verifiable.

| # | Element | Source | Definition | Status |
|---|---|---|---|---|
| 1 | Workshop name | `session.memberships.first.workshopName` (`workshop_admin_home.dart:66-68`) | the caller's first membership; falls back to `workshopAdminTitle` when there is no session | **VERIFIED** |
| 2 | Account name | `session.user.displayName`, else `roleWorkshopAdmin` | — | **VERIFIED** |
| 3 | Account email | `session.user.email` | — | **VERIFIED** |
| 4 | Initials | first letters of the first two name tokens (`_initials`) | — | **VERIFIED** |
| 5 | Section label | `destinations[selectedIndex].label` (l10n) | derived from the selected index | **VERIFIED** |
| 6 | Six destinations | `workshop_admin_home.dart:73-110`, fixed order | index 0–5 contract (K1) | **VERIFIED** |
| 7 | Language control | `localeProvider`; label is the *other* language (`languageEnglish` / `languageArabic`) | — | **VERIFIED** |
| 8 | Sign out | `authControllerProvider.notifier.signOut()` | — | **VERIFIED** |
| 9 | Notification entry | opens `WorkshopNotificationsPage` | no unread count anywhere | **VERIFIED** (no badge — do not invent one) |
| 10 | Unread count badge | — | no count endpoint in scope | **MISSING** — the rebuild must not add a badge |
| 11 | Global search | the jobs API supports `search` | not present in the shell today | **ASSUMED** (available, would need a destination for results) |
| 12 | Tenant / role | session membership role | not displayed anywhere on the shell | **VERIFIED** (out of scope) |

## Gate 1 self-grade

- 12 elements: 10 VERIFIED, 1 ASSUMED, 0 SUSPECT, 1 MISSING (the unread badge).
- The MISSING element is *explicitly excluded*: no notification badge may be
  added, because there is no count to put in it.
- Search (row 11) is available as an API capability but has no results surface in
  the shell's scope. A direction may propose it **only** if it routes to the jobs
  tab with the query applied — otherwise it is a dead control and must be dropped.
- **PASS (self).**
