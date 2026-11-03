# ADR-0003: Riverpod for state management

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Technical lead

## Context

The technician app needs offline state, per-screen async data, dependency injection and testability. `master.md` recommends Riverpod but does not make it binding.

## Options

1. Riverpod (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`).
2. Bloc.
3. Provider/setState (rejected for this complexity).

## Decision

Use **Riverpod** exclusively. Do not mix Riverpod and Bloc. Use `freezed` for immutable models and sealed unions, and `json_serializable` for JSON.

## Consequences

- Compile-time-safe DI and easier provider overrides in tests.
- Code generation adds a build step.
- The team must follow one pattern; mixing libraries is forbidden.
- Major-version mismatches between Riverpod packages must be resolved together.

## Follow-ups

- Confirm D3.
- Pin compatible versions in Phase 2.
- Add a lint/test rule against Bloc imports.

## What was not proven

No Flutter app or state layer was built. Performance and codegen impact are not measured.

