# Waivers

A waiver is a bounded exception with a named human owner and an expiry date. The agent proposes;
it never approves its own waiver. An expired waiver fails its gate again.

| ID | Gate | What is waived | Why | Owner (human) | Expiry | Status |
|---|---|---|---|---|---|---|
| W-LIGHT | 5 | Dark-theme gallery and dark screenshot evidence | The app is light-only by an earlier product decision: `AppTheme.build` asserts `Brightness.light` (`tokens.dart:736-748`), `darkTheme` is not wired in `app.dart`, and `ui_matrix_test.dart` now pins that with a test. Rebuilding one screen must not invent a dark palette. | Syed Moiz | 2027-02-18 | **IN FORCE — countersigned 2026-11-18** |
| W-NOTOTP | 3 | A TOTP / code-entry state on the sign-in screen | `source_scan_test.dart:248-264` bans any code-entry surface in this app, and `ADMIN_TOTP_REQUIRED` defaults to false (`application.yml:80-81`). The screen must show a localized message instead of an input. | Syed Moiz | 2027-02-18 | **IN FORCE — countersigned 2026-11-18** |
| W-SCREENSHOTS | 6 | Asserting the 77 committed PNGs in `test/screenshots/real/` as goldens | The suite rewrites them on every run and asserts nothing (Finding F7). Making them goldens is a repo-wide QA decision, not a sign-in decision. Mitigation: evidence is regenerated deliberately and reviewed; the tree is restored after each run. | Syed Moiz | 2026-12-31 | **proposed — countersign at Gate 6** |

None of these is in force yet. If the user rejects one, the pipeline does not proceed past its gate.
