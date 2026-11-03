# ADR-0009: UUIDv7 keys and layered immutability

- **Status:** Accepted for the Phase 2 foundation (UUIDv7 `BINARY(16)` implemented); full immutability is Phase 5/6
- **Date:** 3 November 2026
- **Owner:** Backend lead / DBA

## Context

Offline clients must create records without a central sequence. MySQL has no native UUID type. Finalized findings must not be changed through normal application, API or database paths.

## Options

1. Auto-increment BIGINT keys (rejected — offline creation and enumeration risk).
2. Random UUIDv4 `BINARY(16)` (works, but poor index locality).
3. **UUIDv7 `BINARY(16)`** (chosen — time-ordered, offline-safe).
4. ULID stored as text (larger, less standard for Java).

## Decision

- Generate UUIDv7 in the application (Java/Dart) and store `BINARY(16)`.
- Every workshop-owned table carries `workshop_id` with a leading index.
- Finalized data is protected by: no edit code path, API prohibition, database triggers, least-privilege grants, report snapshot hash, audit, and direct-SQL tests.
- A correction, if ever approved, is a new report version; the old version is never modified.
- Acknowledge that a privileged DBA can disable triggers; separation of duties and hash monitoring are required.

## Consequences

- Offline rows can be created safely.
- Index locality is better than UUIDv4.
- Hibernate/JPA needs a custom `BINARY(16)` mapping.
- Triggers add write overhead and must be tested.
- Column-level grants and worker roles add operational complexity.

## Follow-ups

- Test UUIDv7 generation and `BINARY(16)` mapping in Phase 2.
- Write and test triggers for every immutable table.
- Test direct SQL as `tr_app` fails.
- Implement the snapshot hash job and alerting.
- Document the DBA bypass limitation in the security review.

## What was not proven

No schema or trigger was executed in Phase 1. Trigger performance and MySQL 8.4 behavior are untested.
