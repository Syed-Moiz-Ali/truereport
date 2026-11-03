# MASTER PROJECT PROMPT

## Partner-Workshop Vehicle Inspection and Public Report Platform

**Document version:** v0.3 (Phase 1 approved decisions applied; Phase 2 and Phase 3 delivered for review).
**Project status:** Phase 1 approved. Phase 2 foundation and Phase 3 Platform Admin hierarchy/master content delivered for review. No Phase 4+ feature is to be built until Phase 3 is approved.
**Open decisions are tracked in §13A.12.** D6, D7, D8, D11 and the legal consent wording remain open.

**Changelog**

- v0.3: Applied the approved Phase 1 decisions: MySQL 8.4 LTS (D1), one admin app (D2), Riverpod (D3), server-rendered HTML public report (D4), headless Chromium PDF (D5), no correction UI/API in V1 (D9), `zh-Hans` (D10), admin TOTP (D12), and the approved role/consent/PDF-download defaults. Recorded Phase 0’s source-of-truth corrections for the approved scope. D6, D7, D8, D11 and legal consent wording remain open.
- v0.2: Added §13A (Flutter, Java and database technology decisions, repository layout, API conventions, offline and upload design, PDF options, CI, decision log). Replaced PostgreSQL references with MySQL 8.x (to be confirmed).
- v0.1: Original master prompt.

### 0. Your role and how to work

Act as a senior product researcher, automotive inspection workflow specialist, Flutter architect, Java backend architect, UX designer, security engineer, and technical project manager.

Help design and build a vehicle-inspection platform for partner workshops. The final product must be understandable to non-technical workshop owners and detailed enough for Flutter developers, Java developers, designers, and testers.

**Work phase by phase. Do not attempt to build the whole system in one response.**

At the beginning:

1. Research the product and technical requirements.
2. Summarize the confirmed scope.
3. Identify assumptions and unanswered questions.
4. Produce a phased development plan.
5. Do **not** start coding until the user approves the next phase.

At the end of each phase, provide:

- What was completed.
- The files or documents created or changed.
- How to run or test the work.
- The tests performed and their results.
- Requirements that are not yet complete.
- Risks, decisions needed, and acceptance criteria for the next phase.

Do not skip a phase. Do not invent unapproved features. If a requirement is unclear, state a reasonable assumption and flag it for confirmation.

If a project repository already exists, inspect its structure before changing files. Do not overwrite existing work without explaining why. If no repository exists, propose the structure before generating a large amount of code.

---

## 1. Product and business requirements

Build a **business-to-business vehicle-inspection platform for partner workshops**.

The partner workshop handles the customer, the vehicle, the technician, and the payment. The technician uses our app to record the inspection. The system creates a report, a public URL, and a bilingual PDF.

### Confirmed requirements

- First market: **United Arab Emirates (UAE)**.
- Future market: **India**.
- Application languages at launch: **English and Arabic**.
- Arabic must have a genuine right-to-left interface and report layout.
- Prepare the system for Russian and Chinese.
- Russian and Chinese customer names and notes must be supported as entered, even before the full app interface is translated into those languages.
- Customers do **not** get an app, booking portal, or account in Version 1.
- Customers give their details to partner-workshop staff.
- Partner workshops employ the technicians.
- Partner workshops handle customer payments directly.
- Our platform must not collect customer card details or process customer payments in Version 1.
- Technicians use a Flutter mobile app.
- Workshop Admins use a Flutter mobile app and a Flutter website.
- Platform Admins manage the overall platform and partner workshops.
- Platform Admins can view and manage the workshop/staff hierarchy.
- Platform Admin owns the shared inspection-item library, master dropdowns, translations, guide images, and standard report content.
- Workshop Admins create their own inspection templates by selecting items from the Platform Admin’s library.
- The initial inspection-item library must contain **100+ inspection points**, grouped into useful vehicle categories.
- Each inspection item must support guide images. Technicians also capture real photos of the vehicle as inspection evidence.
- The technician checks and finalizes their inspection. The server then generates the report.
- There is **no manager role, second-person review, approval queue, or resubmission workflow**.
- Admins and Platform Admins must not edit completed inspection findings to make a report look better.
- The report must be accessible through a public URL hosted on our server.
- Anyone with the URL can read the report in a web browser without signing in or installing an app.
- The system sends the report link through WhatsApp and/or SMS.
- The system sends the PDF by email or another agreed delivery method.
- Develop locally first. Select the production hosting location and server later.

### Explicitly out of scope for Version 1

Do not build:

- A customer mobile app.
- A customer booking website or customer portal.
- In-platform customer payments.
- A vehicle-buying or vehicle-selling marketplace.
- A manager role.
- A report-review or manager-approval step.
- A workflow that lets an Admin edit inspection findings.
- AI-generated diagnoses, valuations, or repair-price predictions unless approved as a later feature.

The public report page is a web page, but it is **not** a customer portal.

---

## 2. Roles and access

There are three authenticated system roles. A customer is a record, not a login role. A public viewer is an unauthenticated person with a report link.

### Technician

Can:

- Sign in to the technician app.
- See inspections assigned to them. An optional workshop queue requires an explicit workshop policy and product-owner approval.
- Record customer and vehicle information.
- Complete inspection items.
- Add notes, defect severity, recommendations, and evidence photos.
- Save work locally when the internet is poor.
- Finalize their inspection.

Cannot:

- See private jobs from another workshop.
- Change finalized findings.
- Create or edit the global inspection-item library.

### Workshop Admin

Can:

- Use the workshop Admin app and website.
- See and manage only their own workshop’s inspections and staff.
- Edit customer/vehicle intake fields before finalization; never edit checklist answers, findings, notes, severity or evidence.
- Assign or reassign technicians before an inspection is finalized.
- Create and manage workshop inspection templates from approved master items.
- See completed reports in read-only form.
- Resend an authorized report link or PDF.
- Deactivate a report link for a valid privacy, security, legal, or customer-request reason, recording the action.

Cannot:

- Edit or delete finalized findings, severities, notes, or evidence.
- Change Platform Admin master inspection items.
- See another workshop’s private records.

### Platform Admin

Can:

- Use the Platform Admin website and appropriate admin-app screens.
- See the hierarchy of partner workshops, Workshop Admins, and Technicians.
- Create and manage accounts (the default for account creation; a Workshop Admin may assign work but does not create accounts in V1).
- View read-only report snapshots for oversight; customer contact details are hidden by default and any PII access is limited and audited.
- Create, invite, disable, reactivate, or transfer accounts according to policy.
- Manage partner workshops and platform settings.
- Manage the shared inspection library, master dropdowns, translations, guide images, and standard content.
- See audit history and platform operations.

Cannot:

- Change finalized inspection findings or evidence.
- Make a poor inspection appear favourable by modifying or hiding its contents.
- Resend or revoke a report link by default; those actions belong to the owning Workshop Admin unless an audited support process is separately approved.
- See customer contact details by default; any PII access is limited and audited.

### Customer and public viewer

- The customer does not log in to our platform.
- The technician records customer information at the partner workshop.
- The customer receives the report URL and PDF.
- Anyone with an active public report URL can view the customer-consented public report link.
- A public viewer cannot edit or browse other reports.

---

## 3. Workshop hierarchy and Platform Admin tree

Create a clear Platform Admin screen that displays the account structure, for example:

Platform
├── Workshop A
│ ├── Workshop Admins
│ ├── Technicians
│ ├── Templates
│ └── Inspections and reports
├── Workshop B
│ ├── Workshop Admins
│ ├── Technicians
│ ├── Templates
│ └── Inspections and reports

The Platform Admin tree must support:

- Expand and collapse.
- Search workshops, Workshop Admins, and Technicians.
- Filters by active, disabled, or pending invitation.
- Opening a workshop to see its staff and templates.
- Creating and disabling accounts.
- Assigning accounts to the correct workshop.
- Viewing audit history for sensitive account actions.

A Workshop Admin must only see their own workshop. Enforce this rule in the Java backend on every request; do not rely on hiding screens in Flutter.

For Version 1, assume each technician belongs to one primary workshop unless the product owner approves multi-workshop membership.

---

## 4. Platform Admin master content library

Platform Admin manages shared content that must be available to workshops through the system. Do not hardcode this business content into Flutter screens.

The master library includes:

- Inspection categories.
- Inspection items and instructions.
- English and Arabic wording for each item.
- Future Russian and Chinese translations.
- Guide images and accessibility descriptions.
- Available answers and severity labels.
- Reasons for “not checked,” “not applicable,” and “could not verify.”
- Recommended tools and equipment.
- Vehicle categories and make/model reference data.
- Standard recommendations and report disclaimers.
- Other shared dropdown values needed by the inspection workflow.

Platform Admin should have screens to create, translate, update, publish, retire, and audit this content.

### Clarify what “Platform Admin enters content” means

- Platform Admin maintains the shared catalogue, dropdown values, checklist content, translations, guide images, and standard messages.
- Technicians enter information for the specific customer and vehicle being inspected.
- Workshop Admins create their own templates by selecting and arranging approved master-library items.
- Standard app buttons, navigation labels, and general UI text can use normal localization files. They do not need to be entered manually through Platform Admin screens unless product requirements later demand that.

If a needed make, model, checklist item, dropdown option, or standard recommendation is missing, provide a safe fallback or an “Other” option where appropriate. The technician must be able to report a real vehicle even when the catalogue is incomplete.

---

## 5. Workshop templates

Workshop Admins have a **Templates** section and create templates for their own workshop using approved Platform Admin library items.

A Workshop Admin can:

1. Create a template name and description.
2. Choose a vehicle/service type.
3. Search and select approved master inspection items.
4. Arrange item order and categories.
5. Choose allowed settings for each item.
6. Preview English and Arabic content.
7. Save a draft and publish a template version.
8. See which template version is used by each inspection.

The Platform Admin controls which settings a workshop may change. For example, a master item may specify that evidence is required or that an item cannot be made optional. A Workshop Admin must not be able to weaken a platform safety requirement.

Workshop Admins cannot change the meaning, translated wording, answers, severity definitions, or safety rules of a master item. If they need a new item, Platform Admin adds it to the shared library.

### Template versioning

- Publishing a change creates a new template version.
- Existing inspections retain the version with which they started.
- Completed reports preserve the exact item wording, answers, and template version used.
- A Platform Admin update to a master item must not silently change existing templates or reports.
- A full inspection package should support 100+ relevant checklist items. Other service templates may use a smaller set if the business approves it.

---

## 6. Multilingual app, content, and keyboard requirements

Language support applies to app screens, templates, customer-entered information, reports, and PDFs.

### At launch

- English interface.
- Arabic interface with correct right-to-left layout.
- English and Arabic checklist and report content.
- Bilingual English-Arabic PDF.
- Support entering Arabic, Russian, and Chinese customer names and notes.
- Prepare the localization structure to add full Russian and Chinese interface/report translations later.

Use language identifiers such as:

- English: `en`
- Arabic: `ar`
- Russian: `ru`
- Simplified Chinese: `zh-Hans`

Simplified Chinese (`zh-Hans`) is confirmed as the working future Chinese variant (D10). Keep the localization design flexible enough to add other variants later.

### Keep these settings separate

1. **App language:** the language of menus, labels, and buttons.
2. **Text-entry language/direction:** the intended language and direction of an individual input.
3. **Report language:** the languages in which the report content is rendered.

A technician may use the app in English, enter a customer name in Arabic, and generate the required English-Arabic PDF. Preserve the customer’s name exactly as entered. Do not replace it with a transliteration.

### Keyboard behavior

When someone selects Arabic, the app must:

- Change the interface to Arabic.
- Change the layout to right-to-left where appropriate.
- Set Arabic text-field direction and alignment.
- Request an Arabic keyboard/input method where the platform supports it.
- Use the appropriate keyboard type for fields such as phone number or VIN.

When someone selects English, do the equivalent for English fields and interface.

Important technical limit: Android and iOS control their system keyboards, and an app cannot guarantee that every device switches its keyboard language automatically. Research the current Flutter and native-platform options. Where a device does not switch automatically, clearly explain how the user can change or add a keyboard in device settings. Do not build a custom keyboard for Version 1.

### Typed information and fonts

- Text inputs must support Unicode, including Arabic, Cyrillic, Chinese, Latin characters, and mixed-language content.
- Vehicle makes/models should have localized display names where possible.
- Allow a technician to search catalogue values using the selected language.
- Keep VINs and technical identifiers unchanged and displayed in an appropriate direction.
- Ensure fonts used in the apps and PDFs display all required characters.
- Test Arabic and mixed-direction content on real Android and iOS devices.

### PDF and note translation

The Version 1 PDF must contain both English and Arabic. It must use correct Arabic direction and shaping.

For technician-written notes:

- Preserve the original note.
- Record its language where possible.
- If a translation is provided, show it separately from the original.
- Do not present unreviewed machine translation as a confirmed safety finding.

---

## 7. Inspection checklist requirements

The initial shared inspection-item library must contain at least 100 vehicle inspection points, grouped into relevant categories. It must be editable by Platform Admin through the content-management screens, not hardcoded into the Flutter application.

Research suitable UAE inspection practices and have the final checklist validated by an automotive inspection specialist. Do not represent the checklist as an official government inspection or certification unless the workshop is authorized to provide that service.

Candidate categories include:

- Vehicle identity and intake.
- Exterior body panels and paint.
- Glass, mirrors, lights, and wipers.
- Tyres, wheels, and brakes.
- Interior and occupant safety.
- Engine and visible mechanical systems.
- Transmission and drivetrain.
- Steering and suspension.
- Electrical systems and air conditioning.
- Underbody and exhaust.
- Road test and diagnostics.
- Conditional EV/hybrid checks.

Each inspection item should support:

- Stable item ID.
- English and Arabic label.
- Inspection instruction.
- Optional Russian/Chinese translations.
- Category.
- Applicability rules.
- Result options.
- Severity guidance where relevant.
- Whether a note is required.
- Whether a real evidence photo is required.
- Guide-image reference.
- Required tool/equipment.
- Reasons available when the item is not checked.
- Version and publishing history.

Keep these two image types distinct:

1. **Guide image:** teaches the technician where or how to inspect an item.
2. **Vehicle evidence image:** a real photo of this specific vehicle during this inspection.

A guide image must never be displayed as if it were evidence of the inspected vehicle.

Suggested results:

- No issue observed in this check.
- Attention recommended.
- Defect found.
- Not checked.
- Not applicable.
- Could not verify.

Require a reason for “not checked” and “could not verify.” Define severity levels such as Minor, Moderate, Major, and Safety-critical with clear UAE-appropriate guidance. Do not imply that “no issue observed” means that the vehicle is perfect.

Do not force every point to require a real photo without validating the practical inspection time and report size. Platform Admin can define photo requirements for individual items, and workshop templates can only change them if the platform permits.

### Equipment

Platform Admin can associate tools with checklist items. The technician app displays the equipment list for the selected template or service.

Potential tools include a flashlight, tyre-pressure gauge, tyre-depth gauge, OBD scanner, battery tester, paint-thickness gauge, lift, or other validated tools. Treat these as examples to be confirmed with an automotive specialist.

If equipment is unavailable or a check is unsafe, the technician records the limitation. Do not force a technician to perform unsafe work.

---

## 8. Inspection workflow and statuses

The customer visits or contacts the partner workshop. The workshop handles payment. The technician records details, performs the inspection, and finalizes it. The system then creates the report.

### Main flow

1. Customer provides details to workshop staff.
2. Workshop Admin creates or schedules a job, or the technician starts an authorized walk-in job.
3. Workshop Admin assigns a technician when required.
4. Technician opens the job.
5. Technician records or confirms customer details, vehicle details, consent, and inspection scope.
6. App displays tools and checklist version.
7. Technician completes applicable items and takes real vehicle photos.
8. App checks required answers and evidence.
9. Technician reviews their report and uses **Approve & Generate Report** or a similarly clear finalization button.
10. Server locks the inspection and creates the report.
11. System creates an English-Arabic PDF and public URL if the required sharing consent is recorded.
12. System sends the link and PDF through the selected channels.

The technician’s approval is a **self-finalization action**, not a manager’s review or independent verification. Store the final status as something like `FINALIZED`, not a manager-approved state.

### Suggested inspection statuses

- `DRAFT`
- `SCHEDULED`
- `ASSIGNED`
- `IN_PROGRESS`
- `READY_TO_FINALIZE`
- `FINALIZED`
- `CANCELLED`

Do not include manager-review or resubmission statuses.

Keep message delivery status separate, for example:

- `QUEUED`
- `SENT`
- `DELIVERED`, if the provider supplies that status
- `FAILED`
- `RETRY_PENDING`

---

## 9. Customer intake and consent

The technician or workshop staff records customer and vehicle information in the technician/admin system. There is no customer login.

Possible fields:

- Customer name as provided.
- Mobile phone number with country code.
- Email address if the customer wants the PDF emailed.
- Preferred communication/report language.
- Preferred delivery channels.
- Consent to send links/PDFs.
- Consent to create a publicly accessible report link.
- Vehicle make, model, year, and variant.
- VIN and registration details.
- Odometer reading and units.
- Workshop, technician, date, scope, and customer instructions.

Collect only information the workshop needs. The public report must not show customer name, email, phone, precise location, full VIN, or registration details by default.

Record when and how consent was obtained. Consent is separate for processing, the public link, each delivery channel and (if enabled) PDF download. Finalization may succeed without public-link consent; the public link stays inactive until the specific public-link consent is recorded. Exact privacy and consent wording must be reviewed for the UAE before production.

---

## 10. Public report and PDF

The report is the most important customer-facing product.

### Public report contents

- Vehicle make, model, year, and approved vehicle details.
- Odometer reading and units, if approved for publication.
- Inspection date and time.
- Partner workshop and technician information.
- Inspection scope and template version.
- Summary of key findings.
- Coverage count for applicable checklist items.
- Category-by-category results.
- Defect severity, explanation, and recommendation.
- Evidence photos linked to the relevant item.
- Checks not completed and their reasons.
- Road-test or diagnostic limitations.
- Report version and publication date.
- Clear limitations and disclaimer.

The report should offer English and Arabic. It must display public-approved information only.

### Bilingual PDF

- Include both English and Arabic.
- Render Arabic right-to-left correctly.
- Use a layout tested with long descriptions, findings, and photographs.
- Include report version and ID on each page or in a consistent header/footer.
- Keep public report and PDF contents consistent.
- Ensure the PDF can display Russian and Chinese customer names or notes when entered.

Test the PDF-generation technology with real Arabic and mixed-language examples before choosing it. Do not assume a PDF library supports correct Arabic shaping and font fallback without testing.

### Scoring and trust

Do not use a single unexplained numerical condition score as the primary summary.

Show inspection coverage, findings, and limitations instead. For example:

> 104 of 110 applicable checks were completed.
> Four checks were not applicable and two could not be verified.
> This is inspection coverage, not a vehicle condition score.

Clearly explain that the report records the vehicle as inspected at a particular time and within a defined scope. It is not a guarantee that the vehicle has no faults or will remain unchanged.

Do not label the report “independently reviewed” or “certified” unless that is factually true and legally appropriate.

---

## 11. Report URLs, sharing, and delivery

Create an unguessable public report URL hosted on our server.

Requirements:

- A report must open directly from a WhatsApp, SMS, or email link.
- No account or app installation is required for the viewer.
- Use a long, random token, not a sequential report ID.
- Store a protected token representation in the database.
- Make the public link active only when the required customer consent is recorded.
- Allow an authorized Workshop Admin to deactivate the link with a reason.
- Do not index reports in search engines.
- Do not expose customer details or private vehicle identifiers.
- Do not permanently expose original high-resolution evidence files.
- If a link is invalid or revoked, show a neutral message without revealing vehicle information.

Anyone who receives an active public link may be able to open it. Inform the workshop/customer of this. Revoking a link prevents future server access but cannot remove copies, downloaded PDFs, or screenshots already saved by someone else.

### Messaging and email

The system should support:

- Sending a report URL through WhatsApp.
- Sending a report URL through SMS.
- Sending a bilingual PDF by email.
- Authorized manual download and resend if automated delivery fails.

Use an approved business messaging provider and check the current provider rules. Store delivery attempts and results. A message failure must not delete or change a report.

Do not place customer phone numbers, full VINs, or private report details in link previews or application logs.

The workshop handles payment outside the platform. Do not add card forms or payment-processing API endpoints to Version 1.

---

## 12. Flutter application surfaces

Use Flutter for the requested mobile applications and web applications. Organize the code so common UI, localization, networking, and data models can be shared without giving every role access to every feature.

Recommended application targets:

1. **Technician Mobile App** — Flutter for Android and iOS.
2. **Admin Mobile App** — Flutter for Workshop Admin and Platform Admin permissions.
3. **Admin Website** — Flutter Web with role-based Workshop Admin and Platform Admin screens.
4. **Public Report Website** — server-rendered HTML report page served by the Java server from a public report URL (D4 approved). Flutter is not used for the public report in V1.

There is **no customer mobile app and no customer portal website**.

The Java server must enforce role and workshop permissions. A hidden Flutter screen is not a security control.

For direct public report links, the Java server returns a server-rendered HTML document with neutral metadata (no customer data, no vehicle details), `noindex`, and the correct cache/referrer headers. The link must open reliably from an external messaging app and must not expose private content in previews.

---

## 13. Java backend and technical architecture

Use Java with a current, supported Spring Boot version after verifying the official documentation.

For Version 1, build a **modular monolith** rather than many microservices. Keep clear module boundaries:

- Authentication and account management.
- Workshop tenancy and user membership.
- Platform Admin hierarchy.
- Master content and translations.
- Workshop templates.
- Inspection jobs and assignments.
- Technician assessments and findings.
- Media and evidence.
- Report snapshots, public links, and PDFs.
- WhatsApp/SMS/email delivery.
- Audit history.

Recommended supporting technology:

- MySQL 8.4 LTS (SQL database) for structured data. D1 approved; see §13A.1.1.
- Object storage for photos, videos, guide images, and generated PDFs.
- A background worker (database-backed outbox plus job runner; see §13A.4.3) for PDF rendering, image processing, and message delivery.
- Provider adapters for WhatsApp, SMS, and email so the business is not permanently tied to one vendor.
- Local development services that can later be replaced with self-hosted production services.

Use database migrations. Do not keep production secrets in source code.

---

## 13A. Technology stack and engineering decisions (added in v0.2)

> **Version policy:** this section deliberately lists **no version numbers**; versions were not checked when it was written. Phase 2 starts with a "version lock" task (check pub.dev, Maven Central and official release pages, then pin versions).
>
> Legend: **[DECIDED]** the product owner decided it. **[RECOMMENDED]** proposed, accepted unless objected to. **[OPEN]** needs an answer or a Phase 1/2 spike. **[VERIFY]** licence or version not yet checked.

### 13A.1. Technology decisions at a glance

| Area                    | Choice                                            | Status                                     |
| ----------------------- | ------------------------------------------------- | ------------------------------------------ |
| Client framework        | Flutter (Dart)                                    | DECIDED                                    |
| Monorepo tooling        | Melos + Dart pub workspaces                       | DECIDED / VERIFY workspace support         |
| Flutter version pinning | FVM                                               | RECOMMENDED                                |
| Routing                 | go_router                                         | DECIDED                                    |
| Animation               | flutter_animate                                   | DECIDED                                    |
| State management        | Riverpod                                          | DECIDED                                    |
| Backend language        | Java (current LTS) + Spring Boot (current stable) | DECIDED (Java) / VERIFY versions           |
| Backend style           | Modular monolith (Spring Modulith)                | DECIDED                                    |
| Database                | **MySQL 8.4 LTS** (SQL)                           | DECIDED (D1)                               |
| Migrations              | Flyway                                            | RECOMMENDED                                |
| Object storage          | S3-compatible interface; MinIO local-only; production TBD | DECIDED interface / D6 OPEN |
| Background jobs         | DB-backed outbox + JobRunr                        | RECOMMENDED / VERIFY licence               |
| PDF                     | Server-side; headless Chromium (D5)               | DECIDED                                    |
| Push                    | Firebase Cloud Messaging                          | RECOMMENDED                                |
| Hosting                 | Local now, own server later                       | DECIDED                                    |

#### 13A.1.1 About "SQL instead of Postgres"

"SQL" is a query language, not a database product. Postgres, MySQL, MariaDB and SQL Server all use it. The database is **MySQL 8.4 LTS** (D1 approved). It is common, free, well supported by Java and easy to self-host. Do not build against MySQL 8.0, which is end-of-life. Everything below that depends on this choice is marked **(MySQL)**.

Consequences of choosing MySQL instead of Postgres, and how we handle them:

| Postgres feature we would have had               | MySQL approach                                                                                                                                                                                                               |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Row-level security for workshop isolation        | Not available. Enforce isolation in the application layer: every workshop-owned table has `workshop_id`, every query goes through a tenant-aware repository layer, plus automated cross-workshop tests that must pass in CI. |
| Native UUID type                                 | Store UUIDv7 as `BINARY(16)`.                                                                                                                                                                                                |
| Rich JSONB                                       | Use MySQL `JSON` columns only for the frozen report snapshot and flexible settings. Keep searchable data in normal columns.                                                                                                  |
| Strong partial indexes and exclusion constraints | Use composite and unique indexes plus application checks.                                                                                                                                                                    |
| Arabic/Chinese full-text search                  | Use `utf8mb4` everywhere. For catalogue search use simple `LIKE`/prefix indexes first; add the ngram parser for CJK or an external search engine only if needed (OPEN).                                                      |

**Mandatory MySQL settings [RECOMMENDED]:**

- Character set `utf8mb4` with a Unicode collation, so Arabic, Cyrillic and Chinese text are stored exactly as entered.
- All timestamps stored in UTC (UAE is UTC+4; display conversion happens in the app).
- InnoDB, `STRICT_ALL_TABLES` SQL mode.
- Separate database users: a migration user (schema changes), an application user (no schema rights), and a read-only reporting user. The application user gets **no UPDATE/DELETE** on tables that hold finalized data (see §13A.5.1).

---

### 13A.2. Repository layout (monorepo)

One repository, two top-level areas. [RECOMMENDED]

```
inspection-platform/
├── MASTER.md
├── docs/                      # phase documents, diagrams, ADRs
├── client/                    # Flutter workspace (Melos)
│   ├── pubspec.yaml (workspace root)
│   ├── apps/
│   │   ├── technician_app/    # Android + iOS
│   │   ├── admin_app/         # Android + iOS + Web (one codebase, 2 roles)
│   │   └── (public report is server-rendered by the Java server, not a Flutter app)
│   └── packages/
│       ├── core/              # errors, result types, logging, utils
│       ├── design_system/     # tokens, theme, widgets, RTL helpers
│       ├── l10n/              # ARB files, locale helpers
│       ├── api_client/        # generated + hand-written API layer
│       ├── domain/            # shared models (freezed)
│       ├── auth/              # sign-in, token storage, guards
│       ├── offline_sync/      # local DB, sync queue, upload queue
│       ├── media/             # capture, compress, upload helpers
│       └── report_ui/         # report widgets shared by web + admin viewer
├── server/                    # Java backend (Maven multi-module or single module with packages)
│   └── src/main/java/.../
│       ├── identity/  tenancy/  masterdata/  templates/
│       ├── inspections/  media/  reports/  delivery/  audit/
│       └── shared/
├── infra/
│   ├── docker-compose.yml     # MySQL, MinIO, Mailpit, server
│   └── scripts/
└── .github/workflows/         # CI
```

**Decision (D2 approved):** one `admin_app` Flutter project with both Workshop Admin and Platform Admin screens, selected by role, with feature folders per role and server-enforced permissions.

**Why the public report is its own app:** it must be small, fast to load from a WhatsApp link, and must contain no admin code.

---

### 13A.3. Flutter decisions

#### 13A.3.1 Core tooling

| Purpose         | Package / tool                              | Notes                                                                                                             |
| --------------- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Monorepo        | `melos`                                     | Scripts for `bootstrap`, `analyze`, `test`, `gen`, `format`. VERIFY whether current Melos expects pub workspaces. |
| SDK pinning     | `fvm`                                       | Everyone uses the same Flutter version.                                                                           |
| Linting         | `very_good_analysis` (or `flutter_lints`)   | Strict rules in CI; analysis must pass with zero warnings.                                                        |
| Code generation | `build_runner`                              | Run through a Melos script.                                                                                       |
| Environments    | `--dart-define-from-file` + Flutter flavors | `dev`, `staging`, `prod`. No secrets in the app.                                                                  |

#### 13A.3.2 Architecture inside each app

Feature-first folders with clean layers: `presentation` (screens/widgets) → `application` (Riverpod notifiers) → `domain` (models/use-cases) → `data` (repositories, API, local DB). UI never calls the API directly.

#### 13A.3.3 State management

| Package                                                           | Purpose                                             |
| ----------------------------------------------------------------- | --------------------------------------------------- |
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | State, dependency injection, async data             |
| `freezed` + `freezed_annotation`                                  | Immutable models, sealed unions (e.g., sync states) |
| `json_serializable` + `json_annotation`                           | JSON                                                |

Why Riverpod [DECIDED, D3]: compile-time-safe DI, easy to test, works well for offline state and per-screen async data. Alternative: `flutter_bloc` (more boilerplate, very explicit). Do not mix both.

#### 13A.3.4 Navigation

`go_router` [DECIDED]:

- Declarative routes, deep links, redirect guards for auth and role.
- Web: use path URL strategy (`usePathUrlStrategy` from `flutter_web_plugins`) so links look like `/r/abc` rather than `/#/r/abc`.
- Guards are a convenience only. The server enforces permissions.
- Typed routes (`go_router_builder`) are optional [OPEN].

#### 13A.3.5 Animation

`flutter_animate` [DECIDED]. Rules so animation does not hurt a workshop tool:

- Short and subtle (list item fade/slide, success check, progress changes). No decorative motion on checklist screens.
- Respect the system "reduce motion" setting (`MediaQuery.disableAnimations`). Provide a central helper in `design_system` that disables or shortens effects.
- Never animate in a way that delays data entry.
- Use implicit Flutter animations where simpler; use `flutter_animate` for sequences and effects.
- Optional later: `lottie` for a few branded illustrations [OPEN].

#### 13A.3.6 Networking and API client

| Package                                                           | Purpose                                                           |
| ----------------------------------------------------------------- | ----------------------------------------------------------------- |
| `dio`                                                             | HTTP, interceptors (auth token, retry, locale header, request id) |
| `retrofit` + `retrofit_generator` **or** OpenAPI-generated client | Typed API                                                         |
| `pretty_dio_logger` (debug only)                                  | Debug logs; **never** log tokens, phone numbers or VINs           |

**Recommendation [RECOMMENDED]:** the Java server publishes an OpenAPI spec (springdoc-openapi). Generate the Dart client from it (`openapi-generator`, Dart-Dio generator) so Flutter and Java cannot drift apart. VERIFY generator quality before committing; fallback is hand-written `retrofit` interfaces.

Interceptors: attach access token; refresh-token rotation on 401 with a single in-flight refresh; `Accept-Language`; `Idempotency-Key` on finalize and other unsafe retries; exponential backoff for transient errors.

#### 13A.3.7 Offline and local storage (technician app)

| Package                          | Purpose                                                                                                        |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `drift` + `sqlite3_flutter_libs` | Local SQLite database: jobs, checklist version, answers, photo queue, sync log                                 |
| `flutter_secure_storage`         | Refresh token and sensitive keys                                                                               |
| `shared_preferences`             | Non-sensitive prefs (language, last tab)                                                                       |
| `connectivity_plus`              | Network hints (not a guarantee of internet)                                                                    |
| `workmanager`                    | Background upload/sync on Android; iOS background limits apply, so uploads must also resume when the app opens |
| `path_provider`                  | App file paths for stored photos                                                                               |

Why `drift` [RECOMMENDED]: type-safe SQL, migrations, reactive queries, good for a sync queue. Alternative: `isar` / `objectbox`; not recommended because relational data and migrations are central here.

#### 13A.3.8 Media

| Package                                                           | Purpose                                                      |
| ----------------------------------------------------------------- | ------------------------------------------------------------ |
| `image_picker` (start here) → `camera` (later, for guide overlay) | Capture                                                      |
| `flutter_image_compress`                                          | Compress to a target size before upload                      |
| `cached_network_image`                                            | Guide images and report photos                               |
| `photo_view` or `InteractiveViewer`                               | Zoom gallery                                                 |
| `permission_handler`                                              | Camera/storage permissions                                   |
| `exif` (read)                                                     | Capture time for evidence metadata; GPS is **not** published |
| `video_player`                                                    | Short evidence clips, only if approved [OPEN]                |

#### 13A.3.9 Localization (English, Arabic; Russian and Chinese ready)

| Item                    | Decision                                                                                                                                                                                                                                                                                                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Framework               | `flutter_localizations` + `intl`, ARB files, generated `AppLocalizations`                                                                                                                                                                                                                                                                                                 |
| Locale codes            | `en`, `ar`, later `ru`, `zh-Hans` (D10 approved)                                                                                                                                                                                                                                                                                                                    |
| RTL                     | Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`. **Ban** hardcoded `left/right` in lint review. Mirror directional icons (arrows, back). Numerals and VINs stay LTR inside RTL text via explicit direction wrappers.                                                                                                                                     |
| Three separate settings | App language, per-field text direction, report language (see §6)                                                                                                                                                                                                                                                                                                          |
| Fonts                   | **Bundle** fonts with the app and PDF; do not rely on `google_fonts` fetching at runtime (workshop internet is poor). Candidates: a Latin+Arabic family (e.g. IBM Plex Sans / Noto Sans Arabic) plus a CJK fallback (Noto Sans SC). VERIFY licences and app-size impact; CJK fonts are large, so consider subsetting or loading Chinese only when that locale is enabled. |
| Input                   | Text fields accept any Unicode. Set `textDirection` and `keyboardType` per field. We cannot force the OS keyboard language; show a help hint to add/switch keyboards (decision from §6).                                                                                                                                                                                  |
| Catalogue content       | From server (`localized_content`), not ARB. ARB is only for fixed UI text.                                                                                                                                                                                                                                                                                                |

#### 13A.3.10 Forms, validation, input

| Package                                                                    | Purpose                                  |
| -------------------------------------------------------------------------- | ---------------------------------------- |
| `reactive_forms` **or** `flutter_form_builder` + `form_builder_validators` | Complex forms (intake, template builder) |
| `phone_form_field` (or `intl_phone_field`)                                 | International phone input                |
| `mask_text_input_formatter`                                                | Odometer, plate masks if needed          |

Pick **one** forms approach [OPEN]. VIN: validate length/characters client-side as a hint; the server is authoritative.

#### 13A.3.11 UI and design system

- Material 3 as the base, heavily themed through a `ThemeExtension` token set (colours, spacing, radii, status/severity colours). Premium, calm, trustworthy look: not a generic admin template.
- Status and severity must use colour **plus** icon **plus** text (accessibility).
- Components in `design_system`: buttons, cards, status chips, severity badges, evidence gallery, progress header, empty/error/loading states, offline banner, data table (web).
- Responsive: `LayoutBuilder` / breakpoints; admin web uses side navigation; mobile uses bottom nav or stepper.
- Web tables: `data_table_2` or `pluto_grid` [OPEN]; choose in Phase 1.
- Tree view for the Platform Admin hierarchy: custom widget or `flutter_fancy_tree_view` [OPEN].
- Icons: Material Symbols (built in). Mirror in RTL where meaning is directional.
- Accessibility: minimum tap targets, text scaling, semantic labels, contrast checks, screen-reader pass.

#### 13A.3.12 Utilities

| Package                                            | Purpose                                                      |
| -------------------------------------------------- | ------------------------------------------------------------ |
| `url_launcher`                                     | Open links, call, WhatsApp                                   |
| `share_plus`                                       | Share report link from admin/technician app                  |
| `package_info_plus`, `device_info_plus`            | Diagnostics (sent without personal data)                     |
| `uuid`                                             | **Client-generated UUIDs** for offline-created records       |
| `intl`                                             | Dates, numbers, plurals                                      |
| `logger` or `talker`                               | Local logging with redaction                                 |
| `sentry_flutter`                                   | Crash and error reporting [RECOMMENDED]; scrub personal data |
| `firebase_core`, `firebase_messaging`              | Push notifications for technicians (new job assigned)        |
| `local_auth`                                       | Optional biometric unlock for the app [OPEN]                 |
| `google_mlkit_text_recognition` / `mobile_scanner` | VIN scanning, **deferred** until core flow is proven         |

#### 13A.3.13 Flutter testing

| Layer                        | Tooling                                                                    |
| ---------------------------- | -------------------------------------------------------------------------- |
| Unit                         | `flutter_test`, `mocktail`                                                 |
| Riverpod                     | `ProviderContainer` overrides                                              |
| Widget                       | `flutter_test`                                                             |
| Golden (visual, EN + AR/RTL) | `alchemist` or `golden_toolkit` alternative                                |
| Integration                  | `integration_test`; `patrol` optional for native permission dialogs [OPEN] |
| Real-device checks           | Android + iOS: keyboards, Arabic, camera, offline (manual test plan)       |

Must-have automated checks: every key screen renders in `ar` without overflow; offline queue survives app kill; finalize is idempotent.

---

### 13A.4. Java backend decisions

#### 13A.4.1 Platform and build

| Item      | Decision                                                                                                                                |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Java      | Current LTS release [VERIFY which LTS is current when Phase 2 starts]                                                                   |
| Framework | Spring Boot, current stable line [VERIFY]                                                                                               |
| Build     | Maven (simple, widely known) [RECOMMENDED]; Gradle is acceptable if the team prefers it                                                 |
| Structure | **Modular monolith**: packages (or Maven modules) = business modules; **Spring Modulith** verifies boundaries in tests [RECOMMENDED]    |
| Quality   | Spotless (formatting), Checkstyle or Error Prone, JaCoCo (coverage), ArchUnit (rules such as "no module reads another module's tables") |

#### 13A.4.2 Modules (match §13)

`identity` · `tenancy` (workshops, memberships) · `masterdata` (categories, items, translations, dropdowns, guide images, equipment) · `templates` (workshop templates + versions) · `inspections` (jobs, assignments, answers, findings) · `media` (evidence + derivatives) · `reports` (snapshots, public links, PDF) · `delivery` (WhatsApp/SMS/email) · `audit` · `shared`.

Modules talk through public Java interfaces and domain events, never by reading each other's tables.

#### 13A.4.3 Libraries

| Purpose               | Library                                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Web/REST              | Spring Web (MVC). Virtual threads optional once verified [OPEN]                                                      |
| Validation            | Jakarta Bean Validation                                                                                              |
| Security              | Spring Security, JWT access tokens + rotating refresh tokens (server-stored, hashed)                                 |
| Password hashing      | Argon2 (Spring Security Crypto + Bouncy Castle)                                                                      |
| Admin 2FA             | TOTP (D12 approved; implementation reviewed)                                                                         |
| Persistence           | Spring Data JPA / Hibernate **(MySQL)**; use jOOQ or `JdbcClient` for complex report queries if needed [OPEN]        |
| Migrations            | Flyway                                                                                                               |
| IDs                   | UUIDv7 generated in the app, stored `BINARY(16)` **(MySQL)**                                                         |
| Mapping               | MapStruct (DTO ↔ entity)                                                                                             |
| API docs              | springdoc-openapi (feeds the Dart client)                                                                            |
| Errors                | RFC 9457 Problem Details (`application/problem+json`)                                                                |
| Rate limiting         | Bucket4j (login, public report, resend)                                                                              |
| Cache                 | Caffeine in-process; Redis only if/when we scale to several servers [OPEN]                                           |
| Phone numbers         | `libphonenumber`                                                                                                     |
| Images                | Thumbnailator (resize) + `metadata-extractor` (read/strip EXIF)                                                      |
| Object storage client | AWS SDK v2 for Java (S3 API: works with MinIO and many others)                                                       |
| Email                 | Spring Mail (SMTP) behind a `MailSender` adapter                                                                     |
| WhatsApp / SMS        | Provider adapters behind `MessageChannel` interface; provider choice OPEN                                            |
| Jobs                  | Outbox table + **JobRunr** (DB-backed scheduler/worker) [VERIFY licence/features] or plain Spring scheduler + outbox |
| Observability         | Micrometer + Prometheus + Grafana; structured JSON logs (Logback) with redaction; Sentry for errors [RECOMMENDED]    |

#### 13A.4.4 Backend testing

JUnit 5, Mockito, AssertJ, **Testcontainers** (real MySQL and MinIO in tests), Spring `MockMvc`/`WebTestClient`, ArchUnit, Awaitility (async jobs).

**Required automated suites:**

1. Cross-workshop isolation: workshop A can never read or write workshop B (every endpoint).
2. Immutability: no endpoint and no DB path can change finalized findings.
3. Role matrix per endpoint.
4. Finalize idempotency (double submit, retry after timeout).
5. Public report allowlist (no private fields leak).
6. Revoked-link behaviour.

---

### 13A.5. Database (MySQL) design rules

Tables as listed in §15. Additional rules:

- Every workshop-owned table includes `workshop_id` and an index starting with it.
- All primary keys are UUIDv7 (`BINARY(16)`), generated by the app, so **offline clients can create records safely**.
- `created_at`, `updated_at` in UTC; `version` column for optimistic locking on editable (pre-final) rows.
- Soft-disable users/workshops (status), never hard-delete records that reports depend on.
- Catalogue versioning: `master_item_versions` is append-only. Templates reference **versions**, not items.
- At finalization, copy the exact wording, answers, severities, translations and template version into `inspection_item_snapshots` and the report snapshot JSON. The report never joins live catalogue tables.
- Public tokens: generate at least 256 bits randomly; store only a **hash** (e.g. SHA-256) of the token; lookup by hash.
- Evidence files: store object key, content hash (SHA-256), size, MIME type, captured-at, uploader. Originals private; public derivatives are separate objects.
- No payment-card columns anywhere.

#### 13A.5.1 Enforcing immutability (defence in depth) **(MySQL)**

1. **Application:** no update/delete code paths for finalized data; domain method `finalize()` sets a locked state.
2. **Database triggers:** `BEFORE UPDATE`/`BEFORE DELETE` triggers on `assessments`, `findings`, `evidence_assets`, `inspection_item_snapshots`, `reports`, `report_versions` that raise an error when the parent inspection is `FINALIZED`.
3. **Database permissions:** the application database user has no `UPDATE`/`DELETE` privilege on report/snapshot tables.
4. **Integrity check:** store a hash of the report snapshot; a scheduled job recomputes and alerts on mismatch.
5. **Tests:** direct SQL attempts as the app user must fail.

Corrections: **no correction UI or API is built in V1** (D9 approved). If a correction policy is approved later, it must create a new **immutable report version** that references the earlier one, with a visible correction note and reason; the earlier version is never modified. The policy for who may create a correction remains open.

---

### 13A.6. API conventions

- Base path `/api/v1`. Resource-style endpoints; JSON.
- Auth header `Authorization: Bearer <access token>`.
- Errors: Problem Details with a stable machine-readable `code` and a translatable message key.
- Pagination: cursor-based for long lists (jobs, audit).
- **Idempotency:** `Idempotency-Key` header required on finalize, resend and other unsafe retries; server stores outcome.
- **Conflict detection:** `If-Match`/version fields; server returns 409 on stale writes and never silently overwrites.
- Locale: `Accept-Language` for server-generated messages; stored content keeps its original language.
- Rate limits on login, public report and resend endpoints.
- Public endpoints are isolated under `/r/{token}` and `/api/v1/public/...` with an explicit allowlist serializer.

---

### 13A.7. Offline and upload design (technician)

1. When a job is assigned or opened, the app downloads the job plus the **exact checklist/template version** and guide images, and stores them in Drift.
2. Every answer is written to the local DB immediately with a client revision number.
3. Photos: captured → compressed → saved locally → added to an upload queue (target roughly 1–2 MB each [VERIFY by real tests]).
4. Sync sends answers as batches (`PUT` upserts keyed by client-generated UUID) and photos via **short-lived pre-signed upload URLs** to object storage, with retry. Resumable/chunked upload is added only if tests show it is needed [OPEN].
5. UI always shows two states: **Saved on this phone** and **Received by server** (per item, plus overall).
6. Finalize is enabled only when mandatory data and required photos have been **received by the server**. Server confirms before the UI says "Finalized".
7. The public report is generated and available only after server finalization.
8. Conflicts (e.g. job reassigned while offline) are detected by version and shown to the technician; never silently overwritten.

---

### 13A.8. Reports, PDF and public link

- **Report snapshot:** built once at finalization, stored as JSON plus a hash; public pages and PDFs render from this snapshot only.
- **Public web (D4 approved):** server-rendered HTML at `/r/{token}` from the Java server. It renders only the immutable report snapshot through an explicit public allowlist, with neutral metadata (no customer data, no vehicle details), `noindex`, and `Referrer-Policy`/cache headers. Flutter is not used for the public report in V1.
- **PDF engine (D5 approved): headless Chromium** (for example Playwright for Java) rendering a dedicated print HTML template. OpenHTMLtoPDF is rejected for V1 because the Phase 1 spike showed broken Arabic shaping/bidi.
  - Chromium renders the browser-grade Unicode bidi/shaping stack. It is heavier to operate; PDF generation runs in a worker with a queue, health checks and a patching process.
  - **Spike test content:** long Arabic paragraphs, mixed Arabic+English+numbers+VIN, Russian and Chinese customer names, many photos, multi-page tables.
- PDF fonts are bundled on the server. Each page footer shows report ID and version.
- Link rules: unguessable token, revocable by Workshop Admin with a recorded reason, invalid/revoked shows a neutral message, no search indexing, no original high-resolution files exposed.

---

### 13A.9. Storage, hosting and environments

| Environment | Setup                                                                                  |
| ----------- | -------------------------------------------------------------------------------------- |
| Local dev   | `docker compose`: MySQL, MinIO, Mailpit (fake email), the Java server. Fake data only. |
| Staging     | A small internet-reachable server, HTTPS, test messaging accounts                      |
| Production  | Own server (location TBD)                                                              |

- **Object storage (D6 Pending):** MinIO is local-development only and must not be used in production. Use an S3-compatible interface so a maintained provider (shortlist: AWS S3 UAE / OCI Object Storage UAE) can be selected later. Provider choice and data residency remain open.
- **Reverse proxy:** Nginx or Caddy with HTTPS (automatic certificates), security headers, request size limits.
- **A report link needs a public server and domain.** Localhost links cannot be opened by customers.
- **Production readiness checklist:** off-site encrypted backups, a tested restore, UPS/power plan, patching, monitoring and alerts, incident process, domain/DNS, certificate renewal.
- Legal review for UAE data protection before any real customer data; India review before expansion.

---

### 13A.10. Security checklist (summary)

HTTPS only · server-side authorization on every call · tenant isolation tests · short-lived access tokens, rotating refresh tokens · stronger login for admins (2FA) · rate limiting · upload validation (type, size, content sniffing; consider ClamAV) · EXIF stripped from public images · private storage + signed URLs · redacted logs (no phones, VINs, tokens) · audit events for account changes, finalization, link revocation, resend · secrets in environment/secret store, never in git or in the Flutter app · dependency scanning in CI.

---

### 13A.11. CI/CD and developer workflow

- Git: trunk-based with short feature branches and pull requests; conventional commit messages.
- **CI (GitHub Actions or equivalent) [RECOMMENDED]:** Flutter analyze + test + golden tests (EN/AR); Java build + unit + Testcontainers tests + ArchUnit; OpenAPI spec generated and Dart client regenerated, with CI failing if they drift; dependency and secret scanning.
- Builds: Fastlane or Codemagic for Android/iOS; pilot distribution through Firebase App Distribution / TestFlight.
- Architecture Decision Records (ADRs) in `docs/adr/` for every choice marked OPEN once resolved.

---

### 13A.12. Decision log (to be closed before or during Phase 1/2)

| #   | Decision                                             | Status                            |
| --- | ---------------------------------------------------- | --------------------------------- |
| D1  | Database product: MySQL 8.4 LTS                      | DECIDED                           |
| D2  | One `admin_app` for both admin roles                 | DECIDED                           |
| D3  | Riverpod vs Bloc                                     | DECIDED: Riverpod                 |
| D4  | Public report as Flutter Web vs server-rendered HTML | DECIDED: server-rendered HTML     |
| D5  | PDF engine                                           | DECIDED: headless Chromium        |
| D6  | Production object storage                            | OPEN                              |
| D7  | Forms package                                        | OPEN                              |
| D8  | WhatsApp, SMS, email providers                       | OPEN                              |
| D9  | Correction/new-version policy                        | DECIDED: no correction UI/API in V1 |
| D10 | Chinese variant (`zh-Hans`)                          | DECIDED: `zh-Hans`                |
| D11 | Photo requirements per item and size limits          | OPEN: pilot tests                 |
| D12 | Admin 2FA method                                     | DECIDED: TOTP                     |
| D13 | Version lock of all packages                         | DECIDED: Phase 2 lock recorded    |

### 13A.13. Rejected / deferred for Version 1

Customer app or portal · in-platform payments · marketplace · manager role or review queue · admin editing of findings · AI diagnosis or valuation · microservices · custom keyboard · multi-workshop technicians (until approved) · VIN scanning/OCR (deferred) · video evidence (pending approval).

## 14. Offline technician operation

The technician may work in a workshop with weak internet.

The app must:

- Download assigned inspection information and the required checklist version.
- Save each answer locally as it is entered.
- Save captured photos locally before upload.
- Retry failed uploads safely.
- Resume interrupted uploads where supported.
- Prevent duplicate final submissions.
- Show the difference between local saving and server receipt.
- Detect conflicting edits and avoid silently overwriting data.

The app may allow the technician to complete the inspection offline, but the public report must not become available until the server has received the required inspection data and evidence.

Do not show “submitted” until the server confirms receipt.

---

## 15. Database and data model

Design a relational schema that supports multiple partner workshops and immutable report history.

Consider records such as:

- `workshops`
- `users`
- `workshop_memberships`
- `customers`
- `vehicles`
- `inspection_jobs`
- `assignments`
- `inspection_categories`
- `master_inspection_items`
- `master_item_versions`
- `localized_content`
- `master_dropdown_values`
- `guide_images`
- `workshop_templates`
- `template_versions`
- `template_items`
- `inspection_item_snapshots`
- `assessments`
- `findings`
- `evidence_assets`
- `reports`
- `report_versions`
- `public_share_links`
- `consent_records`
- `delivery_attempts`
- `audit_events`

Data rules:

- Every workshop-owned record is linked to its workshop.
- Users can access only the workshops they are authorized to access.
- Each inspection stores the exact template version used.
- Each completed report is an immutable snapshot.
- Published template changes do not rewrite old inspections.
- A public report uses an approved data snapshot, not direct access to all internal records.
- Store original media privately; generate safe derivatives for public display.
- Do not store payment-card information.

---

## 16. API design

Use a versioned API such as `/api/v1`. The exact endpoint names can be decided during architecture design. Include endpoints for:

- Sign-in, token renewal, and sign-out.
- Platform Admin workshops and staff tree.
- Workshop membership and account management.
- Master inspection library and localized content.
- Workshop template creation and publication.
- Technician job list and inspection details.
- Checklist answer updates and media upload.
- Inspection finalization.
- Report and PDF generation.
- Public share links and revocation.
- WhatsApp/SMS/email sending and delivery status.
- Audit history.

The backend must enforce:

- Workshop-level separation.
- Role permissions.
- Finalized-report immutability.
- Safe, idempotent retries.
- Required inspection fields before finalization.
- Public-data allowlists.
- Audit logging of important actions.

An Admin must not be able to bypass report immutability by calling an API directly.

---

## 17. Security, privacy, and hosting

### Security requirements

- HTTPS for all production communications.
- Secure authentication and account recovery.
- Stronger authentication for Platform Admins and Workshop Admins where appropriate.
- Server-side authorization on every protected operation.
- Private evidence storage.
- Short-lived upload access where appropriate.
- File validation and safe media processing.
- Protection against unauthorized object access, malicious uploads, and common web vulnerabilities.
- Audit records for account changes, report finalization, corrections, and link revocation.
- Redaction of tokens, phone numbers, and sensitive data from logs.

### Local development and future server

Use fake customer and vehicle data during local development. A local `docker compose` setup can provide Java, MySQL, and a local object-storage service.

A report link hosted only on a developer’s computer cannot be opened by a customer outside that computer. Public links require an internet-accessible server, a domain, and HTTPS.

Keep the application portable so it can run locally first and later on an agreed self-hosted server. Before production:

- Choose the server and data-storage location.
- Set up backups and test restoring them.
- Secure server access and updates.
- Monitor application, database, storage, and delivery failures.
- Set privacy, retention, and incident-response processes.
- Keep provider credentials outside source code.

Review UAE data-protection requirements with qualified local counsel before storing real customer data. Review India requirements again before entering the Indian market. Do not claim legal compliance or official inspection certification without verification.

---

## 18. UX and screen inventory

Create a complete screen inventory and navigation map before implementation.

### Technician app

- Sign-in and language selection.
- Assigned inspections.
- Inspection details.
- Customer information.
- Vehicle identification.
- Consent.
- Equipment list.
- Checklist categories and progress.
- Inspection-item assessment.
- Photo/video capture.
- Final inspection check.
- Approve & Generate Report.
- Report and delivery status.
- Offline sync queue.

### Admin mobile app and website

- Dashboard.
- Workshop job list and filters.
- Create or schedule inspection job.
- Assign or reassign technician before finalization.
- Workshop staff management.
- Workshop template list.
- Template builder and preview.
- Completed report viewer in read-only mode.
- Delivery status and resend.
- Share-link deactivation with reason.
- Workshop settings.

### Platform Admin website and appropriate app screens

- Workshop/staff hierarchy tree.
- Workshop details.
- Workshop Admin and Technician account management.
- Shared master inspection-item library.
- Categories and answer options.
- Dropdown catalogue management.
- Translations and guide images.
- Equipment catalogue.
- Template/version overview.
- Audit events.
- Platform settings.

### Public report

- Summary.
- Vehicle and inspection information.
- Findings by category.
- Evidence photos.
- Items not checked.
- Limitations and disclaimer.
- Report version and verification details.
- English/Arabic language selection.
- PDF download is **disabled by default**. No download control is shown on the public page in V1; a later policy may enable a short-lived authorized download.

Every screen must describe loading, empty, error, success, and offline states. Mobile layouts must be designed for technicians using a phone with one hand in a workshop.

---

## 19. Research requirements

Before architecture or feature recommendations, perform genuine web research if browser access is available.

### Reference research

- Inspect the supplied AutoHub report and publicly accessible supporting pages.
- Record what was directly observed.
- Check its report layout on mobile and desktop.
- Check vehicle details, findings, photos, language behavior, sharing, and disclaimers only if they are actually visible.
- Do not infer hidden functionality.
- Do not copy branding, source code, protected content, or proprietary assets.

If the page cannot be reached, say so clearly and list what could not be verified.

### Product comparison

Research relevant official product material for:

- Digital inspection software.
- Automotive workshop inspection reporting.
- Professional used-vehicle inspection services.
- Vehicle-history products as a different, complementary category.

Compare workflow patterns and explain what is relevant. Do not claim a feature exists unless its source confirms it.

### Official and authoritative references

Use current official documentation where available, including:

- Flutter documentation for web, mobile, and localization.
- Java/Spring Boot documentation.
- MySQL documentation (and Flyway, Spring Data JPA, Spring Modulith documentation).
- WhatsApp Business Platform documentation.
- W3C guidance for Arabic layout and accessibility.
- Relevant UAE privacy and data-protection resources.
- India data-protection resources before future expansion.
- ISO/IEC 17020 only as a possible inspection-body reference, not as a checklist or a claim of certification.
- Government inspection manuals only as jurisdiction-specific examples. Do not present a foreign inspection manual as a UAE standard.

For every important factual claim, cite the source. Clearly label each finding as:

1. **Verified in a source**
2. **A product comparison observation**
3. **A recommendation**
4. **An assumption needing confirmation**

Never invent citations, current regulations, product features, or access to a reference page. If web research is not available, disclose that limitation.

---

## 20. Development phases

### Phase 0 — Research and requirements

Deliver:

- Research findings with citations and limitations.
- Confirmed product scope.
- User and permission model.
- Full workflow diagrams.
- Assumptions and unresolved questions.
- Initial risk register.
- Proposed roadmap.

**Gate:** Product owner approves the scope and assumptions. Do not code yet.

### Phase 1 — UX, domain, and architecture

Deliver:

- Navigation maps.
- Screen inventory.
- English/Arabic interaction and right-to-left rules.
- Platform Admin hierarchy design.
- Master library and workshop-template flows.
- Public report design.
- Database and API proposal.
- Offline and PDF approach.

**Gate:** Approve the experience and architecture before implementing modules.

### Phase 2 — Project foundation

Build:

- Flutter project structure for technician, admin mobile, admin web, and public report.
- Java backend foundation.
- Local development environment.
- Database migrations.
- Authentication.
- Workshop membership and role checks.
- Localization framework.
- Base design system.
- Automated test setup.

**Gate:** App and server run locally; roles and workshop separation are tested.

### Phase 3 — Platform Admin hierarchy and master content

Build:

- Workshop tree.
- Workshop Admin and Technician account management.
- Master inspection categories and items.
- Master dropdowns.
- Localized content management.
- Guide-image management.
- Equipment library.
- Content versioning and audit history.

**Gate:** Platform Admin can add and publish master content, and no content changes old reports.

### Phase 4 — Workshop Admin and templates

Build:

- Workshop job management.
- Technician assignment.
- Workshop staff screens.
- Template builder.
- Master item selection.
- Template order and permitted configuration.
- English/Arabic preview.
- Template publishing and versioning.

**Gate:** Workshop Admin can create and publish a template without changing master item wording or rules.

### Phase 5 — Technician inspection

Build:

- Job list and inspection details.
- Customer and vehicle intake.
- Consent recording.
- Equipment list.
- 100+ point checklist.
- Findings and severity.
- Guide images and evidence-photo capture.
- Offline save and retryable upload.
- Finalization checks.
- Technician finalization.

**Gate:** A technician completes a realistic inspection on a mobile device and can recover work after connectivity loss.

### Phase 6 — Reports, PDF, and public link

Build:

- Immutable report snapshot.
- Server-rendered HTML public report page.
- Public link generation and revocation.
- Bilingual English-Arabic PDF.
- Safe public fields and media processing.
- Correction history without silent overwrite.
- Report version display.

**Gate:** Public report and PDF match the finalized inspection and do not expose private details by default.

### Phase 7 — Messaging and delivery

Build:

- WhatsApp provider integration.
- SMS provider integration.
- Email PDF delivery.
- Delivery-status records.
- Retry and manual fallback.
- Consent checks.
- Message templates in English and Arabic.

**Gate:** Failed delivery does not lose or alter the report. Resends are auditable.

### Phase 8 — Pilot, security, and production readiness

Test:

- Partner-workshop data separation.
- Immutability of completed findings.
- Public-link security and revocation.
- Offline work and photo upload recovery.
- Arabic RTL interface and PDF.
- Russian and Chinese text entry and rendering.
- Direct report links from messaging apps.
- Accessibility and common security risks.
- Backups and restoration.
- Monitoring and incident handling.

Run a small partner-workshop pilot before broad launch. Do not launch India features until local legal, language, inspection, and operational requirements are researched.

---

## 21. Required tests and acceptance criteria

At minimum, test:

1. Platform Admin sees the full workshop/Admin/Technician hierarchy.
2. Workshop Admin sees only their workshop.
3. Platform Admin can add translated inspection items, dropdowns, guide images, and equipment requirements.
4. Workshop Admin can build and publish a template using approved items.
5. Workshop Admin cannot change locked master content.
6. New template versions do not change previous inspections.
7. Technician can enter Arabic, English, Russian, and Chinese names or notes.
8. Arabic interface and text fields have correct direction.
9. Keyboard-language behavior is tested on actual Android and iOS devices, including its operating-system limitations.
10. Technician can complete a 100+ point checklist and add vehicle evidence.
11. Technician can save work offline and safely sync it later.
12. Required fields are validated before finalization.
13. Technician finalization locks findings on the server.
14. Admin and Platform Admin cannot edit findings through the app, website, or API.
15. Report creation preserves the template, wording, answers, evidence, and version used.
16. Bilingual PDF displays English, Arabic, and entered Russian/Chinese text correctly.
17. Public URL works in a browser without login.
18. Revoked links stop serving report content.
19. Public reports do not expose customer contact information, full VIN, or private images by default.
20. WhatsApp, SMS, or email failures can be retried without changing the report.
21. No customer payment is processed or stored by our platform.
22. Workshop data is isolated in all API and file-access tests.

---

## 22. First response when this master prompt is used

In your first response:

1. Restate the confirmed scope in plain English.
2. Begin with **Phase 0 only**.
3. Perform and cite real web research if available.
4. Separate verified information from assumptions and recommendations.
5. State clearly if the AutoHub reference cannot be accessed.
6. List unresolved product and operating decisions without blocking the whole plan.
7. Propose the phase sequence and acceptance gates.
8. Do not generate application code until the product owner approves the next phase.

**Final product rule:** Partner workshops handle the customer and payment. Technicians record and finalize inspections in Flutter. Platform Admins control the shared inspection library and workshop hierarchy. Workshop Admins create templates from approved inspection items. Finalized findings cannot be edited by Admins. The system generates a bilingual report and a public URL that anyone with the link can open.







