# UI brief ΓÇö Workshop Admin sign-in ┬╖ direction B "The bay"

Phase 3 spec for the **chosen** direction. Gate 3 approved by the user on
2026-11-18 against the renders in `docs/evidence/directions/b-bay-*.png`.
This document supersedes the previous split-panel spec, which was rejected as a
restyle at Gate 6.

## Assumptions

1. Primary user: a workshop owner/admin in the UAE, opening this screen as the
   first action of the day ΓÇö desktop in the office, phone in the bay. Bilingual
   EN/AR; Arabic is first-class.
2. The screen's only job is getting in. No signup, no reset, no SSO, no TOTP
   entry (`source_scan_test` forbids TOTP UI).
3. Accounts are provisioned by a platform administrator, so the help line is
   honest and no "forgot password" affordance is offered.
4. Technicians use another app; a technician who lands here is told, not bounced
   silently.

## The feeling

**You are already at the workshop door, and you can see the work through it.**
The right half of the screen is not a poster about inspections ΓÇö it is an
inspection: one labelled example job, its vehicle drawn top-down, its checklist
as 24 physical ticks. The left half is the door: two fields, one action.

Reference energy: an instrument panel in a clean bay ΓÇö precise, dark, legible,
nothing decorative.

## Anti-goals

- No marketing panel, no "trusted by", no badges, no security claims.
- No gradient, no glass, no stock photography, no illustration blob.
- No card floating on a coloured slab (the rejected pattern).
- No fake product chrome: no disabled nav, no fake tabs, no counters presented
  as live data.
- No second primary action; "Sign in" is the only filled control.
- No English leaking into the Arabic build.
- No elevation: the ink surface is flat, the form sits directly on canvas.

## The signature: "The bay window"

The 54 % ink surface carries **one labelled example job, mid-inspection**:

- eyebrow `EXAMPLE JOB` with a 6 px dot,
- `2023 Porsche 911 GT3` at 30/38,
- `DXB 48291 ┬╖ Rashid Al Mansoori` at meta scale,
- the real top-down chassis drawing (`Minimalist_SVG_Top-Down_Car_Chassis`),
  tinted `onAccent @ 26 %`, never mirrored in RTL,
- `Inspection checklist` + `18 of 24 items ┬╖ 75 %`,
- a 24-tick spine, 18 filled,
- technician row: avatar, name, role, `Started 45 min ago`.

Everything is labelled as an example and announced as an example to assistive
technology. It is evidence of what the product does, never a claim about the
user's data.

Motion: on first paint the 24 ticks fill left-to-right, one per 12 ms
(Γëê400 ms total, `easeOutCubic`), and the form fades up 8 px over 180 ms. Zero
duration under `disableAnimations`. Nothing loops.

## Information architecture

```
/signin ΓöÇΓöÇsubmitΓöÇΓöÇΓû╢ /workshop      (role = workshop admin)
        Γö£ΓöÇchallengeΓöÇΓû╢ stay, 2FA message (no code field)
        Γö£ΓöÇfailureΓöÇΓöÇΓöÇΓû╢ stay, inline banner
        ΓööΓöÇother roleΓöÇΓû╢ /unauthorized (router decides)
```

One route, no navigation, three exits. Language toggle is the only escape
hatch.

## Flow (2 steps, 2 fields)

1. **Recognise** ΓÇö mark + "Sign in" + "Use your workshop account." + the example
   inspection (0 taps).
2. **Authenticate** ΓÇö email, password, Sign in (1 primary tap; Enter submits from
   the password field; eye toggle is local and never submits).

## Layout per breakpoint

**ΓëÑ 1000 px ΓÇö 46 / 54 split, no gap, both edges bleed**

```
ΓöîΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓö¼ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÉ
Γöé [TR] TrueReport             Γöé ΓùÅ EXAMPLE JOB                  Γöé
Γöé                             Γöé 2023 Porsche 911 GT3           Γöé
Γöé  (96 px)                    Γöé DXB 48291 ┬╖ Rashid Al Mansoori Γöé
Γöé  WORKSHOP ADMIN             Γöé                                Γöé
Γöé  Sign in                    Γöé        Γò¡ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓò«         Γöé
Γöé  Use your workshop account. Γöé        Γöé  chassis    Γöé         Γöé
Γöé                             Γöé        Γöé  drawing    Γöé         Γöé
Γöé  Email                      Γöé        Γò░ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓò»         Γöé
Γöé  [____________________]     Γöé                                Γöé
Γöé  Password                   Γöé  Inspection checklist   18/24  Γöé
Γöé  [_______________ ≡ƒæü]       Γöé  Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû«Γû»Γû»Γû»Γû»Γû»Γû»       Γöé
Γöé  [      Sign in      ]      Γöé  KA Karim Ahmed ┬╖ Lead tech    Γöé
Γöé  Contact your adminΓÇª        Γöé                Started 45m ago Γöé
ΓööΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓö┤ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÿ
   gutter 88 (ΓëÑ1200) / 64, form column 372, car 340, 96 from the end edge
```

**900ΓÇô999 px** ΓÇö same split, gutter 48, car 260, form 340.

**< 900 px ΓÇö the surface collapses to an identity band**

```
ΓöîΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÉ
Γöé [TR] TrueReport  ≡ƒîÉ  Γöé ink band 132 px
Γöé EXAMPLE JOB   (car)  Γöé car 60 wide, 18 from the end edge
Γöé 2023 Porsche 911 GT3 Γöé
Γö£ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöñ
Γöé WORKSHOP ADMIN       Γöé canvas
Γöé Sign in              Γöé
Γöé Use your workshopΓÇª   Γöé
Γöé Email                Γöé
Γöé [__________________] Γöé
Γöé Password             Γöé
Γöé [______________ ≡ƒæü] Γöé
Γöé [     Sign in     ]  Γöé
Γöé Contact your adminΓÇª  Γöé
ΓööΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÿ
   gutters 16; content starts 24 px under the band
```

Why the band and not nothing: the phone user still needs to know this is the
workshop tool, not a generic admin login ΓÇö at the cost of 132 px, which still
leaves the first field visible without scrolling at 360 ├ù 800.

## Type (existing tokens only)

| Element | Token | Note |
|---|---|---|
| Page title (`Sign in`) | `ws.heroNumber` 40 / 44 w700 | the only display-scale text |
| Example vehicle | `ws.pageTitle` 30 / 38 | on ink, `onAccent` |
| Eyebrow (`WORKSHOP ADMIN`, `EXAMPLE JOB`) | `ws.eyebrow` 11 / 16 w600, tracking 1.4 | mono-spaced feel via tracking |
| Body / subtitle | `ws.body` 14 / 21 | muted on canvas, 72 % white on ink |
| Field label | `ws.bodyStrong` | from `WorkshopTextField` |
| Meta (plate, customer, technician) | `ws.meta` 12.5 / 18 | tabular figures for numbers |
| Progress figure | `ws.sectionTitle` 19 / 26 w700 | tabular figures |

No new type sizes; Arabic tracking is already zeroed by the token factory.

## Colour (existing tokens only)

| Role | Token | Use |
|---|---|---|
| Canvas | `ws.canvas` | form side |
| Surface | `ws.surface` | fields only |
| Ink | `ws.ink` | the inspection surface, headings |
| Muted | `ws.muted` | labels, help, meta |
| Border | `ws.border` | hairlines, field outline |
| Accent | `ws.accent` | eyebrow, primary button |
| On accent | `ws.onAccent` | the 18 filled ticks (white on ink) |
| On accent | `ws.onAccent` | all text and the drawing on ink |
| Danger | `ws.danger` / `dangerSoft` | error banner only |

Accent appears exactly **two** ways on the door: the eyebrow and the primary
button. On the ink surface the ticks are `onAccent` white ΓÇö a green tick on ink
would fail contrast and read as decoration.

## States (every one specified)

| State | Behaviour |
|---|---|
| **Default** | Email autofocused on ΓëÑ 900 px only. Tab order: email ΓåÆ password ΓåÆ eye ΓåÆ submit ΓåÆ language. |
| **Focused** | 2 px accent ring + focus halo, as `WorkshopTextField` does today. |
| **Filled** | Values persist through failures; nothing re-formats. |
| **Validation error** | Inline below the field on submit, `ws.meta` in `ws.danger`; focus moves to the first invalid field. Message-only (no red outline) ΓÇö accepted limitation of `WorkshopTextField`, documented in `docs/visual_language.md`. |
| **Submitting** | Button spinner, label hidden, disabled, `Semantics(busy: true)`; second tap impossible. The ink surface does not change. |
| **Auth error** | Banner above the button on the canvas: `dangerSoft`, `error_outline`, `liveRegion`; password keeps focus for retry; email preserved. |
| **Network error** | Same banner, network copy. No offline claim. |
| **2FA required** | Same banner, 2FA copy, no code field, Sign in stays enabled. |
| **Success** | No flash. The button resolves and the router replaces the route. |
| **Locale switch** | Rebuilds in place; typed values persist; the split mirrors; the drawing does not. |
| **Text scale 200 %** | Everything wraps; at ΓëÑ 1.5├ù the split falls back to the band layout below 1100 px so nothing clips. |
| **RTL (ar)** | Surface on the left, form on the right; annotations and rows mirror; chassis, plate, model and all numbers stay LTR. |
| **Reduced motion** | Ticks already filled, no fade. |

## Microcopy

Reuse existing `l10n` keys only. No new English strings except what already
exists for the example job: `signInExampleLabel`, `signInExampleChecklist`,
`signInExampleProgress`, `signInExampleStarted`, `roleLeadTechnician`,
`signInPortalLabel`, `signInTitle`, `signInSubtitle`, `signInHelp`,
`emailLabel`, `passwordLabel`, `signInButton`, `invalidCredentials`,
`networkError`, `twoFactorRequired`, `genericError`, `requiredField`,
`invalidEmail`.

`signInHeadline` and `signInBrandLine` are no longer rendered by this screen.
They stay in the ARB for other surfaces; do not delete them.

## Accessibility

- Labels are visible above fields; placeholders carry no meaning.
- Contrast: `onAccent @ 72 %` on `ink` ΓëÑ 4.6:1; `muted` on `canvas` ΓëÑ 4.6:1;
  accent on canvas for the 11 px eyebrow ΓëÑ 4.5:1 (verify at Gate 6).
- The inspection surface is one `Semantics` container labelled
  "Example inspection: 2023 Porsche 911 GT3, 18 of 24 items, 75 percent" and is
  not exposed as the user's data. The chassis drawing itself is excluded.
- The banner is a `liveRegion`; focus does not move on an auth failure.
- Touch targets ΓëÑ 44 px; the eye toggle and language toggle included.
- Every interactive element has a visible focus ring.

## Structural departures (non-empty, required by Gate 6)

1. The 50/50 split is gone: 46/54, form flush-left and top-weighted, surface
   full-bleed with no radius.
2. The white example-job **card** is deleted. Its data moves into the ink
   surface as six flat elements plus a 24-tick spine.
3. The progress **bar** is deleted in favour of the tick spine.
4. The brand slab with a headline is deleted; the surface now carries the product
   drawing instead of a promise.
5. On phone the surface is **not dropped**: it collapses to an ink identity band
   instead of disappearing.
6. The page is split into region widgets (band, surface, form, lockup, toggle)
   instead of one 633-line file.

## Acceptance checklist

1. 1440 / 1280 / 1024 / 768 / 390 / 360 EN and 1280 AR: no clipping, no
   horizontal scroll, no `RenderFlex overflowed`.
2. At 360 the first field is visible without scrolling.
3. At 200 % text scale: readable, submit reachable, no overflow.
4. AR: zero English except the wordmark and the language label; chassis, plate,
   model and counts render LTR and in order.
5. Every string from `l10n` except the wordmark and the example proper nouns
   (approved at Gate 0).
6. A1ΓÇôA3 stay green; the screen adds no allowlist entries.
7. Error, submitting, validation and 2FA states each have a test **and** a Phase
   6 capture.
8. The example job is visibly labelled and announced as an example.
9. Keyboard-only: Tab reaches email ΓåÆ password ΓåÆ eye ΓåÆ submit ΓåÆ language; Enter
   submits from the password field.
10. Reduced motion: no fill animation.

## Risks

1. **The chassis SVG is a Figma export with baked colours** (`#C7C5D3`,
   `#10B981`). It is rendered through a `srcIn` colour filter so only the
   silhouette survives; the raw greys must never leak. Verify on the AR and 1├ù
   captures.
2. **RTL mirroring.** The drawing must be pinned LTR; a mirrored car is a
   credibility bug.
3. **Asset weight.** The SVG is 2.8 kB ΓÇö no budget concern, but it must be
   declared in the design-system asset manifest.
4. **The ink surface is the identity.** Softening it (radius, lighter fill,
   removing the drawing) turns the screen back into the rejected pattern.

---

## CR-4 (2026-11-19): replaced by the shared photo bay

The ink inspection surface described above is no longer mounted. Workshop Admin now renders the shared SignInBayView: left photo with the portal copy and example visuals stacked, right rounded credential panel overlapping it; phones use the photo on top and a rounded sheet. Canonical spec: client/packages/auth/docs/shared_signin.md.
