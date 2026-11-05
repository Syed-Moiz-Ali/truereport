# F1 accessibility and i18n review (final)

- **Reviewer:** a11y-i18n-reviewer
- **Date:** 5 November 2026
- **Scope:** F1 design system, components, gallery, F1 tests
- **Revision:** final verification. No code, token, component, test or doc file was changed except this report.

## Verdict

**PASS WITH CONDITIONS — 0 blockers, 6 accepted/deferred major conditions, 8 minor items.**

The last blocker is fixed: `_NavDockItem` now has `onTap: onTap` on the outer `Semantics` (`navigation.dart:200`), so the `InkWell` action is no longer excluded from assistive technology. The remaining majors are known, owner-visible deferred conditions; they do not block F1.

## Verified fixed

- B1 screen-reader activation: nav dock `navigation.dart:200`; admin rail `admin_chrome.dart:249`; admin bottom tile `:566`; interactive result chip `results.dart:240`; result options `results.dart:115`; sortable headers `data_table.dart:248-250`; tree expand `tree_view.dart:453`.
- B2 non-text contrast: input/chip/result/segment boundaries use `outline`/`brand.ink`; selected chips/segments show check icons; primary emerald button has a 1.5 dp deep-green boundary (`inputs.dart:117-120`, `chips.dart:205-207,323-325`, `results.dart:126-128`, `buttons.dart:102-106`).
- B3 Arabic tracking: both apps build `AppTheme.build(isArabic: locale.languageCode == 'ar')` (`technician_app/lib/app.dart:17-21`, `admin_app/lib/app.dart:17-21`).
- M1 emerald boundary; M3 coverage + ring LTR (`progress.dart:55,99,118`); M4 admin rail selected dot (`admin_chrome.dart:285-296`); M7 skeleton settles (`states.dart:149`); M11 tests added.
- Consent starts unselected; Save disabled until type and status are chosen (`job_detail_page.dart:352-359,497`).

## Accepted / deferred major conditions

| ID | Condition | Evidence |
|---|---|---|
| M2 | 200% ellipsis / fixed-scale risk | `chips.dart:371-372`; `admin_chrome.dart:589-590`; `data_table.dart:279-280`; `progress.dart:51-53` |
| M5 | Data-table semantics | `data_table.dart:124-137,245-306` |
| M6 | Gallery chrome localization | `gallery_app.dart:186,201,216,227,244,261` and section titles |
| M8 | Noto Sans SC scope/size | `pubspec.yaml:59-62`; `tokens.dart:748-752`; `supportedLocales` is `ar,en` |
| M9 | Directional icon mirroring | `buttons.dart:62-64`; `showcase_components.dart:73` |
| M10 | VIN / field direction | `inputs.dart:13,38,132` |

## Minor items (unchanged)

`m1` data-table header focus is an 8% tint, not the 2 px ring (`data_table.dart:263`); `m2` chips enforce minHeight 48 but not minWidth (`chips.dart:222`, `results.dart:250`); `m3` duplicate semantics risk (`buttons.dart:123-126`, `inputs.dart:109-111`, `progress.dart:26-28`); `m4` field fill token mismatch (`tokens.dart:806` vs `inputs.dart:148`); `m5` progress track `outlineVariant` = 1.40:1 (`progress.dart:45,141`); `m6` disabled tree rows still expose a tap action (`tree_view.dart:373-379`); `m7` loading button not announced busy; `m8` gallery chrome `TextScaler.noScaling` (`gallery_app.dart:130-132`, dev-only trade-off).

## New regressions

None found in product code.

## Tests

Analyze is clean and component tests pass (design_system 114, technician 22, admin 83, gallery 1, as reported). This final check verified the nav-dock line by source inspection.

## Still cannot be verified

Real TalkBack/VoiceOver activation, real devices, browser zoom, native Arabic review, rendered focus/contrast, Escape/focus traps, and Arabic date/currency/odometer formatting (km, UTC+4, AED) in F1 components.
