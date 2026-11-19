# Rebuild state — technician_app sign-in (dock + full-bleed photo hero)

Path:            **lite** · 2026-11-19
Screen:          `/signin` — technician **dock** with a full-bleed photo hero;
                 workshop/platform use the shared photo-bay
Direction:       **all three: photo + stacked copy + rounded credential
                 container** (technician dock; workshop/platform shared bay)
Canonical spec:  `docs/ui_brief.md` (technician) +
                 `client/packages/auth/docs/shared_signin.md` (workshop/platform)
Current phase:   **CR-6 complete**

## CR-6 (2026-11-19) — technician hero becomes an inspection moment

- The technician hero photo is replaced with a professional technician holding
  the printed inspection report beside the vehicle in a working bay (Pexels
  `6870324`, Gustavo Fring; credited in
  `packages/auth/assets/images/CREDITS.md`). It reads *inspection and report*,
  not generic engine repair.
- Layout, dock, statement, language pill, hints and pill primary are unchanged;
  only `packages/auth/assets/images/signin_hero_technician.jpg` changed.
- Fresh captures: `docs/evidence/signin_inspection_hero/index.html` (1440, 1280,
  390 EN/AR/2FA).

## CR-4 (2026-11-19) — workshop + platform adopt the technician treatment

- `SignInBayView` rewritten: desktop **left photo / right credential panel**
  (the panel overlaps the photo with a 28 px rounded inner edge and a soft
  shadow); phones use the photo on top and a rounded sheet at the bottom. The
  ink inspection surface is no longer mounted; the example visuals are stacked
  on the photo.
- The photo is the same bundled image, moved to
  `packages/auth/assets/images/signin_hero.jpg` (credits there). The technician
  dock now loads it from the auth package.
- Portal copy (label/title/subtitle) is on the photo; the panel holds the
  fields, error, primary and help. The language control sits on the photo in a
  dark pill (workshop EN/AR toggle; platform manifest menu).
- Platform passes its backend email/password hints.
- Workshop's `widget_test` no longer expects the removed ink-surface chassis;
  the example label + tick spine remain pinned.
- Technician is unchanged visually (dock + hero + pill button).

## CR-3 (2026-11-19)

- The technician dock opens with a **full-bleed hero photo**: a technician
  working on an open engine bay (Unsplash `1625047509168-a7026f36de04`,
  downloaded at w=1400/q=70 and bundled; credit in
  `assets/images/CREDITS.md`). The product name/language sit on a top scrim;
  the statement and tagline are stacked over a bottom scrim.
- **Layer:** the credential sheet overlaps the photo with a 28 px rounded top
  and a soft shadow; the photo's bottom edge is hidden behind the sheet
  (no fog, no hard seam). The photo appears to come out of the container.
- **Language selector:** a single dark pill with white EN/AR labels (no nested
  light track), so it is legible and looks like one control.
- **Help/security line** ("Need technician login? Get help" + the security
  caption) moved from above the fields into the sheet footer, below the
  primary.
- **Field hints** added: `name@workshop.com` and `Enter your password`
  (new ARB keys `technicianEmailHint`, `technicianPasswordHint`; AR too).
- **Primary** is a full pill (radius = half its height); the fields keep their
  12 px rounding.
- The hero is the full area above the dock; at 1.5×/2× the page scrolls and the
  hero keeps a fixed height so the form stays reachable.
- Workshop and platform remain on the shared bay (`SignInBayView`); the auth
  package still exports it.
- `AdminSignInView` stays deleted (platform dead view; the i18n `SignInCopy`
  offender is gone).

## Measured result (CR-3)

- technician: **264 pass / 18 fail** — the same 18 baseline failures (14
  non-login goldens, `f2b_a11y`, ARB placeholder scan B4, dates, empty-state
  copy-fit). Login goldens regenerated with the photo hero. Log:
  `docs/evidence/logs/cr3_technician_test.txt`.
- workshop sign-in: 53/53; platform login: 9/9 (logs from CR-1 still apply; the
  shared bay was unchanged by CR-3).
- analyzers: auth 0, technician 0, platform 0. Workspace red only for the
  untracked preview files of concurrent waves.

## Evidence

- `docs/evidence/signin_dock_v2/` — 16 dock captures + `index.html` (1440, 1280,
  1024, 768, 600, 390 EN/AR/error/2FA/keyboard, 360 EN/1.5× AR/2×, 1280 1.5×).
- `docs/evidence/signin_bay/` — CR-1 bay evidence, historical (technician no
  longer uses it); `docs/evidence/signin_platform/` — platform bay.
- `packages/auth/docs/shared_signin.md` — the bay for workshop/platform.

## Gates

0 PASS(user) · 1 PASS(self) · 3 PASS(user, dock) · 4-lite PASS(self) ·
5 PASS(user, dock) · 6 PASS(dock, independent r2) · CR-1 PASS WITH FIXES
(independent) · **CR-2 implemented (owner request; same dock, one image added)**.

## Next allowed action

Ship. A live-device spot-check remains optional (W-SIGNIN-WEB).


## Measured result (CR-4)

- technician: **264 pass / 18 fail** (same baseline).
- workshop sign-in: **53 pass** (7 files).
- platform login: **9 pass**; the full platform app keeps its one external preview-file failure.
- analyzers: auth 0, technician 0, workshop 0, platform 0.
- captures: platform docs/evidence/signin_platform/; shared index docs/evidence/signin_admin_shared/index.html.

## Measured result (CR-5)

- New admin image (premium garage, Unsplash 1492144534655) + example changed to the Camaro ZL1 to match it.
- Shared bay: compact floating credential card (no empty full-height panel), hints on workshop + platform fields, pill primary.
- technician: **264 pass / 18 fail** (same baseline).
- platform login: **9 pass**; full platform app keeps its one external preview-file failure.
- workshop: sign-in page analyzes 0; new smoke/capture 	est/signin_cr5_smoke_test.dart passes. The app-wide sign-in suite is blocked by 18 external staff-file compile errors from the concurrent wave.
- captures: docs/evidence/signin_admin_shared/ (workshop + platform).

## Measured result (CR-6)

- technician suite: **264 pass / 18 fail** (same baseline; the two login goldens were regenerated for the new hero).
- sign-in behaviour + gallery: **24 pass**; analyzer 0.
- captures: `docs/evidence/signin/` (all states) and `docs/evidence/signin_inspection_hero/index.html`.
- workshop/platform are untouched by this change (they use `signin_hero_admin.jpg`).
