# App shell rebuild — independent Gate 6 verdict

Reviewer: QA/UX (read-only) · Date: 2026-11-19
Scope: direction C "The dock" — identity strip, dock, content reserve, states.
Spec: `docs/ui_brief.md` §1–§10 · Language: `docs/visual_language.md` · Waivers: `docs/waivers.md`
Artifacts judged: `docs/evidence/shell_after/*` (14 captures), `docs/evidence/gallery/shell_*`, `docs/evidence/dashboard_states/*`, `docs/evidence/logs/*`, `test/screenshots/real/*`, and the shell source.

## Verdict

**PASS WITH FIXES** — no structural failure, 4 MAJOR and 4 MINOR findings; the 360 dock label and the AR evidence must be corrected before this wave is called done.

The signature is actually built: one 44 px strip that names the workshop once, a language control that never hides in a menu, and a single floating dock whose only expanded item names the place you are. The chrome is flat (hairlines, one accent, no shadow or glass), the dock reserve is explicit, RTL mirrors both strip and dock with real Arabic glyphs, and the 2× text cases stay on screen. But the execution is not clean enough for a PASS: at the documented 360 px floor the active label is clipped to "Over…"/"Job b…", the AR state capture shows a language control that contradicts every other Arabic screen, the committed app test log predates the shell tests, and the AR job board renders its appointment column in a form that does not scan.

## Checklist

| # | Item (review brief / §9) | Result | Evidence |
|---|---|---|---|
| 1 | Identity strip at 1440/1024/768/390/360: brand + workshop once, language, bell, avatar, no second identity | **PASS** | `shell_after/dashboard_{1440,1024,768,390,360}.png`, `staff_1440.png`, `jobs_390.png`, `gallery/shell_strip_{ltr,narrow}.png` |
| 2 | Dock at 1440/1024/768/390: active item labelled, others icon-only, no clipped labels, no content overlap | **PASS** | `shell_after/dashboard_*`, `board_*`, `staff_1440`; `gallery/shell_dock_{default,staff,narrow}` |
| 3 | Dock at 360: active item labelled | **FAIL** | `shell_after/dashboard_360.png`, `shell_after/board_360.png`, `dashboard_states/ready_360.png` (→ F1) |
| 4 | Content reserve: last row clears the dock (dock height reserved by the shell) | **PASS** | `shell_dock.dart:35-36, 101-104`; all captures; DS `shell_test` "content can never be trapped" (green log) |
| 5 | RTL at 1280: strip and dock mirror, no clipped labels, real Arabic glyphs, no reversed icon semantics | **PASS** (chrome) | `shell_after/dashboard_1280_ar.png`, `board_1280_ar.png`, `gallery/shell_dock_rtl.png`, `shell_strip_rtl.png`; content chevron → F8 |
| 6 | Visual language: hairline borders, one accent, no shadows/glass, consistent type scale | **PASS** | all `shell_after` captures; `gallery/shell_dock_default.png` |
| 7 | Spacing / radii / status colour consistency across the captures | **PASS with drift** | `jobs_1440` vs `staff_1440` vs `templates_1440`; `board_768` (→ F6, F7) |
| 8 | States visible with shell chrome (loading / empty / error) | **FAIL** (one capture) | `dashboard_states/loading_1280.png`, `empty_1280.png`, `counts_error_1280.png` are honest; `ready_1280_ar.png` is an impossible state (→ F3) |
| 9 | §9.1 kill list gone; §9.2 `WorkshopAppShell` API unchanged | **PASS** | `workshop_shell.dart:20-41`; no `_Sidebar`/`_Rail`/`_TopBar`/`_BottomBar`/`showWorkshopMoreSheet` survivors in `lib/` |
| 10 | §9.5 selected announced + focus ring; §9.6 language visible; §9.7 no More / `navMore` | **PASS** | `shell_dock.dart:120-123, 157-159`; strip captures; no More in any capture |
| 11 | §9.9 1.5×/2× at 390 and 1280: no overflow, active label ellipsizes | **PASS** | `dashboard_states/scale150_390.png`, `scale200_390.png`, `scale150_1280.png`, `scale200_1280.png` |
| 12 | §9.10 all screens + `flutter analyze` / `flutter test` / `baseline_check` clean | **FAIL** (evidence) | 77 real-font screen captures exist in `test/screenshots/real/`; app `test.txt` does not contain this wave's tests (→ F4) |
| 13 | Dark mode | **WAIVED** (W-LIGHT, countersigned 2026-11-18) | `docs/waivers.md:8` |

W-NOTOTP and W-ROWOPEN are accepted and not re-tested. Settings shows the workshop name as a form value in addition to the strip; that is content, not a second identity, and is not a §8.4 duplication.

## Findings

### F1 — MAJOR — the active dock label is clipped at the 360 px floor
- **Evidence:** `docs/evidence/shell_after/dashboard_360.png` ("Over…"), `docs/evidence/shell_after/board_360.png` ("Job b…"), `docs/evidence/dashboard_states/ready_360.png` ("Over…"). The gallery's "narrow" proof is 390 px (`gallery/shell_dock_narrow.png`), so 360 was never proven.
- **What is wrong:** at 360 × 1.0 the only navigation surface stops naming the current section. The signature idea is that the dock names the place you are; "Over…" is ambiguous outside the app (it can read as "Overdue") and every other item is icon-only. §6 only permits label truncation at 1.5×/2× text, not at base scale. Cause: the active item is given `flex: 2` below 380 px.
- **Exact fix:** in `shell_dock.dart:77`, keep `flex: 3` for the active item at every width ≥ 360 (7 other units + 3 = 8; at 360 the pill is ~124 px and "Overview"/"Templates"/"Job board" fit), or reduce item horizontal padding from 8 to 4 and the icon–label gap from 8 to 6 below 380. Add a `Size(360, 800)` shell test that asserts the active label is not ellipsized, and a 360 gallery capture.
- **File:** `client/packages/design_system/lib/src/components/shell/shell_dock.dart:71-82` (line 77); test gap: `client/packages/design_system/test/shell_test.dart` (only 1280/390 today).

### F2 — MAJOR — the AR job board's Scheduled column does not scan
- **Evidence:** `docs/evidence/shell_after/board_1280_ar.png` rows 1–3 (`٩٠٠٢٠٢٦/١١/٥`, `…/١١/٦`, `…/١١/٧`) versus `docs/evidence/shell_after/dashboard_1280_ar.png` and `dashboard_states/ready_1280_ar.png`, which show the same field as `5/11/2026 09:00`.
- **What is wrong:** the board renders the appointment as Arabic-Indic digits, time-first, with no visible separator at 12.5 px, so the value reads as one digit run; it is also the only Arabic-Indic value on an otherwise Latin-numbered screen. The dashboard pins dates LTR with Latin digits (the committed dashboard RTL rule), so the same timestamp has two formats. The three dates (5/6/7 Nov) match the English board, so this is a presentation defect, not a data contradiction.
- **Exact fix:** use one formatter for tabular dates. Either isolate the value (`Directionality(textDirection: TextDirection.ltr)` + tabular figures, as the dashboard does) or split date and time onto two lines with a visible separator, and use the same numeral set app-wide. Add an AR board test that pins the rendered order/string, not just its presence.
- **File:** `client/apps/workshop_admin_app/lib/src/features/jobs/jobs_board_tab.dart:421`; formatter `client/apps/workshop_admin_app/lib/src/workshop_clock.dart:78`.

### F3 — MAJOR — the AR state capture is an impossible state (contradicts the AR screens)
- **Evidence:** `docs/evidence/dashboard_states/ready_1280_ar.png` shows the language control labelled "العربية" while the whole UI is Arabic. `shell_after/dashboard_1280_ar.png` and `board_1280_ar.png` correctly show "English".
- **What is wrong:** the control must offer the language you are *not* in; showing "العربية" in an Arabic UI cannot happen in the app. The capture harness sets `MaterialApp.locale` but never sets `localeProvider`, while the host derives the label from `localeProvider` — so the evidence is a harness artefact, not the shipping state. It also means this capture cannot be used to prove the AR state.
- **Exact fix:** set the provider in the harness (`ref.read(localeProvider.notifier).setLocale(locale)`, as `_ScreenshotHarness` already does) or derive the label from `Localizations.localeOf(context)` so label and copy cannot diverge; regenerate `ready_1280_ar` and check it against `dashboard_1280_ar`.
- **File:** `client/apps/workshop_admin_app/test/dashboard_states_capture_test.dart:112-163`; `lib/src/features/home/workshop_admin_home.dart:126`.

### F4 — MAJOR — the committed app test log is not the post-shell run
- **Evidence:** `docs/evidence/logs/test.txt:648` says `+562: All tests passed!` but contains no `shell_gallery_test`, no `the shell names the workshop exactly once`, and no dock/strip test names. `docs/evidence/shell_qa.md:13,19-20` cites `+555` and "shell gallery +8". `docs/evidence/logs/design_system_test.txt:208` is `+138`, not the `+136` claimed, though it does include the new `shell_test.dart`.
- **What is wrong:** the app-side test evidence predates the app-side changes (host, gallery, rewritten dashboard test), and the numbers in the proof sheet reconcile with neither log. `baseline_check.txt` reports "tests: green (0 failures)" but carries no counts or case names, so it cannot close the gap. There is no evidence of a failing test; there is evidence that the right test run was not committed.
- **Exact fix:** from the fixed tree, re-run `flutter test` in the app and the design system, commit both logs, update the counts in `shell_qa.md`, and correct "shell_after (8)" to the 14 captures that actually exist.
- **File:** `docs/evidence/logs/test.txt`, `docs/evidence/shell_qa.md`.

### F5 — MINOR — a destination without `selectedIcon` loses its icon when selected
- **Evidence:** `docs/evidence/gallery/shell_dock_staff.png` (active pill has no icon) and `test/screenshots/real/workshop_templates_360.png` (Templates pill has no icon), while `shell_after/staff_1440.png` and `settings_390` show icons.
- **What is wrong:** `selectedIcon` is optional, but the dock renders `widget.selected ? destination.selectedIcon : destination.icon`; a null `selectedIcon` means `Icon(null)` — the icon disappears exactly when the item becomes active. The gallery exposes it, and it explains why the Templates pill at 360 fits a full label while Overview at 360 clips.
- **Exact fix:** `widget.destination.selectedIcon ?? widget.destination.icon` (or make `selectedIcon` required), then regenerate every dock capture from one build.
- **File:** `client/packages/design_system/lib/src/components/shell/shell_dock.dart:166-168`.

### F6 — MINOR — the board filter bar is ragged at 768
- **Evidence:** `docs/evidence/shell_after/board_768.png`.
- **What is wrong:** the search field keeps ~356 px while the four chips wrap, leaving "Published (1)" alone on a second line under the chips. It is usable but visibly unfinished at a required width.
- **Exact fix:** below 900 px put the chips on their own full-width row under the search (or let the search flex to ~40 % and wrap the chips 2 × 2); never leave a single orphan chip.
- **File:** `client/apps/workshop_admin_app/lib/src/features/jobs/jobs_board_tab.dart` (filter row, ~:60-160).

### F7 — MINOR — the six sections do not share one content frame
- **Evidence:** at 1440, `jobs_1440` starts at x≈32 and `dashboard_1440` at x≈40, while `staff_1440` and `templates_1440` are centred at x≈120 with a 1200 max. The dashboard scale's comment "matches `WorkshopTokens.pageGutter`" is false at this width (40 vs 32).
- **What is wrong:** switching sections shifts the page edge by up to 88 px and changes the usable width; the page title and primary action jump. The shell is now the one frame for six screens, so this reads as drift, not intent.
- **Exact fix:** pick one frame for all six (pageGutter + a documented max content width) and apply it in the shell or in one shared content wrapper; use it for the dashboard too.
- **File:** `lib/src/features/dashboard/dashboard_style.dart:57` vs `staff_tab.dart`/`templates_tab.dart` vs `jobs_board_tab.dart:60`.

### F8 — MINOR — the RTL row chevron is not mirrored
- **Evidence:** `docs/evidence/shell_after/board_1280_ar.png` — the disclosure chevron at the far-left (trailing) edge still points right; `dashboard_1280_ar.png` shows the Review arrow correctly mirrored to ←.
- **What is wrong:** at the trailing edge of an RTL row, a right chevron points back into the table instead of forward to the detail.
- **Exact fix:** render the chevron with `matchTextDirection: true` (or `chevron_left` under RTL).
- **File:** `lib/src/features/jobs/jobs_board_tab.dart` (row trailing affordance).

## What is genuinely good

- **The signature lands.** At 1440/1024/768/390 there is exactly one identity strip and exactly one dock; the workshop is named once, there is no breadcrumb, no sidebar, no "More", and the language is one tap away at every width — the two tap-to-language path is gone.
- **The RTL chrome is properly mirrored.** Overview sits on the right of the dock, the active icon and label swap sides, the strip cluster reverses, and the Arabic glyphs are real, not boxes. The dock/strip never clip a label at 1280 AR.
- **The restraint is real.** Hairline-only surfaces, no shadow or glass, one accent, shared radii across dock/pill/cards, and a dock that adds no second surface type. 1.5×/2× text stays on screen and ellipsizes as specified.
- **The states are honest.** Loading skeletons, scoped error bands with Retry, no invented counters, an explicit "Other 2" for an unaccounted remainder, and the workshop/initials fallback for no session.

## Blocking action

Do not sign this wave off until F1 is fixed and the entire evidence set — `shell_after/`, `gallery/`, `dashboard_states/` and the app + design-system `flutter test` logs — is regenerated from that one build and re-reviewed at 360 and 1280 AR.
