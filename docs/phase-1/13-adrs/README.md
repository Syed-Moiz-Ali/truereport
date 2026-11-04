# Architecture Decision Records (Phase 1)

**Project:** TrueReport  
**Status:** Phase 1 decision records. Decisions marked **Accepted** are binding; Pending/Proposed records remain open.

| ADR | Title | Status |
|---|---|---|
| [0001](0001-mysql-84-lts.md) | MySQL 8.4 LTS | **Accepted** — D1 |
| [0002](0002-one-admin-app.md) | One admin app for both admin roles | **Accepted** — D2 |
| [0003](0003-riverpod.md) | Riverpod for state management | **Accepted** — D3 |
| [0004](0004-server-rendered-public-report.md) | Server-rendered HTML public report | **Accepted** — D4 |
| [0005](0005-headless-chromium-pdf.md) | Headless Chromium for the bilingual PDF | **Accepted** — D5 |
| [0006](0006-production-object-storage.md) | Production object storage shortlist | Proposed — D6 Pending |
| [0007](0007-no-correction-until-policy.md) | No correction UI/API until policy approved | **Accepted constraint** — D9 |
| [0008](0008-consent-gate-and-pdf-download.md) | Consent gate and PDF-download default | **Accepted** — role/consent/PDF defaults |
| [0009](0009-uuidv7-and-immutability.md) | UUIDv7 BINARY(16) and layered immutability | Accepted for Phase 2; full immutability later |
| [0010](0010-public-token-and-allowlist.md) | Public token and allowlist boundary | Proposed |
| [0011](0011-role-and-account-defaults.md) | Role and account defaults | **Accepted** — role defaults |
| [0012](0012-localization-and-numerals.md) | Localization, RTL and numeral defaults | Partially accepted — `zh-Hans`; numerals Pending |
| [0013](0013-admin-totp.md) | Admin TOTP | **Accepted** — D12 |
| [0014](0014-master-content-versioning.md) | Master content versioning | Accepted for Phase 3 |
| [0015](0015-guide-images-and-local-storage.md) | Guide images separate from evidence; local dev storage | Accepted for Phase 3; D6 Pending |
| [0016](0016-template-version-pinning.md) | Template version pinning and safety-rule locking | Accepted for Phase 4; MySQL triggers untested |
| [0017](0017-online-inspection-finalization.md) | Online inspection execution and immutable finalization | Accepted for Phase 5A; MySQL triggers untested; 5B evidence reserved |
| [0018](0018-delivery-link-generation.md) | New public link per delivery send | **Accepted for Phase 7** |
| [0019](0019-pii-field-encryption.md) | Application-level PII encryption and key IDs | **Accepted for Phase 8** |
| [0020](0020-self-hosted-filesystem-storage.md) | Self-hosted filesystem storage supersedes cloud storage for D6 | **Accepted by owner - Phase 8.1** |
| [0021](0021-admin-totp-configurable.md) | Admin TOTP configurable and off by default | **Accepted by owner - Phase 8.1** |

## How to read an ADR

Each record contains: context, options, decision, status, consequences, follow-ups and what was not proven. A “Proposed” ADR is safe for design work but must not be treated as a production approval.
