# Roles and Permissions (Phase 0 Proposal)

**Project:** TrueReport  
**Document:** 03-roles-and-permissions.md  
**Status:** Proposed for product-owner approval. Permission details marked **[ASSUMPTION]** or **[OPEN]** require confirmation.

---

## 1. Principles

1. **Three authenticated roles only:** Technician, Workshop Admin, Platform Admin.
2. **Customer is a record, not a login.** The customer does not have an account, app or portal.
3. **Public viewer is unauthenticated.** Anyone with an active report link can read that one report, nothing else.
4. **The server enforces every permission.** A hidden Flutter screen, a disabled button or a client-side route guard is not a security control.
5. **Workshop isolation is mandatory.** Every workshop-owned table has a `workshop_id`; every query goes through a tenant-aware repository; cross-workshop access must fail in automated tests.
6. **Finalized findings are immutable for everyone.** No role can edit, delete or hide a finalized finding, severity, note or evidence item.
7. **Least privilege.** A role gets only what the workflow requires. Platform Admin oversight does not mean silent editing power.
8. **Every sensitive action is audited.** Account changes, finalization, link revocation, resend and correction attempts are recorded.

---

## 2. Role definitions

### 2.1 Technician

An employee of a partner workshop who performs inspections.

**Can:**

- Sign in to the technician app.
- See inspections assigned to them (default) or their workshop’s queue if the workshop policy allows it. **[ASSUMPTION — see Q3]**
- Record or confirm customer and vehicle information for an assigned job.
- Record consent as captured at the workshop.
- Complete inspection items, add notes, defect severity, recommendations and evidence photos.
- Save work locally when the internet is poor.
- Finalize their own inspection.
- View the resulting report and delivery status.

**Cannot:**

- See another workshop’s jobs or reports.
- Change finalized findings.
- Create or edit the global inspection-item library.
- Create or publish workshop templates. **[ASSUMPTION — master.md does not grant this]**
- Manage staff accounts.
- Revoke a public link.
- Change platform or workshop settings.

### 2.2 Workshop Admin

An employee of a partner workshop who manages that workshop.

**Can:**

- Use the workshop Admin app and website.
- See and manage only their own workshop’s inspections, staff and templates.
- Create or schedule a job, and manage intake before finalization. **[ASSUMPTION — “manage inspections” is not defined in detail in master.md]**
- Assign or reassign a technician before finalization.
- Create and manage workshop inspection templates from approved master items.
- See completed reports in read-only form.
- Resend an authorized report link or PDF.
- Deactivate a report link for a valid privacy, security, legal or customer-request reason, recording the action.
- Manage their own workshop’s technicians. **[ASSUMPTION — account-creation authority needs confirmation; see Q4]**

**Cannot:**

- Edit or delete finalized findings, severities, notes or evidence.
- Change Platform Admin master inspection items.
- Weaken a platform safety requirement in a template.
- See another workshop’s private records.
- Create or edit platform-wide translations, guide images or master dropdowns.
- Manage Platform Admin accounts or other workshops.

### 2.3 Platform Admin

The platform operator.

**Can:**

- Use the Platform Admin website and appropriate admin-app screens.
- See the hierarchy of partner workshops, Workshop Admins and Technicians.
- Create, invite, disable, reactivate or transfer accounts according to policy.
- Manage partner workshops and platform settings.
- Manage the shared inspection library, master dropdowns, translations, guide images, equipment, standard recommendations and report content.
- See audit history and platform operations.
- View workshop/template/inspection/report records for platform oversight. **[ASSUMPTION — read-only; no editing of finalized findings]**

**Cannot:**

- Change finalized inspection findings, severities, notes or evidence.
- Make a poor inspection appear favourable by modifying, hiding or deleting its contents.
- Bypass report immutability through an API or direct database path.
- Use platform access to impersonate a technician or Workshop Admin for the purpose of changing findings. **[RECOMMENDATION]**

### 2.4 Customer (record)

- Does not log in.
- Gives details to workshop staff.
- Receives the report URL and PDF.
- Can ask the workshop to correct details, resend the report or revoke the link.
- Has data-subject rights under applicable law, exercised through the workshop/platform process. The exact process is a legal and operational decision.

### 2.5 Public viewer

- Is unauthenticated.
- Can open an active report link and read that report.
- Can switch the report between English and Arabic.
- Can download the PDF only if the sharing policy allows it. **[OPEN — the master document mentions PDF download “if authorized by the sharing policy” but does not define the policy]**
- Cannot edit, comment, browse other reports, search for reports or see private fields.
- Sees a neutral message if the link is invalid or revoked.

### 2.6 System worker (non-human)

A background worker (outbox + JobRunr) that renders PDFs, processes images and sends messages.

- Has a dedicated service identity with least privilege.
- Does not bypass domain rules.
- Cannot change finalized content.
- Records delivery attempts and failures.
- Is not a user role and is never exposed to the client.

---

## 3. Permission matrix

**Legend:**

- **Yes** — allowed within the stated scope.
- **No** — not allowed.
- **Own** — only records belonging to the user’s workshop or assignment.
- **Read-only** — view but not change.
- **Consent** — allowed only when the required consent is recorded and the link is active.
- **Open** — policy decision required; do not implement until decided.

| Action / resource | Technician | Workshop Admin | Platform Admin | Customer | Public viewer |
|---|---|---|---|---|---|
| Sign in | Yes | Yes | Yes | No | No |
| Manage own password/session | Yes | Yes | Yes | No | No |
| View own profile | Yes | Yes | Yes | No | No |
| View workshop job list | Own assigned (default) | Own workshop | All workshops (oversight) | No | No |
| View unassigned workshop queue | **[ASSUMPTION]** optional | Yes | Yes | No | No |
| Create a scheduled job | No | Yes | **[ASSUMPTION]** No by default | No | No |
| Start an authorised walk-in job | Yes | Yes | No | No | No |
| Edit job schedule/details before finalization | Own assigned | Own workshop | No by default | No | No |
| Record/confirm customer details | Own assigned | Own workshop | No by default | No | No |
| Record/confirm vehicle details | Own assigned | Own workshop | No by default | No | No |
| Record consent | Own assigned | Own workshop | No by default | No | No |
| View customer PII (name, phone, email) | Own assigned | Own workshop | Limited, audited **[ASSUMPTION]** | Own data only, through workshop | No |
| Assign/reassign technician before finalization | No | Own workshop | No by default | No | No |
| Complete checklist items | Own assigned | No | No | No | No |
| Add notes/severity/recommendations | Own assigned | No | No | No | No |
| Capture evidence photos | Own assigned | No | No | No | No |
| Edit draft answers | Own assigned | No | No | No | No |
| Delete draft evidence (before finalization) | Own assigned | No | No | No | No |
| Finalize inspection | Own assigned | No | No | No | No |
| View draft inspection | Own assigned | Own workshop, read-only **[ASSUMPTION]** | Read-only oversight | No | No |
| View finalized report (internal) | Own assigned | Own workshop, read-only | All, read-only | No | No |
| Edit finalized findings/notes/severity/evidence | No | No | No | No | No |
| Delete finalized findings/notes/severity/evidence | No | No | No | No | No |
| Create a correction / new report version | Open (D9) | Open (D9) | Open (D9) | No | No |
| Create/edit workshop template | No | Own workshop | No (master library only) | No | No |
| Publish workshop template | No | Own workshop | No | No | No |
| View workshop templates | Own workshop, read-only | Own workshop | All, read-only | No | No |
| Create/edit master inspection items | No | No | Yes | No | No |
| Create/edit translations and guide images | No | No | Yes | No | No |
| Create/edit master dropdowns/equipment | No | No | Yes | No | No |
| Publish/retire master content | No | No | Yes | No | No |
| Manage workshop staff (technicians) | No | Own workshop **[ASSUMPTION]** | Yes | No | No |
| Manage Workshop Admin accounts | No | No | Yes | No | No |
| Disable/reactivate/transfer accounts | No | No | Yes | No | No |
| Manage workshop settings | No | Own workshop | Yes | No | No |
| Manage platform settings | No | No | Yes | No | No |
| View audit history | No | Own workshop subset **[OPEN]** | Yes | No | No |
| Resend report link/PDF | No | Own workshop | No by default **[OPEN]** | No | No |
| Deactivate report link | No | Own workshop, with reason | No by default **[OPEN]** | Can request via workshop | No |
| Reactivate report link | No | Open (not in master.md) | Open (not in master.md) | No | No |
| View public report via active link | Yes (as viewer) | Yes (as viewer) | Yes (as viewer) | Consent | Consent |
| Switch report language | Yes | Yes | Yes | Yes | Yes |
| Download public PDF | Consent/policy | Consent/policy | Consent/policy | Consent/policy | Consent/policy |
| Browse or search all reports | No | Own workshop list | Yes (admin) | No | No |
| Edit public report content | No | No | No | No | No |
| Export customer data | No | Open (legal/ops) | Open (legal/ops) | Own data request | No |

### 3.1 Notes on contested cells

- **“Own assigned” versus “workshop queue”:** `master.md` says a technician can “see inspections assigned to their workshop account”, which could mean all workshop jobs or only jobs assigned to that technician. The safer default is “only jobs assigned to me”, with an optional unassigned queue controlled by workshop policy. Confirm before building the job-list screen.
- **Workshop Admin intake editing:** `master.md` says “manage inspections” but does not define whether a Workshop Admin can edit customer/vehicle fields or checklist answers. The proposal allows intake/job management before finalization but **never** checklist answers, notes or evidence. Confirm.
- **Platform Admin viewing customer PII:** Platform Admin needs some oversight, but not necessarily full customer contact details. The proposal limits PII and audits access. Confirm with privacy review.
- **Resend/revoke by Platform Admin:** `master.md` grants resend/revoke to Workshop Admin, not Platform Admin. The proposal keeps Platform Admin out by default to avoid silent central control. If platform support needs it, define an audited support role or a break-glass procedure.
- **Audit visibility for Workshop Admin:** `master.md` only explicitly grants audit history to Platform Admin. A read-only own-workshop audit subset is a recommendation, not an approved right.
- **Correction authority:** D9 is unresolved. Do not grant any correction power until the policy is approved.

---

## 4. Data visibility: public report versus internal record

The public report must use an explicit allowlist serializer. It must never serialize a live database entity directly.

### 4.1 Allowed on the public report by default

| Field | Rule |
|---|---|
| Vehicle make, model, year, variant | Allowed, as approved for publication. |
| Odometer reading and units | Allowed only if the workshop/product policy approves publication. **[OPEN]** |
| Inspection date and time | Allowed. |
| Partner workshop name and approved branch details | Allowed. |
| Technician display name or approved identifier | Allowed only as approved by policy. **[OPEN]** |
| Inspection scope and template version | Allowed. |
| Summary of key findings | Allowed. |
| Coverage count for applicable items | Allowed. |
| Category-by-category results | Allowed. |
| Defect severity, explanation and recommendation | Allowed. |
| Evidence photos linked to the relevant item | Allowed as safe derivatives. |
| Checks not completed and their reasons | Allowed. |
| Road-test/diagnostic limitations | Allowed. |
| Report version and publication date | Allowed. |
| Limitations and disclaimer | Required. |

### 4.2 Not on the public report by default

- Customer name.
- Customer email address.
- Customer phone number.
- Precise location or address.
- Full VIN.
- Registration/plate details.
- Engine number.
- Internal customer/vehicle IDs.
- Staff personal contact details.
- Original high-resolution evidence files.
- Internal notes, audit data, delivery logs or provider message IDs.
- Any payment or billing information (which the platform must not hold anyway).

### 4.3 Internal-only fields

- Customer contact details and consent records.
- Full VIN and registration.
- Job assignment history.
- Draft answers, autosave state, sync queue.
- Original evidence files and EXIF metadata.
- Report snapshot hash and integrity alerts.
- Audit events.
- Delivery attempts and provider responses.
- Link token hash and revocation reason.
- Internal comments that are not approved for publication.

### 4.4 Comparison note

AutoHub and dubizzle public reports displayed more data than TrueReport allows: AutoHub displayed a customer name and full chassis number on the inspected report; dubizzle displayed full VIN, engine number and plate number [S2][S7]. Those are **[COMPARISON]** observations, not a reason to relax TrueReport’s default. TrueReport’s stricter boundary is a product decision and must be reflected in the report design.

---

## 5. Account lifecycle and authority

`master.md` gives Platform Admin the power to create, invite, disable, reactivate and transfer accounts, and gives Workshop Admin “staff management”. The exact split is not fully defined. Proposed split:

| Action | Platform Admin | Workshop Admin | Status |
|---|---|---|---|
| Create/invite a Workshop Admin | Yes | No | Proposed |
| Create/invite a Technician | Yes | Own workshop | **[ASSUMPTION]** |
| Disable/reactivate a Workshop Admin | Yes | No | Proposed |
| Disable/reactivate a Technician | Yes | Own workshop | **[ASSUMPTION]** |
| Transfer a user to another workshop | Yes | No | Proposed |
| Reset a user’s password | Yes, audited | Own staff, audited | **[OPEN]** |
| Change a user’s role | Yes, audited | No | Proposed |
| Delete a user permanently | No (soft-disable) | No | Proposed; reports depend on identity history |
| Delete a workshop permanently | No (soft-disable) | No | Proposed |

**Rule:** a technician belongs to one primary workshop in V1 unless the product owner approves multi-workshop membership.

---

## 6. Enforcement requirements

### 6.1 Server-side

- Authenticate every protected request.
- Resolve the user’s role and workshop membership on the server, not from a client-supplied workshop ID.
- Reject cross-workshop access with 404 or 403 without leaking whether the record exists.
- Enforce finalization state in the domain layer and at the database level.
- Enforce public-report allowlists in a dedicated serializer.
- Require `Idempotency-Key` on finalize, resend and other unsafe retries.
- Use optimistic locking/version checks; return 409 on stale writes; never silently overwrite.
- Log redacted audit events for sensitive actions.

### 6.2 Database

- Every workshop-owned table has `workshop_id` and an index starting with it.
- Finalized data tables have triggers that reject `UPDATE` and `DELETE` when the parent inspection is `FINALIZED`.
- The application database user has no `UPDATE`/`DELETE` privilege on report/snapshot tables.
- Report snapshot hash is stored and periodically recomputed; a mismatch raises an alert.
- No payment-card columns exist anywhere.

### 6.3 Flutter

- Route guards are a convenience only.
- Hide actions a role cannot perform, but never rely on hiding.
- Clear cached data on sign-out and on workshop/role change.
- Do not store report tokens or customer PII in logs.
- Offline data is scoped to the signed-in user and workshop; a different user on the same device must not see it.

### 6.4 Required automated tests

1. Technician A cannot read or write Workshop B’s job, report, media or template.
2. Workshop Admin A cannot read or write Workshop B’s records.
3. Platform Admin can read the hierarchy but cannot mutate finalized findings.
4. Every role/endpoint combination matches the matrix.
5. A finalized inspection cannot be updated or deleted through any API.
6. Direct SQL `UPDATE`/`DELETE` as the application user fails on finalized tables.
7. Public report serializer never includes a private field.
8. Revoked link returns a neutral response and no report data.
9. A disabled user cannot sign in or refresh a token.
10. A reassigned job cannot be finalized by the old technician without a conflict response.
11. Finalization is idempotent under double submit and retry.
12. Public report access is rate-limited.

---

## 7. Open questions affecting permissions

| ID | Question | Default if unanswered |
|---|---|---|
| Q1 | Can a technician see all jobs in their workshop, or only jobs assigned to them? | Only assigned jobs; no unassigned queue. |
| Q2 | Can a Workshop Admin edit customer/vehicle intake fields before finalization? | Yes for intake, never for checklist answers/evidence. |
| Q3 | Can a Workshop Admin create/invite technicians, or only Platform Admin? | Platform Admin creates all accounts; Workshop Admin manages assignments. |
| Q4 | Can a Workshop Admin see an audit history for their own workshop? | No by default; Platform Admin only. |
| Q5 | Can Platform Admin resend or revoke links? | No by default; add only with an approved audited support process. |
| Q6 | Who may initiate a correction? | D9 open; no correction UI until approved. |
| Q7 | Can a public viewer download the PDF? | Consent/policy decision; default is link-only until approved. |
| Q8 | Should Platform Admin see customer PII? | Limited and audited; default to no contact details. |
| Q9 | Can a technician belong to more than one workshop? | No in V1. |
| Q10 | What happens to a user’s offline data when they are disabled or transferred? | Wipe on next sign-in/role change; server revokes tokens. |

---

## 8. Approval

This role model is proposed, not approved. The product owner must confirm the contested cells and the account-lifecycle split before Phase 1 designs the navigation and screens.

**No code has been written. Phase 1 has not started.**
