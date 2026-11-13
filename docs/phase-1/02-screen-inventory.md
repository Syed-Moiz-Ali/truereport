# Screen Inventory

**Project:** TrueReport  
**Document:** 02-screen-inventory.md  
**Status:** Phase 1 proposal. Every screen below is a design target, not implemented UI.

---

## 1. State vocabulary

Every screen must define these states. “N/A” is allowed only where the state is genuinely impossible.

| Code | State | Meaning |
|---|---|---|
| **L** | Loading | Skeleton, spinner or progress; no layout jump; preserve back navigation. |
| **E** | Empty | Nothing to show, with a clear next action. Never a blank screen. |
| **X** | Error | What failed, whether data is safe, retry path, request ID. |
| **S** | Success | Confirmed result; for finalization, only after the server confirms. |
| **O** | Offline | What still works, what is queued, what is blocked. |

**Global rules**

- Destructive or irreversible actions use a confirmation dialog with the consequence in plain language.
- “Saved on this phone” and “Received by server” are different states everywhere. Never show “submitted” before the server confirms.
- Error messages never include tokens, full VIN, phone numbers or customer names in logs or URLs.
- Arabic and English layouts must both be designed; RTL is not a mirror applied at the end.
- Touch targets are at least 44×44 logical pixels (48×48 preferred).
- No screen may offer a manager review, approval, resubmission or correction action.

---

## 2. Technician mobile app

| ID | Screen / route | Purpose and user | Key components | Actions | States (L / E / X / S / O) | Entry points | Responsive behaviour |
|---|---|---|---|---|---|---|---|
| T01 | Sign in `/sign-in` | Authenticate a technician | Logo, email/username, password, show/hide, language switch, help link | Sign in, recover access via workshop process, change language | L: button spinner · E: n/a · X: generic invalid credentials, network, locked/disabled account · S: route to jobs · O: explain that sign-in needs internet; no offline login | App launch, session expiry | One column; keyboard-safe; large fields; no forced password autofill trap. |
| T02 | Language selection `/language` | Choose app language before or after sign-in | EN/AR segmented control, sample direction preview, keyboard help link | Select language, continue | L: n/a · E: n/a · X: n/a · S: applied immediately · O: works offline | First launch, Settings | Full-width options; Arabic preview right-aligned; persists locally. |
| T03 | Assigned jobs `/jobs` | See jobs assigned to this technician | Search, status filter, job cards (ref, vehicle, time, status, sync badge), pull-to-refresh, offline banner | Open job, refresh, filter, go to Sync | L: skeleton cards · E: “No jobs assigned” + contact Workshop Admin · X: retry with request ID · S: list · O: cached list + “last updated” timestamp; server actions disabled | Sign-in, bottom nav | One-hand list; sticky filter row; 2-column tablet cards; no horizontal scroll. |
| T04 | Job detail `/jobs/:jobId` | Understand one job and start/resume | Header (ref, status, vehicle), assignment, schedule, template version, scope, equipment shortcut, start/resume button, conflict banner | Start, resume, view equipment, open report if finalized | L: skeleton · E: n/a · X: missing template, reassigned, cancelled, disabled workshop · S: ready to start/resume · O: cached detail; start only if downloaded | T03, notification | Sticky primary action at bottom; status chip + icon + text. |
| T05 | Customer intake `/jobs/:jobId/intake/customer` | Record customer details as provided | Name, mobile with country code, email (optional), preferred language, delivery channels, notes | Save, continue, mark field as “not provided” only where allowed | L: n/a · E: blank form · X: invalid phone/email, duplicate warning, save conflict · S: saved locally and queued · O: saved locally; “received by server” pending | T04, review back-link | One field per row on phone; phone keypad; direction toggle for the name field; preserve exact script. |
| T06 | Vehicle identification `/jobs/:jobId/intake/vehicle` | Record the vehicle being inspected | Make/model/year/variant search, VIN, plate, odometer + units, registration (internal only) | Search catalogue, choose “Other”, scan deferred, save | L: catalogue search spinner · E: no match + “Other” · X: invalid VIN length/characters, missing make/model, catalogue offline · S: saved · O: cached catalogue; “Other” allowed; VIN field LTR | T05 | VIN uses LTR monospace field, uppercase, no auto-correct; odometer numeric keyboard. |
| T07 | Consent `/jobs/:jobId/consent` | Capture separate consents and inspection scope | Consent cards (process data, public link, WhatsApp, SMS, email, PDF if enabled), wording version, captured-by, timestamp, scope notes | Record each consent, record refusal, continue | L: n/a · E: no consent recorded · X: missing required wording version, save conflict · S: recorded with audit event · O: local only until server receipt; public link cannot activate | T06, T04 | Checkbox rows with plain-language summaries and “view full wording”; never pre-ticked. |
| T08 | Equipment list `/jobs/:jobId/equipment` | Show tools required by the pinned template | Grouped equipment list, required/optional chips, limitation note | Mark unavailable, add limitation note, continue | L: skeleton · E: no equipment required · X: template not downloaded · S: acknowledged · O: cached with template | T04, T07 | Checklist-style rows; large tap areas; no forced unsafe work. |
| T09 | Checklist categories and progress `/jobs/:jobId/checklist` | Navigate 100+ items by category | Progress header, category cards with counts, item status icons, search, “next incomplete” | Open category, search, jump to item, review | L: skeleton · E: no items in pinned template · X: corrupt template, version mismatch · S: progress updates · O: fully usable from cached template | T04, T08, T10 back | Virtualized lists; sticky progress; one-hand “next” button; no decorative motion. |
| T10 | Item assessment `/jobs/:jobId/checklist/:itemId` | Record result, note, severity, recommendation and evidence | Item label EN/AR, instruction, guide image, result chips, severity, note, recommendation, reason, evidence thumbnail, “Saved on phone / Received by server” | Select result, add note, add severity/recommendation, add reason, attach photo, next/previous, flag unsafe | L: guide image spinner · E: unanswered · X: required reason missing, required photo missing, save conflict, upload failed · S: saved locally, queued, then received · O: local save; queue evidence | T09, notification, search | Result chips are large; note field supports AR/EN/RU/ZH; direction toggle; camera action in thumb zone. |
| T11 | Photo capture `/jobs/:jobId/checklist/:itemId/photo` | Capture real evidence of this vehicle | Camera preview, flash, gallery pick, compression indicator, retake, caption, item link, storage warning | Capture, retake, delete before upload, compress, attach, add caption | L: camera opening · E: no photo · X: permission denied, storage full, capture/compression failed · S: local file + hash + queue entry · O: local only; retry upload later | T10 | Full-screen camera; shutter in bottom third; explicit “guide image is not evidence” note; no video in V1. |
| T12 | Review and missing items `/jobs/:jobId/review` | Check completeness before finalization | Coverage summary, blocking list, warnings, category counts, evidence list, “not checked” reasons | Jump to item, recheck, sync, continue to finalize | L: validation spinner · E: no items · X: blocking items, missing evidence, conflict · S: ready to finalize · O: local validation only; finalize disabled until server receipt | T09, T10 | Sticky “Fix” list; do not hide warnings; no single condition score. |
| T13 | Approve and generate report `/jobs/:jobId/finalize` | Self-finalize the inspection | Summary, consent status, report language, irreversible warning, confirm button, progress state | Confirm finalization, cancel, retry with same idempotency key | L: submitting · E: n/a · X: 422 validation, 409 stale/reassigned, 403 not assignee, timeout · S: `FINALIZED` only after server response · O: disabled with explanation | T12 | Full-width primary action; explicit “this cannot be edited” text; no manager/approval wording. |
| T14 | Report and delivery status `/jobs/:jobId/status` | See report/link/delivery result | Report ID/version, link state, delivery attempts, PDF status, timestamps, copy/share | Copy link if policy permits, share, refresh | L: skeleton · E: report generating · X: PDF failed, link pending consent, delivery failed · S: ready/active · O: cached last known state | T13, T03 | Read-only; Technician cannot revoke or resend; link actions belong to Workshop Admin. |
| T15 | Sync queue `/sync` | Understand local vs server state | Overall banner, per-item rows, retry, conflict details, storage use | Retry all, retry one, resolve conflict, open item | L: checking · E: everything received · X: failed items, conflicts, storage full · S: all received · O: queue persists | Bottom nav, banners | Group by job; show exact counts; no “submitted” label before receipt. |
| T16 | Settings `/settings` | Personal app preferences and help | App language, default entry direction, keyboard help, diagnostics, sign out, version | Change language, open help, sign out | L: n/a · E: n/a · X: sign-out fails to clear local data · S: saved · O: works offline | Bottom nav | Simple list; sign-out warns about unsent work; wipes local PII per policy. |
| T17 | Keyboard and language help `/help/keyboard` | Explain OS keyboard limits and how to add/switch keyboards | Steps for Android/iOS, direction toggle explanation, examples | Open device settings guidance, back | Static; no error state except unavailable help asset | T02, T16, field help | Short sections with screenshots; no promise of automatic keyboard switching. |
| T18 | Offline fallback `/offline` | Explain what works without internet | Cached-job list, queued count, last sync time, retry | Retry, open cached job | L: connectivity check · E: no cached jobs · X: n/a · S: back online · O: this is the offline state | Any offline action | Calm, non-blocking; never imply data was sent. |

---

## 3. Workshop Admin app and website

| ID | Screen / route | Purpose and user | Key components | Actions | States (L / E / X / S / O) | Entry points | Responsive behaviour |
|---|---|---|---|---|---|---|---|
| A01 | Sign in `/sign-in` | Authenticate Workshop Admin | Email, password, 2FA step if enabled, language switch | Sign in, 2FA challenge, recover via Platform Admin | L: spinner · E: n/a · X: invalid, locked, disabled, network · S: dashboard · O: sign-in requires internet | Web/app launch | Desktop centred card; mobile one column; no account enumeration. |
| A02 | Dashboard `/dashboard` | Daily overview of own workshop | Counts by status, unassigned/scheduled, finalizing, failed delivery, link issues, recent jobs | Open job, create job, assign | L: skeleton cards · E: “Create your first job” · X: partial data with retry · S: live counts · O: cached with timestamp; actions disabled | A01 | 3-column cards on web; stacked on mobile; no vanity score. |
| A03 | Job list `/jobs` | Find and filter workshop jobs | Search, status, technician, date, template, pagination/cursor | Open, create, filter, export? (export pending) | L: table skeleton · E: no jobs · X: retry · S: list · O: cached first page; no server filters | A02, nav | Data table on web; cards on mobile; column chooser; RTL columns. |
| A04 | Create / schedule job `/jobs/new` | Create a job and choose scope | Customer search/create, vehicle, template, schedule, walk-in, assign later | Save draft, schedule, assign, cancel | L: catalogue/template load · E: no published template (block) · X: duplicate customer/vehicle, invalid phone, disabled workshop · S: created with audit event · O: disabled; creation needs server | A02, A03 | Stepper on mobile; two-column form on web; template preview. |
| A05 | Job detail / intake `/jobs/:jobId` | Manage job before finalization | Summary, customer/vehicle fields, consent status, assignment, timeline, template version | Edit intake, reassign, cancel, open report | L: skeleton · E: n/a · X: finalized (read-only), conflict, missing template · S: saved · O: cached; no edits that need server | A03, A04 | Two-column on web; read-only banner after finalization. |
| A06 | Assign / reassign `/jobs/:jobId/assign` | Assign current technician | Technician picker with status, current assignment, reason | Assign, reassign, confirm | L: staff list · E: no active technicians · X: technician disabled/transferred, job finalized · S: assigned + audit · O: disabled | A05 | Searchable picker; shows only own workshop. |
| A07 | Workshop staff `/staff` | View staff and assignments | Staff list, role, status, current jobs | View profile, request change (if permitted), filter | L: skeleton · E: no staff · X: permission, disabled workshop · S: list · O: cached read-only | Nav | Table on web; cards on mobile; account creation hidden by default (RQ3). |
| A08 | Template list `/templates` | Manage own templates | Search, status (draft/published/retired), version, last published, used-by count | Open, duplicate? (pending), create, view versions | L: skeleton · E: no templates + create · X: retry · S: list · O: cached read-only | Nav, A02 | Table on web; cards on mobile. |
| A09 | Template builder `/templates/new` and `/templates/:id/edit` | Build a template from approved master items | Name, description, service type, category tree, item search, selected items, order drag handles, per-item permitted settings, validation panel | Add/remove, reorder, configure allowed settings, save draft | L: catalogue load · E: no items selected · X: locked setting attempted, item retired, conflict · S: draft saved / new version published · O: draft only; publish needs server | A08 | Desktop-first; mobile read-only preview; drag-and-drop plus accessible move buttons. |
| A10 | Template preview `/templates/:id/preview` | Review EN/AR before publishing | Language tabs, rendered checklist sample, item rules, locked/overridable badges, version diff | Switch language, compare versions, publish, back | L: render · E: no items · X: missing Arabic translation, invalid rule · S: preview ready · O: cached preview | A09 | Side-by-side on wide screens; tabs on mobile; RTL preview. |
| A11 | Version history `/templates/:id/versions` | Understand version usage | Version list, published date/by, item count, inspections using it, diff summary | View version, view inspections | L: skeleton · E: no versions · X: retry · S: list · O: cached | A08, A10 | Table with expandable diff; no editing old versions. |
| A12 | Completed report viewer `/jobs/:jobId/report` | Read a finalized report | Same snapshot renderer as public report plus internal metadata, delivery panel | Print, copy link (if active), open delivery/link | L: skeleton · E: not finalized · X: report generating/failed, revoked link · S: read-only report · O: cached last view | A05, A03 | Responsive document; no edit controls; internal-only annotations clearly marked. |
| A13 | Delivery status and resend `/jobs/:jobId/delivery` | See and retry delivery | Channel, recipient (masked), status, attempts, provider response, consent | Resend with idempotency key, change channel if consented | L: skeleton · E: no attempts · X: no consent, invalid recipient, provider failure, rate limit · S: queued/sent/delivered · O: disabled | A12 | Table on web; cards on mobile; never show full phone in logs. |
| A14 | Deactivate public link `/jobs/:jobId/link` | Revoke a link with a reason | Current state, active since, access count? (optional), reason picker, consequence text | Revoke, cancel | L: n/a · E: no active link · X: already revoked, wrong workshop, missing reason · S: revoked + audit · O: disabled | A12 | Confirmation dialog; explain copies cannot be recalled; no reactivate by default. |
| A15 | Workshop settings `/settings/workshop` | Own workshop preferences | Name, branch, contact, default report language, time zone, delivery defaults | Save | L: skeleton · E: n/a · X: validation, conflict · S: saved + audit · O: cached read-only | Nav | Form sections; Platform Admin controls plan-level settings. |
| A16 | Audit subset `/audit` | Own-workshop sensitive actions | Filterable event list | Filter, open event | **Hidden by default (RQ4)**. If enabled: L/E/X/S/O as normal | Nav (conditional) | Read-only table; no deletion. |

---

## 4. Platform Admin website and app

| ID | Screen / route | Purpose and user | Key components | Actions | States (L / E / X / S / O) | Entry points | Responsive behaviour |
|---|---|---|---|---|---|---|---|
| P01 | Sign in + 2FA `/sign-in` | Strong authentication | Email, password, TOTP challenge, recovery guidance | Sign in, verify TOTP, recover via approved process | L: spinner · E: n/a · X: invalid, locked, 2FA failure, rate limit · S: overview · O: requires internet | Web launch | Desktop card; mobile one column; TOTP autofocus. |
| P02 | Platform overview `/dashboard` | Platform health and operations | Workshop count, active users, jobs by status, finalization/report failures, delivery failures, storage alerts | Drill into tree, audit, failures | L: skeleton · E: no workshops · X: partial metric failure · S: metrics · O: cached read-only | P01 | KPI cards; no customer PII; click-through to filtered lists. |
| P03 | Hierarchy tree `/hierarchy` | See and manage workshops/staff | Expand/collapse tree, search, filters (active/disabled/pending), counts, context menu, keyboard support | Expand, search, filter, open workshop, open account, create workshop, invite/disable/transfer where permitted | L: skeleton tree · E: no workshops + create · X: retry, partial node failure · S: tree · O: cached read-only | P02, nav | Full tree on web; mobile drill-down; virtualization for large trees; RTL. |
| P04 | Workshop detail `/hierarchy/workshops/:id` | Manage one workshop | Profile, status, staff tabs, templates tab, inspection/report counts, audit tab | Edit profile, disable/reactivate, invite admin, transfer, view reports | L: skeleton · E: no staff/templates · X: conflict, disabled, permission · S: saved + audit · O: read-only | P03 | Tabs on web; stacked cards on mobile. |
| P05 | Account detail `/hierarchy/accounts/:id` | Manage one account | Identity, role, workshop membership, status, sessions, audit, last activity | Disable, reactivate, transfer, reset password (audited), change role | L: skeleton · E: n/a · X: last-admin protection, conflict, permission · S: saved + audit · O: read-only | P03, P04 | Two-column web; mobile summary + actions. |
| P06 | Master categories `/master/categories` | Manage category tree | Category list/tree, EN/AR names, order, status | Create, edit, reorder, retire | L: skeleton · E: none + create · X: duplicate slug, conflict, missing translation · S: saved + new version if published | Nav | Tree/table; desktop drag handles + accessible move buttons. |
| P07 | Master items `/master/items` | Find and manage inspection items | Search, category filter, status, version, evidence rule, used-by count | Create, open, duplicate? (pending), retire | L: skeleton · E: none + create · X: retry · S: list · O: cached | P06, nav | Data table; bulk actions only if audited. |
| P08 | Master item editor `/master/items/:id` | Author one item and its versions | Stable ID, category, EN/AR labels, instruction, results, severity guidance, note/evidence rules, reasons, equipment, guide image, applicability, publishing | Save draft, publish new version, retire, preview, compare | L: editor load · E: new item · X: missing required translation, locked-field violation, conflict · S: draft/version published + audit · O: disabled | P07 | Long form with section nav; autosave draft only; publish requires validation. |
| P09 | Item version history `/master/items/:id/versions` | Audit and compare versions | Version list, author, date, status, diff, templates/reports using it | View, compare, publish from draft | L: skeleton · E: one version · X: retry · S: list | P08 | Diff view; old versions read-only. |
| P10 | Answer options / severity / reasons `/master/items/:id/rules` | Define allowed results and safety rules | Result matrix, severity scale, reason-required toggles, overridable flags, evidence locks | Edit draft rules, validate, publish | L: skeleton · E: defaults · X: invalid combination, safety-rule violation · S: draft/version | P08 | Matrix table; mobile read-only. |
| P11 | Dropdown catalogue `/master/dropdowns` | Manage shared dropdown values | Dropdown type list, values, translations, order, status | Create type, add/edit values, reorder, retire | L: skeleton · E: none + create · X: duplicate value, conflict · S: saved + audit | Nav | Table; import deferred. |
| P12 | Guide images `/master/media` | Manage instructional images | Upload, crop? (pending), alt text EN/AR, category/item links, licence note, preview | Upload, replace, retire, link | L: upload progress · E: no images · X: invalid type/size, virus scan fail, missing alt text · S: stored private + derivative | P08, nav | Grid on web; camera upload on mobile; no evidence confusion. |
| P13 | Equipment catalogue `/master/equipment` | Manage tools | Equipment list, description, translations, active status | Create, edit, retire, link to items | L: skeleton · E: none + create · X: duplicate, conflict · S: saved | Nav | Table. |
| P14 | Standard recommendations and disclaimers `/master/content` | Manage approved report text | Recommendation list, disclaimer versions, EN/AR, report placement | Create draft, translate, publish, retire | L: skeleton · E: none + create · X: missing legal-approved wording, conflict · S: version published | Nav | Editor with preview. |
| P15 | Templates overview `/templates` | Oversee workshop templates without editing them | Filters, workshop, status, version, item count, inspections | Open read-only, view versions | L: skeleton · E: none · X: retry · S: list | Nav | Table. |
| P16 | Audit events `/audit` | Investigate sensitive actions | Filters (actor, workshop, action, date, entity), event detail, export pending | Filter, open, export | L: skeleton · E: none · X: retry · S: list | Nav, P02 | Table + detail drawer; immutable; no delete. |
| P17 | Platform settings `/settings/platform` | Platform-wide configuration | Language registry and translation coverage summary | Open languages | L: skeleton; E: none; X: retry; S: list | Nav | Localization summary; no fake settings controls. |

---

## 5. Public report

| ID | Screen / route | Purpose and user | Key components | Actions | States (L / E / X / S / O) | Entry points | Responsive behaviour |
|---|---|---|---|---|---|---|---|
| U01 | Public report `/r/{token}` | Read the consented report | Neutral header, language switch, summary, coverage, vehicle, findings, photos, limitations, version | Switch language, zoom photo, print | L: server-rendered HTML with no blocking JS · E: n/a · X: neutral unavailable page · S: report · O: static HTML remains readable on a poor connection; photos lazy-load | WhatsApp/SMS/email/browser | Mobile-first document; max-width 980 px; tables reflow; print CSS. |
| U02 | Neutral unavailable `/r/unavailable` or any invalid token | Avoid confirming whether a report exists | Neutral icon, “This link is unavailable”, no report data, no contact form | Retry, close | Static | Invalid, revoked, expired, rate-limited, consent missing | Mobile-first; no token echo; no analytics with token. |
| U03 | PDF download `/r/{token}/pdf` | Download the PDF **only if approved later** | Consent check, short-lived authorization, download | Download | **Disabled by default.** If enabled: L/X/S per policy | Public report (conditional) | Not rendered in V1 default. |
| U04 | Photo derivative `/r/{token}/photo/{id}` | View safe evidence image | Resized/re-encoded image, alt text, caption, item link | Zoom, close | L: image placeholder · X: unavailable → neutral placeholder · S: image | U01 | Responsive image; no original resolution; no EXIF. |

---

## 6. Shared screen patterns

### 6.1 Loading

- Use skeletons that match final layout to avoid layout shift.
- Do not block the whole app for a local read; use local data first and refresh in the background.
- For long operations (PDF, upload), show progress and a safe “you can leave this screen” message where true.

### 6.2 Empty

- Say what is empty and what to do next.
- Do not show a dead end. Example: “No jobs assigned. Ask your Workshop Admin to assign a job.”
- Public empty states never reveal whether a report exists.

### 6.3 Error

- Plain language first, technical code second.
- Include a request ID that support can use; never include tokens or PII.
- Distinguish validation (fix the field), conflict (reload/compare), permission (neutral), network (retry), server (retry later).
- Local work is preserved.

### 6.4 Success

- Confirm the action and the next step.
- Finalization success is shown only after the server returns `FINALIZED`.
- Delivery success is separate from report success; a failed message does not change the report.

### 6.5 Offline

- Show a persistent but calm banner: “Offline — work is saved on this phone.”
- Distinguish **Saved on this phone**, **Queued**, **Uploading**, **Received by server**, **Failed**, **Conflict**.
- Disable actions that need the server (finalize, resend, revoke, publish, account changes).
- Do not claim a message was sent while offline.

### 6.6 Accessibility

- Every screen has a logical heading order and focus order.
- Status and severity use colour + icon + text.
- Charts are not the only representation of data.
- Forms have labels, hints and errors tied to the field.
- Arabic screens are tested with screen readers, not only visually.

### 6.7 Responsive breakpoints (design target)

| Breakpoint | Use |
|---|---|
| < 600 px | Phone; single column; bottom actions; technician primary target |
| 600–899 px | Large phone/small tablet; two-column cards where useful |
| 900–1199 px | Tablet/small laptop; collapsible admin side navigation |
| ≥ 1200 px | Desktop admin; persistent side navigation; data tables; tree + detail split view |
