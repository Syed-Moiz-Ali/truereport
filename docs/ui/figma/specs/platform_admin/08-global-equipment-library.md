# 08. 8. Global Equipment Library

- App: Platform Admin
- Figma node: `1:5086`
- Frame: 1280x1180 px (desktop web)
- Export folder: `screens/08_8._Global_Equipment_Library`
- Sources read: `8._Global_Equipment_Library.json`, `8._Global_Equipment_Library@2x.png`, `assets/manifest.json`, `package-manifest.json`
- Confidence: high — six cards, hardware labels, toggles, and geometry are explicit.

## 1. Purpose
Network-wide hardware/equipment catalogue: authorized diagnostic devices, calibration status/toggles, a register-device entry point, and an automatic telemetry-sync banner.

## 2. Layout structure
Root `1:5086` vertical, 1280x1180, `paddingLeft: 256`, fill `#FFFFFF`.
- `Main` `1:5087` 1024x1180, padding 64/32/32/32.
- `Container` `1:5088` 960x1084, gap 32:
  - Header `1:5089` 960x188: title 299x172; filters + CTA 511x56 (segmented 280x36, Register Equipment 215x56).
  - Grid `1:5112` 960x640: `Container` 960x624 with six 304x300 cards (radius 32, padding 24) in a 3x2 layout (the sixth is an “Integrate New Spec” dashed/tinted card).
  - Footer `1:5253` 960x96, radius 32, padding 24: telemetry-sync copy + “5/5 Authorized Active” + “Diagnostic Logs”.
- `Header` `1:5270` 1024x64 glass; `Aside` `1:5295` 256x1156.

Cards are fixed 304x300 (3 columns); gap is implied by the 960/304 arrangement (~24). No responsive variant.

## 3. Visual tokens observed
### Colours
| Hex | Count | Usage |
|---|---|---|
| `#5E5D69` | 37 | Specs, labels, meta |
| `#FFFFFF` | 21 | Cards |
| `#1B1B25` | 16 | Device names/headings |
| `#10B981` | 14 | Active chips, toggles, status dots |
| `#F4F3F8` | 12 | Segmented track, integrate card |
| `#006C49` | 7 | Active text |
| `#10B9811A` | 5 | Info/telemetry icon tints |
| `#3C4A42` | 5 | Nav |
| `#1A1B1F` | 3 | Chrome |
| `#10B98126` | 1 | Footer icon tint |
| `#F4F3F899` | 1 | Integrate card wash |
| `#FFFFFFE5` | 1 | Header glass |

### Typography
`Plus Jakarta Sans`. H1 32/800 LH38 -0.80; device names 18/700 LH24 -0.45; specs 14/500 LH20; status chips 11/600; card footer labels 11/600; footer title 16/700; body 13/400; toggles unlabeled.

### Radii, shadows, strokes, spacing
- Radii: equipment cards 32; integrate card 32; footer 32; segmented/buttons/toggles 9999; icon tiles 16/rounded.
- Shadows: cards `0 2 8 .02` + `0 14 40 .04`; footer `0 4 14 .03`; toggles `0 2 6 .20`; no borders.
- Strokes: none.
- Spacing: card padding 24; grid gaps ~24; page 64/32; header/footer gaps 32.

## 4. Components
Flattened export. Patterns: page header with 3-way segmented filter + primary CTA, 3x2 feature-card grid, status chip, spec line, bottom toggle row, “integrate” empty-card CTA, telemetry sync banner with count + secondary action.
Mapping: `Card`, `StatusChip`, `Switch`, `AppButton`, `SectionHeader`; no equipment-card, segmented filter, or “integrate” card component. No table despite the fleet/registry nature.

## 5. Assets
25 assets, all individual SVG icons. No raster/composed/photo. Icons: logo/nav, search/chrome, scanner, gauge, wrench, paint, EV bolt, plug, sync, log, plus filter/search.

## 6. Content and data
| Visible text / label | Sample | Real data field? | Notes |
|---|---|---|---|
| Eyebrow | NETWORK HARDWARE FLEET | No | — |
| Title | Platform Equipment Catalogue | — | Current app has no equipment UI |
| Subtitle | “Hardware devices, calibration gauges, and diagnostic readers authorized across network.” | No | Authorisation not modelled |
| Filters | All Tools / Calibrated / Telemetry | No | No calibration/telemetry data |
| CTA | Register Equipment | Yes (`POST /master/equipment`) | UI absent; request only code+labels |
| Device 1 | OBD2 Scanner — “Diagnostic Telemetry Tool • BLE 5.0” — “Signal Locked” | Partly (`code`, labels) | BLE/signal not modelled |
| Device 2 | Digital Tire Depth Gauge — “Laser Micrometer • 0.01mm Precision” — “ISO Certified” | Partly | Precision/ISO claim not modelled |
| Device 3 | Precision Torque Wrench — “Digital Strain Sensor • 120-140 Nm” — “Auto Zeroing” | Partly | Range/zeroing not modelled |
| Device 4 | Paint Depth Gauge (Fe/NFe) — “Ultrasonic Substrate Probe” — “Magnetic Eddy” | Partly | Probe/metrology not modelled |
| Device 5 | EV High-Voltage Analyzer — “Cell Impedance & Isolation Tester” — “CAT IV 1000V” | Partly | Safety rating not modelled |
| Status chips | Active (x5) | Partly (`status`) | — |
| Toggle rows | Signal Locked, ISO Certified, Auto Zeroing, Magnetic Eddy, CAT IV 1000V | No | Five unlabeled switches |
| Integrate card | Integrate New Spec — “Pair CAN-bus, RF or optical calibration heads.” — Browse Protocols | No | No pairing/protocol registry |
| Footer | Automatic Telemetry Sync — “All certified devices auto-stream calibration drifts every 24 hours to workshop nodes.” | No | No telemetry |
| Footer count | 5/5 Authorized Active | Partly (`status`) | — |
| Footer action | Diagnostic Logs | No | No logs endpoint |

No customer PII/VIN/plate. Hardware names/specs are sample/invented, not real catalogue entries.

## 7. States shown / not shown
Shown: five active devices, filters, toggles on, one integrate card, footer count. Not shown: inactive/retired device, calibration due/failed, empty catalogue, loading/error, register form, pairing flow, diagnostics logs, search/no-results, toggle pending/failure, RTL, keyboard, 200% text, small screens.

## 8. Implied interactions
Filter All/Calibrated/Telemetry; register equipment; toggle device features; browse protocols; open diagnostic logs; header search/nav. Toggles save immediately with no confirmation.

## 9. Correspondence to current product
Partial/new. Existing: `Equipment` model (`code`, `status`, `sortOrder`, `labelEn`, `labelAr`), `GET/POST /api/v1/platform/master/equipment` (`MasterContentController`), `admin_api.equipment()/createEquipment()`. There is **no equipment UI** in `admin_app`. The card fields (manufacturer, category, precision, connection, calibration, certificate, telemetry, five per-device toggles) do not exist in the model; “Register Equipment” would need a form and model expansion. Telemetry sync, protocol pairing, and diagnostic logs are new server features.

## 10. Locked-rule conflicts / unsafe-to-ship content
- Rule: “no certification/‘verified by’/compliance claims.” Evidence: “ISO Certified” (`1:5161`), “CAT IV 1000V” (`1:5236`) and “All certified devices” (`1:5262`). ISO certification is not established by a product label.
- Rule: “Never invent versions/licences/measurements/results.” Evidence: “0.01mm Precision”, “120–140 Nm”, “CAT IV 1000V”, “BLE 5.0”, “Fe/NFe”, “Ultrasonic”, “24 hours”, “5/5”, “Signal Locked”, “Auto Zeroing”.
- Rule: “UI layer only; no … model/server change.” Evidence: the equipment model has only code/status/sort/labels; every card detail and telemetry feature requires new columns/endpoints.
- Rule: “no single unexplained condition score / results.” Evidence: “calibration drifts every 24 hours” and “Signal Locked” are presented as measured states with no data source.
- Rule: “Finalized findings/evidence/reports immutable; no server change.” Evidence: per-device toggles imply live operational state changes; no reason/audit/confirmation is shown.
- Rule: “tokens from central tokens.” Evidence: 32 px card radii, `#10B981`/`#006C49`, lavender `#F4F3F8`, and Plus Jakarta Sans differ from current tokens; `AppRadiiTokens` stops at 16.
- Rule: “no manager role.” No explicit manager construct here, but “Authorized Active” implies an approval/authorisation process not modelled.

## 11. Open questions / could not verify
- Is the equipment registry meant to store calibration certificates and telemetry, or only names/codes? Current schema is the latter.
- Where do the five per-card toggles store state? There is no device-detail table.
- Are “Calibrated” and “Telemetry” real filters or decoration?
- Is “Browse Protocols” a pairing UI, an equipment-type picker, or a documentation link?
- Do “Diagnostic Logs” exist anywhere?
- No empty/error/loading/RTL/failure states.
