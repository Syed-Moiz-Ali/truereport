# Visual language — dashboard, direction B "The floor"

Committed at Gate 3 (user). This is the language the rebuilt dashboard speaks.
The app-wide language (sign-in wave) is unchanged; this file adds the one idea
and the one extra type role the dashboard needs, and names what it replaces.

## 1. The idea (committed, not a proposal)

**The partition is the page.** One full-width band of nine real status counts is
the largest object after the total; the legend beneath repeats exactly those nine
numbers (it is a legend, not a ruler — labels are not aligned to segment widths,
because a proportional bar cannot carry readable labels for 1/24 buckets); the
total is never inferred. Nothing is a card inside a card.

The page reads like a printed operations sheet: an eyebrow, one enormous number,
one sentence that makes it personal, one band, three lists, one baseline.

## 2. Tokens

No new colour, radius or spacing token. Everything comes from
`context.ws` / `context.spacing` (design-system `WorkshopTokens`).

Added (app-local, because the design-system barrel is write-locked):

| Token | Value by width | Role |
|---|---|---|
| `DashboardScale.totalSize` | 76 / 64 / 56 / 48 / 40 (≥1200 / ≥1024 / ≥900 / ≥768 / <768) | the total numeral |
| `DashboardScale.totalLetterSpacing` | −2.4 / −2 / −1.6 / −1.2 / −1 | optical tracking of the big figure |
| `DashboardScale.atlasHeight` | 64 / 56 / 48 / 0 / 0 | horizontal bar height; 0 means spine |
| `DashboardScale.gutter` | 40 / 32 / 32 / 20 / 16 | page gutter (matches `pageGutter`) |
| `dashboardStatusColor(status)` | see `dashboard_style.dart` | the nine-segment sequence |

Type roles in use: `pageTitle` (numeral, via `dashboardTotalStyle`), `sectionTitle`
(group titles), `bodyStrong` (row titles), `body`, `meta`, `eyebrow`.

### The colour sequence (data, not decoration)

```
DRAFT      ink 18 %     ─ neutral, not started
SCHEDULED  ink 32 %
ASSIGNED   accent 40 %
IN_PROGRESS accent      ─ the bay
PENDING_REVIEW warning  ─ the only warm colour: this is the decision stage
APPROVED   success 45 %
PUBLISHED  success
REJECTED   danger 55 %
CANCELLED  danger 25 %
Other      muted 45 %   ─ only when total > sum(nine)
```

Rules: colour is never the only signal (every segment is labelled and has a
semantics label); `warning` appears exactly once on the page (the decision
stage) so it cannot be mistaken for a decoration; red appears only at the tail of
the bar, never on an action.

## 3. Primitives (built and gallery-proven)

| Primitive | File | States proven |
|---|---|---|
| `DashboardAtlas` | `widgets/dashboard_atlas.dart` | horizontal, remainder ("Other"), phone spine, RTL |
| `DashboardGroupHeader` | `widgets/dashboard_rows.dart` | default, RTL |
| `DashboardJobRow` | `widgets/dashboard_rows.dart` | verb inline, verb under meta, no verb, RTL |
| `DashboardGroupEmpty` | `widgets/dashboard_rows.dart` | empty group |
| `DashboardHeroSkeleton` | `widgets/dashboard_states.dart` | loading |
| `DashboardAtlasSkeleton` | `widgets/dashboard_states.dart` | loading |
| `DashboardRowsSkeleton` | `widgets/dashboard_states.dart` | loading |
| `DashboardErrorLine` | `widgets/dashboard_states.dart` | bounded error + retry, no numbers |

Gallery evidence: `docs/evidence/gallery/dashboard_*.png`
Contact sheet: `docs/evidence/gallery/dashboard_index.html`

## 4. Elevation and surfaces

No elevation anywhere on this page. No cards. Groups sit on the canvas separated
by hairlines (`ws.border`). The only filled surfaces are status pills (DS badge)
and the single primary button. Hover on a row = `ws.canvas`; focus = `ws.accentSoft`.

## 5. Motion

One motion, once: the partition grows from the reading start edge over 260 ms
(`easeOutCubic`) on first paint. Nothing else animates; rows do not stagger;
numbers do not count up. `ReduceMotion.duration` collapses it to zero when the
platform asks for reduced motion.

## 6. RTL

- The atlas mirrors: `DRAFT` starts on the right in Arabic. `Align` uses
  `AlignmentDirectional`, so the growth animation also mirrors.
- The numeral, references and dates are LTR-pinned (`TextDirection.ltr`,
  tabular figures).
- Row verbs sit at the inline end; the `→` glyph mirrors to `←` automatically
  through the icon's matchTextDirection.
- Arabic type uses `letterSpacing: 0` from `WorkshopTokens.standard(isArabic: true)`.

## 7. Dark theme

Waived (W-LIGHT, countersigned). This screen must not invent a dark palette;
`ui_matrix_test` pins light-only.

## 8. Kill list (named, executed in the mini Brief)

Deleted from the page and from the codebase once the build lands:

| Symbol | Where it lives today | Replacement |
|---|---|---|
| `_PageColumn` | `dashboard_tab.dart` | page padding from `DashboardScale` |
| `_MetricStrip` (+ `WorkshopMetricStrip` usage) | `dashboard_tab.dart` | `DashboardAtlas` legend |
| `_DashboardBody` | `dashboard_tab.dart` | page composes the three groups |
| `_UpcomingCard`, `_nearestUpcoming` | `dashboard_tab.dart` | deleted (no schedule ordering exists) |
| `_RecentJobsCard` | `dashboard_tab.dart` | three status groups |
| `_PipelineAndActions`, `_PipelineCard`, `_PipelineBody`, `_PipelineLegend` | `dashboard_tab.dart` | `DashboardAtlas` |
| `_QuickActionsCard`, `_QuietAction` | `dashboard_tab.dart` | deleted (the shell navigates) |
| `JobListRow` as used here | `job_widgets.dart` (shared with the queue) | `DashboardJobRow` (the queue keeps its own) |
| legacy imports: `job_counts.dart`, `JobCounts`, `jobsProvider`, `jobCountsProvider` | `dashboard_tab.dart` | `cleanJobCountsProvider`, `cleanJobsProvider` |

`formatNumber(BuildContext, int)` stays exported from `dashboard_tab.dart`
because five other screens import it from there; deleting it would be a rename,
not a simplification.

## 9. Gate 5 evidence

Order executed: build tokens/primitives → gallery capture → **user approval**.

- Gallery, light, LTR + RTL: `docs/evidence/gallery/dashboard_*.png` (11 files)
- Contact sheet: `docs/evidence/gallery/dashboard_index.html`
- Every primitive × every state it can take is in that set; dark is waived.

Gate 5 verdict: **awaiting user approval** (contact sheet in the Review pane).
