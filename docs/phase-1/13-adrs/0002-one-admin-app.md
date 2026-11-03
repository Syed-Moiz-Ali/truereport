# ADR-0002: One admin app for both admin roles

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Technical lead

## Context

Workshop Admin and Platform Admin need overlapping screens (jobs, reports, audit) but different scopes. Two Flutter apps would duplicate navigation, design system, auth and release work.

## Options

1. One Flutter `admin_app` with role-selected feature folders, plus web build.
2. Two separate Flutter apps.
3. Web-only Platform Admin; separate Workshop Admin app.

## Decision

Use **one `admin_app`** Flutter project for Workshop Admin and Platform Admin, with role-based feature folders and server-enforced permissions. Platform Admin is web-first; the same app exposes only the appropriate screens on mobile.

## Consequences

- Smaller codebase and one release pipeline.
- Feature-folder discipline is required so Platform Admin code is not shipped to Workshop Admin routes.
- Route guards are convenience only; the server is authoritative.
- A compromised role must not gain access by manipulating the client.

## Follow-ups

- Confirm D2.
- Define feature-folder boundaries and ArchUnit/Flutter lint rules.
- Test that a Workshop Admin cannot reach Platform Admin endpoints even with a crafted request.

## What was not proven

No app was built. The build-size and release-pipeline impact is not measured.

