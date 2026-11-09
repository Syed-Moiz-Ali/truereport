# TrueReport: consolidate the UI layers and align the existing components and screens to the Figma, in place

Project folder: `E:\syed_moiz_ali\bitlogix\truereport`

You are the **lead engineer and orchestrator**. Use **subagents** for the audit (read-only, at most 3 at a time). Work in the order below and **stop at each gate**. Do not commit. Do not delete anything before the plan in Step 1 is approved.

**Owner prerequisite (not for the agent):** take a git snapshot first (`git add -A`, `git commit -m "Snapshot before consolidation"`, `git tag before-consolidation`) because nothing has been committed so far.

---

## 1. What the owner wants (this overrides earlier approaches)

- **Exact Figma UI, UX, components and style.** Do **not** start from scratch and do **not** create parallel "twin" or duplicate screens or components.
- Use the **existing centralized components and theme**. Change them **in place** so they match the Figma exactly (shared card, button, field, chip, navigation dock, header, sheet, dialog and so on). Screens that use them update automatically.
- **One component per role, one file per screen.** Superseded duplicates are removed after their call sites are migrated.
- **Multi-language:** every visible and accessibility string comes from the ARB files (English and Arabic now; `ru` and `zh-Hans` later). **No Figma sample text or literal strings in `lib/`.** The Figma is a visual reference only; Figma wording is used only where it is allowed, as an ARB value. Figma text for comparison exists only in test-only fixtures under `test/`.
- Light mode only. Do not change business logic, API contracts, models, validation, permissions or state management. Locked product rules apply (no certification, "verified", compliance, score or GPS wording; no sample people, vehicles, photos or plates in the product; finalized data immutable; account model from C0: Platform Admin creates Workshop Admins, Workshop Admin creates Technicians, no invitations).

## 2. Step 0: read-only audit (subagents, produce `docs/ui/consolidation-map.md`, then stop)

Read `master.md`, `docs/ui/c0-report.md`, `i18n-inventory.md`, and everything under `client/`. Produce:

**A. Component map.** Every shared widget in `design_system` and in the apps: its role (card, button, field, chip, dock, header, sheet, dialog, list row, ring, selector...), where it is defined, how many call sites use it, and which screens. Mark **duplicates** (for example the first-generation design-system components versus the `Fx*` Figma-exact kit, or app-local copies) and recommend which one survives.

**B. Screen map.** For each Technician screen (1 to 16, excluding 8, 10, 12) and each Workshop Admin, Platform Admin screen that exists: every file that renders it (page, `screens/f2a`, `f2b`, `f3` views, older versions), which one the production router actually uses, which are test or fixture only, and which are **dead code**.

**C. Token map.** Where colours, text styles, radii, spacing and shadows are defined; duplicates or conflicting values; hardcoded values inside widgets.

**D. Language map.** Any literal user-visible or accessibility string in `lib/`, any Figma sample text in `lib/`, ARB parity status, and screens that would break with longer Arabic text.

**E. Test map.** Tests, goldens and fidelity harness pieces tied to old layers, and what would need to change when a layer is removed.

Give counts, a short list of the risks, and your recommendation. **Do not delete or edit anything.** Stop and wait for approval.

## 3. Step 1: consolidation plan (after the owner approves the map)

Write `docs/ui/consolidation-plan.md`: the target structure (one token source, one component per role, one file per screen, fixtures only in `test/`), the exact migration order (tokens, then components, then screens), what is deleted at each step, which tests change and how, and the checks after each step. **Stop for approval** before changing code.

## 4. Step 2: consolidate (after the plan is approved)

Small steps, each of which compiles and passes the affected tests before the next: unify tokens; unify each component role (migrate call sites, delete the superseded component); unify each screen to a single file; move fixtures to `test/`. No behaviour changes. Run `flutter analyze --fatal-infos` and the suites after each step; at the end run all client suites in full, the server suite, and builds. Stop and report.

## 5. Step 3: align to the Figma in place, one screen at a time (technician login first)

For each screen, in this order: **Technician 1 Login, 2 Jobs, 3 Empty state, 4 Job details, 5 Consent (no signature pad), 6 Equipment, 7 Inspection hub, 9 Defect detail, 11 Dense list, 13 Final review, 14 Finalize, 15 Offline sync, 16 Success**; then Workshop Admin; then Platform Admin. Do **one screen, then stop for the owner's approval** until the owner says to batch.

Procedure per screen:

1. Compare the **existing screen** with the Figma `@2x.png` and node JSON (Figma exports are in `docs/ui/figma-export/`). Write a short difference list: layout, spacing, sizes, colours, shadows, radii, fonts (Plus Jakarta Sans size, weight, line height, letter spacing), icons, states.
2. Fix at the **right layer**: shared tokens first, then the shared component, then the screen's own layout. Do not patch a single screen for something a shared component should own. Do not create a new component if one already plays that role; change it.
3. **Text:** reuse or add ARB keys (English and Arabic). If the design has text we may not show (certification, "verified", compliance, score, GPS, hardware, bay, fleet, sample people), use the neutral replacement in the same slot, size and style, as an ARB value, and list it. Never write a literal string.
4. **Languages:** check Arabic (RTL mirroring; VIN, plate and numbers left-to-right; longer Arabic text; no clipping) and text scale up to 2.0x, plus 48 dp tap targets via invisible hit areas.
5. Screenshot the screen at 390 px (technician) or 1280 px (admin) in English and Arabic, and put it next to the Figma image (`side-by-side.png`) for the owner. Report remaining differences honestly with causes. Do not claim "pixel-perfect" unless measured.
6. Update only the tests affected. No new parallel files. Delete anything the change made obsolete.
7. Run `flutter analyze --fatal-infos` and the affected suites; at the end of each batch run all suites and builds.

## 6. Multi-language: how it must work

- All text, including semantic labels, hints, tooltips, dialogs, errors and status names, are ARB keys with matching English and Arabic values and matching placeholders.
- Layout never depends on English text length: use flexible layouts and test with the Arabic values.
- Server errors arrive as codes and are mapped to ARB keys.
- Dates, numbers and units use `intl` with the active locale.
- Figma text is only a visual guide and is never copied into code as a literal.

## 7. Subagents

Audit: `component-auditor`, `screen-auditor` (one for technician, one for admin screens), `token-and-language-auditor`, `test-auditor` (max 3 at a time, read-only). Later steps: the lead edits shared tokens and components and the router; per-screen subagents may propose changes only inside their own screen file. Two agents never edit the same file. Each subagent returns a short structured report. If a run fails or is overloaded, retry in a smaller batch and state what the lead did instead.

## 8. Rules

Never invent versions, measurements or results. State what you could not verify. Do not claim real-device testing you did not do. Arabic remains "derived, pending native review".

## 9. Final report (in chat) for each gate

What was done; files changed or deleted; test and build results; screenshots (English and Arabic) and remaining differences for the screen; decisions needed. Then **stop and wait for approval.**
