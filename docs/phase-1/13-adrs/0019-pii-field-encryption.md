# ADR-0019: Application-level PII encryption and key IDs

- **Status:** Accepted for Phase 8
- **Date:** 4 November 2026
- **Owner:** Security/backend lead

## Context

Customer name, phone, email, VIN and plate were stored as plaintext job columns. The final inspection snapshot also contained those values internally. The database is backed up, copied and administered separately from the application; at-rest exposure is therefore a real risk.

## Options

1. Database TDE/disk encryption only (not available as a portable application control here).
2. Encrypt all columns with a single unversioned key (rotation and old-key failure are painful).
3. **Application-level AES-256-GCM with key IDs and a small key ring** (chosen).
4. Tokenize PII into a separate service (rejected for pilot complexity; no provider selected).

## Decision

- Use AES-256-GCM with a 12-byte random IV and a 128-bit tag.
- Store `<key-id>:<base64(iv+ciphertext)>`.
- Encrypt `inspection_jobs` customer name/phone/email/VIN/plate and `inspection_final_snapshots.snapshot_json`.
- Load the key ring from `APP_PII_KEYS` with `APP_PII_ACTIVE_KEY_ID`; use `APP_ENCRYPTION_KEY` as the v1 local fallback.
- Keep retired keys for decryption; new writes use the active key.
- Run a one-time Flyway Java data migration for existing fake rows and restore the finalized-job/snapshot triggers.
- Keep recipient matching on the existing SHA-256 recipient hash; current job search is in-memory after decryption.
- Do not claim that backups, local Drift, database memory/logs or a privileged DBA are protected by this control.

## Consequences

- Database readers cannot search encrypted columns directly; current search loads and decrypts jobs in memory.
- Key loss makes affected rows unrecoverable; key custody must be operationally approved.
- A migration touching finalized rows requires controlled trigger removal/recreation; this was tested on MySQL.
- Report snapshot hashes remain hashes of plaintext, so integrity checks are unchanged.
- Backups and local device data require separate controls.

## Follow-ups

- Move the key ring to a secret manager/KMS; never commit keys.
- Add an audited re-encryption job for key rotation.
- Add automated log/PII leakage tests.
- Approve backup encryption, key custody and retention with counsel.
