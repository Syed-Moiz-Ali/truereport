# 12. 13. Final Review (Missing Items)

- App: Technician
- Figma node: `1:8349`
- Frame: 390 x 1008 px (phone; mobile portrait)
- Export folder: `screens/12_13._Final_Review_(Missing_Items)`
- Sources read: `13._Final_Review_(Missing_Items).json` (developerSummary, assetIndex, full node tree), `13._Final_Review_(Missing_Items)@2x.png`, `assets/manifest.json`
- Confidence: high for layout/typography; medium for the blocking semantics (what counts as "mandatory" is not defined in the file); low for RTL and for post-resolution states (only the blocked state is exported)

> **Ordering note:** this folder is manifest index **12** but the Figma screen is named **"13. Final Review (Missing Items)"**. The file name above uses the manifest index as the NN prefix, per instruction. Export order and Figma screen numbers diverge for screens 12–15.

## 1. Purpose

A pre-finalization validation gate. It tells the technician that three items block submission (photos and a signature), explains why, lists each blocking item with a direct-fix row, shows coverage metadata, and disables the "Resolve to Continue" CTA until the items are fixed.

## 2. Layout structure

Root `1:8349`: 390x1008, VERTICAL, fill `#FFFFFF`, FIXED/HUG.

1. `1:8350` "Main" — 390x1008, VERTICAL, padding `64/0/0/0`.
   - `1:8351` content container — 390x944, VERTICAL, padding `0/20/40/20`.
     - `1:8352` status/overview — 350x138, VERTICAL, gap 4, padding `8/0/24/0`.
       - row 350x22: `STEP 4 OF 4 • VALIDATION` 12/16 SemiBold + red chip `3 Action Items` (113.39x22, `#FFDAD6`, dot `#B91A24`).
       - heading 350x36: `Review Findings` 26/32 ExtraBold.
       - body 350x40: "Resolve outstanding compliance requirements before submitting the digital work order." 14/20 Medium.
     - `1:8363` attention banner margin — 350x184, bottom padding 24.
       - `1:8364` banner 350x160, HORIZONTAL, gap 16, padding 20, **radius 32**, fill `#FFDAD7@0.3`, shadow.
         - 44x44 white icon circle with 22x19 `#B91A24` alert.
         - text column 250x120: `3 Mandatory Photos Missing` 16/22 Bold; body 13/18 `#62616D`; numbered badges 24x24; `Tap any item below to capture instantly` 11/14.
     - `1:8386` missing items — 350x354, bottom padding 32; stack 350x322, gap 14; label `MANDATORY RESOLUTION ITEMS`; three 350x88 rows (**radius 32**, padding 20, shadow).
     - `1:8447` metadata card — 350x116, bottom padding 32; card 350x84, **radius 32**, fill `#F4F3F8@0.6`, padding 16.
     - `1:8460` bottom action — 350x112, gap 12: disabled 350x56 CTA + 350x36 helper.
2. `1:8468` Header — 390x64, `#FFFFFF@0.8` + blur + shadow; back 44x44, title `Diagnostic Checklist` 18/24, 32x32 emerald avatar.

The blocked CTA sits in normal flow (not a fixed dock), so the whole page scrolls. No tablet layout.

## 3. Visual tokens observed

### Colours

| Hex | Usage | ~Count |
|---|---|---|
| `#1A1B1F` | primary text/icons | 11 |
| `#5E5D69` | secondary text | 11 |
| `#FFDAD6` | action count chip, icon circles, "Required" chip | 8 |
| `#FFFFFF` | card surfaces, icon circle | 8 |
| `#B91A24` | danger icons/text | 6 |
| `#C7C5D3` | disabled text/chevrons | 5 |
| `#79000E` | on-error text | 4 |
| `#F4F3F8` | icon backgrounds, metadata card | 3 |
| `#006C49` | coverage icon | 2 |
| `#10B981` | coverage icon text | 1 |
| `#62616D` | banner body copy | 1 |
| `#F4F3F899` (60%) | metadata card | 1 |
| `#FFDAD74D` (30%) | banner fill | 1 |

### Typography

- Family **Plus Jakarta Sans** (plus **Nimbus Sans Bold 11** for the 1/2/3 badge numerals — an outlier).
- 26 / 32 / ExtraBold 800 / -0.65 — page title.
- 16 / 22 / Bold 700 — banner title and row titles.
- 14 / 20 / Medium 500 — intro body; 14 / 18 / Bold — disabled CTA.
- 13 / 18 / Regular — row detail, metadata detail, helper.
- 12 / 16 / SemiBold (+0.6) — step kicker, section label.
- 11 / 14 / SemiBold (+0.44) — chips, counts, "Tap any item…".

### Radii, shadows, strokes, spacing

- Radii: `9999` x19, `32` x5. Banner, cards, rows all 32.
- Shadows: banner, all three missing-item rows, icon/CTA circles.
- Strokes: none.
- Spacing: 20 dominant (18), then 8, 16, 2, 4, 12, 10, 24, 32, 40, 64. 20/32 not in `AppSpacingTokens`.

## 4. Components

Figma patterns:
- Step kicker + destructive count pill.
- 32px-radius attention banner with white icon medallion, numbered badges, and a helper line.
- "Mandatory resolution" list rows with leading 48px icon, title + category chip, detail line, trailing red action medallion + chevron.
- Coverage/metadata summary card with tinted icon and right-aligned percentage.
- Disabled full-width CTA with lock icon and explanatory body.

Mapping:
- `SectionHeader` — page/step headings.
- `StatusChip` — `3 Action Items`, `Required`, `Chassis`, `Front Left`.
- `SeverityBadge` — no direct equivalent (danger medallions are custom).
- `AppListTile` + `Card`/`AppCard` — missing-item rows.
- `AppButton` disabled state — "Resolve to Continue".
- `EmptyState`/`ErrorState` — no equivalent shown.
- Numbered badge stack — no equivalent.
- "91% Complete" progress text — `LinearProgressIndicator` exists but not this layout.

## 5. Assets

17 assets: 14 individual SVGs, 3 composed SVGs, no raster.
- Icons: alert (22x19), brake-fluid (18x18), tread (22x19), signature (19x18), camera action (18.3x16.7 / 16.7x15 / 16.7), chevron (6.2x10), coverage/check (16.5x15.8), lock (13.3x17.5), back (11.8x20), avatar (12x12).
- Composed: three 50.17x36 `Container` groups (red camera/alert medallion + chevron) — pure vector composites.
- **No photo/avatar/vehicle raster.**

## 6. Content and data

| Visible text/label | Sample text or field | Real data field? | Notes |
|---|---|---|---|
| Step | `STEP 4 OF 4 • VALIDATION` | No | No step model in technician app |
| Action count | `3 Action Items` | Partly: `ReviewResult.blocking.length` | Must be computed |
| Title | `Review Findings` | No | Current page title is "Review and finalize" |
| Intro | `...compliance requirements...digital work order` | No | **Compliance claim**; product says inspection, not compliance certification |
| Banner | `3 Mandatory Photos Missing` | Partly: `EVIDENCE_PENDING_5B` warnings exist | Current server warning is non-blocking in 5A (ADR 0017 §9) |
| Banner body | `Customer sign-off & quality assurance mandate verified optical documentation...` | No | **Invented policy/compliance wording** |
| Counts | `1 2 3` | Derived | Badge numerals |
| Section | `MANDATORY RESOLUTION ITEMS` | No | No such section in `review_page.dart` |
| Row 1 | `Brake Fluid`, `Chassis`, `Reservoir moisture gauge & test strip` | Partly: label/category exist; detail no | Detail is invented |
| Row 2 | `Tread Photo`, `Front Left`, `3/32" depth indicator macro verification` | No | **Invented tread measurement/unit**; no tire model |
| Row 3 | `Signature`, `Required`, `Digital advisor & vehicle owner sign-off` | No | No signature/consent gate in review; customer signature is a separate screen |
| Metadata | `28 Verified Data Points`, `Powertrain, OBD-II & exterior scans passed`, `91% Complete` | No | **Invented count, OBD scan claim, and percentage** |
| Disabled CTA | `Resolve to Continue` | No | No such CTA; current uses "Mark ready"/"Approve and generate report" |
| Helper | `All 3 critical checklist items must be resolved to unlock client sign-off.` | No | "critical"/"sign-off" wording |

## 7. States shown / not shown

Shown: blocked state with 3 items and a disabled CTA.
Not shown: loading, ready-to-finalize, zero missing items, all fixed, save/validation failure, offline/local-only pending count, conflict, >3 items, RTL, 200% text, very long item names.

## 8. Implied interactions

- Back → checklist.
- Tap a missing-item row → jump straight to the relevant capture (camera/tread/signature).
- Tapping the numbered badges may scroll/focus the corresponding row.
- The CTA is disabled until all 3 are resolved; no enabled visual is provided.
- Metadata is read-only.

## 9. Correspondence to current product

- Matches `client/apps/technician_app/lib/src/pages/review_page.dart`, route `/jobs/:id/review`, endpoint `technicianReview` plus `technicianReady`. Current UI already shows `completed/total`, `savedOnPhone` chip, `review.warnings` and `review.blocking` rows that deep-link to `/jobs/:id/items/:itemId`, and a disabled finalize until `review.ready && pending == 0`.
- Current warning `EVIDENCE_PENDING_5B` is non-blocking (ADR 0017 §9); this Figma screen makes mandatory photos blocking. That is a **product/validation change**, not UI-only.
- **New data/server needed** for: signature capture/gate, tire/photo-angle requirements, "28 verified data points"/OBD scan metadata, and a coverage percentage.
- The "jump directly to camera" behaviour for photos exists only as item assessment; there is no per-photo "capture this angle" requirement model.

## 10. Locked-rule conflicts / unsafe-to-ship content

1. **Compliance/certification claims.** Rule: never claim "certified", "official", "RTA approved", "manager approved" or "independent review"; no compliance claims in the public report. Evidence: "Resolve outstanding compliance requirements", "quality assurance mandate", "client sign-off", "Verified Data Points ... scans passed", "Defects Found" summary. Must be removed or grounded in approved master text.
2. **Invented counts/measurements.** `28 Verified Data Points`, `91% Complete`, `3/32"` depth, `3 of 6` are fabricated sample values. The rule forbids inventing measurements/results.
3. **Single unexplained condition score.** `91% Complete` is ambiguous: completion coverage vs condition. If it is coverage, label it explicitly; if it is a condition score, it is forbidden.
4. **Blocking evidence rule changes the finalization gate.** Figma makes photos/signature mandatory; ADR 0017 keeps evidence non-blocking in 5A and the offline design makes evidence a blocking gate only in 5B. This is a server/validation decision, not just UI.
5. **Customer sign-off wording.** The product has no customer app/portal and no customer signature capture in the finalize flow; a "vehicle owner sign-off" would invent a workflow and a role.
6. **Token drift.** 32px radii, 20px spacing, `#FFDAD7@0.3`, `#79000E`, `#B91A24` are not in `tokens.dart` (current danger/critical tokens are `#A3231F`/`#7F1D1D`).
7. **Font outlier.** Badge numerals use Nimbus Sans Bold; the rest is Plus Jakarta Sans. Must normalize.

## 11. Open questions / could not verify

- Which three items are actually mandatory? Is the list driven by blocking `review.blocking` or by a new photo-angle/signature rule?
- Where would a signature be captured? Screen 05 ("Consent & Signatures") exists but is not linked from review in code.
- Is the metadata card intended as coverage, condition, or device telemetry? OBD-II implies an integration that does not exist.
- Does "Resolve to Continue" become a normal button, or does it auto-advance once the list is empty?
- Should each row deep-link to an item assessment (current behaviour) or open a dedicated capture sheet?
- RTL, Arabic, 200% text, disabled contrast (`#C7C5D3` on white ≈ 1.8:1) and focus order could not be verified. The disabled CTA fails AA as rendered.
