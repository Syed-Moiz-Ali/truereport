# Server deployment

Two supported paths:

1. **Personal server, no Docker** → [`personal-server/README.md`](personal-server/README.md)
   (systemd units for Linux, `run-api.ps1` for Windows).
2. **Docker Compose** (optional) → this file.

For a personal server the non-Docker path is the recommended one: it runs the
JAR and LibreTranslate directly, with no container runtime to maintain.

The content translation worker needs LibreTranslate in both cases:

```
MySQL  ──  API (Spring Boot)  ──  LibreTranslate
                  │                     │
                  └──── local / private network ────┘
```

LibreTranslate should listen on `127.0.0.1:5000` (personal server) or stay on
the private compose network. Only the API port is public.

## Docker Compose (optional)

The rest of this file describes the Docker path. If you are not using Docker,
stop here and follow [`personal-server/README.md`](personal-server/README.md).

## 1. Configure

```powershell
cd deploy
Copy-Item .env.example .env
```

Fill `.env`:

- `DB_PASSWORD`, `DB_ROOT_PASSWORD`
- `JWT_SECRET` and `APP_ENCRYPTION_KEY` — each must be base64 32 bytes:
  ```powershell
  openssl rand -base64 32
  ```
- `PUBLIC_BASE_URL`, `CORS_ALLOWED_ORIGINS`
- `LIBRETRANSLATE_LANGUAGES` — must match the languages that are LIVE in the
  product. Current default: `en,es,fr`.

## 2. Start

```powershell
docker compose up -d --build
docker compose logs -f api
```

The API waits for MySQL and LibreTranslate health checks before starting.

The **first translation** downloads the Argos model for the language pair
(about 100 MB per pair). Watch it once:

```powershell
docker compose logs -f libretranslate
```

Models are stored in the `libretranslate-models` volume, so redeploys do not
download them again.

## 3. Verify

```powershell
# LibreTranslate is up and has the expected languages
docker compose exec api curl -s http://libretranslate:5000/languages

# Real translation through the private network
docker compose exec api curl -s -X POST http://libretranslate:5000/translate `
  -H "Content-Type: application/json" `
  -d '{"q":"Measure the tyre tread depth.","source":"en","target":"es","format":"text"}'

# API health
curl.exe http://localhost:8080/actuator/health
```

The API log should contain:

```
Content translation provider: libretranslate
```

If it says `fake`, the `I18N_TRANSLATION_PROVIDER` environment variable did not
reach the container — check `docker compose config`.

## 4. Operations

| Task | Command |
|---|---|
| Restart API only | `docker compose restart api` |
| Rebuild after code changes | `docker compose up -d --build api` |
| Backup database | `docker compose exec db mysqldump -u root -p truereport > backup.sql` |
| Backup uploaded evidence | copy the `truereport-storage` volume |
| Add a language | add it to `LIBRETRANSLATE_LANGUAGES`, make it LIVE in the app, then `docker compose up -d libretranslate` |

## Using an existing MySQL

Delete/comment the `db` service and point the API at your database:

```yaml
DB_URL: jdbc:mysql://your-db-host:3306/truereport?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=utf8
DB_USER: ...
DB_PASSWORD: ...
```

Remove the `depends_on: db` entry and the `db` health condition too.

## Security notes

- LibreTranslate has **no authentication** in this setup. It is intentionally
  not published to the host; keep it on the internal network.
- If you must expose it, enable API keys (`LT_API_KEYS=true`) and set
  `LIBRETRANSLATE_API_KEY` for the API.
- Pin `libretranslate/libretranslate` to a version (currently `v1.10.0`) and
  upgrade deliberately.
- The engine is CPU-based; no GPU is required. Translations are batched by the
  worker (`batch-size: 20` toward LibreTranslate).
