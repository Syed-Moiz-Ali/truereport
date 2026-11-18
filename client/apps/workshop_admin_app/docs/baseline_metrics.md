# Baseline metrics — Workshop Admin, dashboard + jobs (Phase 0)

Measured read-only on 2026-11-18, after the sign-in wave. No app code changed.

## Suites and gates

| Metric | Value |
|---|---|
| `flutter test` | **428 pass, 0 fail, 0 skip** (52 s wall) |
| `flutter analyze --fatal-infos` | **0 issues** |
| `dart format` | 19 pre-existing files allowlisted, 0 new |
| `tool/baseline_check.dart` | OK (tests green, format 0 new, analyzer clean) |
| Screenshot suite | 77 PNGs rewritten per run (`test/screenshots/real/`) |

## Coverage (`flutter test --coverage`, lcov)

| File | Lines | Covered | % |
|---|---|---|---|
| `dashboard_tab.dart` | 350 | 326 | 93.1 |
| `jobs_tab.dart` | 135 | 123 | 91.1 |
| `jobs_board_tab.dart` | 308 | 251 | 81.5 |
| `job_detail_page.dart` | 614 | 444 | 72.3 |
| `job_widgets.dart` | 107 | 87 | 81.3 |
| `job_presentation.dart` | 309 | 301 | 97.4 |
| `workshop_admin_home.dart` | 70 | 59 | 84.3 |
| `workshop_job_providers.dart` | 43 | 37 | 86.0 |
| `job_counts.dart` | 18 | 16 | 88.9 |
| **in-scope UI + providers** | **1954** | **1644** | **84.1** |
| `admin_api.dart` | 427 | **5** | **1.2** |
| `models.dart` (WorkshopJob + DTOs) | 332 | 27 | **8.1** |
| `workshop_job_models.dart` (CleanJob + DTOs) | 310 | 52 | **16.8** |

**Read this honestly:** the screens are well covered *against a fake*, while the
layer that turns HTTP into those objects is almost entirely unexercised. Every
test overrides `adminApiProvider` with `FakeAdminApi`, which constructs models
from Dart constructors — so `fromJson`, query building, error mapping and
endpoint paths never run. The UI is green; the contract is unproven.

## Code shape (in scope)

| File | Lines | Note |
|---|---|---|
| `admin_api.dart` | 1187 | one class, all endpoints for every feature |
| `job_detail_page.dart` | 1063 | 14 private widgets, one file |
| `dashboard_tab.dart` | 712 | 9 private widgets |
| `job_presentation.dart` | 661 | formatters + badge vocabulary |
| `jobs_board_tab.dart` | 625 | CleanJob world |
| `jobs_tab.dart` | 260 | WorkshopJob world |
| `workshop_admin_home.dart` | 155 | shell, 6-tab IndexedStack |

## Not measured in this phase

- Web bundle size / build: not rebuilt. Last recorded value is in
  `docs/baseline_build.md` (60.99 MB debug-era figure); treat as stale.
- Startup time and frame timings: no profile run yet; the shell keeps six tabs
  mounted, which is the first thing to measure if jank is reported.
- Live API behaviour: no reachable server in this environment (carried gap from
  the sign-in wave), so contract samples must come from server code/fixtures.
