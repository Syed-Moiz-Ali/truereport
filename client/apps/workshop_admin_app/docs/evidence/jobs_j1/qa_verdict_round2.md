# Gate 6 verdict, round 2 — wave J1: jobs queue, job detail, legacy archive

Date: 2026-11-19 · Reviewer: independent qa-reviewer (read-only) · Inputs: docs/ui_brief_jobs.md §3–§9/§12, docs/visual_language*.md, docs/waivers.md, the current docs/evidence/jobs_j1/*.png (28 images), the raw logs in docs/evidence/logs/, and the current source/test tree. No build conversation was read.

## Verdict: FAIL

The three round-1 blockers are genuinely fixed: the Arabic detail date is Latin and date-first, the public-link page no longer publishes, and the unfiltered queue's All (20) now equals its 1–10 of 20 footer with the status buckets summing to 20. The inspector now shows the job facts at 1280×800 and its footer sits on the sheet edge, the first-use empty state is honest, and a raw analyzer/test run is attached. The wave still fails on a required state that the remediation itself added: at 2× text the 1440×900 queue truncates the inspector's primary action to Revi…, breaks table headers and names mid-word (Technicia/n, Custom/er 1), and cuts the second row and the phone value at the fold (queue_1440_2x.png). A required 2× layout that hides the action label is not shippable, and the suite only asserts takeException() at 2× (test/jobs_queue_test.dart:540-561), so the green run cannot catch it. Independently, the new consent-blocked detail capture proves a spec gap: APPROVED without consent shows the reason but offers no checklist link, although brief §5 requires the same checklist link (detail_consent_blocked_1280.png; job_detail_action_bar.dart:44-65 adds no checklist action; test/job_detail_capture_test.dart:249-253 asserts only that no primary exists).

## F1–F14 remediation

| # | Round-1 severity | Status | Check against the current artifact |
|---|---|---|---|
| F1 | BLOCKER | FIXED | detail_1280_ar.png: "Scheduled at" reads 5/11/2026 09:00, Latin and date-first; no Arabic-Indic digits. job_detail_summary.dart:34-37 pins the digits; test/job_detail_capture_test.dart:203-233 asserts no Arabic-Indic digits, no bidi controls, and the exact string. |
| F2 | BLOCKER | FIXED | grep publishJob( in lib/ returns only publish_checklist_page.dart:244. public_link_page.dart:162-166 now offers the checklist and :268-272 routes there; test/source_scan_test.dart:309-330 asserts the single call site. The old jobs-publish-link-button is gone. |
| F3 | BLOCKER | FIXED | queue_1440.png / queue_1280.png: All (20), buckets 3+4+2+3+4+1+1+1+1 = 20, footer "Showing 1–10 of 20"; queue_filtered_1280.png: Pending review (4), 4 rows, "1–4 of 4". Fixture is a true partition (test/jobs_queue_capture_test.dart:40-126); assertions at test/jobs_queue_test.dart:563-630; an incoherent unfiltered total is labelled "Workshop totals: N" (jobs_queue_footer.dart:55-59). |
| F4 | MAJOR | FIXED | queue_1440.png and queue_1280.png show Technician, Scheduled, Template, Mileage, Review status and Consent in the 380 px inspector, with the action footer pinned; jobs_inspector.dart:79-86 pins it and :204-243 uses minColumns: 2. Facts are visible at 1280×800, not only 900. |
| F5 | MAJOR | FIXED | queue_1440.png: footer x≈33–1000 shares the sheet's x≈33–1002 edges; queue_1280.png likewise. jobs_queue_layout.dart:40-41 stretches, :67-76 puts the footer in the sheet column, jobs_queue_footer.dart:63-64 forces full width. The sheet still clips its last visible row at the scroll viewport (minor, N5), but the footer no longer floats. |
| F6 | MAJOR | FIXED | queue_empty_1280.png: "No jobs yet" + "Create the first job to start the queue." + New job, counts all 0, footer hidden. jobs_queue_states.dart:142-143; app_localizations_en.dart:3735,3738; filtered branch remains "No jobs in this view" + Clear filters (queue_filtered_empty_1280.png). |
| F7 | MAJOR | FIXED | Raw runs attached: jobs_j1b_remediation_analyze.txt:36-37 = "No issues found! (ran in 5.1s)"; jobs_j1b_remediation_test.txt:647 = "00:51 +609: All tests passed!" (609 passed / 0 failed). Earlier jobs_j1_test.txt = 594 and jobs_j1_detail_test.txt = 35 (focused subset). The compact reporter interleaves names, so not every capture name is printed; the totals are raw. Caveat: 2× is still asserted only as "no exception" (N1). |
| F8 | MINOR | FIXED | detail_1280_ar.png: JOB-0001 now sits under Toyota Camry at the start (right) edge; job_detail_summary.dart:49-56 wraps it in Align(AlignmentDirectional.centerStart) inside a stretched column. |
| F9 | MINOR | STILL PRESENT (minor) | queue_1280_ar.png: the الموعد header and the scheduled date still do not share a column edge (date painted ~50 px left of the header's start). jobs_queue_table.dart:542-555 now wraps the cell in Align(centerStart) + Directionality(ltr), so either the capture predates the fix or the alignment is not effective. Regenerate and add an AR alignment assertion; not a blocker. |
| F10 | MINOR | ACCEPTED | The eyebrow is "WORK QUEUE" (jobsQueueEyebrow, jobs_queue_header.dart:52), not the brief's literal "JOB QUEUE", but it names the queue; the subtitle is now "Sorted by scheduled · ascending" (:29-41), so the substantive part is fixed. Wording accepted. |
| F11 | MINOR | FIXED | detail_1024.png: Customer & vehicle uses two columns and Inspection sits above the sticky bar; job_fact_grid.dart:21-25 computes 3/2/1 columns; test/job_detail_test.dart:68 asserts the 1024 two-column case. |
| F12 | MINOR | PARTIAL | (a) FIXED: the phone card's semantics label now includes status, schedule and technician (jobs_queue_cards.dart:83-93). (b) FIXED: the disabled pager is a muted text variant (jobs_queue_footer.dart:109-154). (c) STILL PRESENT: the chevron affordance exists (jobs_status_strip.dart:74-85), but at 360 the third chip is still cut through its count (queue_360.png). |
| F13 | MINOR | ACCEPTED | The recorded §10 exception (docs/ui_brief_jobs.md:205-210) covers WorkshopJob/jobsProvider/admin_api.jobs(), and a source-scan test forbids them outside archive/. The archive has column labels (archive_1280.png). Leftovers: composition is still features/jobs/job_detail_page.dart rather than features/jobs/detail/; job_row_data.dart is still absent. Not blocking. |
| F14 | MINOR | PARTIAL | Added: queue_filtered_1280.png, queue_filtered_empty_1280.png, detail_consent_blocked_1280.png, queue_1440_2x.png, queue_390_2x.png, detail_text2x_1280.png, detail_text2x_390.png. Still missing: any 1.5× capture and a 1024 2× capture; archive only at 1280. The new 2× capture fails visually (N1). |

## §12 checklist — current images

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Queue 1440/1280: status strip, workshop totals, six columns, sortable headers, selection, inspector, footer range/pagination | PASS | queue_1440.png, queue_1280.png: facts visible, footer at the sheet edge, All 20 = footer 20. |
| 2 | Queue 1024/768: full-width inspector above the sheet; close clears selection | PASS | queue_1024.png, queue_768.png; minor uneven row heights (N5). |
| 3 | Queue 390/360: card list, one action per card, New job, archive in overflow | PASS | queue_390.png, queue_360.png; chip clip at 360 (F12c) and lone overflow button (N6) are minor. |
| 4 | States: loading, list error, counts error, empty, filtered-empty, page out of range | PASS | queue_loading_1280.png, queue_error_1280.png, queue_empty_1280.png, queue_filtered_empty_1280.png; counts absent until loaded, empty/filtered copy now distinct. |
| 5 | Detail 1440/1280/1024/768/390/360: identity, facts, assignment, review/publication, sticky action bar | PASS | detail_1440/1280/1024/768/390/360.png; 1024 now two columns. |
| 6 | Terminal and conflict states hide mutations and offer reload | PASS (minor) | detail_terminal_1280.png (only View public link / Documents / More); detail_conflict_1280.png shows the reload banner. The disabled primary still looks enabled (N7). |
| 7 | Archive: banner, read-only, no create/assign/cancel/report/publish/link | PASS | archive_1280.png; labels Reference/Vehicle/Customer/Status/Scheduled; no actions. |
| 8 | Visual language: hairline, one accent, no shadow/glass, type scale, card anatomy, status tones | PASS | Queue/detail are consistent with the bay-window language; no second accent in the working states. |
| 9 | RTL: mirroring, identifiers LTR, Latin dates/counts, no reversed range, no clipped labels | PASS WITH MINORS | F1/F8 fixed (detail_1280_ar.png, queue_1280_ar.png); F9 alignment, AR inspector reference (N3) and mileage unit order (N4) remain. |
| 10 | Data honesty: counts labelled, footer = server total, no relative ages, publication labels, consent-blocked, no publish outside the checklist | PASS | All 20 = footer 20; filtered 4/4; empty 0; "Workshop totals"; publication PUBLISHED/UNPUBLISHED/REVOKED mapping visible; publishJob only in the checklist. |
| 11 | Edit-vs-replace: rewritten queue/detail, one new file per region, non-empty kill list, visibly different at 1440/1024/390 | PASS | features/jobs/queue/*, detail/*, shared/*, assign/*, archive/*; legacy quick/schedule sheets and count widgets gone; the 390 card screen differs structurally from shell_after/jobs_390.png. |
| 12 | Flow proof: filter/count/selection/pagination/archive; detail assign/cancel/conflict/terminal | PASS (minor) | queue_filtered_1280.png shows 4 rows / 4 total; conflict/terminal/consent captured; assign and cancel after-states remain test-only (test/job_detail_test.dart:275-401). |
| 13 | 360–1440 EN + 1280 AR, no overflow, 1.5×/2× text | FAIL | queue_1440_2x.png truncates the primary to Revi…, splits Technicia/n and Custom/er 1, and cuts the row/phone at the fold; no 1.5× or 1024 2× capture. |
| 14 | A11y: labels, contrast, touch targets | PARTIAL | Phone semantics fixed; the 2× action label is unreadable and the conflict disabled primary is visually indistinguishable (N7). |
| 15 | dart format, flutter analyze --fatal-infos, flutter test green | PASS | Raw logs: analyze 0 issues; 609 passed / 0 failed. The green suite does not assert 2× layout, which is why N1 escaped. |
| 16 | Dark theme | WAIVED | W-LIGHT, countersigned 2026-11-18. |
| 17 | W-NOTOTP, W-ROWOPEN | PASS | Respects docs/waivers.md:9,11; no dark-theme invention, no legacy row sheet. |

## New findings

### N1 — BLOCKER — required 2× text breaks the 1440 queue
queue_1440_2x.png (1440×900, textScaler 2): the inspector's pinned footer gives the primary only ~140 px, so "Review & approve" renders as Revi…; the table header breaks Technician as Technicia/n; Customer 1 breaks as Custom/er 1; the second row is cut by the footer and the inspector's phone value is not fully visible at the fold. This is a required §7/§12 state ("1.5×/2× … no clipping at 1440/1024/390"); a primary action whose label is ellipsized is an accessibility failure, not polish.
Files: lib/src/features/jobs/queue/jobs_inspector.dart:278-375 (footer row), lib/src/features/jobs/queue/jobs_queue_table.dart:183-217,459-555 (header/row cells), test/jobs_queue_capture_test.dart:439-449 (capture), test/jobs_queue_test.dart:540-561 (only takeException).
Fix: at 2× (or when the inspector is 380 px and the scale > ~1.3) stack the primary full-width and move "Open job" into the more menu, or allow the primary label to wrap; do not ellipsize an action label. Let table cells wrap at word boundaries or reduce the column set at 2× so a single word is never split. Add an assertion that the primary label is fully painted and that no word is broken, plus a 1024 2× and a 1.5× capture.
Owner: queue table/inspector + the capture/test author.

### N2 — MAJOR — consent-blocked detail has no checklist link
detail_consent_blocked_1280.png (APPROVED, consent missing) shows "Publication is blocked" and the reason, but the action bar offers only Public link, Documents and More actions. Brief §5 requires "Publication blocked" with the same checklist link; the queue inspector has that link (jobs_inspector.dart:313-331), the detail does not. test/job_detail_capture_test.dart:249-253 asserts the block text and that no primary exists, but never asserts a checklist route, and its comment ("the only primary route is the checklist") describes a link the screen does not render.
Files: lib/src/features/jobs/detail/job_detail_action_bar.dart:44-65,133-166, lib/src/features/jobs/detail/job_detail_review_publication.dart:56-64, test/job_detail_capture_test.dart:236-255.
Fix: render a secondary "View checklist" action (key job-detail-publish-checklist) when status == APPROVED && !consentGranted, and assert it in the consent-blocked test/capture.
Owner: detail action bar/review-publication region + test.

### N3 — MINOR — Arabic inspector reference is still detached
queue_1280_ar.png: JOB-0001 sits at the physical left of the inspector (x≈93) while the close control is at x≈57 and the vehicle title is at the right; the reference should sit at the start (right) next to the close. jobs_inspector.dart:160-167 uses a bare Text(textDirection: ltr) inside Expanded, which aligns to the physical left under RTL. This is the same class as round-1 F8, now in the inspector.
Fix: wrap the reference in Align(alignment: AlignmentDirectional.centerStart, child: Text(..., textDirection: ltr)).
Owner: jobs_inspector.dart:160-167.

### N4 — MINOR — Arabic inspector mileage reads unit-first
queue_1280_ar.png: the mileage fact renders km 18,240 instead of 18,240 km. jobs_inspector.dart:262 omits valueDirection, so the value inherits the RTL paragraph direction; the detail's 45,000 KM is correct because it passes valueDirection: ltr (job_detail_customer_vehicle.dart). Data ordering defect, not a data-value defect.
Fix: JobFact(..., valueDirection: TextDirection.ltr) at jobs_inspector.dart:262 and add an AR assertion for 18,240 km.
Owner: jobs_inspector.dart:262.

### N5 — MINOR — table rows become uneven when status/date wrap
queue_1280.png / queue_768.png: the Pending review badge wraps to two lines at 1280 and the scheduled date wraps at 768, growing those rows above 56 px while neighbouring rows stay 56 px; the last row is cut mid-badge at the sheet's scroll edge. Readable, but it breaks the sheet's rhythm and the "row height 56" brief.
Fix: widen the status/scheduled flex or use a compact status label at these widths; add a bottom fade/scroll cue so the cut row reads as scrollable.
Owner: jobs_queue_table.dart:203-217,532-555.

### N6 — MINOR — the phone header leaves the overflow menu alone
queue_390.png / queue_360.png: "New job" is full-width and the … overflow button sits on its own row beneath it, with a large gap before the search toolbar. It reads as an orphaned control.
Fix: place New job and the overflow in one row (primary expanded, menu 44 px) or move the overflow into the toolbar.
Owner: jobs_queue_header.dart:51-72 / phone header layout.

### N7 — MINOR — the conflict state's disabled primary looks enabled
detail_conflict_1280.png: after the 409, the banner says "Reload it before you continue" and mutationsEnabled is false (job_detail_page.dart:48-49), yet the "Assign technician" button is painted with the same saturated fill as an enabled primary. A user can tap a control that does nothing. The secondary pager got a distinct disabled treatment in round 1 (F12b); the primary did not.
Fix: use a distinct disabled primary style when mutationsEnabled == false, or replace the primary with a "Reload to continue" action while the conflict banner is shown.
Owner: job_detail_page.dart:84-94, job_detail_action_bar.dart:136-142.

## What is good

1. The three blockers are actually gone, not relabelled. The AR detail date is 5/11/2026 09:00 in detail_1280_ar.png; publishJob( has one call site (the checklist); the queue's 20 is the sum of its nine buckets and its footer total in the same capture.
2. Counts are now a contract, not a coincidence. The fixture is a true partition, the filtered capture proves 4/4, and an incoherent unfiltered total is explicitly labelled "Workshop totals: N" rather than left as two unexplained numbers.
3. The inspector is usable at the counter widths. At 1440 and 1280 the facts a manager needs (technician, schedule, template, mileage, review, consent) are visible with the action pinned, and the footer shares the sheet's edges.
4. The states are designed, not slabs. Loading keeps the real geometry and withholds counts; the list error is bounded with Retry; first-use and filtered-empty are now distinct and honest; the footer hides at total 0.
5. The archive is a real read-only bridge. Banner, labelled columns, no create/assign/cancel/report/publish/link; legacy reads are quarantined by a source-scan test and the §10 exception is recorded.
6. The detail body holds up at 1024 and 360. Two-column customer facts at 1024, terminal hides mutations, consent-blocked explains itself, and the 2× detail captures do not overflow (the queue is the failure, not the detail).

## Single next action

One remediation pass before any further review: fix N1 so the required 2× 1440 queue never ellipsizes the primary action or breaks a word (stack the inspector actions / let the label wrap; assert the rendered label and recapture queue_1440_2x.png, plus add the missing 1.5× and 1024 2× captures), and add the N2 consent-blocked checklist link on the detail with an assertion in test/job_detail_capture_test.dart:236-255. Attach a fresh raw flutter analyze --fatal-infos + flutter test, then re-run Gate 6. The residual F9/F12c/N3–N7 items do not block on their own but should be swept in the same pass.
