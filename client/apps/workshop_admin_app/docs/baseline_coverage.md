# Baseline coverage (established at Gate 2b)

Command: `flutter test --coverage` (whole app suite, 406 tests executed).

| Scope | Lines hit | Lines found | Coverage |
|---|---|---|---|
| Whole app (`lib/`) | 5,085 | 7,251 | **70.1 %** |
| `lib/src/features/auth/workshop_login_page.dart` | 285 | 294 | **96.9 %** |

Notes:

- The app suite does not instrument `packages/auth`, `packages/domain` or `packages/api_client`
  (they are separate packages with their own test runs), so the auth-path numbers above are the
  page only. The behaviour of the auth layer is covered indirectly through the page tests plus
  the 13 behaviour-fix tests.
- The 9 uncovered lines in the sign-in page are the `!mounted` guards and the generic
  `catch (_)` fallback, which are hard to reach deterministically in a widget test.
- **No threshold is enforced yet.** The rule for this rebuild: the sign-in path must not lose
  coverage. A repo-wide floor should be set once the 19 unformatted files and the remaining
  screens are addressed, so the floor reflects a known-good state rather than today's backlog.
