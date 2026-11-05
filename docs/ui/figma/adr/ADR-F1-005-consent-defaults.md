# ADR-F1-005 — Consent defaults (privacy fix)

- **Status:** accepted
- **Date:** 5 November 2026
- **Phase:** F1
- **Deciders:** product owner; privacy reviewer

## Context

The current technician consent sheet initialises `granted = true` and the Figma design shows pre-ticked consent switches. The approved consent rule is that consent is explicit, separate and never pre-selected. A consent record must only exist after an explicit action by the person giving it.

## Decision

1. All consent switches start **unticked**.
2. No consent record is created until the user explicitly selects a state and submits the action.
3. The existing separate consents (`PROCESSING`, `PUBLIC_LINK`) remain separate; no new consent type is invented.
4. The fix is a small behavioural change, allowed in F1, with tests proving the initial state and the no-record-until-action behaviour.
5. The Figma pre-ticked/“Recorded” signature visuals are not adopted in any phase unless a separate signature policy is approved.

## Consequences

- One behavioural change in F1, limited to the consent default.
- Existing tests are updated and new tests assert the default is `false`/unselected.
- The public-link consent remains required before a public link is activated.

## Rejected alternatives

- **Keep `granted = true`:** violates consent rules and is a live privacy defect.
- **Pre-select only in the design:** the design must not normalise a non-compliant state.
