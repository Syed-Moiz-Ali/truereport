# F2-A.2 fidelity audit — Screen 5 Consent

Read-only audit. Inputs: node dump `05-consent.txt`, `figma-text/` + `product-copy/` renders/metrics, `consent_view.dart`, `figma_screen_kit.dart`.
Render: 390×972 @ DPR2. Gate: **FAIL** — SSIM 0.81555 (figma-text) / 0.80934 (product-copy); ΔE2000>5 8.77% / 8.98%; worst 64² tile 0.282 / 0.210.
No app, test, server or harness code was edited.

## Read first — global reference offset (−3.5 logical)

Both `figma.png` references are **3.5 logical px lower** than the node dump/render (profile icon, step icon, card icons, switches, CTA all show +7 device px).
Root cause: fixture crop `y=7` includes 7 px of header shadow above the frame. The export frame starts at `y=14`; the first deep-green profile pixel is at export `y=46` = `14 + 2×16`.
Fix: set both fixture crops to `y=14` (`x=40`, 780×1944), then re-run metrics. This alone removes the whole-CTA, header-title and many switch/card vertical diffs.

## figma-text diff boxes (logical)

| # | x,y,w,h | Region | Likely cause | Concrete fix |
|---:|---|---|---|---|
| FT1 | 298,232,52,35.5 | Card 1 switch | Reference ON vs render OFF (fixture has no selectedStatus) + 3.5 px crop offset | Set fixture `selectedType=PUBLIC_LINK`, `selectedStatus=true`; apply crop fix |
| FT2 | 298,328,52,35.5 | Card 2 switch | Reference ON vs render OFF (fixture state) + crop offset | Set fixture `selectedType=PROCESSING`, `selectedStatus=true`; crop fix |
| FT3 | 20,906.5,350,29 | CTA lower band | 3.5 px global crop shift; CTA shadow bottom | Crop fix; re-check `Fx.ctaShadow` (25/10) only if residual remains |
| FT4 | 20,876,350,29 | CTA upper band | 3.5 px global crop shift | Crop fix |
| FT5 | 77,606,236,56 | Signature stroke area | J4: capture out of scope, decision slot is approved replacement; box also 4 px high | No copy fix (J4); align decision box to y542 (see FT6) |
| FT6 | 146.5,502,67.5,18 | “Required” pill (render) | Decision header 10 px too high; pill 6.5 px too right | 32 gap card3→header; header 18 + 12 bottom pad; header left pad 4; title gap 6 (pill x139.94) |
| FT7 | 140,515.5,67.5,18 | “Required” pill (reference) | Reference side of the 10 px header offset + 3.5 px crop | Same header fix + crop fix |
| FT8 | 236.5,27,62.5,19.5 | Header title tail | Crop offset; title starts x64 vs Figma x68 | Crop fix; add 4 px title inset (x68) |
| FT9 | 174.5,149,66.5,15 | Intro line 1 | `figmaText` still uses `l10n.technicianConsentIntro`, not Figma copy | Use literal “Review compliance permissions and provide\ncustomer digital sign-off.” when `figmaText` |
| FT10 | 20.5,169,63.5,15 | Intro line 2 | Same intro copy mismatch | Same literal intro fix |
| FT11 | 110,120.5,26,18.5 | Heading “Authorizations” | Crop offset + w800/ExtraBold rasterization/tracking | Crop fix; verify font asset, weight w800, tracking −0.65 |
| FT12 | 128,25.5,30.5,17.5 | Header title | Crop offset + 4 px-left title | Crop fix; title inset 4 |
| FT13 | 170,120.5,26.5,18.5 | Heading “Authorizations” | Same as FT11 | Same as FT11 |
| FT14 | 48,152,51,12 | Intro line 1 | Intro copy mismatch | Literal intro fix |
| FT15 | 207.5,25.5,28,17.5 | Header title | Crop offset + 4 px-left title | Crop fix; title inset 4 |
| FT16 | 298,443,51.5,16.5 | Card 3 switch | Crop offset + thumb shadow blur 2/y1 vs Figma 6/y2 | Crop fix; switch thumb shadow `blur 6, offset (0,2)` |
| FT17 | 242.5,149,33,17.5 | Intro line 1 end | Intro copy mismatch | Literal intro fix |
| FT18 | 110.5,152,40.5,12 | Intro line 1 | Intro copy mismatch | Literal intro fix |
| FT19 | 107.5,169,32.5,15 | Intro line 2 | Intro copy mismatch | Literal intro fix |
| FT20 | 64,25.5,27,17.5 | Header title start | Crop offset + 4 px-left title | Crop fix; title inset 4 |

## product-copy diff boxes (logical)

| # | x,y,w,h | Region | Likely cause | Concrete fix |
|---:|---|---|---|---|
| PC1 | 298,232,52,35.5 | Card 1 switch | Fixture OFF vs reference ON + crop offset | Same as FT1 |
| PC2 | 298,328,52,35.5 | Card 2 switch | Fixture OFF vs reference ON + crop offset | Same as FT2 |
| PC3 | 77,606,236,58 | Signature area | J4 approved decision-slot replacement + 4 px box offset | Align box y542; approved content residual |
| PC4 | 20,906.5,350,29 | CTA lower | Crop offset + CTA shadow | Crop fix |
| PC5 | 20,876,350,29 | CTA upper | Crop offset | Crop fix |
| PC6 | 146.5,502,67.5,18 | “Required” pill (render) | Decision header 10 px high; pill 6.5 px right | Same header/pill fix as FT6 |
| PC7 | 140,515.5,67.5,18 | “Required” pill (reference) | Header offset + crop | Same as FT7 |
| PC8 | 70.5,117.5,65.5,21.5 | Heading | Product “Consent” vs Figma “Authorizations”; crop offset | Approved product-copy residual; crop fix |
| PC9 | 95,330,84,16 | Card 2 title/body | Product copy “Processing consent” vs Figma title | Approved product-copy residual; keep card clipping fix |
| PC10 | 20.5,115,53,24 | Heading | Product “Consent” vs Figma “Authorizations” | Approved product-copy residual |
| PC11 | 174.5,149,66.5,15 | Intro line 1 | Product intro differs from Figma | Approved product-copy residual |
| PC12 | 151,234,48.5,16 | Card 1 title/body | Product “Public-link consent” vs Figma title | Approved product-copy residual |
| PC13 | 20.5,169,63.5,15 | Intro line 2 | Product intro differs from Figma | Approved product-copy residual |
| PC14 | 197,902,50.5,12 | CTA label | Product “Save consent” vs Figma “Save Consent” | Approved; or capitalize for cross-screen consistency |
| PC15 | 80,28.5,38,14.5 | Header title | Crop offset + 4 px-left title | Crop fix; title inset 4 |
| PC16 | 200.5,237,35,16 | Card 1 body | Product body differs from Figma copy | Approved product-copy residual |
| PC17 | 48,152,51,12 | Intro line 1 | Product intro differs | Approved product-copy residual |
| PC18 | 113.5,234,36.5,16 | Card 1 title | Product title differs | Approved product-copy residual |
| PC19 | 211.5,331,32.5,15 | Card 2 body | Product body differs | Approved product-copy residual |
| PC20 | 179,333,31.5,13 | Card 2 body | Product body differs | Approved product-copy residual |

## Region findings (heights / shadow / typography)

- **Cards:** 80 logical high, 16 gap, radius 32, padding 20 all match the node. No card-edge diff box >ΔE5, so card height is correct after the crop fix.
- **Card shadow:** `Fx.cardShadow` offsets/blur (8/2 + 40/14) match the dump and shadows are now enabled (`debugDisableShadows=false`). Shadow colour/alpha is not in the dump, so only offsets/blur can be confirmed.
- **Switch:** track 52×32, radius pill, pad 4, thumb 24, on-inset 4 and off-inset 4 are correct. Only state and thumb shadow (2/1 vs 6/2) differ.
- **Decision slot:** box must start at y542 (350×176, radius 32, `#F4F3F899`); current render starts y538 because the header is 10 px high and the 30 px centred header adds 6 px. Approved J4 content replacement, not a capture defect.
- **Card typography:** render text column is ~196 wide with ellipsis; Figma clips at 186.86/190.13/190.77 with no ellipsis, so titles/bodies cut at different glyphs. Use `clip` for `figmaText` and widen the text→switch gap from 8 to ~16.
- **Other observed (below top-20 cut):** profile avatar is a person vector in Figma but “TR” text in the render; Figma header is `#FFFFFFCC` + blur 48 vs opaque white + blur 24; figma-text timestamp still reads “Not recorded yet” instead of “Today, 14:38 EST”; card 2 glyph is 15×13.33 in Figma vs 16.67 in the kit.

## Top 5 fixes

1. **Fix reference crop:** change both fixtures `y:7` → `y:14` and re-run. Removes the 3.5 px global offset on header, cards, switches, pill and CTA.
2. **Decision header/box:** use 32 gap after card 3, header height 18 + 12 bottom pad (not 30 centred), 4 px left inset, 6 px title→pill gap; header text at y512, pill x139.94, box y542.
3. **Switch state + thumb shadow:** set an ON fixture for cards 1–2; replace `Fx.pillShadow` on the thumb with blur 6 / offset (0,2). Track geometry needs no change.
4. **figmaText copy + card clipping:** literal two-line intro; exact timestamp text; constrain text to Figma widths and use `TextOverflow.clip` instead of ellipsis.
5. **Header chrome:** add 4 px title inset (x68); optionally use Figma person icon instead of “TR” when `figmaText`; keep header fill/blur parity if content can scroll under it.

## Approved residuals

- **J4:** signature capture, cursive stroke and “Recorded” badge are out of scope. The Granted/Refused decision slot is the approved replacement (FT5/PC3 and part of PC9).
- **product-copy sample:** copy-only boxes PC8–PC14 and PC16–PC20 are intentional product copy; they cannot match the Figma reference and should be masked or judged by a copy-agnostic gate.
- **Sub-pixel AA / w800-vs-ExtraBold rasterisation** in the 26 px title is accepted after the crop fix.
- **Card shadow colour/alpha** is accepted as implemented because the node dump does not carry the shadow colour.

## What could not be verified

- Exact Figma shadow colours/alphas for cards and CTA (dump lists only blur/offset).
- ON-state switch thumb/shadow until a fixture with `selectedStatus=true` exists (geometry was inferred from node values).
- Real signature capture/recorded state (J4 out of scope).
- Runtime `debugDisableShadows` behaviour versus the golden harness render.
- Plus Jakarta Sans variable-font parity at w800/ExtraBold across platforms.
- RTL, long translations, textScale >1, status-bar/safe-area and scrolled-header states.
- Product-copy UX wording correctness (only the fidelity diff was measured).
