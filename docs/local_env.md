# Local environment — canonical values

The cause of the `AEADBadTagException: Tag mismatch` 500s on `/workshop/jobs` was that
two different env files provided different `APP_ENCRYPTION_KEY` values for a database
that was seeded with one of them.

**Rule: the database is seeded with the values in `server/start-mysql-backend.ps1`.
Use that script (or copy its values) for every local run.**

| Variable | Canonical local value |
|---|---|
| MySQL | `127.0.0.1:3306`, db `truereport` |
| `DB_USER` | `truereport` |
| `DB_PASSWORD` | `truereport123` |
| `DEV_SEED_PASSWORD` | `Truereport#Local123` |
| `JWT_SECRET` | value in `server/start-mysql-backend.ps1` |
| `APP_ENCRYPTION_KEY` | value in `server/start-mysql-backend.ps1` |
| `JAVA_HOME` | `C:\Users\sanja\jdk-25.0.5+8` |

`infra/.env` is the deployment/compose file. Do **not** use it to start the API against
the local database: its `APP_ENCRYPTION_KEY` does not match the seeded rows.

Seeded accounts (all share `DEV_SEED_PASSWORD`):

- `platform@truereport.test`
- `admin.a@truereport.test`, `tech.a@truereport.test`
- `admin.b@truereport.test`

Public report token used for smoke checks:
`c6wnoKy4x78Sk2o4EoNWFZZPDoXq9VtxF9DE7Cs5rWk` (`/r/<token>`, `/r/<token>/pdf`).
