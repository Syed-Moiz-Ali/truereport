# F1.1 deviations from the Figma

**Project:** TrueReport
**Date:** 5 November 2026
**Rule:** a deviation is allowed only for (1) content/privacy, (2) a measured
text-contrast failure, or (3) language coverage/RTL. Everything else must equal
the Figma value. This file lists every deviation; `owner-approved: no` items are
open and must not be presented as accepted.

**Exact matches are not listed here.** The token revert (surface, shadows,
radii, spacing, type metrics), the button border/dividers removal and the
component structure rebuilds are exact Figma values; they are recorded in
`f1-fidelity-audit.md`.

---

## Approved deviations

| ID | Area | Figma value | Our value | Reason (allowed category) | Measured effect on fidelity | Owner-approved |
|---|---|---|---|---|---|---|
| D-01 | Product type scale | 11/14 w600 captions; 13/18 w400 body (371 + 289 uses) | 12/16 w600 labels; 12/18 w400 body; 14/20 body | Accessibility/language: F1 decision **B1** sets a 12 px product minimum | None on the exact samples: `FigmaType` uses the Figma 11/13 metrics for the exact variants. Product copy is 1-2 px different. | **yes** (`decisions.md` B1) |
| D-02 | Primary button label (product) | White `#FFFFFF` on `#10B981` | Ink `#1A1B1F` on `#10B981` | Measured contrast: white is 2.54:1; ink is 6.78:1. F1 decision **A2** | Exact variant (option 1) measures SSIM **0.99520**. The product label colour is an intentional, unmeasured deviation. | **yes** (`decisions.md` A2), but the final button choice is **re-opened** (section 3.4) |
| D-03 | Emerald fill as a control fill | `#10B981` fill | `#10B981` fill | Measured contrast: 2.54:1 against white, below 3:1 for a UI boundary; A2 approves it as a fill only | The exact sample is the Figma fill; the ink label (6.78:1) and the Figma shadow carry the affordance. Never used as text/icon. | **yes** (A2) |
| D-04 | Result vocabulary (product) | `Pass` / `Minor` / `Major` | `No issue observed` / `Attention recommended` / `Defect found` | Content/privacy: locked Phase 1 result vocabulary; "Pass"/"Minor"/"Major" are not the approved product vocabulary | None on the exact sample: it uses the Figma labels. Product labels are longer; the toggle text widths change. | **yes** (Phase 1 vocabulary, `decisions.md`) |
| D-05 | Three extra result states | Not drawn in the Figma toggle | Secondary chip row: `Not checked`, `Not applicable`, `Could not verify` | Content/data: the product has six results; Figma draws three. The owner instructed the extra three as a secondary row | No effect on the Figma node crop (the extra row is below the 350 x 70 node). Visual language is the same fill/radius/type. | **yes** (F1.1 instruction) |
| D-06 | Delivery card copy (product) | `WhatsApp` / `Sent`; `Fleet Portal` / `Synced` | `Report link` / `Sent`; `Workshop copy` / `Synced` | Content/privacy: no portal feature; public-report allowlist. Figma sample copy is test-only | Exact fixture uses the Figma copy and measures SSIM **0.99198**. The product card differs only in text runs. | **yes** (locked public-report/portal rules) |
| D-07 | Product result option height | 40 px option inside a 52 px pill | 48 px option inside a 60 px pill | Accessibility: F1 decision **B2** requires 48 dp targets | Exact variant keeps 40 px and measures SSIM **0.98340**. Product pill is 8 px taller. | **yes** (B2) |
| D-08 | Product delivery/status chip | 28 px neutral pill with an 8 px emerald dot | Same structure; `StatusChip` remains available for other screens with a 20 px icon | Content: not all product status chips are the Figma delivery chip | No effect on the exact card sample (it uses `FigmaStatusPill`). Other screens are an F2 mapping task. | **yes for the exact card; other screens open** |

---

## Open deviations (owner decision required)

| ID | Area | Figma value | Our value | Reason | Measured effect | Owner-approved |
|---|---|---|---|---|---|---|
| O-01 | Text field boundary | Filled `#F4F3F8`, no stroke | Filled `#F4F3F8`, no stroke (F1's 1.5 dp `outline` border removed) | Figma-exact, but the fill against white is **1.09:1**, below WCAG 2.2 1.4.11 (3:1) for an input boundary | Exact to Figma. The accessibility failure is measured and listed here. Choice: accept Figma (borderless) or restore the 1.5 dp `outline` border (F1 behaviour). | **no** |
| O-02 | Primary button final colour | Option 1 (white on `#10B981`, 2.54:1) | Product default stays option 3 (ink on `#10B981`, 6.78:1) | The owner re-opened A2 and asked for four options | Options measured: 2.54 / 3.77 / 6.78 / 6.48. Option 2 needs >= 18.66 px bold. | **no** (choice pending) |
| O-03 | Workshop admin header height | 80 px | Shared `AdminTopBar` default 64 px | App-structure/skin decision, not a component token | No component sample measures the admin header. Needs a role skin if A is kept. | **no** |
| O-04 | Large-card radius in product screens | 32 or 48 for large cards | `AppCard` default 24; optional `radius` now exists | F2 screen mapping has not happened | No measured screen yet. The delivery card exact uses 32. | **no** (F2 mapping) |
| O-05 | General `StatusChip` composition on non-delivery screens | Figma status pills are 28 px dot pills | General `StatusChip` is a 20 px icon chip | F2 has not mapped every status use | Not measured. The delivery card exact uses the Figma pill. | **no** (F2 mapping) |
| O-06 | Motion tokens | Not present in the Figma export | 120/220/320 ms, 0.98 press scale | No Figma source to compare | Cannot be measured against Figma | **no** (unverifiable) |

---

## Notes

- **Nothing else was left changed.** The F1-added button border, the
  filter/segment/result option borders, the admin chrome borders, the offline
  banner border and the 1.5 dp data-table separators were removed or reverted
  to the Figma values.
- The **Figma exports were not modified** and the Figma sample copy stays in
  test-only fixtures guarded by `FixtureGuard`.
- The **product default** for the primary button is still option 3 (ink label)
  as F1 left it. Option 1 is used only by the Figma-exact gallery/harness
  variants.
