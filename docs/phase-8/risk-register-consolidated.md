# Phase 8 Consolidated Risk Register

**Project:** TrueReport  
**Date:** 4 November 2026  
**Status:** Single current register. Earlier phase files remain for history and are not deleted.

Risk IDs are now unique (`TR-Rxxx`). The legacy table maps reused and phase-specific IDs to the new IDs. A risk is not closed because a document says so; the evidence column must point to a test, scan or operational proof.

---

## 1. Current register

| ID | Risk | Impact | Likelihood | Score | Status | Owner | Evidence / mitigation |
|---|---|---:|---:|---:|---|---|---|
| TR-R001 | Production could start with unsafe/local storage | 4 | 3 | 12 High | Closed for storage choice | Eng/Ops | Owner D6: `FileSystemObjectStorage` on persistent volume; local dev-only; guard; S3 unused |
| TR-R002 | S3 adapter is unused and untested against a production provider | 3 | 2 | 6 Medium | Closed by owner decision | Eng/Ops | S3 retained optional/disabled; no cloud account used |
| TR-R003 | PII at rest was plaintext | 4 | 4 | 16 High | Mitigated | Eng/Security | AES-256-GCM job fields + final snapshot; V15/V16; real MySQL migration test; backups/local/client residual |
| TR-R004 | PII key custody, separation and rotation are not production-proven | 4 | 3 | 12 High | Open | Security/Ops | Key-ID format and rotation test; no secret manager/KMS integration |
| TR-R005 | Admin TOTP had no recovery path | 4 | 3 | 12 High | Closed | Eng/Security | Ten one-time recovery codes; regeneration endpoint; tests |
| TR-R006 | No login/TOTP brute-force lockout at application layer | 4 | 3 | 12 High | Mitigated | Security | 5 failures / 15-minute lockout; generic errors; Nginx login limit; no shared lockout store |
| TR-R007 | Retention/cleanup undefined | 3 | 3 | 9 Medium | Mitigated, C2 pending | Product/Legal/Ops | `RetentionService`; periods default disabled; never deletes finalized reports |
| TR-R008 | Public evidence photos may expose plates, faces or addresses | 4 | 4 | 16 High | Open | Product/Legal | No blur/crop policy; do not use real evidence publicly until approved |
| TR-R009 | Arabic report/PDF/delivery wording has no native review | 4 | 4 | 16 High | Open | Arabic reviewer | No native sign-off |
| TR-R010 | Real-device camera/offline/keyboard/browser matrix not run | 4 | 4 | 16 High | Open | QA | `real-device-test-plan.md`; every item NOT RUN |
| TR-R011 | D8 WhatsApp/SMS providers, templates, sender IDs and contracts are undecided | 4 | 4 | 16 High | Open | Product/Legal/Ops | Fake/SMTP only; D8 Pending |
| TR-R012 | Real provider status/webhook mapping is unproven | 3 | 4 | 12 High | Open | Eng | Fake HMAC webhook test only |
| TR-R013 | Production email deliverability/authentication is not configured | 3 | 4 | 12 High | Open | Ops | No SPF/DKIM/DMARC/bounce handling |
| TR-R014 | Backup/restore and backup retention are not fully operationalised | 4 | 3 | 12 High | Mitigated for filesystem drill | Ops | Encrypted DB+storage bundle restored to fresh MySQL/storage; report/evidence/PDF hashes matched; off-site destination and retention pending |
| TR-R015 | Monitoring/alerts are configs, not a running production service | 3 | 3 | 9 Medium | Partially mitigated | Ops | Prometheus/Grafana configs; no Sentry, on-call rotation or live alert test |
| TR-R016 | Load test is small, sequential and local | 3 | 4 | 12 High | Open | Eng/QA | Login/job list/public only; not representative |
| TR-R017 | Single-instance worker/rate-limit assumptions block safe horizontal scaling | 3 | 3 | 9 Medium | Open | Eng/Ops | DB polling and in-memory limits; Nginx edge limit |
| TR-R018 | Java dependency vulnerability scan did not run | 4 | 3 | 12 High | Open | Security | OWASP Dependency-Check failed: no NVD API key |
| TR-R019 | Flutter dependency advisory scan not completed | 3 | 3 | 9 Medium | Open | Security | `flutter pub outdated` only; no advisory API scan |
| TR-R020 | Secret scan reports two tracked test-vector findings | 3 | 2 | 6 Medium | Mitigated false positives | Security | Gitleaks: RFC 6238 test secrets only; `infra/.env` ignored and untracked |
| TR-R021 | No independent penetration test | 4 | 4 | 16 High | Open | Security | No test booked |
| TR-R022 | Invalid/revoked public responses are neutral but timing was not measured | 3 | 3 | 9 Medium | Open | Security | Same page/status tested; no timing study |
| TR-R023 | Image decompression-bomb handling is not explicitly tested | 3 | 3 | 9 Medium | Open | Security | MIME/hash/size tests; ImageIO re-encode; no dimension bomb test |
| TR-R024 | Every endpoint has anonymous-auth coverage, but not every endpoint has a cross-tenant object test | 4 | 3 | 12 High | Partially mitigated | QA/Security | 99 endpoints reject anonymous; existing role/tenant suites cover a subset |
| TR-R025 | CORS could allow localhost in production | 3 | 3 | 9 Medium | Closed | Eng | Configurable origin list; prod example has explicit origin; CORS test |
| TR-R026 | Swagger/OpenAPI could be exposed in production | 3 | 2 | 6 Medium | Closed | Eng/Ops | `application-prod.yml` disables; startup guard |
| TR-R027 | HSTS/security headers rely on reverse proxy | 3 | 2 | 6 Medium | Mitigated | Ops | Nginx config; app public headers; not deployed |
| TR-R028 | Generic errors could leak internals | 3 | 2 | 6 Medium | Mitigated | Eng | Problem details; stack traces disabled; no generic 500 regression test |
| TR-R029 | Log redaction is code-reviewed, not automatically proven | 3 | 3 | 9 Medium | Open | Security | No request-body logging found; no logger appender test |
| TR-R030 | No legal compliance/DPIA sign-off | 4 | 4 | 16 High | Open | Legal | No PDPL/GDPR/DPDP claim |
| TR-R031 | No correction process for a wrong report | 4 | 4 | 16 High | Open | Product/Legal | D9 fence; report v1 immutable |
| TR-R032 | Chromium/JVM memory at PDF concurrency is not measured | 4 | 3 | 12 High | Open | Eng/Ops | Single-worker design; no 1/2/4 load measurement |
| TR-R033 | Multiple active links and already-shared copies cannot be recalled | 3 | 4 | 12 High | Open | Product/Ops | Revoke-all-active; `no-store`; copies cannot be recalled |
| TR-R034 | Lost active link URL cannot be recovered from hash-only storage | 3 | 3 | 9 Medium | Open | Product | URL shown once; no token recovery without new link |
| TR-R035 | Report generation is delayed/failed by worker or PDF dependency | 3 | 3 | 9 Medium | Mitigated | Eng | `QUEUED`/`FAILED` visible; retry; failure does not undo finalization |
| TR-R036 | Archived MinIO OSS remains unsafe for production | 4 | 2 | 8 Medium | Closed | Eng | Not used; SeaweedFS local test only |
| TR-R037 | Published/finalized rows could be edited by direct SQL | 4 | 2 | 8 Medium | Mitigated | Eng/DBA | MySQL triggers tested for jobs, assessments, findings, snapshots, evidence, reports, master/template versions; privileged DBA can disable |
| TR-R038 | HEIC server normalization depends on unavailable native `libheif` | 3 | 3 | 9 Medium | Open | Eng | Client normalizes to JPEG; HEIC server path not verified |
| TR-R039 | Local Drift PII/evidence is not encrypted at rest | 4 | 3 | 12 High | Open | Eng/Security | Fake data only; device storage/encryption policy unresolved |
| TR-R040 | Offline conflict recovery is simple | 3 | 3 | 9 Medium | Open | Product/Eng | Conflict state; no rich merge UI |
| TR-R041 | No OS background sync worker | 3 | 3 | 9 Medium | Open | Eng | Sync on save/reconnect/manual; queue survives restart |
| TR-R042 | Large template/job lists are not paginated | 3 | 3 | 9 Medium | Open | Eng | In-memory lists; pilot scale may be acceptable |
| TR-R043 | Placeholder master content could be mistaken for specialist-approved wording | 4 | 3 | 12 High | Open | Product/Automotive | `sampleData=true`; specialist not named/validated |
| TR-R044 | Last-admin recovery relies on Platform Admin process | 3 | 2 | 6 Medium | Mitigated | Ops | Guard + manual process; no self-service |
| TR-R045 | Manual invitation token delivery remains | 3 | 3 | 9 Medium | Open | Ops | D8 pending; one-time display/no-store |
| TR-R046 | MySQL Connector/J GPLv2 distribution concern remains | 3 | 2 | 6 Medium | Open | Legal/Eng | Hosted-only assumption; legal review needed |
| TR-R047 | Chrome copied from Playwright image may age | 3 | 2 | 6 Medium | Open | Ops | Version pinned; patch cadence review needed |
| TR-R048 | Runtime DB user/grants least privilege is not proven | 4 | 3 | 12 High | Open | DBA/Ops | V5A grant design exists; Compose uses one user |
| TR-R049 | Email PDF larger than provider limit | 3 | 2 | 6 Medium | Mitigated | Eng | 10 MiB limit; link fallback only with public-link consent |
| TR-R050 | Backups contain PII and their access/retention is not approved | 4 | 3 | 12 High | Open | Legal/Ops | Encryption script; restore tested; C2 pending |
| TR-R051 | Payment tables/endpoints could be added accidentally | 4 | 1 | 4 Low | Closed | Eng | Repository scan found none; scope fence |
| TR-R052 | Legal retention periods and deletion rights are undecided | 4 | 4 | 16 High | Open | Legal | C2 Pending; config placeholders |
| TR-R053 | Certificate-expiry alert is not deployed | 3 | 3 | 9 Medium | Open | Ops | Nginx TLS placeholder; no cert monitor |
| TR-R054 | Production secrets file/KMS integration is not verified | 4 | 3 | 12 High | Open | Ops | `production.env.example`; no secret manager test |
| TR-R055 | Public rate limiting remains single-instance | 3 | 3 | 9 Medium | Open | Eng/Ops | In-memory app limit + Nginx; no shared store |
| TR-R056 | S3 SSE/KMS, versioning, object-lock/backup lifecycle are untested | 4 | 3 | 12 High | Open | Eng/Ops | Local adapter test only |
| TR-R057 | Real provider webhook signature schemes are unproven | 3 | 4 | 12 High | Open | Eng | Fake HMAC only |
| TR-R058 | Message/link preview metadata may expose sender or context | 3 | 3 | 9 Medium | Open | Product/QA | Neutral bodies; real previews untested |
| TR-R059 | No report/link/PDF implementation | 4 | 1 | 4 Low | Closed | Eng | Phase 6 implementation and tests |
| TR-R060 | No report public allowlist | 4 | 1 | 4 Low | Closed | Eng | Snapshot allowlist/PII tests |
| TR-R061 | Additive schema migration risk | 2 | 2 | 4 Low | Closed | Eng | V9/V15/V16/V17 applied and tested |
| TR-R062 | No delivery implementation | 3 | 1 | 3 Low | Closed | Eng | Phase 7 delivery subsystem |
| TR-R063 | Delivery message body could expose customer data | 4 | 1 | 4 Low | Mitigated | Eng | Neutral body tests; Mailpit PII scan |
| TR-R064 | One link per report version | 3 | 1 | 3 Low | Closed | Eng | V13 + ADR-0018 |
| TR-R065 | Real recipient allowlist disabled by default | 3 | 3 | 9 Medium | Mitigated | Eng/Ops | Allowlist; production guard requires explicit real-recipient switch |
| TR-R066 | Local restart loses in-flight scheduled work | 3 | 2 | 6 Medium | Mitigated | Eng | DB-persisted jobs; due-time retry |
| TR-R067 | Guide image authorization could expose content | 4 | 1 | 4 Low | Closed | Eng | PA-only endpoint and tests |
| TR-R068 | Docker/MySQL path unverified | 4 | 1 | 4 Low | Closed | Eng | Compose and Testcontainers pass |
| TR-R069 | No Platform Admin read-only job/template oversight | 2 | 3 | 6 Medium | Open | Product | Intentional scope; support workaround |
| TR-R070 | Category ordering is derived from item order | 2 | 2 | 4 Low | Open | Product | Pilot feedback needed |
| TR-R071 | Evidence warnings were non-blocking | 4 | 1 | 4 Low | Closed | Eng | `EVIDENCE_REQUIRED` blocks |
| TR-R072 | Offline work absent | 3 | 1 | 3 Low | Closed | Eng | Drift/sync queue |
| TR-R073 | Guide images absent offline | 2 | 2 | 4 Low | Closed | Eng | Cached guide images |
| TR-R074 | Legacy frozen reports may lack metadata | 2 | 3 | 6 Medium | Open | Product | No invention; legacy blanks |
| TR-R075 | Public PDF flag could be unexpectedly enabled | 3 | 2 | 6 Medium | Mitigated | Eng | Off by default; audit; revocation |
| TR-R076 | PDF text extraction does not preserve Arabic glyphs in tooling | 2 | 3 | 6 Medium | Open | QA | Visual/native review still required |

---

## 2. Legacy ID mapping

| Legacy ID | Phase / previous meaning | New ID |
|---|---|---|
| R61 | Published master/template direct SQL | TR-R037 |
| R62 | Local storage not production | TR-R001 |
| R63 | Manual invitation token | TR-R045 |
| R66 | Sample content mistaken for final | TR-R043 |
| R67 | Image picker/device upload untested | TR-R010 |
| R68 | Last-admin recovery | TR-R044 |
| R69 | Invitation delivery | TR-R045 |
| R70 | Guide image authorization | TR-R067 |
| R71 | Docker/MySQL unavailable | TR-R068 |
| R72 | Workshop invitations absent | TR-R045 |
| R73 | Technician walk-ins absent | Not a current risk; implemented in 5A |
| R74 | MySQL triggers untested | TR-R037 |
| R75 | Job PII plaintext | TR-R003 |
| R76 | Placeholder checklist | TR-R043 |
| R77 | Platform job oversight absent | TR-R069 |
| R78 | Status transitions partial | Closed by later phases |
| R79 | Category ordering | TR-R070 |
| R80 | Large list pagination | TR-R042 |
| R81 | Evidence warnings non-blocking | TR-R071 |
| R82 | Customer/vehicle plaintext | TR-R003 |
| R83 | MySQL inspection triggers | TR-R037 |
| R84 | Offline absent | TR-R072 |
| R85 | Concurrency on H2 only | TR-R037 |
| R86 | 100+ item device performance | TR-R010 |
| R87 | Keyboard/RTL/accessibility device pass | TR-R010 |
| R88 | Guide image display absent | TR-R073 |
| R89 | Final snapshot PII | TR-R003 |
| R90 | HEIC normalization | TR-R038 |
| R91 | Local Drift growth | TR-R039 |
| R92 | Real-device offline matrix | TR-R010 |
| **R93 (5B)** | **Local disk storage/evidence** | **TR-R001** |
| **R93 (6/7)** | **No report/link/PDF implementation** | **TR-R059** |
| **R94 (5B)** | **No OS background sync** | **TR-R041** |
| **R94 (6/7)** | **No report allowlist** | **TR-R060** |
| **R95 (5B)** | **Simple offline conflict handling** | **TR-R040** |
| **R95 (6/7)** | **Report generation tied to finalization** | **TR-R035** |
| **R96 (5B)** | **Additive migration risk** | **TR-R061** |
| **R96 (6/7)** | **No MySQL report immutability** | **TR-R037** |
| R97 | MinIO unavailable | TR-R036 |
| R98 | Local PII unencrypted | TR-R039 |
| R99 | No video | Out of scope |
| R100 | Lost public URL | TR-R034 |
| R101 | Public evidence plates/faces | TR-R008 |
| R102 | PDF runtime size | TR-R032 |
| R103 | Chromium memory unmeasured | TR-R032 |
| R104 | In-memory public rate limit | TR-R055 |
| R105 | Arabic native review | TR-R009 |
| R106 | Real WhatsApp/iOS/screen reader | TR-R010 |
| R107 | Legacy metadata blanks | TR-R074 |
| R108 | Public PDF flag | TR-R075 |
| R109 | Worker queue delay | TR-R035 |
| R110 | Public page depends on report readiness | TR-R035 |
| R111 | No correction process | TR-R031 |
| R112 | Local storage dev-only | TR-R001 |
| R113 | Shared copies cannot be recalled | TR-R033 |
| R114 | PII unencrypted / no compliance | TR-R003, TR-R030 |
| R115 | Arabic PDF extraction tooling | TR-R076 |
| R116 | Chrome binary aging | TR-R047 |
| R117 | No delivery implementation | TR-R062 |
| R118 | Delivery body PII | TR-R063 |
| R119 | One link per report | TR-R064 |
| R120 | D8 provider undecided | TR-R011 |
| R121 | Allowlist/default recipients | TR-R065 |
| R122 | Multiple active links | TR-R033 |
| R123 | Provider preview metadata | TR-R058 |
| R124 | Webhook spoof/replay | TR-R057 |
| R125 | Retry storms/rate | TR-R017 |
| R126 | PDF attachment size | TR-R049 |
| R127 | Email deliverability | TR-R013 |
| R128 | Arabic delivery wording | TR-R009 |
| R129 | Real device/browser matrix | TR-R010 |
| R130 | Real provider status callbacks | TR-R012 |
| R131 | Local restart in-flight work | TR-R066 |
| R132 | Link retention | TR-R007 |
| R133 | Multi-instance coordination | TR-R017 |
| R134 | PII unencrypted | TR-R003 |
| R135 | Provider pricing/approval gate | TR-R011 |

---

## 3. Top risks

1. TR-R008 public photos may expose plates/faces.
2. TR-R009 Arabic native review.
3. TR-R010 real-device matrix.
4. TR-R011 D8 provider approval.
5. TR-R030/TR-R052 legal compliance/retention.
6. TR-R021 no independent penetration test.
7. TR-R002/TR-R056 selected S3 provider, KMS and lifecycle unproven.
8. TR-R003/TR-R004 PII encryption residual and key custody.
9. TR-R018/TR-R019 dependency advisory coverage.
10. TR-R032 PDF concurrency memory.

---

## 4. Owner key

- **Eng:** backend/mobile owner.
- **Security:** security reviewer.
- **Ops:** deployment/on-call owner.
- **Product:** product owner.
- **Legal:** counsel; cannot be closed by engineering.
- **Automotive:** named automotive specialist.
- **Arabic:** named native Arabic reviewer.
- **QA:** pilot/device test owner.
- **DBA:** database administrator.
---

## 5. Phase F1 design-system risks (5 November 2026)

These are additional to the product risks above. F1 is a design-system/UI phase; no business logic or public allowlist was changed.

| ID | Risk | Likelihood | Impact | Current mitigation / status | Owner |
|---|---|---|---|---|---|
| F1-R01 | Noto Sans SC adds 15.68 MiB to every app build, although it is only for zh-Hans | High | Medium | Accepted in ADR-F1-002; subsetting or lazy loading is a candidate before release | Eng |
| F1-R02 | Arabic native review not performed; Arabic shaping/RTL is only table- and render-tested | High | High | Noto/IBM candidates and RTL tests exist; native reviewer still required | Arabic |
| F1-R03 | Goldens were generated/passed on Windows only; CI Linux may differ | Medium | Medium | 20 goldens pass on Windows; tolerant/cross-platform comparator still to be chosen | Eng |
| F1-R04 | Three F1 component fidelity samples fail the 0.98 SSIM gate (0.938 / 0.880 / 0.756) | High | High | Residuals are listed in 1-report.md; owner acceptance or rework required before F2 | Product |
| F1-R05 | Emerald fill boundary is 2.42–2.54:1 against the surface | Medium | Medium | A2 approved fill-only; primary button now has a 1.5 dp deep-green boundary; exception pending owner sign-off | Product |
| F1-R06 | Decorative outlineVariant dividers are 1.14–2.19:1 | Low | Low | Not the sole boundary of interactive controls; exception pending owner sign-off | Product |
| F1-R07 | Screen-reader activation fixes are code/test reviewed but not tested with TalkBack/VoiceOver | Medium | High | Semantics onTap added; manual device pass required | QA |
| F1-R08 | Directional icon mirroring is only implemented for AppIcon.arrowForward; legacy IconData uses are not auto-mirrored | Medium | Medium | Screen-level RTL review in F2 will catch remaining icons | Eng |
| F1-R09 | Gallery control labels are not localized | Low | Low | Developer-only gallery; not shipped | Eng |
| F1-R10 | HTML report uses Plus Jakarta Sans/Noto Sans Arabic while the PDF still embeds Noto Sans/Naskh/SC | Medium | Medium | Token colours match; font parity deferred to F5 | Eng |
| F1-R11 | Five Figma SVG icons are user-provided; provenance/licence is not independently verified | Medium | Low | Copied with stable names; lutter_svg is MIT; no runtime fetch | Product |
| F1-R12 | Widget tests use an in-memory offline store; the production drift store is not exercised in those tests | Low | Low | Deterministic tests; real store has its own test coverage | Eng |
| F1-R13 | F1 changes are uncommitted | High | Low | Review and commit only after owner approval | Product |

---

## 6. Phase F1.1 fidelity-first rework risks (5 November 2026)

F1.1 reverted the design-system drift to the Figma values. No business logic,
API contract, model, validation, permission, state-management or server logic was
changed. The F1-R04 fidelity residual is closed for the three measured
components; the remaining items are open decisions or unverified areas.

| ID | Risk | Likelihood | Impact | Current mitigation / status | Owner |
|---|---|---|---|---|---|
| F1.1-R01 | Primary-button colour is still undecided; option 1 (Figma white label on `#10B981`) is 2.54:1 and fails even the large-text 3:1 allowance | High | High | Four options measured in `contrast-after.md`; product default remains the ink-label option 3 (6.78:1); owner decision pending | Product |
| F1.1-R02 | Borderless text field is Figma-exact but its fill against white is 1.09:1, below WCAG 2.2 1.4.11 for an input boundary | High | High | Documented as open deviation O-01; choice is accept Figma or restore a 1.5 dp boundary; not silently accepted | Product |
| F1.1-R03 | Product type scale keeps 12 px labels and 12/18 body instead of Figma 11/13 px (B1) | Medium | Low | Owner-approved B1; exact variants use `FigmaType` 11/13; measured samples pass | Product |
| F1.1-R04 | Only three components have a Figma-exact SSIM sample; the other shared components are structurally rebuilt but not measured at 0.98 | Medium | Medium | Three samples pass (0.99520 / 0.99198 / 0.98340); remaining components listed in the audit as unmeasured | Eng |
| F1.1-R05 | Figma-exact fixtures use Figma sample copy (`Fleet Portal`, `Pass`/`Minor`/`Major`) | Low | Medium | Test-only fixtures under `docs/.../fidelity` and `test/`; gallery hidden in release by `FixtureGuard`; product copy uses approved vocabulary | Eng |
| F1.1-R06 | Figma-exact samples are Windows-only and renderer-dependent; a Linux CI or a Flutter/font update can shift SSIM | Medium | Medium | Measured on Flutter 3.47.9 with the bundled OFL fonts; rerun the capture+compare command in CI when added | Eng |
| F1.1-R07 | One `admin_app` still serves both admin roles with a flat `pages/` folder; Workshop header is 80 px vs the shared 64 px | Medium | Medium | App-structure report recommends keeping A with role skins and a folder boundary; owner decision pending | Product |
| F1.1-R08 | `ui_gallery` is dev-only by structure plus a release guard, but the guard is not a security boundary | Low | Low | `FixtureGuard`, release-blocked entry, and a release-guard test; no product/infra/CI reference | Eng |
| F1.1-R09 | Server authorization relies on URL-prefix rules for several controllers; `/api/v1/workshops/{id}` has no method annotation | Medium | High | Server tests cover role separation; recommend method annotations/ArchUnit; unchanged by the UI work | Security |
| F1.1-R10 | Motion tokens cannot be compared to Figma because the export has no motion data | Low | Low | Reported as unverified; F1 motion retained | Eng |
| F1.1-R11 | F1.1 changes are uncommitted | High | Low | Review and commit only after owner approval | Product |

## 7. Phase F2-A technician screen risks (5 November 2026)

F2-A is a UI-only refresh of technician screens 1 to 7. No server, API, model, validation, permission or state-management change was made. Screen 6 is blocked by missing equipment names.

| ID | Risk | Likelihood | Impact | Mitigation / status | Owner |
|---|---|---|---|---|---|
| F2A-R01 | Fidelity gate (SSIM >= 0.98, no unexplained diff > 4 px) is not met on any of the six built screens (0.7723-0.8860) | High | High | Residuals are measured and listed in `docs/ui/figma/f2a-report.md` and each per-screen `REPORT.md`; caused by P1/P2, required removals and copy. Owner must accept, or change P1/P2/removals | Product |
| F2A-R02 | Screen 6 equipment checklist cannot be built: the technician API returns `equipmentIds` only | High | Medium | Screen not faked; existing sheet states names are unavailable; needs a small server/API change or stays deferred | Product/Eng |
| F2A-R03 | Borderless field fill boundary is 1.10:1 light / 1.18:1 dark, below 3:1 | High | Medium | Accepted under P2; visible label above and F1 focus ring; listed in `deviations.md` and `contrast-after.md` | Product |
| F2A-R04 | Large primary label white on `#059669` is 3.77:1, below 4.5:1 normal text | Medium | Low | P1 requires 19 px bold (large text, 3:1 threshold); measured and recorded | Product |
| F2A-R05 | Arabic is derived from the same tokens; no native review and no Arabic Figma frame | High | High | EN/AR goldens, RTL matrix, LTR VIN/plate/numerals; native reviewer still required | Arabic |
| F2A-R06 | Real device, sunlight, one-hand reach and screen-reader behaviour were not tested | High | Medium | Manual pass on a real Android/iOS device is in the report checklist | QA |
| F2A-R07 | Goldens were generated on Windows only | Medium | Medium | 18 F2-A goldens pass on Windows; cross-platform comparator still to be chosen | Eng |
| F2A-R08 | Product dock is 3 items (Jobs/Sync/Profile); Figma shows 4 (Intake/Fleet/Sync/Profile) | Medium | Low | P7 default; 4-item layout is gallery-only; no Fleet route | Product |
| F2A-R09 | Figma sample copy exists in test-only fixtures | Low | Medium | Fixtures live under `test/` and `docs/.../fidelity`; gallery dock is behind `FixtureGuard`; product fixtures use neutral data | Eng |
| F2A-R10 | F2-A changes are uncommitted | High | Low | Review and commit only after owner approval | Product |
