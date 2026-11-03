# ADR-0001: MySQL 8.4 LTS

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Technical lead
- **Supersedes:** PostgreSQL assumption in `master.md` v0.1 (v0.2 already switched to MySQL)

## Context

`master.md` v0.2 says MySQL 8.x but marks the product choice for confirmation. Phase 0 established that MySQL 8.0 reached end of life in April 2026 and that 8.4 is the current 8.x LTS. The schema depends on `utf8mb4`, `JSON`, InnoDB, triggers and column-level grants.

## Options

1. MySQL 8.4 LTS.
2. MySQL 8.0 (rejected — EOL).
3. MariaDB (compatible but different features/licence).
4. Microsoft SQL Server (different cost/ops).

## Decision

Use **MySQL 8.4 LTS** with `utf8mb4`, InnoDB, UTC `DATETIME(6)`, strict SQL mode, Flyway migrations, UUIDv7 `BINARY(16)`, tenant-scoped tables and defence-in-depth immutability. Do not build for MySQL 8.0.

## Consequences

- No row-level security; tenancy must be enforced in the application with tests.
- UUIDv7 is stored as `BINARY(16)`, not a native UUID type.
- JSON is used only for immutable snapshots/settings; searchable data stays in normal columns.
- Column-level grants and triggers are part of the design.
- MySQL Connector/J licensing needs legal review before distribution.

## Follow-ups

- Confirm D1 in writing.
- Test Flyway migrations on MySQL 8.4 from empty and from the previous version.
- Verify Hibernate 7 mappings for `BINARY(16)`.
- Record the exact 8.4 patch version in the Phase 2 version lock.

## What was not proven

No database was installed or benchmarked in Phase 1. Version 8.4.13 was the Phase 0 snapshot; re-verify at Phase 2.

