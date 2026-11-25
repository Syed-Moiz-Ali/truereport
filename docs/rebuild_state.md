# Rebuild state — technician jobs module

```
Path:            full (module-restricted)
Module:          technician_app jobs — /jobs, /jobs/:id, items, summary, signature, completed
Direction:       RE-OPENED. The first W2 build (queue + deck) was rejected by the user as
                 "not a mobile app". Three structurally different directions were designed and
                 rendered as proofs; none is in production yet.
Directory:       A — FOCUS (user pick, 2026-11-25)
Current phase:   6 (W3 production build)
Gates:           0 PASS · 1 PASS · 2 PASS · 2b PASS
                 3 PASS (A chosen from three rendered directions)
                 5 PASS-by-inheritance
                 6 PENDING (ramp queue + job session building; wiring after)
Artifacts:       docs/briefs/brief-3.md · docs/design/proofs/*.png · lib/preview/** (delete after build)
Next allowed action: integrate ramp page + job session into the router/workspace, delete the W2 queue/deck,
                 capture 390/768/1024 + AR, run the resume→answer→evidence→offline→finish flow proof.
```

## Decisions on record

- Visual language (Plus Jakarta Sans, brand ink, rounded cards) is **kept**; only structure changes.
- Past-dated assigned jobs must be reachable (`UNFINISHED` section), cancelled hidden by default.
- Job detail keeps the ledger + derived footer verb; the duplicate summary entry point goes.
- 15 dead screens are deleted, not migrated (~5,350 lines).
- Tests: none exist (deleted in `a8197d6`); W1 adds harness + characterization tests, CI gains `flutter test`.
