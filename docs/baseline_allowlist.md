# Baseline allowlist — technician app jobs module

Recorded before the rebuild (Phase 0). Anything here is pre-existing and does not trip a gate.
Anything **not** here that appears later is a new failure and stops the pipeline.

## Commands and results (2026-11-25)

| Check | Command | Result |
|---|---|---|
| Analyzer | `flutter analyze` in `client/apps/technician_app` | **0 issues** (85.8 s) |
| Tests | `client/apps/technician_app/test/` | **directory does not exist** — no unit, widget, golden or integration test in this app |
| Literal gate | `node tools/gate_all.js` (repo root) | fails on **9** pre-existing user-visible literals: `platform_identity_strip.dart:356`, `api_client.dart:384-458` |
| Backend | `GET localhost:8080/actuator/health` | UP |

## Pre-existing UI defects observed on the real build

Captured at 390×844 and 768×1024 against the local API (`tech.a@truereport.test`).

1. **Past-dated assigned work is unreachable.** The day rail starts at today (25 Nov) and runs forward;
   the seeded technician has 20 jobs, all scheduled 23 Nov (11 `ASSIGNED`, 8 `CANCELLED`, 1 `PUBLISHED`).
   The empty state says "Pick another day", but no earlier day exists in the rail. `jobs_queue_format.dart:137`
   already models past/upcoming sections — the clean page does not use them.
2. **Weekday label disagrees with the day rail.** At 390 px the header reads "Today, Tuesday 25 Nov" while
   the same screen's rail marks 25 Nov as **WED**; at 768 px the header drops the weekday and reads
   "Today, 25 Nov". Two responsive variants paint the header differently.
3. **Category rail clips silently.** "Suspension, Steering & Un…" at 390 px, "Electrical, Ba…" at 768 px,
   with no scroll affordance or overflow count.
4. **Repeated status noise.** Every item row carries the same "Not checked" pill; the only differentiator
   is the safety-critical pill on item 04, which is hidden at 390 px because the instruction line and pill
   do not fit.
5. **Duplicated next action.** The sticky bar ("NEXT UP — Engine Oil Condition & Level / Start") repeats
   item 01, which is the row directly above it.
6. **Tablet is a stretched phone.** Single 720 px column, ~400 px of dead space, no use of width for
   category context, progress or the remaining categories.

## What this means for gates

- Gate 6 must not report "no new overflow" as success while reproducing 1–6 unchanged; 1, 2 and 3 are
  explicitly in scope.
- Any new test suite is additive: there is no existing test to weaken.
