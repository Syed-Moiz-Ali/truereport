# Data samples — provenance

**These are not captured responses.** No server was reachable from this
environment (no Docker; Java 17 only; carried gap from the sign-in wave). Each
file below is constructed from the server DTO definitions and the client
mappers, so the **shape** is exact and the **values** are illustrative.

Every file carries `"provenance": "derived-from-dto"` so nothing here can be
mistaken for evidence of live behaviour. When a server is available, replace
these with sanitized captures and bump `provenance` to `captured`, recording the
request, status code and timing in this README.

| File | Endpoint | Source of shape |
|---|---|---|
| `legacy-job-counts.json` | `GET /workshop/legacy/jobs/counts` | `JobCountsDto` |
| `legacy-jobs.json` | `GET /workshop/legacy/jobs` | `JobDto` (legacy mapping) |
| `clean-job-counts.json` | `GET /workshop/jobs/counts` | `JobStatusCountsDto` |
| `clean-jobs-page.json` | `GET /workshop/jobs?page=0&size=10` | `JobPageDto` + `JobDto` |

Not sampled: `/jobs/{id}/review` and `/assignments`. Their client mappers are
marked **ASSUMED** in `docs/data/inventory.md` and need a real capture before
any UI depends on their shape.

## What still needs a real capture (Gate 2b)

1. A timestamp value from each endpoint, to settle T1 (naive vs offset).
2. `assignedBy` / `technicianId` values from `/assignments`, to confirm T5.
3. One unknown-status response, to prove the neutral fallback does not print a
   raw enum.
4. A 409 stale-version response, to prove the client shows a conflict rather
   than `commonActionFailed`.
