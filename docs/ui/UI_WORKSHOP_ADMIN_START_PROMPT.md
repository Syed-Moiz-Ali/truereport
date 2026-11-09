# TrueReport: Workshop Admin first (consolidate, create the missing login, then align screens in place)

Project folder: `E:\syed_moiz_ali\bitlogix\truereport`

You are the **lead engineer and orchestrator**. Use **subagents** (read-only audits, at most 3 at a time). Work in the order below and **stop at each gate**. Do not commit. Do not delete anything before the plan in Step 1 is approved.

**Owner prerequisite (not for the agent):** a git snapshot exists (`git tag before-consolidation`).

**All rules in `docs/ui/UI_INPLACE_ALIGNMENT_PROMPT.md` remain in force** (use the existing centralized components and theme and change them in place; no twin or duplicate screens or components; one component per role and one file per screen; ARB for every string, English and Arabic, no Figma sample text in `lib/`; light mode only; no business-logic, API, model, validation, permission or state-management change; locked product rules; the C0 account model; never invent results). Read that file, `master.md`, `docs/ui/c0-report.md` and `i18n-inventory.md` first.

## 1. Scope and order

**This session starts the Workshop Admin app** (Flutter web and mobile, `client/apps/admin_app`, Workshop Admin role). Platform Admin and the public report come later. The technician screens were already aligned to the Figma: they must **not regress**.

Order, each step a gate:

1. **Step 0** audit (read-only) focused on what Workshop Admin touches.
2. **Step 1** consolidation plan (approval).
3. **Step 2** consolidation (only the layers Workshop Admin and the technician app share).
4. **Step 3 Admin sign-in screen** (new, derived from the technician login, see section 2).
5. **Step 4 Workshop Admin app shell** (sidebar rail, floating header, page container, from the Figma).
6. **Step 5 onward, one screen at a time** (each needs the owner's approval before the next):
   Queue (Figma 2) → Create/Schedule Job drawer (3) → Assign Technician dialog (4) → Dashboard (1) → Staff Management (5) → Create Technician (6) → Template List (7) → Template Builder (8) → Completed Report Viewer (9) → Share-Link Deactivation dialog (10) → Print-Ready PDF Preview (12). Workshop Settings (11) is on hold (no settings endpoint).

Figma source: `docs/ui/figma-export/Workshop_admin_figma/` (12 screens at 1280 px; the folder number prefixes do not match the screen numbers, so confirm each folder against its PNG; if `docs/ui/figma/f3-slot-sheet.md` still exists it contains the mapping and the slot decisions, otherwise rebuild them from the audit).

## 2. The missing login screen (Step 3)

The Workshop Admin Figma export has **no login screen**. Create one by **reusing the technician login that is already aligned to the Figma**, with the same shared components: language switch pill, logo glow and mark, white shadowed field cards (email and password with the Figma icons), the primary button, the helper text slots, spacing and type styles. **Do not create new components for it.** If a needed variation is missing, change the existing shared component and verify the technician login is unchanged.

Layout:

- At 1280 px: the same composition as the technician login, centered in a narrow column (about 420 px wide, vertically balanced) on the white canvas, language pill at the top right of the page. At narrow widths it becomes identical to the technician login.
- It is **one "Admin sign in" screen for both Workshop Admin and Platform Admin**; the server returns the role after sign-in and the existing router sends each role to its own area. Do not add a role picker.
- Text: all ARB keys (English and Arabic): app title, subtitle, field labels/placeholders, button, and one neutral helper line saying that accounts are created and reset by the Platform Admin. No signup, no forgot-password flow, no invitation wording, no certification or "secure" claims, no sample text.
- Behaviour unchanged: the existing sign-in logic, lockout and error mapping (neutral localized errors). TOTP stays off by configuration; if the flag is on, the existing challenge works but has no Figma design: label it "derived, pending designer review".
- Label the screen "derived from the technician login, no Figma frame" in the docs. Do not claim it is identical to a Figma frame.
- Accessibility: visible labels for screen readers (invisible if the Figma shows none), focus order, Enter submits, visible focus ring, 48 dp hit areas, password visibility toggle labelled. RTL: mirror; keep the email left-to-right.

## 3. Step 0 audit (read-only, produce `docs/ui/consolidation-map-admin.md`, then stop)

Subagents cover: components (the shared design system, the Figma-exact kit, app-local widgets, duplicates and call sites), screens (every file that renders each Workshop Admin screen and each shared screen, which one the router uses, dead code, current state against the Figma), tokens, language (literals, Figma text, ARB parity, Arabic length risks), tests (goldens, fidelity harness pieces, what would change). Also list, for each Workshop Admin Figma screen, whether an existing screen already exists, and map every Figma element to existing data and endpoints (check `ApiEndpoints` and the server controllers). Include a **regression guard plan**: how the technician screens (1 to 7, 9, 11, 13 to 16) are protected while shared components change (their existing goldens and tests must stay green).

## 4. What to wire and what never to show (Workshop Admin, existing backend only)

| Screen                  | Wire to                                                                                                                                                                        | Do not show or invent                                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| Shell                   | Workshop Admin routes and guards, workshop name, sign out, language switch                                                                                                     | Role badges, avatars, notifications, search that does not exist          |
| Queue                   | Jobs list, search, status filters                                                                                                                                              | Bay numbers, telemetry, fake customer identifiers                        |
| Create drawer           | Existing create-job fields (customer, vehicle, scope, published template)                                                                                                      | Tiers or protocols that are not real templates                           |
| Assign dialog           | Own workshop's technicians; assign/reassign                                                                                                                                    | Certifications, workload, shifts, "available now"                        |
| Dashboard               | Read-only job counts endpoint (counts by status, finalized today; "Active" = assigned + in progress)                                                                           | Bay utilization, throughput, telemetry, averages                         |
| Staff                   | Own workshop's technicians; disable, reactivate, password reset                                                                                                                | Certifications, shifts, stations, hardware, IDs                          |
| Create Technician       | `POST /workshop/technicians` (name, email, initial password, Idempotency-Key; password never echoed or logged; neutral `EMAIL_EXISTS`); no invitations                         | Roles other than Technician, "pending", invite wording                   |
| Template List / Builder | Real templates, approved published master items, search, reorder (drag only if the save API takes an ordered list), locked-rule pills, EN/AR preview, draft, publish, versions | Autosave, cross-category drag, custom items, controls the server rejects |
| Report Viewer           | Report status, public link controls, PDF per the report setting, delivery history                                                                                              | "Certified", "verified", scores, compliance, stamps, signatures          |
| Deactivation            | Mandatory reason, existing revoke, a line that copies and screenshots cannot be recalled                                                                                       | Anything implying full erasure                                           |
| PDF preview             | Our generated PDF (same allowlist, bilingual) when allowed                                                                                                                     | Print studio, signatures, stamp editing                                  |

Never show GPS, certification, "verified", compliance or score wording, sample people, vehicles, photos or plates, or manager, review or approval wording. Where the design has something we may not show, use a neutral replacement in the same slot, size and style as an ARB value, and list it.

## 5. Per-screen procedure (Steps 3 to 5 onward)

1. Compare the existing screen (or, for the login, the technician login) with the Figma `@2x.png` and node JSON at 1280 px; write a short difference list.
2. Fix at the right layer: tokens, then the shared component, then the screen. No new component if one already plays that role.
3. Text via ARB only; neutral replacements per section 4.
4. Check Arabic (RTL, LTR for IDs/VINs/numbers, longer text), text scale up to 2.0x, keyboard operation (tab order, focus ring, Esc closes drawers and dialogs, focus trap, return focus), hover states, 48 dp hit areas without changing the resting look.
5. Screenshot at 1280 px in English and Arabic next to the Figma image (`side-by-side.png`); report remaining differences with causes. Do not claim "pixel-perfect" unless measured.
6. Responsive: tablet and phone layouts are **derived** from the same tokens (rail collapses, tables become cards, drawer becomes a full-height sheet, dialog becomes a bottom sheet) and labelled "derived, pending designer review".
7. Update only affected tests; no duplicate files; delete what the change made obsolete.
8. Run `flutter analyze --fatal-infos` and the affected suites; at the end of each gate run all client suites, the server suite (with Docker/MySQL if available) and the web build. Technician goldens must stay unchanged.

## 6. Subagents and rules

Audits: `component-auditor`, `screen-auditor`, `token-and-language-auditor`, `test-auditor` (max 3 at a time, read-only). Later: the lead edits shared tokens, shared components and the router; per-screen subagents may propose changes inside their own screen file only. Two agents never edit the same file. Never invent versions, measurements or results; state what you could not verify; do not claim real-device testing; Arabic remains "derived, pending native review".

## 7. Report format (every gate, in chat)

What was done; files changed or deleted; test and build results; screenshots (English and Arabic) and remaining differences; decisions needed. Then **stop and wait for approval.** For this first run: **Step 0 only.**
