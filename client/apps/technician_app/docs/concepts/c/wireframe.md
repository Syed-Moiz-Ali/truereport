# Direction C — "The dock"

Sign-in (`/signin`). Full-bleed canvas + action band docked to the bottom edge.
No card, no centred column, no hero image. Evidence:
`test/preview/directions/c/` (preview widget + capture test).

## 0. Idea in one line

**The canvas holds the sentence; one tinted band at the bottom edge holds every
action, so the thumb never leaves the bottom of the phone.**

Everything below follows from that split: statement = canvas, work = dock. The
dock is always flush with the bottom edge (never a floating card), its top edge
is the only elevation on the screen, and it is the only place a control lives.

## 1. Structural wireframe — 1440 × 900 (desktop)

```
┌──────────────────────────────────────────────────────────────────────────────┐ 0
│  TrueReport                                        [ English | العربية ]     │ 72   command strip
├──────────────────────────────────────────────────────────────────────────────┤ 73   hairline
│                                                                              │
│   Use your workshop                        ← 60/64 · w800 · ink (#1A1B1F)    │ 137
│   account.                                    measure 700 px, top-left        │
│                                                                              │ 265
│   Vehicle inspection reports for partner workshops.   ← 16/24 · muted        │ 289
│                                                                              │ 313
│                                                                              │
│                       (generous white space, no ornament)                    │
│                                                                              │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤ 642  band top
│  Need technician login?  Get help                     ◯ Authorised workshop   │ 698  meta row
│                                                          staff only           │      (inside band)
│                                                                              │ 750  labels
│   Email                          Password                          ┌───────┐  │ 772  cells 52 h
│  ┌──────────────────────────┐   ┌──────────────────────────────┐  │       │  │
│  │                          │   │                        (eye) │  │ Sign  │  │
│  └──────────────────────────┘   └──────────────────────────────┘  │  in   │  │
│       flex 4 · 52 h                  flex 4 · reveal 44×44        └───────┘  │ 824
│                                                                  300 wide   │
│   (reserved error row — 20 px, always present, liveRegion)                   │ 836
│                                                                              │ 900
└──────────────────────────────────────────────────────────────────────────────┘
   64 px gutter shared by strip, statement and band → one left rule, one grid.
   Band 258 px, tint #F4F3F8 · top hairline #DAD9DF · cell #FFFFFF on the tint.
```

Challenge (2FA) on desktop: the row keeps its shape — one compact code cell
(360 px) at the start, the primary block (`Verify`) at the end. The band keeps
its height, its edge and its meta row.

## 2. Structural wireframe — 390 × 844 (phone)

```
┌────────────────────────────────────────┐ 0
│  TrueReport              [EN | العربية] │ 56   command strip
├────────────────────────────────────────┤ 57   hairline
│                                        │
│  Use your workshop                     │ 97   34/39 · w800 · max 330
│  account.                              │ 136
│                                        │ 175
│  Vehicle inspection reports for        │ 195  15/22 · muted
│  partner workshops.                    │
│                                        │ 239
│                                        │
│        (white space: the top third     │
│         belongs to the statement)      │
│                                        │
│                                        │
│                                        │
│  Need technician login?  Get help      │ 522  meta row on canvas,
│  ◯ Authorised workshop staff only      │ 536       touching the band
├────────────────────────────────────────┤ 550  band top hairline
│  Email                                 │ 570  label 12/16
│  ┌──────────────────────────────────┐  │ 592  cell 52
│  └──────────────────────────────────┘  │ 644
│                                        │
│  Password                              │ 658
│  ┌────────────────────────────────┐    │ 680
│  │                          (eye) │    │
│  └────────────────────────────────┘    │ 732
│                                        │
│  (reserved error row — 20 px)          │ 740
│  ┌──────────────────────────────────┐  │ 772
│  │             Sign in              │  │ 56 → thumb zone
│  └──────────────────────────────────┘  │ 828
└────────────────────────────────────────┘ 844 + safe area bottom
   Band 294 px, full-bleed, flush with the bottom; fields stacked; submit
   full width, 56 px tall, inside the thumb arc.
```

Challenge (2FA) on phone: the two cells collapse to one code cell (label
`Authentication code`), the reserved error row stays, the primary becomes
`Verify`. Nothing else moves.

## 3. Departures from today's screen (structural, not cosmetic)

1. **No card, no 350 px centred column, no hero.** At 390 the band is
   full-bleed; at 1440 the band is one horizontal row. Today the same
   narrow centred column is used at every width (`sign_in_view.dart:57-70`).
2. **The form lives in a bottom dock, not mid-page.** Every control — both
   cells and the primary — sits in one band flush with the bottom edge; today
   the button floats at y≈472 with a 128 px fixed footer below it.
3. **Persistent labels above every cell.** `Email` / `Password` are drawn once
   above the cell and never vanish with input (today the hint *is* the label).
4. **Reserved error row inside the band.** 20 px is held at all times; the
   message fills it, so a failure never re-flows the form. It is a
   `liveRegion` and sits next to the action, not between label and button.
5. **The 2FA state is a mode of the band, not a third appended field.** One
   compact code cell replaces the two cells; the primary label flips to
   `Verify`. On desktop the band is the same height (one row either way); on
   phone it is one cell shorter, still flush with the bottom edge. The default
   screen never shows it; only the style tile and the `showChallenge` preview
   do. The cell accepts a 6-digit TOTP **or** an 11-character recovery code
   (no 6-character cap, as G4 requires).
6. **The utility lines are docked, not footered.** Access + security sit as a
   thin meta row on the band's top edge (desktop) or directly above the band
   (phone). The fixed 128 px footer and its pixel-pinned string widths are
   gone. "Password help" is deleted and "Get help" is plain text (G1).
7. **The language switch has a structural home.** It ends the command strip on
   a shared hairline, aligned to the same gutter as the statement — instead of
   floating above the layout.
8. **A rise, not a settle/stamp.** The band enters from +12 px over 240 ms
   (`easeOutCubic`), zero duration under reduce-motion; the canvas is static.

## 4. Type and colour character

| Role | Value |
|---|---|
| Families | Plus Jakarta Sans; Noto Sans Arabic fallback (bundled `TrFonts`, no new families) |
| Wordmark | 16/22 desktop · 15/20 phone · w800 · ink · tracking −0.3 / −0.2 |
| Statement (desktop) | 60/64 · w800 · ink · tracking −1.8 · measure 700 |
| Statement (phone) | 34/39 · w800 · ink · tracking −0.9 · measure 330 |
| Arabic statement | 58/76 desktop · 32/44 phone · w800 · tracking 0 (no negative tracking, no clipped marks) |
| Tagline | 16/24 desktop · 15/22 phone · w400 · muted |
| Cell label | 12/16 · w600 · tracking +0.3 · muted (Arabic: tracking 0) |
| Cell text | 14/20 · w500 · ink |
| Meta row | 11/16 · w600 · tracking +0.2 · muted (Arabic: tracking 0) |
| Error row | 12/16 · w600 · error, 6 px dot, reserved 20 px |
| Primary label | 15/20 · w700 · on-accent |
| Canvas | `#FFFFFF` |
| Band | `#F4F3F8` (soft neutral tint, no gradient) |
| Hairlines | `#DAD9DF` — command strip + band top edge only |
| Cell | `#FFFFFF`, 1 px `#DAD9DF`, radius 12; focus = 1.5 px primary |
| Accent | `#006C49` (deep green, `TrBrandLight.deepGreenFill`) — primary fill only, white label = 6.5:1 AA |
| Error | `#A3231F` (dot + 12/16 message) on the band tint |
| Motion | one: band rise 12 px / 240 ms; nothing else animates |

No gradients, no glow, no icon tiles, no shadows; the only edge is the band's
top hairline. The language switch is the only borrowed kit control
(`FxLanguageSwitch`), kept for its keys and segment semantics.

## 4b. Honest notes and debts this direction hands back

1. **Reveal control name.** The 44 px reveal button needs an accessible name and
   §4 contains no such string. The preview uses a file-local English label
   (`Show password` / `Hide password`), so the build wave must add one ARB key
   or reuse a platform-provided string. Nothing else on the screen is hard-coded.
2. **Kit switch hit area.** `FxLanguageSwitch` segments are 24 px tall inside a
   32 px container — below 44 px. Fixed only by editing `design_system`, which
   this wave forbids. Every band control is ≥52 px.
3. **Keyboard-up.** On a 390×844 phone the band is 294 px; with the keyboard
   open it must either lift above the inset or scroll. The dock cannot simply
   stay pinned. `resizeToAvoidBottomInset` behaviour is a build-wave decision.
4. **Period spacing at 60 px.** Plus Jakarta Sans ExtraBold gives the full stop a
   wide advance, so "account." shows a small gap at display size. It is the
   bundled font's metric, not a stray space in the string.

## 5. Trade-off

The dock spends the bottom quarter to third of every viewport on a form, so the
screen has no room for brand, imagery or reassurance beyond two meta lines, and
on a small phone with the keyboard up the band must lift or scroll or it becomes
the whole viewport. On desktop the statement and the fields are far apart (eye
travel of ~400 px) and a 300 px-wide primary at the far end of a 1312 px row
reads as "toolbar" rather than "document". It is the least warm of the three
directions and the most dependent on precise spacing to avoid looking
unfinished.

## 6. Signature sentence

The persistent bottom dock: content rises above it, the statement owns the top,
and every action lives in one band at the edge of the thumb.
