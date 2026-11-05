# F1 privacy and public-report boundary review

**Reviewer:** `privacy-reviewer`  
**Date:** 5 November 2026 (final, after integration fixes)  
**Scope:** consent fix, components/tokens/gallery, fidelity fixtures, public report, server diff  
**Method:** read-only inspection of code, tests, tokens, docs and `git status`/`git diff`; ran the token checks, direct lint probes and the three new fidelity fixtures. No application code, test, token or doc was edited except this report. No server was run.

## Verdict

**Pass.** No blockers, no open medium/low conditions. Three informational notes remain.

## Findings

| ID | Status | Severity | Area | Evidence |
|---|---|---|---|---|
| PR-F1-01 | Closed | Medium | Public-report token integration | `report.css:1` imports `tokens.g.css`; `print-report.html` has the `TOKENS:BEGIN/END` block. Both `wire-print-tokens.mjs --check` and `generate.mjs --check` exit 0. |
| PR-F1-02 | Closed | Medium | Forbidden-term lint | `lint.mjs` now uses `(?<![\p{L}\p{N}_])…(?![\p{L}\p{N}_])` with `giu`. Arabic probes now match (`شهادة`, `الهاتف`, `الموقع`, `تم التحقق`). `uae-plate-value` and `uae-area-address` patterns added. Fixtures: `arabic-certification-bad` FAIL (3 matches), `plate-address-bad` FAIL (2 matches), `arabic-safe` PASS (0 matches). |
| PR-F1-03 | Closed | Low | Consent coverage | `type` and `granted` both start null; Save requires both; records only on Save. Tests cover PROCESSING+GRANTED and PUBLIC_LINK+REFUSED with zero records before Save and assert recorded type/status. |
| PR-F1-04 | Closed | Low | Fixture build guard | Fixtures remain under `docs/ui/figma/` and `design_system/test/`; no pubspec references them. No immediate risk; optional CI asset-manifest check. |
| PR-F1-05 | Info | Info | Public/print template (pre-existing) | `public-report.html` is unchanged. Both templates show masked VIN, technician display name and workshop/branch; no full VIN, plate, customer, phone, email or location. PDF remains conditional on `pdfDownloadEnabled` (default false). Claims are negative disclaimers only. Confirm allowlist-pending technician/branch fields before Phase 5. |
| PR-F1-06 | Info | Info | Deny-list false positives | Terms `official`, `certificate`, `score`, `phone`, `location` flag legitimate negative disclaimers and masked-VIN labels if the lint is later applied to the public report. It is currently scoped to F1 samples. |
| PR-F1-07 | Info | Info | Harness report wording | `compare.mjs` headlines every gate failure as “SSIM threshold 0.98” even when the forbidden-term gate failed; the gate table correctly shows `SSIM pass` and `Forbidden terms fail`. Reporting clarity only. |

## What is already correct

- Consent starts with `type` and `granted` null; Save requires both; records only after explicit Save; `PROCESSING`/`PUBLIC_LINK` remain separate; no new consent type. Server still requires PUBLIC_LINK consent before activation (`ReportService.java:148`).
- No new fields, endpoints, analytics, logging or real PII in F1 components/gallery; gallery data is synthetic.
- Server changes are static presentation only: `report.css` and `print-report.html`. No Java changed; `public-report.html` is unchanged.
- Public allowlist, PDF gating and negative-claim wording are unchanged; no write/portal actions.
- Fixtures remain outside all pubspec asset declarations.

## What remains unverified

- The Flutter consent test and full suite were not executed (read-only inspection).
- The server was not run; runtime PDF configuration and actual snapshot/DTO output were not exercised.
- No end-to-end public-report PII scan was performed.
