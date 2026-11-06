# F2-A.2 region audit — screen 6 Equipment

**Auditor:** integration lead (the assigned auditor subagent was cancelled by an
upstream overload; no app code was changed by the failed run).
**Inputs:** `docs/ui/figma/fidelity/f2a1/equipment/figma-text/{metrics.json,diff.png,render.png,figma.png}`,
`docs/ui/figma/f2a1-nodes/06-equipment.txt`,
`client/apps/technician_app/lib/src/screens/f2a/equipment_view.dart`.
**Measurement state:** real shadows, corrected crop `y=14`, J5 server labels now
available in the product build.

| Diff box (logical) | Likely cause | Evidence / fix | Allowed residual? |
|---|---|---|---|
| 144.5,25 71.5×14.5 | Header title text raster | Same 18/24 w700 ls−0.45 metrics | Yes, font raster |
| 314.5,267 39×32 | Status circle / check glyph | Figma shows a verified check on card 1; product has no verification state (J5 adds status only, not verification) | Yes, data gap |
| 153,722 58×11 | Standards body text | Same 13/18 w400 metrics; text raster | Yes, font raster |
| 137,185 43×14.5 | “1 of 4 Verified” pill text | Product shows item count (no verification); fixture uses the Figma string | Yes, slot replacement |
| 105,25.5 38×14 | Back-arrow glyph | Exported SVG; edge raster | Yes, icon raster |
| 117.5,362 23×21 | Not-found status circle | Figma card 2 shows an empty circle; product shows an empty circle; edge/antialias | Yes, raster |
| 53,719.5 14×25.5 | Standards shield icon | Exported SVG at the right slot; glyph edge | Yes, icon raster |
| 104.5,361.5 13×38 | OBD Scanner icon | Exported SVG; glyph edge | Yes, icon raster |
| 81.5,29 24×14 | Header back/heading spacing | Text/icon raster only | Yes, raster |
| 218.5,185 35×11.5 | Status pill text | Font raster | Yes, font raster |

## Top fixes applied

1. J5: the server now returns `items` with `labelEn`, `labelAr`, `code`, `status`
   and `sortOrder`; the Flutter model and screen show the real name/code/status.
2. Corrected crop origin and real shadows (screen 0.834→0.934).
3. Kept the Figma card geometry, icons, order and standards card.

## Approved residuals

- The product has no verification/pairing/calibration state, so the “verified”
  checks and the “1 of 4 Verified” wording remain neutral. Status circles stay
  unticked.
- Product data/copy differ from the Figma sample names in fixture (b).

## What could not be verified

- Unknown-ID skipping is not directly integration-tested because master-data
  validation rejects unknown equipment IDs.
- Exact shadow alpha and real-device rendering.
