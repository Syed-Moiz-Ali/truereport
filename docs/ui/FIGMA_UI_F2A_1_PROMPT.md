# TrueReport: Figma UI, Phase F2-A.1 (identical-first correction of Technician screens 1 to 7)

Project folder: `E:\syed_moiz_ali\bitlogix\truereport`

You are the **lead engineer and orchestrator**. You **must use subagents** (section 7); if the environment cannot run them, say exactly why before working sequentially. This session covers **F2-A.1 only**. Do not start F2-B. Do not commit. Stop at the gate and wait for approval.

---

## 1. What went wrong, and the new rule

The owner reviewed the F2-A login screen (`login_en_1_0x.png`) next to the Figma and rejected it: it is **not identical**. Visible differences include: green-tinted language pill with a tick (Figma: white selected pill, no tick); small "TR" badge and smaller title (Figma: soft green glow with the logo mark and a larger heavy title); lavender fields with a label above and clipped bottom corners (Figma: white shadowed field cards with the icon and placeholder inside); a darker button with the arrow on the left and no glow (Figma: `#10B981`, "Sign In" with the arrow on the right, emerald glow); removed "Forgot password?", "Need technician access? Request ID" and the footer line; different vertical spacing. Measured SSIM was 0.77 to 0.89 against a 0.98 gate. Some of this came from defaults in the F2-A prompt (P1, P2, P7 and the removals) that conflicted with the owner's standing requirement.

**The owner's requirement is 100% identical UI, UX, style and layout to the Figma: same components, colours, shadows, fonts, sizes, positions and behaviour.** This supersedes decisions P1, P2, P7 and every "deviation by default" from F1.1 and F2-A.

**New rule:** everything visual is identical to the Figma. The only allowed changes are text or data that would be false or unsafe under locked product rules (certification/compliance claims, scores, GPS, features or data that do not exist, sample people/vehicles/photos), and each such change **keeps the same slot, size, style, colour and position** unless the owner approves otherwise. Nothing is silently removed, restyled or "improved".

## 2. Read first

`master.md`; `docs/phase-*`; all of `docs/ui/figma/` (specs, tokens, gap report, deviations, F1/F1.1/F2-A reports, fidelity artifacts); the Figma exports in `docs/ui/figma-export/technision_figma/` (JSON, `@2x.png`, assets); `client/packages/design_system` and `client/apps/technician_app`; the owner's screenshot `login_en_1_0x.png` if present in `docs/ui/`.

## 3. Decisions that replace P1/P2/P7 (record in `decisions.md` and `deviations.md`)

| ID  | New decision                                                                                                                                                                                                                                                                                                                                                                                  |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| I1  | **Primary button = Figma exact:** fill `#10B981`, white label, Figma size/weight, the Figma emerald glow shadow, pill radius, label and arrow positions as drawn. The accessible alternatives (ink label, `#059669`, `#006C49`) stay available behind **one** token switch that is **off**; record contrast numbers (measured) and list the accessibility trade-off as an owner-accepted risk |
| I2  | **Fields = Figma exact:** white cards, soft shadow, icon and placeholder inside, 48 px height, Figma radius and padding, no label above, no filled lavender. Accessibility is added **invisibly**: semantic labels for screen readers, input-purpose hints, and hit areas enlarged with transparent padding. No visible change                                                                |
| I3  | **Targets:** keep the Figma's visual sizes. Where the Figma control is smaller than 48 dp, enlarge only the **invisible hit area**                                                                                                                                                                                                                                                            |
| I4  | **Bottom dock = Figma 4 slots** (Intake / Fleet / Sync / Profile) with the Figma icons, positions and shadow. We have no fleet feature, so propose, in the slot sheet (section 4), what the "Fleet" slot maps to using **existing** data (candidate: a "Completed" jobs list from existing finalized jobs). Do not invent a feature. Owner approves the mapping                               |
| I5  | Fonts: **Plus Jakarta Sans** at the exact Figma sizes, weights, line heights and letter spacing for Latin; Arabic fallback as approved (Noto Sans Arabic)                                                                                                                                                                                                                                     |
| I6  | Brand text "TechInspect" becomes "TrueReport" in the same slot and style. The logo mark slot keeps the Figma glow and mark layout; use our own mark (no Figma mark if it is another brand's; ask the owner)                                                                                                                                                                                   |
| I7  | Shadows, radii, spacing, colours and component structure = Figma values exactly (the F1.1 shadow tests stay and are extended to every shadow used on these screens)                                                                                                                                                                                                                           |

## 4. Slot sheet (owner decides; do not decide for the owner)

For **every** Figma element on screens 1 to 7 that cannot be shown as drawn (content that is false/unsafe, data we do not have, features we do not have), write a row in `docs/ui/figma/f2a1-slot-sheet.md`:

| Screen | Element and Figma text | Problem (cite the rule or data gap) | Option A: same-slot neutral replacement (exact style and position) | Option B: real data of the same shape | Option C: hide (and what the layout does) | Your recommendation |

Examples to cover (find the rest yourself from the specs): "ISO 27001 Certified Fleet Security"; "Forgot password?"; "Need technician access? Request ID"; avatar and vehicle photos; bay and shift labels; live-sync indicator; scan-VIN; Fleet dock slot; pass-rate and summary text; signature pad content; third consent item; hardware pairing. Where an element is purely informational and harmless, keep it. Where the owner does not decide, the default is **Option A** (same slot, neutral text, same style); never Option C unless the element is unsafe and has no neutral form.

## 5. Work

1. **Fidelity audit (per screen, subagents, read-only first):** compare the current render with the Figma at the node level. For every Figma node with a bounding box, text style, fill, shadow and radius, record the Flutter value and the difference. Output `f2a1-audit.md` per screen.
2. **Geometry tests (new, mandatory):** a test per screen that renders at 390 x 858 and asserts, for every key node (containers, fields, buttons, icons, text), that its position and size are within **1 logical px** of the Figma `absoluteBoundingBox` (use widget keys and `tester.getRect`), and that each text node's size, weight, line height, letter spacing and font family equal the Figma style. Text that is replaced under the slot sheet is tested for the replacement's box, not the original string.
3. **Rebuild to identical:** rebuild shared components first (lead only), then screens (one builder subagent per screen, only inside its own folder). Reproduce the Figma structure: gaps, padding, radii, shadows, glow, icons (use the exported SVGs), pill language switch, blurred logo glow, field cards, button, dock, cards.
4. **Visual verification:** per screen at 390 logical width, DPR 2, bundled fonts, with **two fixtures**: (a) Figma text, (b) real product copy with slot-sheet replacements. Produce `figma.png`, `render.png`, `side-by-side.png`, `diff.png`, `metrics.json`, `REPORT.md`. **Gate: SSIM at least 0.98 and no unexplained difference larger than 4 px on fixture (a); fixture (b) must differ only where the slot sheet says so.** If a screen misses the gate, show the diff and the cause; do not lower the gate and do not claim "pixel-perfect" unless measured.
5. **Arabic/RTL:** derive from the same tokens; mirror directional elements; VIN/plate/numerals stay LTR; label as derived and pending native review.
6. **Keep behaviour intact:** UI only. No change to business logic, API contracts, models, validation, permissions, state management or the server. Consent switches stay unticked and create no record until saved.
7. **Tests:** `flutter analyze --fatal-infos` clean; geometry tests; goldens in English and Arabic; no overflow at 360/390/600/900 and 1.0x/1.5x/2.0x text; focus visibility; reduce-motion; forbidden-term lint (no certification, "verified", score, compliance or GPS wording); source-scan tests (no hardcoded colours/sizes/radii/shadows/endpoints); all existing technician, design_system, admin and server tests; web and debug APK builds. Update the contrast report and list every failing pair (expected: white on `#10B981`; list it as the owner-accepted I1 risk).
8. Screen 6 (equipment) stays blocked by the data gap (names unavailable); show the Figma layout using what the API returns and report what is missing, with the small API change described for the owner.

## 6. Deliverables

`f2a1-audit.md` per screen, `f2a1-slot-sheet.md`, updated `deviations.md` (only owner-approved or rule-mandated deviations may remain), updated `decisions.md`, per-screen fidelity folders, the geometry tests, `f2a1-report.md`, and screenshots in English and Arabic.

## 7. Subagents (mandatory for this phase and all later phases)

- **Roles:** `fidelity-auditor` (one per screen, read-only, node-by-node), `screen-builder` (one per screen, edits only its own folder), `geometry-test-engineer`, `a11y-i18n-reviewer`, `privacy-reviewer`, and you as `integration-lead`.
- Only the lead edits shared tokens, shared components, routing and shared providers. Two agents never edit the same file.
- Run auditors in parallel first; then builders in parallel on independent screens after the lead finishes the shared components; then integrate, test and build yourself.
- Each subagent returns a short structured report: what it did, files touched, assumptions, open questions, what it could not verify. Keep large JSON and logs out of your own context.
- If a subagent hits a conflict with a locked rule or a data gap, it stops that item and reports; it does not improvise. If any subagent run fails or is cancelled, rerun it or state plainly that the lead did that work instead.
- Never invent versions, licences, measurements or results. Do not claim real-device testing you did not do.

## 8. Final report (in chat)

What was fixed; per-screen fidelity numbers for both fixtures and the geometry-test results (how many nodes within 1 px, which not); the slot sheet summary and the decisions the owner must make; contrast results and the I1 trade-off; test and build results; what could not be verified; what the owner should check on a real phone (compare each screen against the Figma image; English and Arabic; large text; sunlight; one-hand reach). Then **stop and wait for approval.**
