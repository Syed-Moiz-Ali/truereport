# Phase 0-lite — baseline metrics, findings, strategy

Scope: Workshop Admin **sign-in** screen. Read-only audit, no app code changed.

## Baseline metrics

| Metric | Baseline | Source |
|---|---|---|
| Analyzer (`--fatal-infos`) | **0 issues** | `flutter analyze` (82.8 s) |
| Tests | **396 executed — 393 pass / 3 fail / 0 skip** | `flutter test` |
| Failing tests | 3, all `source_scan_test.dart` token rules, all from `workshop_login_page.dart` | `docs/baseline_allowlist.md` |
| Coverage | **not measured, not enforced** | no CI gate |
| `RenderFlex overflowed` | **0** (but see F1 — matrix mounts the wrong widget) | `flutter test test/ui_matrix_test.dart` |
| Real-font screenshots | 77 committed PNGs, rewritten on every test run, asserted by nothing | `test/screenshots/real/` |
| Locales | 2 (`en`, `ar`) + RTL | `packages/l10n` |
| Theme | **light-only by decision** (`AppTheme.build` asserts light; dark removed in C0 Workstream B) | `tokens.dart:736-748` |
| Fonts | **bundled** in `packages/design_system/assets/fonts`, declared in that package's `pubspec.yaml`, no runtime fetch, no `google_fonts` dependency | `packages/design_system/pubspec.yaml` |
| Build / bundle size | see `docs/baseline_build.md` | `flutter build web --release` |

## Font strategy — decision (settled here, not at Gate 5)

**Bundled fonts. No runtime fetching. One global test loader.**

- `.ttf`s already ship in `packages/design_system/assets/fonts` and are declared under the
  `Plus Jakarta Sans`, `Noto Sans Arabic`, `IBM Plex Sans Arabic`, `Noto Sans`,
  `Noto Sans SC`, `Noto Sans Telugu` families.
- Theme resolves them through `TrFonts` (`packages/design_system/lib/src/fonts.dart`), which
  prefixes `packages/design_system/…`; `AppTheme.build` sets `fontFamily` + `fontFamilyFallback
  (tokens.dart:799-807)`. **Family names match the theme today.**
- `google_fonts` is absent from every pubspec (grep: 0 hits) — nothing to disable at runtime.
  CI adds a grep ban so it cannot be introduced silently.
- **Gap:** the real-font `FontLoader` lives only in
  `test/workshop_real_font_screenshot_test.dart:33`. Move it to `test/flutter_test_config.dart`
  so every widget test lays out with real glyphs, then delete the local copy.
- **Violation to remove:** `fontFamily: 'monospace'` (`workshop_login_page.dart:523`) is an
  unregistered family. It renders as black boxes in the committed 1440 and AR screenshots.

## Top-10 findings

| # | Finding | Consequence | Fix | Effort | Risk |
|---|---|---|---|---|---|
| F1 | **The sign-in test matrix tests the wrong widget.** `ui_matrix_test.dart:157,191` and `widget_test.dart:35,47` mount `SignInPage` (`packages/auth/src/sign_in_page.dart`), not `WorkshopLoginPage`. 22 green tests cover an unused page. | A real overflow / RTL break on the screen that ships passes CI. The app is only pinned at 1280 EN and 390 EN. | Point both files at `WorkshopLoginPage`; drop the `Brightness.dark` axis (see F10). | S | M — may reveal real failures |
| F2 | **Token rules already broken on this screen** — `Colors.black`, `Colors.white`, `fontSize: 36/15`, `BorderRadius.circular(6/3)`, `BoxShadow`, `fontFamily: 'monospace'` (`workshop_login_page.dart:158,383,421,432,461,462,523,557,603`). | 3 CI tests red; the one screen that looks most like marketing is the least token-driven; monospace renders as tofu. | Rebuild with `context.ws` + `WorkshopCard`; no raw colours/type/radii/shadows. | M | L |
| F3 | **Hardcoded English in the Arabic build** — headline `'Inspections your\ncustomers can trust.'` (:418), `'2023 Porsche 911 GT3'` (:477), `'DXB 48291'` (:521), `'Rashid Al Mansoori'` (:532), `'Inspection checklist'` (:542), `'18 / 24 items (75%)'` (:546), `'Karim Ahmed · Lead Tech'` (:578), `'Started 45m ago'` (:585). | Arabic screenshot shows an English headline with a bidi-mangled full stop and `items (75%) 24 / 18`. A Dubai workshop's first screen is half-untranslated. | l10n keys for every visible string, or delete the mock. Numbers formatted with `intl`/`NumberFormat`, never concatenated. | M | L |
| F4 | **2FA challenge is silently swallowed.** `_submit()` awaits `signIn(...)` and discards the `AuthResult`; `AuthChallenge` therefore produces no message and no progress (:51-53). | With `ADMIN_TOTP_REQUIRED=true` an admin can never sign in and is never told why. | Branch on `AuthChallenge` and show a localized "two-factor required — contact your platform administrator" (do **not** add TOTP UI: `source_scan_test.dart:248` forbids it). | S | L |
| F5 | **No `AutofillGroup`.** `autofillHints` are set (:276,286) but the fields are not grouped and the context is never finished. | Password managers may not offer to save/autofill the workshop admin credentials. | Wrap the form in `AutofillGroup`; `TextInput.finishAutofillContext()` after success. | S | L |
| F6 | **Real fonts are not global.** No `test/flutter_test_config.dart`; only one test file loads fonts. | Every other widget test measures Ahem, so "no overflow" claims are measured against fake metrics. | Move `_loadRealFonts()` into `flutter_test_config.dart`, delete the local copy. | S | L |
| F7 | **Screenshot evidence is unasserted churn.** The test writes 77 tracked PNGs on every run and asserts nothing; a bare `flutter test` dirties the worktree. | Visual regressions land as "modified PNG" nobody reviews; evidence cannot gate CI. | Write to gitignored `build/screenshots/`, or assert goldens explicitly in the QA phase. | S | L |
| F8 | **Only the happy path is tested.** No test for the error banner (:305-336), validation copy, `_submitting` state or the eye toggle. | The one failure path users actually hit is unpinned; a rebuild may change it silently. | Characterization tests in Brief 1 (keys + widget finders, no golden). | S | L |
| F9 | **Mobile composition is weak.** At 360×800 the form starts ~270 px down with ~200 px of empty canvas above the title (header 64 px + `Center` in `Expanded`). Desktop has a similar top empty band in the brand panel. | The smallest, most common size looks unfinished on first paint. | Own the vertical rhythm: top-weighted form on phone, optical centring on desktop. | S | M (design) |
| F10 | **Two sign-in surfaces.** `SignInPage` / `SignInView` / `AdminSignInView` stay exported from `package:auth` (used by technician + platform apps) and the workshop app keeps a bespoke duplicate that the tests prefer. | Two sources of truth; test drift (F1) is a symptom, not a one-off. | Delete the duplicate after the rebuild, or make the workshop page the only admin sign-in and move shared bits into `design_system`. | M | M |

**What to keep**

- Brand-panel idea (deep green slab + real product preview), the 900 px split breakpoint, the
  400 px form column, the form's single-column rhythm.
- The inline error banner with `Semantics(liveRegion: true)` (:307-309) — keep the pattern.
- `sign-in-email` / `sign-in-password` / `sign-in-submit` keys (I11) — the harness depends on them.
- The router's "one `GoRouter`, refresh via `ChangeNotifier`" design (I2) — it exists because
  recreating the router wiped the form. Do not regress it.
- The "no demo-fill / no fake security badges" stance (`widget_test.dart:106-125`).
- Bundled fonts + `TrFonts` family names.
- The existing real-font capture approach — it is the right harness, just misplaced.

## Strategy

**Strangler, single screen, no new architecture boundary.**

The app already has the target pieces (`WorkshopTokens`, `WorkshopTextField`, `WorkshopButton`,
`WorkshopCard`, `AppTheme.build`, l10n package, router). The screen is the outlier. So the
rebuild replaces the screen's internals while keeping its route, keys, controller wiring and
error-mapping contract.

Ordered seams (each independently revertible):

1. **Harness first** — point the 22 mis-targeted tests at `WorkshopLoginPage`; global
   real-font loader; baseline-allowlist CI check. No visual change. (Brief 1)
2. **Behaviour** — `AuthChallenge` branch, `AutofillGroup`, validation/error characterization
   tests. No visual change. (Brief 1)
3. **Copy** — l10n keys for every visible string, `intl` number formatting. Visible text only,
   no layout change. (Brief 1 / mini Brief)
4. **Visual** — rebuild panel + form on tokens/primitives, token-only styling, own the mobile
   vertical rhythm. (mini Brief)
5. **Proof** — 1440/1280/1024/768/390/360 EN + 1280 AR, light + (documented) light-only dark
   stance, error/submitting/validation states, 1.5× text scale, resize 1440→360.

No big-bang rewrite: step 1 must be green before step 4 exists.

## Dark theme

The app is light-only **by an earlier decision**, not by omission (`AppTheme.build` asserts
light; `themeMode: ThemeMode.light`). The rebuild will not invent a dark theme for one screen.
Gate 5 evidence therefore uses light only, with the dark axis removed from the matrix (F1) and
the decision recorded as a waiver, not silently skipped.

## Open questions for Gate 0 approval

1. **Keep or drop the product-preview mock** in the brand panel? It is the only fabricated
   content on the screen (a Porsche, a plate number, a technician, "45m ago"). Keeping it
   means localizing a fictional job; dropping it means the panel is headline + one line.
2. **2FA copy** — confirm the admin app intentionally has no TOTP entry and the message should
   point the user to a platform administrator.
3. Confirm light-only is still the intended product decision.
