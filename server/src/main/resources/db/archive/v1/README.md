# Legacy migration archive (V1–V18)

These files are **reference-only** copies of the pre-rebuild Flyway migrations.
They are not on the active Flyway classpath (`db/migration`).

- `*.sql` — shared legacy migrations V1–V18.
- `mysql/` — MySQL-specific legacy migrations (triggers, PII, links).
- `h2/` — H2-specific legacy compatibility migrations.

The rebuilt Phase 1 schema starts at `db/migration/V100__platform_admin_clean_baseline.sql`
and uses the `platform_*` prefix (see `docs/DECISIONS.md` D-049).

Do not add new migrations here.
