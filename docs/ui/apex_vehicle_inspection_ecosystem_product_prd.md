# Product Requirements Document (PRD): Apex Fleet & Precision Vehicle Inspection Ecosystem

**Document Version:** 1.0.0  
**Status:** Approved / In Implementation  
**Product Hierarchy:** Platform Admin (Cloud) → Workshop Admin (Desktop/Tablet) → Field Technician (Mobile Native/PWA) → Customer Public Report (Responsive Web)  
**Design System Reference:** Field Technician Inspection System (Light Theme, Pure White #FFFFFF, Navy #1A1A24, Emerald #10B981)

---

## 1. Executive Summary & Vision

The **Apex Fleet & Precision Vehicle Inspection Ecosystem** is a multi-tier automotive diagnostic and condition reporting platform. It bridges high-precision shop-floor diagnostics (CAN-bus OBD2, laser tire tread depth gauges, optical paint depth meters) with enterprise fleet governance, workshop scheduling, and cryptographic customer-facing verification.

The platform eliminates manual, error-prone paper checklists and unstructured photo uploads, standardizing vehicle assessments according to ISO/IEC 17020 and OEM compliance standards while delivering consumer reports with radical visual clarity.

---

## 2. User Roles & Personas

| Role | Environment | Key Responsibilities | Primary Needs |
|---|---|---|---|
| **Platform Super Admin** | Desktop Web | Centralized governance, multi-tenant workshop provisioning, master item dictionary, translation catalog, audit compliance. | High-level control, zero spreadsheet clutter, immutable cryptographic logging, multi-region schema sync. |
| **Workshop Admin / Floor Manager** | Tablet / Desktop Web | Bay dispatch, technician scheduling, custom checklist builder, live queue management, PDF sign-off & customer delivery. | Real-time throughput metrics, seamless technician re-assignment, automated template deployment. |
| **Field Diagnostic Technician** | Rugged Mobile / Phone | Vehicle intake, 360° exterior visual marking, optical macro photo evidence capture, hardware sensor pairing, final sign-off swipe. | Ultra-fast single-hand input, offline resilience with queued synchronization, high-contrast daylight UI. |
| **Fleet Manager & Vehicle Owner** | Responsive Mobile & Desktop Web | Review certified inspection reports, review defect evidence & repair recommendations, download audited PDF certificate. | Transparent evidence, intuitive damage schematics, verifiable authenticity (tamper-evident SHA-256 seal). |

---

## 3. Product Architecture & Ecosystem Map

```
┌────────────────────────────────────────────────────────┐
│             PLATFORM ADMIN PORTAL (Desktop)            │
│  - Multi-tenant Workshop Registry & Hierarchy          │
│  - Master Inspection Library & Bilingual Taxonomy     │
│  - Global Hardware Equipment Registry & 2FA Security   │
└──────────────────────────┬─────────────────────────────┘
                           │ Syncs Catalog & Policies
┌──────────────────────────▼─────────────────────────────┐
│             WORKSHOP ADMIN CONSOLE (Tablet/Desktop)    │
│  - Bay Dispatch & Live Job Queue                       │
│  - Template Builder & Staff Shift Allocation           │
│  - Customer PDF Generation, WhatsApp/SMS Delivery      │
└──────────────────────────┬─────────────────────────────┘
                           │ Dispatches Job Tickets
┌──────────────────────────▼─────────────────────────────┐
│          FIELD TECHNICIAN APP (Mobile 16-Screen Flow)  │
│  - VIN/Odometer Intake & Consent Signature             │
│  - 360° Wireframe Hotspots & Macro Evidence Capture    │
│  - BLE Sensor Integration & Swipe Finalization         │
└──────────────────────────┬─────────────────────────────┘
                           │ Publishes Signed Dossier
┌──────────────────────────▼─────────────────────────────┐
│          PUBLIC VERIFIED REPORT (Mobile & Desktop Web) │
│  - Visual Customer Summary Hero                        │
│  - Interactive 2D Chassis / Tire Wear Hotspots         │
│  - Cryptographic Blockchain/SHA-256 Proof & PDF Export │
└────────────────────────────────────────────────────────┘
```

---

## 4. Key Functional Modules & Screen Specifications

### Module A: Platform Admin (Desktop Web — 11 Screens)
Centrally manages the network of franchised or company-owned inspection facilities.
1. **Global Hierarchy & Staff Tree**: Split-view organization tree (`Platform` → `Workshop A/B`) with node capacity metrics and quick staff addition.
2. **Add Staff / Create Account**: Secure modal drawer provisioning credentials, role assignments (Workshop Admin, Lead Inspector), and station scoping.
3. **Register New Workshop**: Streamlined onboarding flow defining operating region, default template suite, and automatic catalog sync pipelines.
4. **Workshop Details & Settings**: Diagnostics node status, active bay throughput counters, emergency dispatch phone, and master killswitch toggle.
5. **Shared Master Inspection Library**: Canonical catalog of diagnostic checkpoints categorised across Powertrain, Brakes, Tires, and Chassis.
6. **Master Item Content & Translation Editor**: Side-by-side English vs. Arabic (RTL) localized editor with schematic reference uploads.
7. **Master Dropdowns & Data Catalogues**: Global taxonomies (Vehicle Makes, Defect Severities P0–P3, Bypass Reasons).
8. **Global Equipment Library**: Network hardware fleet management (OBD2 scanners, digital micrometer tire gauges, paint depth probes).
9. **Global Platform Settings**: System-wide configuration covering session timeouts, mandatory TOTP 2FA, and real-time telematics webhooks.
10. **Platform Audit Events Log**: Tamper-proof activity ledger documenting privilege shifts, link revocations, and node provisioning.
11. **Admin 2FA / TOTP Verification**: Dedicated security challenge screen featuring segmented 6-digit pin input with hardware-token backup.

### Module B: Workshop Admin (Tablet / Desktop Web — 12 Screens)
Powers day-to-day operations on the active inspection floor.
1. **Workshop Dashboard**: High-level bay utilization, active job counter, pending finalizations, and live floor telemetry.
2. **Live Job Queue & Filters**: Card-based live queue with vehicle profiles, customer identifiers, assigned techs, and stage chips.
3. **Create / Schedule Job**: Slide-out intake drawer capturing customer contact, vehicle make/model, bay schedule, and protocol tier.
4. **Assign Technician**: Modal overlay highlighting certified available specialists, bay assignments, and workload balancing.
5. **Workshop Staff Management**: Roster overview featuring technician certifications (EV High-Voltage, Level 3 Master), active shifts, and access switches.
6. **Add Staff / Create Account**: Rapid floor personnel invitation drawer.
7. **Workshop Template List**: Grid of active blueprint protocols (100-Point Standard, EV High-Voltage, Quick Oil Service).
8. **Template Builder**: Drag-and-drop sequence architect allowing reordering and configuration of required photographic gates.
9. **Completed Report Viewer & Delivery**: Dossier delivery hub supporting one-click WhatsApp dispatch, SMS notifications, and PDF downloads.
10. **Share-Link Deactivation Warning**: Destructive action confirmation with mandatory justification logging for immediate public link revocation.
11. **Workshop Settings**: Local business credentials, operating address, DOT licensing, and automated customer dispatch triggers.
12. **Print-Ready PDF Preview**: Desktop document viewer rendering floating A4 physical compliance sheets with vector stamps and signatures.

### Module C: Field Technician Inspection (Mobile — 16 Screens)
Built for one-handed operation on rugged shop-floor mobile terminals.
1. **Login & Language Selector**: Rapid biometric/pin authentication and instant English/Arabic switch.
2. **Assigned Jobs Dashboard**: Card list of assigned vehicle queues, bay indicators, and quick-start actions.
3. **Empty State Dashboard**: Standby queue state indicating operational readiness.
4. **Job Details & Intake**: Vehicle identification number (VIN) validation, odometer snapshot, and intake logging.
5. **Consent & Signatures**: Digital customer intake waiver capture with capacitive touch signature pad.
6. **Equipment Checklist**: Mandatory pre-inspection Bluetooth pairing check for calibrated shop tools.
7. **Main Inspection Hub**: Section progress tracker breaking down inspection into distinct mechanical phases.
8. **360° Exterior Wireframe**: Interactive orthographic vehicle line-art wireframe allowing technicians to tap and pin damage markers.
9. **Defect Detail & Evidence**: Severity categorization (Cosmetic vs Structural) with millimeter dimensions and repair tags.
10. **Photo Annotation & Markup**: Camera preview with focal circle markup tools and macro detail validation.
11. **Dense Mechanical List**: Rapid-fire pass/advisory/fail checklist optimized for thumbs.
12. **Tire Condition Capture**: Interactive 4-wheel schematic capturing cold PSI pressure and digital groove depth readings per axle.
13. **Final Review (Missing Items)**: Validation gate ensuring zero mandatory checkpoints or required photo angles are omitted.
14. **Finalize & Approval (Swipe)**: High-intent directional slider preventing accidental job completion.
15. **Offline Sync Queue**: Local SQLite cache viewer ensuring background upload reliability in low-connectivity service bays.
16. **Post-Finalization Success**: Instant feedback confirmation with automated customer dispatch indicators.

### Module D: Public Verified Inspection Report (Mobile & Desktop Web — 7 Screens)
Consumer and fleet manager viewing interface designed for extreme credibility.
1. **Mobile Customer Summary Hero**: Vehicle photo header, compliance pass percentage (e.g., 95% Pass Rate), and core metrics.
2. **Mobile Category Findings (Tyre Defect)**: Minimalist top-down axle schematic highlighting defective tires with mechanic commentary and gauge photos.
3. **Mobile Exterior Condition & Evidence**: 2D line-art door locator accompanied by a high-resolution damage photo gallery.
4. **Mobile Verification & PDF Footer**: ISO 17020 compliance disclaimer, bilingual toggle, SHA-256 seal, and PDF download action.
5. **Desktop Wide Hero & Summary Overview**: Two-column layout featuring orthographic car renders, compliance matrix, and inspector credentials.
6. **Desktop Detailed Findings Grid**: Multi-card visual layout combining paint depth vectors, battery impedance, and underbody health.
7. **Desktop Limitations & Disclaimer Footer**: Documented excluded checkpoints (safety protocol bypasses) with legal liability shields.

---

## 5. Non-Functional & Technical Requirements

### 5.1 Design & Visual Standards (The "Strict Global Style")
- **Palette**: Pure White `#FFFFFF` canvas, Light Theme only (Zero dark mode).
- **Typography**: Chunky Dark Navy `#1A1A24` for bold headings, Soft Gray `#6B7280` for secondary metadata, Plus Jakarta Sans font family.
- **Accents**: Primary Emerald Green `#10B981`, Warning Pastel Amber `#F59E0B`, Destructive Pastel Red `#EF4444`.
- **Containers**: Heavy rounding (`rounded-3xl` / `rounded-2xl`) with diffuse, ambient drop shadows (`shadow-[0_16px_40px_rgba(0,0,0,0.03)]`). Extreme padding and whitespace throughout.

### 5.2 Offline First & Hardware Interoperability
- **Local Cache**: Technicians operate in underground/shielded service bays. All draft states, photos, and sensor inputs store locally in IndexedDB/SQLite before syncing via WebSockets.
- **Hardware Integration**: Bluetooth Low Energy (BLE 5.0) protocols for instant pairing with digital micrometers, OBD-II CAN bus readers, and ultrasonic paint depth gauges.

### 5.3 Security, Integrity & Compliance
- **Cryptographic Hashing**: Inspection dossiers are compiled into an immutable JSON tree and hashed via SHA-256 upon lead technician swipe.
- **Public Access Controls**: Share links support instant deactivation with audit trails; tokenized URLs expire after customer lease termination.
- **Regulatory Compliance**: Adheres to ISO/IEC 17020 (Requirements for the operation of various types of bodies performing inspection).

---

## 6. Release Roadmap & Milestones

1. **Phase 1: Core Field Diagnostics (Completed)** — 16 Mobile Technician screens & Localized Design System.
2. **Phase 2: Workshop Operations (Completed)** — 12 Tablet/Desktop screens for bay assignment, scheduling & template customization.
3. **Phase 3: Platform Governance & Public Reports (Completed)** — 11 Platform Admin screens + 7 Public Mobile/Desktop consumer screens.
4. **Phase 4: Telematics Hardware SDK & Automated OCR** — AI VIN scanning, tire barcode OCR, and automated CAN-bus live telemetry streaming.
