# F2-A privacy and safety review

**Phase:** F2-A (Technician app, screens 1 to 7)
**Reviewer:** privacy-reviewer subagent, with lead verification
**Date:** 5 November 2026
**Verdict:** **pass with no blockers** after two fixes.

## Findings fixed before sign-off

| Finding | Fix |
|---|---|
| The gallery section for the P7 dock comparison was declared in `showcase_chrome.dart` but not referenced in `gallery_app.dart`, so the “behind FixtureGuard” claim was inaccurate | Added the `Technician dock decision (P7)` section inside `if (FixtureGuard.enabled)` in `client/apps/ui_gallery/lib/gallery_app.dart`. The 4-item Figma dock remains gallery-only. |
| The intake card exposed customer email, phone, VIN and plate at once (allowed internally, but more over-the-shoulder exposure than the Figma) | Removed the customer email from the intake card; email remains editable in the existing customer sheet. Phone, VIN and plate stay because they are real fields the Figma shows and the technician needs them. |
| Unused `TechnicianConsentCard` would toggle immediately via a switch if adopted later | Removed the unused component. The shipped consent UI records only on Save. |

## Confirmed passes

- No server, API contract, model, validation, permission or state-management change. `server/`, `backend/` and `infra/` are untouched; `tokens.g.css` is unchanged.
- Consent starts unselected; Save is disabled until both a type and Granted/Refused are chosen; no record is created before Save; PROCESSING and PUBLIC_LINK are retained; no signature pad or prefilled signature.
- No Figma sample names, vehicles, VINs, photos or avatars in product code. Fixtures are under `test/` and `docs/.../fidelity`; no `lib/` import; gallery dock is behind `FixtureGuard`; `ui_gallery` is not referenced by product or infra.
- No certification, “verified”, score, pass-rate, compliance, approval/sign-off, GPS, BLE/pairing or live-sync wording in F2-A product UI. The product-copy deny-list is clean.
- Public report, PDF, admin app and server surfaces are untouched.
- The equipment sheet states that names are unavailable instead of inventing them.

## Remaining low/info items

- **VIN clipboard:** the copy-VIN action writes the VIN to the system clipboard. It is user-initiated and local; no transmission.
- **Profile email:** the profile sheet shows the technician’s own email. It is their own account data and is not a public surface.
- **Raw equipment IDs:** the existing equipment sheet renders server IDs only; documented as the screen-6 data gap.
- **Test/doc artifacts:** fidelity PNGs, fixtures and screenshots contain test-only sample data. They are not packaged assets or deployment inputs.
- **Pre-existing, outside F2-A:** the wider app still contains “Could not verify” as a result label and the key `approveAndGenerateReport` (rendered as “Finalize inspection”). No new F2-A forbidden wording was introduced.

## Not verified

- Real-device clipboard behaviour, over-the-shoulder visibility, screen readers and Arabic rendering.
- A produced release artifact was not inspected to prove fixture exclusion; the structural and guard evidence above is the basis for the claim.
- The server suite was not rerun by the reviewer; no server files changed.
