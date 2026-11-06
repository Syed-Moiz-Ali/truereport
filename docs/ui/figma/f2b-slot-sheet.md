# F2-B.1 slot sheet — Figma elements that cannot be shown as drawn

**Project:** TrueReport
**Phase:** F2-B.1 (identical-first correction, technician Figma screens 9, 11, 13, 14, 15, 16)
**Date:** 6 November 2026
**Rule applied (owner decision L8):** every Figma element keeps the Figma slot, size,
style, colour and position. Only text or data that would be false or unsafe under
locked product rules may change, and the change is a **same-slot neutral replacement
in the exact style** — never a hide, unless the element is unsafe and has no neutral
form. Where the owner has not decided, the default is **Option A**.
Nothing was silently removed. This sheet records what is currently rendered in the
product build (`client/apps/technician_app/lib/src/screens/f2b/*.dart`) and what
still needs owner approval.

**Screen numbering:** this sheet uses Figma screen numbers (9, 11, 13, 14, 15, 16).
Export folders are off by fixed offsets for three screens — folder `12_13` = Figma
screen **13** Final Review, folder `14_15` = Figma screen **15** Offline Sync Queue,
folder `15_14` = Figma screen **14** Finalize & Approval. Folders `09_9`, `11_11`,
`16_16` match their Figma screen numbers.

**Implemented baseline (existing handling, kept):**
- Screen 9 keeps the Figma three-way pill toggle geometry exactly (`F2bSegmented`,
  52 px track / 40 px options); labels are the 3 main ARB result codes with a
  secondary chip row for the other 3, plus the 4-severity chip row
  (`MINOR/MODERATE/MAJOR/SAFETY_CRITICAL`). Screen 11 does the same per card.
- Screen 14 keeps the Figma 64 px slide track + 52 px emerald thumb exactly
  (`F2bSlideToConfirm`); the same action is additionally exposed as an invisible
  semantic button / keyboard `ActivateIntent` with no visible change.
- Screen 16 shows the real report (`TechnicianReportStatus`) + real delivery
  records (`TechnicianDelivery`), never hardcoded Sent/Synced.
- Finalize summary card keeps the Figma VIN line slot; full VIN is shown only in
  that internal slot, everywhere else last-4.

Legend: **A** = same-slot neutral replacement (implemented by default),
**B** = real data of the same shape, **C** = hide (not used unless unsafe and no
neutral form exists).

| Screen | Element and Figma text | Problem (rule / data gap) | Option A (same slot, neutral) | Option B (real data, same shape) | Option C (hide) | Recommendation / status |
|---|---|---|---|---|---|---|
| 09 Defect (`1:8021`, folder `09_9`) | `BAY 04 • IN PROGRESS` pill (`1:8030`) | No bay field; job reference/status exist | **`{reference} • {localized status}`** in the same 178×22 pill with emerald dot | Reference + bay from API change | Remove pill | A implemented (`defect_detail_view.dart` `_ContextHalf`) |
| 09 Defect | `PIN #03` label (`1:8056`) | Pin index is a UI construct; no defect-pin model | **Category/item context label** (same pill: `technicianInspection`) in the same slot | Real pin model per panel | Remove label | A implemented; owner to confirm pin model is out of scope |
| 09 Defect | `INSPECTION STATUS: Pass / Minor / Major` (`1:8075–1:8080`) | Merges result + severity; `Pass` is forbidden wording for `NO_ISSUE_OBSERVED` | **Same-geometry three-way pill with the 3 main ARB results** (`No issue / Attention / Defect`) + secondary chip row for `NOT_CHECKED / COULD_NOT_VERIFY / NOT_APPLICABLE`; severity stays a separate 4-chip row | n/a (ARB set is fixed) | Hide toggle (breaks Figma) | A implemented; Figma geometry kept exactly |
| 09 Defect | `DEFECT CLASSIFICATION: Dent / Crease, Surface Scratch, Paint Chip; 1 Selected` (`1:8088–1:8095`) | No defect-type taxonomy or endpoint | **Severity chips only** in the same slots (no invented damage-type taxonomy); no `1 Selected` count unless a real selection exists | Master defect-type taxonomy + endpoint (new data/server change) | Remove section | A implemented (severity row); **owner to approve taxonomy or accept omission** |
| 09 Defect | Damage type detail (dent vs crease vs chip distinction) | Same as above; product has result + severity + note only | Same-slot severity + note; no damage-type claim | Taxonomy + per-defect record | Remove | A implemented |
| 09 Defect | `Cosmetic / Structural` nature tags (Figma-wide defect nature taxonomy) | No cosmetic/structural field in `InspectionItem`/assessment | **No nature tag rendered**; severity + result carry the meaning in the same slots | New `damageNature` master field + API | Hide (current) | A implemented (= not rendered); **owner to approve or reject a new nature field** |
| 09 Defect | `P0 / P1 / P2 / P3` priority labels (Figma-wide) | Product severities are `MINOR / MODERATE / MAJOR / SAFETY_CRITICAL`; P0–P3 is not the product vocabulary | **ARB severities** (`Minor / Moderate / Major / Safety critical`) in the same chip slots | Rename product severities to P0–P3 (locked-vocabulary change, not recommended) | Remove severity | A implemented |
| 09 Defect | Repair tags (`Tagged` badge `1:8111`; repair-tag copy family) | No per-photo tag/annotation field | **Evidence tile shows capture state** (`attachments` / `addPhoto` + timestamp) in the same 167×167 slots; no `Tagged` claim | Per-photo tag/annotation model + `EvidenceController` extension | Remove badge | A implemented (tile + status pill carry real state) |
| 09 Defect | `1 of 4 Required` (`1:8101`) | Hardcoded count; must come from template | **`{photos.length} / {minPhotos \|\| 1}`** derived from `item.minPhotos` in the same slot | n/a (already real) | Remove count | A implemented |
| 09 Defect | Note hint `Add defect notes (e.g. 2.5cm door ding)...` (`1:8125`) | **Invented measurement example** (`2.5cm`); must never ship | **Localized `note` hint** with no measurement example, same 13 px slot | Approved neutral example text | Remove hint | A implemented (`F2bNoteField` with `l10n.note`) |
| 09 Defect | Defect `mm length` measurement family (length/size inputs implied by annotation flows) | No length/size field; inventing a value is forbidden | **No length field rendered**; note carries free text in the same note slot | New calibrated measurement field + unit/locale rules | Hide (current) | A implemented (= not rendered); **owner to fund or reject measurement capture** |
| 09 Defect | Blurred wireframe + 40 px pin (`1:8036–1:8053`) | No wireframe/illustration consent issue, but no pin model | **Neutral vehicle silhouette** in the same 350×256 card with the same overlay/status-pill slots | Real panel wireframe per job | Remove visual | A implemented (`TechnicianVehicleSilhouette`) |
| 09 Defect | Help `?` button (`1:8031`) | No help endpoint | Same 48 px circular slot, non-interactive, semantic label only | Real help flow | Remove | A implemented |
| 11 Dense (`1:8220`, folder `11_11`) | `INSPECTION ZONE 04` (`1:8227`) | No zone entity; categories exist | **Real category label uppercased** in the same 12/16 slot | Zone entity + API | Remove kicker | A implemented |
| 11 Dense | `3 of 6 checkpoints logged` (`1:8229`) | Hardcoded sample count | **`{completed} {checksDone} / {total}`** computed in the same slot | n/a (already real) | Remove count | A implemented |
| 11 Dense | `Live Bay #2` pill (`1:8233`) | No bay field | **Job reference pill** with emerald dot in the same 104×26 slot | Reference + bay from API | Remove pill | A implemented |
| 11 Dense | `Dipstick at optimal line • 5W-30 synthetic` (`1:8246`) | **Invented oil-grade/measurement copy**; no description field of this kind | **Real master instruction text** (`instructionEn/Ar`) in the same 13/18 slot; nothing invented | Approved fluid-spec library + API | Remove line | A implemented |
| 11 Dense | `Coolant / Expansion reservoir inspection`, `Transmission Fluid / Sealed system…`, `Washer Fluid / Topped to max…` descriptions | Labels are real; detail copy is sample/instruction text | Real instruction text where present, else label only | Master instruction library | Remove detail | A implemented |
| 11 Dense | `DOT 4 standard • Reservoir visual` (`1:8293`) | **Specification claim** that must not be invented | Real instruction text in the same slot | Approved spec library | Remove | A implemented |
| 11 Dense | `Normal / Low / Critical` level selector (`1:8264–1:8269`) | Not a product result vocabulary | **Same-geometry three-way pill with the 3 main ARB results** + secondary row (identical pattern to screen 9) | New level-threshold model + master rules | Hide selector | A implemented; Figma 40 px track geometry kept |
| 11 Dense | `Pass / Marginal / Fail` compact toggle (`1:8298–1:8303`) | `Pass/Fail` labels violate the approved result vocabulary | Same-geometry pill with ARB results in the same 36 px track | Vocabulary change (not recommended) | Hide | A implemented |
| 11 Dense | `ACTIVE` chip (`1:8262`) | No such server state; accordion UI state only | Chip slot reused only when a card is expanded (no fake server state implied) | Real item-state field | Remove chip | A implemented (expansion is local UI state) |
| 11 Dense | `Enter fluid level / notes` (`1:8273`) | Placeholder only; levels not modelled | Localized `note` hint in the same filled textarea | Level model + thresholds | n/a | A implemented |
| 11 Dense | `Take Photo` + barcode icon button (`1:8275–1:8282`) | Inline capture exists via `AssessmentPage`; **barcode/diagnostic-attach implies BLE/hardware pairing that does not exist** | Same 48 px primary + 48 px tonal slots: photo opens the item assessment, second button opens the same item (no fake pairing claim) | Real diagnostic-attach endpoint + BLE scope | Remove barcode button (breaks Figma rhythm) | A implemented; **owner to confirm no BLE implication is drawn from the icon** |
| 11 Dense | `Confirm Fluid Levels` CTA (`1:8337`) | No zone-level confirm endpoint; save is per item | **Same 56 px pill slot labelled with the real next step** (`reviewAndFinalize`) | Zone-confirm endpoint + per-item validation gate | Remove dock | A implemented (`onContinue` → review) |
| 13 Review (`1:8349`, folder `12_13`) | `STEP 4 OF 4 • VALIDATION` (`1:8355`) | No step model in technician app | **`reviewAndFinalize` kicker** in the same 12/16 slot | Step model + API | Remove kicker | A implemented |
| 13 Review | `3 Action Items` red chip (`1:8358`) | Sample count | **`{blocking.length} {missingItems}`** computed in the same chip | n/a (already real) | Remove chip | A implemented |
| 13 Review | Intro `Resolve outstanding compliance requirements before submitting the digital work order.` (`1:8362`) | **Compliance / work-order claim**; product says inspection, not compliance certification | **Approved limitation copy** (`finalizeIrreversible`) in the same 14/20 slot | Evidence-backed compliance wording (owner-supplied) | Remove intro | A implemented |
| 13 Review | Banner `3 Mandatory Photos Missing` + body `Customer sign-off & quality assurance mandate verified optical documentation…` (`1:8371–1:8373`) | Invented policy wording; `EVIDENCE_PENDING_5B` is non-blocking in 5A; photos/signature gate is a validation change | **Same 32 px-radius banner slot with real blocking count + approved limitation copy** | Server validation change making photos/signature blocking + signature capture | Remove banner | A implemented; **owner to decide the finalization gate (photos/signature blocking?)** |
| 13 Review | Badge numerals `1 2 3` (Nimbus Sans Bold outlier `1:8377–1:8383`) | Font outlier; counts derived | Real 1-based index numerals in Plus Jakarta Sans in the same 24 px badges | n/a | Remove badges | A implemented (`_IssueRow` index) |
| 13 Review | `MANDATORY RESOLUTION ITEMS` (`1:8389`) | No such section in `review_page.dart` | Localized `missingItems` label in the same 12/16 slot | n/a | Remove label | A implemented |
| 13 Review | Row 1 `Brake Fluid / Chassis / Reservoir moisture gauge & test strip` | Label/category real; detail invented | **Real `label ?? code` + `detail ?? code`** from `ReviewIssue` in the same slots | Master detail library | Invent detail (forbidden) | A implemented (never invent detail) |
| 13 Review | Row 2 `Tread Photo / Front Left / 3/32" depth indicator macro verification` | **Invented tread measurement + inch unit** (conflicts with metric path); no tyre model | Real issue label/detail; no measurement rendered | Tyre model + calibrated gauge + unit rules | Remove row | A implemented; tyre capture stays out unless owner funds it |
| 13 Review | Row 3 `Signature / Required / Digital advisor & vehicle owner sign-off` | No signature/consent gate in review; invents a role + workflow; no customer app | Real blocking issue if the server sends one, else row absent; same card slot | Signature capture scope + consent model | Remove row | A implemented (server-driven only) |
| 13 Review | Metadata `28 Verified Data Points / Powertrain, OBD-II & exterior scans passed / 91% Complete` (`1:8455–1:8459`) | **Invented count, OBD scan claim, ambiguous %** (coverage vs condition score; single unexplained score forbidden) | Same 32 px card slot with **real `completed / total` + explicit `%` labelled as coverage** | OBD integration + verified-points definition | Remove card | A implemented; **no `Pass`/score wording** |
| 13 Review | `pass-rate / %` family (`91%`, `33% completed`, `38 / 38`, `100% Pass`-style copy anywhere) | % must never read as a condition score | **Coverage % only** (`completed/total`), same slots, never labelled Pass/verified-score | Coverage definition sign-off | Remove % | A implemented |
| 13 Review | Disabled CTA `Resolve to Continue` + helper `All 3 critical checklist items must be resolved to unlock client sign-off.` (`1:8465–1:8467`) | `critical / client sign-off` wording invents severity + role | Same 56 px CTA + helper slots with **`reviewAndFinalize` + `finalizeIrreversible`** (disabled until `review.ready && blocking.isEmpty`) | Approved gate copy | Remove helper | A implemented |
| 15 Sync (`1:8633`, folder `14_15`) | `Sync Status` + `Local Engine v4.2 • Background sync` (`1:8643–1:8645`) | **Invented engine version**; never invent versions | Real title (`technicianSyncTitle`) + real connectivity line (`allSynced` / `offlineBanner`) in the same slots | n/a | Remove version line | A implemented |
| 15 Sync | `No Signal` chip (`1:8650`) | No connectivity enum; only online/offline derived state | **ONLINE/OFFLINE SYNC** derived from connectivity in the same 40 px chip | Connectivity enum | Remove chip | A implemented |
| 15 Sync | Offline banner + `Store Active` chip + body `All high-res vehicle capture tags and inspection checkpoints are safely cached…` (`1:8652–1:8664`) | `capture tags` model does not exist; cache claim overstates | Same amber card slot with **real `offlineBanner` / `pendingSync` / `syncComplete` copy** | Tag model + storage accounting | Remove banner | A implemented |
| 15 Sync | `BUFFERED CACHE 148.6 MB Local` (`1:8670–1:8676`) | **Invented byte value**; no storage-size provider | Same KPI card slot with **real `pendingCount` + items label** | Storage-size provider | Remove card | A implemented (`_StatCard` with real counts) |
| 15 Sync | `PENDING BATCH 3 Inspections / Awaiting link` (`1:8680–1:8687`) | Count vs operations mismatch (`Inspections` ≠ operations) | Same card slot with **real pending-operations count + distinct job count** | Pending-definition sign-off | Remove card | A implemented |
| 15 Sync | `Upload Queue / Auto-retry paused` (`1:8692–1:8694`) | Contradicts exponential-backoff design; `paused` is a new state | Same header slot with **real online/pending state** (no fake paused claim) | Paused-state feature + resume control | Remove label | A implemented |
| 15 Sync | Active card `Uploading Evidence Photos (4/12) / Job #IN-88912 • 2024 Ford F-150 Lightning / Standby / 33% completed / 8 items remaining / Transfer Speed 0.0 KB/s / Pending Jobs 2 in Line` (`1:8703–1:8735`) | **Invented batch counts, %, speeds, job refs**; no bytes/speed/progress totals in `SyncOperation`; `Standby` is not a product state | Same card slots with **real operation type + `jobId` + localized state pill** (`pending/conflict`); no %, no speed | Bytes/speed/progress model + sync protocol change | Remove card | A implemented (per-operation rows) |
| 15 Sync | Queued rows `Telemetry Telematics & Checkpoints 18.4 MB / Body Schematics Pin Markups 6.2 MB / Queued` (`1:8743–1:8765`) | **Invented job titles, sizes, features** (telematics / pin markups do not exist) | Same 32 px row slots with **real `attachments` / `saveAnswer` + `Jobs • jobId` + real state** | Feature + size accounting | Remove rows | A implemented |
| 15 Sync | `Retry Sync Now` + `Device will ping master servers every 60 seconds` (`1:8772–1:8774`) | Fixed-interval claim contradicts backoff; `master servers` wording | Same 56 px CTA (`syncNow`) + real pending-state note in the same slots | Retry-policy sign-off | Remove note | A implemented |
| 15 Sync | Bottom nav `Intake / Fleet / Sync / Profile` (`1:8789–1:8808`) | **Navigation mismatch**: no Fleet/Profile surface; documented tabs are Jobs/Sync/Settings | **No floating nav rendered**; route back-stack kept (no fake tabs) | Navigation IA change + design review | Render fake tabs (forbidden) | A implemented (= not rendered); **owner to approve IA if Fleet/Profile are desired** |
| 14 Finalize (`1:8809`, folder `15_14`) | `INSPECTION STEP 4 OF 4` pill (`1:8817`) | No step model | Same pill slot with `reviewAndFinalize` kicker | Step model | Remove pill | A implemented |
| 14 Finalize | Intro `Review verified points and sign off to dispatch fleet records.` (`1:8821`) | `sign off / dispatch` implies approval + delivery | Approved limitation copy (`finalizeIrreversible`) in the same slot | Approval/dispatch scope | Remove intro | A implemented |
| 14 Finalize | Vehicle `2024 Ford Transit 350` + `VIN • 1FTBR1Y85RKB92104` (`1:8831–1:8833`) | Full VIN is allowed internally but must never reach public report/logs/shares | **Full VIN kept only in this internal finalize-card slot** (LTR, single line); public surfaces use last-4 | Masked-VIN component everywhere (owner option) | Remove VIN | A implemented with privacy constraint; **owner approved full-VIN-in-this-slot only** |
| 14 Finalize | `Bay #04` chip (`1:8835`) | No bay field | **Real plate pill in the same slot when a plate exists, else omitted** (no fake bay) | Bay field + API | Remove chip | A implemented |
| 14 Finalize | `104 Checks Completed / 2 Defects Found` KPI tiles (`1:8844–1:8855`) | Sample counts; standalone defect count can read as a condition score | Same tiles with **real `review.completed` + real flagged-findings count labelled as findings** | n/a (already real) | Remove tiles | A implemented |
| 14 Finalize | Technician `Marcus Vance / Lead Fleet Specialist • ID #8842` + avatar photo (`1:8859–1:8867`) + `Today 14:48 PST` | **PII photo + invented role/ID**; timezone must come from workshop, not device | Same row slots with **signed-in technician display name (or `notProvided`), initials disc (no photo), job reference**; no role/ID claim; no PST hardcode | Role/ID directory + avatar consent + timezone rule | Remove row | A implemented (`_initials` disc) |
| 14 Finalize | Verified tick (emerald check next to technician name `1:8865`) | Tick must not imply certification/manager approval | Same 14.67 px slot kept as a **completion check** next to the real assignee name (no approval meaning) | Approval workflow (not in scope) | Remove tick | A implemented; **owner to confirm tick never means approval** |
| 14 Finalize | Vehicle photo raster 302×144 + `Odometer: 14,820 mi` chip (`1:8874–1:8878`) | **No provenance/consent for a sample vehicle photo**; `mi` unit + value are sample | Same 144 px media slot with **neutral silhouette + real `odometer: value unit`** chip | Real per-job photo with consent | Remove photo | A implemented (silhouette + real odometer or `notProvided`) |
| 14 Finalize | `Flagged Items Summary / Requires Follow-up` + rows `Front Left Tire Tread Depth — Measured at 3/32 in.… / Rear Cargo Door Latch — Minor resistance…` (`1:8883–1:8906`) | `3/32 in.` is an invented measurement with a conflicting unit; flagged rows must derive from findings | Same card/row slots with **real flagged items (result `DEFECT_FOUND`/`ATTENTION_RECOMMENDED`) + real note or result label**; never invented | Tyre/condition model | Invent text (forbidden) | A implemented |
| 14 Finalize | Disclaimer `By completing this inspection, technician confirms vehicle condition complies with fleet standards. Digital signature and GPS coordinates will be permanently appended to Fleet Ledger #2024-FLT-0982.` (`1:8909`) | **Compliance claim + invented signature/GPS/ledger + external reference**; GPS collection is not implemented and is privacy-sensitive | Same centered 13 px block with **approved limitation copy** (`finalizeIrreversible`) | Compliance text + signature scope + GPS privacy review + ledger integration | Remove block | A implemented; **owner must supply any replacement legal copy** |
| 14 Finalize | `Slide to Finalize Inspection` swipe dock (`1:8912–1:8919`) | Gesture-only irreversible action fails a11y without an alternative | **Figma slide kept exactly** (64 px track, 52 px thumb) **plus an invisible semantic button + keyboard activation on the thumb** that calls the same idempotent finalize | n/a | Button-only (breaks Figma) | A implemented (`F2bSlideToConfirm`) |
| 16 Success (`1:8931`, folder `16_16`) | `SERVICE SESSION #1042` (`1:8937`) | No service-session entity | **Real job reference uppercased** (LTR) in the same 11 px slot | Session entity | Remove line | A implemented |
| 16 Success | `Locked & Signed` chip (`1:8939`) | `Signed` invents a signature/consent event | **Real `finalized` / `inProgress` ARB chip** in the same 120×22 slot | Signature/consent record | Remove chip | A implemented |
| 16 Success | `Inspection Finalized` heading | Must appear only after server `FINALIZED` | Same 26 px heading, rendered from real `job.status == FINALIZED` | n/a | n/a | A implemented |
| 16 Success | `Report #1042 has been locked and uploaded.` (`1:8947`) | Conflates finalization + report generation + delivery; report generation is async | Same subheading slot with **real `reportStatus: generationStatus` state or `reportUnavailable`** | Report-ready copy sign-off | Remove subheading | A implemented; see raw-status mapping below |
| 16 Success | Delivery card `WhatsApp / Sent` + `Fleet Portal / Synced` (`1:8949–1:8971`) | `Fleet Portal` channel does not exist; `Sent/Synced` were hardcoded successes | Same 32 px card + row slots with **real `TechnicianDelivery` channel + server status** (max 2 rows; `noDeliveries` empty state) | Fleet Portal integration (future) | Remove card | A implemented; **Fleet Portal must not appear until implemented** |
| 16 Success | Unlocalized raw statuses `SENT / FAILED / DEAD_LETTER / DELIVERED` + raw `generationStatus` (e.g. `READY`) | Raw codes are not localized and `generationStatus` is shown verbatim | **Map to ARB labels in the same slots**: delivery success = `SENT/DELIVERED` tone, failure = `FAILED/DEAD_LETTER` danger tone; report line uses `reportStatus` ARB label + localized state (never raw code alone) | New ARB keys if owner wants per-state copy (ARB set currently fixed) | Show raw codes (forbidden) | A implemented in tone + channel rows; **owner to confirm per-state ARB wording** |
| 16 Success | Metadata `VIN ENDING ·8492 / ITEMS VERIFIED 38 / 38 / PDF SIZE 2.4 MB` (`1:8976–1:8990`) | `38/38` sample; `VERIFIED` overstates; **PDF size field does not exist**; VIN-ending is the right privacy posture | Same 48 px strip with **real last-4 (`·{vinEnding}` or `notProvided`), real `completed / total` labelled `completedItems`, real report `v{version}`** (no size claim) | PDF-size exposure + `verified` definition | Remove strip | A implemented |
| 16 Success | `customer-notified` family (any copy implying the customer was notified / signed off / can view the report) | No customer app/portal/notification channel in scope | **No customer-notification claim rendered**; delivery card shows only real technician-visible delivery records | Customer notification scope + privacy review | Hide (current) | A implemented (= not rendered) |
| 16 Success | Avatars (header + card avatar slots, cf. screens 13/14/15 emerald avatar discs `1:8476`, `1:8928`, `1:8784`) | No avatar asset/consent for a sample person | **Initials disc (`TR` or derived initials)** in the same 32–40 px circular slots | Real profile photo with consent | Hide avatar | A implemented (`FxProfileButton` / initials disc) |
| 16 Success | Vehicle photos (any sample vehicle raster outside real per-job capture) | No provenance/consent for Figma sample vehicle images | **Silhouette or real captured evidence only**; Figma rasters never shipped in product slots | Real per-job photo with consent | Remove media | A implemented |
| 16 Success | Hardware / BLE wording (`diagnostic hardware calibrated and paired`, barcode-attach, OBD-II scans, `Local Engine`, background-sync promises) | Pairing/BLE/telemetry not implemented; background delivery cannot be promised on iOS | **Neutral slots with real connectivity + queue state only**; no pairing/scan/version/speed claims | Hardware scope + pairing UX + telemetry | Keep hardware copy (forbidden) | A implemented |
| All | `Fleet` / `Fleet Portal` / `Fleet Ledger` / `fleet records` / `fleet standards` wording family | No fleet feature, channel, ledger, or standards text in product | Same slots carry **Finalized list / inspection / limitation copy**; fleet words never shipped | Fleet module scope + naming review | Hide | A implemented; **owner approval required for any fleet-named surface** |
| All | Full-VIN rule | Full VIN must never reach public report, logs, URLs, or shares | **Last-4 only outside the screen-14 internal card slot** (LTR, never logged); full VIN only where the Figma slot requires it and the owner approves | Global last-4 rule (recommended) | Show full VIN everywhere (forbidden) | A implemented |

## Prompt-screen vs export-folder map (normative)

| Figma screen (this sheet) | Export folder | Spec file |
|---|---|---|
| 9 Defect Detail & Evidence | `screens/09_9._Defect_Detail_&_Evidence` | `09-defect-detail-and-evidence.md` |
| 11 Dense Mechanical List | `screens/11_11._Dense_Mechanical_List` | `11-dense-mechanical-list.md` |
| 13 Final Review (Missing Items) | `screens/12_13._Final_Review_(Missing_Items)` | `12-final-review-missing-items.md` |
| 15 Offline Sync Queue | `screens/14_15._Offline_Sync_Queue` | `14-offline-sync-queue.md` |
| 14 Finalize & Approval (Swipe) | `screens/15_14._Finalize_&_Approval_(Swipe)` | `15-finalize-and-approval-swipe.md` |
| 16 Post-Finalization Success | `screens/16_16._Post-Finalization_Success` | `16-post-finalization-success.md` |

Tire capture (`screens/13…`, spec `13-tire-condition-capture.md`) is out of scope for
F2-B.1 and is not given a slot row here; its `mm`/`3/32"`/tread vocabulary is covered
above through the shared measurement rows.

## Decisions the owner must make

1. Approve the **defect taxonomy omission** (damage type, repair tags, `Cosmetic /
   Structural`, `mm` length) or fund a master taxonomy + measurement model with
   units, calibration, and ARB copy.
2. Approve the **P0–P3 non-mapping**: product stays on
   `MINOR / MODERATE / MAJOR / SAFETY_CRITICAL` rendered in the Figma pill slots.
3. Decide the **finalization gate**: are photos / signature actually blocking, or does
   the product keep `EVIDENCE_PENDING_5B` non-blocking with server-driven `blocking`
   only? (Screens 13/14 depend on this.)
4. Supply or approve the **finalize legal / limitation copy** replacing the fleet-
   compliance + signature + GPS + ledger disclaimer. Confirm GPS stays out of scope.
5. Confirm **full VIN only in the screen-14 internal card slot**, last-4 everywhere
   else (recommended), and that no VIN ever reaches logs/URLs/shares.
6. Confirm the **verified-tick meaning** (completion check only, never approval /
   certification) and the **pass-rate rule** (coverage % only, never a score).
7. Confirm **raw-status localization**: map `SENT / DELIVERED / FAILED / DEAD_LETTER`
   and `generationStatus` to fixed ARB labels; approve wording if new keys are wanted.
8. Confirm **no Fleet / Fleet Portal / Fleet Ledger surface**, no customer-notified /
   sign-off claim, no avatar or vehicle sample photos, no bay labels, and no
   hardware/BLE pairing implication until those scopes exist.
9. Confirm the **screen-11 barcode slot** stays a same-slot item opener (no fake
   diagnostic pairing) and the **screen-15 nav stays absent** (no fake Fleet/Profile
   tabs) unless an IA change is approved.

---

## Structured report

- **File created:** `docs/ui/figma/f2b-slot-sheet.md` (this file; the only file
  created — no other file was edited).
- **Rows written:** 58 slot rows + 1 numbering-map table + 9 owner decisions.
- **Coverage check:** all mandated items are present — defect `mm` length, repair
  tags, damage type, `Cosmetic / Structural`, P0–P3 vs the 4 severities,
  fleet-compliance sentences, GPS, ledger, specialist ID, verified tick, avatars,
  vehicle photos, bay labels, customer-notified, hardware/BLE wording, pass-rate/%,
  unlocalized raw statuses (`SENT`/`FAILED`/`generationStatus`) mapped to ARB labels;
  full-VIN scoping, screen-11 pill fidelity, screen-14 slide + invisible accessible
  alternative, and screen-16 real report + delivery status are each stated with file
  references (`defect_detail_view.dart`, `dense_mechanical_view.dart`,
  `final_review_view.dart`, `finalize_view.dart`, `offline_sync_view.dart`,
  `success_view.dart`, `f2b_kit.dart`, `ui_helpers.dart`).
- **Assumptions:**
  - L8 (same-slot neutral replacement in exact style; hide only when unsafe with no
    neutral form) is the governing rule for every row.
  - ARB set is fixed; no new strings were assumed — rows that need new copy are
    marked as owner decisions.
  - Figma sample counts, versions, sizes, speeds, percentages, roles, IDs, bays,
    zones, steps, sessions, ledgers, and channels are never shipped as data.
  - `EVIDENCE_PENDING_5B` stays non-blocking and the review/finalize gate stays
    server-driven (`review.ready`, `review.blocking`, idempotent finalize) unless
    the owner decides otherwise.
- **Open decisions needing owner approval:** the 9 items listed above; items 1–5
  block any future data/model work, items 6–9 are wording/privacy confirmations.
