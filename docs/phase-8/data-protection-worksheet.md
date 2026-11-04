# Phase 8 Data-Protection Worksheet for Counsel

**Project:** TrueReport  
**Status:** Worksheet, not legal advice. Counsel must decide all legal conclusions.

---

## 1. Roles and scope

- First market: UAE. Future market: India (not launched).
- Partner workshops collect customer/vehicle data and contract with the customer.
- TrueReport is likely a processor for workshop data; controller/processor terms must be confirmed by counsel.
- No customer account, app, portal, marketing profile or payment data.
- No PDPL/GDPR/DPDP compliance is claimed.

---

## 2. Data collected

| Data | Purpose | Where stored | Who can access | Public? | Current protection | Proposed retention |
|---|---|---|---|---|---|---|
| Customer name | Identify job/customer | MySQL job row; encrypted final snapshot | Workshop staff, limited Platform Admin oversight, support | No | App AES-256-GCM at rest | Pending C2 |
| Phone | Delivery/support | MySQL job row; recipient hash in delivery | Workshop Admin, delivery adapter, support | No | Encrypted; masked/hash in delivery | Pending C2 |
| Email | Delivery/support | MySQL job row; recipient hash in delivery | Workshop Admin, delivery adapter, support | No | Encrypted; masked/hash in delivery | Pending C2 |
| VIN | Identify vehicle | MySQL job row/final snapshot | Workshop staff, support | Masked last 4 only in report | Encrypted at rest | Pending C2 |
| Plate | Identify vehicle | MySQL job row/final snapshot | Workshop staff, support | No | Encrypted at rest | Pending C2 |
| Inspection answers/notes/photos | Produce report | MySQL; object storage | Workshop staff, Platform Admin oversight, support | Allowlisted report fields/derivatives | Private storage; public derivatives only | Pending C2 |
| Consent records | Evidence of consent | MySQL append-only | Workshop/Platform Admin, support | No | Append-only | Pending C2 |
| Audit events | Accountability | MySQL append-only | Platform Admin/support | No | Append-only; no bodies | Pending C2 |
| Delivery rows | Delivery status | MySQL | Workshop/Platform Admin, support | No | Masked/hash recipient | Pending C2 |
| Public token hash | Link lookup | MySQL | System | No | SHA-256 hash only | While report/link retained |
| Backups | DR | Encrypted file/off-site | Ops/DBA | No | Encrypted script; key separate | Pending C2 |
| Device local Drift data | Offline work | Device app-private storage | Technician on device | No | Platform sandbox; **not app-encrypted** | Pending C2 |
| Logs/metrics | Operations | Server/log platform | Ops/Security | No | No request bodies/PII in code review; not centrally proven | Pending C2 |

---

## 3. Storage and processing locations

| Component | Current | Production question |
|---|---|---|
| MySQL | Local Docker | Which UAE region/host? Backup region? |
| Files/evidence/PDFs | Self-hosted filesystem on a persistent volume | Which server/volume? Full-disk/volume encryption and off-site backup? |
| Server/Chromium | Local Docker | Which host/region? Logs? |
| Email | Mailpit local | Which provider/region? SPF/DKIM/DMARC? |
| WhatsApp/SMS | Fake only | Which provider/BSP? UAE data routing? |
| Error tracking | None | Sentry or equivalent? Scrubbing? |
| Monitoring | Local configs | Hosted or self-hosted? Retention? |

No production provider, region or contract has been selected. Counsel must review cross-border transfers and subprocessors before real data.

---

## 4. Access and security controls

- Tenant-scoped API; role checks; anonymous endpoint coverage test.
- Admin TOTP + recovery codes + 15-minute lockout after 5 failures.
- PII encryption at rest for job fields and final snapshots; key IDs for rotation.
- Public links: 256-bit token, hash only, consent gate, revocation, no-store, noindex.
- Files are stored on the self-hosted server volume and served only through backend/token endpoints; no cloud object storage.
- Finalized report rows and triggers tested immutable.
- Private evidence; public derivatives only; plates/faces not blurred (open policy).
- Backups encrypted by script; restore tested into fresh MySQL.
- Local device data not encrypted by the app.
- A privileged DBA can bypass application encryption/triggers.

---

## 5. Data-subject requests

| Request | What can be done | What cannot be done / needs policy |
|---|---|---|
| Access | Export job/report data through an approved support process | No self-service portal |
| Correction | Intake fields before finalization; finalized report correction has no workflow | D9 correction policy missing |
| Deletion | Delete/disable eligible records and objects after retention approval | Finalized reports/audit/backups may need retention; copies already shared cannot be recalled |
| Revocation | Revoke public links immediately | Cannot recall screenshots/downloaded PDFs |
| Objection/withdrawal | Record consent withdrawal and revoke link | Does not erase already shared copies |

---

## 6. Questions for counsel

1. Controller/processor roles and contract terms.
2. Lawful basis and exact consent/privacy wording (C2).
3. Retention periods for jobs, reports, evidence, audit, delivery rows, backups and logs.
4. Data-subject request procedure, identity verification and response timelines.
5. Cross-border transfer position for each proposed host/provider.
6. Subprocessor list, data-processing terms and breach-notification obligations.
7. Whether a DPIA is required.
8. Deletion/erasure limits for immutable reports, audit and backups.
9. Photo policy for plates/faces and public evidence.
10. Whether the product may describe itself as ?secure?, ?encrypted? or ?compliant? in customer materials.
