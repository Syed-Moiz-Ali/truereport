# Phase 8 Real-Device Test Plan

**Project:** TrueReport  
**Status:** All items **NOT RUN** until the user reports results on real hardware.

Do not mark an item PASS from an emulator, widget test or desktop browser. Record the exact device, OS, app build, browser/viewer, network and result.

---

## 1. Device matrix

| ID | Device class | Required | Result |
|---|---|---|---|
| D1 | Low-end Android (? 4 GB RAM) | Yes | NOT RUN |
| D2 | Mid-range Android | Yes | NOT RUN |
| D3 | Current iPhone | Yes | NOT RUN |
| D4 | Older supported iPhone | Yes | NOT RUN |
| D5 | Android tablet | If pilot uses tablets | NOT RUN |
| D6 | iPad | If pilot uses tablets | NOT RUN |

Record: model, OS version, free storage, app build/commit, date, tester.

---

## 2. Technician app

| ID | Test | Steps | Expected | Result |
|---|---|---|---|---|
| T01 | Airplane-mode inspection | Enable airplane mode; start assigned job; answer all items; add photo; kill/relaunch; reconnect | Draft survives; queue syncs; only server-received work is ?submitted? | NOT RUN |
| T02 | Kill app mid-upload | Start photo upload; force-stop app; reopen; reconnect | Queue survives; no duplicate; photo eventually VERIFIED | NOT RUN |
| T03 | Camera permission denied | Deny camera; attempt evidence | Clear explanation/settings path; no fake evidence; limitation only if template permits | NOT RUN |
| T04 | Low storage | Fill device near threshold; attempt capture | Warn below threshold; block capture below hard limit; sync/cleanup still works | NOT RUN |
| T05 | 100+ items | Open a 100+ item template; scroll, answer, search/filter | Usable scroll; no OOM/crash; save latency acceptable | NOT RUN |
| T06 | Arabic keyboard | Enter mixed Arabic/English note | Exact Unicode preserved; RTL editing usable | NOT RUN |
| T07 | Russian keyboard | Enter Cyrillic customer/note | Stored/displayed exactly | NOT RUN |
| T08 | Chinese keyboard | Enter `zh-Hans` note | Stored/displayed exactly | NOT RUN |
| T09 | RTL layout | Arabic locale all technician screens | Correct direction, no clipped text/icons | NOT RUN |
| T10 | Large text | 200% text scale, phone and tablet | No overflow; all actions reachable | NOT RUN |
| T11 | Screen reader | TalkBack and VoiceOver through start/answer/photo/review/finalize | Labels/roles/order usable; finalize state announced | NOT RUN |
| T12 | Reassignment while offline | Reassign from admin while technician offline; sync | `JOB_REASSIGNED`; no overwrite; local data preserved | NOT RUN |
| T13 | Cancellation while offline | Cancel job; sync | `JOB_CANCELLED`; no finalize | NOT RUN |
| T14 | Low battery/battery pull | Interrupt during assessment/photo | Previous committed state survives; no corruption | NOT RUN |

---

## 3. Public report and PDF

| ID | Test | Steps | Expected | Result |
|---|---|---|---|---|
| P01 | Safari iPhone | Open report link in Safari | Report renders; Arabic RTL; no external font/CDN fetch | NOT RUN |
| P02 | Chrome Android | Open report link in Chrome | Report renders; language switch works | NOT RUN |
| P03 | WhatsApp in-app Android | Send/receive link in WhatsApp; open in-app browser | Renders or offers external browser; no broken token | NOT RUN |
| P04 | WhatsApp in-app iPhone | Same on iPhone | Same | NOT RUN |
| P05 | Link preview | Paste link in WhatsApp/SMS/email compose | No customer/VIN/phone/findings in preview; neutral title | NOT RUN |
| P06 | PDF iPhone viewers | Open PDF in Files/Preview and one third-party viewer | Bilingual layout, fonts, pages, footer intact | NOT RUN |
| P07 | PDF Android viewers | Open in Drive/Files and one third-party viewer | Same | NOT RUN |
| P08 | Revoke and reopen | Open report; revoke; reopen same URL | Neutral unavailable page; no cached content | NOT RUN |
| P09 | Invalid link | Open random token | Same neutral page; no details | NOT RUN |
| P10 | Screen reader public page | VoiceOver/TalkBack headings, tables, links | Logical reading order; language attributes correct | NOT RUN |
| P11 | Large text public page | 200% text | No content loss; horizontal navigation only where needed | NOT RUN |

---

## 4. Sign-off

| Item | Required | Result |
|---|---|---|
| D1?D4 devices tested | Yes | NOT RUN |
| T01?T14 | Yes | NOT RUN |
| P01?P11 | Yes | NOT RUN |
| Evidence screenshots/video retained | Yes | NOT RUN |
| Accessibility findings triaged | Yes | NOT RUN |
| Tester name/date | Yes | NOT RUN |

---

## 5. Result recording

For each failure record: ID, device, OS, app/browser build, steps, expected, actual, screenshot/video reference, severity, owner and retest result. Do not delete failures; retest after fix.
