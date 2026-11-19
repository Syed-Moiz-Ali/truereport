# CR-1 verdict — shared sign-in bay

**Verdict: PASS WITH FIXES** (independent review, 2026-11-19). No blocker.
Two majors, six minors; all addressed below.

| # | Item | Grade | Evidence |
|---|---|---|---|
| 1 | One composition | **PASS** | technician `signin_1440_en.png`, platform `platform_1440_en.png`, workshop `states/signin_default_1440_en.png` are the same 46/54 bay; phones share the 132 px band |
| 2 | Workshop visual | **PASS** | ink grid, top-down chassis, EXAMPLE JOB, 911 GT3, DXB 48291/Rashid, technician row, 18/24 = 75% (`signin_example.dart:12-19`); no tenant data |
| 3 | Per-portal copy | **PASS** | TECHNICIAN / WORKSHOP ADMIN / PLATFORM ADMINISTRATION; platform strings from the backend (`en.json`); form/visual identical |
| 4 | Behaviour | **PASS** | workshop no code cell and explains a challenge; technician/platform code regex 6-digit/`XXXXX-XXXXX`; double-submit guard; no PII logging; `/workshops`; platform lib has no `AppLocalizations` (delegates from auth) |
| 5 | States/RTL/a11y | **PASS with minors** | focus ring, live-region error, RTL, 1.5×/2×; "inputs stay LTR" was false (documented) |
| 6 | No regressions | **PASS after fix** | see M1 |
| 7 | Kill list | **PASS** | no dock, `AdminSignInView` or workshop `signin/` files; no imports remain |
| 8 | Known limits | **PASS** | `packages/auth/docs/shared_signin.md` |

## Majors — fixed

- **M1 evidence count.** The CR-1 logs now exist:
  `docs/evidence/logs/cr1_technician_test.txt` (**260 pass / 18 fail**),
  `cr1_platform_test.txt` (242 pass / 1 skip / 1 fail — the untracked
  `lib/preview/dashboard_directions_preview.dart` policy hit),
  `cr1_workshop_signin_test.txt` (**53 pass**). The 18 are:
  14 pre-existing non-login goldens, `f2b_a11y`, the ARB placeholder scan (B4),
  `intl_dates_tech`, and the empty-state copy-fit case. The two login goldens
  were regenerated for the bay and **pass**; `SignInCopy` (B3) is gone with the
  dead `AdminSignInView`, hence 18 not 19. The state and checklist agree.
- **M2 trust claim.** Platform's help line was the backend footer
  "256-bit TLS Encrypted · SOC-2 Certified". It now uses
  `PlatformAdminKeys.loginNeedHelp` ("Need help?"); the claim is no longer shown
  on the door. Capture regenerated (`platform_1440_en.png`).

## Minors — addressed

1. Stale dock PNGs removed from `signin_bay/` (the folder now holds only bay
   captures + index + checklist + this verdict).
2. Arabic inputs: documented, not changed — `WorkshopTextField` exposes no
   `textDirection`; Latin text still renders LTR by bidi, while the caret and
   alignment follow the page direction. Accepted shared-primitive limit.
3. 2FA recovery-code hint: documented (the field accepts `XXXXX-XXXXX`; no
   explanatory copy exists in the shared ARB).
4. Malformed code uses `requiredField` copy: documented (no "invalid code" key).
5. Submitting state captured (`signin_390_submitting.png`); the platform loading
   label is its button label, announced only (spinner is visual).
6. Band chassis: resized to 36 px and anchored bottom-right, so it neither clips
   at the 132 px band nor collides with the language control.

## Closing

No blocker or major remains. The two documented input/copy limits are inherited
from the shared field primitive and the copy set; they are visible in the
canonical spec, not hidden. **CR-1 closes.**
