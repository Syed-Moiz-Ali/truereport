# CR-1 QA checklist — shared sign-in bay (technician · workshop · platform)

Reviewer: independent. Grade from the captures, the shared spec and the test
logs. Do not take the builder's prose as evidence.

## What changed

- The workshop's split "bay" moved from `apps/workshop_admin_app/.../auth/signin/`
  into `packages/auth/lib/src/signin/` and is now `SignInBayView`.
- **Technician** `/signin` renders the bay (the approved dock is retired; its
  view + 8 widgets + tokens are deleted).
- **Platform** `/signin` renders the bay (the legacy `AdminSignInView` is deleted).
- **Workshop** renders the same bay from the shared package; its sign-in tests
  pass unchanged.
- Per-app copy via `SignInBayCopy`; 2FA on technician/platform; workshop keeps
  its no-code rule; platform keeps its backend language menu.

## Evidence

| App | Captures | Tests |
|---|---|---|
| Technician | `apps/technician_app/docs/evidence/signin_bay/` (1440, 1280 EN/AR/1.5×, 1024, 768, 600, 390 EN/AR/error/2FA/submitting/keyboard, 360 EN/1.5× AR/2×) | `test/features/auth/signin/`, router guard, copy-fit, geometry: **260 pass / 18 fail** (14 non-login goldens, a11y, ARB B4, dates, empty-state copy-fit; `SignInCopy` B3 fixed) — log `docs/evidence/logs/cr1_technician_test.txt` |
| Platform | `apps/technician_app/docs/evidence/signin_platform/` (1440, 1280, 390 EN, 390 AR) | `test/platform_login_test.dart`: 9 pass; full app **242 pass / 1 skip / 1 fail** — the failure is the untracked `lib/preview/dashboard_directions_preview.dart` policy hit from a concurrent wave, not sign-in — log `cr1_platform_test.txt` |
| Workshop | its existing `docs/evidence/signin/` state captures | 7 sign-in test files: **53 pass** — log `cr1_workshop_signin_test.txt` |

Analyzer: auth 0, technician 0, platform 0. Workspace-wide red only for the
documented untracked preview files from other waves.

## Checklist

1. **Same composition in all three:** 46/54 split with the right inspection
   surface at desktop; identity band below 900. Compare the technician 1440,
   platform 1440 and the workshop's existing 1440 capture.
2. **The right-side visual is the workshop one:** ink grid, top-down chassis,
   `EXAMPLE JOB`, `2023 Porsche 911 GT3`, plate/customer, 18/24 ticks, technician
   row. It is labelled as an example; no fabricated tenant data.
3. **Per-portal copy:** TECHNICIAN / WORKSHOP ADMIN / PLATFORM ADMINISTRATION;
   the title and subtitle differ appropriately; the form/visual do not.
4. **Behaviour preserved per app:** workshop no code UI; technician and platform
   2FA; recovery code accepted on both; error copy mapped; no PII logging;
   double-submit guard; platform navigates to `/workshops`.
5. **RTL + language:** Arabic mirrors the band and split; inputs stay LTR;
   technician/workshop EN/AR toggle; platform language menu lists the manifest.
6. **States:** default, focus, validation, auth error, submitting, 2FA, RTL,
   1.5×/2×, keyboard-up (390×500 + inset test), 390/360.
7. **No regressions:** workshop sign-in suite 53/53; technician only the 19
   baseline failures; platform only the external preview failure; the shared
   bay has no new render exception.
8. **Kill list:** technician dock files, platform `AdminSignInView`, workshop
   local `signin/` folder deleted; no imports remain.
9. **No new copy hardcoded:** all product strings come from `SignInBayCopy`; the
   bay's structural labels come from the shared ARB; platform lib still has no
   `AppLocalizations` usage.

## Known limits (judge, do not auto-fail)

- Platform's language menu needs the backend manifest; the capture without a
  manifest has no menu (the control renders nothing rather than crashing).
- A platform language with no ARB translation (e.g. zh-hans) shows the example
  labels in English.
- The shared field primitive exposes no focus node, so "focus the first invalid
  field" is not implemented; errors are inline and announced (matching the
  workshop screen).
- The workspace-wide analyzer is red for untracked preview files of concurrent
  waves.

## Verdict

Write **PASS / PASS WITH FIXES / FAIL** with blockers/majors/minors and evidence.
A restyle is not possible here (the composition is the workshop's); the real
blockers would be: different layouts between apps, lost workshop pixels, a
missing 2FA/challenge state, a new render exception, or a behaviour regression.

