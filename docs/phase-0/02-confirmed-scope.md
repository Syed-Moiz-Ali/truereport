# Confirmed Scope (Phase 0 Proposal)

**Project:** TrueReport — Partner-Workshop Vehicle Inspection and Public Report Platform  
**Document:** 02-confirmed-scope.md  
**Status:** Proposed for product-owner approval. This is not an approval record.

---

## 1. The product in plain English

TrueReport is a business-to-business tool for partner workshops in the UAE.

A customer brings a vehicle to a partner workshop. The workshop staff record the customer and vehicle details, and a technician inspects the vehicle using a Flutter mobile app. The technician works through a checklist of at least 100 inspection points, adds notes, severity, recommendations and real photographs of that vehicle.

When the technician finishes, they press **Approve & Generate Report**. That is a self-finalization action, not a manager approval. The server then locks the inspection, creates an English–Arabic report, and makes a public report link available if the required consent was recorded. The system can send the link by WhatsApp and/or SMS and the PDF by email.

The workshop handles the customer and the money. Our platform does not process payments and does not hold card details.

The report is a record of what was inspected, when, by whom, within what scope. It is not a guarantee that the vehicle has no faults, and it is not an official RTA/Tasjeel certificate.

---

## 2. Who uses it

| User | What they use | What they do |
|---|---|---|
| **Technician** | Flutter Android/iOS app | Records customer/vehicle details, completes the checklist, adds evidence, finalizes their own inspection. |
| **Workshop Admin** | Flutter mobile app and Flutter website | Manages their own workshop’s jobs, staff and templates; assigns technicians; views completed reports read-only; resends links/PDFs; deactivates a link with a recorded reason. |
| **Platform Admin** | Flutter website and appropriate admin-app screens | Manages the workshop/staff hierarchy, accounts, shared inspection library, translations, guide images, dropdowns, equipment and platform settings; views audit history. |
| **Customer** | No login | A record, not an account. Gives details to workshop staff and receives the report link/PDF. |
| **Public viewer** | Browser only | Anyone with an active report link can read the public report; cannot browse other reports or edit anything. |

There is **no manager role**, **no second-person review**, **no approval queue**, and **no resubmission workflow**.

---

## 3. In scope for Version 1

### 3.1 Markets and languages

- First market: **United Arab Emirates**.
- Future market: **India** (prepared for, not launched in V1).
- Launch languages: **English** and **Arabic**, including a genuine RTL interface and RTL report layout.
- Structure prepared for **Russian** and **Simplified Chinese** (`zh-Hans`), to be confirmed.
- Customer names and notes must be accepted as entered in Arabic, Russian, Chinese and Latin script, even before the full interface is translated into Russian or Chinese.

### 3.2 Inspection content and templates

- A shared inspection-item library of **at least 100 inspection points**, grouped into useful vehicle categories.
- Platform Admin manages categories, items, instructions, English/Arabic wording, future translations, guide images, accessibility descriptions, answer options, severity labels, “not checked” reasons, recommended tools/equipment, vehicle reference data, standard recommendations and report disclaimers.
- Each item has a stable ID, version and publishing history.
- Guide images (teaching the technician where/how to inspect) are kept distinct from vehicle evidence photos (real photos of the inspected vehicle).
- Workshop Admins create their own templates by selecting approved master items, arranging them, and configuring only the settings the platform permits.
- Template publishing creates a new version. Existing inspections keep the version they started with. Finalized reports preserve the exact wording, answers, severity and template version used.
- A Platform Admin update to a master item must not silently change existing templates or reports.

### 3.3 Jobs and inspection workflow

- Workshop Admin creates or schedules a job, or a technician starts an authorised walk-in job.
- Workshop Admin assigns or reassigns a technician before finalization.
- Technician records/confirms customer details, vehicle details, consent and inspection scope.
- The app shows the equipment list and the exact checklist/template version.
- The technician completes applicable items, records results, notes, severity, recommendations and evidence photos.
- The app checks mandatory answers and evidence.
- Technician reviews and finalizes.
- Server locks the inspection, creates an immutable snapshot, and triggers report/PDF/link generation.
- Statuses: `DRAFT`, `SCHEDULED`, `ASSIGNED`, `IN_PROGRESS`, `READY_TO_FINALIZE`, `FINALIZED`, `CANCELLED`. No manager-review or resubmission statuses.
- Message delivery status is tracked separately: `QUEUED`, `SENT`, `DELIVERED` (if the provider supports it), `FAILED`, `RETRY_PENDING`.

### 3.4 Offline technician operation

- Download the assigned job, the exact checklist/template version and guide images.
- Save each answer locally as it is entered.
- Save captured photos locally before upload.
- Retry failed uploads safely.
- Resume interrupted uploads where supported.
- Prevent duplicate final submissions.
- Show “saved on this phone” versus “received by server” per item and overall.
- Detect conflicting edits and never silently overwrite.
- The public report becomes available only after the server has received the required data and evidence.
- Do not show “submitted” until the server confirms receipt.

### 3.5 Reports, PDF and public link

- An immutable report snapshot built at finalization.
- English–Arabic report content with correct Arabic direction and shaping.
- A public URL on our server, using a long random token, not a sequential ID.
- The link works in a browser without login or app installation.
- Store a protected representation (hash) of the token; lookup by hash.
- Link is active only when the required sharing consent is recorded.
- Authorized Workshop Admin can deactivate the link with a recorded reason.
- Do not index reports in search engines.
- Do not expose customer details, full VIN, registration details or private identifiers by default.
- Do not permanently expose original high-resolution evidence files; public derivatives only.
- Invalid or revoked links show a neutral message without vehicle information.
- A bilingual PDF with report version/ID in a consistent header or footer.
- Public report and PDF contents must be consistent.
- PDF must display Russian and Chinese customer names/notes when entered.
- A correction creates a new report version with a visible correction note and reason; the earlier version stays in history. The exact correction policy is still open.

### 3.6 Delivery

- Send the report URL by WhatsApp.
- Send the report URL by SMS.
- Send the bilingual PDF by email.
- Authorized manual download and resend if automated delivery fails.
- Store delivery attempts and results.
- A message failure must not delete or change a report.
- Consent checks before sending.
- Message templates in English and Arabic.

### 3.7 Administration and audit

- Platform Admin workshop/staff tree with expand/collapse, search, active/disabled/pending filters, workshop detail, account creation/disabling, assignment to workshop, and audit history for sensitive account actions.
- Workshop Admin sees and manages only their own workshop.
- Server-side enforcement of workshop isolation on every request; hiding a Flutter screen is not a security control.
- Audit events for account changes, finalization, link revocation, resend and other sensitive actions.
- Role-based access for Technician, Workshop Admin and Platform Admin.

### 3.8 Security and privacy

- HTTPS in production.
- Server-side authorization on every protected operation.
- Short-lived access tokens and rotating refresh tokens.
- Stronger login for admins (2FA method still open).
- Rate limiting on login, public report and resend.
- Upload validation (type, size, content sniffing).
- EXIF stripped from public images.
- Private storage with signed URLs.
- Redacted logs (no phone numbers, VINs, tokens).
- Secrets outside source code.
- No payment-card columns anywhere.
- Legal review for UAE data protection before real customer data.

### 3.9 Technology direction (to be confirmed)

- Flutter for technician mobile, admin mobile and admin website.
- Flutter Web or server-rendered HTML for the public report — decision pending spike.
- Java and Spring Boot modular monolith.
- MySQL 8.x — **must be confirmed as MySQL 8.4 LTS** because MySQL 8.0 is end-of-life.
- Flyway migrations.
- S3-compatible object storage; production provider to be decided (MinIO OSS is no longer maintained).
- Database-backed outbox plus JobRunr for background jobs.
- PDF engine chosen after the Arabic spike; headless Chromium is the current default candidate.

---

## 4. Explicitly out of scope for Version 1

Do not build:

- A customer mobile app.
- A customer booking website or customer portal.
- In-platform customer payments.
- A vehicle-buying or vehicle-selling marketplace.
- A manager role.
- A report-review or manager-approval step.
- A workflow that lets an Admin edit inspection findings.
- AI-generated diagnoses, valuations or repair-price predictions.
- A custom keyboard.
- Multi-workshop technician membership (unless separately approved).
- VIN scanning/OCR (deferred until the core flow is proven).
- Video evidence (pending approval).
- Microservices.
- Customer e-signatures or customer approval of findings.
- Customer accounts, login, password reset or profile management.
- A public report browsing directory or search.
- Report indexing in search engines.
- Payment-card storage, card forms or payment-processing API endpoints.
- Official RTA/Tasjeel certification or roadworthiness claims.
- Vehicle-history reports or accident-history databases.
- AI chat, voice notes, repair-order management, invoicing or parts ordering.

The public report page is a web page, but it is **not** a customer portal.

---

## 5. Scope rules that cannot be weakened

These are product-integrity rules, not preferences:

1. **Finalized findings can never be edited by anyone.** No manager, admin, support person or database path may rewrite the finalized findings, severities, notes or evidence.
2. **Corrections create a new report version.** The earlier version remains in history. The exact policy is open (who may initiate, what evidence is required, how the reason is shown).
3. **No manager role and no review queue.** The technician’s approval is self-finalization.
4. **No customer app or customer portal.** The customer receives a link and a PDF.
5. **No in-platform payments.** The workshop handles payment outside the platform.
6. **No admin editing to make a report look better.**
7. **Workshop data is isolated.** This is enforced by the server on every request, with automated cross-workshop tests.
8. **The public report uses an allowlist.** It never joins live internal tables or exposes private fields by default.
9. **A message failure never changes the report.**
10. **Do not claim official certification, independent review or legal compliance** unless it is factually true and approved.

---

## 6. What the product is not

- It is not an RTA/Tasjeel vehicle inspection certificate.
- It is not a guarantee that the vehicle has no faults or will remain unchanged.
- It is not a vehicle-history or accident-history product.
- It is not a marketplace or a lead-generation website.
- It is not a workshop management system with invoices, payments, parts or repair orders.
- It is not an AI diagnosis or valuation tool.
- It is not a customer-facing booking service.
- It is not a manager-approval workflow.

The report must clearly say that it records the vehicle as inspected at a particular time and within a defined scope, and that it is not a warranty.

---

## 7. Success criteria for Version 1

A Version 1 release is successful when:

1. Platform Admin can see the full workshop/admin/technician hierarchy and manage accounts.
2. Workshop Admin sees only their own workshop, staff, templates and inspections.
3. Platform Admin can publish translated master items, dropdowns, guide images and equipment requirements.
4. Workshop Admin can build and publish a template from approved master items without changing master wording or safety rules.
5. A technician can complete a realistic 100+ point inspection on a phone, including evidence photos.
6. The technician can work offline and recover safely after connectivity loss.
7. Finalization is a single, idempotent action that locks the findings on the server.
8. No Admin or Platform Admin can edit finalized findings through the app, website or API.
9. The report preserves the exact template version, wording, answers, evidence and severity used.
10. The English–Arabic PDF renders correctly, including mixed-direction text and entered Russian/Chinese names.
11. The public URL works in a browser without login.
12. A revoked link stops serving report content.
13. Public reports do not expose customer contact details, full VIN or private images by default.
14. WhatsApp/SMS/email failures can be retried without changing the report.
15. No customer payment is processed or stored.
16. Workshop data is isolated in all API and file-access tests.

These mirror `master.md` §21 and are expanded into phase gates in `08-roadmap-and-gates.md`.

---

## 8. Scope decisions still open

The following can change the scope or the plan. They are tracked in `06-assumptions-and-open-questions.md`.

| ID | Decision | Why it matters |
|---|---|---|
| D1 | Confirm MySQL 8.4 LTS (not 8.0) | MySQL 8.0 is EOL; schema and hosting depend on it. |
| D2 | One `admin_app` for both admin roles, or two apps | Affects repository layout, build and permissions. |
| D3 | Riverpod versus Bloc | Recommended Riverpod; not yet binding. |
| D4 | Public report: Flutter Web versus server-rendered HTML | Affects public report performance, accessibility and link previews. |
| D5 | PDF engine: headless Chromium versus OpenHTMLtoPDF | Affects Arabic quality, runtime and operations. |
| D6 | Production object storage | MinIO OSS is no longer maintained. |
| D7 | Forms package | `reactive_forms` versus `flutter_form_builder`. |
| D8 | WhatsApp, SMS and email providers | Onboarding, consent, cost and delivery status depend on the provider. |
| D9 | Correction/new-version policy | Who may create a correction, and how it is shown, is unresolved. |
| D10 | Confirm `zh-Hans` as the future Chinese variant | Affects localisation and fonts. |
| D11 | Photo requirements per item and size limits | Affects inspection time, storage, report size and offline sync. |
| D12 | Admin 2FA method | Security and support effort. |
| D13 | Version lock | Phase 2 task; Phase 0 versions are preliminary. |

---

## 9. Approval

**Product-owner approval is required before Phase 1 starts.**

By approving this document, the product owner confirms:

- The in-scope and out-of-scope lists are correct.
- The three authenticated roles and the customer/public-viewer model are correct.
- The “no manager, no review queue, no admin edit, no customer app, no payments” rules are correct.
- The open decisions may proceed to Phase 1 with the listed defaults, unless the owner marks a decision as blocking.

**No code has been written. No Flutter or Java project exists. Phase 1 has not started.**
