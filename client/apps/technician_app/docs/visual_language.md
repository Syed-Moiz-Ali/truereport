# Visual language — technician sign-in · "The dock"

> **CR-3 (2026-11-19): the dock opens with a full-bleed workshop photo**; the
> credential sheet overlaps it with rounded corners and a soft shadow, the
> language switch is one dark pill, the help/security line sits in the sheet
> footer, the fields have hints, and the primary is a full pill. The shared bay
> remains for workshop/platform (`packages/auth/docs/shared_signin.md`).

Committed at Gate 5. The direction is **C "The dock"** (Gate 3, user, 2026-11-19);
this document fixes the tokens and primitives the screen is built from. No
direction changes after this file.

## 1. The idea, committed

**The whole form is a band docked to the bottom edge; the canvas above it states
the job and then gets out of the way.**

Three rules make it recognisable, and all three are non-negotiable:

1. **The band touches the bottom edge** at every size. It is not a card, not a
   floating sheet, and its top corners never round.
2. **The canvas is empty except one statement and one tagline.** It is not a
   place to add illustrations, stats, badges or "example jobs".
3. **One accent, twice at most** — the primary block and a focused field edge.
   Everything else is ink, muted grey and hairlines.

## 2. Type

One family: Plus Jakarta Sans, with Noto Sans Arabic as the Arabic fallback
(both bundled; no runtime fetch). Arabic tracking is always 0.

| Role | Size / line / weight | Where |
|---|---|---|
| Statement (desktop) | 60 / 64 / w800, tracking −1.8 | canvas, ≥ 900 px |
| Statement (phone) | 34 / 39 / w800, tracking −0.9 | canvas, < 900 px |
| Statement (≥ 1.5× text) | 44 / 48 (desktop), 26 / 30 (phone) | keeps words whole |
| Tagline | 16 / 24 / w400 (desktop), 15 / 22 (phone) | under the statement |
| Product name | 16 / 22 / w800 (desktop), 15 / 20 (phone) | command strip |
| Field label | 12 / 16 / w600, tracking +0.24 | above every cell |
| Input | 16 / 24 / w500 | inside the cell, LTR always |
| Primary label | 15 / 20 / w700, tracking −0.1 | on the accent |
| Meta / help / security | 11 / 16 / w600, tracking +0.2 | dock meta row |
| Error | 12 / 16 / w500 | status row and field messages |

Arabic line boxes are ≥ 1.3× the Latin line height (the statement uses 1.38×,
the tagline 26 px at 15 px). Nothing is letter-spaced in Arabic.

## 3. Colour

| Role | Token | Value | Contrast |
|---|---|---|---|
| Canvas | `ColorScheme.surface` | `#FFFFFF` | — |
| Band | `ColorScheme.surfaceContainer` | `#F4F3F8` | — |
| Cell fill | `ColorScheme.surfaceContainerLowest` | `#FFFFFF` | — |
| Hairline | `ColorScheme.outlineVariant` | `#DAD9DF` | structural only |
| Ink | `ColorScheme.onSurface` | `#1A1B1F` | 16.4:1 on canvas |
| Muted | `ColorScheme.onSurfaceVariant` | `#5E5D69` | 6.8:1 |
| Accent | `ColorScheme.primary` | `#006C49` | 5.5:1 with white |
| On accent | `ColorScheme.onPrimary` | `#FDFDFA` | 5.5:1 |
| Error | `ColorScheme.error` | `#A3231F` | 6.6:1 |

The accent is **deep green, not emerald**: white on `Fx.emerald` (`#10B981`) is
≈2.2:1 and fails text contrast. The primary block is the only filled accent on a
resting screen.

No gradients. No glow. No shadows on fields, band or primary. The only elevation
is the band's 1 px top hairline, which separates it from the canvas. The
language pill carries a 1 px shadow; it is the sole exception.

## 4. Space and shape

| Token | Value |
|---|---|
| Grid module | 4 px |
| Gutter | 20 (phone) · 32 (600–899) · 64 (≥ 900) |
| Command strip | 56 (phone) · 72 (desktop) · 112 at ≥ 1.8× text |
| Cell height | min 52 |
| Primary height | 56 |
| Primary width | 300 (horizontal band, ≥ 1024) |
| Cell / primary radius | 12 |
| Language pill radius | full (pill) |
| Label gap | 6 |
| Error row | min 20, may grow to two lines |
| Dock padding | 20/16 phone · 56/44 desktop + safe area |
| Canvas top pad | 40 phone · 64 desktop |

The dock is bottom-anchored: growth from an error or a longer label pushes the
band upward into the canvas, never the primary downward off-screen.

## 5. Motion

| Motion | Spec |
|---|---|
| Band entrance | rise 12 px, 240 ms, `easeOutCubic`, first paint only |
| Reduce motion | duration 0 (no translate) |
| Focus edge | 1 → 1.5 px colour change, 120 ms |
| Loops | none |
| Success | no flash, no toast; the router replaces the route |

## 6. Dark theme

**Not deliverable.** `AppTheme.build` asserts `Brightness.light`; the product is
light-only in this app. A dark gallery would be fiction. Waiver **W-LIGHT** in
`docs/waivers.md` covers the Gate 5 dark evidence requirement (owner: Syed Moiz,
expiry 2027-02-18).

## 7. RTL

- The command strip mirrors: product name at the start (right), language at the
  end (left).
- The dock meta row mirrors; labels right-align; the reveal sits at the visual
  end of the password cell; the primary has no icon to mirror.
- Email, password and code inputs are **LTR in both locales**; their caret and
  content follow LTR. Labels remain in the page direction.
- Numerals are Latin in both locales (no Arabic-Indic digits on this screen).
- Arabic tracking 0; line heights as in §2.

## 8. Primitives (built, tested, gallery-captured)

| Primitive | File | States captured |
|---|---|---|
| `SignInField` | `widgets/signin_field.dart` | idle, focused, invalid, disabled (challenge email), obscured + reveal |
| `SignInPrimary` | `widgets/signin_primary.dart` | default, busy, disabled |
| `SignInLanguageSwitch` | `widgets/signin_language_switch.dart` | LTR selected EN, RTL selected AR, 44 px targets |
| `SignInMetaRow` | `widgets/signin_meta_row.dart` | wide, compact, LTR/RTL |
| `SignInErrorRow` | `widgets/signin_error_row.dart` | empty (reserved), message, LTR/RTL |
| `SignInCommandStrip` | `widgets/signin_command_strip.dart` | one row, two rows at ≥ 1.8× |
| `SignInStatement` | `widgets/signin_statement.dart` | desktop, phone, ≥ 1.5× |
| `SignInDock` | `widgets/signin_dock.dart` | horizontal, two-row, stacked |

The reveal uses Material `visibility_outlined` / `visibility_off_outlined`; the
security line uses the existing design-system shield (`1_7128`). No new image
assets and no invented logo.

## 9. Kill list (final)

| Killed | Why |
|---|---|
| `packages/auth/lib/src/sign_in_view.dart` | Replaced; technician-only copy in a shared package |
| `packages/auth/lib/src/sign_in_page.dart` | Replaced by the app-owned page |
| `packages/auth/lib/src/true_report_app.dart`, `router.dart` | Dead shell that only mounted the deleted screen |
| `auth.dart` exports for the four files above | No consumer remains |
| `_BrandMark` (empty glow), `_Reveal` (24.5×19.25), the `_M` Figma metric set | Deleted with the old view |
| Use of `FxTextField`, `FxButton`, `FxLanguageSwitch` on this screen | Replaced by the dedicated primitives above (the design system keeps them for other screens) |
| "Password help" (dead affordance) | Deleted; key remains in the ARB |
| The link styling on "Get help" | De-linked; it is static text until a channel exists (G1) |
| The login case of `f2a1_geometry_test.dart` (1 px boxes) | Rewritten to structural intent |
| The two login cases of `o2_copy_fit_test.dart` (exact slots) | Rewritten to no-truncation intent |
| `f2a_login_{en,ar}_light.png` goldens | Regenerated deliberately |
| The three direction previews under `test/preview/directions/` | Throwaway; deleted after Gate 3 evidence is committed |

## 10. Anti-patterns (a future change that does these is a regression)

1. Rounding the dock's top corners, adding a shadow, or detaching it from the
   bottom edge.
2. Filling the canvas with a fake workshop, example job, stat, badge, or
   illustration.
3. Adding a second filled button or a second accent.
4. Turning the visible labels back into placeholders.
5. Moving the error into a toast or a dialog, or letting it shift the primary.
6. Adding a dark theme without changing the app-wide light-only decision.
7. Replacing the typographic lockup with an invented logo.
