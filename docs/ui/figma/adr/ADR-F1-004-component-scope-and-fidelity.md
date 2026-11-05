# ADR-F1-004 — Component scope, gallery and fidelity gate

- **Status:** accepted
- **Date:** 5 November 2026
- **Phase:** F1
- **Deciders:** product owner; integration lead

## Context

The F0 gap report classifies 45 Figma screens as 16 matches, 7 UI-only, 10 needing new data/server work and 12 conflicting with locked rules. Building every Figma pattern would smuggle deferred features and forbidden content into the design system. The owner approved building only components used by approved screens and a measured fidelity gate.

## Decision

1. Build only the component groups required by the F1 scope and approved F2–F5 screens:
   buttons, icon buttons, cards, filled inputs, chips/severity badges/result selector, segmented control/language switch, floating bottom nav dock, progress ring/coverage, sheet/dialog, list row, section header, empty/error/offline/skeleton, data table, tree view, admin sidebar/top bar.
2. Do not build damage canvas, annotation editor, signature pad, print studio, swipe-to-confirm, 360 vehicle, platform settings, dashboards, TOTP or marketplace components.
3. Provide a runnable gallery with EN/AR, light/dark, text scale 1.0/1.5/2.0 and both A2 colour strategies.
4. Provide a fidelity harness that renders at the exact Figma logical size (390 or 1280) at DPR 2 with bundled fonts, and produces `figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json` and `REPORT.md`.
5. The gate is structural plus measured visual: SSIM ≥ 0.98, no unexplained difference region larger than 4 logical px, key boxes within 2 px, exact token/string checks, and a forbidden-term lint.
6. Fidelity fixtures are test-only, guarded from release builds; product fixtures are neutral and non-PII.
7. At F1 the harness is validated on component-level samples; real screens start in F2.
8. Accessibility is part of the gate: 48 dp targets (56 dp primary technician), 200% text, RTL, focus visibility, reduced motion, semantics.

## Consequences

- Some Figma visuals cannot be reproduced in F1 because their data/feature is deferred; that is intentional.
- The gallery and harness become the shared evidence for every later screen phase.
- No "pixel-perfect" claim is made; residuals are measured and accepted.

## Rejected alternatives

- **Build every Figma component:** imports forbidden/deferred scope.
- **Visual review only:** cannot support a fidelity claim.
- **Strict pixel equality:** unrealistic across Flutter/Chromium/font renderers.
