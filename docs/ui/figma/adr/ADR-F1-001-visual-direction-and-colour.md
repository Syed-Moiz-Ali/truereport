# ADR-F1-001 — Hybrid visual direction and accessible colour strategy

- **Status:** accepted
- **Date:** 5 November 2026
- **Phase:** F1
- **Deciders:** product owner; integration lead

## Context

Phase F0 found that the Figma exports use a consistent emerald system (`#10B981` fill, `#006C49` deep green) but fail WCAG 2.2 AA in the common pairings: white on `#10B981` is 2.54:1, and `#10B981` on white is 2.54:1. The current TrueReport tokens are teal (`#0B3B4A` / `#0F6B6F`) and already pass. The owner chose a hybrid direction: Figma layout, shapes, type and component structure, with our accessible colour and semantic rules.

## Decision

1. Keep the Figma layout/shape/type/component language, not a wholesale palette replacement.
2. Keep the Phase 1 semantic status and severity pairs; do not introduce a second green with a different meaning.
3. Use emerald `#10B981` **only as a fill**, with a dark ink label `#1A1B1F`. White text on `#10B981` is prohibited.
4. Use deep green `#006C49` for brand text and icons on light surfaces.
5. Provide an alternative token set behind one switch: deep green `#006C49` fill with white label. Both sets are shown side by side in the gallery for the owner to compare.
6. Light-first; dark is a derived theme from the same semantic tokens and is tested, but is not a Figma fidelity target.
7. Brand name is **TrueReport**; `TechInspect`, `Apex` and `ShopFlow` in the exports are placeholders.

## Consequences

- A token contract is required; raw emerald/fill values must not appear in widgets.
- Every text/background and UI pair is measured in `contrast-after.md`.
- The public report and PDF share the same semantic names and values via generated CSS.
- The gallery must render both A2 variants and all status/severity pairs.

## Rejected alternatives

- **Full Figma palette:** fails contrast as drawn and would require changing every screen and report.
- **Keep current teal only:** loses the approved visual direction.
- **White label on emerald:** fails 4.5:1 and is not permitted.
