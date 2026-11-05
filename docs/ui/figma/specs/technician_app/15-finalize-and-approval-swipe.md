# 15. 14. Finalize & Approval (Swipe)

- App: Technician
- Figma node: `1:8809`
- Frame: 390 x 1231.25 px (phone; mobile portrait, tall scroll)
- Export folder: `screens/15_14._Finalize_&_Approval_(Swipe)`
- Sources read: `14._Finalize_&_Approval_(Swipe).json` (developerSummary, assetIndex, full node tree), `14._Finalize_&_Approval_(Swipe)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/typography; medium for the finalize semantics (the screen mixes review, approval and submission); low for the swipe/gesture and RTL behaviour (only the idle state is exported)

> **Ordering note:** this folder is manifest index **15** but the Figma screen is named **"14. Finalize & Approval (Swipe)"**. The file name above uses the manifest index as the NN prefix. Screens 12–15 are numbered differently in Figma than in the export order.

## 1. Purpose

A final review-and-finalize screen: it summarises the vehicle, counts of checks/defects, the technician, the flagged items, and a legal-sounding confirmation, then asks the technician to **slide a thumb** to "Finalize Inspection".

## 2. Layout structure

Root `1:8809`: 390x1231.25, VERTICAL, fill `#FFFFFF`.

1. `1:8810` "Main" — 390x1231.25, VERTICAL, padding `64/0/0/0`.
   - `1:8811` content — 390x1167.25, VERTICAL, bottom padding 128.
     - `1:8812` intro — 390x126, padding `12/20/8/20`, gap 4.
       - step pill 180.38x22 (`#F4F3F8`, 12.5 icon `#006C49`, `INSPECTION STEP 4 OF 4` 11/14).
       - `Review & Finalize` 26/32 ExtraBold.
       - body 350x40: "Review verified points and sign off to dispatch fleet records." 14/20 Medium.
     - `1:8822` summary margin — 390x574, padding `16/20/0/20`; card 350x558, **radius 32**, two shadows.
       - header 302x68, bottom padding 20: 48x48 tinted car icon; `2024 Ford Transit 350` 16/22 Bold; `VIN • 1FTBR1Y85RKB92104` 13/18; `Bay #04` chip 73.83x22 `#E1DEEC` text `#62616D`.
       - stats 302x152, gap 12: two 145x152 `#F4F3F8` cards, padding 16; 32x32 icon circles (`#6FFBBE`+`#002113` check; `#FFDAD6`+`#93000A` flag); `104` / `2` 22/28 Bold; `Checks Completed` / `Defects Found` 13/18.
       - technician 302x98 `#F4F3F8` padding 16: 34.94x40 avatar (raster, radius pill); `Marcus Vance` 14/18 Bold + 14.67 emerald check; `Lead Fleet Specialist • ID` 13/18; `#8842`; right column `Today` / `14:48` / `PST` (11/14, 12/16, 12/16, right aligned).
       - vehicle photo 302x144 (raster) + `Odometer: 14,820 mi` chip 155.39x22.
     - `1:8879` flagged margin — 390x214, padding `16/20/0/20`; card 350x198, **radius 32**, padding 20, gap 12.
       - `Flagged Items Summary` 16/22 Bold; `Requires Follow-up` 11/14 SemiBold `#B91A24`.
       - two rows 310x56: 24x24 `#FFDAD6` icon circle with `#93000A` alert; title 14/20 SemiBold; body 13/18.
     - `1:8907` disclaimer — 390x125.25, padding `19/28/0/28`; 334x106 centered 13/21.13 `#5E5D69`.
2. `1:8910` Swipe dock — 390x104, padding 20, fill `#FFFFFF@0.95`, `BACKGROUND_BLUR`; 350x64 pill track `#E9E7ED` with 6px inner padding; label `Slide to Finalize Inspection` 14/18 Bold (+0.35) `#5E5D69`; 52x52 emerald thumb with 16.33x14 icon.
3. `1:8920` Header — 390x64, `#FFFFFF@0.8` + blur + shadow; back 44x44, `Diagnostic Checklist` 18/24, 32x32 emerald avatar.

The content scrolls under the fixed swipe dock; the dock is the only safe-area action.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#1A1B1F` | primary text/icons | 13 |
| `#5E5D69` | secondary text | 13 |
| `#FFFFFF` | cards/header | 6 |
| `#F4F3F8` | stat cards, icon circles | 5 |
| `#006C49` | emerald icons/check | 4 |
| `#93000A` | on-error flag icons | 3 |
| `#FFDAD6` | danger icon circles | 3 |
| `#10B981` | swipe thumb, success wording | 2 |
| `#FFFFFF01` | transparent shadow layers | 2 |
| `#002113` | on-primary-fixed check | 1 |
| `#62616D` | Bay chip text | 1 |
| `#6FFBBE` | success icon circle | 1 |
| `#B91A24` | "Requires Follow-up" | 1 |
| `#E1DEEC` | Bay chip surface | 1 |
| `#E9E7ED` | swipe track | 1 |
| `#FFFFFFCC` / `#FFFFFFE5` / `#FFFFFFF2` | header / dock / photo chip | 1 each |

### Typography

- Family **Plus Jakarta Sans**; weights 400/500/600/700/800.
- 26 / 32 / ExtraBold 800 / -0.65 — page title.
- 22 / 28 / Bold 700 / -0.55 — counts.
- 16 / 22 / Bold 700 — vehicle, flagged title.
- 14 / 20 / Medium 500 / -0.07 — intro; 14 / 18 Bold — tech name, swipe label; 14 / 20 SemiBold — flag titles.
- 13 / 18 / Regular — VIN, meta, flag bodies, disclaimer (line-height 21.13).
- 12 / 16 SemiBold — time/zone; 11 / 14 SemiBold (+0.44) — step pill, Bay chip, labels.
- Mixed alignment: left for most, right for time/PST; centered for disclaimer.

### Radii, shadows, strokes, spacing

- Radii: `9999` x15, `32` x2. Cards 32; pills/nav full.
- Shadows: summary card (2), flagged card (1), swipe track thumb, header blur.
- Strokes: none; photo chip uses transparency.
- Spacing: 16 dominant (16), 20 (15), 12, 4, 6, 2, 10, 28, 8, 24, 40, 56.58, 64. 20/32 not in current tokens.

## 4. Components

Figma patterns:
- Step pill with check icon + 26px title + supporting body.
- Large summary card: vehicle header, two KPI tiles, technician identity row with avatar, vehicle photo with odometer chip.
- Flagged-items card with danger medallions and follow-up label.
- Long centered disclaimer block.
- **Slide-to-confirm** track with a 52px thumb and inline label.
- Sticky blurred app bar.

Mapping:
- `SectionHeader` — page title/intro.
- `StatusChip` — step pill, `Bay #04`, `Requires Follow-up`.
- `SeverityBadge` — close for flag rows (ours is text + tone, not medallion rows).
- `AppListTile`/`Card` — flagged rows and technician row.
- `AppButton` — no direct equivalent for a swipe-to-confirm control; `ConfirmDialog` is the current pattern.
- `LinearProgressIndicator` — no equivalent here.
- KPI tiles, odometer chip, vehicle photo block — no equivalent.
- Avatar image — no avatar component (only icons).

## 5. Assets

12 assets: 10 individual SVGs, 2 raster JPEGs, no composed SVG.
- Icons: step/check (12.5), vehicle (19.5x17.3), success check (15), defect flag (11.25x12.75), technician check (14.67), alert (12.83x11.08 ×2), swipe/chevrons (16.33x14), back (11.8x20), avatar (12x12).
- Raster 1: `image-1-7ddff35831.jpg` rendered 34.94x40 — a **technician avatar photo** (personal image).
- Raster 2: `image-2-8fd829937a.jpg` rendered 302x144 — a **vehicle photo** (white van in a workshop).
- The avatar is personal data: no PII should appear in logs/analytics; use a real profile or a neutral placeholder.

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Step | `INSPECTION STEP 4 OF 4` | No | No step model |
| Title | `Review & Finalize` | Close: `l10n.reviewAndFinalize` | — |
| Intro | `Review verified points and sign off to dispatch fleet records.` | No | "sign off"/"dispatch" implies approval/delivery |
| Vehicle | `2024 Ford Transit 350` | Yes: make/model/year | — |
| VIN | `VIN • 1FTBR1Y85RKB92104` | Yes: `vehicleVin` | Full VIN available internally; must never reach the public report or logs |
| Bay | `Bay #04` | No | No bay field |
| Counts | `104 Checks Completed`, `2 Defects Found` | Partly: completed/total and findings exist | "Defects Found" must be derived from result codes, not a separate score |
| Technician | `Marcus Vance`, `Lead Fleet Specialist • ID #8842` | Partly: assigned technician exists; role/ID/photo do not | "Lead Fleet Specialist" is a **role not in the product**; avatar photo is PII |
| Time | `Today 14:48 PST` | Partly: timestamps exist | Timezone must come from workshop, not device |
| Odometer | `Odometer: 14,820 mi` | Yes: `odometerValue`/`odometerUnit` | Unit/locale must be consistent |
| Flagged | `Front Left Tire Tread Depth`, `Measured at 3/32 in. Marginal wear pattern documented.` | No | **Invented measurement/condition wording**; no tyre model |
| Flagged | `Rear Cargo Door Latch`, `Minor resistance observed...` | Partly: finding/note exists | Sample note |
| Disclaimer | `By completing this inspection, technician confirms vehicle condition complies with fleet standards. Digital signature and GPS coordinates will be permanently appended to Fleet Ledger #2024-FLT-0982.` | No | **Compliance claim, invented signature/GPS/ledger, full external reference** |
| Swipe | `Slide to Finalize Inspection` | No | Current flow uses a confirm dialog, not a swipe |

## 7. States shown / not shown

Shown: idle swipe-to-finalize, populated summary, flagged items, long disclaimer.
Not shown: loading, validation/blocking state, submitting spinner, success (separate screen 16), error/409/422, offline-disabled, conflict, double-submit guard, accessibility alternative to swipe, RTL, 200% text.

## 8. Implied interactions

- Back returns to the checklist/review.
- Drag the thumb to the end to finalize (gesture-only).
- On completion, show submitting state, then the post-finalization screen only after a server `FINALIZED` response.
- Flag rows may be tappable (not shown).
- Scroll the summary/disclaimer under the fixed dock.

## 9. Correspondence to current product

- Matches the finalize portion of `client/apps/technician_app/lib/src/pages/review_page.dart` (route `/jobs/:id/review`), which uses `technicianReview` + `confirm dialog` + `technicianFinalize` with a client-generated UUIDv7 idempotency key.
- Server: `TechicianInspectionController`/`InspectionService.finalize` (finalize requires `READY_TO_FINALIZE`, idempotency, pessimistic lock); ADR 0017 `0017-online-inspection-finalization.md`. Finalization currently writes findings/snapshot and returns `FINALIZED`; report/PDF generation is a separate phase.
- **UI-only differences**: layout, counts, KPI tiles, vehicle photo, swipe gesture.
- **New data/server change** needed for: bay, technician role/ID/avatar, tyre tread findings, GPS, "Fleet Ledger" reference, fleet-standards compliance text. None exist in `TechnicianJob`/`Assessment`/`Finding`.
- **Semantics change**: swipe-to-confirm would replace the current explicit `ConfirmDialog`; an accessible non-swipe alternative is mandatory.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Approval" is misleading.** Product has no manager role, review queue or approval step; finalization is self-finalize (locked rule; ADR 0017). The screen title "Finalize & Approval" and "sign off" imply an approval.
2. **Compliance claim.** "technician confirms vehicle condition complies with fleet standards" is a compliance/certification assertion. Rule: no certification/"verified by"/compliance claims. Must be removed or replaced with approved limitation text.
3. **Invented signature/GPS/ledger.** "Digital signature and GPS coordinates will be permanently appended to Fleet Ledger #2024-FLT-0982" invents a signature capture, GPS collection, an external ledger and a reference. GPS collection is not implemented and would be privacy-sensitive; no such server field exists.
4. **Invented measurement.** "Measured at 3/32 in." is a fabricated tread measurement and a mixed unit (inches) that conflicts with screen 13's mm.
5. **Full VIN on screen.** Internally allowed, but the rule is that the public report never shows full VIN/plate/customer name; the same screenshot/copy must not leak it. Do not expose it in shares/logs.
6. **Person data/role.** Technician name + avatar + "Lead Fleet Specialist • ID #8842" are personal data and a role that does not exist. Use the signed-in user's real display name and no invented role.
7. **Swipe-only confirmation.** Gesture-only irreversible action fails WCAG 2.2 AA and the product rule that destructive/irreversible actions need an explicit confirmation with the consequence in plain language. Provide a button/dialog alternative.
8. **"Defects Found" as a score risk.** A standalone defect count can become an unexplained condition score. Counts must be labelled as findings counts, not vehicle condition.
9. **Token drift.** `#10B981`, `#006C49`, `#FFDAD6`, `#93000A`, `#6FFBBE`/`#002113`, 32px radii, 20px spacing are outside `tokens.dart`.

## 11. Open questions / could not verify

- Is the swipe intended to actually finalize, or only to open a confirmation? The screen shows no confirmation copy and no submitting state.
- Where do "104 checks" and "2 defects" come from? Are they computed from the pinned template/findings or hardcoded?
- What is the approved legal/limitation copy? The current text is not approved content.
- Is GPS/signature required for finalization in this product? If yes, it is a data/privacy/scope change.
- Is the technician avatar a real profile image (and therefore PII) or a placeholder?
- Does the screen replace or sit before the current review page? The header still says "Diagnostic Checklist".
- RTL (the "Slide to Finalize" affordance is directional), 200% text, reduced motion, and screen-reader behaviour for the slider could not be verified.
