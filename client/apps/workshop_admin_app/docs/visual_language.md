# Visual language — Workshop Admin sign-in

Phase 5 for direction **B · The bay**. The idea below is **committed**; Gate 5
needs the gallery proof in `docs/evidence/gallery/` before approval.

## The committed signature: "The bay window"

The screen is divided by a hard edge: a paper door on the left (46 %) and an
**inspection surface** on the right (54 %), full-bleed, no radius, on ink. The
surface carries exactly one **labelled example job, frozen mid-inspection**:

- `EXAMPLE JOB` + a 6 px dot,
- `2023 Porsche 911 GT3`,
- `DXB 48291 · Rashid Al Mansoori`,
- a **real top-down chassis drawing**, tinted `onAccent @ 26 %`,
- `Inspection checklist` + `18 of 24 items · 75 %`,
- a **24-tick spine**, 18 filled,
- the technician, their role and elapsed time.

It earns its place because:

1. It shows the product's core object — the vehicle under inspection — instead of
   a slogan about it.
2. It reuses the vocabulary of a job card (plate, customer, checklist count,
   technician, elapsed) so the screen is a promise the app keeps one click later.
3. It is honestly labelled **Example job** in copy and announced as an example to
   assistive tech.
4. It gives the screen exactly one memorable moment, and the ticks are the only
   thing that moves.

Restraint rule: accent appears exactly **two** ways on the door — the
`WORKSHOP ADMIN` eyebrow and the primary button. On the ink surface the ticks are
`onAccent` white, because a green tick on ink fails contrast.

## What this screen must never look like

- A SaaS landing page: no gradient hero, no "trusted by", no logos, no badges.
- The **rejected pattern**: a coloured slab with a white example-job card
  floating on it (that is what the previous run built, and why it was sent back).
- A Material demo: no `ElevatedButton`, no default `Card` elevation, no `AppBar`.
- A stock admin template: no card-in-card, no three equal white boxes.
- A dashboard teaser: no fake counters, no "coming soon", no disabled chrome.

## Type

Inherits `WorkshopTokens.standard` (Plus Jakarta Sans + the Arabic fallback
chain). No new sizes were added — the display scale is `ws.heroNumber` (40/44),
which the design system already exposes.

| Role | Size / line | Weight | Source |
|---|---|---|---|
| Page title | 40 / 44 | 700 | `ws.heroNumber`, tracking −1.2 |
| Example vehicle | 30 / 38 | 700 | `ws.pageTitle`, on ink |
| Eyebrow (`WORKSHOP ADMIN`, `EXAMPLE JOB`) | 11 / 16 | 600–700 | `ws.eyebrow`, tracking 1.4 |
| Subtitle / body | 14 / 21 | 400 | `ws.body` |
| Field label | 14 / 21 | 600 | `ws.bodyStrong` (inside `WorkshopTextField`) |
| Meta (plate, customer, technician) | 12.5 / 18 | 500 | `ws.meta` |
| Progress figure | 19 / 26 | 700 | `ws.sectionTitle` |

Numbers use `FontFeature.tabularFigures()`. Arabic tracking is already zeroed by
the token factory. Nothing below 11 px; body never below 14 px.

## Colour roles

| Role | Token | Used for |
|---|---|---|
| Canvas | `ws.canvas` `#F7F5F1` | the door |
| Surface | `ws.surface` `#FFFFFF` | fields only |
| Ink | `ws.ink` `#1B1C19` | inspection surface, headings |
| Muted | `ws.muted` `#6A6F6A` | labels, help, meta |
| Border | `ws.border` `#E6E2DA` | hairlines, field outline |
| Accent | `ws.accent` `#0B6B4F` | eyebrow, primary button |
| On accent | `ws.onAccent` `#FFFFFF` | all type and the drawing on ink |
| Danger | `ws.danger` / `dangerSoft` | failure banner only |
| Focus | `ws.focus` `#0B63CE` | focus halo only |

No `Colors.*` or `Color(0x…)` anywhere on this screen; A1–A3 enforce it.

## Space, radius, elevation

- Spacing tokens only: `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · massive 64`
  (`TrSpacing.massive` is 64, not 48 — corrected after Gate 6).
- Left gutter 88 (`massive + xl`) at ≥1200, 64 below.
- Radii: fields/buttons `controlRadius 10`; nothing on the ink surface.
- **Elevation: none.** The screen has no shadow. Depth comes from the hard
  canvas/ink edge, not from floating surfaces.
- The grid on the ink surface is a 56 px hairline at 5 % white — texture, not
  ornament.

## Motion

| Element | Spec |
|---|---|
| Tick spine | 24 ticks fill over 400 ms, `easeOutCubic`, once, on first paint |
| Form column | fade 0→1 + translateY 8→0, 180 ms, once |
| Button loading | crossfade label→spinner, 120 ms, no layout shift |
| Field focus | ring + border colour, 140 ms (`WorkshopTextField`) |
| Failure banner | 6 px rise + fade, 180 ms, announced once |
| Reduced motion | every duration above becomes zero; no exceptions |

Nothing loops. No shimmer. No count-up numbers — the figure is static text; only
the ticks move.

## Dark theme — waived, not skipped

The app is light-only by product decision (`AppTheme.build` asserts
`Brightness.light`; `ui_matrix_test` pins it). This rebuild does not invent a
dark palette for one screen. Waiver **W-LIGHT** is countersigned in
`docs/waivers.md` (owner Syed Moiz, expiry 2027-02-18).

## RTL

- The whole split mirrors: form right, inspection surface left.
- **The chassis drawing never mirrors.** `WorkshopChassisMark` pins its own
  `Directionality.ltr`; a mirrored car is a credibility bug.
- Model, plate and customer are wrapped in LTR so bidi cannot reorder
  `DXB 48291`. The technician string keeps the Latin name first.
- **The progress figure is deliberately not isolated.** It originally carried an
  `LRI…PDI` pair around the percent (added when the phrase was force-pinned LTR).
  Once the base direction became RTL, that isolate made the Arabic renderer drop
  the percent entirely — reserved advance, nothing painted. The isolate was
  removed and the phrase now orders correctly from the ambient direction.
  Rule: isolate *values*, never a sentence; and verify the glyphs, not the string.
- Pattern, technician row and checklist label mirror with the page.
- All padding uses `EdgeInsetsDirectional`.

## Gallery findings (Gate 5 evidence review)

The gallery was captured before approval; it exposed these, which is why the gate
comes after the proof:

1. **`WorkshopTextField` cannot render an error outline.** Accepted:
   message-only error state, which the copy makes specific and announced. Fixing
   it needs `workshop_ui.dart`, which is write-locked.
2. **The design-system barrel is write-locked** (`components.dart` carries an
   explicit deny ACL). New primitives are therefore app-local, not forced into a
   shared package by editing ACLs. No existing component was modified.
3. **The gallery needed 1240 px of height** to show every state; at 820 px the
   tick spines fell below the fold. Captured at 1280 × 1240.
4. **The chassis SVG's baked greys** (`#C7C5D3`, `#10B981`) must never leak: it is
   rendered through `srcIn`, and the tint is the only colour that survives.

## Gate 6 findings and fixes (2026-11-18)

The independent reviewer failed the first pass. All four blocking findings were
real and are fixed here; the gallery and state captures were regenerated.

| ID | Finding | Fix |
|---|---|---|
| B1 | No language control on any ≥900 px width — Arabic was unreachable on desktop | `SigninLanguageToggle` now sits top-right in the 46 % column, declared after the form so it stays the **last** tab stop |
| B2 | Arabic count phrase inverted (forced LTR base read "24 of 18") | `_ltr` removed from the progress figure; the ARB's own percent isolation carries it. Regression test: `AR progress figure keeps an RTL base direction` |
| B3 | Submitting state had no announcement and its capture showed an invisible grey spinner on green | New `SigninSubmitButton`: stays accent-filled, `onAccent` spinner, live-region announcement (`signingIn`, new l10n key, never shown). Capture now settles (two pumps) |
| B4 | 768 px was two axes (brand at 16, form at 124) with half the viewport blank | The band's content shares the form's 520 column at ≥600 px; the door stays top-weighted |

Polish adopted from the same review: the checklist figure is flush right again
(`Expanded` label, not `Flexible` + `Spacer`, which had split the free space and
wrapped the Arabic phrase); the surface is a `Positioned.fill` child so it spans
instead of sizing to its widest child; the band's drawing is hidden below 600 px
and at ≥1.5× text (it was a smudge behind the toggle); the duplicate "Workshop
Admin" on the door is gone (mark sub-label suppressed at split widths); the tick
spine is decorative because the figure is visible beside it; field gap is `lg`;
the form and the banner animate as specified; the rejected-direction preview
route was deleted.

Deliberately **not** changed: email still autofocuses at split widths (the blue
focus ring is the token's focus colour, not a style choice), and
`WorkshopTextField` still cannot draw an error outline (write-locked primitive).

## Primitive inventory

| Primitive | Where | Variants used |
|---|---|---|
| `WorkshopTextField` | design_system | default, focused, error, disabled, obscured + suffix |
| `WorkshopAvatar` | design_system | 24 px, initial-only |
| `WorkshopGridPainter` | design_system | ink texture, 5 % white |
| `SigninSubmitButton` | **app**, `signin/signin_submit_button.dart` | idle, in-flight (accent fill + white spinner + live region), disabled |
| `SigninLanguageToggle` | **app** | on canvas, on ink |
| `SigninMark` | **app** | on canvas, on ink, portal label shown/hidden |
| `WorkshopChassisMark` | **app**, `signin/signin_primitives.dart` | 340 px wide, 26 % on ink; 60 px in the tablet band |
| `WorkshopTickSpine` | **app**, same file | 0 / 18 / 24 of 24; animated and static |

`WorkshopButton` is **not** used here any more: its loading variant drops the
accent fill, which made the only primary control vanish exactly when the user
needed to see progress. `WorkshopCard` and `WorkshopStatusBadge` are not used —
the floating card and the "In progress" pill are part of the rejected pattern.

## Asset manifest

| Asset | Source | Use |
|---|---|---|
| `.../icons/figma/Minimalist_SVG_Top-Down_Car_Chassis-1_8499.svg` | existing (2.8 kB) | the inspection surface, tinted `onAccent` |
| Wordmark | typographic `TrueReport` + `TR` tile | no logo asset exists; do not invent one |

No photography, no illustration, no new binary asset.

## Kill list — what this language deletes

| Deleted | Was |
|---|---|
| `_BrandPanel` | the coloured 50 % slab with a headline |
| `_ExampleJobCard` | the white card floating on the slab |
| `_BrandBar` | the phone header bar |
| `_Lockup` | replaced by `SigninMark` (accent-aware) |
| `_buildForm` (inline) | replaced by `SigninForm` |
| `WorkshopCard` on this screen | card-in-panel composition |
| `WorkshopStatusBadge` "In progress" | decoration on the card |
| `WorkshopButton` (on this screen) | its loading variant dropped the accent fill |
| `LinearProgressIndicator` | replaced by the 24-tick spine |
| `lib/preview/signin_directions.dart` | the rejected-direction preview route (dead code after Gate 3) |
| `signInHeadline` / `signInBrandLine` renders | the marketing promise line |

The keys stay in the ARB for other surfaces; only this screen stops rendering
them.

## Self-review before asking for approval

1. One focal point? The example job on ink, then the form. ✔
2. Mistakable for Material / a template? No card, no AppBar, no elevation. ✔
3. Signature visible but restrained? One drawing, one tick spine, one animation. ✔
4. Empty area > 200 px undesigned? The form column is top-weighted by design;
   the ink surface carries the right half at every split width. ✔
5. Any fabricated number presented as live? Everything is under `EXAMPLE JOB`
   and announced as an example. ✔
6. Does it survive 390 px? The surface collapses to a band; the first field is
   still above the fold at 360 × 800. ✔
7. Does it look like the screen we sent back? No: the slab, the card with a
   shadow, the progress bar and the paper promise line are all gone. ✔
