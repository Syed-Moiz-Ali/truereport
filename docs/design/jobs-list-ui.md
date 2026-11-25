# Jobs list — UI pass (flow locked)

Screen: `/jobs` only. No route, provider, API, filter, pager or callback changes. No new screens.
Order after the checklist is **summary → signature → complete** (already true; do not touch).

## User and job

Technician, one hand, gloves, bay-door glare, 4–8 cars a day. The list must answer in one glance:
**which car is mine now, what is next, and how much is left.** No help text.

## Hierarchy (what the eye gets, in order)

1. The job that is live / next due (selected day, first row).
2. The other jobs of the day (time, vehicle, plate, items).
3. The day rail (navigation, not content).
4. Search / filter (available, quiet).

## Rules

- Keep the existing day rail, filters, search, pager and empty/error/offline states. Restyle only.
- One card surface per day list, hairline separators, no nested cards.
- Row: 78 px minimum; time gutter (14.5/800, `NOW` tag on the live row), vehicle 16/700 (2 lines max, never ellipsised), plate chip + `customer · reference`, status chip, `n of 30 items`, chevron. Whole row tappable; 44 px minimum everything.
- Status never colour-only; numbers always with a unit; no raw enums or ISO dates.
- Tokens only (`context.colors/brand/texts/statusColors`, radii 14/16/999); 4/8 rhythm; no raw hex, no literals — `TechnicianKeys` only.
- States: loading skeleton that mirrors the rows; empty (no jobs on this day) with the nearest day named; error + Retry; offline note; filter-active state.
- RTL: directional insets, mirrored chevrons, no clipped text. 1.5× text must not overflow.
- Motion ≤ 240 ms, respects reduced motion.

## File ownership (one writer per file)

| Owner | File |
|---|---|
| Main | `technician_jobs_clean_page.dart` (header, search, filter sheet, assembly) |
| Agent A | `jobs_queue_agenda.dart` (rows) |
| Agent B | `jobs_queue_week.dart` (day rail) |
| Agent C | `jobs_queue_primitives.dart` (chips, plate, progress, search field, skeleton, empty/error/note, buttons) |

Public widget names and constructor signatures in primitives must not change (A and Main import them).
