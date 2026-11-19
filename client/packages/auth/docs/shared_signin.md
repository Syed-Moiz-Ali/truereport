# Shared sign-in — "The bay" (workshop · platform)

> **CR-3 (2026-11-19): the technician app keeps its own dock**, now with a
> full-bleed workshop photo hero and field hints. This bay is used by
> **workshop and platform only**; the technician rows and evidence below are the
> CR-1 record.

Status: implemented 2026-11-19. Canonical spec for the shared sign-in used by
workshop and platform.

## Why

The apps had different sign-ins: the workshop's split "bay", the technician's
bottom dock, and the platform's `AdminSignInView` showcase. The owner asked for
the workshop bay in platform, then later restored the technician dock (CR-2).
The bay lives once in `packages/auth` so workshop and platform cannot drift.

## Composition

`SignInBayView` (`packages/auth/lib/src/signin/signin_bay_view.dart`):

- **≥ 800 px (≥ 1100 at 1.5× text):** a photo on the left and a **compact
  floating credential card** on the right (content-sized, 28 px radius, soft
  shadow), vertically centred. The photo carries the brand/language on top and,
  at the bottom, the portal eyebrow, title, subtitle and the labelled example
  visuals (example job, vehicle, checklist progress, tick spine).
- **< 800 px:** the same photo on top and a rounded credential sheet at the
  bottom, overlapping by 20 px.
- The photo is the bundled admin image (`packages/auth/assets/images/
  signin_hero_admin.jpg`, credited in `assets/images/CREDITS.md`); the
  technician app uses its own `signin_hero_technician.jpg`.
- The language control sits on the photo in a dark pill; each app supplies it
  (EN/AR toggle or the platform manifest menu).
- Fields carry hints (`name@workshop.com`, `Enter your password`); the primary
  is a full pill.
- The example job is a **2023 Chevrolet Camaro ZL1**, matching the photo; it is
  explicitly labelled and never presented as the user's data.

## Copy model

`SignInBayCopy` carries every product string: portal label, title, subtitle,
help, email/password/code labels, sign-in/verify labels, loading label, app name.
The bay also uses the shared ARB for its structural labels (example job,
show/hide password); `signInBayLocalizationsDelegates` exposes those delegates
without forcing Platform Admin to import `AppLocalizations` in its own lib.

| App | portalLabel | title | subtitle | help | 2FA | language control |
|---|---|---|---|---|---|---|
| Workshop | `signInPortalLabel` ("Workshop Admin") | `signInTitle` | `signInSubtitle` | `signInHelp` | **No code UI** (source scan forbids TOTP; a challenge shows `twoFactorRequired`) | EN/AR toggle |
| Platform | backend `login.portalBadge` | `login.signInTitle` | `login.signInSubtitle` | `login.needHelp` | Code cell; 6-digit or recovery code | backend manifest menu (any language) |
| Technician | — | — | — | — | — | **Not this bay.** Technician uses its own dock (CR-2) |

## Behaviour ownership

Each page owns its AuthController calls, validation, error mapping, challenge
token, locale/language switching and navigation:

- Workshop: `apps/workshop_admin_app/lib/src/features/auth/workshop_login_page.dart`
- Technician: `apps/technician_app/lib/src/features/auth/signin/technician_sign_in_page.dart`
- Platform: `apps/platform_admin_app/lib/src/features/auth/platform_login_page.dart`

The bay is presentational only.

## What moved / what was deleted

| Moved to `packages/auth/lib/src/signin/` | Deleted |
|---|---|
| `signin_bay_view`, `signin_copy`, `signin_form`, `signin_identity_band`, `signin_inspection_surface`, `signin_language_toggle`, `signin_localizations`, `signin_mark`, `signin_primitives`, `signin_submit_button`, `signin_example` | The platform's `AdminSignInView` (dead after migration) and the workshop's local `features/auth/signin/` folder |

**CR-3:** the technician's dock (`technician_sign_in_view` + 8 dock widgets +
`signin_tokens`) is **not** part of this bay. It now opens with a full-bleed
workshop photo hero and hint fields.

`flutter_svg` was added to `packages/auth` for the chassis drawing.

## Tests and evidence

| App | Sign-in tests | Result |
|---|---|---|
| Workshop | 7 files (characterization, a11y, behaviour fixes, primitives gallery, state captures, smoke capture, widget) | **53 pass** |
| Platform | `test/platform_login_test.dart` (9, incl. language manifest and captures) | **9 pass; full app 242 pass / 1 external preview-file policy failure** |
| Technician | its own dock suite (`test/features/auth/signin/`, router, copy-fit, geometry) | **264 pass / 18 baseline failures** (CR-2) |

Captures (real bundled fonts):

- Platform bay: `apps/technician_app/docs/evidence/signin_platform/`
- Workshop: its existing `docs/evidence/signin/` captures (state capture test passes).
- CR-1 technician bay (historical): `apps/technician_app/docs/evidence/signin_bay/`
- CR-2 technician dock: `apps/technician_app/docs/evidence/signin_dock_v2/`

## Known limits

- Platform's language menu needs the backend manifest; until it loads, the
  control renders nothing (graceful, no crash).
- The example labels come from the shared ARB (EN/AR). A platform language with
  no ARB translation (e.g. zh-hans) shows the example labels in English.
- The workshop's `source_scan_test` forbids TOTP UI in that app; the shared form
  only renders the code cell when a page sets `challenge`.
- The field primitive (`WorkshopTextField`) does not expose its focus node or a
  `textDirection`, so "focus the first invalid field" is not implemented, and
  Arabic inputs follow the page direction (Latin values still render LTR by
  bidi; the caret/alignment follows RTL). Errors are inline and announced.
- The 2FA cell accepts the 11-character recovery code but has no explanatory
  hint; a malformed code uses the shared `requiredField` copy. Both need new
  copy that the current ARB does not have.
- The band chassis is a small (36 px) mark at 600–899 px; the full drawing is
  the right-side surface at ≥ 900 px.
- Platform's help slot uses the backend `login.needHelp` ("Need help?") rather
  than the old certification footer; the claim stays out of the door.
