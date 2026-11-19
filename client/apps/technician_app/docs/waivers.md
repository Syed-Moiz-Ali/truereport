# Waivers — technician sign-in rebuild

| ID | Gate | What is waived | Why | Owner (human) | Expiry | Status |
|---|---|---|---|---|---|---|
| **W-LIGHT** | 5, 6 | Dark-theme primitive gallery and dark screenshots | The technician app is light-only by product decision: `AppTheme.build` asserts `Brightness.light` (`tokens.dart:739-748`). Producing a dark gallery would require a theme the app cannot render | Syed Moiz | 2027-02-18 | **approved at Gate 5** (2026-11-19) |
| **W-SIGNIN-WEB** | 6 | A live-browser walk on a device/emulator | This environment has no running app target; evidence is real-font widget captures at every specified viewport plus the full test suite | Syed Moiz | 2026-12-19 | **approved with Gate 6 closure** (2026-11-19) |

Rules: a waiver needs a named human owner and an expiry; an expired waiver fails
its gate again. The agent proposes; it never approves its own waiver. W-LIGHT was
countersigned by the Gate 5 approval; W-SIGNIN-WEB stays proposed until the user
accepts the Gate 6 evidence basis.
