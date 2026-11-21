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

## Optional LibreTranslate (Phase C)

Docker is optional and the service is behind a compose profile so it never starts by
default:

```bash
docker compose --profile libretranslate up -d libretranslate
# wait for /languages, then point the API at it:
export I18N_TRANSLATION_PROVIDER=libretranslate
export LIBRETRANSLATE_URL=http://127.0.0.1:5000
```

- Image: `libretranslate/libretranslate:latest`, internal port `5000`.
- `LT_LOAD_ONLY=en,es,fr`, `LT_DISABLE_WEB_UI=true`, models persisted in
  `libretranslate_models`.
- Memory: allow ~2 GB and a few minutes of first-run model download; the
  healthcheck hits `/languages` with a 120 s start period.
- Optional API key: set `LIBRETRANSLATE_API_KEY`; it is sent as `api_key`.
- Tests never call LibreTranslate; they use a local `HttpServer` stub and the
  default `fake` provider.

### Windows without Docker (what this machine uses)

Python 3.12 is available via `py`, so LibreTranslate runs from a venv:

```powershell
$venv = "$env:TEMP\lt-venv"
py -3.12 -m venv $venv
& "$venv\Scripts\python.exe" -m pip install libretranslate

# cp1252 consoles break the model updater (it prints "→"); force UTF-8:
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
& "$venv\Scripts\libretranslate.exe" --load-only en,es,fr --disable-web-ui --host 127.0.0.1 --port 5000
```

- First start downloads Argos models (`en→es`, `en→fr`, `es→en`, `fr→en`, ~550 MB) into
  `%USERPROFILE%\.local\share\argos-translate\packages`; later starts load them from cache in
  a few seconds. `/languages` is the readiness probe.
- API env: `I18N_TRANSLATION_PROVIDER=libretranslate`, `LIBRETRANSLATE_URL=http://localhost:5000`,
  `I18N_WORKER_ENABLED=true`.
- Queue existing content once: `POST /api/v1/platform/i18n/content/backfill {"languages":["es"]}`.
- Results arrive as `MACHINE / PENDING_REVIEW` in Platform Admin → Content review.

