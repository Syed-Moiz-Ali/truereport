# Phase 3 (reopened) — three directions for Workshop Admin sign-in

Status: **Gate 3 passed (user, 2026-11-18) — direction B, "The bay" chosen.**
The throwaway preview route (`lib/preview/signin_directions.dart`) was deleted
after Gate 3 as dead code; the renders below are the retained evidence.

---

## 0. Why Phase 3 was reopened

The previous run reached Gate 6. The user's verdict on the built screen was
"UI and UX was very bad". That verdict is supported by the structural diff:

| | Original (`HEAD`) | Shipped rebuild (working tree) |
|---|---|---|
| 1440 layout | 50/50 split, green panel left, form centred right | **identical** 50/50 split, form centred right |
| 390 layout | brand bar, then form | **identical** brand bar, then form |
| Signature | white example-job card floating on green | **same card**, moved to the bottom, plus a label |
| Widget tree | one 633-line file | **one file**, same regions |

The shipped work changed colours, type sizes, spacing and a label. It did not
change the composition. That is the definition of a **restyle**, which the
pipeline's edit-vs-replace test explicitly fails. The engineering underneath it
(invariants, characterization tests, real-font harness, l10n, 2FA handling) is
sound and is **kept** — the design decision is what is being redone.

One more root cause worth naming: the old screen treats sign-in as a marketing
landing page (half the viewport sells the product), so the form is pushed into
the remaining half and floats in empty canvas. At 390 px the phone shows a bar,
a title, two fields, a button and 300 px of nothing. Both are composition
problems, not colour problems — which is why colour changes could never fix it.

---

## 1. Thinking protocol

**The job.** Get a workshop admin into their shop in one short step, on the
first action of their day, on a desktop in the office or a phone in the bay.

**What today's screen gets wrong**

1. Split-screen: half the page is a poster, so the task is off-centre and the
   eye lands on the promise instead of the fields.
2. No containment: the form is a naked stack of two boxes on a large field.
3. The example job is a card floating on a slab — decoration, not evidence, and
   disconnected from the headline it is supposed to prove.
4. At 390 px the lower third of the screen is empty.
5. Nothing on the screen is specific to a workshop: no vehicle, no job, no bay.

**Constraints that bind**

- Data: only email, password, and failure codes exist before sign-in. No
  workshop name, no live counts. Any "activity" must be the **labelled example
  job** approved at Gate 0, or it is fabricated data.
- Invariants: keys `sign-in-email|password|submit`, no TOTP field, no
  self-serve/reset/SSO, `/signin → /workshop` redirect matrix, l10n-only copy,
  light-only theme, tokens-only styling (`source_scan_test`).
- Platform: Flutter web + mobile, bilingual EN/AR with RTL, 360 px floor.

**Axes varied** — colour is deliberately *not* one: layout logic, hierarchy,
density, navigation shell, motion verb.

---

## A — "Work order" · the page is a ruled job sheet

**Signature idea.** Sign-in is one line on a workshop's paper job sheet: numbered
rows on a hairline grid, no card, no poster. The example job is the final row of
the same sheet, not a floating card.

**1440**

```
┌──────────────────────────────────────────────────────────────┐
│ [TR] TrueReport  Workshop Admin            [🌐 العربية] 64px │
├──────────────────────────────────────────────────────────────┤
│                  WORKSHOP ADMIN                              │
│                  Sign in                                     │
│                  Use your workshop account.                  │
│                  ═════════════════════════════════ dark rule │
│  01              Email                                       │
│                  [__________________________]                │
│  ─────────────────────────────────────────────────────────   │
│  02              Password                                    │
│                  [_____________________ 👁]                  │
│  ═════════════════════════════════════════════════ dark rule │
│                  Contact your platform…        [ Sign in ]   │
│  ─────────────────────────────────────────────────────────   │
│  EXAMPLE JOB                          18 of 24 items · 75 %   │
│  2023 Porsche 911 GT3 · DXB 48291 · Rashid Al Mansoori       │
│  ██████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    │
└──────────────────────────────────────────────────────────────┘
   content 880 wide, centred; huge step numerals in the left spine
```

**390**

```
┌──────────────────────┐
│ [TR] TrueReport  🌐  │ white header block
│ Sign in              │
│ Use your workshop…   │
├──────────────────────┤
│ Email                │ canvas + faint grid
│ [__________________] │
│ Password             │
│ [______________ 👁] │
│ [     Sign in     ]  │
│ Contact your admin…  │
│                      │
│   (ruled paper)      │
│                      │
├──────────────────────┤ pinned footer, accent-soft
│ EXAMPLE JOB   18/24  │
│ 2023 Porsche 911 GT3 │
│ ███████████░░░░      │
│ KA Karim Ahmed       │
└──────────────────────┘
```

**Structural departures.** Split screen deleted · centred card deleted · the
example job becomes a ruled row and a footer band · numerals as a spine ·
hairlines instead of surface colour to separate regions.

**Type + colour character.** Stationery: ink rules at 100 % on paper, one green
accent reserved for the progress rule and the eyebrow. No elevation at all.

**Trade-off.** The calmest and most "adult" of the three, and the one that
scales to any copy length — but it has the least emotional pull and almost no
product imagery. At 1440 it is deliberately quiet, which some will read as
plain.

**Evidence.** `docs/evidence/directions/a-work-order-1440.png`,
`-390.png`, `-tile.png`

---

## B — "The bay" · form on the left, the inspection surface on the right

**Signature idea.** The right half of the screen *is* an inspection: a real
top-down chassis drawing on ink, with a 24-tick checklist spine that matches the
example job. The form is flush-left and top-weighted, like a tool.

**1440**

```
┌────────────────────────────┬─────────────────────────────────┐
│ [TR] TrueReport            │ ● EXAMPLE JOB                   │
│                            │ 2023 Porsche 911 GT3            │
│  WORKSHOP ADMIN            │ DXB 48291 · Rashid Al Mansoori  │
│  Sign in                   │                                 │
│  Use your workshop…        │        ╭───────────╮            │
│                            │        │  chassis   │           │
│  Email                     │        │  drawing   │           │
│  [_________________]       │        │  (real SVG)│           │
│  Password                  │        ╰───────────╯            │
│  [______________ 👁]       │                                 │
│  [    Sign in    ]         │  Inspection checklist    18/24  │
│  Contact your admin…       │  ▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▯▯▯▯▯▯       │
│                            │  KA Karim Ahmed · Lead tech     │
└────────────────────────────┴─────────────────────────────────┘
   46 %                      54 %, full-bleed ink, no radius
```

**390**

```
┌──────────────────────┐
│ [TR] TrueReport  🌐  │ ink band 132px
│ EXAMPLE JOB   (car)  │
│ 2023 Porsche 911 GT3 │
├──────────────────────┤
│ WORKSHOP ADMIN       │ canvas
│ Sign in              │
│ Use your workshop…   │
│ Email                │
│ [__________________] │
│ Password             │
│ [______________ 👁] │
│ [     Sign in     ]  │
│ Contact your admin…  │
└──────────────────────┘
```

**Structural departures.** Form moves from centred to flush-left · the colour
block becomes a full-bleed inspection surface with a real asset instead of a
white card on green · the example job moves to the top of that surface · a
24-tick spine replaces a progress bar · on phone the surface collapses to an
identity band instead of being dropped entirely.

**Type + colour character.** Instrument: ink field, 26 % white line-art,
tabular numerals, ticks, one green accent rule. Product-specific, not generic.

**Trade-off.** Generated copies of the chassis SVG need asset licensing and a
light/dark tint decision · the asset must **not** mirror in RTL (the drawing
stays, annotations flip) · the ink surface is the identity, so it cannot be
softened later without losing the direction · heaviest to maintain of the three.

**Evidence.** `docs/evidence/directions/b-bay-1440.png`, `-390.png`, `-tile.png`

---

## C — "The pass" · a stage, a sheet that overlaps it, a stub

**Signature idea.** One full-bleed ink stage with the wordmark at poster scale,
and the sign-in sheet overlapping the stage edge like a workshop pass with a
tear-off stub that carries the example job.

**1440**

```
┌──────────────────────────────────────────────────────────────┐
│ [TR] TrueReport                            [🌐 العربية]     │
│                                                              │
│   TrueReport                     (ink stage, 440px)          │
│   ────                                                       │
│                                                              │
│                ┌───────────────────────────┐ ── stage edge ──│
│                │ Sign in                   │                 │
│                │ Use your workshop account. │                │
│                │ Email                      │                │
│                │ [_______________________]  │                │
│                │ Password                   │                │
│                │ [____________________ 👁]  │                │
│                │ [       Sign in        ]   │                │
│                │ Contact your platform…     │                │
│                ├───────────────────────────┤ accent-soft    │
│                │ EXAMPLE JOB     18/24 75%  │  stub          │
│                │ 2023 Porsche 911 GT3       │                │
│                │ ████████████░░░            │                │
│                │ KA Karim Ahmed             │                │
│                └───────────────────────────┘                 │
│                                                    ⟂ rail    │
└──────────────────────────────────────────────────────────────┘
```

**390**

```
┌──────────────────────┐
│ [TR] TrueReport  🌐  │ ink stage 228px
│ TrueReport           │  poster wordmark
│ ────                 │  green rule
├──────────────────────┤
│ ╭──────────────────╮ │  sheet overlaps the stage by 32px
│ │ Sign in          │ │
│ │ Use your workshop│ │
│ │ Email            │ │
│ │ [______________] │ │
│ │ Password         │ │
│ │ [___________ 👁] │ │
│ │ [    Sign in   ] │ │
│ ├──────────────────┤ │
│ │ EXAMPLE JOB 18/24│ │  stub
│ │ 2023 Porsche 911 │ │
│ │ ████████░░       │ │
│ ╰──────────────────╯ │
└──────────────────────┘
```

**Structural departures.** No side-by-side at any width · the page is a stack of
overlapping planes rather than regions · display type at wordmark scale (a new
`display` token in Phase 5) · the example job becomes the sheet's stub rather
than a separate card · vertical rail fills the right margin.

**Type + colour character.** Poster: 1.8× type contrast between wordmark and
meta, ink stage against paper, one thin green rule. The most deliberate
typography of the three.

**Trade-off.** The most striking first impression and the closest to the
"marketing page" anti-goal — it must earn the stage with product truth or it
reads as a landing page · the overlap is the most fragile part at 200 % text
scale · at 1440 the right side of the stage is intentionally empty, which only
works if the wordmark carries it.

**Evidence.** `docs/evidence/directions/c-stage-1440.png`, `-390.png`, `-tile.png`

---

## 2. What is the same in all three (non-negotiables)

Stable keys, validation, error banner, submitting state, 2FA message, language
toggle, autofill hints, one primary action, no invented data, no fabricated
security claims, tokens-only styling, and the example job always labelled
"Example job" and announced as an example.

## 3. Recommendation

**B** if the product's identity matters more than its calm — it is the only
direction that looks like a workshop tool and it survives the 390 px test with
an identity band. **A** if the admin base is conservative and speed matters most.
**C** only if the brand is strong enough to carry a poster-scale wordmark.

The choice is the user's at Gate 3.
