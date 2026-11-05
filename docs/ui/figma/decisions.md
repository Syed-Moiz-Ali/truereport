# F1 design decisions (owner-approved)

**Project:** TrueReport
**Phase:** F1 — design system, shared components, gallery, fidelity harness
**Date:** 5 November 2026
**Status:** accepted for implementation. Anything left as "recommended" in `decisions-needed.md` is approved as written.

This file records the owner decisions supplied for F1. The ADRs are in `docs/ui/figma/adr/`.

| ID | Decision | ADR / note |
|---|---|---|
| A1 | **Hybrid** direction: Figma layout, shapes, type and component structure; our accessible colour/semantic rules | ADR-F1-001 |
| A2 | Emerald `#10B981` as a **fill only**, with a dark ink label (never a white label on `#10B981`). Deep green `#006C49` fill + white label is available behind one switch and shown side by side in the gallery. | ADR-F1-001 |
| A3 | Bundle Plus Jakarta Sans (Latin) and an Arabic sans (Noto Sans Arabic and IBM Plex Sans Arabic candidates; gallery shows both; native reviewer picks later). Noto Sans SC for `zh-Hans` only. Cyrillic fallback required. Licences and coverage recorded. | ADR-F1-002 |
| A4/A5 | Hybrid radii and spacing: add large-card radii 24/32 and extend spacing modestly. Outliers map to the nearest token and are listed. | ADR-F1-003 |
| A6 | Light-first. Dark mode is a derived theme from the same tokens; it is not a Figma fidelity target. | ADR-F1-001 |
| A7 | Build only components used by approved screens. | ADR-F1-004 |
| A8 | Brand: **TrueReport**. | ADR-F1-001 |
| B1 | Minimum text: 12 px labels, 14 px body, 16 px body for the technician flow. No 11 px text. | ADR-F1-002 |
| B2 | Targets at least 48 dp; 56 dp for primary technician actions. | ADR-F1-004 |
| B3–B5 | Responsive scrolling layouts, visible focus tokens, Arabic design pass before Arabic fidelity. | ADR-F1-004 |
| B6 | Consent switches must not be pre-ticked. A consent record is created only after an explicit action. Separate small privacy fix. | ADR-F1-005 |
| C1–C4 | Defer all: 360 pins, photo markup, tyre PSI/tread, BLE/OBD/NFC/hardware, signature pad, dashboards, settings screens, TOTP screen. None is built in any UI phase. | `gap-report.md`; F6 only by separate approval |
| D1–D3 | Safe subset only. Omit anything the model does not have. km, UTC+4 and AED via locale formatting. | `gap-report.md` |
| D6-a | Approved: test-only fidelity fixtures with Figma-like sample text, guarded from release builds. | ADR-F1-004 |
| E1–E6 | Public report: keep our information structure and allowlist; apply the Figma look. PDF download off by default. Coverage counts only (no score). No vehicle hero photo. Factual report fingerprint only, no tamper-proof/ledger/certificate claims. Keep light and dark. | ADR-F1-001, ADR-F1-003 |
| F1–F7 | Restyle current shells. Account creation stays Platform-Admin-only. Audit stays read-only. Master content stays draft/version/publish. Build dropdown and equipment UI with existing fields. Restyle the report viewer. | `gap-report.md`; no server/business changes |
| G1–G3 | Fidelity gate: structural + measured visual; SSIM ≥ 0.98; no unexplained difference > 4 px; every residual listed and accepted in writing. | ADR-F1-004 |

## Defaults adopted where the owner table says "recommended"

These are implementation defaults, not new product decisions:

- `A2` default = emerald fill `#10B981` + ink label `#1A1B1F`; alternative = deep green fill `#006C49` + white label.
- `A3` default Arabic face = Noto Sans Arabic for the first gallery build; IBM Plex Sans Arabic is shown next to it.
- `A4/A5` large-card radii = 24 and 32; spacing scale = 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Other Figma values are mapped to the nearest token and listed in `tokens.md`/the F1 report.
- `A6` light is the fidelity target; dark is a derived, tested theme.
- `B1` body = 14; technician body = 16; labels = 12 minimum.
- `B2` target = 48 minimum; primary technician action = 56.
- `G1` harness metric = SSIM + RMSE + ΔE2000 + key-box geometry, with a JSON and Markdown report per sample.

## Locked constraints for F1

- No change to business logic, API contracts, models, validation, permissions, state management or the server, except the approved consent default fix (B6).
- Locked rules still apply: immutability, public-report allowlist, no certification claims, no single score, Arabic RTL, WCAG 2.2 AA, no hardcoded colours/sizes/radii/shadows/endpoints in widgets.
- No runtime font downloads. No invented versions, licences, measurements or results.
- No commit in F1.
---

## F1 implementation status (5 November 2026)

- A1, A2, A3, A4/A5, A6, A7, A8, B1–B6 and D6-a are implemented as described above.
- C1–C4 remain deferred; no deferred feature component was built.
- E1–E6 and F1–F7 remain the rules for F5/F3/F4; F1 did not build those screens.
- G1–G3: the harness, gallery and measured reports exist. Three component-level samples are below the 0.98 SSIM threshold and are listed as residuals in 1-report.md; they are **not** accepted as passing yet.
- Owner decisions still pending: (1) accept or reject the 14 contrast exceptions, (2) accept or rework the three fidelity residuals, (3) choose the Arabic font after native review, (4) accept or reduce the 15.68 MiB Noto Sans SC cost, (5) decide whether PDF fonts must match the HTML stack.