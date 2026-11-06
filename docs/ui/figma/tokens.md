# Figma Design-System Extraction (Phase F0)

**Status:** Evidence and mapping only. This document does **not** choose a visual direction and does not change code, tokens, config, or other docs.
**C0 note (6 November 2026):** the F0 evidence below is unchanged, but the product is now light-only per `adr/ADR-F1-006-light-only-theme.md`. Dark-theme rows describe the pre-C0 system and are superseded.
**Scope:** all four Figma exports (45 screens), cross-checked against the existing implementation and design docs.
**Date:** 2026-11-05.

Sources analysed:

- `figma/technision_figma` — 16 screens, 390 px phone.
- `figma/Workshop_admin_figma` — 12 screens, 1280 px desktop.
- `figma/platform_admin_figma` — 10 screens, 1280 px desktop.
- `figma/public_report_figma` — 7 screens (4 × 390, 3 × 1280).
- Verified copies under `docs/ui/figma-export` were not re-read separately; the originals and copies are byte-identical per `package-manifest.json` totals.
- Per-screen specs in `docs/ui/figma/specs/**` used as a cross-check.

---

## 1. Method and coverage

### 1.1 Tooling

A Node.js (v24.11.1) aggregator walks every screen JSON and counts only values present in the export. No value is inferred, rounded to a token, or invented.

- Script: `docs/ui/figma/tools/aggregate-tokens.js`
- Table renderer: `docs/ui/figma/tools/render-tables.js`
- Reproduce:

```bash
node docs/ui/figma/tools/aggregate-tokens.js --out %TEMP%\tokens-aggregate.json
node docs/ui/figma/tools/render-tables.js --in %TEMP%\tokens-aggregate.json
```

### 1.2 Counting rules (important for interpreting the totals)

| Item | Rule |
|---|---|
| Colour count | Every visible `SOLID` fill occurrence, including text fills, counted once per fill. Gradient pseudo-fills are counted separately; gradient stops are counted separately. Strokes and effects are separate maps. |
| Appears in app | A colour/font/radius/spacing value is attributed to an app if at least one visible node in that app uses it. |
| Typography | Every visible `TEXT` node; family + style + weight from `text.fontName`/`text.fontWeight`; size, line-height and tracking from `text`. |
| Radii | `cornerRadius > 0` per node. Non-uniform corners are listed separately. |
| Item spacing | `itemSpacing > 0` or `counterAxisSpacing > 0` per auto-layout container. Padding is counted **per side** (`paddingLeft`, `paddingRight`, `paddingTop`, `paddingBottom` separately). |
| Effects | Every visible effect on a node; exact definition includes type, x, y, blur, spread and RGBA. |
| Assets | Every `assetIndex` entry; reuse measured by SHA-1 of the actual exported SVG/JPG file, not by filename. |

Every aggregated value also carries the exact screen list it came from; the JSON aggregate field is `colors.all[].screens` (and the equivalent `screens` array on typography, radii, spacing and asset entries). The tables below report the app set and screen count to stay readable.

Totals are **pooled node occurrences across 45 screens**, so they are much larger than any single screen's `developerSummary` counts. On a per-screen check this method matches the export summary exactly: for screen 01 (Login), node-level fill counts reproduce `developerSummary.designSystemObserved.colors` one-for-one (`#6C7A71` 7, `#FFFFFF` 6, `#5E5D69` 4, `#1A1B1F` 2, etc.).

### 1.3 Coverage

| Read | Count |
|---|---|
| Screen JSONs | 45 / 45 |
| Screen asset manifests (`screens/*/assets/manifest.json`) | 45 / 45 |
| Package manifests (`package-manifest.json`) | 4 / 4 |
| Exported asset files hashed (SVG + JPG) | 993 |
| Spec files scanned (token/component sections) | 45 / 45 |
| Specs read in full | 3 (tech 01, workshop 02, public 01) |
| Preview `@2x.png` files visually inspected | 0 (specs cover visual reading) |

No file failed to parse. 22 of 45 screens carry the non-fatal export warning "No composed SVG groups were detected in this screen. Individual SVG vectors are still preserved."

**Spec reconciliation:** the three specs read in full (tech 01, workshop 02, public 01) agree with the measured geometry, radii and color values. Their colour-count columns are per-screen `developerSummary` counts, not the pooled totals in this document; a spot check on tech 01 reproduced the summary counts exactly. Where a spec gives a single "dominant" value (e.g. workshop card shadow `0 16 40 .035`), the aggregate confirms the per-screen claim but also shows the shared two-layer shadow used elsewhere.

### 1.4 Structural facts

- **There are no `COMPONENT`, `COMPONENT_SET` or `INSTANCE` nodes.** Node types are `FRAME` 5,893, `TEXT` 1,876, `VECTOR` 906, `RECTANGLE` 245, `GROUP` 6. Everything is frames/text/vectors, so all "components" below are naming/structural patterns, not reusable Figma components.
- **No Figma variables or shared styles.** Across all 45 files `variables` and `variableCollections` are empty, and every `fillStyleId`, `textStyleId`, `strokeStyleId` and `effectStyleId` is blank.
- Layout modes: `VERTICAL` 3,841, `HORIZONTAL` 1,894, `NONE` 140, `GRID` 18.
- Screen widths: 20 × 390 px and 25 × 1280 px. No intermediate/tablet variants, no RTL frames.

---

## 2. Palette

### 2.1 Totals

| Metric | Value |
|---|---:|
| Unique fill/text colours | **80** |
| Unique stroke colours | 17 |
| Unique gradient-stop colours | 13 |
| Unique effect (shadow) colours | 46 |
| **Union of exact colour values** | **133** |
| Opaque (`#RRGGBB`) | 44 |
| Alpha-bearing (`#RRGGBBAA`) | 89 |
| Fill/text occurrences pooled | 4,415 (of which 1,876 are text fills) |
| Fill/text colours in all 4 apps | 16 |
| Fill/text colours in ≥3 apps | 24 |
| Fill/text colours in ≥2 apps | 41 |
| Fill/text colours in exactly 1 app | 39 |

The large alpha-bearing count is mostly shadow opacity (e.g. `#00000004`…`#00000040`) and glass/tint fills, not a designed 89-step alpha ramp.

### 2.2 Shared fill/text palette (used in ≥2 apps)

`Fill count` is pooled occurrences (text + fill). `Role split` is the same data split by whether the fill was on a `TEXT` node or a non-text node.

| Hex | Fill count | Apps | Role split | Screens |
| --- | ---: | --- | --- | ---: |
| #5E5D69 | 1173 | Platform, Public, Tech, Workshop | text 810 · fill 363 | 44 |
| #FFFFFF | 709 | Platform, Public, Tech, Workshop | fill 639 · text 70 | 45 |
| #1A1B1F | 618 | Platform, Public, Tech, Workshop | text 532 · fill 86 | 44 |
| #F4F3F8 | 585 | Platform, Public, Tech, Workshop | fill 585 | 45 |
| #10B981 | 366 | Platform, Public, Tech, Workshop | fill 332 · text 34 | 45 |
| #006C49 | 231 | Platform, Public, Tech, Workshop | fill 144 · text 87 | 43 |
| #3C4A42 | 151 | Platform, Public, Tech, Workshop | text 149 · fill 2 | 33 |
| #1B1B25 | 134 | Platform, Tech, Workshop | text 116 · fill 18 | 13 |
| #FFFFFFE5 | 43 | Platform, Public, Tech, Workshop | fill 43 | 34 |
| #EEEDF3 | 41 | Platform, Public, Tech, Workshop | fill 41 | 16 |
| #B91A24 | 29 | Platform, Public, Tech, Workshop | fill 18 · text 11 | 10 |
| #E9E7ED | 21 | Platform, Public, Tech, Workshop | fill 17 · text 4 | 13 |
| #FFFFFF01 | 19 | Platform, Public, Tech, Workshop | fill 19 | 9 |
| #10B9811A | 18 | Platform, Public, Tech, Workshop | fill 18 | 11 |
| #FFDAD6 | 18 | Public, Tech, Workshop | fill 18 | 6 |
| #DAD9DF | 13 | Platform, Workshop | text 10 · fill 3 | 3 |
| #E1DEEC | 13 | Platform, Public, Tech, Workshop | fill 13 | 5 |
| #F4F3F899 | 13 | Platform, Public, Tech, Workshop | fill 13 | 9 |
| #10B98126 | 10 | Platform, Tech, Workshop | fill 10 | 8 |
| #6FFBBE4D | 9 | Platform, Public, Tech, Workshop | fill 9 | 9 |
| #BA1A1A | 9 | Public, Workshop | fill 7 · text 2 | 5 |
| #E3E2E7 | 9 | Platform, Tech, Workshop | fill 9 | 6 |
| #93000A | 8 | Public, Tech, Workshop | fill 4 · text 4 | 5 |
| #F59E0B | 8 | Tech, Workshop | fill 8 | 3 |
| #5E5D6966 | 7 | Platform, Tech | fill 4 · text 3 | 3 |
| #BBCABF | 7 | Tech, Workshop | fill 7 | 3 |
| #FFFFFFF2 | 7 | Tech, Workshop | fill 7 | 5 |
| #002113 | 6 | Tech, Workshop | text 5 · fill 1 | 4 |
| #5E5D6999 | 6 | Platform, Workshop | text 6 | 2 |
| #C7C5D3 | 6 | Public, Tech | fill 5 · text 1 | 2 |
| #00422B | 5 | Public, Tech | fill 3 · text 2 | 3 |
| #62616D | 5 | Public, Tech, Workshop | text 4 · fill 1 | 5 |
| #6FFBBE | 5 | Platform, Tech, Workshop | fill 5 | 4 |
| #6FFBBE66 | 4 | Public, Workshop | fill 4 | 3 |
| #E3E1EF | 4 | Platform, Tech, Workshop | fill 4 | 4 |
| #B45309 | 3 | Tech, Workshop | text 3 | 2 |
| #FF7A73 | 3 | Public, Tech | fill 3 | 3 |
| #FFDAD7 | 3 | Platform, Public | fill 3 | 2 |
| #FFDAD666 | 2 | Public, Workshop | fill 2 | 2 |
| #FFDAD74D | 2 | Tech, Workshop | fill 2 | 2 |
| #FFFFFF99 | 2 | Platform, Workshop | fill 2 | 2 |

### 2.3 App-specific fill/text palette

| App | Hex | Fill count | Role split | Screens |
| --- | --- | ---: | --- | ---: |
| Tech | #6C7A71 | 12 | text 7 · fill 5 | 3 |
| Tech | #FFFFFFCC | 11 | fill 11 | 11 |
| Public | #10B98133 | 8 | fill 8 | 5 |
| Public | #F4F3F8B2 | 8 | fill 8 | 3 |
| Workshop | #F4F3F866 | 5 | fill 5 | 1 |
| Tech | #79000E | 4 | text 4 | 1 |
| Public | #6B7280 | 3 | text 3 | 1 |
| Workshop | #1A1B1FD9 | 2 | fill 2 | 1 |
| Public | #2F3034BF | 2 | fill 2 | 1 |
| Platform | #410004 | 2 | fill 1 · text 1 | 1 |
| Platform | #5E5D6980 | 2 | text 2 | 1 |
| Public | #F1F0F5 | 2 | text 2 | 1 |
| Workshop | #FFFBEB | 2 | fill 2 | 1 |
| Workshop | #FFFFFFB2 | 2 | fill 2 | 2 |
| Platform | #006C490D | 1 | fill 1 | 1 |
| Platform | #006C491A | 1 | fill 1 | 1 |
| Public | #10B98140 | 1 | fill 1 | 1 |
| Tech | #10B9814D | 1 | fill 1 | 1 |
| Public | #1A1B1F0D | 1 | fill 1 | 1 |
| Tech | #5E5D6933 | 1 | fill 1 | 1 |
| Tech | #5E5D694D | 1 | fill 1 | 1 |
| Workshop | #5E5D69B2 | 1 | text 1 | 1 |
| Tech | #6FFBBE33 | 1 | fill 1 | 1 |
| Public | #92400E | 1 | text 1 | 1 |
| Workshop | #BA1A1A1A | 1 | fill 1 | 1 |
| Workshop | #C2410C | 1 | text 1 | 1 |
| Workshop | #D97706 | 1 | text 1 | 1 |
| Tech | #E1DEEC66 | 1 | fill 1 | 1 |
| Tech | #F59E0B66 | 1 | fill 1 | 1 |
| Public | #FAFAFC | 1 | fill 1 | 1 |
| Tech | #FBBF2433 | 1 | fill 1 | 1 |
| Tech | #FDE68A80 | 1 | fill 1 | 1 |
| Tech | #FED7AA | 1 | fill 1 | 1 |
| Public | #FEF3C7B2 | 1 | fill 1 | 1 |
| Workshop | #FFDAD699 | 1 | fill 1 | 1 |
| Tech | #FFF5EB | 1 | fill 1 | 1 |
| Public | #FFF5F5 | 1 | fill 1 | 1 |
| Workshop | #FFF7ED | 1 | fill 1 | 1 |
| Workshop | #FFFFFF80 | 1 | fill 1 | 1 |

### 2.4 Observed colour roles

These are role clusters inferred from node names/types and the counts above; they are not Figma token names.

- **Base / raised surface:** `#FFFFFF` (709), `#F4F3F8` (585), `#EEEDF3` (41), `#E9E7ED` (21), `#E1DEEC` (13), `#DAD9DF` (13), `#E3E2E7` (9). `#FAF9FE` (the DESIGN.md front-matter surface) is **never observed**.
- **Primary text/ink:** `#1A1B1F` (618, mostly text), `#5E5D69` (1,173, mostly text), `#3C4A42` (151, text), `#1B1B25` (134, mostly text), `#62616D`, `#6C7A71` (tech-only placeholders/icons).
- **Brand action:** `#10B981` is the dominant **fill** (332 of 366); `#006C49` is the dominant deep-green **text/icon** value (87 text + 144 fill). Both are used together; neither is the single "primary" in the export.
- **Mint/verified tints:** `#6FFBBE` and `#6FFBBE4D/66/33`, `#10B9811A/26/33/40/4D`, `#E1DEEC`.
- **Danger/warning:** `#B91A24` (29; tertiary/defect), `#BA1A1A` (9; error), `#93000A`/`#79000E`, `#FFDAD6`/`#FFDAD7` (error containers), `#F59E0B` (8; warning), `#B45309`/`#D97706`/`#C2410C`/`#92400E` (warning text variants).
- **Glass/overlay:** `#FFFFFFE5` (workshop/platform/public headers), `#FFFFFFCC` (tech header, app-only), `#FFFFFF01` (invisible shadow carrier), and the alpha variants `#F4F3F899`, `#F4F3F8B2`, `#F4F3F866`.
- **Gradient:** 9 gradient fills (8 linear, 1 radial). Only one is repeated heavily: a `#BBCABF → #BBCABF00` linear gradient on Platform screen 06 (240/236 stops); the other gradients are single-use decorative fills.

---

## 3. Typography

### 3.1 Families and styles

There are **4 font families** and **11 family/style/weight combinations** in the export.

| Family · style · weight | Count | Apps |
| --- | ---: | --- |
| Plus Jakarta Sans · SemiBold · 600 | 738 | Platform, Public, Tech, Workshop |
| Plus Jakarta Sans · Bold · 700 | 564 | Platform, Public, Tech, Workshop |
| Plus Jakarta Sans · Regular · 400 | 296 | Platform, Public, Tech, Workshop |
| Plus Jakarta Sans · Medium · 500 | 180 | Platform, Public, Tech, Workshop |
| Plus Jakarta Sans · ExtraBold · 800 | 70 | Platform, Public, Tech, Workshop |
| Liberation Mono · Bold · 600 | 15 | Platform, Public, Workshop |
| FreeSerif · Bold · 600 | 3 | Platform, Public, Tech |
| Liberation Mono · Bold · 700 | 3 | Public, Workshop |
| Liberation Mono · Regular · 400 | 3 | Workshop |
| Nimbus Sans · Bold · 700 | 3 | Tech |
| Plus Jakarta Sans · SemiBold Italic · 600 | 1 | Workshop |

**Agreement:** Plus Jakarta Sans is the shared UI family in all four apps, across all five weights.

**Differences / non-Plus-Jakarta text:**

- **FreeSerif Bold 600** is the Arabic fallback, not a brand choice: tech 01 `عربي` (12/16, tracking +0.24), platform 06 `مطلوب` (11/14, +0.44), public 04 `عربي` (12/16, +0.24). It appears in 3 apps, never in Workshop Admin. It is a serif fallback and is letter-spaced, which conflicts with the Phase 1 rule "do not letter-space Arabic".
- **Liberation Mono** is a technical-identifier face (VIN, URN, SHA-256, item codes, ISO number): Workshop Admin (10 occurrences), Platform (6), Public (5); never Tech. Sizes 8/10/11/12/16.
- **Nimbus Sans Bold 700** is a Tech-only outlier in Final Review: the badge numerals `1`, `2`, `3` at 11/16.5. It is almost certainly an accidental substitution; specs flag it as a font outlier.
- **Plus Jakarta Sans SemiBold Italic 600** appears once in Workshop Admin; italic is not part of the shared system.

### 3.2 Sizes

| px | Count | Apps |
| ---: | ---: | --- |
| 11 | 627 | Platform, Public, Tech, Workshop |
| 13 | 303 | Platform, Public, Tech, Workshop |
| 14 | 270 | Platform, Public, Tech, Workshop |
| 12 | 257 | Platform, Public, Tech, Workshop |
| 16 | 222 | Platform, Public, Tech, Workshop |
| 18 | 88 | Platform, Public, Tech, Workshop |
| 22 | 49 | Platform, Public, Tech, Workshop |
| 32 | 34 | Platform, Public, Workshop |
| 26 | 16 | Public, Tech |
| 7.467 | 4 | Public |
| 10 | 3 | Tech, Workshop |
| 7 | 1 | Workshop |
| 8 | 1 | Workshop |
| 9 | 1 | Workshop |

The shared core sizes are 11, 12, 13, 14, 16, 18, 22 and 32 across all four apps; 26 is mobile/public-only. The 7/7.467/8/9/10 values are one-off micro-labels and metadata, not a scale.

### 3.3 Line heights and tracking

Top line heights: 14 (607), 18 (365), 16 (263), 22 (173), 20 (135), 24 (111), 28 (44), 38 (29), 13.75 (20, Platform-only), 32 (20), 17.5 (12, Workshop-only), 21.13 (11). There are 26 numeric line heights plus one `AUTO`/unknown bucket (44 text nodes); the numeric long tail is 16.5, 22.75, 15, 27.5, 22.5, 26, 12, 10.5, 11, 17.88, 19.25, 30.25, 40, 9.

Top tracking values: +0.44 (456), 0 (319), +0.24 (238), −0.16 (200), −0.07 (148), −0.14 (116), +0.55 (101), −0.27 (57), −0.44 (36), −0.45 (30), +0.275 (28), +1.1 (26), −0.8 (25), −0.4 (17), −0.65 (16), −0.55 (13), +0.6 (12). There are 32 distinct tracking values.

### 3.4 Dominant type combinations

These combos reproduce the DESIGN.md front-matter type scale almost exactly (same sizes, weights, line heights and tracking), with one visible split noted below:

| Combination | Count | Apps | DESIGN.md front-matter role |
| --- | ---: | --- | --- |
| Plus Jakarta Sans 600 11/14 ls +0.44 | 361 | all 4 | `label-sm` (11/14, 600, +0.04em) |
| Plus Jakarta Sans 400 13/18 ls 0 | 250 | all 4 | `body-sm` (13/18, 400) |
| Plus Jakarta Sans 600 12/16 ls +0.24 | 172 | all 4 | `label-md` (12/16, 600, +0.02em) |
| Plus Jakarta Sans 700 16/22 ls −0.16 | 164 | all 4 | `headline-sm` (16/22, 700, −0.01em) |
| Plus Jakarta Sans 500 14/20 ls −0.07 | 124 | all 4 | `body-md` (14/20, 500, −0.005em) |
| Plus Jakarta Sans 700 14/18 ls −0.14 | 94 | all 4 | `label-lg` (14/18, 700, −0.01em) |
| Plus Jakarta Sans 600 11/14 ls +0.55 | 91 | all 4 | `label-sm` uppercase variant |
| Plus Jakarta Sans 700 12/16 ls +0.24 | 57 | Public, Tech, Workshop | `label-md` bold variant |
| Plus Jakarta Sans 700 11/14 ls +0.44 | 54 | all 4 | `label-sm` bold variant |
| Plus Jakarta Sans 700 18/24 ls −0.27 | 50 | all 4 | `headline-md` (18/24, 700, −0.015em) |
| Plus Jakarta Sans 700 22/28 ls −0.44 | 30 | all 4 | `headline-lg` (22/28, 700, −0.02em) |
| Plus Jakarta Sans 800 32/38 ls −0.8 | 22 | Platform, Public, Workshop | `headline-xl` size/weight, but −0.025em tracking (mobile value) |
| Plus Jakarta Sans 800 26/32 ls −0.65 | 16 | Public, Tech | `headline-xl-mobile` (26/32, 800, −0.025em) |
| Plus Jakarta Sans 600 16/24 ls −0.16 | 11 | Platform | `body-lg` semibold variant |
| Plus Jakarta Sans 500 16/24 ls −0.16 | 10 | Platform, Public, Workshop | `body-lg` (16/24, 500, −0.01em) |

There are 96 distinct size/line-height/tracking/weight combinations in total; the remaining 81 are screen-specific labels, technical strings, micro-copy or anomalies.

**One split:** 32/38 800 appears with tracking −0.8 (22 nodes, all mobile/public and Workshop) and with −0.96 (7 nodes, Platform/Workshop). DESIGN.md front matter specifies −0.03em = −0.96 px for `headline-xl`; the dominant observed 32/38 value is −0.8 px (−0.025em), i.e. the mobile headline tracking applied at desktop size.

**Note:** The 13/18 `body-sm` pairing is the second most common combo overall; the DESIGN.md prose body text says tracking 0 for body-sm, which matches. But the Phase 1 type scale uses 15/22 body text, which does not appear in the export at all.

---

## 4. Spacing

### 4.1 Auto-layout gaps (`itemSpacing` / `counterAxisSpacing`)

Pooled per container. "Role split" separates main-axis `itemSpacing` from `counterAxisSpacing`.

| px | Count | Apps | Role split |
| ---: | ---: | --- | --- |
| 8 | 309 | Platform, Public, Tech, Workshop | itemSpacing 300 · counterAxisSpacing 9 |
| 16 | 259 | Platform, Public, Tech, Workshop | itemSpacing 257 · counterAxisSpacing 2 |
| 4 | 187 | Platform, Public, Tech, Workshop | itemSpacing 179 · counterAxisSpacing 8 |
| 12 | 156 | Platform, Public, Tech, Workshop | itemSpacing 151 · counterAxisSpacing 5 |
| 24 | 153 | Platform, Public, Tech, Workshop | itemSpacing 152 · counterAxisSpacing 1 |
| 6 | 96 | Platform, Public, Tech, Workshop | itemSpacing 95 · counterAxisSpacing 1 |
| 0 (sub-pixel) | 29 | Platform, Tech, Workshop | itemSpacing 29 |
| 32 | 29 | Platform, Public, Workshop | itemSpacing 29 |
| 2 | 25 | Platform, Public, Tech, Workshop | itemSpacing 25 |
| 10 | 17 | Public, Tech, Workshop | itemSpacing 17 |
| 14 | 16 | Platform, Tech, Workshop | itemSpacing 16 |
| 20 | 11 | Tech, Workshop | itemSpacing 11 |
| 48 | 3 | Public, Workshop | itemSpacing 3 |

Beyond this, 156 distinct `itemSpacing` values are >100 px (191 occurrences) and are fixed/computed layout gaps, not a spacing scale: e.g. 400.89 (12, Workshop), 247.44 (10, Platform), 47.37 (10, Platform), 125.47 (5, Platform), 102.47 (4, Tech), 91.87 (4, Public). The specs for public 01 confirm these are Figma constraint artefacts that should become `space-between`/`gap` in code, not literal tokens.

### 4.2 Padding (per side)

| px | Count | Apps | Role split |
| ---: | ---: | --- | --- |
| 16 | 893 | Platform, Public, Tech, Workshop | left 309 · right 305 · top 158 · bottom 121 |
| 4 | 602 | Platform, Public, Tech, Workshop | top 253 · bottom 198 · left 80 · right 71 |
| 24 | 595 | Platform, Public, Tech, Workshop | left 166 · right 155 · top 144 · bottom 130 |
| 8 | 543 | Platform, Public, Tech, Workshop | top 214 · bottom 164 · left 100 · right 65 |
| 20 | 370 | Platform, Public, Tech, Workshop | left 134 · right 129 · bottom 54 · top 53 |
| 12 | 310 | Platform, Public, Tech, Workshop | right 104 · left 97 · top 59 · bottom 50 |
| 32 | 307 | Platform, Public, Tech, Workshop | bottom 86 · left 76 · right 75 · top 70 |
| 2 | 207 | Platform, Public, Tech, Workshop | top 131 · bottom 67 · left 7 · right 2 |
| 6 | 167 | Platform, Public, Tech, Workshop | bottom 76 · top 73 · left 9 · right 9 |
| 10 | 163 | Platform, Public, Tech, Workshop | top 42 · bottom 41 · left 40 · right 40 |
| 40 | 113 | Platform, Public, Tech, Workshop | left 38 · right 38 · bottom 23 · top 14 |
| 14 | 84 | Platform, Public, Tech, Workshop | top 22 · bottom 22 · left 20 · right 20 |
| 1 | 68 | Platform, Tech, Workshop | top 37 · bottom 31 |
| 28 | 56 | Platform, Tech, Workshop | left 20 · right 16 · top 10 · bottom 10 |
| 48 | 46 | Platform, Workshop | bottom 30 · left 6 · top 5 · right 5 |
| 64 | 34 | Platform, Tech, Workshop | top 25 · bottom 7 · left 1 · right 1 |
| 3 | 23 | Public, Tech, Workshop | top 15 · bottom 8 |
| 80 | 17 | Public, Workshop | top 15 · left 1 · right 1 |
| 96 | 13 | Platform, Workshop | left 12 · bottom 1 |
| 11.5 | 10 | Platform, Workshop | top 7 · bottom 3 |
| 256 | 10 | Platform | left 10 |

There are 178 distinct padding values. The long tail is a mix of optical alignment (1, 2, 3, 6.5), desktop outer margins (80, 96, 256), and one-off computed values (0.01, 16.25, 17.5).

### 4.3 Grid gaps

| px | Count | Apps |
| ---: | ---: | --- |
| 32 | 26 | Platform, Public, Workshop |
| 16 | 6 | Public, Tech |
| 24 | 2 | Platform |
| 40 | 2 | Workshop |

### 4.4 Observed vs our scale

- On the current 4/8/12/16/24/32/48 scale: gaps 4/8/12/16/24/32 are heavily used; 48 is rare (3 gaps); 64 never occurs as a gap.
- Off-grid but recurring across all four apps: **6** (96 gaps), **2** (25), and sub-pixel 0 (29).
- Off-grid and cross-app: **10** (Public/Tech/Workshop, 17), **14** (Platform/Tech/Workshop, 16), **20** (Tech/Workshop, 11; 370 padding sides).
- **20 px** is a real screen margin in the mobile exports (and DESIGN.md `margin: 1.25rem`), but it is not in `AppSpacingTokens`.
- **28 / 40 / 64 / 80 / 96 / 256** occur mainly as desktop page/section padding, not component internals.

---

## 5. Radii, shadows/effects and strokes

### 5.1 Radii

| px | Count | Apps | Typical observed role |
| ---: | ---: | --- | --- |
| 9999 | 1,056 | Platform, Public, Tech, Workshop | pills, buttons, chips, toggles, avatars, progress |
| 16 | 221 | Platform, Tech, Workshop | inputs, icon tiles, inner rows, small cards |
| 32 | 111 | Platform, Public, Tech, Workshop | mobile/public cards, platform cards, sheets |
| 48 | 64 | Platform, Public, Tech, Workshop | large desktop cards, document/preview panes, sheets |
| 24 | 36 | Tech, Workshop | Workshop metric/cards, some tech cards |
| 6 | 1 | Tech | tire tread number field (one-off) |

Non-uniform corners (3 nodes): `32/0/32/0` and `40/0/40/0` (Workshop drawer/tab shapes), `48/48/0/0` (Tech top-only sheet/card).

Per-app radius sets:

- Tech: 16 / 24 / 32 / 48 / 9999 (+ one 6).
- Workshop: 16 / 24 / 32 / 48 / 9999.
- Platform: 16 / 32 / 48 / 9999 (no 24 as `cornerRadius`).
- Public: 32 / 48 / 9999 (no 16/24 card radius in this export).

**Card radius differs by app:** Tech and Public use 32; Workshop uses 24; Platform uses 32 or 48. There is **no 28 px radius anywhere**, although DESIGN.md prose specifies `rounded-2xl` 24 and `rounded-3xl` 28.

### 5.2 Shadows / effects

There are **127 exact effect definitions** and **58 distinct geometries**. The exact definition includes RGBA; the "geometry" view groups identical offsets/blur regardless of opacity.

Top exact definitions (pooled occurrences):

| Type / offset / blur / spread / colour | Count | Apps |
| --- | ---: | --- |
| DROP_SHADOW x=0 y=2 blur=8 spread=0 rgba(0,0,0,0.016) | 231 | all 4 |
| DROP_SHADOW x=0 y=14 blur=40 spread=0 rgba(0,0,0,0.043) | 216 | all 4 |
| DROP_SHADOW x=0 y=10 blur=25 spread=0 rgba(16,185,129,0.3) | 52 | all 4 |
| DROP_SHADOW x=0 y=1 blur=2 spread=0 rgba(0,0,0,0.05) | 50 | Public, Tech, Workshop |
| BACKGROUND_BLUR NORMAL x=0 y=0 blur=48 spread=0 | 42 | all 4 |
| DROP_SHADOW x=0 y=2 blur=6 spread=0 rgba(0,0,0,0.02) | 35 | Platform, Tech |
| DROP_SHADOW x=0 y=2 blur=8 spread=0 rgba(0,0,0,0.03) | 28 | Platform, Tech |
| DROP_SHADOW x=0 y=2 blur=8 spread=0 rgba(0,0,0,0.02) | 24 | Platform, Tech |
| DROP_SHADOW x=0 y=1 blur=8 spread=0 rgba(0,0,0,0.03) | 23 | Platform, Tech |
| BACKGROUND_BLUR NORMAL x=0 y=0 blur=24 spread=0 | 20 | all 4 |
| DROP_SHADOW x=0 y=2 blur=8 spread=0 rgba(0,0,0,0.06) | 14 | all 4 |
| DROP_SHADOW x=0 y=8 blur=24 spread=0 rgba(16,185,129,0.28) | 13 | Platform, Tech, Workshop |
| DROP_SHADOW x=0 y=0 blur=8 spread=0 rgba(16,185,129,0.5) | 12 | Platform, Public |
| DROP_SHADOW x=0 y=2 blur=6 spread=0 rgba(0,0,0,0.15) | 12 | Platform, Tech, Workshop |
| DROP_SHADOW x=0 y=2 blur=8 spread=0 rgba(0,0,0,0.01) | 12 | Platform, Tech, Workshop |
| DROP_SHADOW x=0 y=14 blur=40 spread=0 rgba(0,0,0,0.035) | 11 | Platform, Tech |
| DROP_SHADOW x=0 y=2 blur=6 spread=0 rgba(0,0,0,0.2) | 11 | Platform |
| DROP_SHADOW x=0 y=4 blur=12 spread=0 rgba(0,108,73,0.2) | 10 | Platform |
| DROP_SHADOW x=0 y=4 blur=12 spread=0 rgba(0,0,0,0.03) | 8 | Platform, Tech |
| DROP_SHADOW x=0 y=4 blur=12 spread=0 rgba(16,185,129,0.25) | 8 | Public, Tech |

Top geometries (colour-independent):

| Type / offset / blur / spread | Count | Apps |
| --- | ---: | --- |
| DROP_SHADOW x=0 y=2 blur=8 spread=0 | 317 | all 4 |
| DROP_SHADOW x=0 y=14 blur=40 spread=0 | 232 | all 4 |
| DROP_SHADOW x=0 y=2 blur=6 spread=0 | 65 | Platform, Tech, Workshop |
| DROP_SHADOW x=0 y=10 blur=25 spread=0 | 58 | all 4 |
| DROP_SHADOW x=0 y=4 blur=12 spread=0 | 53 | all 4 |
| DROP_SHADOW x=0 y=1 blur=2 spread=0 | 50 | Public, Tech, Workshop |
| BACKGROUND_BLUR NORMAL x=0 y=0 blur=48 spread=0 | 42 | all 4 |
| DROP_SHADOW x=0 y=8 blur=24 spread=0 | 31 | all 4 |
| DROP_SHADOW x=0 y=1 blur=8 spread=0 | 23 | Platform, Tech |
| BACKGROUND_BLUR NORMAL x=0 y=0 blur=24 spread=0 | 20 | all 4 |
| DROP_SHADOW x=0 y=4 blur=16 spread=0 | 20 | Platform, Tech, Workshop |
| DROP_SHADOW x=0 y=0 blur=8 spread=0 | 15 | Platform, Public |
| DROP_SHADOW x=0 y=4 blur=14 spread=0 | 15 | all 4 |
| DROP_SHADOW x=0 y=18 blur=50 spread=0 | 9 | Platform, Tech |
| BACKGROUND_BLUR NORMAL x=0 y=0 blur=8 spread=0 | 6 | Public, Tech, Workshop |
| DROP_SHADOW x=0 y=20 blur=25 spread=-5 | 6 | Public, Tech |
| DROP_SHADOW x=0 y=8 blur=10 spread=-6 | 6 | Public, Tech |

**Agreement:** the two-layer card shadow is shared across all four apps:

- `0 2 8 rgba(0,0,0,0.016)`
- `0 14 40 rgba(0,0,0,0.043)`

The emerald CTA shadow `0 10 25 rgba(16,185,129,0.30)` is also shared across all four apps.

**Difference:** Workshop uses `0 16 40 rgba(0,0,0,0.035)` on its five major dashboard cards (per spec 02) instead of the two-layer pair; Platform has a large family of 6/8/12 px blurs at 1–20% opacity; Public uses inset/negative-spread shadows for segmented controls and photo elements.

**Reconciliation with DESIGN.md prose:** the prose specifies `0 14 40 rgba(0,0,0,0.045)` + `0 2 8 rgba(0,0,0,0.015)`; the export measures **0.043** and **0.016**. This is near-identical but not the same token. The prose CTA shadow `0 10 25 rgba(16,185,129,0.3)` matches exactly.

### 5.3 Strokes

UI cards are borderless in almost every screen; most strokes are vector artwork (vehicle wireframes, chassis guides, photo annotation).

Top stroke weights: 2 px INSIDE (12), 1.148 px CENTER (7), 1.467 px (6), 2.8 px (6), 0.88 px (4), 1.033 px (4), 1.4 px (4), 1.5 px (4), 1.867 px (4), 1.17 px (3), 1.435 px (3), 1.8 px (3), 2.333 px (3), 2.5 px (3), 3.2 px (3). There are 34 weight/align combinations; the sub-pixel values are scaled vector art, not UI hairlines.

Stroke colours by app:

- `#F59E0B` (18) — Tech vehicle wireframe.
- `#C7C5D3` (16) — Public/Tech chassis guide.
- `#10B981` (11) — Public/Tech/Workshop selected/verified.
- `#BBCABF` (9) — Tech exterior wireframe.
- `#3C4A4266` (7), `#E3E2E7` (6), `#D1D5DB` (5), `#E5E7EB` (4) — Public line art / guides.
- `#FFFFFF` (6), `#F4F3F8` (3) — Workshop contrast strokes.
- `#1A1B1F` (3), `#BA1A1A` (3), `#006C49` (2), `#EEEDF3` (1) — occasional UI/badge rings.

No evidence of a general border token; dividers are usually 1 px tonal rectangles (`#EEEDF3` / `#E3E2E7`), not stroked containers.

---

## 6. Icon / asset system

### 6.1 Semantic roles

| Role | Refs | Apps | Screens |
| --- | ---: | --- | ---: |
| icon | 862 | Platform, Public, Tech, Workshop | 45 |
| graphic | 55 | Platform, Public, Tech, Workshop | 23 |
| vector | 40 | Public, Tech, Workshop | 11 |
| image | 32 | Platform, Public, Tech, Workshop | 18 |
| decoration | 4 | Workshop | 2 |
| **Total** | **993** | | |

Per package totals: Tech 244 assets (220 individual SVG, 16 composed, 8 raster); Workshop 337 (292 SVG, 34 composed, 11 raster); Platform 286 (278 SVG, 4 composed, 4 raster); Public 126 (112 SVG, 5 composed, 9 raster).

### 6.2 Reuse

Measured by SHA-1 of exported files, not by asset reference (references are screen-local such as `svg-1_7094`).

- 616 unique asset files out of 993 references.
- 68 files are reused across ≥2 screens; 31 are reused across ≥2 apps.
- The most-reused icon appears in **36 screens across all 4 apps** (generic `Icon`; the export does not name the glyph). A second icon appears in 14 screens across 2 apps; many icons repeat 10–12 times within one app.
- Thousands of icon nodes are all named `Icon` (797 VECTOR + 8 FRAME), so semantic names must be recovered from screen context, not filenames.

### 6.3 Raster / photo / avatar usage

- 32 JPG images (role `image`): Tech 8, Workshop 11, Platform 4, Public 9.
- Dimensions from each asset manifest `pixelSize`: 512×279 (12 — the dominant hero/evidence crop), 294×160 (4), 235×128 (3), 112×112 (2), 206×112 (2), 399×218 (2), 470×256 (2), 64×64 (2 — profile avatars), 176×96, 70×125, 352×263.
- The 64×64 images are the only avatar-sized rasters; elsewhere "avatars" are circular icon tiles or initials, not photos.
- Several node names are long external image URLs/hashes (stock vehicle/tyre photos), so provenance/licensing is not evidenced in the export.
- Exported as JPG originals plus @2x PNG previews; the original raster is evidence, not a bundled app asset.

---

## 7. Shared component patterns and per-app differences

There are no real Figma components. The following are recurring node-name/structural patterns, with counts of matching nodes (all apps unless stated).

| Pattern | Nodes | Apps | Key geometry observed |
| --- | ---: | --- | --- |
| icon | 805 | all 4 | VECTOR icons mostly 12–24 px; many reused assets |
| button/cta | 336 | all 4 | Mobile/public CTA: 56 px high, pill (9999). Workshop primary: 56 px high, **16 radius** in several screens. Tech secondary controls: 16/32 radius. |
| modal/sheet/drawer/dialog | 123 | all 4 | Tech bottom sheet 48; Workshop right drawer 32/48; overlays + 24/48 blur |
| card | 96 | all 4 | Tech/Public 32; Workshop 24; Platform 32/48; white surface + two-layer shadow |
| header/appbar/topbar | 81 | all 4 | Tech 64 h `#FFFFFFCC`; Workshop 80 h `#FFFFFFE5`; Platform 64 h `#FFFFFFE5`; Public 64/80 h white/E5; 48 blur |
| input/field/select | 78 | Platform/Tech/Workshop | Borderless filled fields; 16 radius (login/workshop settings); some pill search controls; 44–56 h |
| segmented/tabs/toggle/switch | 46 | all 4 | Pill track 9999, 32 h, emerald active (#10B981), tonal inactive |
| table/grid/list/queue | 45 | all 4 | Desktop row cards 16/24; mobile stacked cards; no bordered tables |
| chip/badge/tag/pill | 40 | all 4 | Pill 9999; status fills use mint/warning/danger tints |
| nav/rail/sidebar | 34 | all 4 | Desktop icon rail (Workshop/Platform); mobile bottom pill nav (Tech); public header nav |
| bottom bar/footer | 30 | all 4 | Mobile fixed CTA dock, pill; desktop footer rows |
| avatar/photo/media | 20 | all 4 | 64×64 raster avatars; circular icon tiles; photo evidence cards |
| progress/stepper | 18 | Tech/Workshop | Rings/donuts; no fake percentage rule in Phase 1 conflicts with some copy |
| pin/marker | 15 | Public/Tech/Workshop | Damage pins over wireframes; emerald/red rings |
| divider/separator | 14 | all 4 | 1 px tonal rectangles |
| banner/alert/toast/skeleton | 13 | all 4 | Tinted cards (offline amber, etc.) |
| accordion/tree/timeline | 6 | Platform | Hierarchy tree / audit timeline |
| checkbox/radio/slider | 3 | Workshop | Small radio indicators |

Per-app component character:

- **Technician (mobile):** 32 px cards, pill CTAs (56 h), 16 px fields, 48 px bottom sheets, glass header 64 h, bottom pill nav, 24/32 icon tiles.
- **Workshop Admin (desktop):** 24 px cards, 16 px primary buttons (some pill secondary), 16 px inputs, icon rail, 80 px glass header, right drawer for staff creation, fixed 1280 composition.
- **Platform Admin (desktop):** 32/48 px cards, pill buttons, 16 px inputs, icon rail (10 screens), dense tree/timeline/table patterns, 64 px glass header.
- **Public Report (web):** 32/48 px cards, pill CTAs, no inputs, responsive-in-name-only (390 and 1280 frames, no intermediate breakpoints), photographic evidence grid, 64/80 px header.

---

## 8. Cross-app comparison matrix

### 8.1 Distinct-value totals per app

| Metric | Technician | Workshop Admin | Platform Admin | Public Report |
|---|---:|---:|---:|---:|
| Screens | 16 | 12 | 10 | 7 |
| Fill/text colours | 47 | 47 | 30 | 37 |
| Font style/weight combos | 7 | 9 | 7 | 8 |
| Font sizes | 9 | 12 | 8 | 10 |
| Radius values | 6 | 5 | 4 | 3 |
| Distinct `itemSpacing` values | 85 | 151 | 89 | 75 |
| Distinct padding values | 81 | 67 | 67 | 29 |
| Effect colours | 24 | 23 | 30 | 14 |

The raw `itemSpacing`/padding counts include computed layout values; the component-scale frequencies are in section 4.

### 8.2 Matrix

| Dimension | Technician (390) | Workshop Admin (1280) | Platform Admin (1280) | Public Report (390 + 1280) | Verdict |
|---|---|---|---|---|---|
| Shared surface | `#FFFFFF`, `#F4F3F8` | same | same | same | **Agree** |
| Dominant text | `#1A1B1F`, `#5E5D69`, `#3C4A42`, `#1B1B25` | same | same | same | **Agree** |
| Action fills | `#10B981`; deep green `#006C49` | same | same | same | **Agree** |
| Status/danger | `#B91A24`/`#BA1A1A`/`#F59E0B` | same | same | same | **Agree** |
| Header | 64 h, `#FFFFFFCC`, 48 blur | 80 h, `#FFFFFFE5`, 48 blur | 64 h, `#FFFFFFE5`, 48 blur | 64/80 h, white/E5, 48 blur | **Differ in height/alpha** |
| Type family | Plus Jakarta Sans + FreeSerif Arabic + Nimbus outlier | Plus Jakarta Sans + Liberation Mono + 1 Italic | Plus Jakarta Sans + Liberation Mono + FreeSerif | Plus Jakarta Sans + Liberation Mono + FreeSerif | **Agree on Plus Jakarta; differ on technical/Arabic** |
| Base sizes | 11/12/13/14/16/18/22/26/32 | 7/8/9/10/11/12/13/14/16/18/22/32 | 11/12/13/14/16/18/22/32 | 7.467/11/12/13/14/16/18/22/26/32 | **Core agree; long tails differ** |
| Card radius | 32 (some 24) | **24** | 32 / 48 | **32 / 48** | **Differ** |
| Input radius | 16 (login) | 16 / some pill | 16 / some pill | n/a | **Agree where present** |
| Button radius | Pill 9999 (CTA); 16/32 secondary | Pill secondary; **16 primary** | Pill 9999 | Pill 9999 | **Differ (desktop primary)** |
| Pill radius | 9999 | 9999 | 9999 | 9999 | **Agree** |
| Radii values used | 6/16/24/32/48/9999 | 16/24/32/48/9999 | 16/32/48/9999 | 32/48/9999 | **Differ** |
| Core shadow | 0/2/8 .016 + 0/14/40 .043 | same (dashboard uses 0/16/40 .035) | same + many variants | same | **Mostly agree** |
| CTA shadow | 0/10/25 emerald .30 | same | same | same | **Agree** |
| Glass blur | 48 | 48 | 48 | 48 | **Agree** |
| Spacing 4/8/12/16/24 | yes | yes | yes | yes | **Agree** |
| Spacing 6/2/10/14/20 | 6/2/10/14/20 | 6/2/10/14/20 | 6/2/14 | 6/2/10 | **Differ in mix** |
| Grid gap | 16 | 32/40 | 24/32 | 16/32 | **Differ** |
| Asset mix | 244 assets, 8 raster | 337 assets, 11 raster | 286 assets, 4 raster | 126 assets, 9 raster | **Differ in density** |
| Nav pattern | bottom pill | icon rail | icon rail | header only | **Differ** |
| Component nodes | none | none | none | none | **Agree (all frames)** |

---

## 9. Mapping to our current implementation

### 9.1 What already exists

From `client/packages/design_system/lib/src/tokens.dart`:

- Spacing: `4 / 8 / 12 / 16 / 24 / 32 / 48` (`AppSpacingTokens.standard`).
- Radii: `4 / 8 / 12 / 16 / pill 999` (`AppRadiiTokens.standard`).
- Status colours: neutral/info/success/warning/danger/critical, light + dark pairs.
- Material 3 `ColorScheme` with teal brand seed `#0B3B4A`, secondary `#0F6B6F`, surfaces `#F7FAFA`/white, error `#A3231F`, light and dark.
- Motion: 120/220/320 ms with enter/exit curves; reduced-motion helper.
- Breakpoints: phone 600 / tablet 900 / desktop 1200.
- Component themes: filled/tonal/text fields (borderless), filled/text/outlined buttons at `radii.lg` 12, cards at `radii.xl` 16, list tiles, nav rail/bar, tabs, snackbar.

From `docs/phase-1/10-design-system.md`: semantic token contract (teal brand, status/severity pairs, type scale, spacing 4–64, radii 4/8/12/pill, WCAG AA rule, no raw hex in feature code).

From `docs/phase-3.5/ui-decisions.md`: centralised `design_system` components; filled borderless inputs; theme-only colours/type; spacing/radii/motion extensions; breakpoints; light/dark first-class.

### 9.2 Token drift and extensions implied by the export

| Area | Current implementation | Figma evidence | Classification |
|---|---|---|---|
| Brand hue | Teal `#0B3B4A` / `#0F6B6F` | Emerald family `#10B981` / `#006C49` | **Conflict**, not just extension |
| Primary action | Teal primary | `#10B981` fill (332) + `#006C49` text/icon (231) | **Conflict** |
| Surface | `#F7FAFA` page, white cards | `#F4F3F8` tonal (585) + white (709); `#FAF9FE` absent | **Conflict / drift** |
| Text | `#17212B` / `#4D6670` | `#1A1B1F` (618) / `#5E5D69` (1,173) / `#3C4A42` (151) | **Drift** (values differ) |
| Status | Phase 1 pairs (`#1F6B45`/`#A3231F`/`#8A5A00`/`#1D5C8A`) | `#B91A24`, `#BA1A1A`, `#F59E0B`, mint tints; Phase 1 pairs mostly absent | **Conflict** |
| Spacing | 4/8/12/16/24/32/48 | Adds recurring **6, 10, 14, 20, 2**; 64/40/28/80/96 as layout padding | **Extensions + off-grid drift** |
| Radii | 4/8/12/16/pill | 16/24/32/48/pill; no 4/8/12 `cornerRadius` in the export (one 6) | **Conflict / extension** |
| Card radius | `radii.xl` 16 | Tech/Public 32; Workshop 24; Platform 32/48 | **Drift** |
| Button radius | `radii.lg` 12 | Pill 9999 for mobile/public; Workshop primary 16; Platform pill | **Drift** |
| Type family | No `fontFamily` set; no fonts bundled | Plus Jakarta Sans + FreeSerif Arabic + Liberation Mono | **Missing implementation** |
| Type scale | M3 defaults with a few weight/tracking overrides | 32/38, 26/32, 22/28, 18/24, 16/22, 14/20, 13/18, 12/16, 11/14 | **Drift** (not encoded) |
| Shadows | Material elevation 0; no card/CTA shadow tokens | Two-layer card shadow + emerald CTA shadow + glass blur | **Missing / extension** |
| Dark theme | Implemented light + dark | Export is light-only | **Unverified in design** |
| Breakpoints | 600/900/1200 | Only 390 and 1280 frames; no tablet | **Not evidenced** |
| Components | `AppButton`, `AppTextField`, `AppCard`, `StatusChip`, etc. | Patterns exist but no Figma components | **Naming-level mapping only** |

**No raw hex in feature code:** `tokens.dart` is the central owner of raw `Color(0x...)` values and feature code is expected to consume `context.colors`/`context.spacing`/`context.radii`. That locked rule is not violated by the current code structure. The problem is that the central values are the Phase 1 teal system, not the emerald system the Figma exports and DESIGN.md front matter describe.

### 9.3 The DESIGN.md front-matter vs prose conflict (explicit)

Do not average these away. They are two different systems in one file.

| Topic | YAML front matter | Prose body | What the Figma export actually uses |
|---|---|---|---|
| Primary | `#006c49` | `#10B981` | `#10B981` dominant fill; `#006C49` dominant deep-green text/icon |
| Surface | `#faf9fe` | Pure `#FFFFFF` (no off-white) | `#FFFFFF` + `#F4F3F8` tonal; **`#FAF9FE` never appears** |
| Secondary | `#5e5d69` | `#1A1A24` deep ink navy | `#5E5D69` dominant text (1,173); `#1A1B1F` (618); `#1B1B25` (134); **`#1A1A24` never appears** |
| Tertiary/danger | `#b91a24` | `#EF4444` red | `#B91A24` + `#BA1A1A`; **`#EF4444` never appears** |
| Neutrals | `#6c7a71` outline, `#3c4a42` | `#8E8E93` / `#6B7280` | `#6C7A71` (Tech only), `#3C4A42` (151), `#6B7280` (Public only 3) |
| Radius | 0.5/1/1.5/2/3 rem = **8/16/24/32/48**, full 9999 | Cards 24/28, inputs 16–20, controls pill | **16/24/32/48/9999**; no 28; 8 not observed as a card radius |
| Spacing | 4/8/16/24/32 + gutter 16 + margin 20 | 20 outer margin, 16 gutter, 24 internal, 24–32 sections | 4/8/12/16/20/24/32 dominant; plus 6/10/14/2 |
| Typography | Plus Jakarta Sans, exact 32/38, 26/32, 22/28, 18/24, 16/22, 16/24, 14/20, 13/18, 14/18, 12/16, 11/14 + tracking | Plus Jakarta Sans; weights 400–800; usage rules | Matches the front matter combos almost exactly |
| Shadows | none defined | `0 14 40 rgba(0,0,0,.045)` + `0 2 8 rgba(0,0,0,.015)`; CTA `0 10 25 rgba(16,185,129,.3)` | `0 14 40 rgba(0,0,0,.043)` + `0 2 8 rgba(0,0,0,.016)`; CTA `.3` exact |
| Dark mode | not defined | "dark mode states are eliminated" | Light-only export |

**Evidence interpretation:** the front matter closely tracks the Figma type system (every size/weight/line-height combo matches except the 32/38 tracking split) and the observed 16–48 radius range, while the prose carries an older/different emerald-on-white narrative. The export supports the emerald action colour and the front-matter type scale, but contradicts both documents on the base surface (`#F4F3F8` vs `#FAF9FE`/white) and shadow alpha (`.043`/`.016` vs `.045`/`.015`).

### 9.4 Conflicts with the Phase 1 token contract

1. **Brand colour:** Phase 1 is teal (`#0B3B4A` / `#0F6B6F`); neither teal value appears in any of the 45 screens. The export and DESIGN front matter are emerald/deep-green.
2. **Status colours:** Phase 1 pairs (`#1D5C8A`, `#1F6B45`, `#8A5A00`, `#A3231F`, `#7F1D1D` and their backgrounds) do not appear. Observed danger/warning are `#B91A24`/`#BA1A1A`/`#F59E0B` with mint/red tints.
3. **Type scale:** Phase 1 proposes 28/34, 24/30, 20/26, 16/22, 15/22, 13/18, 12/16. The export uses 32/38, 26/32, 22/28, 18/24, 16/22, 14/20, 13/18, 12/16, 11/14; **15/22 is absent**.
4. **Radii:** Phase 1 is 4/8/12/pill; the export is 16/24/32/48/pill for cards, sheets, inputs and containers. The implemented `AppRadiiTokens` (4/8/12/16/999) matches Phase 1, not Figma.
5. **Spacing:** Phase 1 allows 4–64; the export uses 64/80/96/256 as layout padding and 6/10/14/20/2 as recurring component gaps. The implemented token set has no 6/10/14/20/64.
6. **Fonts:** Phase 1 says families are pending licence verification and must not be bundled. The export assumes Plus Jakarta Sans, a mono face and an Arabic serif fallback; none are bundled in either app (`pubspec.yaml` has no `fonts:` section; `design_system/pubspec.yaml` has none either).
7. **WCAG AA:** Phase 1 requires 4.5:1 normal text / 3:1 UI. Measured from the exported hex values: white on `#10B981` = **2.54:1** (fails), `#10B981` text on white = 2.54:1 (fails), `#F59E0B` on white = **2.15:1** (fails), while `#006C49` on white = 6.48:1 and `#5E5D69` on white = 6.47:1. The emerald CTA pattern conflicts with the Phase 1 contrast rule unless text/foreground changes.
8. **Dark theme:** `tokens.dart` implements dark as a first-class variant; Phase 1 says do not ship until tested; DESIGN prose says dark states are eliminated; the Figma export has no dark screens.

### 9.5 Decision inputs (not a decision)

The evidence supports at least these mutually exclusive directions; F0 does not choose one:

- **A. Adopt the Figma/emerald system** (DESIGN front matter + observed values): new emerald/ink/surface tokens, type scale, radius scale 16/24/32/48, Plus Jakarta + Arabic + mono bundling; Phase 1 teal contract would be superseded.
- **B. Keep the Phase 1 teal contract** and recolour Figma: the export's structure/geometry can still inform spacing/radii/type, but all brand/status colours must be remapped and the emerald CTA/shadow removed.
- **C. Keep token names but remap values** (semantic contract preserved, brand values changed): requires resolving the DESIGN.md front-matter/prose conflict first; the export is not internally consistent enough to supply a single value for "primary surface" or "primary action".

---

## 10. What could not be verified

- **Figma variables/styles are absent.** `variables` and `variableCollections` are empty in all 45 files; `fillStyleId`, `textStyleId`, `strokeStyleId` and `effectStyleId` are all blank. There are no token names, modes, or published style definitions to compare.
- **No component system.** No `COMPONENT`, `COMPONENT_SET` or `INSTANCE` nodes; no variants, properties, or component states. Every "button/card/input" is a frame, so component reuse cannot be measured structurally.
- **No dark theme, RTL layout, tablet or intermediate breakpoints.** Only light 390 px and 1280 px frames exist. Arabic appears only as isolated labels (FreeSerif), never as an RTL layout; no Arabic line-height or mirroring evidence.
- **No interaction states.** Hover/focus/pressed/disabled/loading/error visuals are mostly absent; the specs report empty prototype `reactions`.
- **No font files or licences.** Plus Jakarta Sans, Liberation Mono, FreeSerif and Nimbus Sans are referenced by name only. Neither app bundles fonts; the design cannot prove availability, licensing, or Arabic coverage.
- **Alpha/blur composition.** Colours behind translucent fills, glass headers (`#FFFFFFE5`/`#FFFFFFCC`) and background blurs (24/48 px) are composited in Figma; the export gives the layer values, not the final rendered colour against every background.
- **Raster provenance.** 32 JPGs have pixel dimensions from `manifest.pixelSize`, but no source/licence/attribution. Many node names are external image URLs/hashes.
- **Icon semantics.** 805 nodes are named `Icon`; SHA-1 proves reuse but not glyph identity. Semantic icon names must come from screen context/specs, not filenames.
- **Full typography edge cases.** 44 text nodes have no resolved line-height (`AUTO`/unknown); 96 type combinations include screen-specific micro-copy and anomalies (7/7.467/8/9/10 px, Nimbus Sans, italic).
- **Contrast.** Only the key pairs above were calculated; a full WCAG audit of every foreground/background combination was not performed.
- **Visual diff.** The 45 `@2x.png` previews were not pixel-diffed against the JSON; the per-screen specs provide the visual reading. The aggregator is measurement-only.
- **Copy/product claims.** Text content contains unsupported claims ("ISO 27001", "100% accuracy", "Verified") and was not treated as token evidence.
