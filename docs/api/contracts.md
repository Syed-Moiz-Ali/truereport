# API contracts

Wire rules that every client and the server must agree on. These are contracts, not
preferences: a change here is a breaking change for the mobile apps and the public report.

## 1. Error envelope

Every non-2xx JSON error is RFC 9457 problem detail with stable fields
(`ApiExceptionHandler.problem`):

```json
{
  "type": "https://truereport.example/problems/language_invalid",
  "title": "Unprocessable Entity",
  "status": 422,
  "detail": "Unsupported report language",
  "instance": "/api/v1/workshop/jobs/.../deliveries",
  "code": "LANGUAGE_INVALID",
  "messageKey": "error.delivery.language",
  "messageEn": "Unsupported report language",
  "traceId": "..."
}
```

- `code` and `messageKey` are stable identifiers; map them in the client.
- `detail` is localized from `Accept-Language`. `messageEn` is present for non-platform callers
  only; platform-admin endpoints always return English in `detail`.
- Validation failures add `errors` / `fieldErrors` (array of `field`, `code`, `messageKey`,
  `messageEn`). The translation gate adds `translationIssues` and reuses `errors`.

## 2. Idempotency

Mutating endpoints that create a request require `Idempotency-Key`; a missing key is
`400 IDEMPOTENCY_KEY_REQUIRED`. Reusing a key with a different body is
`409 IDEMPOTENCY_KEY_REUSED`; reusing it with the same body returns the original response.
Delivery requests additionally hash `jobId | channel | language`.

## 3. Timestamps (quirk 3)

A field that carries **no offset** is a **wall time**. For user-picked values (job schedule) it is
Dubai wall time (Asia/Dubai, UTC+4, no DST): the create payload is the operator's Dubai clock. A
field that carries `Z` or `±HH:MM` is a real instant.

- Server: `DATETIME` columns are zone-less wall time. Read them with
  `com.truereport.shared.jdbc.JdbcTime.localDateTime(rs, column)`
  (`ResultSet.getObject(column, LocalDateTime.class)`), never
  `getTimestamp(...).toLocalDateTime()` — that renders the value in the JVM zone and shifts every
  schedule on a non-UTC host.
- Client: `client/apps/workshop_admin_app/lib/src/workshop_clock.dart` (`WorkshopClock.wallTime`)
  and `client/apps/technician_app/lib/src/shared/technician_intl.dart` (`parseWallTime`)
  implement the same rule. A naive value must not get `+4h` twice.
- Consequence: a job created with `scheduledAt=2026-11-21T12:00:00` must read back exactly
  `2026-11-21T12:00:00` from `/workshop/jobs/{id}` and `/technician/jobs`, on any host timezone.

Machine-generated instants (`evidence.capturedAt`, sync timestamps) are sent as UTC
(`toUtc().toIso8601String()`) and therefore carry `Z`.

**Known residual (not yet fixed):** database-generated columns (`created_at`, `updated_at`,
history, delivery attempts) use MySQL `CURRENT_TIMESTAMP` in the **database session zone**, and the
three `LocalDateTime.now()` sites use the JVM zone. Clients display naive values as Dubai wall
time, so on a non-Dubai database those *server-generated* stamps are off by the zone difference.
Scheduling is unaffected (it is stored from the request). Fix by running the MySQL session at
`+04:00` (compose `--default-time-zone=+04:00` or Hikari `connection-init-sql`) and generating
server stamps in Dubai time; see `docs/PROGRESS.md` open items.

## 4. Languages

- The **registry** (`GET /api/v1/i18n/languages`, and the platform admin view) is the source of
  truth for which languages exist. Only rows with `status = LIVE AND active = TRUE` are
  selectable.
- Job creation, delivery languages, document language labels and the technician/report surfaces
  read the registry. They must not hardcode `en`/`es`/`ar` or derive the list from UI catalog
  coverage.
- UI catalogs (`/api/v1/i18n/ui-messages/{client}/manifest`) only advertise languages that ship a
  catalog file. Flutter `supportedLocales` follows that manifest, so built-in Material/Cupertino
  copy never claims a language with no catalog.
- Content and delivery bundles fall back to English per key. A live language with no bundle is
  valid; it renders English copy, never an empty string.
- Resolution order (`RequestLanguageContext`): `?lang` when supported → `Accept-Language` (q-values,
  exact tag then base tag) → the caller's saved preference → `truereport.i18n.default-language`.
  An unsupported `?lang` is ignored, never an error. Authoring writes use `Content-Language`
  first and deliberately ignore `?lang`. A published report snapshot keeps its own language;
  `?lang` never overrides it.
- Publishing a job in a non-default language is gated by `TranslationReviewGate`: unreviewed or
  stale safety-critical rows return `409 TRANSLATION_REVIEW_REQUIRED` with the issue list
  (`entityType`, `entityId`, `field`, `lang`, `reason`).

## 5. Delivery

- Delivery requires the job to be `PUBLISHED` with an active public link; otherwise
  `409 REPORT_NOT_READY`.
- Consent is the job's single `consentGranted` flag (`PUT /workshop/jobs/{id}/consent`); there are
  no per-channel consent rows.
- `language` must be a LIVE registry code (`422 LANGUAGE_INVALID` otherwise). It controls the
  email/SMS copy. The report itself is rendered in the job's snapshot language.
- EMAIL attaches the report PDF when it renders and fits `delivery.email-max-attachment-bytes`;
  otherwise the message carries the public link only. SMS/WhatsApp are always link-only.
- Recipient policy (`delivery.allowed-*-recipients`, `real-recipients-enabled`) is enforced
  before a request row is written.

## 6. Status and enum codes

Statuses, enums and option values are served by `/api/v1/reference/*` and backed by the merged
option-set store. Clients resolve `labelKey` from their catalog first, then the served `label`,
then a humanised code. `selectable=false` values must not appear as choices in pickers.
