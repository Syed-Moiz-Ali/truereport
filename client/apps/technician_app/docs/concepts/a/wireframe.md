# Direction A — "The logbook"

**Signature idea (one sentence):** every element is a ruled row on one continuous
baseline grid — the page itself is the object, and the form is written on it.

Structural logic: an editorial column. No hero, no cards, no floating panels, no
shadows, no gradients. Two regions separated by a single vertical hairline on
desktop; one left-aligned column on a phone. Ink on paper, one accent (deep
green) used only for the primary action and the focused rule.

Evidence: `test/preview/directions/a/direction_a_preview.dart` +
`direction_a_capture_test.dart` (real bundled fonts, 1440×900, 390×844 EN,
390×844 AR, style tile 1200×620).

---

## 1. The page, at three levels

**Page frame.** A masthead strip, a full-width top rule, the body, a full-width
bottom rule. The rules are structure, not decoration.

**Body.** Split by one vertical hairline that runs exactly from the top rule to
the bottom rule. It is the page fold, not a card edge.

**Rows.** Every label sits above a 1 px rule; every input sits on that rule. All
rules land on the same 4 px module, so the eye reads one rhythm from the
masthead to the security line.

Measured grid at 1440 (12 columns, 24 gutters, 82 px columns, 96 px side
margins):

| Column | start x | end x |
|---|---|---|
| 1 | 96 | 178 |
| 5 | 520 | 602 |
| 6 | 626 | 708 |
| 7 | 732 | 814 |
| 12 | 1262 | 1344 |

- Left region = columns 1–5 → `x 96…602`, width **506** (35.8 %).
- Vertical hairline = leading edge of column 6 → `x 626`, from the top rule to
  the bottom rule.
- Form = columns 7–12 → `x 732…1344`, width **612** (49.0 %). The primary bar
  ends on column 12's trailing edge, i.e. on the right page margin.
- The 106 px between the hairline and the form is one column + one gutter: the
  page gutter, deliberately unequal to the 24 px before the hairline.

Both regions start on **one top line** (169, i.e. 40 px under the masthead
rule): the deck on the left, the form's lead-in on the right. The page therefore
has a single top edge and a single bottom edge; the hairline is what makes them
two columns rather than two screens.

---

## 2. Wireframe — desktop 1440 × 900

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ 96                                                                    1344 ▏  │  ▲ 80 top margin
│                                                                              │
│  TrueReport                                          English │ العربية       │  48 masthead strip
│  ═══════════════════════════════════════════════════════════════════════════  │  1 px full rule  y 128
│  ▏                                                                           │
│  ▏   Vehicle inspection reports  ┊   Use your workshop account.              │  one top line  y 169
│  ▏   for partner workshops.      ┊                                           │
│  ▏   (34/48 · 400)               ┊   Email                                   │
│  ▏                              ┊   ⟨typed value⟩                           │
│  ▏                              ┊   ─────────────────────────────────────   │  rule 1 px
│  ▏                              ┊                                           │
│  ▏                              ┊   Password                                │
│  ▏                              ┊   ••••••••                            👁  │
│  ▏                              ┊   ─────────────────────────────────────   │
│  ▏                              ┊                                           │
│  ▏                              ┊   [reserved error band · 52 · liveRegion] │
│  ▏                              ┊   ┌───────────────────────────────────┐→  │
│  ▏                              ┊   │ Sign in                           │   │  60 bar, 3 px radius
│  ▏                              ┊   └───────────────────────────────────┘   │
│  ▏                              ┊                                           │
│  ▏              (the body is air ─ one designed field, crossed               │
│  ▏               by the fold; no content is invented to fill it)            │
│  ▏                              ┊                                           │
│  ▏  ◈ Authorised workshop staff only      ┊   Need technician login?  Get help │  y 791
│  ▏  ═══════════════════════════════════════════════════════════════════════  │  1 px full rule  y 827
│ 96                                                                    1344 ▏  │  ▼ 72 bottom margin
└──────────────────────────────────────────────────────────────────────────────┘
   x 96        602 626      732                                            1344
        left 506     ┊        form 612
                     hairline
```

Vertical rhythm of the desktop body (698 px, `y 129…827`):

| Band | height | What |
|---|---|---|
| masthead | 48 | `appTitle` on the start edge, language folio on the end edge |
| top rule | 1 | full 1248 |
| left: deck | 2 × 48 | the tagline, 34/48, starting on the top line |
| left: assurance | 16 | shield + security line, on the foot line (28 above the rule) |
| right: lead-in | 20 | "Use your workshop account." |
| right: gap | 40 | |
| right: email | 66 | label 16 + 6 + input 40 (44 row) + 2 rule |
| right: gap | 32 | |
| right: password | 66 | label, input, reveal at the end of the rule |
| right: error band | 52 | always reserved, `liveRegion` |
| right: gap | 14 | |
| right: bar | 64 | 60 bar + 2 px focus slot all round |
| right: access | 16 | on the foot line (28 above the rule) |
| bottom rule | 1 | full 1248 |

The body between the form block (`y ≈ 523`) and the foot line (`y ≈ 779`) is
air. It is not filled with an illustration, a stat or a reassurance list: the
concept is a page, and a page has a lower margin. The hairline crossing that
air is what makes it read as a designed field rather than an unfinished
screen.

---

## 3. Wireframe — phone 390 × 844

```
┌──────────────────────────────────────────┐
│ 20                                    370│  ▲ 24
│ TrueReport            English│العربية    │  48 masthead strip
│ ────────────────────────────────────────  │  1 px rule
│                                          │  28
│ Vehicle inspection reports               │  16/26 deck, 2 lines
│ for partner workshops.                   │
│                                          │  36
│ Use your workshop account.                │  13/20 lead-in
│                                          │  18
│ Email                                     │  11/16 label
│ ⟨typed value⟩                             │  44 input, 17/24 · LTR
│ ────────────────────────────────────────  │  2 px slot: 1 rest / 2 focus
│                                          │  28
│ Password                                  │
│ ••••••••••                            👁  │  reveal at the end of its rule
│ ────────────────────────────────────────  │
│ [error band 52 · liveRegion]              │  reserves its space, never moves
│                                          │  14
│ ┌──────────────────────────────────────┐  │
│ │ Sign in                           →  │  │  58 bar + focus slot
│ └──────────────────────────────────────┘  │
│                                          │
│              (flex → footer pinned)      │
│ ────────────────────────────────────────  │  footer rule
│ Need technician login?   Get help         │  12/16 · static, not a link
│ ◈ Authorised workshop staff only          │  11/16
│                                          │  ▼ 20
└──────────────────────────────────────────┘
```

Order is exactly the brief: masthead · rule · deck · lead-in · two ruled fields
(reveal at the end of the password rule) · reserved error line · full-width bar ·
access line · security line. On the phone the bar follows the error band so the
action stays in the thumb zone on a 844 px screen, and the footer rules close
the page at the bottom.

---

## 4. Structural departures from today's screen

1. **No hero block.** The 222 px identity void (and the empty blurred pill) is
   replaced by a 48 px masthead strip whose bottom edge is a rule. Identity is a
   typographic lockup only — no invented logo (`G12`).
2. **No rounded field containers, no placeholder-as-label.** The label is
   persistent above the rule; the input sits *on* the rule. This kills the
   finding that the label disappears once the field is filled (S3).
3. **Desktop is a two-region page, not a 350 px column.** Columns 1–5 carry the
   identity, columns 7–12 carry the form, and a hairline from the top rule to the
   bottom rule separates them (S2). Both regions start on one top line.
4. **The footer is page structure, not two fixed Figma slots.** Access and
   security lines are set on the page grid, on the foot line, with no fixed
   widths and no ellipsis (S8: the 153.53 / 64.94 px slots are gone).
5. **The error is part of the rhythm.** A 52 px band is reserved between the last
   rule and the bar, so a failure never moves the primary action; the band is a
   `liveRegion` and both rules turn to the error ink (S5, I15).
6. **The language switch is a folio, not a floating pill.** Two words on the
   masthead's end edge, an underline on the active one that hugs the word. Same
   keys, same `localeProvider` write, no pill, no shadow.
7. **Two dead affordances removed.** "Password help" is gone; "Get help" is
   static text at the same weight as the prompt, never link-styled (G1). The
   page promises nothing it cannot deliver.
8. **2FA is a compact row, not a third stacked field.** The code sits on its own
   rule; in the style tile the single verb `Verify` sits at the end of that rule,
   and on the real challenge screen the bar itself carries `Verify` so there is
   still exactly one primary action (G4: behaviour preserved, treatment
   secondary).

---

## 5. Type and colour character

**Type — one family, contrast by size and weight, never by colour alone.**

| Role | Desktop | Phone | Weight | Tracking | Use |
|---|---|---|---|---|---|
| Masthead | 28 / 36 | 22 / 30 | 700 | −0.02 em | `appTitle` |
| Deck | 34 / 48 | 16 / 26 | 400 | −0.01 em | the tagline |
| Lead-in | 13 / 20 | 13 / 20 | 600 | +0.01 em | "Use your workshop account." |
| Input | 17 / 24 | 17 / 24 | 500 | 0 | what the technician types |
| Label | 11 / 16 | 11 / 16 | 600 | +0.08 em | above every rule |
| Bar label | 15 / 20 | 15 / 20 | 700 | +0.01 em | `Sign in` / `Verify` |
| Error | 12.5 / 18 | 12.5 / 18 | 500 | +0.01 em | reserved band |
| Footer | 12 / 16 · 11 / 16 | 12 / 16 · 11 / 16 | 400 | +0.03 em | access and security lines |

Arabic: tracking is forced to 0 (tracking breaks Arabic joining) and every line
box is lifted to ≥ 1.6 em. Email and password stay LTR inside an RTL page; the
page itself mirrors — masthead on the right, folio on the left, reveal at the
start of the rule, arrow glyph flipped.

**Colour — ink on paper, one accent, no gradients, no glow, no field shadows.**

| Token | Value | Contrast on paper | Role |
|---|---|---|---|
| paper | `#FAF9F4` | — | canvas |
| ink | `#1A1B1F` | 16.4 : 1 | masthead, input text |
| ink soft | `#5A574F` | 6.8 : 1 | deck, lead-in, `Get help` |
| ink quiet | `#6E6A5C` | 5.1 : 1 | labels, footer lines |
| field rule | `#8A8578` | 3.2 : 1 | the field's edge (WCAG 1.4.11) |
| rule | `#C9C4B4` | — | structural hairlines only |
| accent | `#006C49` | 5.5 : 1 | primary bar, focused rule |
| on accent | `#FDFDFA` | 5.9 : 1 on accent | bar label |
| danger | `#A3231F` | 6.6 : 1 | error band, invalid rules |

No second accent. The accent appears exactly twice on a resting screen: the bar
and one focused rule.

---

## 6. States

- **Rest:** 1 px rule at `field rule`; label at `ink quiet`.
- **Focus:** the rule becomes 2 px `accent` inside a 2 px slot that exists at all
  times, so nothing moves.
- **Invalid:** the rule is 2 px `danger`; the reserved band shows the message in
  `danger`, announced through `liveRegion`.
- **Error (screenshot flag):** both credential rules in `danger`, band filled,
  bar unmoved.
- **Challenge (2FA):** a third ruled row appears under the password with
  `Authentication code`; the bar label becomes `Verify`; the error band and the
  bar keep their positions.
- **RTL:** the entire page mirrors; input content stays LTR.
- **Reduced motion:** the settle is removed (0 ms); nothing else animates.
- **Text scale / long strings:** everything is laid out with `Flexible` and
  `softWrap: false` only where a line must not break (labels, footer, bar); the
  error band and the deck wrap.

## 7. Motion

One verb, used once: the form block **settles** — opacity 0 → 1 with an 8 px
upward translate, 180 ms, `easeOutCubic`, on the first frame only. Under
`MediaQuery.disableAnimations` the duration is zero. Rules never animate except
a 120 ms weight change on focus.

## 8. Trade-off — what this makes harder

The page refuses to hold anything. With no cards there is no container for a
future resend-code panel, a rate-limit notice or a maintenance message, so those
states have to be written as new rows on the same grid instead of dropped into a
box — and a fourth field pushes the bar past the fold unless the error band and
the gaps are re-measured. The ruled field is also a custom control: focus, hover,
invalid, autofill and IME composition all run against a 2 px line instead of
Material's `InputDecoration`, and the reserved 52 px band spends 6 % of a phone
screen on a state that is usually empty. Finally, the concept buys its calm with
air: on a 1440 px screen the body below the bar is deliberately empty, so anyone
who reads emptiness as "unfinished" will want to fill it — and filling it would
break the one idea this direction has. It is also the slower of the three to
scan at a glance, because the form lives on the right half of a page rather than
in the centre of a panel.
