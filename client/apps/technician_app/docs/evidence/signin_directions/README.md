# Sign-in directions — Gate 3 evidence

Open `index.html` in a browser for the comparison sheet. Raw renders:

| Direction | 1440 EN | 390 EN | 390 AR | Style tile | Spec |
|---|---|---|---|---|---|
| **A — The logbook** | `a/a_1440_en.png` | `a/a_390_en.png` | `a/a_390_ar.png` | `a/a_tile_1200.png` | `../../concepts/a/wireframe.md` |
| **B — The work order** | `b/b_1440_en.png` | `b/b_390_en.png` | `b/b_390_ar.png` | `b/b_tile_1200.png` | `../../concepts/b/wireframe.md` |
| **C — The dock** | `c/c_1440_en.png` | `c/c_390_en.png` | `c/c_390_ar.png` | `c/c_tile_1200.png` | `../../concepts/c/wireframe.md` |

All renders use the bundled real fonts (`loadF2AFonts`) and the real
`AppTheme`; no Ahem, no placeholder glyphs. The preview code is throwaway under
`test/preview/directions/` and is deleted after Gate 3.

## Structural difference check (not a restyle)

| Axis | Today | A | B | C |
|---|---|---|---|---|
| Layout logic | centred 350 px column | page grid, 2 regions + hairline | one bordered sheet + stamp column | empty canvas + bottom dock |
| Identity | 222 px glow hero | 48 px masthead rule | perforated 112 px header + monogram stamp | command strip + display statement |
| Fields | rounded cards, hint-as-label | ruled rows, label above | boxed cells, 2-col grid on desktop | cells inside the dock band |
| Primary | centred pill | full-width bar on the grid | squared stamp block, right | full width in the dock |
| Footer | fixed Figma slots | foot line on the grid | tear-off strip | dock meta row |
| State space | error line shifts content | reserved 52 px band | per-cell slots + reserved status row | reserved 20 px row inside the band |
| Phone thumb zone | submit ~55 % | submit ~55 % | submit ~77 % | submit ~93 % |

Each direction was produced by an isolated session that did not see the other
two. None is a colour/spacing variant of another.

## Known flaws to fix if chosen

- **A:** "Get help" is still rendered in the accent colour in the preview —
  the spec says it must be de-linked. The warm paper palette is new; Phase 5
  must decide whether it becomes a token or the app canvas is kept.
- **B:** the security line appears twice on desktop (stamp column + tear-off);
  remove one. The empty body between the password cells and the divider needs a
  purpose or a tighter measure.
- **C:** the top canvas needs a reason to be that empty; a shorter statement or
  a lower dock on desktop would tighten it. Keyboard-up behaviour must be
  specified.
- **All:** the reveal control's accessible name will reuse `passwordLabel`
  (no new ARB key is allowed in this wave; it is honest, if terse).

## Gate 3 decision

The user picks **one** direction. The chosen direction becomes
`docs/ui_brief.md`; the other two are archived, and their preview code is
deleted.
