# F2-A accessibility and i18n review

**Phase:** F2-A (Technician app, screens 1 to 7)
**Reviewer:** lead self-review (the a11y-i18n-reviewer subagent run was cancelled in this session; no subagent result is claimed)
**Date:** 5 November 2026
**Verdict:** **conditional** — automated matrix passes; real-device screen reader and native Arabic review remain outstanding.

## Automated evidence

- `test/f2a_screens_test.dart`: each built screen renders at **360 / 390 / 600 / 900** logical width and **1.0x / 1.5x / 2.0x** text in **English and Arabic**, with no overflow.
- Same test: reduce-motion render; 56 dp primary login action; 48 dp dock; source scan for raw colours/sizes/radii/shadows/URLs/endpoints; product forbidden-term lint.
- `test/f2a_goldens_test.dart`: 12 EN/AR light goldens. `test/f2a_goldens_dark_test.dart`: 6 derived dark goldens (separate file).
- `test/f2a_fidelity_capture_test.dart`: 12 measured captures. `test/f2a_screenshots_test.dart`: 24 EN/AR 1.0x/2.0x screenshots.
- Existing consent tests still pass (explicit, unselected start, no record before Save).

## Findings and status

| Area | Finding | Status |
|---|---|---|
| Targets | App buttons/dock/fields use the 48 dp minimum; primary technician CTAs use 56 dp. The ring and status pills are non-interactive. | Pass |
| Focus | `AppTextField` paints the F1 focus ring; `AppButton`, icon buttons, chips and dock items paint the focus token. The login fields and CTA are keyboard reachable. | Pass (code/test) |
| 2.0x | Full matrix passes at 360–900 width. The coverage ring centre uses `FittedBox.scaleDown`; job-card status chips move below the title; `TechnicianSectionTitle` trailing content is `Flexible`; the login language pill uses `Wrap`. | Pass |
| RTL | Directional `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadius` and `Wrap` are used. VIN, plate, odometer and ring numerals are explicitly LTR. The app builds the Arabic theme with `AppTheme.build(isArabic: true)`. | Pass (structural) |
| Directional icons | Chevrons/back arrows use Material direction-aware icons; the custom vehicle silhouette is non-directional. No screen-level mirroring regression found. | Pass |
| Semantics | Icon-only actions have labels (`AppIconButton`), consent choices expose button/selected state, module cards are tappable cards with text, status chips expose their label, and the coverage ring has an explicit “N of M checks done” semantic label. | Pass |
| Reduce motion | `context.motionDuration` honours `MediaQuery.disableAnimations`; the loading skeleton settles rather than repeats. | Pass |
| Contrast | P2 field boundary is **1.10:1 light / 1.18:1 dark** and is accepted with a visible label + focus ring. P1 large label is **3.77:1** at 19 px bold (large-text 3:1). All other F2-A pairs pass. | Documented |
| Arabic coverage | Every new string has an Arabic translation; Arabic is derived from the same tokens (no Arabic Figma frame) and is marked “derived, pending native review”. | Conditional |

## Not verified

- Real TalkBack/VoiceOver/NVDA traversal and announcements.
- Browser zoom and native keyboard navigation on a real device.
- Native Arabic shaping, line-breaking and a native reviewer’s approval.
- Sunlight legibility and one-hand reach on a real phone.
