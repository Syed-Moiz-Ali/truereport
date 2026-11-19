# Rebuild state — technician_app sign-in (dock + full-bleed photo hero)

Path:            **lite** · 2026-11-19
Screen:          `/signin` — technician **dock** with a full-bleed photo hero;
                 workshop/platform stay on the shared bay
Direction:       **technician: the dock** (owner: "revert to previous, it was
                 good") + a real workshop photo hero + field hints
Canonical spec:  `docs/ui_brief.md` (dock) + `client/packages/auth/docs/shared_signin.md`
                 (the bay, now workshop/platform only)
Current phase:   **CR-3 complete**

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

