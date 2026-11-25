# Personal server (no Docker)

Two long-running processes:

```
LibreTranslate  → 127.0.0.1:5000   (only local, not public)
TrueReport API  → 0.0.0.0:8080     (your reverse proxy / firewall)
MySQL           → local or managed
```

The API reaches LibreTranslate at `http://127.0.0.1:5000`. LibreTranslate never
needs to be public.

Pick the section for your server OS.

---

## Linux (systemd)

### 1. LibreTranslate

```bash
sudo useradd --system --create-home --home-dir /opt/libretranslate libretranslate
sudo -u libretranslate python3 -m venv /opt/libretranslate/venv
sudo -u libretranslate /opt/libretranslate/venv/bin/pip install --upgrade pip
sudo -u libretranslate /opt/libretranslate/venv/bin/pip install libretranslate
```

Copy `libretranslate.service` to `/etc/systemd/system/`, then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now libretranslate
sudo systemctl status libretranslate
```

Models download to `/opt/libretranslate/.local/share/argos-translate` on the first
translation. Keep that directory on the server (back it up occasionally).

Verify:

```bash
curl -s http://127.0.0.1:5000/languages
```

### 2. API

```bash
# build on your machine / CI
mvn -f server/pom.xml -DskipTests package

# copy to the server
sudo mkdir -p /opt/truereport /etc/truereport
sudo cp server/target/truereport-server-0.2.0-SNAPSHOT.jar /opt/truereport/
sudo cp deploy/personal-server/api.env.example /etc/truereport/api.env
sudo chmod 600 /etc/truereport/api.env
```

Edit `/etc/truereport/api.env` (database, secrets, URLs). Then copy
`truereport-api.service` to `/etc/systemd/system/` and:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now truereport-api
sudo systemctl status truereport-api
sudo journalctl -u truereport-api -f
```

The log must show:

```
Content translation provider: libretranslate
```

### 3. Firewall

Do **not** open port 5000 publicly:

```bash
sudo ufw deny 5000/tcp
```

Only 8080 (or your reverse-proxy port) is public.

---

## Windows server

1. Copy `api.env.example` to `api.env` in this folder and fill it.
2. Build the JAR:
   ```powershell
   mvn -f server/pom.xml -DskipTests package
   ```
3. Start the whole stack:
   ```powershell
   .\deploy\personal-server\run-api.ps1
   ```
   The script loads `api.env`, starts/reuses LibreTranslate on
   `127.0.0.1:5000`, and runs the JAR.

For an always-on service, use NSSM (or Task Scheduler → “At startup”):

```powershell
nssm install TrueReportLibreTranslate powershell.exe "-NoProfile -ExecutionPolicy Bypass -File C:\truereport\tools\run-libretranslate.ps1"
nssm install TrueReportAPI powershell.exe "-NoProfile -ExecutionPolicy Bypass -File C:\truereport\deploy\personal-server\run-api.ps1"
nssm set TrueReportAPI AppDirectory C:\truereport
nssm set TrueReportLibreTranslate AppDirectory C:\truereport
nssm start TrueReportLibreTranslate
nssm start TrueReportAPI
```

---

## Interface text catalogs

Approved **interface text** translations are written back to `UI_MESSAGES_DIR`.
The API needs a writable copy of the shipped catalogs:

```bash
sudo mkdir -p /opt/truereport/i18n
sudo cp -r server/src/main/resources/i18n/* /opt/truereport/i18n/
sudo chown -R truereport:truereport /opt/truereport/i18n
```

Set `UI_MESSAGES_DIR=/opt/truereport/i18n` in `api.env`. Without a writable
directory, Content Review still approves rows but logs a warning and cannot
publish the JSON catalogs.

### Adding a language's interface text

1. Open **Content review → Interface text → language**.
2. **Generate interface text** (queues the English keys).
3. Review / **Approve all interface text**.
4. The backend writes `common/<lang>.json` and `<client>/<lang>.json` under
   `UI_MESSAGES_DIR`; reload the app to pick up the new manifest and bundle.

This is how the **platform admin console** can gain Spanish/French even though
it has no `platform_admin/<lang>.json` in source: the catalog is generated
through the same pipeline.

## Verify the whole chain

```powershell
# LibreTranslate
curl.exe http://127.0.0.1:5000/languages

# a real translation
curl.exe -s -X POST http://127.0.0.1:5000/translate `
  -H "Content-Type: application/json" `
  -d '{"q":"Measure the tyre tread depth.","source":"en","target":"es","format":"text"}'

# API health (translation provider is now part of health)
curl.exe http://127.0.0.1:8080/actuator/health
```

Expected translation:

```json
{"translatedText":"Medir la profundidad de la pisada de neumáticos."}
```

## Important settings

| Variable | Value |
|---|---|
| `I18N_TRANSLATION_PROVIDER` | `libretranslate` |
| `LIBRETRANSLATE_URL` | `http://127.0.0.1:5000` |
| `LIBRETRANSLATE_TIMEOUT` | `30s` |
| `LIBRETRANSLATE_LANGUAGES` / `--load-only` | `en,es,fr` (must match LIVE languages) |

If `fr` is not actually live in the product, remove it from the load list so the
worker does not queue French jobs.
