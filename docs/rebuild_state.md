# Rebuild state — technician jobs module

```
Path:            full (module-restricted)
Module:          technician_app jobs — /jobs, /jobs/:id, items, summary, signature, completed
Direction:       RE-OPENED. The first W2 build (queue + deck) was rejected by the user as
                 "not a mobile app". Three structurally different directions were designed and
                 rendered as proofs; none is in production yet.
Current phase:   3 (design directions) — proofs complete, awaiting the user's pick
Gates:           0 PASS · 1 PASS · 2 PASS · 2b PASS (15 files / 15,021 lines deleted; 42 tests; analyze 0)
                 3 IN REVIEW (three rendered directions, 390 + 768, real fonts/icons)
                 5 PASS-by-inheritance (visual language unchanged)
                 6 PENDING
Artifacts:       docs/design/directions-brief.md
                 docs/design/proofs/{a,b,c}_{queue,job}_{390,768}.png (+ c_job_390_sections.png)
                 client/apps/technician_app/lib/preview/ (throwaway; delete after the pick)
Tests:           88 pass (42 characterization + 46 preview/layout/interaction), analyze 0, gate_all unchanged at 9
Data fix:        preview fixture corrected 12 → 9 answered items so no direction renders a false count
Open waivers:    none
Next allowed action: user picks A / B / C (or A+B hybrid) → rebuild queue + job session against it,
                 delete lib/preview and the old W2 screens, capture the full matrix, flow proof.
```

## Decisions on record

- Visual language (Plus Jakarta Sans, brand ink, rounded cards) is **kept**; only structure changes.
- Past-dated assigned jobs must be reachable (`UNFINISHED` section), cancelled hidden by default.
- Job detail keeps the ledger + derived footer verb; the duplicate summary entry point goes.
- 15 dead screens are deleted, not migrated (~5,350 lines).
- Tests: none exist (deleted in `a8197d6`); W1 adds harness + characterization tests, CI gains `flutter test`.
