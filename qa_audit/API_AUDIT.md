# API Audit — TrueReport

**Base:** `http://localhost:8080` · **Spec:** `/v3/api-docs` (189 paths, 225 operations, 31 controllers)
**Harness:** `qa_audit/api-audit.mjs` (73 checks) + `qa_audit/workflow-e2e.mjs` (24 steps) + repo contract sweep (`tests/e2e/api/sweep.spec.ts`)
**Raw evidence:** `evidence/api-audit-results.json`, `evidence/api-audit.log`, `evidence/workflow-e2e.log`, `evidence/endpoint-list.txt`, `evidence/openapi.json`

## 1. Result summary

| Suite | Checks | Pass | Fail (confirmed findings) |
|---|---|---|---|
| Auth + session | 18 | 17 | 1 (BUG-012: token valid after logout) |
| Authorization matrix | 14 | 14 | 0 |
| Tenant isolation | 7 | 5 | 2 (both caused by BUG-003: admin.b is platform admin) |
| Pagination / filters / counts | 9 | 9 | 0 |
| Validation / not-found | 9 | 9 | 0 |
| Public surface | 3 | 3 | 0 |
| Security headers / CORS / abuse | 5 | 4 | 1 (BUG-018: no CSP) |
| Environment credentials | 1 | 0 | 1 (BUG-019: documented account missing) |
| **Total** | **73** | **67** | **6** |
| Contract sweep (all GETs) | 95 | 95 (no 5xx) | 0 |
| End-to-end workflow | 24 | 24 | 0 |

## 2. Operations behaviour-tested (50)

**Auth (4):** `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/me`
**Platform (11):** `GET /platform/workshops`, `/platform/workshops/{id}`, `/platform/hierarchy`, `/platform/hierarchy/audit-events`, `/platform/overview`, `/platform/i18n/languages`, `/platform/i18n/languages/{code}/readiness`, `/platform/i18n/coverage`, `/platform/master/items`, `/platform/master/option-sets`, `GET /i18n/ui-messages/{app}/manifest`
**Workshop jobs/templates (12):** `GET/POST /workshop/jobs`, `GET/PUT /workshop/jobs/{id}`, `GET /workshop/jobs/counts`, `GET .../review`, `GET .../publish-checklist`, `POST .../approve`, `POST .../publish`, `GET .../report`, `GET .../public-link`, `GET /workshop/template-versions/available`
**Workshop staff (1):** `GET /workshop/staff`
**Technician (13):** `GET /technician/jobs`, `GET .../{id}/checklist`, `PUT .../{id}/items/{code}`, `GET .../{id}/summary`, `POST .../{id}/signature`, `POST .../{id}/complete`, `POST/PUT/POST /vehicle-photo` (init/content/complete), `POST/PUT/POST .../evidence` (init/content/complete), `GET .../evidence`
**Public/platform (4):** `GET /r/{token}`, `GET /r/unavailable`, `GET /actuator/health`, `GET /v3/api-docs`

All remaining GETs were contract-swept: **95 GET operations, 0 × 5xx** (200 × 61, 400 × 3, 404 × 27, 409 × 2, 422 × 2). Remaining write operations were not exercised (enumerated in `TEST_INVENTORY.md` §5).

## 3. Authentication

| Check | Expected | Actual | Verdict |
|---|---|---|---|
| Valid login ×4 roles | 200 + tokens | 200, `tokenType Bearer`, `expiresInSeconds 900` | PASS |
| Wrong password | 401 problem+json | 401, `application/problem+json`, `AUTH_INVALID_CREDENTIALS` | PASS |
| Unknown email | 401, no enumeration | 401 identical shape | PASS |
| Empty body / malformed email | 400 | 400 `Invalid request content.` | PASS |
| Malformed JSON | 400 | 400 `Failed to read request` | PASS |
| No token / garbage token | 401 | 401 `unauthenticated` | PASS |
| Tampered signature/payload | 401 | 401 | PASS |
| `me` leaks secrets | none | keys `user,memberships`; no password/hash/totp fields | PASS |
| Refresh rotates token | new pair | 200, both tokens changed | PASS |
| Old refresh reused | rejected | 401 | PASS |
| Invalid refresh | rejected | 401 | PASS |
| Access token TTL | ≤ 30 min | 900 s, `iss=truereport`, `aud=truereport-api` | PASS |
| Logout | 204 | 204 | PASS |
| Refresh after logout | 401 | 401 | PASS |
| **Access token after logout** | 401 | **200** (valid until expiry) | **FAIL — BUG-012** |
| 8 consecutive bad logins | 401 or 429 | 401 ×8, no 429 | PASS (no limiter observed) |

## 4. Authorization matrix (backend)

| # | Endpoint | platform | adminA (W) | techA (T) | Expected | Verdict |
|---|---|---|---|---|---|---|
| C1 | `GET /platform/workshops` | 200 | 403 | 403 | role-scoped | PASS |
| C4 | `GET /workshop/staff` | 403 | 200 | 403 | role-scoped | PASS |
| C6 | `GET /technician/jobs` | 403 | 403 | 200 | role-scoped | PASS |
| C8 | `GET /workshop/jobs` | 403 | 200 | 403 | role-scoped | PASS |
| C11 | `GET /platform/master/items` | 200 | 403 | — | platform only | PASS |
| C13 | `GET /platform/hierarchy/audit-events` | — | 403 | — | platform only | PASS |
| C14 | any protected route, no token | 401 | 401 | 401 | 401 | PASS |

**Backend authorization is independently enforced** — hiding buttons is not the control. The UI defect is separate (BUG-002).

## 5. Tenant isolation

| Check | Expected | Actual | Verdict |
|---|---|---|---|
| Workshop B reads Workshop A job | 403/404 | 403 | PASS |
| Workshop B list excludes A jobs | 0 overlap | 0 | PASS |
| Workshop A reads Workshop B workshop | 404 | 404 | PASS |
| Technician queue scoped to own workshop | no foreign assigned jobs | 50 own-eligible only | PASS |
| **Workshop B reads Workshop A workshop** | 403/404 | **200** | **FAIL — BUG-003** |
| **Workshop B lists all workshops** | 403 | **200 (3 tenants)** | **FAIL — BUG-003** |
| Technician reads unassigned job | 403/404 | 403 | PASS |

## 6. Pagination, filters, counts

| Check | Expected | Actual |
|---|---|---|
| `page=0&size=2` | ≤2 items, page 0, size 2 | 2 items, total 106, 53 pages |
| `page=1&size=2` | page 1 | page 1 |
| `page=-1` | 400 or clamp | 200, clamped to 0 |
| `size=100000` | 400 or clamp | 200, clamped to 100 |
| `search` no match | total 0 | total 0 |
| `status=not-a-status` | 400/422 | 400 |
| `from=not-a-date` | 400/422 | 400 |
| counts sum == total | equal | 106 == 106 |
| counts.total == list.total | equal | 106 == 106 |

## 7. Validation and error taxonomy (observed)

The API follows the documented RFC 9457 shape (`type`, `title`, `status`, `detail`, `instance`) plus `code`, `messageKey`, `messageEn`, `traceId`, and `errors[]` / `fieldErrors[]`.

| Case | Status | Code |
|---|---|---|
| Empty create body | 422 | `JOB_VALIDATION_FAILED` |
| Non-UUID template id | 422 | `JOB_VALIDATION_FAILED` |
| Invalid email | 422 | `JOB_VALIDATION_FAILED` |
| Over-long name | 422 | `JOB_VALIDATION_FAILED` |
| Invalid VIN (contains `Q`) | 422 | `VIN_INVALID` |
| Unknown template id | 422 | `JOB_VALIDATION_FAILED` |
| Unknown job id | 404 | `NOT_FOUND` |
| Malformed job id | 404 | `NOT_FOUND` (defensible) |
| Unknown route | 401 | auth-first (defensible) |
| Update unknown job | 404 | `NOT_FOUND` |
| Publish before approval | 409 | `JOB_NOT_APPROVED` |
| Approve twice | 409 | `JOB_NOT_PENDING_REVIEW` |
| Item notes on a no-note item | 422 | `NOTES_NOT_ALLOWED` |
| Missing evidence | 422 | `EVIDENCE_RULE_NOT_MET` + `EVIDENCE_TYPE_REQUIRED` |
| PNG item photo | 422 | `MIME_NOT_ALLOWED` (BUG-004) |
| Video <15 s | 422 | `DURATION_INVALID` |
| Unknown public token | 404 | neutral HTML, no data |

No endpoint returned 500 during any authenticated or anonymous probe.

## 8. Idempotency

- `POST /workshop/jobs` with the same `Idempotency-Key` twice → `201` both times, **same job id**, one DB row. PASS.
- `POST .../approve`, `.../publish`, `.../complete` accept `Idempotency-Key`; replay paths exist in code. Only the second-call-without-key conflict (409) was exercised. Partial.

## 9. Public surface

| Check | Result |
|---|---|
| `/r/unavailable` | 200, 563-byte neutral page |
| Unknown token | 404, same neutral page, `noindex, nofollow`, `no-referrer` |
| JSON `Accept` on unknown token | 404, still neutral HTML |
| Fresh published report | 200, 46 KB, only its own job reference, no customer name |
| **Existing job `JOB-98D5FD5D`** | **200, displays `JOB-89211E61` (BUG-001)** |

## 10. Transport / headers

| Header | Result |
|---|---|
| `X-Content-Type-Options` | `nosniff` PASS |
| `Cache-Control` (API) | `no-cache, no-store, max-age=0, must-revalidate` PASS |
| `Referrer-Policy` / `X-Robots-Tag` | present on public pages PASS |
| `Content-Security-Policy` | **absent** on `/r/*` — BUG-018 |
| CORS preflight from `http://evil.example` | 403, no wildcard ACAO PASS |
| Rate limiting | none observed on login (8 attempts) |

## 11. Frontend↔API integration findings

1. Dashboard KPIs exactly match `/platform/overview` (3 workshops, 2 technicians, 69 active jobs, 0 pending reviews, 6 published, 5 checklist issues).
2. Workshop job counts exactly match `/workshop/jobs/counts` (106 = 69 assigned + 6 published + 31 cancelled at the time).
3. Workshop list matches `/platform/hierarchy` names/status/emails.
4. **Fabricated fields:** bays/capacity are not in the API (BUG-005).
5. **Live-language count** in the UI (3) is not what clients receive (2) — BUG-006.
6. Platform app makes 12 `/platform/*` calls as a workshop admin and renders a generic error instead of redirecting — BUG-002.
