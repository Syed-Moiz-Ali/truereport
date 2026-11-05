# 10. 9. Global Platform Settings

- App: Platform Admin
- Figma node: `1:5618`
- Frame: 1280x1293 px (desktop web)
- Export folder: `screens/10_9._Global_Platform_Settings`
- Sources read: `9._Global_Platform_Settings.json`, `9._Global_Platform_Settings@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — three settings cards, toggles, labels, and geometry are explicit and readable.

> **Export-order note:** this file is manifest index **10**, but the Figma screen is numbered **9** and lives in `screens/10_9._Global_Platform_Settings/`. The previous file (`09-platform-audit-events-log.md`) is export index **09** but screen number **10**. The package orders by page position, not by screen label, so screens 9/10 are reversed.

## 1. Purpose
Global runtime configuration: UI localization/languages, admin security (session timeout, TOTP 2FA, IP whitelist, audit-token encryption), and automated fleet dispatch/webhook/telematics toggles.

## 2. Layout structure
Root `1:5618` vertical, 1280x1293, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:5619` 1024x1293, padding 64/32/32/32.
- `Container` `1:5620` 960x1197, gap 32:
  - Header `1:5621` 960x128, padding-top 8: title block 261x120 + environment badge 220x32.
  - `Main Settings Bento/Two-Column Grid` `1:5635` 960x869, no gap:
    - Card 1 Localization `1:5636` 464x517, radius 48, padding 40, gap 24: header 384x62; three language rows (58/40/40); footnote callout 384x124.
    - Card 2 Security & Access `1:5679` 464x471, radius 48, padding 40, gap 24: header 384x48; dropdown row 384x58; two 58 px rows; encryption row 384x57.
    - Card 3 `1:5729` 960x354, radius 48, padding 40, gap 24: header 880x48; two 424x194/176 cards side by side, gap 32.
  - Action bar `1:5774` 960x72: sync footnote left; Discard 99x56 + Save Platform Preferences 286x56.
- `Header` `1:5788` 1024x64 glass; `Aside` `1:5813` 256x800.

Two-column cards sit side by side (464 each, 32 gutter implied by 960 width). Card 3 spans both. The page is 1293 tall; no sticky save bar.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 37 | Labels/help/meta |
| `#1B1B25` | 17 | Titles/values |
| `#FFFFFF` | 17 | Cards |
| `#F4F3F8` | 14 | Select, callouts, toggles-off, badge, inner cards |
| `#10B981` | 11 | Active toggles, CTA, environment dot |
| `#006C49` | 6 | Active status text |
| `#3C4A42` | 5 | Nav |
| `#1A1B1F` | 4 | Chrome |
| `#E3E2E7` | 2 | Off-toggle track |
| `#F4F3F899` | 2 | Inner cards |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans` plus `Liberation Mono` 600 for “ED25519-SHA512”. H1 32/800 LH38; card titles 18/700 LH22.5 -0.27; settings labels 16/700 LH22; values/select 16/700; help 13/400 LH18; eyebrow 11/600 uppercase +0.44; “WEBSOCKET STREAMING ACTIVE” 11/700 `#006C49`; encryption value 11/600 mono.

### Radii, shadows, strokes, spacing
- Radii: 48 (three big cards), 9999 (toggles, pills, CTA, badge/select). Inner cards 0/soft, selects 9999.
- Shadows: cards `0 14 40 .04` + `0 2 8 .02`; inner cards `0 2 6 .20`; CTA `0 4 12 .20`; no borders.
- Strokes: none.
- Spacing: card padding 40; card gap 32; row gap 24; section gap 32; page 64/32.

## 4. Components
Flattened export. Patterns: page header with environment pill; bento settings cards; language/security/webhook rows with toggles; native-like select; info callout; inner metric/feature cards; destructive-looking primary save and neutral discard; footer sync note.
Mapping: `Switch`, `DropdownButtonFormField`, `AppButton`, `Card`; no settings-card, setting row, info callout, environment badge, or bento grid component. No toggle token/animation spec in export.

## 5. Assets
23 assets, all individual SVG icons. No raster/composed/photo. Icons: logo/nav, search/chrome, localization globe, lock/shield, sync/webhook, bolt, PDF, info.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Eyebrow | CONFIGURATION SCOPE • GLOBAL ROOT | No | — |
| Title | Platform Settings | — | No settings UI today |
| Subtitle | “Global runtime policies, regional localizations, and system authentication rules” | No | — |
| Environment | Production Cluster EU-West | No | No cluster/region setting |
| Localization | Multilingual dictionary & typography sets · 3 Languages | No | App UI is EN/AR only |
| Language 1 | Enable Arabic (RTL) Localization — “Auto-reverses layout coordinates and inspector forms” | Partly (locale) | RTL exists; wording is technically wrong |
| Language 2 | Enable Spanish Support — “es-MX / es-ES” | No | No Spanish UI |
| Language 3 | Enable French Support — “Quebec & European fleet inspection checklists” | No | No French UI |
| Footnote | “Activating a regional dialect dynamically triggers localized font subset packages via the Edge CDN to preserve 60fps…” | No | No Edge CDN/font subset pipeline |
| Security title | Security & Access — “Zero-trust technician permissions & token life” | No | Marketing claim |
| Session timeout | Admin Session Timeout · 30 Minutes · “Automatic revocation after period of inactivity” | No | No settings endpoint; token TTL is server config |
| 2FA | Enforce 2FA (TOTP) for All Admins — “Mandatory hardware security key or authenticator app” (on) | Partly (server flag `ADMIN_TOTP_REQUIRED`) | Default **false** per ADR-0021; no TOTP UI in admin app |
| IP whitelist | IP Restriction Whitelist — “Limit console access strictly to corporate diagnostic VPNs” (off) | No | No IP-allowlist feature/config |
| Encryption | Audit Token Encryption · ED25519-SHA512 | No | Invented algorithm/claim |
| Dispatch title | Automated Fleet Dispatch & Webhooks — “Event pipeline, real-time OBD relays, and customer certificate exports” | No | No webhooks/OBD relay/certificate export |
| Webhook health | Webhooks Healthy • 99.98% SLA | No | No webhooks/SLA |
| Telematics | Real-Time Telematics Ingestion — “Stream vehicle CAN-bus diagnostics and mileage counters live…” · WEBSOCKET STREAMING ACTIVE (on) | No | No telematics ingestion; PRD lists as future Phase 4 |
| PDF | Instant PDF Generation On Sign-Off — “Compile comprehensive inspection reports with embedded damage markup photos upon technician sign.” · AUTO-DISTRIBUTION HOOK (on) | Partly (PDF exists) | Reports are server-rendered HTML (D4) + bilingual PDF (D5); auto-distribution not present |
| Footer | “All changes sync immediately to edge nodes upon save” | No | No edge nodes |
| Actions | Discard, Save Platform Preferences | — | No endpoint |

No customer PII/VIN/plate/report findings. No payment data.

## 7. States shown / not shown
Shown: Arabic+Spanish on, French off, 2FA on, IP whitelist off, telematics on, PDF on, enabled save. Not shown: per-setting dirty/loading, validation, save success/failure, confirmation for security-sensitive changes, reason/re-auth, disabled/read-only state, locale unsupported state, webhook failure, TOTP enrolment, RTL page layout, keyboard/focus, 200% text, small screens.

## 8. Implied interactions
Toggle Arabic/Spanish/French; change session timeout; toggle 2FA; toggle IP whitelist; toggle telematics/PDF; discard; save. No per-toggle confirmation or explanation of blast radius. The 2FA/IP toggles are high-risk but use the same immediate pattern as cosmetic toggles.

## 9. Correspondence to current product
New feature. There is **no** platform-settings screen in `admin_app` and no settings controller in the server; `PlatformController` only lists/gets workshops. Phase-1 `08-api-design.md` lists `GET/PUT /platform/settings` (masked secrets), but it is not implemented. Existing relevant code: `AuthService`/`ADMIN_TOTP_REQUIRED` flag, `AuthController` `/auth/2fa/verify`, `AccessToken`/refresh rotation; locale switch in `platform_admin_home.dart` (`en`/`ar` only); report generation/PDF endpoints under `/workshop/jobs/{id}/report`; no telematics/webhook/IP-allowlist/Edge-CDN. Implementing this screen needs a settings API, persistence, validation, audit, and policy decisions.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “TOTP/security claims + ADR-0021.” Evidence: “Enforce 2FA (TOTP) for All Admins” is shown **on** with “Mandatory hardware security key or authenticator app” (`1:5707`–`1:5709`). ADR-0021 states `ADMIN_TOTP_REQUIRED=false` by default and “The admin app has no TOTP challenge UI”; hardware security keys are explicitly not V1 (ADR-0013).
- Rule: “No certification/‘verified by’/compliance claims.” Evidence: “customer certificate exports” (`1:5738`), “Webhooks Healthy • 99.98% SLA” (`1:5742`) and “Zero-trust technician permissions” (`1:5688`).
- Rule: “Never invent versions/licences/measurements/results.” Evidence: “ED25519-SHA512” (`1:5728`), “99.98% SLA”, “60fps”, “3 Languages”, “EU-West”.
- Rule: “Arabic RTL must work.” Evidence: “Auto-reverses layout coordinates” (`1:5654`) is not valid RTL implementation; phase-1 requires logical order and mirrored layout, not reversed coordinates. The page itself has no RTL variant.
- Rule: “Public report is server-rendered HTML (D4) with bilingual PDF (D5).” Evidence: “customer certificate exports” and “Instant PDF Generation On Sign-Off … AUTO-DISTRIBUTION HOOK” imply a different report/delivery pipeline; delivery must respect consent and is not an automatic hook.
- Rule: “no business logic/API/model/validation/permission/state/server change.” Evidence: every setting except the TOTP flag is absent from the server; IP whitelist, session-timeout config, webhooks, telematics, and edge sync have no model or endpoint.
- Rule: “no single unexplained condition score / marketing claims.” Evidence: “99.98% SLA”, “Webhooks Healthy”, “60fps” are operational claims with no source.
- Rule: “colours/text/radii/spacing from central tokens.” Evidence: 48 px card radii, `#10B981`/`#006C49`, lavender surfaces, and Liberation Mono are outside the current token set; Plus Jakarta Sans is not bundled.
- Rule: “high-risk actions require reason/re-auth.” Evidence: the 2FA/IP-whitelist toggles save with no confirmation, reason, or re-authentication.

## 11. Open questions / could not verify
- Is Platform Settings in scope for this phase? The API design lists it, but no implementation exists.
- Should the 2FA toggle exist at all while ADR-0021 keeps TOTP off by default? If yes, who may flip it, and what confirmation/audit applies?
- Is session timeout a global platform setting or an auth-service environment property? Current token TTL is server-side.
- Is IP whitelisting a planned enterprise feature? No data model exists.
- Are Spanish/French real product languages, or should the screen show EN/AR only? The app and item translations do not support Spanish/French UI.
- What is “Audit Token Encryption ED25519-SHA512”? No such key/algorithm is configured or documented.
- Are telematics/webhooks Phase 4 roadmap items? The PRD lists them as future, not current.
- **PRD mismatch:** the PRD claims **11** Platform Admin screens (Module A includes #11 “Admin 2FA / TOTP Verification”), but only **10** are exported. The missing TOTP challenge screen is not in `screens/` or `package-manifest.json`; this settings page is not a substitute challenge screen.
- No error/loading/success/RTL/small-screen states were exported.
