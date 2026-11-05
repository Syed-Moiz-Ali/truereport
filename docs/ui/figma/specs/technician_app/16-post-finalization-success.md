# 16. 16. Post-Finalization Success

- App: Technician
- Figma node: `1:8931`
- Frame: 390 x 884 px (phone; mobile portrait)
- Export folder: `screens/16_16._Post-Finalization_Success`
- Sources read: `16._Post-Finalization_Success.json` (developerSummary, assetIndex, full node tree), `16._Post-Finalization_Success@2x.png`, `assets/manifest.json`
- Confidence: high for layout/typography; medium for the delivery meaning (report vs delivery states are conflated); low for RTL and for failure/pending variants (none exported)

## 1. Purpose

The confirmation screen after finalization. It states that the inspection is finalized and the report is locked/uploaded, shows per-channel delivery status (WhatsApp sent, "Fleet Portal" synced), a small metadata strip (VIN ending, items verified, PDF size), and a "Back to Job List" CTA.

## 2. Layout structure

Root `1:8931`: 390x884, VERTICAL, fill `#FFFFFF`, padding `0/0/64/0`, FIXED/HUG.

1. `1:8932` container — 390x820, VERTICAL, padding `16/20/32/20`.
   - `1:8933` context row — 350x22, HORIZONTAL, gap `55.8`: 8x8 emerald dot + `SERVICE SESSION #1042` 11/14 SemiBold (+1.1) `#5E5D69`; right chip 120.56x22 `#F4F3F8` `Locked & Signed` 11/14.
   - `1:8940` center content margin — 350x678, padding `70/0/70/0`; core 350x539.
     - `1:8942` typography — 302.2x92, bottom padding 32; heading `Inspection Finalized` 26/32 ExtraBold `#1B1B25` centered; body 302.2x20 `Report #1042 has been locked and uploaded.` 14/20 Medium `#5E5D69` centered.
     - `1:8948` delivery card — 350x145, **radius 32**, padding 20, gap 16, two shadows.
       - row 310x36: 36x36 `#F4F3F8` icon circle, `WhatsApp` 16/22 Bold, right chip 67.98x28 `#F4F3F8` + 8px emerald dot + `Sent` 12/16 SemiBold.
       - divider 310x1 `#EEEDF3`.
       - row 310x36: icon circle, `Fleet Portal` 16/22 Bold, chip 85.73x28 `Synced`.
     - `1:8972` metadata strip — 350x78, top padding 16; strip 350x62, **radius 48**, padding `12/16/12/16`, fill `#F4F3F8`, H gap `21.2`, three cells separated by 1x24 dividers:
       - `VIN ENDING` 11/14 SemiBold + `·8492` 16/22 Bold.
       - `ITEMS VERIFIED` + `38 / 38`.
       - `PDF SIZE` + `2.4 MB`.
     - `1:8991` badge — 144x176, bottom padding 32; 144x144 white circle with two shadows; inner 112x112 `#F4F3F8` circle; 54.25x54.25 emerald check; 16x16 emerald ripple dots.
   - `1:8999` bottom CTA — 350x72, top padding 16; 350x56 pill `#10B981` `Back to Job List` 14/18 Bold + 13.33 arrow.
2. No app bar/header on this screen.

The layout is vertically centered and non-scrolling by design; HUG height 884 matches the phone frame. No tablet variant.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#1B1B25` | primary headline/values | 8 |
| `#5E5D69` | secondary text/icons | 8 |
| `#10B981` | success check, dots, CTA | 7 |
| `#F4F3F8` | icon circles, metadata strip, chips | 7 |
| `#FFFFFF` | page/CTA text/badge | 5 |
| `#E9E7ED` | dividers | 2 |
| `#EEEDF3` | delivery divider | 1 |

### Typography

- Family **Plus Jakarta Sans**; weights 500/600/700/800.
- 26 / 32 / ExtraBold 800 / -0.65 — `Inspection Finalized`.
- 16 / 22 / Bold 700 / -0.16 — delivery channels, metadata values.
- 14 / 20 / Medium 500 / -0.07 — subheading; 14 / 18 Bold — CTA.
- 12 / 16 SemiBold (+0.24) — sent/synced.
- 11 / 14 SemiBold (+0.44, +1.1 for the session label) — labels.
- Centered heading/subheading; left for channel rows and metadata cells.

### Radii, shadows, strokes, spacing

- Radii: `9999` x13, `32` x1, `48` x1. Badge is a circle; delivery card 32; metadata strip 48.
- Shadows: delivery card (2), badge circle (2), CTA shadow.
- Strokes: none; dividers are 1px rectangles.
- Spacing: 12, 16, 20, 8, 6, 2, 32, 4, 69.5, 0, 21.2, 64. 20/32/64 partially outside current token set (64 absent; 20 absent).

## 4. Components

Figma patterns:
- Minimal success header: context dot + session label + status chip.
- Large centered 144px success medallion (double circle + check + ripple).
- Delivery-status card with channel rows, dot + status chips, divider.
- Pill-shaped metadata strip with three cells and vertical dividers.
- Full-width pill CTA.
- No app bar.

Mapping:
- `SectionHeader` — heading (ours is left-aligned).
- `StatusChip` — `Locked & Signed`, `Sent`, `Synced`.
- `StatusTone.success` — closes the delivery/status colours.
- `Card`/`AppCard` — delivery card.
- `AppButton` primary — Back to Job List.
- Success medallion — no equivalent (`EmptyState` is text-first; no success illustration component).
- Metadata strip — no equivalent.
- Delivery channel rows — the current `finalized_page.dart` uses cards with `Wrap` chips and text, not this layout.

## 5. Assets

4 assets, all individual SVGs; no composed SVG, no raster.
- Icons: WhatsApp/message (16.67), Fleet Portal/cloud-check (18.33x13.33), large success check (54.25), CTA arrow (13.33).
- **No photo/avatar/vehicle image.** (The large badge is vector.)

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Session | `SERVICE SESSION #1042` | No | No "service session" entity; job reference exists |
| Lock state | `Locked & Signed` | Partly: `FINALIZED` + snapshot hash exist | "Signed" implies a signature that is not captured |
| Heading | `Inspection Finalized` | Yes: `FINALIZED` | Must appear only after server confirmation |
| Body | `Report #1042 has been locked and uploaded.` | Partly: report exists/generation status | "locked and uploaded" conflates finalization, report generation and delivery |
| Channel 1 | `WhatsApp`, `Sent` | Yes: delivery `channel`/`status` | "Sent" is a delivery state; should distinguish sent/delivered/failed |
| Channel 2 | `Fleet Portal`, `Synced` | No | No such channel/integration |
| VIN | `VIN ENDING`, `·8492` | Partly: `vehicleVin` (full) | Ending-only is the right privacy posture; must be derived from the real VIN |
| Items | `ITEMS VERIFIED`, `38 / 38` | Partly: completed/total | "Verified" wording may overstate; use "items received/complete" |
| PDF | `PDF SIZE`, `2.4 MB` | No | No PDF size in `TechnicianReportStatus`; PDF generation is separate |
| CTA | `Back to Job List` | Yes: `/jobs` | — |

## 7. States shown / not shown

Shown: finalized, delivered-to-WhatsApp, synced-to-portal, PDF ready.
Not shown: finalization pending, report generating, PDF failed, delivery failed/pending, no-report, offline (finalize cannot be offline), read-only error, RTL, 200% text, long channel names.

## 8. Implied interactions

- "Back to Job List" returns to `/jobs` and refreshes the list.
- Channel rows may be tappable for delivery detail (not shown).
- No copy/share/revoke/resend actions (correct for Technician).

## 9. Correspondence to current product

- Matches `client/apps/technician_app/lib/src/pages/finalized_page.dart`, route `/jobs/:id/finalized`, with `technicianReport` + `technicianJobDeliveries` endpoints (`api_endpoints.dart`). Current UI shows: job reference, `finalizedReadOnly` chip, report `generationStatus`, delivery cards (channel, status, masked recipient, attempts, pdfAttached), vehicle/customer line and read-only items.
- The server has `Report`, `ReportVersion`, `ReportArtifact`, `Delivery` (workshop + technician controllers) and `ReportStatusDto`; `TechnicianReportStatus` exposes `reportNumber`, `version`, `generationStatus`, `ready`, `finalizedAt`.
- **New UI/data**: session number, `Locked & Signed` wording, success medallion, per-channel rows with dots, VIN ending, items verified, PDF size.
- **Needs new data**: PDF size is not exposed; "Fleet Portal" is not a known channel; a VIN-ending field would need derivation (or use the existing full VIN client-side and mask it).
- **Delivery is separate from report success** — the current code already models both; this screen must not show "Sent/Synced" unless the server reports those delivery states.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **"Uploaded" overstated.** Finalization completion is not the same as report/PDF/delivery success. The rule: never show success before server confirmation, and delivery success is separate from report success (`docs/phase-1/02-screen-inventory.md` §6.4). Evidence: "Report #1042 has been locked and uploaded."
2. **"Locked & Signed".** No signature is captured in the finalize flow; "Signed" invents a signature/consent event.
3. **"Fleet Portal / Synced".** There is no Fleet Portal channel/integration. This invents a system and a successful sync.
4. **"ITEMS VERIFIED 38 / 38".** "Verified" overstates; item completion should be "received/complete". Also 38/38 is a sample count.
5. **PDF size.** `2.4 MB` is invented; no PDF size field exists. The public report is server-rendered HTML (D4) with bilingual PDF (D5); PDF availability must come from report status, not a hardcoded size.
6. **VIN exposure.** Showing only the last four is the safer pattern. However, the current model only has the full VIN; the UI must not derive/show more than allowed, and never put VIN in logs/URLs.
7. **Public-report privacy.** No customer name/phone/email/full VIN/plate may appear on the public report. This internal success screen must not become a shareable "report preview".
8. **Token drift.** `#10B981`, `#1B1B25`, 48px metadata radius, 20/32/64 spacing are outside `tokens.dart` (current ink `#17212B`, primary `#0B3B4A`).

## 11. Open questions / could not verify

- Should this screen show delivery at all, or only finalization + "report generating"? The current report generation is asynchronous.
- Is "Fleet Portal" a future channel, or design filler? If future, it must not appear until implemented.
- Where does `PDF SIZE` come from? Is PDF even generated at finalization in the current phase?
- Is `SERVICE SESSION #1042` the job reference, report number, or a new identifier?
- Should "Locked & Signed" require an actual signature/consent record?
- What are the failed/pending/report-generating variants of this screen?
- RTL, Arabic, 200% text, and screen-reader announcement of success ("Inspection finalized. Report is being generated.") could not be verified.
