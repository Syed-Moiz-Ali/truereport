# ADR-F1-003 — Token source of truth, Dart/CSS generation and sync

- **Status:** accepted
- **Date:** 5 November 2026
- **Phase:** F1
- **Deciders:** product owner; integration lead

## Context

The F0 audit found 133 raw colour values, radius values from 6 to 48, 127 effect definitions and no Figma variables or shared styles. The product already has Flutter `ThemeExtension` tokens and a separate `report.css` with its own variables. Two hand-maintained token sets would drift. The locked rule requires colours, type, radii, spacing and endpoints to come from central tokens, and the public report/PDF must match.

## Decision

1. A single machine-readable token file is the source of truth: `client/packages/design_system/tokens/tokens.json`.
2. A Node generator (`tools/design_tokens/generate.mjs`) emits:
   - `client/packages/design_system/lib/src/generated/tokens.g.dart` (typed constants);
   - `server/src/main/resources/public-report/tokens.g.css` (light, dark and print custom properties);
   - the marked token block in `server/src/main/resources/templates/report/print-report.html` (for headless Chromium);
   - a human-readable token table for review.
3. Generated files are checked in. `generate.mjs --check` fails when an output is stale.
4. Flutter widgets read tokens only through `Theme.of(context)` / the `context.*` extensions. Feature code may not contain raw colours, font sizes, radii, shadows or spacing.
5. The public report CSS imports `tokens.g.css`; the print/PDF template uses the same custom property names. Flutter and HTML therefore share names and values even though they render in different engines.
6. Hybrid scales:
   - spacing: 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64;
   - radii: 4, 8, 12, 16, 24, 32, pill;
   - Figma outliers map to the nearest token; the mapping is listed.
7. The A2 alternative (emerald fill + ink label vs deep green fill + white label) is modelled as a token strategy, not as duplicated components.

## Consequences

- A contributor changes `tokens.json` and runs the generator; hand edits in generated files are rejected.
- The Dart and CSS names are reviewed together; a parity check is part of the F1 gate.
- The existing `report.css` variable names are kept as aliases during F1 so the report tests do not break, while the new semantic names are added.

## Rejected alternatives

- **Hand-maintain Dart and CSS separately:** guaranteed drift.
- **Generate only CSS:** Flutter would still have a second source.
- **Runtime CSS variables in Flutter:** not supported natively and would add a dependency.
