# Jobs module — mobile design directions

## The user (assume, unless corrected)

A technician on a workshop floor. Gloves on, phone in one hand, a car on the ramp, glare from the bay door.
Sessions are interrupted (a colleague, a customer, a part). One job is 30 checklist items across 6 sections,
several safety-critical, some requiring a photo. They do 4–8 jobs a day. They never read help text.

**Job to be done:** "When I walk up to a car, I want to get through its inspection without thinking or losing my
place, so I can hand it back and start the next one."

**Top tasks, by frequency × value**
1. Resume the car in front of me (not "find a date").
2. Answer an item: pass / advisory / fail, add a photo when the item demands it.
3. Know how much is left and whether anything blocks submission.
4. Finish: summary → signature → hand over.

**What failure costs:** rework (a missed safety item), a blocked handover, or a wrong report — worse than any
visual imperfection. Every design choice is judged on "does this make the next item faster and harder to get wrong".

## Non-negotiables for every direction

- Phone first at 390×844, tablet at 768×1024. Tablet must not be a stretched phone.
- Primary action lives in the thumb zone (bottom 96 px), ≥ 56 px tall for the main verb, ≥ 48 px for the rest.
- One dominant element per screen; the vehicle and the next action beat chrome.
- No default Material look: no stock AppBar/Card/ListTile/Chip/FAB. Custom surfaces, 16 px cards, hairline dividers,
  tonal layers, one accent (brand ink #006C49 already in the design system).
- Status never by colour alone; no raw dates; no `12/30` without a unit.
- Sheets for decisions and section switching, never dialogs.
- Offline / sync-pending is visible where the work happens.
- Motion is quiet: 180–280 ms, ease-out, no decoration loops.
- RTL-safe: directional insets, mirrored chevrons.
- No production file may be touched. Previews live in `lib/preview/` with sample data.

## Three directions (structurally different, not three skins)

### A — FOCUS (one item at a time)
Signature: the job is a **session**, not a list. One item card fills the screen, a 30-tick spine shows the whole
job, and the bottom dock is three huge result actions.
Queue: "on the ramp" hero for the current car + a short upcoming stack; overdue work in one collapsed group.
Job: spine + one item + Pass/Advisory/Fail + Add photo + Next. Sections switch from a sheet.
Trade-off: less overview; must be reachable in one tap from the spine.

### B — ROUTE (sections as stations)
Signature: the job is a **route** the technician walks. Six stations on a vertical line, each with its own progress
and next item; tap a station to open its items inline (accordion).
Queue: dense list + one persistent resume bar.
Trade-off: more scrolling than A, but the whole job is always on screen and orientation never breaks.

### C — DECK (swipe the items)
Signature: items are **cards you clear**. Full-bleed item card; swipe or tap Pass/Advisory/Fail; the card flies out
and the next settles in. Section progress as dots.
Queue: a peeked stack with one big "Start next" action.
Trade-off: gesture discovery; needs buttons as the primary path with swipe as a shortcut.

## How a direction is proven

Each direction is a throwaway preview (`lib/preview/direction_{a,b,c}.dart`) rendering both screens with the shared
sample job (Toyota Land Cruiser 2023, AUD-354626, 30 items, 12 done, current item = front brake pads, safety-critical,
photo required). Captured at 390 and 768 with real fonts. Nothing ships until one direction is chosen.
