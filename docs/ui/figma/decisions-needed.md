# Decisions needed (Phase F0)

**Project:** TrueReport
**Date:** 5 November 2026
**Purpose:** list the real decisions raised by the Figma intake. These are **not** decisions I have made. Each has options, an indicative cost, a recommendation and the phase it blocks.
**Cost scale (rough, not a quote):** **S** ≤ ~1 developer-week; **M** ~1–3 developer-weeks; **L** > 3 developer-weeks or needs server/database/security changes.

Locked rules are not optional decisions. Where a design element contradicts a locked rule, it is marked in `gap-report.md` and repeated at the bottom of this file as "locked — not a decision".

---

## A. Design system

### A1. Which visual direction is authoritative?

**Question:** Do we adopt the Figma visual language (emerald `#10B981` / deep green `#006C49`, Plus Jakarta Sans, 24–48 px radii, soft shadows), keep the current TrueReport teal/Noto system, or take a hybrid?

| Option | Cost | Consequence |
|---|---|---|
| **A1-a Hybrid** — keep current semantic/status colours and accessible teal tokens for meaning-critical UI; adopt Figma layout, shape, spacing and type scale; reconcile one palette | M | One token contract; no data/API change; Figma's look is partly preserved; accessibility can be fixed centrally |
| **A1-b Full Figma** — replace the current palette/type/radii with the Figma system | L | Every screen, public report and PDF changes; still requires contrast fixes; would invalidate current visual tests and dark theme |
| **A1-c Keep current** — take only layout ideas, no visual restyle | S | Lowest risk/effort; the Figma design is not meaningfully adopted |

**Recommendation for your decision:** A1-a (hybrid), because the Figma palette fails WCAG as drawn and the locked rule requires central tokens. This is the least-cost route to a coherent, accessible result.
**Blocks:** F1, and therefore every later phase.

### A2. How do we make the emerald primary accessible?

**Question:** `#FFFFFF` on `#10B981` is **2.54:1** (needs 4.5:1); `#10B981` on white is also **2.54:1**. What replaces it for text/CTAs/icons?

| Option | Cost | Consequence |
|---|---|---|
| **A2-a Emerald as fill only, never text** — keep `#10B981` for non-text decoration, use deep green `#006C49` for text/icons, and a measured darker fill for primary CTA with white text | M | Preserves the emerald identity; requires new token pair and re-checking every pair |
| **A2-b Keep current teal primary** `#0B3B4A` / `#0F6B6F` and use emerald only as an accent | S | Passes today; Figma's emerald identity is mostly lost |
| **A2-c Darken emerald until white passes** — e.g. a candidate around `#047857` (must be measured), keep the rest | S–M | Closest to Figma; changes the visual "brightness"; candidate is not approved until measured |
| **A2-d Text-only restrictions** — allow emerald only at ≥24 px/700 and never for body/UI | S | Still fails the 3:1 UI requirement for icons/borders; not sufficient alone |

**Recommendation for your decision:** A2-a or A2-c after a measured token pass; do not approve A2-d.
**Blocks:** F1, F2–F5, public report/PDF.

### A3. Typography family and licence

**Question:** Do we bundle Plus Jakarta Sans (OFL, Latin/Latin-ext only) with separate Arabic/CJK fallbacks, keep system fonts, or choose a different family?

| Option | Cost | Consequence |
|---|---|---|
| **A3-a Bundle Plus Jakarta Sans + Noto Naskh Arabic + Noto Sans SC fallback** | M | Closest to Figma; needs font assets, licence notices, Flutter bundling, PDF/HTML already has Noto; adds app size (CJK is ~16 MB if bundled in app) |
| **A3-b Keep current platform/system fonts; keep Noto only in server PDF/HTML** | S | No new licence/app-size cost; Flutter Arabic/Cyrillic/CJK rendering remains OS-dependent and unverified |
| **A3-c Use Noto Sans + Noto Naskh everywhere** | S–M | Best script coverage and already licensed in the server; loses the Plus Jakarta look; Type scale still needs work |
| **A3-d Choose a different family with wide coverage** | M–L | Requires licence and coverage verification; not evidenced yet |

**Evidence:** Plus Jakarta Sans has **no Arabic, no Cyrillic and no Chinese** glyphs (verified from the official binary/metadata in `fonts-and-licences.md`). The Figma Arabic label already falls back to `FreeSerif`, which is not a product font. The Flutter apps bundle **no `fonts:` assets**; only the server has Noto.
**Recommendation for your decision:** A3-a if you keep the Figma look, otherwise A3-c. Do not claim Arabic/RTL completeness without a bundled Arabic face and real-device tests.
**Blocks:** F1; all Arabic/RTL acceptance gates.

### A4. Radius and elevation scale

**Question:** Do we adopt Figma's radii (16/24/32/48/pill), keep the current 4/8/12/16/pill, or extend for large cards only?

| Option | Cost | Consequence |
|---|---|---|
| **A4-a Hybrid** — keep 4/8/12 for inputs/chips, add 24/32 for large cards; pill for CTAs/segmented controls | S–M | Figma's softness with current control geometry; fewer breaking changes |
| **A4-b Full Figma** — 16/24/32/48/pill everywhere | M | Strong visual match; 24–48 px radii on small controls may look wrong and complicate dense tables |
| **A4-c Keep current** | S | Dense/compact look; Figma cards, rails and mobile sheets are visibly different |

**Recommendation for your decision:** A4-a.
**Blocks:** F1, F2–F5.

### A5. Spacing scale and off-grid values

**Question:** The export uses 2/4/6/8/10/12/14/16/20/24/28/32/40/48/56/64/80/96/140. The current tokens are 4/8/12/16/24/32/48. Which become tokens?

| Option | Cost | Consequence |
|---|---|---|
| **A5-a Keep 4/8/12/16/24/32/48 and map outliers to the nearest token** | S | Fewer tokens; some Figma spacing cannot be reproduced exactly |
| **A5-b Extend to 4/8/12/16/20/24/32/40/48/64** | S–M | Captures most layouts; still excludes 2/6/10/14/28/56/80/96/140 |
| **A5-c Adopt all observed values** | M | Exact reproduction; creates a large, unstructured scale that is hard to keep consistent |

**Recommendation for your decision:** A5-b. Treat 2/6/14/28 etc. as derived constraints (FILL/space-between), not new tokens.
**Blocks:** F1.

### A6. Dark mode

**Question:** The current apps and public report support dark mode; the Figma exports are light-only and `DESIGN.md` says light-only. Do we keep dark?

| Option | Cost | Consequence |
|---|---|---|
| **A6-a Keep dark for apps; light-first public report with tested dark** | S–M | Preserves current accessibility work; needs token parity for the new palette |
| **A6-b Drop dark to match Figma** | M | Removes tested functionality; users lose OS dark-mode support |
| **A6-c Keep dark everywhere** | S–M | Needs dark equivalents for every new token and re-testing |

**Recommendation for your decision:** A6-a, unless dark is explicitly out of scope.
**Blocks:** F1.

### A7. Component-library scope

**Question:** Which shared components do we build in `design_system`?

| Option | Cost | Consequence |
|---|---|---|
| **A7-a Only patterns needed by approved screens** — buttons, cards, fields, chips, segmented control, nav rail, list rows, empty/error/skeleton, modal/sheet, progress, tabs | M | Keeps the library small and testable; Figma-only patterns wait |
| **A7-b All Figma patterns** — also tree, data table, damage canvas, signature pad, annotation editor, print canvas, swipe control, metric cards, stepper, timeline | L | Highest visual coverage; more surface to test and maintain; some patterns have no product data |
| **A7-c Per-app widgets** | S–M | Faster locally; duplicates visual logic and breaks the central-token rule |

**Recommendation for your decision:** A7-a; add patterns only when the corresponding approved screen is built.
**Blocks:** F1.

### A8. Product name and brand

**Question:** The exports use `TechInspect` (technician), `Apex Auto Care` / `Apex Precision Labs` / `Apex Vehicle Diagnostic Systems` (public), and `ShopFlow` (share URL). Our product is `TrueReport`. Which is authoritative?

| Option | Cost | Consequence |
|---|---|---|
| **A8-a TrueReport everywhere** | S | Consistent with existing code/l10n; Figma brand strings are treated as placeholders |
| **A8-b Adopt a new brand from the design** | M | Requires renaming copy, assets, domains, legal/marketing review; code identifiers may remain |
| **A8-c White-label per workshop** | L | New data/feature (brand settings), not UI-only |

**Recommendation for your decision:** A8-a.
**Blocks:** F1 and every copy/acceptance gate.

---

## B. Accessibility and RTL

### B1. Minimum text sizes

**Question:** Figma uses 11 px labels and 13 px body; the Phase 1 contract uses 13 px labels and 15/22 body. Which minimum do we enforce?

| Option | Cost | Consequence |
|---|---|---|
| **B1-a 12 px label / 14 px body / 16 px preferred body** | M | Readable and close to current; needs layout reflow on dense screens |
| **B1-b Keep Phase 1 sizes (13 label / 15 body)** | M | Strongest readability; more reflow; some dense admin tables need redesign |
| **B1-c Keep 11/13 to match Figma** | S | Fastest fidelity; fails the spirit of WCAG 2.2 AA and 200% scaling is harder |

**Recommendation for your decision:** B1-a as a floor, B1-b where possible.
**Blocks:** F1–F5.

### B2. Touch/click targets

**Question:** Many Figma controls are 24–32 px (language segments, eye toggle, chevrons, switches). How do we meet the 44/48 px requirement?

| Option | Cost | Consequence |
|---|---|---|
| **B2-a Enlarge visual controls to 44/48 and add spacing** | M | Clear hit areas; dense toolbars need re-layout |
| **B2-b Keep visual size but add invisible 44/48 hit areas** | S | Meets target size; visual affordance stays small; risk of adjacent-target overlap |
| **B2-c Both: enlarge critical controls, invisible hit area for compact icon buttons** | S–M | Balanced; needs per-component rules and tests |

**Recommendation for your decision:** B2-c.
**Blocks:** F1–F5.

### B3. Responsive and 200% text behaviour

**Question:** Figma frames are fixed 390/1280 with tall HUG heights; some technician screens use absolute positioning. Do we rebuild them as responsive, scrollable layouts?

| Option | Cost | Consequence |
|---|---|---|
| **B3-a Responsive, scrollable, min-height, no fixed bottom pads** | M | Meets 200% and small-viewport requirements; visual match can drift from fixed-frame Figma |
| **B3-b Reproduce fixed frames exactly** | S | Highest static fidelity; fails text scaling/short screens |
| **B3-c Responsive for phone, fixed desktop** | S–M | Mixed; desktop must still handle zoom |

**Recommendation for your decision:** B3-a.
**Blocks:** F2–F5.

### B4. Focus and keyboard states on web

**Question:** The exports contain no focus/hover states. Do we define them centrally or rely on Material defaults?

| Option | Cost | Consequence |
|---|---|---|
| **B4-a Add focus-visible tokens and test keyboard paths** | S | Meets WCAG and gives a consistent web look |
| **B4-b Use Material defaults** | S | Works but visually inconsistent with the new design |
| **B4-c Defer** | S | Risks failing the accessibility gate |

**Recommendation for your decision:** B4-a.
**Blocks:** F3–F5.

### B5. Arabic/RTL design reference

**Question:** There are no Arabic or RTL frames. How do we verify Arabic fidelity and shaping?

| Option | Cost | Consequence |
|---|---|---|
| **B5-a Produce a small Arabic design pass for one representative screen per app before build** | M | Gives a real reference; catches bidi/mirroring early |
| **B5-b Implement directly with RTL lint + manual native review** | S–M | Faster; no Arabic pixel reference, so fidelity is manual only |
| **B5-c Defer Arabic** | S | Violates a locked requirement; not acceptable |

**Recommendation for your decision:** B5-a for the public report and technician; B5-b plus review for admin. Arabic cannot be claimed "Figma-faithful" without a reference.
**Blocks:** F1 acceptance and all Arabic gates.

### B6. Fix the pre-ticked consent bug independently?

**Question:** Current `job_detail_page.dart` starts consent with `granted = true` (a real defect) and the Figma shows pre-ticked consent. Do we fix this as a bug now, regardless of the redesign?

| Option | Cost | Consequence |
|---|---|---|
| **B6-a Fix now as a privacy bug, separate from F0/UI work** | S | Correct and auditable; may need release note |
| **B6-b Include in F2 consent redesign** | S | Delayed; leaves a live defect until then |
| **B6-c Leave as-is** | S | Not acceptable against "never pre-ticked" |

**Recommendation for your decision:** B6-a.
**Blocks:** independent; relevant to F2 acceptance.

---

## C. Features not in the product

### C1. Technician feature surfaces

**Question:** Which of these do we reject, defer, or approve as new feature work: 360 exterior wireframe, damage pins, photo annotation/markup, tyre PSI/tread capture, BLE/OBD/hardware pairing, customer e-signature, signature/GPS/ledger, fleet/profile tabs, swipe-only finalization?

| Option | Cost | Consequence |
|---|---|---|
| **C1-a Reject all** — do not build them in the UI phases | S | Preserves scope and immutability; Figma screens 05, 06, 08, 10, 13, 15 lose most of their content |
| **C1-b Defer to a named roadmap phase, not F1–F5** | S (now) | Keeps the option open; each item still needs its own product/data/legal case |
| **C1-c Approve selected items now** | L each | Requires model/DB/API/security/consent work; e-signature is explicitly excluded today; damage/tyre/annotation need new tables; hardware needs integrations |

**Recommendation for your decision:** C1-a for V1; C1-b for any item you want to keep as a future candidate. Do not mix them into a visual refresh.
**Blocks:** F2 (specific screens); F6 if approved.

### C2. Workshop/Platform feature surfaces

**Question:** Which of these do we reject, defer, or approve: workshop dashboard, staff management with skills/shifts/NFC, Workshop Admin account creation, workshop settings, template compliance metrics, print studio, platform settings, workshop create/update/disable, platform dashboard metrics, audit verify/export/ledger, equipment calibration/telemetry, master rules/OEM/sync?

| Option | Cost | Consequence |
|---|---|---|
| **C2-a Reject/defer all; restyle only existing screens** | S | Clear UI-only phase; Figma screens 02, 03, 05, 07, 09, 11, 12 (Workshop) and 03, 04, 10 (Platform) are not built as drawn |
| **C2-b Approve a subset as new feature phases** | M–L each | Needs DB/API/permissions/audit; some conflict with ADRs (RQ3, TOTP, immutable versioning) |
| **C2-c Treat all as UI and stub the data** | L + risk | Creates fake states, violates "no invented data", and breaks immutability |

**Recommendation for your decision:** C2-a; approve subsets separately if the business needs them.
**Blocks:** F3, F4; F6 if approved.

### C3. Public report feature surfaces (locked)

**Question:** The public export adds a portal shell, filters, acknowledgement/sign-off, quote request, approved/certified states, PDF/certificate downloads and internal audit IDs. Are any of these approved?

| Option | Cost | Consequence |
|---|---|---|
| **C3-a Remove all** — keep the read-only allowlisted report | S | Complies with D4/D8/allowlist and the "no customer portal" rule |
| **C3-b Reopen the locked rules** (portal, PDF, write actions) | L + legal/privacy review | Requires a new decision record and an ADR change; not a UI task |
| **C3-c Keep visual style only** — no new controls/semantics | S–M | Safe if copy and fields stay allowlisted |

**Recommendation for your decision:** C3-a. C3-c is only acceptable as a visual treatment of existing sections.
**Blocks:** F5.

### C4. Admin TOTP UI

**Question:** The PRD lists an Admin 2FA/TOTP screen, the export omits it, and ADR-0021 defaults `ADMIN_TOTP_REQUIRED=false`. Do we build it?

| Option | Cost | Consequence |
|---|---|---|
| **C4-a No TOTP UI while the flag is off; keep the conditional technician 2FA code field** | S | Matches ADR-0021; no new surface |
| **C4-b Build enrolment/recovery/verify screens behind the flag** | M | Useful if you will enable TOTP; needs recovery UX and audit |
| **C4-c Turn TOTP on by default and build the flow** | L | Security improvement but a policy change and support burden |

**Recommendation for your decision:** C4-a now; C4-b when you decide to enable admin TOTP.
**Blocks:** F4.

---

## D. Data-dependent screens

### D1. Scope of the UI-refresh subset

**Question:** Which screens are in the buildable subset?

| Option | Cost | Consequence |
|---|---|---|
| **D1-a Only screens that match existing data/API and survive the rule filter** (16 matched + safe parts of the 7 UI-only) | M | Buildable now; excludes ~19 screens |
| **D1-b All 45 after stripping forbidden copy** | L | 10 screens still need new data; some cannot be stripped without becoming empty shells |
| **D1-c Public report separately, then apps** | M | Safer sequencing; same total effort |

**Recommendation for your decision:** D1-a, with a per-screen allowlist in `build-plan.md`.
**Blocks:** F2–F5.

### D2. Bay / station / shift / fleet / profile

**Question:** The design shows bays, shifts, fleet and profile everywhere; none exist in the model. Show, derive, or omit?

| Option | Cost | Consequence |
|---|---|---|
| **D2-a Omit until modelled** | S | Honest UI; some layouts look emptier |
| **D2-b Add a new model/API** | L | New business concepts and multi-screen changes |
| **D2-c Hardcode sample values** | S | Violates "no invented data"; not acceptable |

**Recommendation for your decision:** D2-a.
**Blocks:** F2–F4.

### D3. Photos, avatars and vehicle hero images

**Question:** The exports use staff portraits, customer avatars and stock vehicle photos. Do we add them?

| Option | Cost | Consequence |
|---|---|---|
| **D3-a Omit; use initials/placeholders and evidence derivatives only** | S | No consent/licence risk; less "rich" look |
| **D3-b Add staff avatars with consent and storage** | M | New profile data, consent, file handling |
| **D3-c Add a generic brand vehicle hero image** | S | Safe only if it is not presented as the inspected vehicle; licence must be verified |

**Recommendation for your decision:** D3-a; D3-c only with a licensed generic brand image and clear labelling.
**Blocks:** F2–F5.

### D4. Measurements and hardware values

**Question:** PSI, tread mm, Nm, CCA, voltages, paint depth, BLE/OBD/NFC/telemetry appear throughout. Add a measurement model or omit?

| Option | Cost | Consequence |
|---|---|---|
| **D4-a Omit all unmodelled values** | S | Honest UI; tyre/annotation/equipment screens become much simpler |
| **D4-b Add structured measurement fields per item** | L | New schema, validation, units, public allowlist, PDF changes |
| **D4-c Free-text only** | S–M | Can record values as notes but cannot filter/chart/validate; still needs UI decisions |

**Recommendation for your decision:** D4-a for V1; if measurements are needed, D4-b with a separate feature phase.
**Blocks:** F2, F3, F5.

### D5. Public odometer, units and time zone

**Question:** Do we show odometer publicly (Pending in the allowlist), and in which unit/time zone?

| Option | Cost | Consequence |
|---|---|---|
| **D5-a Omit odometer in V1; show inspection time in workshop time zone (default Asia/Dubai/GST) and metric units internally** | S | Complies with current Pending status; avoids EST/mi errors |
| **D5-b Include odometer in km and GST** | S–M | Needs product-owner approval and allowlist update |
| **D5-c Include mile/EST samples from Figma** | S | Wrong for the product; not acceptable |

**Recommendation for your decision:** D5-a; D5-b only with explicit approval.
**Blocks:** F5.

### D6. Fidelity fixture data

**Question:** For pixel comparison, may we use the Figma sample strings in **test-only fixtures**, including fake PII/claims, or must fixtures be sanitized?

| Option | Cost | Consequence |
|---|---|---|
| **D6-a Test-only "fidelity fixtures" using Figma strings, never shipped, excluded from release bundles** | S–M | Best layout comparison; needs a build guard and secret/PII scanning |
| **D6-b Sanitized fixtures only** | S | Safer; text-width differences reduce pixel fidelity and must be documented |
| **D6-c No pixel comparison; review only** | S | No measured fidelity; fails the user's requirement |

**Recommendation for your decision:** D6-a with a hard release guard, or D6-b with measured text-width exclusions. Do not copy Figma strings into product data.
**Blocks:** F1/G1 harness, then F2–F5 gates.

---

## E. Public report and PDF

### E1. Information architecture

**Question:** Keep the current server-rendered report IA (header, summary/coverage, vehicle, key findings, category tables, not-checked, limitations, report details, footer) and apply the Figma visual language, or adopt the Figma portal-like IA?

| Option | Cost | Consequence |
|---|---|---|
| **E1-a Keep IA; visual refresh only** | M | Preserves allowlist and accessibility; Figma's mobile/desktop layouts can inform typography/cards |
| **E1-b Adopt Figma IA** | L | Adds forbidden/unsupported sections; would need new snapshot data and a rule change |
| **E1-c Hybrid: keep sections, redesign each within allowlist** | M | Best balance; some Figma elements (coverage ring, photo grid) still need care |

**Recommendation for your decision:** E1-a or E1-c.
**Blocks:** F5.

### E2. PDF download default

**Question:** Keep ADR-0008 (PDF control off by default), enable it with consent, or remove the PDF entirely?

| Option | Cost | Consequence |
|---|---|---|
| **E2-a Keep D8 off by default; gated flag only** | S | Current correct behaviour; Figma's download CTAs are removed |
| **E2-b Enable per approved policy** | M–L | Needs consent, signed URL/stream, rate limit, audit, revocation handling, legal review |
| **E2-c Remove the PDF product-wide** | M | Contradicts D5 (bilingual PDF is required) |

**Recommendation for your decision:** E2-a. Do not enable from a design screenshot.
**Blocks:** F5.

### E3. Coverage presentation

**Question:** Figma shows a 95% ring/score. Our product uses coverage counts and says "Coverage is not a condition score." What do we show?

| Option | Cost | Consequence |
|---|---|---|
| **E3-a Counts only** — applicable/completed/not applicable/not checked/could not verify | S | Safest; matches current renderer |
| **E3-b Counts + percentage labelled "inspection coverage", with the explicit disclaimer** | S–M | More visual, still not a condition score; needs a numeric percentage field |
| **E3-c Score/health/grade** | L + rule change | Forbidden; not acceptable |

**Recommendation for your decision:** E3-a or E3-b; E3-b only if the disclaimer stays adjacent.
**Blocks:** F5.

### E4. Public vehicle image

**Question:** The public hero uses a stock car photo. Do we add a vehicle/brand image?

| Option | Cost | Consequence |
|---|---|---|
| **E4-a No image** | S | Safe and fast; plainer page |
| **E4-b Licensed generic brand image, labelled as illustrative** | S–M | Needs a verified licence and must not imply it is the inspected vehicle |
| **E4-c Show an evidence derivative as the hero** | M | Needs an approved public photo, cropping/EXIF checks, consent; could expose a plate/face |

**Recommendation for your decision:** E4-a; E4-b only with a verified licence and label.
**Blocks:** F5.

### E5. Public hash / verification display

**Question:** The Figma shows "Verified", "tamper-proof" and three different SHA-256 values. Do we keep the existing factual snapshot hash?

| Option | Cost | Consequence |
|---|---|---|
| **E5-a Show the existing verification hash as "snapshot hash", no verification/certification claim** | S | Factual and consistent with the current report; no crypto overclaim |
| **E5-b Omit the hash** | S | Simpler; loses a factual integrity aid |
| **E5-c Add a verification seal/ledger UI** | M–L | Implies a PKI/ledger that does not exist; forbidden by "no certification/verified" |

**Recommendation for your decision:** E5-a or E5-b. Not E5-c.
**Blocks:** F5.

### E6. Public dark mode and print

**Question:** Current report supports a tested dark mode and print CSS; Figma is light-only. Keep dark?

| Option | Cost | Consequence |
|---|---|---|
| **E6-a Light-first public report; keep tested dark only if token parity is verified** | S–M | Print/readability safe; dark can be retained if re-tested |
| **E6-b Always light** | S | Simplest; users lose OS dark preference |
| **E6-c Keep both and re-test** | S–M | Best if the new palette is dark-ready |

**Recommendation for your decision:** E6-a.
**Blocks:** F5.

---

## F. Admin / Workshop / Platform

### F1. Shell and information architecture

**Question:** Adopt the Figma rails/dashboards/settings, or restyle the current Jobs/Staff/Templates and Hierarchy/Master/Audit shells?

| Option | Cost | Consequence |
|---|---|---|
| **F1-a Restyle current shell; add routes only when data exists** | M | No dead routes; current IA preserved |
| **F1-b Adopt Figma shell and leave dashboard/settings as empty states** | M | Visually closer; dead ends violate "no dead end" |
| **F1-c Adopt full Figma IA including new feature screens** | L | Requires C2 approvals and server work |

**Recommendation for your decision:** F1-a.
**Blocks:** F3, F4.

### F2. Workshop staff creation (RQ3)

**Question:** The Workshop Admin export includes "Add Staff / Create Account". ADR-0011/RQ3 says Platform Admin creates all accounts. Keep or change?

| Option | Cost | Consequence |
|---|---|---|
| **F2-a Keep platform-only; hide the workshop create-account UI** | S | Matches RQ3/ADR-0011; design screen 07 is dropped |
| **F2-b Revert RQ3 and allow workshop invitations** | L | Needs permission/API/audit/security review and a new decision record |
| **F2-c UI-only stub** | S | Misleading; not acceptable |

**Recommendation for your decision:** F2-a.
**Blocks:** F3.

### F3. Platform audit screen

**Question:** Restyle the read-only audit list, or add filter/export/verify/integrity-seal features?

| Option | Cost | Consequence |
|---|---|---|
| **F3-a Read-only restyle only; remove ledger/root-CA claims** | S–M | Matches append-only DB and current endpoint (`limit` only) |
| **F3-b Add filtering/paging/export** | M | Useful; needs an API change (currently `limit` only) |
| **F3-c Add PKI/blockchain verification** | L | Not supported by the data model; overclaim |

**Recommendation for your decision:** F3-a; F3-b as a separate feature if needed.
**Blocks:** F4.

### F4. Master content editing model

**Question:** Keep draft/version/publish (current, ADR-0014/0016) or adopt Figma's "Save Changes"/"Instant Push"/live sync?

| Option | Cost | Consequence |
|---|---|---|
| **F4-a Keep versioned draft/publish; remove in-place save and live push** | S | Preserves immutability and pinned templates |
| **F4-b Add a new version workflow UI only** | M | Still safe; more visible versioning |
| **F4-c In-place edit/live sync** | L | Breaks immutability/version pinning; not acceptable |

**Recommendation for your decision:** F4-a.
**Blocks:** F4.

### F5. Dropdown/equipment UI

**Question:** The APIs exist but have no screens. Build UI now or leave them API-only?

| Option | Cost | Consequence |
|---|---|---|
| **F5-a Build list/detail UI limited to existing fields** | M | Closes a real gap (P2); no new data |
| **F5-b Leave API-only** | S | No new UI; admin cannot manage these in-app |
| **F5-c Build the Figma equipment/calibration/telemetry UI** | L | Requires new data/features (C2) |

**Recommendation for your decision:** F5-a if you want the gap closed in F4; otherwise F5-b.
**Blocks:** F4 scope only.

### F6. Workshop report viewer and print preview

**Question:** Restyle the existing report viewer with its real link/PDF/delivery controls, or adopt the Figma certificate viewer/print studio?

| Option | Cost | Consequence |
|---|---|---|
| **F6-a Restyle the current viewer; keep state controls; remove certificate/signature layer** | M | Correct and consistent with public report/PDF |
| **F6-b Add print studio/preview settings** | L | Needs a new print pipeline/data; not UI-only |
| **F6-c Certificate-style viewer** | L | Conflicts with locked rules; not acceptable |

**Recommendation for your decision:** F6-a.
**Blocks:** F3.

### F7. Admin 2FA

See C4.

---

## G. Verification harness and acceptance

### G1. Fidelity metric and gate

**Question:** What is the acceptance metric for "matches the Figma"?

| Option | Cost | Consequence |
|---|---|---|
| **G1-a Structural + measured visual** — box geometry within a stated tolerance, exact tokens/strings, and screenshot SSIM/RMSE reported; residual diffs listed and accepted individually | M | Honest, testable, allows font/rendering differences; not "pixel-perfect" |
| **G1-b Strict pixel equality** | L | Unrealistic across Flutter/Chromium/font renderers; will fail on anti-aliasing |
| **G1-c Visual review only** | S | No measurement; cannot support a fidelity claim |

**Recommendation for your decision:** G1-a.
**Blocks:** F1 and every batch gate.

### G2. Reference renderers

**Question:** Which renderer produces the "Flutter/HTML" side of the comparison?

| Option | Cost | Consequence |
|---|---|---|
| **G2-a Flutter golden tests with bundled fonts at DPR 2 for apps; headless Chromium at 390/1280 for the public report** | M | Comparable to `@2x` exports; catches layout/type issues |
| **G2-b Browser screenshots only** | M | Misses native app states and Flutter text layout |
| **G2-c Manual screenshots** | S | Not reproducible; no diff metrics |

**Recommendation for your decision:** G2-a.
**Blocks:** F1–F5.

### G3. Acceptance thresholds

**Question:** What numbers pass a screen?

| Option | Cost | Consequence |
|---|---|---|
| **G3-a SSIM ≥ 0.98 and no unexplained diff region > 4 logical px; all residual diffs listed** | M | A measurable gate; still allows intended deviations |
| **G3-b SSIM ≥ 0.995** | M–L | Very strict; font/raster differences may make it unattainable |
| **G3-c Per-screen negotiated threshold** | M | Flexible but inconsistent; needs a baseline record |

**Recommendation for your decision:** G3-a as the starting gate; tighten per screen only after a baseline exists. Do not claim "pixel-perfect" unless a threshold is met and documented.
**Blocks:** F1–F5.

### G4. Arabic/RTL reference

See B5. There is no Arabic Figma frame, so no pixel gate is possible; the gate must be RTL lint + manual native-speaker review + 200% text.

---

## H. Locked rules — not decisions

The following are **already locked** and are not offered as choices. Any design that needs them must be rejected or returned for an explicit rule change with a new ADR.

1. Public report shows no customer name, phone, email, full VIN or plate.
2. No certification, "verified by" or compliance claims we cannot evidence.
3. No single unexplained condition score.
4. No manager role, review queue, customer app/portal or in-platform payments.
5. Finalized findings, evidence and reports are never editable.
6. No correction UI/API in V1 (D9/ADR-0007).
7. Public report is server-rendered HTML (D4); PDF is headless Chromium (D5); public PDF download is off by default (D8/ADR-0008).
8. Arabic RTL and WCAG 2.2 AA are requirements; colours/text/radii/spacing/endpoints come from central tokens/classes.
9. No invented versions, licences, measurements or results.
10. UI layer only in this workstream: no business logic, API contract, model, validation, permission, state or server change.

If you want to revisit any of these, it is a product/legal decision with its own ADR, not a design-intake task.
