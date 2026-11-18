# App shell — design exploration (Phase 3, before the spec)

Nothing in production was touched. Renders come from
`test/support/shell_direction_previews.dart` (throwaway) captured by
`test/shell_directions_preview_test.dart` with the bundled fonts.
Evidence: `docs/evidence/shell_directions/` · contact sheet `index.html`.

The same neutral sample page sits inside all three shells, so the comparison is
about the chrome and the width it leaves the content.

---

## 3a. Thinking protocol

### The job

One sentence: **let an admin move between six sections and know whose workshop
they are in, without the chrome ever competing with the work.**

### What today's shell gets wrong

1. **The workshop is named twice above the fold** — "TrueReport / Marina
   Workshop" in the sidebar, then "Marina Workshop / Overview" in the top bar.
   The top bar's only new information is the section name.
2. **The same chrome is instantiated twice** with 15 identical props (sidebar
   branch, rail branch); any change is a three-place edit.
3. **Six destinations on a phone**, four visible plus a "More" sheet that also
   hides language and sign-out.
4. **Language is buried** behind the avatar (desktop) or "More" (phone).
5. **No global way to find a job** — the most common task has no affordance in
   the chrome, although the jobs API already supports `search`.
6. **No landmarks**: nav items are icon + label, the current item is a soft pill,
   nothing announces "current page".

### Three constraints that bind

1. **Contract:** six destinations, fixed indices 0–5; stable keys
   (`workshop-tab-*`, `workshop-notifications`); `WorkshopNavigationScope.select`
   is the only switch; sign-out through `authControllerProvider`.
2. **Platform:** light only (W-LIGHT), one accent, RTL Arabic, no dark chrome.
3. **Content:** the shell must not add a scroll owner and must not constrain the
   child's width (the dashboard measures its own box).

### Axes I varied (colour is not one)

| Axis | Values |
|---|---|
| Layout logic | left rail + command bar · horizontal tab band · floating bottom dock |
| Where identity lives | top bar (once) · tab band (once) · thin strip (once) |
| Where the tools live | command bar (search + language + bell) · tab band end · strip |
| Navigation surface | persistent icon rail · persistent text tabs · floating dock |
| Phone strategy | 6-item bottom bar · scrollable tab strip · expanding dock |
| Motion verb | none · tab indicator slides · active dock item expands |

---

## 3b. The three directions

### A — "The spine"

**Signature idea:** navigation never takes text width; the rail is a spine of
icons and the command bar is where the tools live.

```
1440                                             390
┌────┬──────────────────────────────────────┐   ┌────────────────────┐
│ TR │ Marina Workshop › Overview  [search] │   │ TR Marina W.  🔔 LH│
│    │                          EN|ع 🔔     │   ├────────────────────┤
├────┼──────────────────────────────────────┤   │ (content)          │
│ ▣  │                                      │   │                    │
│Ovrv│ 24 jobs on the floor                 │   │                    │
│ 📁 │ 4 are waiting for your decision      │   │                    │
│Jobs│ ▁▂▃▄▅  partition + list               │   │                    │
│ 👥 │                                      │   ├────────────────────┤
│Stff│                                      │   │▣ │📁│👥│▦│🗂│⚙│
│ ▦  │                                      │   │Ov Jobs Staff Tpl Brd Set│
│Tpl │                                      │   └────────────────────┘
│ 🗂 │                                      │
│Brd │                                      │
│ ⚙  │                                      │
│Set │                                      │
│ LH │                                      │
└────┴──────────────────────────────────────┘
```

**Structural departures:** the 256 px text sidebar becomes an 84 px icon rail;
the workshop name appears **once**, in the command bar; the breadcrumb becomes
`workshop › section`; a global find field enters the chrome; the account moves to
the base of the spine; the language toggle becomes a visible labelled control.

**Type + colour character:** clinical, near-monochrome, one accent on the active
item and the brand tile. Reference energy: Linear's rail / Figma's tool strip.

**Rendered:** `a-spine-1440.png`, `a-spine-390.png`, `a-style-tile.png`.

**Trade-off:** icon-only navigation costs recognition; six labels at 9.5 px on a
phone bottom bar is the weakest part of the whole set. Search is a promise the
app must keep (it must route to the jobs queue with the query applied).

---

### B — "The ledger"

**Signature idea:** the shell is a document header. Six section tabs in one
64 px band; no sidebar at all, so the content owns the full width.

```
1440                                             390
┌──────────────────────────────────────────────┐ ┌──────────────────────┐
│ TR TrueReport │ ▣Overview Jobs Staff Tpl Brd │ │ TR Marina W. EN|ع LH │
│               │        Set   Marina W. EN|ع🔔│ ├──────────────────────┤
├──────────────────────────────────────────────┤ │ ▣Overview Jobs Staff…│
│                                              │ ├──────────────────────┤
│ 24 jobs on the floor                         │ │ (content)            │
│ 4 are waiting for your decision              │ │                      │
│ ▁▂▃▄▅  partition + list                       │ │                      │
│                                              │ │                      │
└──────────────────────────────────────────────┘ └──────────────────────┘
```

**Structural departures:** no permanent side chrome; navigation becomes a tab
band; the brand + workshop name sit together at the start; the active tab is the
only filled element; the content gains ~170 px at every desktop width.

**Type + colour character:** editorial: a 64 px band, tab labels as text, one
ink-filled active tab. Reference energy: a report reader / Stripe's docs header.

**Rendered:** `b-ledger-1440.png`, `b-ledger-390.png`, `b-style-tile.png`.

**Trade-off:** six text tabs at 1024 plus the right-hand tools will not fit
without truncation; on phone the strip scrolls, so "Settings" is off-screen by
default — a discoverability cost the current "More" sheet does not have.

---

### C — "The dock"

**Signature idea:** content first. Navigation floats at the bottom, and only the
active item shows its name; the top strip is identity only.

```
1440                                             390
┌──────────────────────────────────────────────┐ ┌──────────────────────┐
│ TR TrueReport  Marina W.        EN|ع 🔔 LH   │ │ TR Marina W. EN|ع LH │
├──────────────────────────────────────────────┤ ├──────────────────────┤
│                                              │ │ (content)            │
│ 24 jobs on the floor                         │ │                      │
│ 4 are waiting for your decision              │ │                      │
│ ▁▂▃▄▅  partition + list                       │ │                      │
│                                              │ │                      │
│          ┌────────────────────────────┐      │ ├──────────────────────┤
│          │▣Overview 📁 👥 ▦ 🗂 ⚙     │      │ │▣Overview 📁👥▦🗂⚙  │
│          └────────────────────────────┘      │ └──────────────────────┘
└──────────────────────────────────────────────┘
```

**Structural departures:** a 44 px identity strip replaces the 60 px top bar; no
sidebar and no tab band; the dock is the only navigation surface at every size;
the active item expands to reveal its label (a motion verb, not a colour change);
identity appears exactly once.

**Type + colour character:** product-software, quiet: hairline strip, one filled
dock pill, monochrome icons. Reference energy: iPad-class bottom navigation,
Arc's floating toolbar.

**Rendered:** `c-dock-1440.png`, `c-dock-390.png`, `c-style-tile.png`.

**Trade-off:** unconventional for a desktop admin tool — six items floating at
the bottom centre is a reach for mouse users, and the dock overlays the last ~90 px
of content (a bottom padding contract every screen must honour).

---

## Comparison

| | A The spine | B The ledger | C The dock |
|---|---|---|---|
| Navigation surface | 84 px icon rail + phone bottom bar | 64 px tab band | floating dock, all sizes |
| Identity shown | once (command bar) | once (tab band) | once (top strip) |
| Desktop width given back | ~170 px | ~256 px | ~256 px |
| Tools placement | command bar (search + language) | tab band end | thin strip |
| Phone cost | 6 tiny labels | scrolling strip | dock with expanding label |
| Global search | yes | no | no |
| Risk | icon recognition | tab overflow at 1024 | unusual for desktop |

All three: one identity, one language control that is visible, no invented
counts (no notification badge — there is no count), no second scroll owner, and
the six destination keys unchanged.

---

## What happens after the choice

1. `docs/ui_brief.md` (shell section) — per-breakpoint layout, every state,
   microcopy, acceptance checklist, structural departures.
2. Phase 4-lite confirms the harness (already proven by these renders).
3. Phase 5 builds the chrome primitives and a gallery (nav item × states × LTR/RTL).
4. The mini Brief rewrites `workshop_shell.dart` into `shell/` region files, keeps
   `WorkshopAppShell`'s public constructor, and executes the kill list in
   `docs/audit-shell.md` §6.
