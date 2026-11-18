# Evidence index

Every image here is a **real-font** capture (`test/flutter_test_config.dart` loads the bundled
Plus Jakarta Sans / Noto Sans Arabic). Ahem (solid boxes) can never appear: `test/font_harness_test.dart`
fails if the measured glyph width matches Ahem's square metrics.

| Path | What it proves |
|---|---|
| `phase-4-signin-smoke.png` | Gate 4: the font harness renders real glyphs. It still shows the old page with the plate as black bars — proof the capture is real, not a mock. |
| `gallery/gallery_ltr_light.png` | Gate 5: every primitive × state the rebuild composes (text field default/focused/error/disabled/obscured, button primary/loading/ghost/disabled, status badge, avatar, example card, brand surface). |
| `gallery/gallery_rtl_light.png` | Gate 5: the same in Arabic/RTL. It intentionally shows the pre-fix bidi defect (`24 / 18`, `% 75`, `Porsche 911 GT3 2023`) that the rebuild then fixed. |
| `states/signin_error_1280_en.png` | Error state, desktop: inline banner above the button, email preserved, form still usable. |
| `states/signin_error_1280_ar.png` | The same in Arabic, mirrored, with localized copy. |
| `states/signin_network_error_390_en.png` | Network failure state on a phone. |
| `states/signin_submitting_1280_en.png` | In-flight state: button replaced by a spinner, control disabled, no layout shift. |
| `states/signin_validation_390_en.png` | Both fields invalid: specific messages, no request sent. |
| `states/signin_textscale150_390_en.png` | 1.5× text on a phone: everything wraps, nothing clipped. |
| `states/signin_textscale200_1440_en.png` | 2× text on desktop: panel and card reflow, the technician line wraps instead of truncating. |
| `../test/screenshots/real/workshop_signin_*.png` | Default state at 1440/1280/1024/768/390/360 EN + 1280 AR. |

## Known limitations carried forward (not defects hidden, defects accepted)

1. **Field error message sits inside the field outline**; the outline does not turn red.
   `WorkshopTextField` owns that decoration and is ACL-locked. The message is specific, inline and
   announced, so the state is not colour-only. Follow-up: unlock `workshop_ui.dart` and add an
   error-aware outline.
2. **Dark theme** — waived (W-LIGHT); the whole app is light-only by decision.
3. **The example job is fabricated** — approved at Gate 0, labelled "Example job", announced as an
   example.

## How to regenerate

```
cd client/apps/workshop_admin_app
flutter test test/workshop_real_font_screenshot_test.dart   # default states
flutter test test/signin_states_capture_test.dart           # error/submitting/validation/large text
flutter test test/gallery_signin_primitives_test.dart       # gallery
flutter test test/smoke_signin_capture_test.dart            # Phase 4 smoke
git checkout -- test/screenshots                            # keep the tree clean
```

The 77 PNGs in `test/screenshots/real/` are rewritten by any `flutter test` run. That is Finding
F7 (unasserted churn), waived at Gate 6 as W-SCREENSHOTS; every capture used here is reviewed
deliberately, and the tree is restored afterwards.

**Observed during this rebuild:** after the suite ran, 32 non-sign-in captures (jobs, job detail,
reports, settings, …) differ from HEAD — and a pixel diff of `workshop_jobs_1024.png` shows the
only visual change is the "All (1)" filter chip's tint, i.e. a 120 ms `AnimatedContainer` caught at
a different phase of its animation. Nothing in those screens was edited. That is exactly the
failure mode F7 warns about: an unasserted capture cannot distinguish a regression from a timing
artifact. Those 32 files were reverted; only the 7 sign-in captures are part of this change.
