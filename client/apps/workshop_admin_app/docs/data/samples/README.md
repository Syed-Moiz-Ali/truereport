# Samples — how they were produced

These are **not** live captures. The Phase 1 audit ran without a server, so every sample is
constructed from the producer code and marked `_source` accordingly. A live confirmation pass is
required before Gate 2b (see `docs/data_gaps.md` G7): start the dev server, log in with a seeded
workshop admin, and diff the real response against `login-success.json`.

| File | Shape | HTTP |
|---|---|---|
| `login-success.json` | `AuthResponse` success | 200 |
| `login-2fa-challenge.json` | `AuthResponse.challenge` | 200 |
| `login-invalid-credentials.json` | `ProblemDetail` | 401 |
| `login-validation-error.json` | `ProblemDetail` + `fieldErrors` | 422 |
| `network-failure.json` | no body → synthesized `AppFailure` | — |

Sanitization: all UUIDs are placeholders, all tokens are `<…>` placeholders, no real workshop,
person or email appears. Emails use the documented `.test` domain from `TEST_LOGIN_CREDENTIALS.txt`.
