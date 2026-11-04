# Phase 8.1 Server Deployment

**Owner decisions:** self-hosted filesystem storage; no cloud object storage; admin TOTP off by default.  
**Status:** Deployment configuration and docs only. No production host, DNS name, TLS certificate or secret manager was provided or verified.

---

## 1. One domain, three surfaces

Use one DNS name for everything:

| Path | Served by | Authentication |
|---|---|---|
| `/api/**` | Spring backend | JWT / role / tenant checks |
| `/r/**` | Spring public report and report assets/PDF | public token + revocation/consent checks |
| `/` | Flutter Admin web static build | browser app; API calls use `/api/**` |
| `/actuator/health` | Spring health | public through Nginx |
| `/actuator/*` | Spring metrics/ops | private network only |
| `/storage/**`, `/data/**`, `/files/**` | **404 by design** | never static |

Nginx config: `infra/nginx/nginx.conf`.

The Admin web build must be copied to `infra/web/admin/` and is mounted read-only at `/usr/share/nginx/html`. Do **not** put the storage root under this directory.

---

## 2. DNS and network

1. Create `A` (and `AAAA` if used) DNS records for the chosen domain pointing to the server public IP.
2. Public firewall: allow **80/tcp** and **443/tcp** only.
3. Do **not** expose MySQL, Spring `8080`, Prometheus `9090`, Grafana `3000`, MinIO/S3 or internal admin ports to the internet.
4. Restrict SSH to approved admin IPs or VPN; disable password SSH and use keys.
5. Keep `/actuator/*` (except health) private at the proxy/firewall.
6. Confirm DNS resolves to the server before requesting a certificate.

---

## 3. TLS

TLS certificates and private keys are mounted at `infra/nginx/tls/fullchain.pem` and `privkey.pem`. The directory is gitignored.

### Option A - Certbot / Let's Encrypt

Official instructions: <https://certbot.eff.org/instructions> (choose Nginx + the server OS; accessed 4 November 2026).

Typical Linux flow:

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d reports.example.com
sudo certbot renew --dry-run
```

Point Certbot's Nginx integration at the deployed site or copy the issued `fullchain.pem`/`privkey.pem` into `infra/nginx/tls/`. Do not commit them. HSTS is already configured in `nginx.conf`; enable it only after HTTPS is confirmed.

### Option B - Caddy

Official automatic-HTTPS documentation: <https://caddyserver.com/docs/automatic-https> (accessed 4 November 2026). Caddy can obtain and renew public certificates automatically when DNS points to the server, ports 80/443 are reachable, and its data directory is persistent. If using Caddy instead of Nginx, reproduce the same routes/limits and private `/actuator` policy from `nginx.conf`; do not add a storage static route.

---

## 4. Storage volume

- Production uses `STORAGE_PROVIDER=filesystem`.
- Mount a persistent volume at `/app/.truereport-storage`; `docker-compose.prod.yml` uses `server_storage`.
- The server container is read-only except `/tmp`, `/app/.cache` and the storage volume.
- The adapter enforces root existence, writability, minimum free space, object/total quota, atomic writes, SHA-256 sidecars, path-traversal checks and POSIX permissions (`0700` directories, `0600` files).
- **Host/volume encryption is not provided by the app.** Enable full-disk encryption or encrypted block volume at the provider/host level, protect the unlock key, and record key custody. The application cannot verify that the volume is encrypted.

---

## 5. Server hardening

- Non-root application user (`truereport`, UID 10001); read-only root filesystem; no privileged container.
- Keep Docker/engine, base images, Chromium and OS patched; pin image digests for production where possible.
- No secrets in git/images; use a secret manager and `infra/prod.env` at deploy time only.
- Enable host firewall and fail2ban/SSH protection.
- Limit Docker socket access; do not mount it into the application.
- Centralize logs away from the storage volume; no request bodies or PII.
- Back up database + storage together; keep encrypted off-site copies.
- Monitor free disk, growth, certificate expiry, report failures, delivery dead letters and webhook failures.

---

## 6. Deploy order

1. Provision the host, DNS, firewall, persistent volume and full-disk/volume encryption.
2. Install Docker/Compose and obtain TLS certificates.
3. Create `infra/prod.env` from `infra/env/production.env.example`.
4. Copy the Admin web build to `infra/web/admin/`.
5. Start MySQL, then the server, then Nginx:

```powershell
$env:Path='C:\Users\sanja\AppData\Local\Programs\DockerDesktop\resources\bin;'+$env:Path
docker compose -f infra/docker-compose.prod.yml up -d --build
docker compose -f infra/docker-compose.prod.yml ps
```

6. Verify health, login, job list, public report, evidence/PDF authorization and unknown storage-path 404.
7. Run a database+storage restore drill before real customer data.

---

## 7. What is not verified

- No production host, DNS name, certificate, secret manager, firewall or encrypted volume was provided.
- Nginx config syntax passed against dummy certificates; production TLS was not deployed.
- Docker Scout high/critical scan was run for the development server image; production image/host was not scanned.
- No real-customer data was used.
