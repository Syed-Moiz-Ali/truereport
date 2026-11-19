# Blocked / parked modules

**Run status: HALTED** — the jobs module failed independent Gate 6 judgement twice
(`docs/evidence/jobs_j1/qa_verdict.md`, `qa_verdict_round2.md`).

Threshold: more than 2 parked modules halts the run; this halt is the
"same module fails judgement twice" rule.

| Module | Reason | Since | Next action |
|---|---|---|---|
| jobs (J1 queue + detail + archive) | Gate 6 FAIL r1 → remediated → FAIL r2. Remaining blocker N1 (2x/1440 queue breaks the primary label and splits words) and major N2 (consent-blocked detail has no checklist link). | 2026-11-19 | Fix N1 + N2, attach raw logs, re-run Gate 6 in a new run. J2/J3 not started. |

## Not started (blocked by the halt)

- J2 — write path: wizard, approve, publish checklist, documents.
- J3 — client surface: board (shell F2/F6/F8), notifications, public-link polish.
- Integration pass: content-frame consistency (shell F7), shell log regeneration (F4),
  cross-module screenshot review.
