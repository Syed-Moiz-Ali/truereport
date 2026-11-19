# Direction B — "The work order"

**Signature (one sentence):** The perforation between the credential body and
the tear-off strip — the screen reads as a document you could tear.

The screen is not a column of widgets on a background; it is one physical
work-order sheet. Everything the user needs is inside the sheet's border. There
is no hero, no floating language chip, no card stack, and no second surface.

---

## 1. Desktop — 1440 × 900

```
x=0                                                                     1440
y=0   ┌───────────────────────── canvas  #F3EFE6 ─────────────────────────┐
      │                                                                   │
y=96  │  120 ┌─ sheet 720 × 700 ────────────────────────────┐            │
      │      │ 32                          112                │            │
      │      │ TrueReport                       [ English │ العربية ]     │
      │      │ Vehicle inspection reports for partner workshops.          │
y=208 │      ├╌╌╌╌╌╌╌╌╌╌╌╌ perforation · 14 px band · notches ╌╌╌╌╌╌╌╌╌╌╌╌┤      │      │ 32 656 content                                  32          │
      │      │ Use your workshop account.                                │
      │      │                                                             │
      │      │ EMAIL                        PASSWORD                       │
      │      │ ┌──────────────────┐         ┌──────────────────┐     ◉     │
      │      │ │                  │         │                  │           │
      │      │ └──────────────────┘         └──────────────────┘           │
      │      │   (18 px error slot)            (18 px error slot)          │
      │      │                                                             │
      │      │ ········· ~147 px of paper (the sheet's air) ·········      │
      │      │                                                             │
      │      │ ───────────────────────────────────────────────────────     │
      │      │ Email or password is incorrect.        ┌────────────────┐   │
      │      │ (60 px status row, error optional)     │    Sign in     │   │
      │      │                                        └────────────────┘   │
      │      │                                        240 × 60 stamp       │
y=796 │      ├╌╌╌╌╌╌╌╌╌╌╌╌ perforation · 14 px band · notches ╌╌╌╌╌╌╌╌╌╌╌╌┤
      │      │ 32  tear-off strip 120 px, #FBFAF4                        │
      │      │ Need technician login?  Get help    🛡 Authorised workshop staff only
      │      └─────────────────────────────────────────────────────────────┘
      │
      │   896 ┌─ stamp column 220 × 700 ─┐        324 px quiet right edge
      │       │ 1 px rule at the start   │
      │       │ ┌─────────────────────┐  │
      │       │ │                     │  │
      │       │ │         TR          │  │   164 × 164 hairline frame,
      │       │ │                     │  │   monogram = appTitle initials
      │       │ └─────────────────────┘  │
      │       │ ──────────────────────── │   1 px secondary rule
      │       │ AUTHORISED               │
      │       │ WORKSHOP STAFF           │   security line, stacked,
      │       │ ONLY                     │   11/15, 0.6 tracking
      │       └──────────────────────────┘
      └───────────────────────────────────────────────────────────────────┘

Band maths: 96 + 700 = 796 (104 bottom). 120 + 720 + 56 + 220 = 1116 (324 right).
Sheet: header 112 · tear 14 · body 454 · footer 120 = 700.
Body: 32 pad + 28 subtitle + 28 gap + 102 grid + 1 rule + 24 gap + 60 action + 32 pad
      = 307 fixed, 147 spacer.
Grid: two 316 px cells, 24 gutter, label 16 + 8 + cell 60 + error slot 18 = 102.
```

The group is **not centred**: 120 px at the reading edge, 324 px at the far
edge. The right third is intentionally quiet so the sheet reads as an object,
not a panel. The stamp column is a vertical band with a single 1 px rule, not a
card.

---

## 2. Phone — 390 × 844

```
x=0                                    390
y=0   ┌─────────── canvas #F3EFE6 ───────────┐
y=16  │ 16 ┌─ sheet 358 × 812 ─────────────┐ │
      │    │ 20                         20 │ │
      │    │ TrueReport       English│العربية│ │   title 20/26 · 800 on the
      │    │ Vehicle inspection reports…   │ │   same row as the language;
y=112 │    ├╌╌╌╌ perforation · 14 px ╌╌╌╌╌╌╌┤ │   tagline 11/14 full width
      │    │ 20                           │ │   under it
      │    │ Use your workshop account.    │ │   18/26 · 600
      │    │                               │ │
      │    │ EMAIL                         │ │   11/15 · 700
      │    │ ┌───────────────────────────┐ │ │
      │    │ │                           │ │ │   64 px (gloves)
      │    │ └───────────────────────────┘ │ │
      │    │   (18 px error slot)          │ │
      │    │                               │ │
      │    │ PASSWORD                   ◉  │ │   44 × 44 reveal
      │    │ ┌───────────────────────────┐ │ │
      │    │ │                           │ │ │
      │    │ └───────────────────────────┘ │ │
      │    │   (18 px error slot)          │ │
      │    │                               │ │
      │    │ ······ ~137 px of paper ····· │ │
      │    │                               │ │
      │    │ ───────────────────────────── │ │
      │    │ Email or password is wrong.   │ │   36 px reserved status
      │    │                               │ │   (liveRegion)
      │    │ ┌───────────────────────────┐ │ │
      │    │ │          Sign in          │ │ │   60 px, full width,
      │    │ └───────────────────────────┘ │ │   bottom = 828 − 124 − 20
y=704 │    ├╌╌╌╌ perforation · 14 px ╌╌╌╌╌╌╌┤ │   (geometric: 624…684)
      │    │ 20  tear-off strip 124 px     │ │
      │    │ Need technician login? Get help│ │
      │    │ 🛡 Authorised workshop staff only
      │    └───────────────────────────────┘ │
      └───────────────────────────────────────┘

Band maths: 16 + 812 + 16 = 844. Sheet: header 96 · tear 14 · body 578 · footer 124.
Body: 24 + 26 + 22 + 106 + 16 + 106 + 1 + 16 + 36 + 8 + 60 + 20 = 441 fixed,
      137 spacer. Cell block 106 = label 16 + 8 + cell 64 + error slot 18.
Primary block: top 624, bottom 684 → bottom third, thumb zone. Tear strip pinned.
```

At 390 the sheet is the viewport minus a 16 px canvas margin on all four
sides. The tear-off strip is pinned to the bottom; the credential body can grow
(with text scaling or wrapped Arabic) by consuming the paper spacer, never by
pushing the action off-screen.

---

## 3. Structural departures from today (six)

| # | Today (evidence) | Direction B |
|---|---|---|
| **1. Page law** | One 350 px column centred at every size; above 900 px only a max-width appears (`sign_in_view.dart:57-70`, `_M.contentWidth`) | 720 × 700 sheet at x=120 with a 220 stamp column at x=896 on 1440 — off-centre by construction. Phone: edge-to-edge 358 sheet in a 16 px margin, not a centred column |
| **2. Identity** | 222 px hero (`_M.heroHeight`) holding an 80 px box that paints a blurred glow and no mark (`_BrandMark`); title and tagline centred under it | No hero. A 112 px document header: appTitle + tagline at the start, language at the end, closed by a perforation. The only mark is a **derived** initials monogram set as type in a hairline frame in the stamp column — no invented logo |
| **3. Field structure** | Hint is the only label; 48 px rounded, shadowed, icon-led cards (`FxTextField`, `Fx.pillShadow`) | Persistent 11 px uppercase labels above square 60/64 px cells. Desktop is a two-column form grid; phone stacks. No icons inside cells, no shadows, 1 px hairline at rest, 2 px accent on focus |
| **4. Feedback** | Error is a centred line *inserted* between password and button, so the action jumps; not a liveRegion (`sign_in_view.dart:223-246`) | Every cell owns an 18 px reserved error slot; the pair-level error owns a 36/60 px reserved status row in the authorisation band. Nothing reflows. Both are `liveRegion` |
| **5. Action** | 56 px emerald pill mid-column with a coloured glow shadow (`FxButton`, `Fx.ctaShadow`) | A squared stamp block (desktop 240 × 60, phone 358 − 40 × 60) at the end of the sheet body; one accent; 1 px press / 120 ms; no shadow |
| **6. Footer & help** | Two fixed slots (153.53 / 64.94 px) pinned by a copy-fit test; a dead "Password help"; a link-styled "Get help" that does nothing | Dead row deleted. Access line and security line live in a 120/124 px tear-off strip behind a perforation; no fixed widths; "Get help" is plain ink (G1), so the strip never promises a channel |
| **7. Language** | Floats above the hero, unrelated to the content (`sign_in_view.dart:76-93`) | Docked in the header stub at the end of the product name, divided by a 1 px vertical rule; the perforation passes underneath both |

---

## 4. Type and colour character

**Type — one family, form-document weights (Plus Jakarta Sans; Noto Sans Arabic
fallback, 0 tracking in AR).**

| Role | Spec | Use |
|---|---|---|
| Product | 26 / 32 · 800 · −0.60 (phone 20 / 26 · 800) | `appTitle`, once, in the header |
| Job line | 20 / 28 · 600 · −0.40 (phone 18 / 26) | "Use your workshop account." |
| Cell label | 11 / 15 · 700 · +0.80, uppercase Latin | `Email`, `Password`, `Authentication code` — never disappears |
| Body / meta | 13 / 18 · 400 | footer access line, tagline (12 phone) |
| Stamp label | 15 / 16 · 700 · +0.02 | the primary block only |
| Monogram | 64 / 64 · 800 · −2 | derived initials, decorative, excluded from semantics |

**Colour — paper, not palette.** Canvas `#F3EFE6`, sheet `#FFFFFF`, cell and
tear strip `#FBFAF4`, ink `#1A1B1F`, secondary `#6E675C` (5.6:1 on white),
hairline `#D9D2C4`, dash `#BDB19A`, accent `#006C49` (6.5:1 with white),
accent pressed `#00422B`, error `#A3231F` (7.4:1 on white). **One accent, one
filled block.** Structure comes from 1 px rules, the perforation and space —
never from shadow. A single soft edge shadow belongs to the sheet, nothing else.

**Motion — stamp.** Press: translate 1 px, fill `#00422B`, 120 ms out; release
back over 120 ms. Zero duration when `MediaQuery.disableAnimations` is true
(`ReduceMotion.duration`). No entrance animation.

---

## 5. States

| State | Behaviour inside the document |
|---|---|
| **Resting** | Two labelled cells, one stamp block, one tear-off strip |
| **Field error** | The cell's reserved 18 px slot carries "This field is required." / "Enter a valid email address."; border and label go `#A3231F`; the block does not move |
| **Server error** | The reserved status row carries "Email or password is incorrect." (or network/generic) as a `liveRegion`; both credential cells take the error border because the copy names the pair; layout identical |
| **2FA challenge** | The credential grid is **replaced** by one full-width "Authentication code" cell at the same origin (no third cell bolted under the password); the stamp label becomes "Verify"; header, tear strip and geometry unchanged. No copy exists to explain the challenge, so the state stays visually calm rather than inventing a sentence |
| **Arabic** | Whole composition mirrors: sheet right-of-centre with the stamp column on the left, labels start-aligned right, `Get help` on the reading-start side. Email, password and code cells stay LTR with the caret at their left edge; typed values survive the toggle |

---

## 6. Trade-off — what this makes harder

The sheet's fixed bands turn every future state into a fit problem: a lockout
notice, a "no workshop membership" message, or any real support channel must
fit inside the 36 px status row or the tear-off strip, because adding a band
breaks the document metaphor. On a 358 px phone the usable width is 318 px, so
long Arabic copy wraps inside fixed header and footer heights — AR is the
tightest case and the first place this layout will fail. An official-looking
form also raises the cost of a dead affordance: the help promise had to be
deleted rather than restyled, so this direction has **no support channel at
all** until G1 is answered. Finally, the desktop stamp column spends 276 px of
horizontal width (gap included) on stance and identity, taken from form width.

---

## 7. Non-negotiables carried into the build

- Keys kept: `sign-in-email`, `sign-in-password`, `sign-in-submit`,
  `sign-in-language-en`, `sign-in-language-ar`, `sign-in-access-prompt`,
  `sign-in-security-line` (+ `sign-in-code` in the challenge state).
- Every string from `AppLocalizations`; nothing outside `design_thinking.md §4`.
- Email: LTR, `emailAddress`, `AutofillHints.email`, Enter → password.
  Password: obscured, `AutofillHints.password`, 44 × 44 reveal, Enter submits.
- The 2FA code cell is a text input with no six-character cap, so the server's
  11-character recovery code is enterable (G4); Verify is the same stamp block.
- Language control writes the locale; the language pair is ordered by locale so
  Arabic reads first on the Arabic screen.
- Light only; bundled fonts only; no `design_system` or ARB edits.
