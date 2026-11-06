# ADR-F1-006 — Light-only theme (C0 Workstream B)

- **Status:** accepted
- **Date:** 6 November 2026
- **Phase:** C0 Workstream B
- **Deciders:** product owner; integration lead
- **Supersedes:** decision `A6` in `docs/ui/figma/decisions.md` (light-first with a
  derived, tested dark theme) and the dark-theme half of decision `G1` (fidelity
  gate coverage for dark variants), originally recorded in ADR-F1-001 and
  ADR-F1-004.

## Context

F1 shipped a light-first system with a derived dark theme: `AppTheme.dark` /
`AppTheme.darkDeepGreen`, `TrColorDark` / `TrBrandDark` / `TrStatusDark` token
classes, dark golden baselines, dark gallery toggle, dark fidelity variants,
dark contrast sections, and `prefers-color-scheme: dark` / `[data-theme="dark"]`
CSS in the public report outputs. The Figma exports are light-only and the
product decision for C0 is to ship light-only.

## Decision

1. The product ships one theme: light. `color-scheme: light` everywhere.
2. Dark `ThemeData`, dark token classes, the gallery theme toggle, dark golden
   baselines, dark fidelity variants, dark contrast sections, and dark report
   CSS are removed, not deprecated.
3. The token generator (`tools/design_tokens/generate.mjs`) emits light-only
   Dart and CSS and fails `--check` on any stale output. The contrast report
   (`docs/ui/figma/contrast-after.md`) is light-only.
4. `tokens.json` dark source values are ignored by the generator until the lead
   removes them from the source of truth (lead-owned; tracked as a proposal,
   not changed here).

## Consequences

- `AppTheme.build` asserts `Brightness.light`; call sites that pass
  `Brightness.dark` (admin/technician `app.dart`, dark golden tests) must be
  migrated by the lead — proposed, not changed in this workstream.
- Dark golden PNGs, dark fidelity `variants/*dark*.png` files, and dark failure
  artifacts are deleted. `f2a_goldens_dark_test.dart` is proposed for deletion.
- Public report and print template carry `<meta name="color-scheme"
  content="light">` and no dark CSS.
- This ADR does not change the F0 evidence in `tokens.md` or the historical
  F1 decisions in `decisions.md`; it supersedes them for all new work.

## Rejected alternatives

- **Keep a derived dark theme:** contradicts the C0 light-only product decision
  and doubles golden/fidelity/contrast maintenance.
- **Deprecate-but-keep dark code paths:** leaves dead theme branches in the
  theme, gallery, and CSS that fidelity and contrast gates would still have to
  cover.
