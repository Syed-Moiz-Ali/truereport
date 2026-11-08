# F2-A.1 slot sheet — Figma elements that need an owner decision

**Project:** TrueReport
**Phase:** F2-A.1 (identical-first correction, technician screens 1–7)
**Date:** 6 November 2026
**Rule applied:** every visual element keeps the Figma slot, size, style, colour and
position. Only text or data that would be false or unsafe under locked product
rules may change. Where the owner has not decided, the default is **Option A**.
Nothing was silently removed. This sheet records what is currently rendered in
the product build and what still needs owner approval.

Legend: **A** = same-slot neutral replacement (implemented by default),
**B** = real data of the same shape, **C** = hide (not used unless unsafe and no
neutral form exists).

| Screen | Element and Figma text | Problem (rule / data gap) | Option A (same slot, neutral) | Option B (real data, same shape) | Option C (hide) | Recommendation / status |
|---|---|---|---|---|---|---|
| 01 Login | `TechInspect` wordmark | Other brand. I6 says use TrueReport in the same slot/style | **TrueReport** at the same title metrics | n/a | Hide mark | A implemented (I6) |
| 01 Login | `Vehicle Condition & Fleet Diagnostics` | Harmless description; kept as drawn for fixture (a) | Keep text | Localised tagline | Remove | Keep. Product copy uses the existing localised tagline; the Figma string is test-only |
| 01 Login | Minimal logo mark | Figma mark belongs to another brand and the frame is empty | **TR** monogram in the same 64×64 slot with the same blur glow | Our official mark when supplied | Hide mark | A implemented; owner to supply final mark |
| 01 Login | `Forgot password?` | No password-reset endpoint; the link would be dead | **Password help** in the same 11/14 slot (non-interactive) | Real reset flow | Remove | A implemented; owner to decide whether to fund reset |
| 01 Login | `Need technician access? Request ID` | No self-service request-ID endpoint | **Need technician access? Contact Admin** in the same row/style | Real request-ID flow | Remove | A implemented |
| 01 Login | `ISO 27001 Certified Fleet Security` | Certification claim is not true for this product | **Authorised workshop staff only** (J3) with the same shield icon/style/position | Evidence-backed security claim | Remove | A implemented (J3); ISO text removed from the fixture and product |
| 02 Jobs | Profile photo | No consent/asset for a sample person | **Initials avatar** in the same 32 px circle (`DV`) | Real technician photo with consent | Hide | A implemented |
| 02 Jobs | `LIVE SYNC` | Offline-first product; no live-sync state/timestamp | **ONLINE/OFFLINE SYNC** derived from connectivity in the same two-line pill | Real sync receipt | Remove | A implemented |
| 02 Jobs | `SHIFT 1 • BAY A` | No shift or bay fields | **TODAY • {n} JOBS** in the same pill | Real shift/bay fields (API change) | Remove | A implemented |
| 02 Jobs | `45 min / Avg. turnover` | No turnover data | **In progress count** in the same card | Real average turnover | Remove | A implemented |
| 02 Jobs | Plate / bay meta (`ABC 123 • Bay 4`) | No bay field; plate is not needed on the queue | **Job reference** (+ plate when present) in the same line | Reference + bay from API | Remove | A implemented |
| 02 Jobs | `Scan New VIN Tag` | VIN scanning is deferred | **Walk-in job** with the same primary button shape/position and a tool icon | Real VIN scan | Remove | A implemented |
| 02 Jobs | Dock `Fleet` | No fleet feature | **Finalized** jobs list from existing finalized jobs (I4 candidate) | Real fleet module | Remove 4th slot (breaks Figma dock) | A implemented behind the Fleet slot; **owner must approve the mapping** |
| 02/03 | Sample people/jobs (`David Vance`, `Renault Megan 3`, plates) | Sample data are not real | Real technician/job data in the same slots | Live data (already used in product) | n/a | Product uses real data; Figma samples are fixture-only |
| 03 Empty | `SHIFT ACTIVE` | No shift field | **QUEUE EMPTY** status pill | Real shift state | Remove | A implemented |
| 03 Empty | `Bay 04` | No bay field | **0 JOBS** pill | Real bay | Remove | A implemented |
| 03 Empty | `Queue is current • Synced just now` | No sync receipt timestamp | **All changes synced / N pending sync** derived from queue | Real sync receipt | Remove | A implemented |
| 03 Empty | `TODAY'S SUMMARY`, `14 Completed` | Daily aggregate is not modelled | Real finalized-today count when supplied, otherwise 0 | Real daily aggregate | Remove strip | A implemented; page passes the real count when available |
| 03 Empty | `100% Pass Rate` | Forbidden single score / “pass” wording | **Coverage** (no score) in the same slot/style | Coverage counts (I1/E rules) | Remove | A implemented |
| 04 Intake | Vehicle hero photo | No provenance/consent for a sample vehicle | **Vehicle-type silhouette** in the same 350×176 card with the same overlay/plate/model slots | Real vehicle photo captured for this job | Remove hero | A implemented |
| 04 Intake | `REG: LV71 XZP` | Sample plate | **Real plate or reference** in the same pill | Real plate | Remove pill | A implemented |
| 04 Intake | `INTAKE PHASE` | Phase not modelled | **Real status** in the same pill | Real intake phase | Remove | A implemented |
| 04 Intake | `Ready for Check` | Readiness not modelled | **Real status** in the same green pill | Real readiness | Remove | A implemented |
| 04 Intake | `10:42 AM • Bay 3` | Bay not modelled | **Scheduled time (UTC+4)** in the same slot | Time + bay | Remove | A implemented |
| 04 Intake | `Primary Owner` chip | Owner relationship not modelled | **Customer** chip in the same slot | Real owner type | Remove | A implemented |
| 04 Intake | Call / message buttons | No call/SMS endpoint in V1 | Same icons, non-interactive, semantic labels | `tel:`/SMS deep links | Remove | A implemented (icons kept, no false action) |
| 04 Intake | Scan icon | VIN scanning is deferred | **Copy VIN** action in the same 32 px slot | Real scan | Remove | A implemented (copy icon) |
| 04 Intake | `Keys received • Fuel at 70%` | Not modelled and fuel percentage is invented | **Status • template version** in the same lines | Real checks/fuel | Remove | A implemented |
| 04 Intake | `Step 1 of 4` | Step count not modelled | **Template version / Inspection** in the same slot | Real step flow | Remove | A implemented |
| 05 Consent | `Allow PDF sharing` | Only PUBLIC_LINK consent exists; PDF delivery consent is separate | **Public report link** consent card in the same slot | PDF-delivery consent | Remove | A implemented |
| 05 Consent | `Customer road test consent` | Road-test consent not modelled | **Processing consent** card in the same slot | Road-test consent | Remove | A implemented |
| 05 Consent | `Data storage authorization` | Not modelled | **Data storage** card with a disabled, unticked switch | Real storage consent | Remove | A implemented (visible, disabled, no record) |
| 05 Consent | Signature pad + sample stroke + `Recorded` badge | No signature capture in V1 | **Consent decision** in the same 350×176 box, with explicit Granted/Refused and “No signature captured” | Real signature capture | Remove signature area | A implemented; owner to confirm signature is out of scope |
| 05 Consent | `Timestamp: Today, 14:38 EST` | Wrong time zone (UAE) and no record before save | **Timestamp: Not recorded yet** in the same line | Real UTC+4 timestamp after save | Remove | A implemented |
| 05 Consent | `Alex Lindqvist / Authorized Representative • VIN 4782` | Sample person/VIN | **Authorized representative / not recorded** with status in the same card | Real signer/customer | Remove | A implemented |
| 06 Equipment | Equipment names/specs (`Tire Depth Gauge`, `OBD Scanner`, …) | API returns `equipmentIds` only | **ID + “Name unavailable”** in the same card slots; no invented names in the product | Names/specs from API change (proposed fields in `f2a1-audit-06-equipment.md`) | Empty list | A implemented; screen 6 remains blocked by the data gap |
| 06 Equipment | `1 of 4 Verified`, green checks | Verification/pairing not modelled | **N items** pill; all status circles unticked | Real verification/pairing state | Remove status | A implemented |
| 06 Equipment | `ISO-9001 certified diagnostic requirements` | Certification claim | **Workshop equipment standards** / availability confirmed by workshop | Evidence-backed standard | Remove | A implemented |
| 07 Hub | `Bay #04 • VIN 8492` | No bay; VIN fragment should not be treated as data | **Job reference • template version** in the same slot | Reference + bay | Remove | A implemented |
| 07 Hub | `42 Passed` | “Pass” is not product vocabulary and implies a score | **N no issue observed** in the same pill | Result counts | Remove | A implemented |
| 07 Hub | `3 Action Items` | Not the product vocabulary | **N attention** in the same pill | Real findings count | Remove | A implemented |
| 07 Hub | Vehicle photo + plate/VIN | No provenance; plate/VIN privacy | **Car icon + real reference/odometer** in the same strip | Real photo with consent | Remove strip | A implemented |
| 07 Hub | `Active Bay` | No bay field | **In progress** label in the same line | Real bay | Remove | A implemented |
| 07 Hub | Fixed `45/110` ring and sample model | Sample values | **Real completed / total coverage** in the same ring; real vehicle data | Live data | Empty state | A implemented |
| 07 Hub | Dock `Fleet` | No fleet feature | Same mapping as screen 2: **Finalized** list | Real fleet module | Remove | A implemented; owner approval required |

## Decisions the owner must make

1. Approve or replace the **Fleet → Finalized** dock mapping (I4). This is the only
   place where the Figma label is not the product label.
2. Approve the **Forgot password / Request ID** neutral replacements, or fund the
   real flows.
3. Approve the **secure delivery** footer wording (or supply an evidence-backed
   security claim).
4. Confirm signature capture stays out of scope (the signature slot now holds the
   explicit Granted/Refused decision).
5. Approve the **equipment API extension** (names/specs/state) or accept screen 6
   with IDs only.
6. Supply the final **TrueReport logo mark** if the current TR monogram should be
   replaced.

---

## F2-A.2 owner outcomes (6 November 2026)

| Item | Outcome |
|---|---|
| Fleet dock slot | **J1 approved:** maps to existing **Finalized** jobs; Figma icon/position kept. |
| Password help / Contact Admin | **J2 approved:** neutral replacements kept in the same slot/size/style. |
| ISO security line | **J3 approved:** replaced by **“Authorised workshop staff only”** in the same slot/icon/size/style; no security or certification claim. Product forbidden-term lint passes. |
| Signature | **J4 approved:** stays out of scope; the decision slot holds explicit Granted/Refused. |
| Equipment names | **J5 approved:** read-only API extension returns labels/code/status/sortOrder from master equipment. No schema/write/permission change. |
| Logo slot | **J6 approved:** soft green glow only, no solid TR tile. Export JSON contains an empty `TechInspect Minimal Logo` frame (`1:7090`, x163 y104, 64×64) with no vector/raster asset; the preview shows only the glow. |
| Figma photos/avatars | **J7 approved:** used only in test-only fixtures; decoded at runtime from `docs/ui/figma-export`; not in any pubspec asset list and guarded by `f2a2_asset_guard_test.dart`. |