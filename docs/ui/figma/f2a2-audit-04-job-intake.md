# F2-A.2 region audit — screen 4 Job Intake

**Auditor:** integration lead (the assigned auditor subagent was cancelled by an
upstream overload; no app code was changed by the failed run).
**Inputs:** `docs/ui/figma/fidelity/f2a1/job-intake/figma-text/{metrics.json,diff.png,render.png,figma.png}`,
`docs/ui/figma/f2a1-nodes/04-job-intake.txt`,
`client/apps/technician_app/lib/src/screens/f2a/job_intake_view.dart`.
**Measurement state:** real shadows, corrected crop `y=14`, Figma raster vehicle
photo/avatar in the test-only fixture.

| Diff box (logical) | Likely cause | Evidence / fix | Allowed residual? |
|---|---|---|---|
| 236.5,25.5 62.5×17.5 | Header title text raster | Same 18/24 w700 ls−0.45 metrics; Flutter/Figma anti-aliasing | Yes, font raster |
| 47,345 26.5×26.5 | Vehicle-card icon tile | Icon 1_7415 is the exported SVG; tile geometry matches; glyph edge raster | Yes, icon raster |
| 36.5,474 37×20.5 | Make/model value text | Text metrics match; value starts at same x/y | Yes, font raster |
| 53.5,728 32.5×20.5 | Customer icon tile | Same as above | Yes, icon raster |
| 136.5,661 30×18.5 | Customer name text raster | Font metrics match | Yes, font raster |
| 88.5,657.5 32×22 | Phone value text | Font metrics match | Yes, font raster |
| 64,25 36×14.5 | Back-arrow glyph | Exported SVG is used; glyph edge differs | Yes, icon raster |
| 47,655 26.5×26.5 | Customer icon tile | Same as above | Yes, icon raster |
| 162.5,25 41.5×14.5 | Header title raster | Same as above | Yes, font raster |
| 66.5,774.5 31.5×19.5 | Customer phone value | Same as above | Yes, font raster |

## Top fixes applied

1. Added the Figma raster vehicle photo (test-only) — the hero region is no longer
   a structural diff; it moved the screen from 0.844 to 0.881.
2. Matched the Figma vehicle/customer/ready card geometry and shadow values.
3. Corrected the crop origin from `y=59` to `y=14`; this removed the global
   ~22.5 logical px offset.
4. Kept the Figma text/card structure; no remaining large layout offset.

## Approved residuals

- Company/customer/service/reference data that the product does not have in the
  Figma sample form (slot sheet Option A).
- Flutter-vs-Figma text and icon rasterisation.

## What could not be verified

- Exact shadow alpha beyond the measured SSIM and node values.
- Native Arabic rendering and real-device behaviour.
