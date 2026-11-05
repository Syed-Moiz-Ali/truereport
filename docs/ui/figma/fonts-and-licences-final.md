# Fonts and licences — final F1 bundle

**Project:** TrueReport
**Phase:** F1
**Date:** 2026-11-05
**Status:** fonts downloaded, verified at the binary level, and bundled as local assets. **No native Arabic approval is claimed.** No runtime font download is used.
**Related:** `decisions.md` (A3), `adr/ADR-F1-002-type-and-fonts.md`, `fonts-and-licences.md` (research), `f1-token-api.md` §4.

---

## 1. What was bundled

Owned paths only:

- `client/packages/design_system/assets/fonts/**` — new app assets and licences.
- `server/src/main/resources/public-report/fonts/**` — copies added for the integration lead; no CSS or template was edited.
- This document.

Machine-readable inventory: `client/packages/design_system/assets/fonts/fonts.json`.

All downloads were made on **2026-11-05** from official upstream repositories. Sizes are raw bytes; hashes are SHA-256 of the exact bundled bytes, computed with PowerShell `Get-FileHash`.

### 1.1 Plus Jakarta Sans (Latin, 400/500/600/700/800)

Upstream: `tokotype/PlusJakartaSans`, `fonts/ttf/`, version **2.071**.

| File | Weight | Bytes | SHA-256 |
|---|---:|---:|---|
| `PlusJakartaSans-Regular.ttf` | 400 | 128,972 | `BD6276D4060E3B1EBC45047469E0BB86B08F301BA681CDF1CEB6245EA10478D2` |
| `PlusJakartaSans-Medium.ttf` | 500 | 129,180 | `C77BAB757D7402EC6D9341D5F7DDAAFB2474E17026792697BA4624C7DC89CAF7` |
| `PlusJakartaSans-SemiBold.ttf` | 600 | 129,288 | `65DBCEDB6596A41C30869729EB31CB57D1F5EDFE365684314BBA8A1994EAA4CB` |
| `PlusJakartaSans-Bold.ttf` | 700 | 128,988 | `5F5342EF76862B5B5365D1DFF1A667629DFA484E388DD602552F647219C3870F` |
| `PlusJakartaSans-ExtraBold.ttf` | 800 | 128,888 | `7D60D21B5DEC501C77437E80AABD539F1D7A7B0AC7D4ADA361D4D42ABC7C55EA` |

Source URLs are recorded per file in `fonts.json`. Static files were used; the upstream project publishes these exact TTFs.

### 1.2 Noto Sans Arabic (Arabic, 400/500/600/700)

Upstream: `google/fonts`, `ofl/notosansarabic/NotoSansArabic[wdth,wght].ttf`, version **2.012**. Google Fonts ships this family as a variable font only. Static instances were generated with `fontTools.varLib.instancer` 4.63.0 on Python 3.14.6 using `wght` = 400/500/600/700 and `wdth` = 100 (the only width offered).

| File | Weight | Bytes | SHA-256 |
|---|---:|---:|---|
| `NotoSansArabic-Regular.ttf` | 400 | 194,336 | `AF2E99E42B8AAA04415649AEE873BAE0BEB91F2BA03A544A6ED757147FE03D71` |
| `NotoSansArabic-Medium.ttf` | 500 | 194,612 | `E30AD3BA28F9A90B14A2FC6D0CA79D12CC089C370831B54B478998371D5A8E15` |
| `NotoSansArabic-SemiBold.ttf` | 600 | 194,656 | `10FEC08D76B5AEAE3A1E5A59A1D44D53529E72EE99727FFA872291B9543897F1` |
| `NotoSansArabic-Bold.ttf` | 700 | 194,520 | `0EEB437A4B6C0BFFD3991A5D4B10E92AB56200CAAE98FB0FD33DE71DAD97EE50` |

These are generated instances, not separate upstream static releases; the hashes therefore identify the generated files, not a Google-hosted static. The variable source is recorded in `fonts.json`.

### 1.3 IBM Plex Sans Arabic (Arabic, 400/500/600/700)

Upstream: `google/fonts`, `ofl/ibmplexsansarabic/`, version **1.101**.

| File | Weight | Bytes | SHA-256 |
|---|---:|---:|---|
| `IBMPlexSansArabic-Regular.ttf` | 400 | 235,924 | `6F611412270A132BBAC838DA9259D4C68569B4175F3B3B8FA3FA36A30B56DAB9` |
| `IBMPlexSansArabic-Medium.ttf` | 500 | 242,100 | `B8363AB9F733DFA4F8E96B8B2102C24B5CF4110FB96D1D3D9A9412F6FB49CF74` |
| `IBMPlexSansArabic-SemiBold.ttf` | 600 | 244,616 | `597BD5502E5997BE4414E4C9C88834B30FF3784250C84F20BCE2B20E53EBD467` |
| `IBMPlexSansArabic-Bold.ttf` | 700 | 246,992 | `691E0C891A38637AE6BBDB69700F8042CB0724A137BEE615068FFDB92244F61F` |

### 1.4 Fallbacks

| File | Family / version | Bytes | SHA-256 | Use |
|---|---|---:|---|---|
| `NotoSans-Regular.ttf` | Noto Sans Regular, 2.008 | 569,208 | `B85C38ECEA8A7CFB39C24E395A4007474FA5A4FC864F6EE33309EB4948D232D5` | Cyrillic and general non-Latin fallback |
| `NotoSansSC-Regular.otf` | Noto Sans CJK SC Regular, 2.004 | **16,437,364** | `2C76254F6FC379FDDFCE0A7E84FB5385BB135D3E399294F6EEB6680D0365B74B` | `zh-Hans` only |

Both were copied from the existing `server/src/main/resources/public-report/fonts/` assets, byte-for-byte. The SC file is **15.68 MiB**; it is the dominant size cost and it is not bundled for other locales.

### 1.5 Server handoff copies

The same Plus Jakarta Sans, Noto Sans Arabic, and IBM Plex Sans Arabic files plus their OFL notices were added to `server/src/main/resources/public-report/fonts/`. Existing server files (`NotoSans-Regular.ttf`, `NotoNaskhArabic-Regular.ttf`, `NotoSansSC-Regular.otf`, `OFL.txt`) were not modified. CSS/templates remain untouched for the integration lead to wire.

---

## 2. Licence files and obligations

Official OFL 1.1 texts only; none was written by hand.

| File | Family | Bytes | SHA-256 | Reserved Font Name declared? |
|---|---|---:|---|---|
| `licenses/OFL-PlusJakartaSans.txt` | Plus Jakarta Sans | 4,402 | `995C7199CAB65954F545996326755DAEE7B63CC6B42B06C13DA1F9502AB08A99` | No |
| `licenses/OFL-NotoSansArabic.txt` | Noto Sans Arabic | 4,382 | `07FC70BFEB985CC1A87A8587D0A0C80BAB11C86C9DC3FD95B6F0CB332F983E96` | No |
| `licenses/OFL-NotoSans.txt` | Noto Sans | 4,396 | `CEE9892F9F0CC8FE882C9E9537EE6A89621D86EE7CEAF70B02E2B2B1C25C061A` | No |
| `licenses/OFL-NotoSansSC.txt` | Noto Sans SC | 4,388 | `1C05C68C34F9708415AADA51F17E1B0092D2CEA709BF4A94CD38114F9E73D7D9` | Yes — `Source` (Adobe) |
| `licenses/OFL-IBMPlexSansArabic.txt` | IBM Plex Sans Arabic | 4,456 | `7E6B2818EDBD8F6A01AE80641CC8F16A51080D08FB4E532BE3A0B6F74ADB07DA` | Yes — `Plex` (IBM) |

Total licence bytes: **22,024**.

Obligations carried by every file:

1. Ship the copyright notice and the OFL 1.1 text with the font software. The `licenses/` directory is that notice path; keep it in any app/package or server distribution.
2. Do not sell the fonts by themselves.
3. Modified versions must not use a declared Reserved Font Name. The Noto Sans Arabic instances are modified copies of the upstream variable font; that family's OFL declares **no** RFN, so retaining the name is permitted. IBM Plex (`Plex`) and Noto Sans SC (`Source`) files are unmodified upstream files and keep their names.
4. Do not use copyright-holder names to promote modified versions.
5. The font software stays under the OFL. No UI attribution is required; document embedding is permitted.
6. This is a reading of the official text, not legal advice.

---

## 3. Verified script coverage (binary `cmap`)

Counts are codepoints present in the best `cmap`, read with fontTools 4.63.0. They prove glyph presence, **not** shaping quality.

| Family | Latin basic | Latin-1 | Latin Ext-A | Arabic | Arabic Supp | Arabic Ext-A | Arabic Pres-A | Arabic Pres-B | Cyrillic | CJK Unified | Mapped |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Plus Jakarta Sans (all weights) | 95/95 | 95/96 | 126/128 | 0/256 | 0/48 | 0/96 | 0/688 | 0/144 | 0/256 | 0/20,992 | 721 |
| Noto Sans Arabic (all weights) | 95/95 | 84/96 | 97/128 | **256/256** | **48/48** | **96/96** | 631/688 | 141/144 | 0/256 | 0/20,992 | 1,561 |
| IBM Plex Sans Arabic (all weights) | 95/95 | 96/96 | 15/128 | 252/256 | 48/48 | 40/96 | 196/688 | 140/144 | 0/256 | 0/20,992 | 1,032 |
| Noto Sans Regular | 95/95 | 96/96 | 128/128 | 0/256 | 0/48 | 0/96 | 0/688 | 0/144 | **256/256** (+48/48 supp) | 0/20,992 | 2,840 |
| Noto Sans SC Regular | 95/95 | 96/96 | 30/128 | 0/256 | 0/48 | 0/96 | 0/688 | 0/144 | 66/256 | **20,976/20,992** | 44,810 |

Script summary for the requirement:

- **Latin:** Plus Jakarta Sans covers basic Latin, Latin-1 and most of Latin Ext-A. Noto Sans covers Latin and Latin Ext-A fully.
- **Arabic:** both candidates cover the core Arabic block. Noto Sans Arabic is fuller (256/256 + all Arabic Extended-A); IBM Plex Sans Arabic omits some Extended-A and Presentation Forms codepoints.
- **Cyrillic:** only Noto Sans Regular is the approved fallback (256/256 basic + 48/48 supplement). Plus Jakarta Sans has **zero** Cyrillic despite some Google Fonts metadata listing `cyrillic-ext`; that known discrepancy is unchanged.
- **CJK:** Noto Sans SC covers 20,976/20,992 tested CJK Unified codepoints. It is for `zh-Hans` only.

Both Arabic candidates contain OpenType `GSUB` and `GPOS` with the `arab` script and the `init`, `medi`, `fina`, `rlig`, and `liga` features; IBM also has `calt`. This confirms the shaping machinery exists at the table level.

**Real shaping must be tested on device.** Ligature joining, mark positioning, mixed Arabic/Latin/numerals, and RTL line breaking were not run through Flutter/Skia or a physical device in this task.

---

## 4. Arabic candidates comparison

| Criterion | Noto Sans Arabic 2.012 | IBM Plex Sans Arabic 1.101 |
|---|---|---|
| Core Arabic block | 256/256 | 252/256 |
| Arabic Extended-A | 96/96 | 40/96 |
| Arabic Presentation Forms-A | 631/688 | 196/688 |
| Arabic Presentation Forms-B | 141/144 | 140/144 |
| Arabic shaping tables | GSUB + GPOS, `arab` | GSUB + GPOS, `arab` |
| Latin coverage | Basic 95/95 | Basic 95/95, Latin-1 96/96 |
| Four static weights total | 778,124 bytes | 969,632 bytes |
| Licence | OFL 1.1; no RFN | OFL 1.1; RFN `Plex` |
| Provenance of bundled files | Instanced from official variable | Official static files |
| Native reviewer approval | **Not obtained** | **Not obtained** |

Noto Sans Arabic is the broader-coverage candidate and is the ADR-F1-002 default. IBM Plex Sans Arabic is a valid alternative with a Latin design that matches the Plex family. **Neither is approved for native Arabic quality**; the gallery/reviewer decision remains open. Do not describe either as native-approved.

---

## 5. App-size impact

Measured raw bytes of the bundled files (no compression, no subsetting):

| Group | Bytes | MiB |
|---|---:|---:|
| Plus Jakarta Sans (5) | 645,316 | 0.62 |
| Noto Sans Arabic (4) | 778,124 | 0.74 |
| IBM Plex Sans Arabic (4) | 969,632 | 0.92 |
| Noto Sans Regular (1) | 569,208 | 0.54 |
| **Subtotal without Noto Sans SC** | **2,962,280** | **2.83** |
| Noto Sans SC Regular (1) | 16,437,364 | 15.68 |
| **Total with Noto Sans SC** | **19,399,644** | **18.50** |
| Licence texts (5) | 22,024 | 0.02 |

Noto Sans SC alone accounts for ~84.7% of the font payload. If app size becomes a constraint, subsetting is permitted by the OFL provided the notice travels with the subset and the required Chinese characters are tested; no subsetting was done here. Both Arabic candidates are currently bundled because the gallery must show both; a later decision could remove the unused one and save ~0.74–0.92 MiB.

---

## 6. What could not be verified / remains open

1. **On-device Arabic shaping.** `cmap` presence and `GSUB`/`GPOS` tables are verified; actual HarfBuzz/Skia shaping, diacritic positioning, and RTL line breaking were not tested on Android, iOS, web, or the PDF engine. Test on device before sign-off.
2. **Native Arabic review.** No native speaker approved either candidate. The gallery comparison and review are still required.
3. **Exact Figma font versions.** The Figma exports record names and styles, not binaries; the current official upstream releases were used.
4. **Generated Noto Sans Arabic statics.** Google Fonts does not host separate static files for this family; the four files are `fontTools` instances of the variable font. Their metrics should be visually compared against the variable rendering.
5. **Noto Sans / Noto Sans SC exact upstream release URLs.** These two files are the existing repository assets (versions 2.008 and 2.004). Their upstream repository is recorded, but the exact release tag/commit for those builds was not re-established.
6. **No visual/hinting or metric comparison.** No rendered specimen, hinting check, or metric-match test was performed.
7. **No Flutter build or pubspec wiring.** Per scope, `pubspec.yaml` was not edited; the integration lead must declare the families/weights and run the app build.
8. **No subsetting.** Noto Sans SC is shipped whole; CJK/Latin subsetting and its licence-notice path are not tested.
9. **Licence statements are not legal advice.**

---

## 7. Upstream sources (accessed 2026-11-05)

- Plus Jakarta Sans statics: `https://github.com/tokotype/PlusJakartaSans/tree/master/fonts/ttf`
- Plus Jakarta Sans OFL: `https://github.com/google/fonts/blob/main/ofl/plusjakartasans/OFL.txt`
- Noto Sans Arabic variable: `https://github.com/google/fonts/tree/main/ofl/notosansarabic`
- Noto Sans Arabic OFL: `https://github.com/google/fonts/blob/main/ofl/notosansarabic/OFL.txt`
- IBM Plex Sans Arabic statics and OFL: `https://github.com/google/fonts/tree/main/ofl/ibmplexsansarabic`
- Noto Sans OFL: `https://github.com/google/fonts/blob/main/ofl/notosans/OFL.txt`
- Noto Sans SC OFL: `https://github.com/google/fonts/blob/main/ofl/notosanssc/OFL.txt`
- Noto project: `https://github.com/notofonts/noto-fonts` and `https://github.com/notofonts/noto-cjk`

Exact raw URLs for every file are in `client/packages/design_system/assets/fonts/fonts.json`.
