# Phase 5A Risk Register Update

**Project:** TrueReport  
**Date:** 3 November 2026  
**Baseline:** `docs/phase-4/risk-register-update.md` and `docs/phase-1/14-risk-register-update.md`

---

## 1. New and updated risks

| ID | Risk | Impact | Likelihood | Score | Mitigation | Early warning |
|---|---|---|---|---|---|---|
| R81 | Phase 5A evidence requirements are warnings, not blockers | 4 | 4 | 16 High | `EVIDENCE_PENDING_5B` is explicit in review/finalization; no evidence is fabricated; 5B must convert required evidence to blocking | A finalized 5A inspection is treated as evidence-complete |
| R82 | Customer/vehicle PII is still stored unencrypted | 4 | 3 | 12 High | Fake-only data; encryption/retention deferred to Phase 5B/6 and C2 | Real customer data entered in 5A |
| R83 | MySQL V8 inspection triggers are written but untested | 4 | 4 | 16 High | Run MySQL migration/trigger tests in Docker CI before production; service guards remain primary | Trigger creation fails or direct SQL changes finalized data |
| R84 | Offline mode and local persistence are absent | 3 | 5 | 15 High | Phase 5B scope; 5A clearly requires online/server receipt | Weak workshop connectivity blocks inspections |
| R85 | Concurrency was tested on H2, not MySQL | 3 | 3 | 9 Medium | Pessimistic lock and idempotency tests exist; repeat on MySQL in CI | MySQL lock timeout or duplicate finalization |
| R86 | 100+ item checklist performance in Flutter is untested on a device | 3 | 3 | 9 Medium | Server 105-item end-to-end test; UI tests small fake data; device test in 5B | Slow rendering/scroll on low-end phone |
| R87 | No real-device keyboard/RTL/accessibility pass | 3 | 3 | 9 Medium | Widget tests cover layouts; manual device matrix remains | Arabic/Russian/Chinese input issues in pilot |
| R88 | No guide-image display in technician item assessment | 2 | 3 | 6 Medium | Guide image content endpoint is not wired in 5A; placeholder/instruction text shown | Technician cannot see instructional image |
| R89 | Final snapshot includes customer/vehicle data in the internal JSON | 4 | 2 | 8 High | Internal-only, hash-protected, no report/public link in 5A; retention/encryption pending | Snapshot exposed outside authorized support |

---

## 2. Updated existing risks

| Risk | Change |
|---|---|
| R61 | Service guards now cover finalized inspections; MySQL triggers added but untested. |
| R74 | Additional V8 triggers increase the untested MySQL surface. |
| R13 | Pinned item snapshots are tested at start and finalization. |
| R25 | No offline, evidence, report, delivery, correction, review queue or payment features added. |
| R02 | New technician endpoints are role- and workshop-checked; cross-workshop tests added. |
| R75 | Customer/vehicle plaintext risk remains; Phase 5A does not resolve encryption. |

---

## 3. Top Phase 5A risks

1. R81 evidence warnings are not a final gate.
2. R83 MySQL triggers remain unproven.
3. R82/R89 unencrypted customer/vehicle data.
4. R84 offline work is not available.
5. R86/R87 real-device performance, keyboards and accessibility.
6. R85 MySQL concurrency/locking remains to be proven.
7. R88 guide-image display is deferred.

---

## 4. Decisions needed

- D11 photo limits and evidence blocking rules for 5B.
- D6 production storage and D8 delivery remain Pending.
- C2 retention/consent/legal wording before real customer data.
- Confirm whether guide images must be visible in the technician assessment for Phase 5B.
- Run MySQL 8.4 migrations and trigger tests in CI.
