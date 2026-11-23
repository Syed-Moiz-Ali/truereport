# BUGS.md — TrueReport Audit

## Summary
- Open bugs: 0
- Fixed bugs: 0
- Need-decision items: 0

No bugs were found during the end-to-end Playwright + backend + Flutter test sweep.
All screen sweeps, module flows, cross-app flows, API sweeps, backend tests, and
Flutter tests pass.

## Notes
- Environment issues (static server connection drops during very long full-suite
  runs) were worked around by running specs in smaller batches; not application bugs.
- Public report flow tests 2 and 3 were skipped because `E2E_PUBLIC_REPORT_TOKEN`
  / `E2E_PUBLIC_REPORT_LANG` are not provisioned in the local seed. The unknown-token
  path (test 1) was executed and passed.
