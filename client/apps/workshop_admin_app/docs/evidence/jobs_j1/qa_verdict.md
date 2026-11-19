# Gate 6 verdict — wave J1: jobs queue, job detail, legacy archive

Date: 2026-11-19 · Reviewer: independent qa-reviewer (read-only) · Inputs: docs/ui_brief_jobs.md §3–§9/§12, docs/visual_language*.md, docs/waivers.md, docs/audit-jobs.md §6/§8, docs/evidence/jobs_j1/* (22 images), docs/evidence/jobs_j1/queue_qa.md, source tree.

## Verdict: **FAIL**

The queue is a genuine rebuild and the state/policy spine is strong, but three blockers remain: the Arabic detail date regressed to Arabic-Indic, time-first text (detail_1280_ar.png); the public-link page still publishes outside the checklist (M6), reachable from the rebuilt detail; and the queue's unfiltered list total (12) contradicts the workshop All count (20) with no explanation. Two major composition defects — the inspector's job facts are not visible at ≥1100, and the footer floats at the page centre instead of the sheet — plus a contradictory no-jobs empty state make the primary desktop screen not shippable as "the counter".

## Checklist

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Queue 1440/1280: status strip + "Workshop totals", six columns, sortable headers, selection, inspector, footer range/pagination | **FAIL** | queue_1440.png, queue_1280.png: inspector facts absent (F4), footer centred/floating (F5), All 20 vs 12 (F3) |
| 2 | Queue 1024/768: inspector full-width above the sheet; close clears selection | **PASS** | queue_1024.png, queue_768.png |
| 3 | Queue 390/360: card list, one action per card, New job, archive in header overflow | **PASS** | queue_390.png, queue_360.png; minor F12 |
| 4 | Queue states: loading, list error, counts error, empty, filtered-empty, page out of range | **FAIL** | queue_loading_1280.png, queue_error_1280.png, queue_filtered_empty_1280.png pass; queue_empty_1280.png contradicts itself (F6) |
| 5 | Detail 1440/1280/1024/768/390/360: identity, facts, assignment, review/publication, sticky action bar | **PASS** | detail_1440/1280/1024/768/390/360.png |
| 6 | Detail terminal and conflict states hide mutations and offer reload | **PASS** | detail_terminal_1280.png, detail_conflict_1280.png |
| 7 | Archive: banner, read-only, no create/assign/cancel/report/publish/link | **PASS** | archive_1280.png; minor F13 |
| 8 | Visual language: hairline, one accent, no shadow/glass, type scale, card anatomy, status tones | **PASS** | Queue/detail vs docs/evidence/dashboard_after/dashboard_1440.png and shell_after/jobs_390.png |
| 9 | RTL: mirroring, identifiers LTR, Latin contiguous dates/counts, no reversed range, no clipped labels | **FAIL** | detail_1280_ar.png (F1), queue_1280_ar.png (F8/F9) |
| 10 | Data honesty: counts labelled, footer = server total, no relative ages, publication labels, consent-blocked, no publish outside the checklist | **FAIL** | F2 (publish), F3 (counts); labels/consent pass |
| 11 | Edit-vs-replace: rewritten queue/detail, one new file per region, non-empty kill list, visibly different at 1440/1024/390 | **PASS** | features/jobs/queue/*, detail/*, shared/*, assign/*, archive/*; old shell_after/jobs_390.png |
| 12 | Flow proof: filter/count/selection/pagination/archive; detail assign/cancel/conflict/terminal | **PASS** | test/jobs_queue_test.dart, test/job_detail_test.dart, test/jobs_archive_test.dart; capture gaps F14 |
| 13 | 360–1440 EN + 1280 AR, no RenderFlex overflowed, 1.5×/2× text | **PASS** | Six widths + AR captured; queue has no overflow...up to 2.0x, 2x text at 390; no 1.5×/2× capture (F14) |
| 14 | A11y: labels, contrast, touch targets | **FAIL** | F12 (phone card semantics, disabled affordance) |
| 15 | dart format, flutter analyze --fatal-infos, flutter test green | **FAIL (unverified)** | queue_qa.md:18-20 is a claim, no raw log; the green suite did not catch F1 (F7) |
| 16 | Dark theme | **WAIVED** | W-LIGHT, countersigned 2026-11-18 |
| 17 | W-NOTOTP, W-ROWOPEN | **WAIVED / respected** | docs/waivers.md:9,11 |

## Findings

### F1 — BLOCKER — Arabic detail date is Arabic-Indic and reordered
docs/evidence/jobs_j1/detail_1280_ar.png renders Scheduled at as the Arabic-Indic, time-first string ٩:٠٠ ٢٠٢٦/١١/٥ instead of 5/11/2026 09:00. Cause: lib/src/features/jobs/detail/job_detail_summary.dart:33 calls formatInstant(context, job.scheduledAt) without pinDigits, unlike the queue (queue/jobs_inspector.dart:238, queue/jobs_queue_table.dart:582). queue_qa.md "Fixed since round 1" claims every date is pinned, but the claim stops at the queue. Violates brief §8 (Latin digits for data), §7 (no reordering) and §12's 1280 AR requirement. test/job_detail_capture_test.dart:198-208 only asserts takeException.
**Fix:** at job_detail_summary.dart:33 use pinDigits(formatInstant(context, job.scheduledAt)) (import workshop_digits.dart), keep valueDirection: TextDirection.ltr; add to the AR capture expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing) and expect(find.text('5/11/2026 09:00'), findsWidgets); regenerate detail_1280_ar.png.
**Owner:** lib/src/features/jobs/detail/job_detail_summary.dart:33; test/job_detail_capture_test.dart:198.

### F2 — BLOCKER — a second publish path bypasses the checklist (M6)
lib/src/features/jobs/public_link_page.dart:159-166 still renders jobs-publish-link-button, and :266-274 calls publishJob. The rebuilt detail offers a Public link route (detail/job_detail_action_bar.dart:45-51, :157-162), so the bypass is reachable from the screen under review. Brief §2/§8 (CR-1/M6) and docs/audit-jobs.md §6/§8 say the key/action must disappear.
**Fix:** delete the publish button and _publish; for !active route to PublishChecklistPage; remove jobs-publish-link-button from the key contract; add a source test that publishJob is called only from publish_checklist_page.dart.
**Owner:** lib/src/features/jobs/public_link_page.dart:159-166, 266-274.

### F3 — BLOCKER — unfiltered list total contradicts the workshop All count
queue_1440.png / queue_1280.png show All (20) above Showing 1–10 of 12 with no filter and no scope label; queue_1280_ar.png repeats 20 / 12. The fixtures bake it in: test/jobs_queue_capture_test.dart:44-63 builds 12 jobs but :106-119 returns total: 20; test/jobs_queue_test.dart:80-108 has 24 jobs and total: 36; test/jobs_invariants_characterization_test.dart:402-406 asserts All (140) against a 24-row list. CleanJobCounts.total (workshop_job_models.dart:448) and JobPage.total (:410) are both server values, so either the list is implicitly narrower and the UI must say so, or one number is wrong. This is routed to api-data-integrity; it is not accepted as "counts vs list never conflated" (queue_qa.md:52).
**Fix:** make the fixture coherent (cleanJobs(status: '', search: '') → total == cleanJobCounts.total), assert All == JobPage.total when unfiltered, and if production's list is a subset, render a scope note such as Showing 3–12 of 20 in this view and add the contract to docs/data/jobs_inventory.md.
**Owner:** test/jobs_queue_capture_test.dart:40-119, test/jobs_queue_test.dart:97-108, test/jobs_invariants_characterization_test.dart:395-408; data contract: api-data-integrity.

### F4 — MAJOR — inspector job facts are not visible at ≥1100
queue_1440.png: the Summary eyebrow at y≈617 is followed directly by the pinned footer at y≈688, with no facts; queue_1280.png: no facts at all (the customer block ends at y≈618, the footer starts at y≈632). The 380 px inspector uses a single-column JobFactGrid (jobs_inspector.dart:206-290; job_fact_grid.dart:21-25 switches at 600 px), and pinnedFooter (jobs_inspector.dart:79-86) pushes the facts below the fold with no scroll indicator. Technician, scheduled, template, mileage, review and consent — the data the primary action depends on — are invisible by default. Spec §5 blocks 1–4.
**Fix:** set minColumns: 2 on the customer and facts grids (or use a denser fact row and less cardPadding); unpin the footer at 900 px height or add a visible scroll affordance; add a 1280×900 test that asserts find.text('Technician A'), the scheduled date and jobsConsentGranted inside jobs-inspector.
**Owner:** lib/src/features/jobs/queue/jobs_inspector.dart:56-92, 206-290.

### F5 — MAJOR — footer is centred/floating and the sheet is clipped
queue_1440.png: the footer container spans x≈408–1032 (page centre), not the sheet (x=33–1000), and extends under the inspector column; queue_1280.png: x≈330–950 under both columns; test/screenshots/real/workshop_jobs_1440.png reproduces it. jobs_queue_layout.dart:39 returns a Column with the default CrossAxisAlignment.center, and JobsQueueFooter's Container (jobs_queue_footer.dart:45-86) sizes to its Wrap, so it shrinks and centres. The sheet's last row is cut mid-row at the fold, reading as a broken table.
**Fix:** Column(crossAxisAlignment: CrossAxisAlignment.stretch, ...) or wrap the footer in SizedBox(width: double.infinity) at jobs_queue_layout.dart:39-82; end the sheet with its own bottom edge; assert the footer's left edge equals the sheet's left edge at 1440.
**Owner:** lib/src/features/jobs/queue/jobs_queue_layout.dart:39-82.

### F6 — MAJOR — the no-jobs empty state contradicts itself
queue_empty_1280.png shows No jobs found + Try another filter or create a new job. on the unfiltered empty state; there is no filter to change. Brief §7 requires "No jobs yet" + New job. app_en.arb:823 is No jobs found, :1347 is Try another filter…; AR is app_ar.arb:823, 1311; jobs_queue_states.dart:141-156 uses the same body when filtered == false.
**Fix:** jobsEmpty → "No jobs yet"; jobsEmptyQueueBody → "Create the first job to start the queue." (or omit the body for no-data); keep "No jobs in this view" + Clear filters for filtered. Test both branches.
**Owner:** client/packages/l10n/lib/l10n/app_en.arb:823,1347, app_ar.arb:823,1311, queue/jobs_queue_states.dart:141-156.

### F7 — MAJOR — no raw test/analyze evidence; the green suite did not catch F1
queue_qa.md:18-20 claims 0 issues and 588 passed / 0 failed, but no raw log is attached. The AR detail capture only asserts takeException, so the suite can be green with the wrong date. A claim is not gate evidence; the analyzer/test run must be re-executed and attached after the fixes.
**Fix:** attach the raw flutter analyze --fatal-infos and flutter test output (or a CI link) and include the F1 assertion.
**Owner:** docs/evidence/jobs_j1/queue_qa.md + CI.

### F8 — MINOR — Arabic detail reference is detached from the identity
detail_1280_ar.png: JOB-0001 sits at the far left (x≈57) while Toyota Camry is at the far right (x≈1023), splitting the title/reference pair across the card. job_detail_summary.dart:45-49 gives the reference textDirection: TextDirection.ltr inside a stretched Column, so it aligns to the physical left.
**Fix:** wrap it in Align(alignment: AlignmentDirectional.centerStart, child: Text(..., textDirection: TextDirection.ltr)); regenerate the AR capture.
**Owner:** lib/src/features/jobs/detail/job_detail_summary.dart:45-49.

### F9 — MINOR — RTL scheduled header and cells do not align
queue_1280_ar.png: the header الموعد is right-aligned in its column (x≈543–576) while the date 1/1/2026 10:00 is left-aligned (x≈445–527), because jobs_queue_table.dart:541-549 puts an LTR Text in a stretched cell.
**Fix:** wrap the cell in Align(alignment: AlignmentDirectional.centerStart, child: Directionality(textDirection: TextDirection.ltr, child: Text(...))); apply the same to legacy_archive_page.dart:213-223; add an AR alignment assertion or golden.
**Owner:** lib/src/features/jobs/queue/jobs_queue_table.dart:541-549.

### F10 — MINOR — header does not match §3
queue_1440.png / queue_1280_ar.png: the eyebrow is JOBS (l10n.jobsTab), not JOB QUEUE; the subtitle is Sort applies to this page (the footer note repeated), not Sorted by scheduled · ascending, and the active sort is never shown because the default scheduled column is deliberately not clickable (jobs_queue_table.dart:12-14). jobs_queue_header.dart:29-39.
**Fix:** add a JOB QUEUE eyebrow (AR: قائمة المهام) and a meta line naming the active sort; drop the duplicate note from the header.
**Owner:** queue/jobs_queue_header.dart:29-39, ARB.

### F11 — MINOR — 1024 detail fact grid collapses to one column
detail_1024.png: the 544 px-wide Customer & vehicle card renders ten facts in one column (y≈385–989), pushing Inspection under the sticky action bar; at 1440 the same card uses two columns. job_fact_grid.dart:21-25 switches at 600 px and ignores minColumns.
**Fix:** set minColumns: 2 on job_detail_customer_vehicle.dart:32 (or lower the threshold for this card); re-capture 1024.
**Owner:** detail/job_detail_customer_vehicle.dart:32, shared/job_fact_grid.dart:21-25.

### F12 — MINOR — a11y and state affordances
(a) queue_390.png: the phone card wraps its contents in ExcludeSemantics and the outer Semantics label is only reference, title, customer (jobs_queue_cards.dart:83-95), so status, scheduled and technician are not announced. (b) queue_1440.png / queue_1280.png: Previous page at page 1 looks enabled although onPressed is null (jobs_queue_footer.dart:67-73); the disabled secondary style is indistinct. (c) queue_390.png: the status strip clips the next chip mid-label at the right edge (jobs_status_strip.dart:48-64) with no scroll affordance.
**Fix:** include the status label and the scheduled date in the card's semantics label; dim the secondary disabled state (design_system WorkshopButton) or use a text variant; add an edge fade/chevron to the phone strip.
**Owner:** queue/jobs_queue_cards.dart:83-95, queue/jobs_queue_footer.dart:67-73, queue/jobs_status_strip.dart:48-64.

### F13 — MINOR — structure, kill-list and archive deviations
WorkshopJob (models.dart:489), jobsProvider (admin_providers.dart:89) and admin_api.jobs() (admin_api.dart:132,788) survive although §10 names them for deletion; they are used only by the §9 archive bridge (archive/legacy_archive_page.dart:35). The composition file is features/jobs/job_detail_page.dart, not features/jobs/detail/job_detail_page.dart; job_row_data.dart is absent. The archive row order is vehicle → reference → customer → scheduled → status, not the §9 order, and has no column labels (legacy_archive_page.dart:163-231); Finalized comes from the legacy vocabulary.
**Fix:** narrow the legacy client to archive/ and record the exception in §10 (recommended), or amend the brief; move the detail composition into detail/; add a column header to the archive.
**Owner:** lib/src/models.dart, admin_providers.dart, admin_api.dart, features/jobs/job_detail_page.dart, archive/legacy_archive_page.dart.

### F14 — MINOR — evidence gaps
There is no capture of a status-filtered queue (the §12 "filter by status → count and rows agree" flow is only in tests); no consent-blocked detail capture; no 1.5×/2× captures; the archive is only 1280. Tests cover the logic (jobs_queue_test.dart:282-299, job_detail_test.dart:275-288, 308-373), but §12 says "captured".
**Fix:** add queue_filtered_1280.png (Pending review selected, count 4, rows 4), detail_consent_blocked_1280.png, and 1.5×/2× captures at 1440/1024/390.
**Owner:** test/jobs_queue_capture_test.dart, test/job_detail_capture_test.dart.

## What is good
1. **States are real, not slabs.** Loading is a 6×56 skeleton in the actual column geometry with no counts (queue_loading_1280.png); the list error is bounded with counts intact (queue_error_1280.png); the filtered-empty state offers Clear filters (queue_filtered_empty_1280.png); the footer is hidden at total 0.
2. **Policy is one pure function with a real flow suite.** job_actions.dart plus test/job_detail_test.dart exercise assign with the version forwarded, cancel with reason, 409 conflict, terminal hides mutations, consent-blocked, and 403/404 copy (:275-401).
3. **The queue's RTL work is careful where it was applied.** Columns, chevrons and the range mirror; scheduled dates and the range are Latin/contiguous at 1280 AR (queue_1280_ar.png, jobs_queue_test.dart:450-478); "Workshop totals" labels the counts.
4. **This is a rebuild, not a restyle.** The queue/detail are split into region files; job_quick_sheet.dart, schedule_job_sheet.dart, job_counts.dart, assign_technician_dialog.dart are gone; the 390 screen is visibly different from docs/evidence/shell_after/jobs_390.png (server-count strip, card action footer, no legacy chips).

## Blocking action
One remediation pass before any re-review: (1) delete the publishJob path from public_link_page.dart (M6); (2) pin the detail schedule date and regenerate detail_1280_ar.png with the digit assertion; (3) make the unfiltered All count equal the list total (or display the scope) in the fixtures and the real contract; then attach a raw flutter analyze / flutter test log and re-run Gate 6.
