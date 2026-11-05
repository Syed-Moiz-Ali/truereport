# Figma WCAG 2.2 Contrast Audit (Phase F0)

- **Status:** read-only analysis. No application code, server, configuration, or existing docs were modified.
- **Date:** 2026-11-05
- **Audited exports:** `figma/technision_figma` (16 phone), `figma/Workshop_admin_figma` (12 desktop), `figma/platform_admin_figma` (10 desktop), `figma/public_report_figma` (4 mobile + 3 desktop) = **45 screens**.
- **Deliverable:** this report. **Reproduction script:** `docs/ui/figma/tools/contrast-audit.mjs`.

## 1. Executive summary

The Figma exports contain **1,876 text nodes**. A background could be determined for **1,664** of them (88.7%). Of those, **1,544 pass** and **120 fail** WCAG AA contrast: **107 normal-text failures at 4.5:1**, **1 large-text failure at 3:1**, and **12 translucent placeholder failures**. A further **212 text nodes (11.3%)** sit on image, gradient, blur, translucent or group-alpha backgrounds and are reported as **not determinable** rather than guessed.

The dominant defect is the primary emerald token:

- **`#FFFFFF` on `#10B981` = 2.54:1** (needs 4.5:1 for text, 3:1 for icons). Appears **61 times as text on 42 screens** and **90 times as icon fill on 43 screens**.
- **`#10B981` on `#FFFFFF` = 2.54:1** and **`#10B981` on `#F4F3F8` = 2.30:1**. Appear **17** and **14** times respectively (the latter includes one large `22 px / 700` “95%” label that still fails 3:1).

Using the palette as designed, **43 of 45 screens** contain at least one deterministic contrast failure. The two screens with zero deterministic failures are Technician `12_13._Final_Review_(Missing_Items)` (18 determined nodes) and Technician `15_14._Finalize_&_Approval_(Swipe)` (25 determined nodes).

Two PNG spot checks found failures that are *hidden* inside the “not determinable” bucket:

- `04_4._Job_Details_&_Intake`, node `1:7510` “Renault Megane 3”: white 16 px/700 text over a 40%-to-transparent `#1A1B1F` scrim on the vehicle photo. The measured backdrop under the text is as bright as `#F9F9FA`; **measured white contrast falls to 1.05:1** in the bright half of the label.
- `06_6._Detailed_Findings_Grid_(Desktop_Web)`, node `1:6862` “Laser Geometry Verified”: white 11 px/600 text over a 50%-to-transparent scrim; **worst sampled ratio 2.71:1**.

These are not included in the 120 failures because the ancestor rule cannot assert a single background; they are reported separately in §6.

## 2. Scope and artefacts

| App | Screens | Root frame | Text nodes | Text with determinate background | Text undetermined |
|---|---:|---|---:|---:|---:|
| Technician (phone) | 16 | opaque `#FFFFFF` | 362 | 314 | 48 |
| Workshop admin (desktop) | 12 | opaque `#FFFFFF` | 681 | 614 | 67 |
| Platform admin (desktop) | 10 | opaque `#FFFFFF` | 565 | 511 | 54 |
| Public report (mobile + desktop) | 7 | opaque `#FFFFFF` | 268 | 225 | 43 |
| **Total** | **45** | — | **1,876** | **1,664** | **212** |

Facts established before measuring:

- All 45 root frames are a single opaque `#FFFFFF` fill.
- All **1,876** text nodes have a `text.characters` string and exactly one visible `SOLID` fill. There are **no gradient-text, image-text, multi-fill or empty text nodes**.
- Every text node has numeric `fontSize` and `fontWeight`; no `MIXED` values. Weight `600` is treated as **not bold** for the WCAG large-text threshold (conservative).
- Across all node types the exports contain 4,415 `SOLID`, 32 `IMAGE`, 8 `GRADIENT_LINEAR` and 1 `GRADIENT_RADIAL` fills; 97 `SOLID` strokes; 68 `BACKGROUND_BLUR`, 11 `LAYER_BLUR`, 972 `DROP_SHADOW` and 3 `INNER_SHADOW` effects.
- `fillStyleId` and variables are empty in these exports, so raw fill hex values were used.
- Frame dimensions are Flutter logical px; for these exports logical px and CSS px are treated as **1:1**.

## 3. Method

### 3.1 Text-pair extraction

Every visible `TEXT` node was visited with its ancestor chain. For each text node:

1. Read the single visible solid text fill (`fills[].hex`).
2. Walk **up** the serialized tree to the **nearest ancestor that paints any fill**. That fill hides everything outside it.
3. If every ancestor up to and including that painted ancestor has opacity 1 and no background/layer blur, and the painted ancestor's only visible paint is an opaque `SOLID` with no other paint above it, the ancestor's hex is the effective background.
4. If any ancestor up to that point has group opacity below 1 or a background/layer blur, or the painted ancestor is an image, gradient, translucent solid, has multiple paints, the background is **not determinable**; the text node is excluded from pass/fail totals. This also excludes text inside defocused/dimmed background mock layers.
5. Alpha in the text fill (`#RRGGBBAA`) is composited over the determined solid background with `C = alpha * fg + (1 - alpha) * bg`.

This is deliberately conservative: it does not infer a background from a rectangular **sibling** behind the text. That case is listed as unresolved (§12), even where the PNG suggests an obvious answer.

### 3.2 WCAG maths and thresholds

Standard WCAG 2.x relative luminance, sRGB:

```
c_linear = c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4
L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
CR = (L_lighter + 0.05) / (L_darker + 0.05)
```

- Normal text: **4.5:1**
- Large text (`fontSize >= 24 px`, or `fontSize >= 18.66 px` and `fontWeight >= 700`): **3:1**
- UI components and graphical objects: **3:1**
- Rounded sizes are handled from the JSON px values; no hand-rounded size to cross a threshold.

### 3.3 Alpha and blur

- For 8-digit export hex values, the alpha is taken from the last two hex digits (e.g. `#FFFFFFE5` = alpha 229/255 = 0.898). `fill.opacity` holds the same value; it was **not** multiplied a second time.
- Where an alpha value is over a known solid surface, the report shows both the **unscaled** hex ratio (what the raw RGB would give if opaque) and the **composited** ratio. The composited value is labelled as an assumption.
- Background/layer blur or group opacity below 1 on any ancestor up to the first painted ancestor makes the background **not determinable**; no blur radius or group compositing was estimated. A blur/opacity ancestor outside an opaque child fill is ignored because that child hides it.

### 3.4 PNG use

The PNG was read only for ambiguous cases, using `System.Drawing.Bitmap.GetPixel` on the `@2x` exports. Coordinates were mapped as `(node.absoluteBoundingBox - root.absoluteRenderBounds) * 2`. Four representative cases are reported in §6. This is a spot check, not full coverage.

## 4. Summary counts

| Metric | Count |
|---|---:|
| Screens | 45 |
| Text nodes audited | 1,876 |
| Text nodes with determinate background | 1,664 |
| Text nodes not determinable | 212 |
| Distinct opaque `fg`/`bg` pairs | 43 |
| Distinct alpha text pairs | 4 |
| Opaque text nodes passing 4.5:1 / 3:1 | 1,452 normal + 92 large = 1,544 |
| Opaque text nodes failing 4.5:1 / 3:1 | 107 normal + 1 large = 108 |
| Translucent text nodes passing / failing | 0 / 12 |
| **Total text nodes failing** | **120** |
| Distinct failing pair + requirement buckets | 12 (8 opaque buckets + 4 alpha buckets) |
| Distinct failing colour/alpha pairs | 11 (7 opaque colour pairs + 4 alpha variants) |
| Screens with at least one deterministic failure | 43 / 45 |

### 4.1 Failures by app

| App | Screens | Determined text | Normal pass | Normal fail | Large pass | Large fail | Alpha pass | Alpha fail | Failing nodes | Distinct failing pair+req | Failing screens |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Technician (phone) | 16 | 314 | 268 | 27 | 19 | 0 | 0 | 0 | 27 | 4 | 14 |
| Workshop admin (desktop) | 12 | 614 | 534 | 32 | 44 | 0 | 0 | 4 | 36 | 7 | 12 |
| Platform admin (desktop) | 10 | 511 | 455 | 31 | 17 | 0 | 0 | 8 | 39 | 7 | 10 |
| Public report (mobile + desktop) | 7 | 225 | 195 | 17 | 12 | 1 | 0 | 0 | 18 | 4 | 7 |
| **Total** | **45** | **1,664** | **1,452** | **107** | **92** | **1** | **0** | **12** | **120** | **12** | **43** |

### 4.2 Most repeated failing pairs

| Pair | Ratio | Nodes | Screens | Notes |
|---|---:|---:|---:|---|
| `#FFFFFF` on `#10B981` | 2.54 | 61 | 42 | Dominant CTA label/icon problem |
| `#10B981` on `#FFFFFF` | 2.54 | 17 | 11 | Green text on white cards |
| `#10B981` on `#F4F3F8` | 2.30 | 14 | 8 | Includes one large `95%` label |
| `#5E5D69` at 40–70% alpha on `#FFFFFF` | 1.85–3.25 | 12 | 5 | Placeholder/divider text |
| `#DAD9DF` on `#FFFFFF` | 1.40 | 10 | 1 | Bullet glyphs in audit log |
| `#E9E7ED` on `#FFFFFF` | 1.23 | 4 | 1 | Bullet glyphs in live queue |

## 5. Worst offenders

“Count” is the number of failing text nodes; “screens” is the number of screens containing at least one. The table includes alpha variants separately because their rendered result differs from the raw hex.

| Foreground | Background | Ratio | Requirement | Count | Screens | Example (app · screen · node · text) |
|---|---|---:|---:|---:|---:|---|
| `#E9E7ED` | `#FFFFFF` | 1.23 | 4.5 | 4 | 1 | Workshop · `03_2._Live_Job_Queue` · `1:602` · “•” |
| `#DAD9DF` | `#FFFFFF` | 1.40 | 4.5 | 10 | 1 | Platform · `09_10._Platform_Audit_Events_Log` · `1:5406` · “•” |
| `#5E5D69` @ 0.4 | `#FFFFFF` | 1.85 | 4.5 | 3 | 3 | Platform · `03_3._Register_New_Workshop` · `1:3807` · “/” |
| `#5E5D69` @ 0.502 | `#FFFFFF` | 2.21 | 4.5 | 2 | 2 | Platform · `02_2._Add_Staff_-_Create_Account` · `1:3748` · “e.g. Marcus Vance” |
| `#10B981` | `#F4F3F8` | 2.30 | 4.5 (3.0 large) | 14 | 8 | Technician · `06_6._Equipment_Checklist` · `1:7654` · “1 of 4 Verified”; Public · `05_5._Wide_Hero_&_Summary_Overview_(Desktop_Web)` · `1:6401` · “95%” (large) |
| `#FFFFFF` | `#10B981` | 2.54 | 4.5 | 61 | 42 | Technician · `01_1._Login_&_Language_Selection` · `1:7116` · “Sign In” |
| `#10B981` | `#FFFFFF` | 2.54 | 4.5 | 17 | 11 | Technician · `04_4._Job_Details_&_Intake` · `1:7500` · “Step 1 of 4” |
| `#5E5D69` @ 0.6 | `#FFFFFF` | 2.66 | 4.5 | 6 | 3 | Workshop · `01_3._Create_-_Schedule_Job` · `1:235` · “e.g. Arthur Pendelton” |
| `#D97706` | `#F4F3F8` | 2.89 | 4.5 | 1 | 1 | Workshop · `02_1._Workshop_Dashboard` · `1:427` · “Awaiting Review” |
| `#5E5D69` @ 0.698 | `#FFFFFF` | 3.25 | 4.5 | 1 | 1 | Workshop · `10_10._Share-Link_Deactivation` · `1:2631` · “e.g. Disputed damage markup…” |
| `#6C7A71` | `#F4F3F8` | 4.08 | 4.5 | 1 | 1 | Technician · `11_11._Dense_Mechanical_List` · `1:8273` · “Enter fluid level / notes” |

The disabled `#C7C5D3` “Resolve to Continue” (Technician `12_13._Final_Review_(Missing_Items)` `1:8465`) is not in this table: its ancestor has group opacity 0.8, so it is in the undetermined bucket. Its stored-color ratio is 1.70:1 and its actual rendered ratio is about 1.52:1. It is an inactive control and exempt from 1.4.3, but it is still hard to read.

The alpha variants’ **unscaled** `#5E5D69` on `#FFFFFF` is 6.47:1; the displayed ratios are the composited values after the recorded alpha. This is why grouping by hex alone would falsely “pass” them.

## 6. PNG-resolved ambiguities

These nodes were in the 212 “not determinable” bucket. Sampling only resolves the local pixels described; it does not turn them into a single deterministic pair.

| Node | Text | Foreground | Backdrop construction | Sampled backdrop | White/normal-text ratio | Verdict |
|---|---|---|---|---:|---|---|
| Technician `04_4._Job_Details_&_Intake` `1:7510` | “Renault Megane 3” | `#FFFFFF`, 16 px / 700 | `#1A1B1F` gradient alpha 0.40 → 0 over vehicle photo | `#F9F9FA`, `#AAABAF`, `#A7AAAD`, `#1D2023` | 1.05, 2.29, 2.33, 16.37 | **Fails over the bright body panels**; not readable across the whole label |
| Public report `06_6._Detailed_Findings_Grid_(Desktop_Web)` `1:6862` | “Laser Geometry Verified” | `#FFFFFF`, 11 px / 600 | `#1A1B1F` gradient alpha 0.50 → 0 over photo | `#9B9DA2`, `#8D9197`, `#1A2027` | 2.71, 3.17, 16.41 | **Fails over the bright right-hand portion** |
| Technician `09_9._Defect_Detail_&_Evidence` `1:8030` | “BAY 04 • IN PROGRESS” | `#1A1B1F`, 11 px / 600 | `#FFFFFFE5` + `BACKGROUND_BLUR` over photo | `#FDFDFD`–`#FFFFFF` | 16.92–17.21 | **Passes at sampled location** (effectively white) |
| Workshop `12_12._Print-Ready_PDF_Preview` `1:3068` | “IMG_3091_R_FRONT” | `#FFFFFF`, 10 px / 400 | `#1A1B1FD9` + `BACKGROUND_BLUR` over photo | `#1F2023`, `#252629`, `#3F3F41` | 16.29, 15.13, 10.51 | **Passes at sampled location** |

The first two are real, visually significant failures that a pure JSON pass/fail count misses. The light scrims need a darker scrim or a solid text plate; see §11.

## 7. Full distinct opaque text-pair table

Deduped by `fg`/`bg`; counts are text nodes. “N/L” = normal/large. “Fail N/L” = failing normal/large nodes. Requirement is 4.5:1 for normal text and 3:1 for large text; only the `#10B981` on `#F4F3F8` row contains a large failure. Representative example is the first encountered instance.

| fg | bg | Nodes (N/L) | Fail N/L | Min ratio | Apps | Representative (app · screen · node · text) |
|---|---|---|---:|---:|---:|---|
| `#E9E7ED` | `#FFFFFF` | 4 (4/0) | 4/0 | 1.23 | 1 | Workshop · `03_2._Live_Job_Queue` · `1:602` · “•” |
| `#DAD9DF` | `#FFFFFF` | 10 (10/0) | 10/0 | 1.40 | 1 | Platform · `09_10._Platform_Audit_Events_Log` · `1:5406` · “•” |
| `#10B981` | `#F4F3F8` | 14 (13/1) | 13/1 | 2.30 | 4 | Technician · `06_6._Equipment_Checklist` · `1:7654` · “1 of 4 Verified” |
| `#FFFFFF` | `#10B981` | 61 (61/0) | 61/0 | 2.54 | 4 | Technician · `01_1._Login_&_Language_Selection` · `1:7116` · “Sign In” |
| `#10B981` | `#FFFFFF` | 17 (17/0) | 17/0 | 2.54 | 4 | Technician · `04_4._Job_Details_&_Intake` · `1:7500` · “Step 1 of 4” |
| `#D97706` | `#F4F3F8` | 1 (1/0) | 1/0 | 2.89 | 1 | Workshop · `02_1._Workshop_Dashboard` · `1:427` · “Awaiting Review” |
| `#6C7A71` | `#F4F3F8` | 1 (1/0) | 1/0 | 4.08 | 1 | Technician · `11_11._Dense_Mechanical_List` · `1:8273` · “Enter fluid level / notes” |
| `#6C7A71` | `#FFFFFF` | 6 (6/0) | 0/0 | 4.51 | 1 | Technician · `01_1._Login_&_Language_Selection` · `1:7097` · “Email” |
| `#62616D` | `#E1DEEC` | 3 (3/0) | 0/0 | 4.60 | 3 | Technician · `15_14._Finalize_&_Approval_(Swipe)` · `1:8835` · “Bay #04” |
| `#6B7280` | `#FFFFFF` | 3 (3/0) | 0/0 | 4.83 | 1 | Public · `02_2._Findings_by_Category-_Tyre_Defect_(Mobile_Web)` · `1:6092` · “FL” |
| `#B45309` | `#FFFBEB` | 2 (2/0) | 0/0 | 4.84 | 1 | Workshop · `03_2._Live_Job_Queue` · `1:594` · “In Progress” |
| `#C2410C` | `#FFF7ED` | 1 (1/0) | 0/0 | 4.88 | 1 | Workshop · `03_2._Live_Job_Queue` · `1:640` · “Pending Review” |
| `#B91A24` | `#FFDAD6` | 2 (2/0) | 0/0 | 5.02 | 2 | Technician · `12_13._Final_Review_(Missing_Items)` · `1:8438` · “Required” |
| `#B91A24` | `#FFDAD7` | 1 (1/0) | 0/0 | 5.03 | 1 | Public · `02_2._Findings_by_Category-_Tyre_Defect_(Mobile_Web)` · `1:6080` · “1 Attention” |
| `#5E5D69` | `#E9E7ED` | 1 (1/0) | 0/0 | 5.27 | 1 | Technician · `15_14._Finalize_&_Approval_(Swipe)` · `1:8915` · “Slide to Finalize Inspection” |
| `#5E5D69` | `#EEEDF3` | 10 (10/0) | 0/0 | 5.56 | 3 | Technician · `14_15._Offline_Sync_Queue` · `1:8650` · “No Signal” |
| `#006C49` | `#EEEDF3` | 1 (1/0) | 0/0 | 5.57 | 1 | Workshop · `12_12._Print-Ready_PDF_Preview` · `1:2993` · “CERTIFICATE #1042” |
| `#5E5D69` | `#F4F3F8` | 214 (214/0) | 0/0 | 5.86 | 4 | Technician · `01_1._Login_&_Language_Selection` · `1:7080` · “عربي” |
| `#006C49` | `#F4F3F8` | 30 (30/0) | 0/0 | 5.87 | 4 | Technician · `03_3._Empty_State_Dashboard` · `1:7358` · “100% Pass Rate” |
| `#B91A24` | `#F4F3F8` | 3 (3/0) | 0/0 | 5.88 | 2 | Workshop · `01_3._Create_-_Schedule_Job` · `1:142` · “Hold” |
| `#BA1A1A` | `#FFFFFF` | 2 (2/0) | 0/0 | 6.46 | 2 | Workshop · `04_4._Assign_Technician` · `1:876` · “Unassigned” |
| `#FFFFFF` | `#BA1A1A` | 1 (1/0) | 0/0 | 6.46 | 1 | Workshop · `10_10._Share-Link_Deactivation` · `1:2639` · “Confirm Deactivation” |
| `#5E5D69` | `#FFFFFF` | 510 (510/0) | 0/0 | 6.47 | 4 | Technician · `01_1._Login_&_Language_Selection` · `1:7086` · “Vehicle Condition & Fleet Diagnostics” |
| `#006C49` | `#FFFFFF` | 33 (33/0) | 0/0 | 6.48 | 4 | Technician · `01_1._Login_&_Language_Selection` · `1:7124` · “Request ID” |
| `#B91A24` | `#FFFFFF` | 4 (4/0) | 0/0 | 6.49 | 3 | Technician · `15_14._Finalize_&_Approval_(Swipe)` · `1:8885` · “Requires Follow-up” |
| `#93000A` | `#FFDAD6` | 2 (2/0) | 0/0 | 7.24 | 1 | Public · `06_6._Detailed_Findings_Grid_(Desktop_Web)` · `1:6646` · “MODERATE SCRATCH” |
| `#3C4A42` | `#E9E7ED` | 1 (1/0) | 0/0 | 7.61 | 1 | Technician · `11_11._Dense_Mechanical_List` · `1:8262` · “ACTIVE” |
| `#3C4A42` | `#F4F3F8` | 36 (36/0) | 0/0 | 8.45 | 3 | Technician · `02_2._Assigned_Jobs_Dashboard` · `1:7145` · “SHIFT 1 • BAY A” |
| `#3C4A42` | `#FFF5EB` | 1 (1/0) | 0/0 | 8.67 | 1 | Technician · `14_15._Offline_Sync_Queue` · `1:8664` · “All high-res vehicle capture tags…” |
| `#79000E` | `#FFDAD6` | 4 (4/0) | 0/0 | 8.93 | 1 | Technician · `12_13._Final_Review_(Missing_Items)` · `1:8358` · “3 Action Items” |
| `#3C4A42` | `#FFFFFF` | 107 (107/0) | 0/0 | 9.33 | 3 | Workshop · `04_4._Assign_Technician` · `1:940` · “Stage 01” |
| `#1A1B1F` | `#FED7AA` | 1 (1/0) | 0/0 | 12.71 | 1 | Technician · `09_9._Defect_Detail_&_Evidence` · `1:8078` · “Minor” |
| `#002113` | `#6FFBBE` | 3 (3/0) | 0/0 | 13.22 | 1 | Workshop · `04_4._Assign_Technician` · `1:976` · “Brakes L2” |
| `#1B1B25` | `#E3E1EF` | 2 (2/0) | 0/0 | 13.24 | 2 | Technician · `06_6._Equipment_Checklist` · `1:7650` · “01” |
| `#410004` | `#FFDAD7` | 1 (1/0) | 0/0 | 13.26 | 1 | Platform · `09_10._Platform_Audit_Events_Log` · `1:5422` · “Security Action” |
| `#1B1B25` | `#E9E7ED` | 1 (1/0) | 0/0 | 13.92 | 1 | Workshop · `06_7._Workshop_Template_List` · `1:1440` · “Rapid Intake” |
| `#1A1B1F` | `#EEEDF3` | 10 (10/0) | 0/0 | 14.78 | 2 | Technician · `09_9._Defect_Detail_&_Evidence` · `1:8091` · “Dent / Crease” |
| `#1B1B25` | `#F4F3F8` | 30 (30/0) | 0/0 | 15.46 | 2 | Technician · `04_4._Job_Details_&_Intake` · `1:7447` · “VF1KZ040647192831” |
| `#1A1B1F` | `#F4F3F8` | 133 (126/7) | 0/0 | 15.59 | 4 | Technician · `02_2._Assigned_Jobs_Dashboard` · `1:7201` · “Ready” |
| `#1A1B1F` | `#FFF5EB` | 1 (1/0) | 0/0 | 15.99 | 1 | Technician · `14_15._Offline_Sync_Queue` · `1:8660` · “Working Offline — Saving Locally” |
| `#1B1B25` | `#FFFFFF` | 79 (68/11) | 0/0 | 17.07 | 2 | Technician · `04_4._Job_Details_&_Intake` · `1:7417` · “Vehicle Info” |
| `#1A1B1F` | `#FFFFFF` | 302 (228/74) | 0/0 | 17.21 | 4 | Technician · `01_1._Login_&_Language_Selection` · `1:7078` · “English” |
| `#FFFFFF` | `#1A1B1F` | 3 (3/0) | 0/0 | 17.21 | 2 | Platform · `01_1._Global_Hierarchy_&_Staff_Tree` · `1:3327` · “All (14)” |

### 7.1 Alpha text pairs

These are the 12 text nodes whose text fill itself carries alpha. All fail; the raw hex alone would pass. Alpha comes from the 8-digit hex (same value as `fill.opacity`).

| Raw fg | Alpha | bg | Nodes | Fails | Composited ratio | Unscaled ratio | Example |
|---|---:|---|---:|---:|---:|---:|---|
| `#5E5D6966` | 0.400 | `#FFFFFF` | 3 | 3 | 1.85 | 6.47 | Platform · `03_3._Register_New_Workshop` · `1:3807` · “/” |
| `#5E5D6980` | 0.502 | `#FFFFFF` | 2 | 2 | 2.21 | 6.47 | Platform · `02_2._Add_Staff_-_Create_Account` · `1:3748` · “e.g. Marcus Vance” |
| `#5E5D6999` | 0.600 | `#FFFFFF` | 6 | 6 | 2.66 | 6.47 | Workshop · `01_3._Create_-_Schedule_Job` · `1:235` · “e.g. Arthur Pendelton” |
| `#5E5D69B2` | 0.698 | `#FFFFFF` | 1 | 1 | 3.25 | 6.47 | Workshop · `10_10._Share-Link_Deactivation` · `1:2631` · “e.g. Disputed damage markup…” |

## 8. Per-screen failures

Screens with at least one deterministic or alpha failure are listed, plus the two zero-failure screens at the end of the Technician block. “Determined” is the number of text nodes with a determinate background on that screen; it excludes that screen’s undetermined nodes.

| App | Screen | Determined | Failing | Normal fail | Large fail | Alpha fail |
|---|---|---:|---:|---:|---:|---:|
| Platform admin (desktop) | `09_10._Platform_Audit_Events_Log` | 60 | 13 | 13 | 0 | 0 |
| Platform admin (desktop) | `03_3._Register_New_Workshop` | 36 | 10 | 5 | 0 | 5 |
| Platform admin (desktop) | `04_4._Workshop_Details_&_Settings` | 50 | 5 | 4 | 0 | 1 |
| Platform admin (desktop) | `02_2._Add_Staff_-_Create_Account` | 45 | 4 | 2 | 0 | 2 |
| Platform admin (desktop) | `07_7._Master_Dropdowns_&_Data_Catalogues` | 46 | 2 | 2 | 0 | 0 |
| Platform admin (desktop) | `01_1._Global_Hierarchy_&_Staff_Tree` | 75 | 1 | 1 | 0 | 0 |
| Platform admin (desktop) | `05_5._Shared_Master_Inspection-Item_Library` | 65 | 1 | 1 | 0 | 0 |
| Platform admin (desktop) | `06_6._Master_Item_Content_&_Translation_Editor` | 55 | 1 | 1 | 0 | 0 |
| Platform admin (desktop) | `08_8._Global_Equipment_Library` | 37 | 1 | 1 | 0 | 0 |
| Platform admin (desktop) | `10_9._Global_Platform_Settings` | 42 | 1 | 1 | 0 | 0 |
| Public report (mobile + desktop) | `05_5._Wide_Hero_&_Summary_Overview_(Desktop_Web)` | 52 | 7 | 6 | 1 | 0 |
| Public report (mobile + desktop) | `06_6._Detailed_Findings_Grid_(Desktop_Web)` | 78 | 3 | 3 | 0 | 0 |
| Public report (mobile + desktop) | `07_7._Limitations_&_Disclaimer_Footer_(Desktop_Web)` | 32 | 3 | 3 | 0 | 0 |
| Public report (mobile + desktop) | `01_1._Customer_Summary_Hero_(Mobile_Web)` | 15 | 2 | 2 | 0 | 0 |
| Public report (mobile + desktop) | `02_2._Findings_by_Category-_Tyre_Defect_(Mobile_Web)` | 27 | 1 | 1 | 0 | 0 |
| Public report (mobile + desktop) | `03_3._Exterior_Condition_&_Evidence_(Mobile_Web)` | 12 | 1 | 1 | 0 | 0 |
| Public report (mobile + desktop) | `04_4._Verification_&_PDF_Footer_(Mobile_Web)` | 9 | 1 | 1 | 0 | 0 |
| Technician app (phone) | `13_12._Tire_Condition_Capture` | 24 | 5 | 5 | 0 | 0 |
| Technician app (phone) | `11_11._Dense_Mechanical_List` | 23 | 3 | 3 | 0 | 0 |
| Technician app (phone) | `02_2._Assigned_Jobs_Dashboard` | 23 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `04_4._Job_Details_&_Intake` | 25 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `06_6._Equipment_Checklist` | 16 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `07_7._Main_Inspection_Hub` | 27 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `08_8._360_Exterior_Wireframe` | 16 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `09_9._Defect_Detail_&_Evidence` | 18 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `10_10._Photo_Annotation_&_Markup` | 8 | 2 | 2 | 0 | 0 |
| Technician app (phone) | `01_1._Login_&_Language_Selection` | 11 | 1 | 1 | 0 | 0 |
| Technician app (phone) | `03_3._Empty_State_Dashboard` | 12 | 1 | 1 | 0 | 0 |
| Technician app (phone) | `05_5._Consent_&_Signatures` | 16 | 1 | 1 | 0 | 0 |
| Technician app (phone) | `14_15._Offline_Sync_Queue` | 37 | 1 | 1 | 0 | 0 |
| Technician app (phone) | `16_16._Post-Finalization_Success` | 15 | 1 | 1 | 0 | 0 |
| Technician app (phone) | `12_13._Final_Review_(Missing_Items)` | 18 | 0 | 0 | 0 | 0 |
| Technician app (phone) | `15_14._Finalize_&_Approval_(Swipe)` | 25 | 0 | 0 | 0 | 0 |
| Workshop admin (desktop) | `03_2._Live_Job_Queue` | 60 | 8 | 8 | 0 | 0 |
| Workshop admin (desktop) | `01_3._Create_-_Schedule_Job` | 64 | 7 | 4 | 0 | 3 |
| Workshop admin (desktop) | `06_7._Workshop_Template_List` | 62 | 6 | 6 | 0 | 0 |
| Workshop admin (desktop) | `07_6._Add_Staff_-_Create_Account` | 48 | 3 | 3 | 0 | 0 |
| Workshop admin (desktop) | `02_1._Workshop_Dashboard` | 49 | 2 | 2 | 0 | 0 |
| Workshop admin (desktop) | `04_4._Assign_Technician` | 35 | 2 | 2 | 0 | 0 |
| Workshop admin (desktop) | `08_8._Template_Builder` | 63 | 2 | 2 | 0 | 0 |
| Workshop admin (desktop) | `11_11._Workshop_Settings` | 37 | 2 | 2 | 0 | 0 |
| Workshop admin (desktop) | `05_5._Workshop_Staff_Management` | 50 | 1 | 1 | 0 | 0 |
| Workshop admin (desktop) | `09_9._Completed_Report_Viewer` | 59 | 1 | 1 | 0 | 0 |
| Workshop admin (desktop) | `10_10._Share-Link_Deactivation` | 24 | 1 | 0 | 0 | 1 |
| Workshop admin (desktop) | `12_12._Print-Ready_PDF_Preview` | 63 | 1 | 1 | 0 | 0 |

### 8.1 Failing pair mix by app

| App | Failing pair | Ratio | Nodes |
|---|---|---:|---:|
| Technician | `#FFFFFF` on `#10B981` | 2.54 | 19 |
| Technician | `#10B981` on `#FFFFFF` | 2.54 | 5 |
| Technician | `#10B981` on `#F4F3F8` | 2.30 | 2 |
| Technician | `#6C7A71` on `#F4F3F8` | 4.08 | 1 |
| Workshop | `#FFFFFF` on `#10B981` | 2.54 | 19 |
| Workshop | `#E9E7ED` on `#FFFFFF` | 1.23 | 4 |
| Workshop | `#10B981` on `#F4F3F8` | 2.30 | 4 |
| Workshop | `#10B981` on `#FFFFFF` | 2.54 | 4 |
| Workshop | `#5E5D6999` @ 0.6 on `#FFFFFF` | 2.66 | 3 |
| Workshop | `#D97706` on `#F4F3F8` | 2.89 | 1 |
| Workshop | `#5E5D69B2` @ 0.698 on `#FFFFFF` | 3.25 | 1 |
| Platform | `#FFFFFF` on `#10B981` | 2.54 | 13 |
| Platform | `#DAD9DF` on `#FFFFFF` | 1.40 | 10 |
| Platform | `#10B981` on `#FFFFFF` | 2.54 | 5 |
| Platform | `#5E5D6966` @ 0.4 on `#FFFFFF` | 1.85 | 3 |
| Platform | `#10B981` on `#F4F3F8` | 2.30 | 3 |
| Platform | `#5E5D6999` @ 0.6 on `#FFFFFF` | 2.66 | 3 |
| Platform | `#5E5D6980` @ 0.502 on `#FFFFFF` | 2.21 | 2 |
| Public report | `#FFFFFF` on `#10B981` | 2.54 | 10 |
| Public report | `#10B981` on `#F4F3F8` | 2.30 | 5 |
| Public report | `#10B981` on `#FFFFFF` | 2.54 | 3 |

## 9. UI-component and palette audit

### 9.1 Text palette matrix

Cells are measured contrast ratios. **Bold** = passes 4.5:1 for normal text. *Italic* = 3.0–4.49:1, usable only for large text or non-text where 3:1 applies. ~~Struck~~ = below 3.0:1.

**Dark foregrounds on light surfaces**

| fg \ bg | `#FFFFFF` | `#F4F3F8` | `#EEEDF3` | `#E1DEEC` | `#E9E7ED` | `#E5E7EB` |
|---|---:|---:|---:|---:|---:|---:|
| `#1A1B1F` | **17.21** | **15.59** | **14.78** | **13.00** | **14.03** | **13.90** |
| `#3C4A42` | **9.33** | **8.45** | **8.02** | **7.05** | **7.61** | **7.54** |
| `#5E5D69` | **6.47** | **5.86** | **5.56** | **4.89** | **5.27** | **5.23** |
| `#6C7A71` | **4.51** | *4.08* | *3.87* | *3.40* | *3.67* | *3.64* |
| `#006C49` | **6.48** | **5.87** | **5.57** | **4.89** | **5.28** | **5.23** |
| `#10B981` | ~~2.54~~ | ~~2.30~~ | ~~2.18~~ | ~~1.92~~ | ~~2.07~~ | ~~2.05~~ |
| `#B91A24` | **6.49** | **5.88** | **5.58** | **4.90** | **5.29** | **5.24** |
| `#D97706` | *3.19* | ~~2.89~~ | ~~2.74~~ | ~~2.41~~ | ~~2.60~~ | ~~2.57~~ |
| `#B45309` | **5.02** | **4.55** | *4.31* | *3.79* | *4.09* | *4.06* |
| `#F59E0B` | ~~2.15~~ | ~~1.95~~ | ~~1.85~~ | ~~1.62~~ | ~~1.75~~ | ~~1.73~~ |

**Foregrounds on coloured surfaces**

| fg \ bg | `#10B981` | `#006C49` | `#6FFBBE` | `#FFDAD7` | `#FFDAD6` | `#FFFBEB` | `#FFF5EB` |
|---|---:|---:|---:|---:|---:|---:|---:|
| `#FFFFFF` | ~~2.54~~ | **6.48** | ~~1.29~~ | ~~1.29~~ | ~~1.29~~ | ~~1.04~~ | ~~1.08~~ |
| `#1A1B1F` | **6.78** | ~~2.66~~ | **13.29** | **13.32** | **13.32** | **16.59** | **15.99** |
| `#006C49` | ~~2.55~~ | ~~1.00~~ | **5.00** | **5.02** | **5.01** | **6.25** | **6.02** |
| `#B91A24` | ~~2.56~~ | ~~1.00~~ | **5.01** | **5.03** | **5.02** | **6.26** | **6.03** |
| `#F59E0B` | ~~1.18~~ | *3.02* | ~~1.66~~ | ~~1.66~~ | ~~1.66~~ | ~~2.07~~ | ~~2.00~~ |
| `#D97706` | ~~1.26~~ | ~~2.03~~ | ~~2.46~~ | ~~2.47~~ | ~~2.47~~ | *3.07* | ~~2.96~~ |
| `#B45309` | ~~1.98~~ | ~~1.29~~ | *3.88* | *3.89* | *3.89* | **4.84** | **4.67** |

### 9.2 Component-pair audit

Counts are observed text or icon instances where noted; “—” means the pair is a palette/token check with no direct instance in these screens.

| Component / role | Pair | Ratio | Requirement | Observed | Verdict |
|---|---|---:|---:|---|---|
| Primary CTA text | `#FFFFFF` on `#10B981` | 2.54 | 4.5 | 61 text / 42 screens | **FAIL** |
| Primary CTA icon | `#FFFFFF` on `#10B981` | 2.54 | 3.0 | 90 icons / 43 screens | **FAIL** |
| Primary fill boundary | `#10B981` vs `#FFFFFF` | 2.54 | 3.0 | 61 text/CTA instances | **FAIL** if the fill is the only boundary |
| Primary text | `#10B981` on `#FFFFFF` | 2.54 | 4.5 | 17 text / 11 screens | **FAIL** |
| Primary icon | `#10B981` on `#FFFFFF` | 2.54 | 3.0 | 29 icons / 17 screens | **FAIL** |
| Primary text | `#10B981` on `#F4F3F8` | 2.30 | 4.5 | 13 normal + 1 large | **FAIL** (large also fails 3.0) |
| Primary icon | `#10B981` on `#F4F3F8` | 2.30 | 3.0 | 31 icons / 13 screens | **FAIL** |
| Deep-green text | `#006C49` on `#FFFFFF` | 6.48 | 4.5 | 33 text / 4 apps | PASS |
| Deep-green icon | `#006C49` on `#FFFFFF` | 6.48 | 3.0 | 19 icons / 11 screens | PASS |
| Deep-green text/icon | `#006C49` on `#F4F3F8` | 5.87 | 4.5 / 3.0 | 30 text, 60 icons | PASS |
| Deep-green on mint | `#006C49` on `#6FFBBE` | 5.00 | 4.5 / 3.0 | — (palette) | PASS |
| Deep-green on translucent mint | `#006C49` on `#6FFBBE4D` over `#FFFFFF` | 5.91 (estimated) | 4.5 | 9 translucent badges | PASS under white assumption |
| Muted text/icon | `#5E5D69` on `#FFFFFF` | 6.47 | 4.5 / 3.0 | 510 text, 143 icons | PASS |
| Muted text/icon | `#5E5D69` on `#F4F3F8` | 5.86 | 4.5 / 3.0 | 214 text, 205 icons | PASS |
| Muted alternative | `#6C7A71` on `#FFFFFF` | 4.51 | 4.5 / 3.0 | 6 text, 4 icons | PASS (marginal text) |
| Muted alternative | `#6C7A71` on `#F4F3F8` | 4.08 | 4.5 / 3.0 | 1 text, 1 icon | **FAIL text** (passes 3:1 icon) |
| Dark text | `#3C4A42` on `#FFFFFF` / `#F4F3F8` | 9.33 / 8.45 | 4.5 | 107 / 36 text | PASS |
| Dark text | `#1A1B1F` on `#FFFFFF` / `#F4F3F8` | 17.21 / 15.59 | 4.5 | 302 / 133 text | PASS |
| Danger text/icon | `#B91A24` on `#FFDAD7` | 5.03 | 4.5 / 3.0 | 1 text, 1 icon | PASS |
| Danger text/icon | `#B91A24` on `#FFDAD6` | 5.02 | 4.5 / 3.0 | 2 text, 4 icons | PASS |
| Danger on translucent red | `#B91A24` on `#FFDAD74D` over `#FFFFFF` | 6.02 (estimated) | 4.5 | 2 translucent badges | PASS under white assumption |
| Danger on surface | `#B91A24` on `#F4F3F8` | 5.88 | 4.5 | 3 text / 2 apps | PASS |
| Warning icon | `#F59E0B` on `#FFFFFF` | 2.15 | 3.0 | 18 stroke instances | **FAIL** |
| Warning icon | `#F59E0B` on `#F4F3F8` | 1.95 | 3.0 | 1 icon | **FAIL** |
| Warning icon | `#F59E0B` on `#EEEDF3` | 1.85 | 3.0 | 1 icon | **FAIL** |
| Warning text | `#D97706` on `#F4F3F8` | 2.89 | 4.5 | 1 text | **FAIL** |
| Amber alternative | `#B45309` on `#FFFFFF` / `#F4F3F8` | 5.02 / 4.55 | 4.5 | 2 text on `#FFFBEB`; palette checks | PASS, but 4.31 on `#EEEDF3` |
| Amber alternative | `#92400E` on `#FFF5EB` / `#F4F3F8` / `#FFFFFF` | 6.59 / 6.42 / 7.09 | 4.5 | palette checks; 1 undetermined text on `#FEF3C7B2` | PASS |
| Disabled text | `#C7C5D3` on `#FFFFFF` | 1.70 (≈1.52 with 0.8 group opacity) | exempt | 1 text (undetermined) / 3 icons | WCAG-exempt (inactive control); still hard to read |
| Badge text | `#002113` on `#6FFBBE` | 13.22 | 4.5 | 3 text | PASS |
| Badge text | `#93000A` on `#FFDAD6` | 7.24 | 4.5 | 2 text | PASS |
| Badge text | `#410004` on `#FFDAD7` | 13.26 | 4.5 | 1 text | PASS |
| Progress fill / track | `#10B981` on `#EEEDF3` | 2.18 | 3.0 | multiple progress bars | **FAIL** |
| Progress fill / track | `#10B981` on `#E5E7EB` | 2.05 | 3.0 | palette | **FAIL** |
| Progress fill / track | `#006C49` on `#EEEDF3` | 5.57 | 3.0 | candidate | PASS |
| Progress fill / track | `#006C49` on `#E5E7EB` | 5.23 | 3.0 | candidate | PASS |
| Border/outline | `#E3E2E7` on `#FFFFFF` / `#F4F3F8` | 1.29 / 1.17 | 3.0 | 6 strokes | **FAIL** |
| Border/outline | `#DAD9DF` on `#FFFFFF` / `#F4F3F8` | 1.40 / 1.27 | 3.0 | palette / text glyphs | **FAIL** |
| Border/outline | `#D1D5DB` on `#FFFFFF` | 1.47 | 3.0 | 8 strokes | **FAIL** |
| Border/outline | `#E5E7EB` on `#FFFFFF` | 1.24 | 3.0 | 5 strokes | **FAIL** |
| Border/outline | `#C7C5D3` on `#FFFFFF` | 1.70 | 3.0 | 6 strokes | **FAIL** |
| Border/outline | `#BBCABF` on `#FFFFFF` | 1.71 | 3.0 | palette / 1 icon | **FAIL** |
| Focus ring (light) | `#006C49` on `#FFFFFF` / `#F4F3F8` | 6.48 / 5.87 | 3.0 | candidate; no Figma focus token | PASS |
| Focus ring (light) | `#10B981` on `#FFFFFF` | 2.54 | 3.0 | candidate only | **FAIL** |
| Focus ring (light) | `#F59E0B` on `#FFFFFF` | 2.15 | 3.0 | candidate only | **FAIL** |

### 9.3 Stroke pair audit

All 97 visible solid strokes were compared with the nearest opaque ancestor background and, where present, the node’s own opaque fill. 26 distinct stroke/bg/context pairs remained determinable. Width is exported stroke weight (may be in/out/centre aligned).

| Stroke | Adjacent fill | Context | Ratio | Count | Width | Verdict 3:1 |
|---|---|---|---:|---:|---:|---|
| `#BA1A1A` | `#BA1A1A` | own fill | 1.00 | 1 | 2.0 | FAIL (same colour; likely hidden/overpainted) |
| `#F4F3F8` | `#FFFFFF` | parent background | 1.10 | 1 | 12.8 | FAIL (decorative separator) |
| `#EEEDF3` | `#FFFFFF` | parent background | 1.16 | 1 | 13.2 | FAIL (decorative separator) |
| `#E3E2E7` | `#F4F3F8` | parent background | 1.17 | 6 | 1.17 | FAIL |
| `#E5E7EB` | `#FAFAFC` | own fill | 1.19 | 1 | 1.40 | FAIL |
| `#E5E7EB` | `#FFFFFF` | parent background | 1.24 | 4 | 1.87 | FAIL |
| `#FFFFFF` | `#E3E2E7` | own fill | 1.29 | 1 | 2.0 | FAIL |
| `#FFFFFF` | `#E1DEEC` | parent background | 1.32 | 6 | 2.0 | FAIL |
| `#D1D5DB` | `#FFFFFF` | parent background | 1.47 | 5 | 1.40 | FAIL |
| `#D1D5DB` | `#FFFFFF` | own fill | 1.47 | 3 | 1.87 | FAIL |
| `#C7C5D3` | `#FFFFFF` | parent background | 1.70 | 6 | 2.67 | FAIL |
| `#F59E0B` | `#FFFFFF` | parent background | 2.15 | 18 | 1.44 | FAIL |
| `#F59E0B` | `#FFFFFF` | own fill | 2.15 | 2 | 0.92 | FAIL |
| `#10B981` | `#F4F3F8` | parent background | 2.30 | 3 | 2.80 | FAIL |
| `#10B981` | `#FFFFFF` | parent background | 2.54 | 7 | 13.2 | FAIL |
| `#10B981` | `#FFFFFF` | own fill | 2.54 | 8 | 2.0 | FAIL |
| `#FFFFFF` | `#10B981` | own fill | 2.54 | 5 | 2.0 | FAIL |
| `#BA1A1A` | `#FFDAD6` | own fill | 5.00 | 1 | 2.80 | PASS |
| `#BA1A1A` | `#F4F3F8` | parent background | 5.85 | 2 | 2.0 | PASS |
| `#006C49` | `#F4F3F8` | parent background | 5.87 | 1 | 3.0 | PASS |
| `#BA1A1A` | `#FFF5F5` | own fill | 6.04 | 1 | 2.33 | PASS |
| `#BA1A1A` | `#FFFFFF` | parent background | 6.46 | 2 | 1.40 | PASS |
| `#006C49` | `#FFFFFF` | parent background | 6.48 | 1 | 2.0 | PASS |
| `#006C49` | `#FFFFFF` | own fill | 6.48 | 1 | 2.0 | PASS |
| `#3C4A42` | `#F4F3F8` | parent background | 8.45 | 7 | 1.95 | PASS |
| `#1A1B1F` | `#FFFFFF` | parent background | 17.21 | 1 | 1.80 | PASS |

### 9.4 Named icon-fill audit

All 906 `VECTOR` nodes were scanned; **766** had a determinate solid ancestor and produced **43** distinct fill/background pairs. The table below is the subset of **36** pairs whose node name contains “Icon”. 9 of those pairs fail 3:1 and account for 158 icon instances. This audit uses **fill**; line-art icons whose visible mark is the stroke are covered by §9.3, not here.

| Icon fill | Background | Ratio | Instances | Screens | Verdict 3:1 |
|---|---|---:|---:|---:|---|
| `#C7C5D3` | `#FFFFFF` | 1.70 | 3 | 1 | FAIL |
| `#BBCABF` | `#FFFFFF` | 1.71 | 1 | 1 | FAIL |
| `#F59E0B` | `#EEEDF3` | 1.85 | 1 | 1 | FAIL |
| `#F59E0B` | `#F4F3F8` | 1.95 | 1 | 1 | FAIL |
| `#10B981` | `#6FFBBE` | 1.96 | 1 | 1 | FAIL |
| `#FFFFFF` | `#F59E0B` | 2.15 | 1 | 1 | FAIL |
| `#10B981` | `#F4F3F8` | 2.30 | 31 | 13 | FAIL |
| `#FFFFFF` | `#10B981` | 2.54 | 90 | 43 | FAIL |
| `#10B981` | `#FFFFFF` | 2.54 | 29 | 17 | FAIL |
| `#6C7A71` | `#F4F3F8` | 4.08 | 1 | 1 | PASS |
| `#6C7A71` | `#FFFFFF` | 4.51 | 4 | 1 | PASS |
| `#006C49` | `#E1DEEC` | 4.89 | 6 | 1 | PASS |
| `#BA1A1A` | `#FFDAD6` | 5.00 | 1 | 1 | PASS |
| `#B91A24` | `#FFDAD6` | 5.02 | 4 | 2 | PASS |
| `#5E5D69` | `#E3E1EF` | 5.02 | 1 | 1 | PASS |
| `#B91A24` | `#FFDAD7` | 5.03 | 1 | 1 | PASS |
| `#62616D` | `#F4F3F8` | 5.51 | 1 | 1 | PASS |
| `#5E5D69` | `#EEEDF3` | 5.56 | 3 | 1 | PASS |
| `#5E5D69` | `#F4F3F8` | 5.86 | 205 | 34 | PASS |
| `#006C49` | `#F4F3F8` | 5.87 | 60 | 23 | PASS |
| `#B91A24` | `#F4F3F8` | 5.88 | 2 | 2 | PASS |
| `#FFFFFF` | `#BA1A1A` | 6.46 | 1 | 1 | PASS |
| `#5E5D69` | `#FFFFFF` | 6.47 | 143 | 27 | PASS |
| `#FFFFFF` | `#006C49` | 6.48 | 37 | 36 | PASS |
| `#006C49` | `#FFFFFF` | 6.48 | 19 | 11 | PASS |
| `#B91A24` | `#FFFFFF` | 6.49 | 3 | 2 | PASS |
| `#93000A` | `#FFDAD6` | 7.24 | 4 | 2 | PASS |
| `#3C4A42` | `#F4F3F8` | 8.45 | 2 | 1 | PASS |
| `#1B1B25` | `#E1DEEC` | 12.89 | 3 | 1 | PASS |
| `#002113` | `#6FFBBE` | 13.22 | 1 | 1 | PASS |
| `#410004` | `#FFDAD7` | 13.26 | 1 | 1 | PASS |
| `#1A1B1F` | `#EEEDF3` | 14.78 | 4 | 3 | PASS |
| `#1B1B25` | `#F4F3F8` | 15.46 | 15 | 4 | PASS |
| `#1A1B1F` | `#F4F3F8` | 15.59 | 40 | 15 | PASS |
| `#1A1B1F` | `#FFFFFF` | 17.21 | 9 | 5 | PASS |
| `#FFFFFF` | `#1A1B1F` | 17.21 | 1 | 1 | PASS |

## 10. Comparison with the current product

The product was measured with the same formula. Sources: `client/packages/design_system/lib/src/tokens.dart` (AppStatusColors light/dark, explicit `ColorScheme` values) and `server/src/main/resources/public-report/report.css`.

### 10.1 Current product results

| Group | Representative pairs | Ratios | Verdict |
|---|---|---|---|
| `AppStatusColors.light` | neutral, info, success, warning, danger, critical | 5.36, 6.15, 5.67, 5.41, 6.36, 7.63 | All PASS 4.5 |
| `AppStatusColors.dark` | neutral, info, success, warning, danger, critical | 8.12, 9.22, 8.83, 9.09, 9.23, 9.68 | All PASS 4.5 |
| `ColorScheme.light` text | `onPrimary`/`primary`, `primary`/`surface`, `secondary`/`surface`, `onSurface`/`surface`, `error`/`surface` | 12.08, 11.51, 5.97, 15.52, 7.10 | All PASS 4.5 |
| `ColorScheme.light` UI | `outlineVariant #D5E3E6` on `#F7FAFA` / `#FFFFFF` | 1.25 / 1.32 | **FAIL 3:1** |
| `ColorScheme.dark` text | `onPrimary`/`primary`, `primary`/`surface`, `secondary`/`surface`, `onSurface`/`surface`, `error`/`surface` | 7.70, 10.88, 10.56, 15.54, 10.96 | All PASS 4.5 |
| `ColorScheme.dark` UI | `outlineVariant #33464C` on `#0D1416` / `#1B262A` | 1.88 / 1.56 | **FAIL 3:1** |
| `report.css` light text | body, primary button, link, on-variant, badges | 15.52, 12.08, 5.97, 5.80–6.09, 5.28–7.63 | All PASS 4.5 |
| `report.css` light UI | `--outline #D5E3E6` on `#F7FAFA` / `#FFFFFF` | 1.25 / 1.32 | **FAIL 3:1** |
| `report.css` light focus | `--secondary #0F6B6F` on `#F7FAFA` | 5.97 | PASS 3:1 |
| `report.css` dark text | body, primary button, link, on-variant, badges | 15.54, 9.05, 10.56, 12.18, 8.83–9.68 | All PASS 4.5 |
| `report.css` dark UI | `--outline #33464C` on `#0D1416` | 1.88 | **FAIL 3:1** |
| `report.css` dark focus | `--secondary #82D0D4` on `#0D1416` | 10.56 | PASS 3:1 |

Important detail: in dark mode `.button.primary` uses `color: var(--surface-card)` = `#1B262A` on `#8FD1D8`, which is **9.05:1**. A hypothetical white label on the same dark primary would be **1.71:1**; white is not the implemented dark-mode foreground.

`ColorScheme.fromSeed` generates `onSurfaceVariant`, `surfaceContainer*` derivatives and other Material roles that are not explicitly tokenised here. Those generated values were **not assumed**; only explicitly written colours were measured. `onSurface` on the explicit surfaces passes: light ≥12.82, dark ≥9.74.

### 10.2 Figma vs product

- **Text:** the product is materially better than the Figma design. The product’s primary and status pairs are all ≥5.36:1. The Figma palette relies on raw emerald for primary text/icons: white-on-`#10B981` alone appears on 42/45 screens at 2.54:1, and `#10B981`-on-light adds 11 screens on white and 8 on `#F4F3F8` at 2.30–2.54:1. The product uses deep teal/teal-green status pairs designed around contrast.
- **Borders/indicators:** both are weak. Figma outline/border strokes sit at 1.10–1.71:1; the product `outlineVariant` is 1.25–1.88:1. Both fail the 3:1 UI-component requirement where the border is the only boundary. The Figma side is worse because it also uses low-contrast amber indicators (`#F59E0B` = 2.15:1 on white) and pale separators.
- **Focus:** the product has passing focus outlines (5.97:1 light, 10.56:1 dark). Figma has no explicit focus-ring token; only candidate palette checks are possible.
- **Disabled:** the product has no explicit disabled token in the audited files; Figma disabled text/icon `#C7C5D3` on white is 1.70:1 (≈1.52 at 0.8 group opacity), which is exempt for inactive controls but poor for readability.
- **Dark mode:** the Figma exports are light-only; no dark-mode Figma pairs could be audited. The product dark-mode text pairs all pass.

## 11. Prioritised fixes

All replacement values below are **candidates, not approved tokens**. They are measured against the same backgrounds; validate them in the rendered Flutter/CSS implementation before adopting.

### P0 — widespread, blocks normal reading

1. **White text/icons on `#10B981` = 2.54:1 (61 text + 90 icons).**
   - Option A (keep white fg): darken the fill to **`#047857`** → white **5.48:1**, or **`#065F46`** → white **7.68:1**.
   - Option B (keep `#10B981` fill): use **`#002113`** fg → **6.75:1**, or **`#1A1B1F`** → **6.78:1**.
   - Do **not** use `#006C49` on `#10B981` (2.55:1), even though `#006C49` is good on light surfaces.
2. **`#10B981` text on light surfaces = 2.54:1 on white, 2.30:1 on `#F4F3F8` (31 text nodes including one large label).**
   - Replace with **`#006C49`**: 6.48:1 on white, 5.87:1 on `#F4F3F8`.
   - Use the same `#006C49` for icons on white/`#F4F3F8` (6.48/5.87) and white icons on `#006C49` (6.48).
3. **White text over photo scrims (`1:7510`, `1:6862`) = measured as low as 1.05:1 and 2.71:1.**
   - Raise the `#1A1B1F` scrim to **at least 0.60 alpha at every text position**: measured **4.68:1** over the brightest sampled pixel (`#F9F9FA`) and **6.52:1** at 0.70.
   - Or place the label on a solid `#1A1B1F` plate. Do not rely on a 0.40–0.50 scrim that reaches 0 alpha under the label.
4. **Translucent placeholder text (`#5E5D69` at 0.40–0.70) = 1.85–3.25:1 (12 nodes).**
   - Use opaque **`#5E5D69`** → 6.47:1 on white, 5.86:1 on `#F4F3F8`.
   - If placeholder must look lighter, `#6C7A71` is 4.51:1 on white but **fails** at 4.08:1 on `#F4F3F8`; keep it only on pure white.
5. **Warning text `#D97706` on `#F4F3F8` = 2.89:1; amber indicators `#F59E0B` = 2.15:1 on white / 1.95:1 on `#F4F3F8` / 1.85:1 on `#EEEDF3`.**
   - Use **`#92400E`** for warning text/icons → 6.42:1 on `#F4F3F8`, 7.09:1 on white, 6.59:1 on `#FFF5EB`.
   - `#B45309` is a secondary candidate → 4.55:1 on `#F4F3F8`, 5.02:1 on white, 4.84:1 on `#FFFBEB`, but it falls to 4.31:1 on `#EEEDF3` and 3.79:1 on `#E1DEEC`.

### P1 — component/state clarity

6. **`#6C7A71` body/placeholder text on `#F4F3F8` = 4.08:1 (1 node).** Use `#5E5D69` (5.86:1) or `#3C4A42` (8.45:1).
7. **Progress fill `#10B981` against track `#EEEDF3` = 2.18:1; against `#E5E7EB` = 2.05:1.** Use `#006C49` → 5.57:1 against `#EEEDF3`, 5.23:1 against `#E5E7EB`.
8. **Borders/outlines:** `#E3E2E7`, `#DAD9DF`, `#D1D5DB`, `#E5E7EB`, `#C7C5D3`, `#BBCABF` against white/`#F4F3F8` are 1.12–1.71:1. For a visible boundary use **`#6C7A71`** (4.51:1 white, 4.08:1 `#F4F3F8`) or **`#5E5D69`** (6.47/5.86). If a border is purely decorative, it does not need 3:1, but it must not be the only cue.
9. **Focus rings:** no Figma focus token exists. Adopt **`#006C49`** on light surfaces (6.48:1 white, 5.87:1 `#F4F3F8`, well above 3:1). `#10B981` (2.54:1) and `#F59E0B` (2.15:1) are not acceptable focus indicators.
10. **Decorative bullet glyphs `#E9E7ED` (1.23:1) and `#DAD9DF` (1.40:1) on white.** If truly decorative, mark them `aria-hidden` and keep them out of the text layer. If they convey meaning, use `#5E5D69` (6.47:1).
11. **Disabled state `#C7C5D3` on white (stored 1.70:1; ≈1.52 at 0.8 group opacity).** The node is in the undetermined bucket because the group opacity prevents a single deterministic ratio. WCAG 1.4.3 exempts inactive controls, so this is not a formal AA failure. If the product wants readable disabled text, use `#6C7A71` (4.51:1) or `#5E5D69` (6.47:1).

## 12. What could not be determined

### 12.1 Undetermined text nodes (212)

| Reason | Nodes |
|---|---:|
| Ancestor fill is translucent (alpha 0.051–0.749; most common 0.302, 0.600, 0.698) | 98 |
| Ancestor has background or layer blur | 99 |
| Ancestor fill is a linear gradient | 6 |
| Ancestor opacity below 1 (0, 0.6, 0.8, 0.85, 0.9) | 9 |
| **Total** | **212** |

Notes:

- One node (`03_3._Empty_State_Dashboard` `1:7345`, “Queue is current • Synced just now”) has an ancestor opacity of **0** and is effectively not rendered; it is counted in the 212 but is not a real contrast defect.
- The blur count includes the fixed bottom navigation/header overlays (`#FFFFFFE5`, `#FFFFFFF2`, `#FFFFFFCC`) over photos and cards. Four representative PNG checks are in §6; the rest need per-screen image analysis.
- The opacity bucket includes the disabled `#C7C5D3` “Resolve to Continue” (`12_13._Final_Review_(Missing_Items)` `1:8465`, ancestor group opacity 0.8) and dimmed staff/tree states (0.6, 0.85, 0.9). The blur bucket includes the defocused/dimmed background mock screens (`Defocused…`, `Blurred Background…`, `Underlying…`). Those are not part of the primary UI; they are excluded from pass/fail rather than treated as failures.
- The translucent bucket includes translucent pills such as `#6FFBBE4D`, `#FFDAD74D`, `#10B9811A` and `#F4F3F8B2`. Where those sit over a known white/`#F4F3F8` card, estimates are:
  - `#006C49` on `#6FFBBE4D` over white ≈ **5.91:1** (over `#F4F3F8` ≈ 5.50:1) — likely PASS.
  - `#B91A24` on `#FFDAD74D` over white ≈ **6.02:1** (over `#F4F3F8` ≈ 5.61:1) — likely PASS.
  - `#006C49` on `#10B9811A` over white ≈ **5.89:1** — likely PASS.
  - **`#10B981` on `#F4F3F8B2`/`#F4F3F899` over white ≈ 2.30–2.37:1** — likely **FAIL** if the backdrop is light; this affects examples such as `05_5._Wide_Hero_&_Summary_Overview_(Desktop_Web)` `1:6393` “Class A Zeroed” (16 px/700). This is not in the 120 count; verify against the actual image.
- The method cannot see a **sibling** opaque rectangle that sits behind text. Example: `10_10._Photo_Annotation_&_Markup` `1:8148` “Markup Active” is inside a frame whose fill is `#FFFFFF01` (alpha 0.004), while a sibling green rectangle `1:8146` (`#10B981`) covers the pill area. The text was marked undetermined (the ancestor fill is effectively transparent) even though the likely background is the green sibling; the PNG would be needed to resolve the z-order/coverage.
- `#FFFFFF` text on linear-gradient scrims (`1:7510`, `1:6862`) cannot be reduced to one ratio; the PNG-sampled range is in §6.

### 12.2 Unknown or unmeasured tokens

- **Generated Material colours:** `onSurfaceVariant`, `primaryContainer`, `secondaryContainer`, `surfaceContainer*` derivatives not explicitly written in `tokens.dart` are generated by `ColorScheme.fromSeed`. They were not assumed or measured. Explicit `onSurface` surfaces all pass.
- **Focus ring:** the Figma files contain no explicit focus-ring paint/token. “Focus” named nodes are conceptual frames, not a reusable ring style; only candidate palette colours were measured.
- **Dark mode in Figma:** none of the 45 exports is dark mode. Product dark mode was measured separately.
- **Line-art icons:** vector **fill** is not always the visible mark. Example `08_8._360_Exterior_Wireframe` `1:7991` has a `#FFFFFF` fill with a `#F59E0B` stroke; the white-fill icon pairs are not the meaningful graphic. Stroke measurements are in §9.3.
- **Font rendering:** all text uses Plus Jakarta Sans with numeric size/weight; 600 was treated as not bold for WCAG large text. If the implementation treats 600 as bold for the 18.66 px rule, a few large-text classifications could change; no audited node sits exactly on 18.66 px, so no current pass/fail changes.
- **PNG sampling:** only four nodes were sampled. Pixel samples are not a substitute for rendered DOM/Flutter contrast, and they do not account for text anti-aliasing, font hinting, or image colour management.

## 13. How to reproduce

The audit is fully scripted; it reads the exports only and writes nothing into the repository unless `--out` is supplied.

```powershell
# Summary to stdout
node docs/ui/figma/tools/contrast-audit.mjs --root=figma --format=summary

# Full JSON (write to a temp location; do not commit)
node docs/ui/figma/tools/contrast-audit.mjs --root=figma --out="$env:TEMP\contrast-audit.json"
```

`--root` defaults to `figma`. The script uses Node.js 24 and no third-party dependencies. The JSON contains `summary`, `byApp`, `byScreen`, `textPairs`, `alphaPairs`, `pairFailures`, `undetermined`, `strokes`, `vectors`, `containers`, `textRecords`, `palette` and `product`.

PNG spot checks were performed separately with PowerShell `System.Drawing`:

```powershell
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile('figma/.../@2x.png')
# map: (node.absoluteBoundingBox - root.absoluteRenderBounds) * 2
$c = $img.GetPixel($x, $y)
```

The script’s thresholds are `normal 4.5`, `large 3.0`, `UI 3.0`, `largePxBold 18.66`, `largePx 24`. The report does not modify the Figma exports or the product.
