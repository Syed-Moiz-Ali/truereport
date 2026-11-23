# UI/UX Improvements — TrueReport

Priorities: **P0** release blocker · **P1** next sprint · **P2** polish.
Each item names the screen, the observed problem, the user impact, and a concrete change. Visual craft is generally strong; the problems below are correctness, trust and operability issues, not taste.

## P0 — blockers

### 1. Platform app must refuse non-platform roles (Platform sign-in / shell)
- **Observed:** Workshop Admin A signs in successfully, sees Dashboard/Workshops/Checklist/Reports/Audit Log/Settings, then a generic "Something went wrong · Retry".
- **Impact:** Broken privilege boundary; the user believes they have access and retries a call that can never succeed. Support load.
- **Fix:** role check in `platform_router.dart` → `/unauthorized` with role-specific copy and a link to the correct app. On a 403 from any call, show "You do not have platform access", not "Something went wrong".

### 2. Never publish a report whose snapshot belongs to another job (Job detail / publication)
- **Observed:** the Published job `JOB-98D5FD5D` displays/links another report number.
- **Impact:** the product's core artefact is wrong for the customer.
- **Fix:** show the report number in the publication panel, block publish with a mismatch warning, and alert on the invariant.

### 3. Make evidence requirements operable (Technician item / summary)
- **Observed:** every item requires 1 photo **and** 1 video (30 items = 60 captures); the UI only says "Photos" are missing; the API rejects the save.
- **Impact:** a clean inspection is the slowest to complete; technicians attach junk to proceed.
- **Fix:** define evidence rules per result (defects need evidence, "no issue" does not, or photo-only); show every missing requirement, not just the first; allow "not applicable" with a reason.

## P1 — trust and consistency

### 4. Remove fabricated workshop KPIs (Platform → Workshops)
- `Bays 8` and `88%` are model defaults, identical for every tenant. Replace with API values or "—". Do not ship invented numbers in an operational console.

### 5. Align "live languages" with reality (Dashboard / Languages)
- French is LIVE at 0% readiness and absent from client manifests while the dashboard says "All languages live (3)".
- Show "3 registered · 2 delivered", and block LIVE activation below a readiness threshold.

### 6. Fix the template sequence category filters (Workshop → Templates → Sequence)
- Blank oval buttons, no labels, unusable for sighted and screen-reader users. Render the category names and a selected state.

### 7. Fix encoding on template cards (`Â·`)
- Double-encoded UTF-8 in a user-facing list. Decode once at the boundary; add a golden test with `·`, Arabic and emoji.

### 8. Remove test data from production-facing options
- "Live Set 1794471507926" appears in Issue Type. Retire it and add a data-hygiene check for timestamp/`test`/`e2e` values in master content.

### 9. Repair the job table layout (Workshop → Jobs)
- References wrap mid-token and merge with the customer name (`JOB-E7E87034Audit Customer…`); timestamps collide (`11/23/202610:43`).
- Fix column widths, `maxLines: 1` + ellipsis, copy-on-click for references, and a real gap before the date.

### 10. Correct unauthorized copy (both worker apps)
- "Something went wrong / Use your workshop account" on a technician's screen is wrong and unhelpful.
- Use: "This app is for technicians. Your account is a workshop admin — open the Workshop app." with a switch link.

### 11. Make technician navigation URL-addressable
- Workspace/item screens keep `/jobs`; Back does nothing visible; refresh loses the job.
- Use GoRouter navigation; keep the deep links that already work.

### 12. Clarify sign-in identity on the Technician app
- Headline "Use your workshop account." conflicts with the technician-only gate. Say "Sign in with your technician account."

## P2 — polish and accessibility

| Screen | Issue | Change |
|---|---|---|
| Platform sign-in | show-password button has no accessible name | `Semantics(label: 'Show password')` |
| Technician sign-in | button is named "Password" | "Show password" / "Hide password" with state |
| Workshop job detail | duplicate `Report` and `Documents` semantics nodes | one node per action |
| Platform edit dialog | workshop-name field has no label | visible + semantic label |
| Platform workshops | filter chip counts stay 3/3 while search returns 1 | update counts or hide them during search |
| Platform workshop detail (Staff) | "No data yet" under every member | show last active / invited date, or remove |
| Workshop templates | empty published template shown without warning | badge "No items" + block publish |
| Public report | no CSP | add `default-src 'self'; img-src 'self' data:; media-src 'self'` |
| Technician queue (desktop) | phone-width column on 1920 screens with large empty margins | optional two-column/max-width layout for tablets+ |
| Empty states (workshop overview) | three sections use identical "Nothing here right now" | differentiate: "No jobs waiting for approval", "No jobs in the bay", etc. |
| Toast/error vocabulary | "Something went wrong" repeated for 403, network and parse errors | map problem codes to specific copy; always offer the next action |

## What is working well (keep)
- Strong, consistent visual language: green/ink palette, generous spacing, clear hierarchy, rounded controls.
- Workshop overview explicitly states "Every segment is a status count. They sum to 106." — a trust-building pattern; reuse it.
- Job/technician cards surface the reference and plate as the primary identifiers.
- Public report is neutral on failure, `noindex`, `no-referrer`, and masks VIN/customer data.
- Empty states, skeletons and disabled states exist across the three apps.
- RTL and Arabic are supported structurally (localization packages, direction-aware layout).
