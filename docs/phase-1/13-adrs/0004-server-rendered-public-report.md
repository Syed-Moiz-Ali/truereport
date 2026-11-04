# ADR-0004: Server-rendered HTML public report

- **Status:** **Accepted** — approved by product owner 3 November 2026
- **Date:** 3 November 2026
- **Owner:** Frontend/backend lead
- **Evidence:** `docs/phase-1/12-spike-results.md` §3

## Context

The public report is opened from WhatsApp/SMS/email by a non-technical customer, often on a poor connection. It must be readable, accessible, selectable, printable, not indexed, and must not expose private data in link previews.

`master.md` originally assumed Flutter Web but marked D4 open. Phase 0 found Flutter Web is canvas-based with opt-in semantics and weaker static-document behavior.

## Options

1. Flutter Web public report.
2. Server-rendered HTML from the Java server, minimal/no JavaScript.
3. Hybrid shell + Flutter island.

## Decision

Use **server-rendered HTML** for `/r/{token}` in V1, rendered from the immutable report snapshot through an explicit public allowlist DTO. Keep Flutter for the technician and admin apps. Use a server-side template with auto-escaping; no admin JavaScript; no external font/script dependency.

## Evidence

Spike B measured:

- SSR: 623 KB transfer (mostly 20 photos), 4.6 KB HTML, 131 table rows in DOM, 13,536 chars of text, no axe violations, no JS required.
- Flutter: 2.84 MB transfer / 7.9 MB decoded, 0 innerText, 0 table rows, 16 semantics nodes in the forced-semantics build, axe critical `meta-viewport`, fonts from `fonts.gstatic.com`.
- Flutter did not produce a document: no text selection/find, no headings/table semantics, default app metadata.

The spike did not test real WhatsApp in-app browsers, real devices or screen readers; those are Phase 6 follow-ups.

## Consequences

- Smaller, faster, more accessible public page.
- A second rendering surface (HTML) must be kept consistent with the PDF and snapshot.
- The public template must be protected against XSS and must not drift from the allowlist.
- Design consistency with Flutter is maintained through shared tokens, not shared widgets.

## Follow-ups

- Approve D4.
- Phase 6: real-device, WhatsApp, screen-reader, print, invalid/revoked and cache tests.
- Choose the server template engine and escaping strategy.
- Confirm no external fonts/scripts on the public page.
- Build a shared snapshot DTO used by HTML and PDF.

## What was not proven

Real in-app browser behavior, real screen readers, print quality, invalid/revoked states, the actual Java server, or a 20-page report equivalent.


---

## Phase 6 implementation note (4 November 2026)

Implemented with Thymeleaf 3.1.5.RELEASE (Apache-2.0) and local CSS/fonts. Public HTML is rendered at `/r/{token}` from the immutable `ReportSnapshot`; no JavaScript, no external requests. See `docs/phase-6/00-decisions.md`.
