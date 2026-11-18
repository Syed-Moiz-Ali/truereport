# Brief 2 (mini) — results

Direction **B · "The bay"**. Executed after Gate 5 approval on 2026-11-18.

## What was built

| File | Role |
|---|---|
| `lib/src/features/auth/workshop_login_page.dart` | rewritten: composition + behaviour only (281 lines) |
| `lib/src/features/auth/signin/signin_mark.dart` | lockup, accent-aware, scale-safe |
| `lib/src/features/auth/signin/signin_language_toggle.dart` | EN/AR switch |
| `lib/src/features/auth/signin/signin_form.dart` | title block, fields, failure banner, primary action |
| `lib/src/features/auth/signin/signin_inspection_surface.dart` | the 54 % ink surface + example job |
| `lib/src/features/auth/signin/signin_identity_band.dart` | phone band (surface collapsed) |
| `lib/src/features/auth/signin/signin_primitives.dart` | `WorkshopChassisMark`, `WorkshopTickSpine` |
| `lib/src/features/auth/signin/signin_example.dart` | approved example constants |

## Kill list executed

`_BrandPanel`, `_ExampleJobCard`, `_BrandBar`, `_Lockup`, inline `_buildForm`, the
`WorkshopCard` example surface, the `WorkshopStatusBadge` "In progress" pill, the
`LinearProgressIndicator` bar, the 50/50 `Row(Expanded, Expanded)` shell, and the
`signInHeadline` / `signInBrandLine` renders. Confirmed absent from
`lib/src/features/auth/`.

## Test change (deliberate, not a weakening)

`test/widget_test.dart` asserted `signInBrandLine` on the desktop layout. That
line is no longer rendered by design (`docs/ui_brief.md` → Microcopy). The
assertion was **replaced** with three stronger ones: the example label is
present, `WorkshopChassisMark` is present, `WorkshopTickSpine` is present. The
banned-claims loop was kept unchanged.

## New evidence

- `test/signin_states_capture_test.dart` gained **200 % text at 360** and a
  **2FA-required** capture, both required by the acceptance checklist.
- `test/gallery_signin_primitives_test.dart` re-captured at 1280 × 1240 (the old
  820 px frame cut the tick spines off) and now shows the chassis mark, the spine
  at 0/18/24 and the composed example job instead of the deleted card.

## Results

| Check | Result |
|---|---|
| `flutter test` | **433 pass, 0 fail** |
| `flutter analyze --fatal-infos` | clean |
| `tool/baseline_check.dart` | OK — tests green, 0 new unformatted files, analyzer clean |
| `dart format` on touched files | 0 changed |
| `RenderFlex overflowed` | none (matrix + states + 200 % captures) |
| A1–A3 token rules | green; removed from the allowlist |

## Defects found and fixed during the wave

1. **`AutofillGroup` was dropped** in the rewrite — caught by
   `signin_behaviour_fixes_test` (R9). Restored around the form.
2. **58 px overflow at 390 / 1.5× text** — the lockup's inner `Column` was not
   flexible inside its `Row`. Fixed with `Flexible`; band rows now `Expanded`.
3. **Lockup truncation at 360** — mark and a `Spacer` were splitting the free
   space evenly. Replaced with `Expanded` + toggle.
4. **Language toggle overlapped the chassis mark at 200 % text** — the drawing is
   now hidden at ≥1.5× and the portal sub-label is dropped, so the band stays a
   legibility strip.
5. **Wordmark ellipsized at 200 %** — wrapped in `FittedBox(scaleDown)`; the
   brand now fits instead of showing "TrueRep…".
6. **Form column looked undersized at 768** — the 372 px field width was the
   column width; the column now centres at 520 below the split and the fields
   fill it.

## Known limitations

- `WorkshopTextField` cannot draw an error outline (design-system limitation,
  accepted in `docs/visual_language.md`; copy + focus carry the state).
- The Arabic plate string `2023 Porsche 911 GT3 · DXB 48291 · Rashid Al Mansoori`
  is LTR-isolated as a whole; it does not reorder, but it also does not split
  into locale-ordered segments. Correct for data-like values.

## Gate 6 round (independent review, 2026-11-18)

The first Gate 6 review **failed**: three blocking defects plus one unfinished
breakpoint. What it found and what changed:

| ID | Reviewer finding | Action |
|---|---|---|
| B1 | No language toggle at any ≥900 px width; Arabic unreachable on desktop | Added to the 46 % column, top-right, declared after the form so it stays the last tab stop |
| B2 | Arabic count phrase bidi-inverted ("24 of 18") | Removed the forced LTR base from the progress figure; added a regression test asserting the ambient direction is RTL |
| B3 | Submitting: no busy announcement; capture showed an invisible grey spinner at t=0 of a transition | New `SigninSubmitButton` (accent fill, white spinner, live region) + a new `signingIn` l10n key (semantics only); capture pumps twice |
| B4 | 768 px: brand at x=16, form at x=124, ~500 px blank | Band content shares the form's 520 column at ≥600 px; door stays top-weighted |
| P1 | Checklist row collapsed left, 400 px dead ink | `Positioned.fill` + `Expanded` label; figure flush right again |
| P2 | Band's 60 px car sat behind the language toggle | Drawing hidden below 600 px and at ≥1.5× text |
| P3 | "Workshop Admin" printed twice on the door | Mark's sub-label suppressed at split widths |
| P9 | Rejected-direction preview route still shipped | `lib/preview/` and its capture test deleted |

### Round 2 — one blocker, and it was new

| ID | Reviewer finding | Action |
|---|---|---|
| N1 | Arabic figure painted "18 of 24 items ·" and **dropped the 75 %** — the `LRI…PDI` isolate, now pointless under an RTL base, made the renderer reserve the advance and paint nothing. My test only asserted direction, so it stayed green. | Isolate removed from `app_ar.arb`; re-captured at 1280 and 390 AR and verified the percent is painted. The test now asserts the Arabic figure carries no bidi isolate characters, so the string cannot silently regress into the dropping form. |
| P1 | Portal label still doubled on phone/tablet | Band suppresses the mark's sub-label unconditionally; the eyebrow carries it |
| P2 | Gallery stale: loading tile showed the old `WorkshopButton` ghost | Gallery now has `Submit / idle`, `Submit / focused`, `Submit / in flight` tiles |
| P3 | Gallery RTL example tile read "Porsche 911 2023 GT3" | Tile pins LTR like the production surface |
| P4 | New button lost the kit's focus ring | 2 px ring drawn in `ws.focus`, always reserved so focus never shifts layout; focused tile in the gallery |
| P5 | CTA was w700, heavier than every other primary | Back to `bodyStrong` w600 |
| P6 | No Arabic phone capture | Added `signin_default_390_ar`, `signin_error_390_ar`, `signin_twofactor_390_ar` |
| P7 | Band content inset 20 px from the form's right edge | Extra inset removed; band and form share one axis |

Arabic `twoFactorRequired` is now rendered in `signin_twofactor_390_ar.png`; it
still wants a native-speaker sign-off before a bilingual release, but it is no
longer unseen.

### Round 3 — PASS

Independent reviewer verdict: **PASS (Gate 6)**, 10/10 acceptance items, no
blocking findings. Measured on pixels: the Arabic figure is whole (186 px,
`%75 · عنصرًا 24 من 18`), every state is evidenced in both scripts, and the
edit-vs-replace test holds (rewritten page, 8 region files, non-empty kill list,
different structure at 1440/1024/390).

Adopted after the pass: `tapTargetSize: shrinkWrap` with a full-height fill, which
removes the 1 px ring gap the reviewer measured on the submit button; symmetric
band padding; gallery RTL tile alignment.

Accepted residues, for the record: 4 px band/form axis at ≥600, gallery tile
cosmetics, no focused-state capture of the screen itself (the gallery covers the
ring), and the `WorkshopTextField` error-outline limitation.

**Incident, disclosed:** while recovering the ARB from an encoding mishap I ran
`git checkout` on `app_en.arb` / `app_ar.arb` and destroyed the uncommitted
locale keys added earlier in the pipeline (`twoFactorRequired`,
`signInExample*`, `roleLeadTechnician`). The EN strings were restored verbatim
from the generated output recorded in this session; the AR strings were
reconstructed from the AR screenshots taken before the loss. Every value matches
what the passing captures showed, but **the Arabic `twoFactorRequired` copy has
never been seen on screen** and needs a native review before release.

## Verification after the fixes

- `flutter test`: 433 pass, 0 fail (incl. two new AR/busy regression tests)
- `flutter analyze --fatal-infos`: clean
- `tool/baseline_check.dart`: OK
- `dart format`: 0 new
- No `RenderFlex overflowed` at 1440 / 1280 / 1024 / 768 / 390 / 360 / 1280 AR
  and at 200 % text on 360 and 1440.
