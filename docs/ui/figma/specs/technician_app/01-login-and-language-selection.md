# 01. Login & Language Selection

- App: Technician
- Figma node: 1:7073
- Frame: 390x858 px (mobile phone; 390 pt logical width)
- Export folder: `screens/01_1._Login_&_Language_Selection`
- Sources read: `1._Login_&_Language_Selection.json`, `1._Login_&_Language_Selection@2x.png`, `assets/manifest.json`, `assets/ASSET_CATALOG.html`
- Confidence: high — full node tree, PNG, and asset manifest agree; only prototype/state data is absent.

## 1. Purpose

Single pre-auth screen combining sign-in with an English/Arabic language switch. The product inventory treats sign-in (T01) and launch language selection (T02) as separate screens; this Figma frame merges them. Observed text: `Email`, `Password`, `Forgot password?`, `Sign In`, `Need technician access?`, `Request ID`, `ISO 27001 Certified Fleet Security`.

## 2. Layout structure

- Root `1:7073`: Auto Layout VERTICAL, FIXED width / HUG height, padding `20/0/20/202`, gap `0`, background `#FFFFFF`. The 202 px bottom pad is a fixed spacer, not a safe-area inset.
- `1:7074` `Container` 350x656: VERTICAL, `SPACE_BETWEEN`, FILL width / HUG height.
  - `1:7075` header 350x64: HORIZONTAL, padding `0/8/0/24`, `MAX` alignment. Language pill `1:7076` 128.4x32 at the right, radius 9999, fill `#F4F3F8`, 4 px inner padding; active `Button` 70.8x24 (white, pill), inactive 49.6x24.
  - `1:7081` hero 350x222, layoutMode NONE, FIXED height: 80x80 logo slot (`1:7090` "TechInspect Minimal Logo") with a blurred green circle behind it (`1:7089`, 80x80, `#6FFBBE4D`, LAYER_BLUR 48); title 26/32 ExtraBold; subtitle 13/18.
  - `1:7091` form block 350x242: VERTICAL, padding `4/0/4/0`; email row 342x48 radius 16, gap 16 via a 64 px margin wrapper, password row 342x48; forgot-password row 342x34; 40 px top margin before CTA.
  - CTA `1:7113` 342x56, pill, `#10B981`, white 14/18 Bold text plus arrow icon; emerald drop shadow.
  - Footer `1:7119` 350x128: VERTICAL, `CENTER`, padding `0/64/0/16`; "Need technician access? Request ID" row 226.5x18; ISO line 208.1x14 at 16 px below.
- Fixed 390 px width; no min/max width or breakpoint variants. No scroll container node; content fits only because of the 202 px bottom pad, so 200% text scaling or a short viewport has no defined overflow path.
- Section order: language switch → logo/brand → email → password → forgot password → primary CTA → access request → security claim.

## 3. Visual tokens observed

### Colours (exact hex, usage, approximate count)

Counts are from `developerSummary.designSystemObserved` (fill occurrences, not unique nodes).

| Hex | Usage | Approx. count |
|---|---|---|
| `#1A1B1F` | brand wordmark, active language label | 2 |
| `#5E5D69` | subtitle, inactive language, "Forgot password?", access line | 4 |
| `#6C7A71` | field placeholders/icons, footer shield line | 7 |
| `#FFFFFF` | screen/card/field surfaces, CTA label | 6 |
| `#006C49` | "Request ID" link | 1 |
| `#10B981` | primary CTA fill | 1 |
| `#6FFBBE4D` | translucent green blur circle behind logo | 1 |
| `#F4F3F8` | language-pill housing | 1 |
| `#FFFFFF01` | invisible shadow rectangle | 1 |

Contrast measured from these hexes: white on `#10B981` = 2.54:1 (CTA label fails AA 4.5:1); `#10B981` text on white = 2.54:1; `#6C7A71` on white = 4.51:1 (borderline pass); `#5E5D69` on white = 6.47:1. The design uses no visible field borders; the 48 px field relies on a very light shadow only.

### Typography (family, weight, size, line-height, letter-spacing, alignment, usage)

| Text / node | Family / weight | Size / line-height | Tracking | Alignment | Usage |
|---|---|---|---|---|---|
| `TechInspect` 1:7083 | Plus Jakarta Sans / 800 | 26 / 32 | -0.65 px | centre | Brand |
| Subtitle 1:7086 | Plus Jakarta Sans / 400 | 13 / 18 | +0.325 px | centre | Tagline |
| `English` 1:7078 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | centre | Selected language |
| `عربي` 1:7080 | **FreeSerif / 600** | 12 / 16 | **+0.24 px** | centre | Inactive language |
| `Email` / `Password` 1:7097 / 1:7104 | Plus Jakarta Sans / 500 | 14 / AUTO | -0.07 px | left | Placeholder |
| `Forgot password?` 1:7111 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | centre | Secondary action |
| `Sign In` 1:7116 | Plus Jakarta Sans / 700 | 14 / 18 | -0.14 px | centre | CTA |
| `Need technician access?` 1:7122 | Plus Jakarta Sans / 400 | 13 / 18 | 0 | left | Helper |
| `Request ID` 1:7124 | Plus Jakarta Sans / 600 | 12 / 16 | +0.24 px | centre | Link |
| ISO line 1:7130 | Plus Jakarta Sans / 600 | 11 / 14 | +0.44 px | left | Claim |

The Arabic label uses `FreeSerif` (a serif fallback) rather than the brand family, with positive letter-spacing. This is visibly inconsistent with the Latin labels and conflicts with the RTL rule "do not letter-space Arabic".

### Radii, shadows/elevation, strokes, spacing values

- Radii: 9999 px (language housing, language buttons, CTA) ×6; 16 px (two text fields) ×2.
- Shadows: `DROP_SHADOW r=2 off=0,1` at 5% (language housing, fields); CTA shadow `r=4/6` at 10%; logo `LAYER_BLUR 48`.
- No strokes on fields; inputs are borderless and white on white.
- Spacing candidates observed: 4 (×16), 8 (×3), 12 (×2), 16 (×9), 20 (×2), 24, 40, 64, plus a 202 px bottom pad.
- The 48 px fields meet the 44 px target; the language buttons are only 24 px high (housing 32 px) and the eye toggle is 24.5x19.2, below the preferred 44–48 px target.

## 4. Components

| Figma pattern / node | Instances | Map to our design system |
|---|---|---|
| Language segmented control 1:7076 / 1:7077 / 1:7079 | 1 control, 2 segments | `AppSelectableText` is the nearest; Figma uses a white raised pill inside a tonal housing, while current `AppSelectableText` uses a tonal selected fill and 8 px radius |
| Text field 1:7092, 1:7099 | 2 | `AppTextField` (filled, borderless) — close, but Figma is pure white with a 16 px radius; theme uses tonal fill and `radii.lg` 12 |
| Primary CTA 1:7113 | 1 | `AppButton(primary, expand)` — current theme radius is 12, not pill |
| Text links 1:7110, 1:7123 | 2 | `AppButton(text)` / `TextButton` |
| Logo + blur 1:7089/1:7090 | 1 | no equivalent; logo asset not present in export |
| "ISO …" shield line 1:7125 | 1 | no equivalent; must not be promoted to a reusable trust badge without approval |

There are no Figma component instances or variants in this screen; nested frames are unnamed `Container`/`Button`/`Text`. Reuse would require semantic components rather than copying the frame tree.

## 5. Assets

- Manifest count: **5** (5 individual SVGs, 0 composed, 0 raster).
- Icons: mail/envelope 1:7094 (16.7x13.3), lock 1:7101 (13.3x17.5), eye 1:7107 (16.5x11.2), arrow 1:7118 (10.7x10.7), shield 1:7128 (8x10).
- No photo, avatar, or vehicle image.
- The logo is **not** an asset: frame 1:7090 is 64x64 with no serialized children and no assetIndex entry. The PNG shows only the green glow, no reproducible logo.
- Asset names are generic (`Icon-1_7094.svg`); licence/provenance is not evidenced in the export.

## 6. Content and data

| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| `English` / `عربي` | English selected | Yes, locale state | Arabic is the only non-Latin string in all eight screens |
| `TechInspect` | fixed brand | No | Product brand is **TrueReport** (`l10n.appTitle`) |
| `Vehicle Condition & Fleet Diagnostics` | fixed tagline | No | Implies condition/fleet product areas not in the technician scope |
| `Email`, `Password` | empty fields | Yes | Auth payload is email/password (`authLogin`) |
| `Forgot password?` | link | No current endpoint | `ApiEndpoints` has no password-reset route |
| `Sign In` | action | Yes | `authLogin` |
| `Need technician access?` / `Request ID` | link | No current flow/endpoint | Account creation is admin-driven in the PRD; no request-ID API exists |
| `ISO 27001 Certified Fleet Security` | claim | No | Certification claim; no evidence/version/source in export |

No VIN, plate, customer name, phone, email value, measurement, or score appears on this screen. The only personal data field is the email input (empty).

## 7. States shown / not shown

Shown: default English-selected state, empty fields, enabled CTA.

Not shown: Arabic-selected/RTL layout; field focus/error/validation; password-visible state; loading/disabled CTA; invalid credentials, network, locked/disabled account, rate-limited and 2FA challenge states (the current code supports a 2FA code field); forgot-password flow; request-ID flow; offline explanation; session-expired message.

## 8. Implied interactions

- Tap `English` / `عربي` to switch locale immediately.
- Focus email/password; eye toggles password visibility (no pressed state shown).
- `Forgot password?`, `Sign In`, `Request ID` are tappable.
- No prototype reactions exist in the JSON (`reactions` empty on all nodes); all interactions are inferred from button styling/labels.

## 9. Correspondence to current product

- Matches T01 Sign in (`/signin`) and T02 Language selection (`/language`) in `docs/phase-1/02-screen-inventory.md`.
- Current code: `client/packages/auth/lib/src/sign_in_page.dart`; route `/signin` is registered in `client/apps/technician_app/lib/src/technician_router.dart:31`; API `ApiEndpoints.authLogin` (`/api/v1/auth/login`); locale via `localeProvider`.
- Current screen already has email, password, language toggles and a conditional 2FA code field; it does **not** have the logo, tagline, forgot-password, request-ID, ISO badge, or a separate language route.
- Gaps that cannot be delivered UI-only: forgot password, request ID/access request, ISO/security claim approval, and any new auth state.

## 10. Locked-rule conflicts / unsafe-to-ship content

- **"no certification/'verified by'/compliance claims"** and **"Never invent versions/licences"**: `ISO 27001 Certified Fleet Security` (1:7130) is a compliance/certification claim with no evidence in the export. Remove or replace with an approved, factual statement.
- **"Arabic RTL must work"** and "do not letter-space Arabic": only an English LTR frame exists; the Arabic label is in `FreeSerif` with +0.24 px tracking and the layout is not mirrored. This is not an RTL implementation.
- **"UI layer only; no business logic/API/model/validation/permission/state/server change"**: `Forgot password?` and `Request ID` imply new server flows that do not exist in `ApiEndpoints`; they cannot be shipped as visual-only controls.
- **WCAG 2.2 AA**: white `Sign In` label on `#10B981` measures 2.54:1; language buttons are 24 px high and the eye toggle 24.5x19.2, below the 44 px minimum.
- **Brand mismatch (not a locked rule, but a release blocker)**: `TechInspect` / "Fleet Diagnostics" are not the product name or scope; the app title string is `TrueReport`.
- **"Never invent versions/licences"**: the ISO claim is the specific instance; no licence/version metadata ships with the asset.

## 11. Open questions / could not verify

- Is `TechInspect` an intentional white-label name or placeholder? Which brand string is authoritative?
- Is `Request ID` a real access-request workflow, or a mislabeled link? No route/endpoint exists.
- Is self-service password reset in scope? No endpoint exists.
- Which Arabic font is licensed/bundled for the app? The export only proves a `FreeSerif` fallback.
- Should 2FA be shown on this screen for technicians? Current code supports it, the frame does not.
- Is the 202 px bottom pad a safe-area mock or a design error? It does not adapt to keyboard/text scale.
- Exact screen-reader labels/focus order cannot be verified from a static frame.
