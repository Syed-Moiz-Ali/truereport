# UI brief — Technician sign-in · direction C "The dock"

Phase 3c spec for the **chosen** direction. Gate 3 approved by the user on
2026-11-19 against `docs/evidence/signin_directions/c/` (renders at 1440 and 390
EN, 390 AR, style tile). This document supersedes the audit's description of the
old screen; the old screen is a requirements document only.

## 1. Assumptions

1. Primary user: a technician in a workshop bay, phone in one hand, possibly
   gloves, bright light, EN or AR. Desktop is rare but must not be a phone
   column in whitespace.
2. Accounts are provisioned by a workshop/platform admin. There is no sign-up,
   no self-service reset, no SSO. The screen must not pretend otherwise.
3. The workshop's identity is **not available before login** — it exists only
   in `memberships[]` after auth. The screen cannot name the workshop.
4. 2FA is effectively unreachable for a pure technician in the default config;
   the state is preserved for behaviour, never promoted.
5. The available copy is fixed (`data_gaps.md` G3): no new ARB keys this wave.

## 2. The feeling

**The app is holding the door open for you.** The page states its job in one
large line, then gets out of the way; the whole form waits at the bottom of the
screen, exactly where a thumb already is. Nothing floats, nothing glows, nothing
is decorated. The calm of the empty canvas is deliberate: it makes the dock the
only thing that can happen.

Reference energy: a service-bay workbench — one clear surface, one drawer that
opens where your hand is.

## 3. Anti-goals

- No marketing panel, no "trusted by", no feature list, no stats.
- No example job, fake workshop name, fake bay, fake user, fake counter.
- No invented logo: the only mark is the product name, typographically set
  (`G12`).
- No gradient, glass, glow, illustration, stock photo.
- No second primary action; language is the only other control.
- No dead affordance: "Password help" is removed; "Get help" is plain text.
- No card floating in the middle of a coloured slab (the rejected pattern).
- No dark surface: the app is light-only (`AppTheme.build` asserts light).
- No new copy. Every string is an existing `AppLocalizations` key.

## 4. The signature: "the dock"

The credential block is a **band docked to the bottom edge of the viewport**, at
every size, with a hairline top edge and the app canvas above it. It holds, in
order: the meta row (access line left, security line right), the email cell, the
password cell, and the primary action. On desktop the same band becomes one
horizontal row across the bottom third: email, password, primary, with the meta
row on its top edge. The band does not float, does not round its top corners
into a card, and never scrolls away from the bottom except when the keyboard
requires it.

The statement above — "Use your workshop account." at display scale, with the
tagline under it — is the **focal point**. The **only primary action** is
`Sign in` (or `Verify` in the challenge state).

A single motion: the band **rises** 12 px over 240 ms with `easeOutCubic` on
first paint; zero under `disableAnimations`. Nothing loops.

## 5. Information architecture

```
/signin ──submit──▶ /jobs              (role = technician)
        ├─challenge─▶ stay, code cell + "Verify"
        ├─failure───▶ stay, error row above the fields (band grows by one row)
        └─other role─▶ /unauthorized    (router decides; not this screen)
```

One route, no navigation, three exits. The language switch is the only other
control. No back button (there is nowhere to go).

## 6. Flow (2 steps, 2 fields)

1. **Recognise** — the statement + tagline + the dock are visible without
   scrolling on a 360 × 800 screen. 0 taps.
2. **Authenticate** — email, password, Sign in. 1 primary tap. Enter on the
   password submits; the reveal toggle is local and never submits; the language
   toggle never submits.

## 7. Layout per breakpoint

### ≥ 1024 px — statement top-left, dock as a horizontal band

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ 48                                                                   48      │
│  TrueReport                                          English │ العربية       │  56 command strip
│  ─────────────────────────────────────────────────────────────────────────── │  hairline
│                                                                              │
│  Use your workshop account.                                                  │  56/64 display
│  Vehicle inspection reports for partner workshops.                           │  16/24 body
│                                                                              │
│                        (canvas — deliberately empty; no invented content)     │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤  dock top hairline
│ Need technician login?  Get help            ◈ Authorised workshop staff only │  20 meta row
│  Email                        Password                                      │  label row
│  ┌──────────────────────┐    ┌──────────────────────┐   ┌──────────────────┐ │
│  │                      │    │                    👁 │   │     Sign in      │ │ 64 cells / 64 bar
│  └──────────────────────┘    └──────────────────────┘   └──────────────────┘ │
│  [error row 28 — reserved, liveRegion, right-aligned under the primary]       │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Statement measure ≤ 720 px; dock inner width ≤ 1200 px, centred.
- Cells: email and password `flex 1` each with 24 px gap; primary fixed 300 px
  at the end; 32 px gap before it.
- Dock padding: 32 top, 40 bottom, 48 side.
- At 1024–1279: same band, primary fixed 300, dock side 32.

### 600–1023 px — statement top, dock two-row

```
┌──────────────────────────────────────────────┐
│ TrueReport                     English│العربية│  command strip
│ ───────────────────────────────────────────  │
│ Use your workshop account.                   │  40/48
│ Vehicle inspection reports for partner …     │
│                                              │
│                (canvas)                      │
├──────────────────────────────────────────────┤
│ Need technician login?  Get help   ◈ Authorised│
│ Email                 Password               │
│ [__________________]  [__________________ 👁 ]│
│ [                Sign in                    ]│ 56 bar, full width
└──────────────────────────────────────────────┘
```

- Dock is stacked: meta row, labels + cells in a row, primary full width.
- Dock padding 24 side, 24 top, 28 bottom.

### < 600 px — statement top, dock stacked (the primary layout)

```
┌──────────────────────────────────┐
│ TrueReport        English│العربية │  56 strip
│ ────────────────────────────────  │
│ Use your workshop                 │  32/40, max 2 lines
│ account.                          │
│ Vehicle inspection reports       │  14/21
│ for partner workshops.           │
│                                  │
│          (canvas)                │
│                                  │
├──────────────────────────────────┤  dock top hairline
│ Need technician login?  Get help  │  12/16 meta
│ ◈ Authorised workshop staff only  │  11/16 meta
│ Email                            │  11/16 label
│ [_____________________________]   │  56 cell
│ Password                    👁    │
│ [_____________________________]   │  56 cell
│ [           Sign in            ]  │  56 bar
│ [error row — reserved 24]         │
└──────────────────────────────────┘
   20 side gutters, 20 top, 16 bottom + safe area
```

- Order is fixed: meta, email, password, primary, error row.
- The submit sits at ~88–93 % of the viewport height on a 390 × 844 screen.
- The canvas above is empty except the statement; no art.
- At 360: gutters 16, display 28/36, cells 56.

### Keyboard up (phone)

- Scaffold resizes; the dock lifts above the keyboard and the canvas scrolls
  away (the statement may scroll out).
- The dock keeps its order; the primary stays visible above the keyboard at
  ≥ 640 px viewport height. Below that, the dock becomes scrollable internally
  and the primary is the last row.
- The error row appears above the fields when a failure is present, so it is
  never hidden behind the keyboard.

### Text scale

- 1.5×: the dock stacks at every width below 1200; cells grow to fit; the
  statement wraps; no clipping.
- 2.0×: the dock becomes an internally scrollable sheet; the primary remains the
  last row and is reachable; the language switch stays in the command strip.

## 8. Type and colour (Phase 5 commits the tokens)

| Role | Token | Note |
|---|---|---|
| Statement | `TrType.display` 32/38 w800 (`TrTypeArabic` in AR) | The focal point |
| Tagline | `TrType.bodyLg` 16/24 w500 | Muted |
| Product name | `TrType.titleLg` 16/22 w700 | Command strip |
| Field label | `TrType.labelMd` 12/16 w600, tracking 0.24 | Persistent, above the cell |
| Input | `TrType.bodyLg` 16/24 w500 | LTR inside RTL |
| Primary label | `TrType.labelLg` 14/18 w700 | White on accent |
| Meta / help / security | `TrType.bodySm` 12/18 and `labelSm` 12/16 | Muted |
| Error | `TrType.bodySm` 12/18 w500 | Danger |
| Canvas | app surface (`TrColorLight.surface`) | No new warm palette: the dock reads through structure, not tint |
| Dock | `Fx.container` / surfaceContainer | One step darker than canvas |
| Ink | `Fx.ink` | 16:1 on canvas |
| Muted | `Fx.muted` | ≥ 4.5:1 |
| Accent | `Fx.deepGreen` (`#006C49`) | **Not** emerald: white on `#10B981` is ~2.2:1. Deep green gives ~5.5:1 |
| On accent | `Fx.white` | Primary label |
| Danger | `Fx.error` | Error row and invalid cell edge |
| Hairlines | `Fx.divider` / `surfaceHighest` | 1 px structure |

The dock's top hairline and the accent primary are the only "loud" elements.
Accent appears **once** on a resting screen.

## 9. States (every one specified)

| State | Behaviour |
|---|---|
| **Rest** | Canvas + statement + dock. Email autofocused on ≥ 1024 only. Tab order: language → email → password → reveal → primary. |
| **Focused** | 2 px `deepGreen` ring inside a 2 px slot that exists at rest, so nothing moves. |
| **Filled** | Values persist through failures and locale switches; email LTR; password obscured. |
| **Validation error** | On submit: inline message under the field (12/18, danger), focus moves to the first invalid field; the form does not submit. The dock grows by the message height; the primary stays visible. |
| **Submitting** | Primary shows an `onAccent` spinner, label hidden, `liveRegion` on the button, disabled; a second tap, a second Enter and a second autofill submit are impossible. The dock does not move. (Flutter has no `Semantics(busy:)`; the spinner's progress semantics plus the live region carry the state.) |
| **Auth error** | A reserved row between the fields and the primary on phone (under the primary on desktop, matching the approved Gate 3 render) with `error_outline`, danger text, `liveRegion`. Password keeps focus for retry (code keeps focus in the challenged state); email preserved. The row exists at rest (height reserved) so nothing shifts. |
| **Network error** | Same row, network copy. No offline claim, no retry button (the primary is the retry). |
| **2FA challenge** | The password cell is replaced by the code cell (`Authentication code`) with the challenge token in memory; the primary label becomes `Verify`; the email cell stays visible but read-only (disabled) so the user sees which account; a text hint is **not** available, so the field accepts 6 digits **or** `XXXXX-XXXXX` (11 chars, case-insensitive, hyphen allowed) and the input is `TextInputType.text` with `autocorrect: false`, `enableSuggestions: false`. A wrong code shows the credential error copy (server collapses all 2FA failures). |
| **Success** | No flash, no toast. The primary resolves (spinner stops) and the router replaces the route. Focus is not moved. |
| **Session restore** | No separate splash on this screen. The router decides: an existing session redirects to `/jobs`; the screen is only interactive when unauthenticated. (Known: a brief sign-in flash can occur while restore is in flight; recorded, not changed.) |
| **Locale switch** | Rebuilds in place; typed values persist; the layout mirrors; email/password input stays LTR; numerals stay Latin. |
| **RTL (ar)** | Command strip mirrors (name on the right, switch on the left); dock meta row mirrors; labels right-aligned; the reveal sits at the visual end of the password cell; the primary arrow flips. |
| **Text scale 1.5× / 2.0×** | See §7; no clipping, no horizontal scroll, primary reachable. |
| **Reduced motion** | No rise; the dock is simply present. |
| **Offline at submit** | The network error row; no optimistic state. |
| **Permission denied** | Not this screen: the router sends a non-technician to `/unauthorized`. The sign-in screen never shows a role error. |

## 10. Microcopy (existing keys only)

`appTitle` · `technicianSignInTagline` · `signInSubtitle` ·
`emailLabel` · `passwordLabel` · `twoFactorLabel` · `signInButton` ·
`verifyButton` · `technicianNeedTechnicianAccess` · `technicianContactAdmin` ·
`technicianSecurityLine` · `languageEnglish` · `languageArabic` ·
`invalidCredentials` · `networkError` · `genericError` · `requiredField` ·
`invalidEmail`.

**Removed:** `technicianPasswordHelp` is no longer rendered (dead affordance,
G1). It stays in the ARB.

## 11. Accessibility

- Visible labels above every cell; hints are not labels.
- The password reveal has an accessible name (`passwordLabel`), a
  `Semantics(toggled:)` state, and a ≥44 × 44 hit area.
- Error text is a `liveRegion`; validation moves focus to the first invalid
  field; an invalid submit also announces once.
- Contrast: ink on canvas ≥ 16:1; muted ≥ 4.5:1; white on deep green ≥ 5.5:1;
  danger on canvas ≥ 6:1.
- Touch targets ≥ 44 px; the language switch segments are ≥ 44 px tall even if
  their visual is 32 px.
- Keyboard: language → email → password → reveal → primary; Enter submits from
  the password (and from the code field in 2FA).
- `AutofillGroup` wraps email + password; `TextInput.finishAutofillContext()` is
  called on success.
- Reduce motion removes the rise only.

## 12. Structural departures (non-empty, required by Gate 6)

1. The centred 350 px column is gone: the primary layout is a **bottom dock**
   with an empty canvas above it.
2. The 222 px hero and the empty glow mark are deleted; identity is a 56 px
   command strip with the product name.
3. Hint-as-label is deleted; labels are persistent above the cells.
4. The error is a reserved row inside the dock, not a centred line that shifts
   the button.
5. The footer is a meta row inside the dock, not two fixed Figma slots
   (153.53 / 64.94 px deleted).
6. "Password help" is deleted; "Get help" is de-linked.
7. 2FA is a dock mode, not a third field appended to a column.
8. Desktop is a statement + horizontal band, not a phone column.
9. The screen file is rewritten and split into region files (command strip,
   canvas statement, dock, field cell, primary, meta row, error row); every old
   private widget is deleted.

## 13. Acceptance checklist

1. 1440 / 1280 / 1024 / 768 / 600 / 390 / 360 EN and 1280 AR: no clipping, no
   horizontal scroll, no new `RenderFlex overflowed`.
2. At 360 × 800 the primary is visible without scrolling; at 390 × 844 it sits
   in the bottom 15 % of the viewport.
3. 1.5× and 2.0× text scale: readable, primary reachable, no overflow.
4. AR: zero English except the wordmark and the language label; email/password
   render LTR; the arrow and the reveal mirror.
5. Every string comes from `AppLocalizations`; no new ARB key; the i18n scan
   adds no offender.
6. 2FA accepts a 6-digit TOTP and an 11-character recovery code, pinned by a
   test.
7. Invalid submit does not call the repository; double submit issues one
   request; both pinned.
8. Error row is a `liveRegion`; focus moves to the first invalid field.
9. The reveal control has an accessible name and a 44 px target.
10. No page-level logging of the email or any credential.
11. Reduced motion: no rise.
12. The two login goldens are regenerated; the other 14 goldens are untouched.
13. The old shared sign-in screen and the dead auth router stack are deleted
    (one revertible step) and nothing else imports them.
14. The Figma geometry and copy-fit login cases are rewritten to their intent
    (no clipping / no truncation), not deleted.

## 14. Risks

1. **A bottom dock must survive the keyboard.** If it is implemented as a fixed
   `Positioned` without resize handling, the primary will sit under the
   keyboard. Mitigation: Scaffold resize + measured 640 px fallback + a test at
   390 × 500 with `viewInsets`.
2. **Empty canvas can read as unfinished.** The statement and the dock's
   hairline must carry the composition; at 1440 the dock must span wide, not
   shrink to a phone bar.
3. **Deep green vs emerald.** The app's `FxButton` primary is emerald with white
   text (low contrast). The sign-in primary must use deep green; a local
   `SignInPrimary` primitive is acceptable, but it must be a primitive, not an
   inline container.
4. **Custom cell control.** A labelled cell with an inline reveal, error slot and
   focus ring is more code than `FxTextField`; it must still be a `FormField`
   so validation, autofill and semantics keep working.
5. **The 2FA recovery-code fix is a behaviour widening.** It must be a separate,
   tested change; do not also change the password rules.
6. **Locale is memory-only.** Do not add persistence in this wave (I13).

## 15. Amendments recorded after the independent Gate 6 review (2026-11-19)

The screen was not redesigned; these are documented corrections where the brief
wording and the approved Gate 3 visual disagreed, plus the keyboard-up fix.

1. **Primary width is 300 at every band width** (not 280/240). The approved
   `c_1440_en.png` shows 300; the brief was stale.
2. **Error row position** on phone is between the fields and the primary, not
   above the fields; this matches the approved render and keeps the primary
   anchored to the bottom edge.
3. **Keyboard-up is implemented with `Scaffold(resizeToAvoidBottomInset: true)`.**
   The threshold uses the available body height (viewport minus the keyboard):
   below 640 px the dock is inside the scroll view and the primary is reachable
   by scrolling; it is never under the keyboard.
4. **At 2× text the canvas scrolls** and the tagline may sit below the initial
   fold. The primary remains reachable; nothing clips.
5. **The language pill keeps its 1 px shadow**; it is the only shadowed element
   on the screen. The "no shadows" rule applies to fields, band and primary.
6. **The statement's ≥ 1.5× size is a base size** that the platform text scaler
   then scales again; the composition is preserved and the words stay whole.
