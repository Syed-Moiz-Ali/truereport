# Preliminary Version Lock Table

**Project:** TrueReport  
**Document:** 05-version-lock-table.md  
**Snapshot date:** 3 November 2026  
**Status:** Phase 0 research snapshot. **This is not the Phase 2 version lock.** Do not treat these numbers as approved pins.

---

## 1. How this table was produced

- Flutter SDK and Dart versions: official Flutter release feed [S12].
- Flutter package versions: pub.dev package API; licences from pub.dev score tags (`license:*`) [S19].
- Java library versions: Maven Central `maven-metadata.xml`; stable versions exclude alpha/beta/RC/milestone/snapshot where possible [S48]. Major framework versions were cross-checked on the official project pages [S22][S24][S25][S26][S27].
- Licences: package metadata, POM `<licenses>` and project repository licence pages. Where the POM did not declare a licence, the project repository licence is used and noted.
- Infrastructure: official vendor pages [S28]–[S34].

**Important:** Spring Boot’s dependency management (BOM) controls many transitive versions. The “current upstream” column is not an instruction to override the BOM. Phase 2 must use the BOM, run compatibility tests, and only override with a recorded reason.

**Version drift warning:** these values will change. Re-check every row at the Phase 2 version-lock task (D13) and record the exact lock in the repository.

---

## 2. Platform and tooling

| Item | Current stable | Licence | Concern / note |
|---|---|---|---|
| Flutter SDK | **3.47.9** (stable, 29 Oct 2026) | BSD-3-Clause | Pin with FVM. Web renderer is CanvasKit/Skwasm, not a DOM renderer. Test Arabic/RTL and web on the target browsers. |
| Dart SDK | **3.13.7** | BSD-3-Clause | Comes with Flutter 3.47.9. Melos 8 needs Dart 3.9+. |
| FVM | **4.3.2** | MIT | Pin the Flutter version per repository; document the FVM install step for Windows/macOS/Linux. |
| Melos | **8.10.0** | Apache-2.0 | Uses pub workspaces; root `pubspec.yaml`, no `melos.yaml`. Melos 8 removed the old layout. |
| very_good_analysis | **11.0.0** | MIT | Strict lint set. Pick either this or `flutter_lints`, not both. |
| flutter_lints | **6.0.0** | BSD-3-Clause | Alternative lint set. |
| build_runner | **2.17.1** | BSD-3-Clause | Codegen for Riverpod/Freezed/JSON/Drift. Run through a Melos script and in CI. |
| openapi-generator (Dart-Dio client) | Not pinned in Phase 0 | Apache-2.0 | Tool, not a runtime library. Verify generated client quality before committing; fallback is hand-written Retrofit. |
| Maven | **3.10.0** | Apache-2.0 | Spring Boot 4.1.2 requires Maven 3.6.3+. |

---

## 3. Flutter packages

All versions below are the current stable version on pub.dev on 3 November 2026 [S19]. “Stale” means no release for roughly 18+ months; it is a maintenance concern, not automatically a blocker.

### 3.1 State, models and code generation

| Package | Version | Licence | Concern / note |
|---|---|---|---|
| `flutter_riverpod` | **3.4.3** | MIT | Recommended state/DI. Do not mix with Bloc. |
| `riverpod_annotation` | **4.0.7** | MIT | Major version differs from `flutter_riverpod`; resolve constraints together. |
| `riverpod_generator` | **4.0.9** | MIT | Codegen; keep `build_runner` compatible. |
| `freezed` | **4.0.3** | MIT | Immutable models and unions. Freezed 4 may change generated APIs; test. |
| `freezed_annotation` | **3.1.0** | MIT | Must match `freezed` constraints. |
| `json_serializable` | **6.15.2** | BSD-3-Clause | JSON codegen. |
| `json_annotation` | **4.12.0** | BSD-3-Clause | JSON annotations. |

### 3.2 Navigation, animation and networking

| Package | Version | Licence | Concern / note |
|---|---|---|---|
| `go_router` | **18.1.2** | BSD-3-Clause | Major version 18; check migration notes. Use path URL strategy on web and configure server rewrites. |
| `go_router_builder` | **4.5.3** | BSD-3-Clause | Optional typed routes. |
| `flutter_animate` | **4.5.2** | BSD-3-Clause | Last published Nov 2024. Use sparingly; respect `MediaQuery.disableAnimations`. |
| `lottie` | **3.8.2** | MIT | Optional, later. Adds asset weight; not needed for core workflow. |
| `dio` | **5.11.1** | MIT | Interceptors for auth, locale, retry, request ID. Never log tokens/PII. |
| `retrofit` | **4.10.0** | MIT | Typed client option. |
| `retrofit_generator` | **10.3.3** | MIT | Codegen for Retrofit. |
| `pretty_dio_logger` | **1.4.0** | MIT | Debug only; must redact tokens, phones, VINs. |

### 3.3 Offline, storage and device services

| Package | Version | Licence | Concern / note |
|---|---|---|---|
| `drift` | **2.35.3** | MIT | Type-safe SQLite, migrations, reactive queries, sync queue. |
| `drift_dev` | **2.35.2** | MIT | Drift codegen. |
| `sqlite3` | **3.8.0** | MIT | Current SQLite binding recommended by Drift. |
| `drift_flutter` | **0.3.1** | MIT | Convenience opener for Flutter; recommended in Drift setup docs [S20]. |
| `sqlite3_flutter_libs` | **0.6.0+eol** | MIT | **Do not use.** The package says it is obsolete after upgrading to `package:sqlite3` 3.x and does nothing from 0.6.0 [S21]. |
| `flutter_secure_storage` | **11.2.0** | BSD-3-Clause | Refresh token and sensitive keys. Test Android/iOS keychain behaviour. |
| `shared_preferences` | **2.5.6** | BSD-3-Clause | Non-sensitive prefs only. |
| `connectivity_plus` | **7.3.2** | BSD-3-Clause | Network hint, not proof of internet. |
| `workmanager` | **0.10.10** | MIT | Android background work; iOS background limits apply. Uploads must also resume when the app opens. |
| `path_provider` | **2.1.6** | BSD-3-Clause | App file paths for photos/database. |

### 3.4 Media

| Package | Version | Licence | Concern / note |
|---|---|---|---|
| `image_picker` | **1.2.4** | Apache-2.0 / BSD-3-Clause | Start here for capture. |
| `camera` | **0.12.2** | BSD-3-Clause | Later, for guide overlay; more native complexity. |
| `flutter_image_compress` | **2.5.1** | MIT | Compress before upload; test on low-end Android. |
| `cached_network_image` | **4.0.6** | MIT | Guide images and report photos. |
| `photo_view` | **0.15.0** | MIT | Last published 2024. Consider built-in `InteractiveViewer` instead. |
| `permission_handler` | **13.0.2** | MIT | Camera/storage permissions. |
| `exif` | **3.3.0** | MIT | Last published 2023. Read capture time; strip GPS from public images. Keep isolated and test. |
| `video_player` | **2.14.1** | BSD-3-Clause | Video evidence is out of scope until approved. |

### 3.5 Localisation, forms and UI

| Package | Version | Licence | Concern / note |
|---|---|---|---|
| `flutter_localizations` | Flutter SDK **3.47.9** | BSD-3-Clause | Built-in delegates; ARB/gen-l10n. |
| `intl` | **0.20.3** | BSD-3-Clause | Dates, numbers, plurals. |
| `reactive_forms` | **18.2.2** | MIT | Forms option A. Pick one forms approach (D7). |
| `flutter_form_builder` | **11.0.0** | MIT | Forms option B. |
| `form_builder_validators` | **11.3.0** | BSD-3-Clause | Validators for option B. |
| `phone_form_field` | **12.0.1** | MIT | Preferred international phone input. |
| `intl_phone_field` | **3.2.0** | MIT | Last published 2023; prefer `phone_form_field`. |
| `mask_text_input_formatter` | **2.9.0** | MIT | Odometer/plate masks if needed. |
| `data_table_2` | **3.0.0** | BSD-3-Clause | Admin web table option. |
| `pluto_grid` | **8.1.0** | MIT | Admin web table option; more feature-heavy. |
| `flutter_fancy_tree_view` | **1.6.0** | MIT | Last published 2024; suitable for the Platform Admin tree, but evaluate accessibility. |

### 3.6 Utilities, diagnostics and testing

| Package | Version | Licence | Concern / note |
|---|---|---|---|
| `url_launcher` | **6.3.3** | BSD-3-Clause | Open links/call/WhatsApp. |
| `share_plus` | **13.3.1** | BSD-3-Clause | Share report link. |
| `package_info_plus` | **10.2.2** | BSD-3-Clause | Diagnostics without personal data. |
| `device_info_plus` | **13.3.0** | BSD-3-Clause | Diagnostics without personal data. |
| `uuid` | **4.6.0** | MIT | Client-generated UUIDs for offline records. |
| `logger` | **2.8.0** | MIT | Local logging with redaction. |
| `talker` | **5.2.0** | MIT | Alternative logging/error UI; pick one. |
| `sentry_flutter` | **10.3.0** | MIT | Crash reporting; scrub PII, tokens, VINs, phone numbers. |
| `firebase_core` | **5.1.0** | BSD-3-Clause | Push prerequisites; native configuration required. |
| `firebase_messaging` | **17.0.1** | BSD-3-Clause | Push for new job assigned. Not in core acceptance criteria; optional. |
| `local_auth` | **3.0.2** | BSD-3-Clause | Optional biometric unlock; not required in V1. |
| `google_mlkit_text_recognition` | **0.17.1** | MIT | VIN scanning deferred. |
| `mobile_scanner` | **7.5.0** | BSD-3-Clause | Barcode/VIN scanning deferred. |
| `flutter_test` | Flutter SDK **3.47.9** | BSD-3-Clause | Unit/widget tests. |
| `mocktail` | **1.0.5** | MIT | Mocks. |
| `alchemist` | **0.14.1** | MIT | Golden tests for EN/AR RTL; preferred. |
| `golden_toolkit` | **0.15.0** | BSD-3-Clause | Last published 2023; avoid for new work. |
| `integration_test` | Flutter SDK **3.47.9** | BSD-3-Clause | Integration tests. |
| `patrol` | **4.11.0** | Apache-2.0 | Optional native permission dialogs; evaluate CI cost. |
| `flutter_web_plugins` | Flutter SDK **3.47.9** | BSD-3-Clause | `usePathUrlStrategy` for web. |

---

## 4. Java platform and libraries

### 4.1 Platform and framework

| Item | Current stable | Licence | Concern / note |
|---|---|---|---|
| Java | **25 LTS** | GPLv2 + Classpath Exception (OpenJDK) | Java 25 is current LTS; Spring Boot 4.1.2 supports Java 17–27. |
| Spring Boot | **4.1.2** | Apache-2.0 | Current stable; 4.2.0-RC1 is preview and must not be used for production. |
| Spring Framework | **7.0.10** (minimum for Boot 4.1.2) | Apache-2.0 | Comes through the Boot BOM. |
| Spring Modulith | **2.1.2** | Apache-2.0 | Verify it is compatible with Boot 4.1.2 in the Phase 2 build. |
| Maven | **3.10.0** | Apache-2.0 | Boot 4.1.2 requires 3.6.3+. |
| Spring Web MVC | Boot-managed | Apache-2.0 | Use `spring-boot-starter-web`; virtual threads optional. |
| Jakarta Bean Validation | **3.1.1** API | Apache-2.0 | Boot-managed implementation (Hibernate Validator). |
| Spring Security | **7.1.2** | Apache-2.0 | JWT access + rotating refresh tokens; Argon2 password hashing. |
| Spring Security Crypto | Boot-managed | Apache-2.0 | Argon2 support. |
| Bouncy Castle (`bcprov-jdk18on`) | **1.86** | Bouncy Castle Licence (MIT-style) | Required by Argon2/Spring Security Crypto. |
| TOTP library (candidate) | **`otp-java` 2.2.0** | MIT | Candidate only; D12 still open. Repository was active in 2026. Do not treat this as a security approval; review algorithm defaults, secret storage and replay protection. |
| Spring Data JPA | **4.1.2** | Apache-2.0 | Boot-managed. |
| Hibernate ORM | **7.4.14.Final** | Apache-2.0 (POM/repository) | Boot-managed version may differ; use the BOM. |
| jOOQ | **3.21.9** | Apache-2.0 (OSS edition) | Optional for complex report queries; MySQL is supported in the OSS edition. Verify edition terms. |
| `JdbcClient` | Spring Framework 7 | Apache-2.0 | Built-in; optional alternative to jOOQ for simple queries. |
| Flyway | **13.12.0** | Apache-2.0 | Community supports MySQL core migrations; add `flyway-mysql`. Boot BOM may manage an older version; test before overriding. |
| MapStruct | **1.6.3** | Apache-2.0 | DTO/entity mapping. |
| springdoc-openapi | **3.2.0** | Apache-2.0 | Generates OpenAPI for the Dart client. |
| Bucket4j | **8.21.0** (`bucket4j_jdk17-core`) | Apache-2.0 | Artifact names changed; use the JDK 17 artifact, not the old `bucket4j-core` coordinate. |
| Caffeine | **3.3.1** | Apache-2.0 | In-process cache. Redis only if scaling. |
| libphonenumber | **9.0.42** | Apache-2.0 | Phone parsing/formatting. |
| Thumbnailator | **0.4.21** | MIT | Image resize. |
| metadata-extractor | **2.22.0** | Apache-2.0 | Read/strip EXIF. |
| AWS SDK for Java v2 (S3) | **2.57.8** | Apache-2.0 | Works with S3-compatible storage. |
| Spring Mail | Boot-managed | Apache-2.0 | SMTP behind a `MailSender` adapter. |
| JobRunr | **9.0.3** (`jobrunr-spring-boot-4-starter`) | LGPL-3.0 or commercial | Use the Spring Boot 4 starter, not the Boot 3 artifact. OSS free tier ~100 recurring jobs, simple dashboard. Pro adds priority queues, batches, workflow, transaction plugin. LGPL obligations apply if modified. |
| Micrometer | **1.17.2** | Apache-2.0 | Metrics. |
| Micrometer Prometheus registry | **1.17.2** | Apache-2.0 | Metrics export. |
| Logback | **1.6.6** | EPL-1.0 / LGPL-2.1 | Structured JSON logs with redaction. |
| Sentry Java | **8.62.0** | MIT | Error reporting; scrub PII. |
| MySQL Connector/J | **26.10.0** | GPLv2 + Universal FOSS Exception | **Licence concern for commercial distribution.** Oracle says commercial distributors need a commercial licence or GPL compliance. Get legal review; consider MariaDB Connector/J (LGPL) if distribution requires it. |
| HikariCP | **7.1.0** | Apache-2.0 | Connection pool; Boot default. |
| Testcontainers (MySQL) | **1.21.4** | MIT | Real MySQL in tests. |
| JUnit Jupiter | **6.1.3** | EPL-2.0 | JUnit 5/6 line. Confirm Boot’s managed version. |
| Mockito | **5.24.0** | MIT | Mocks. |
| AssertJ | **3.27.7** | Apache-2.0 | Fluent assertions. |
| ArchUnit | **1.5.1** | Apache-2.0 | Module boundary and dependency rules. |
| Awaitility | **4.3.0** | Apache-2.0 | Async job tests. |
| Playwright for Java | **1.64.0** | Apache-2.0 | Headless Chromium PDF candidate. Java 8+; downloads browser binaries. |
| OpenHTMLtoPDF | **1.0.10** | LGPL-2.1-or-later | **High concern:** last release 2021, limited RTL/bidi, no OpenType fonts, tested up to Java 17, PDFBox 2.x. Only use if the spike proves it. |
| Apache PDFBox | **3.0.8** | Apache-2.0 | Current PDFBox; note OpenHTMLtoPDF 1.0.10 is built on PDFBox 2.x, so do not put both on the same classpath without testing. |
| Spotless | **3.11.0** | Apache-2.0 | Formatting. |
| Checkstyle | **14.4.0** | LGPL-2.1-or-later | Style checks. |
| Error Prone | **2.52.0** | Apache-2.0 | Static analysis; Java 25 compatibility must be tested. |
| JaCoCo | **0.8.16** | EPL-2.0 | Coverage. |

### 4.2 Java version cautions

- **Do not override Boot-managed libraries casually.** Boot 4.1.2’s BOM is the tested combination.
- **Spring Boot 4.1.2 + Spring Modulith 2.1.2** should be verified with a minimal build in Phase 2.
- **Hibernate 7.x** is a major upgrade from Hibernate 6. Check MySQL dialect, UUID/BINARY(16) mappings and trigger interactions.
- **Flyway 13.x** may be newer than the Boot-managed version. Use the BOM unless a security fix requires an override, then run migration tests.
- **MySQL Connector/J** is the biggest licence question in the Java stack. Do not ship a closed-source distribution with it without legal advice.
- **OpenHTMLtoPDF** is the biggest Arabic/PDF risk. The spike decides.

---

## 5. Infrastructure and external services

| Item | Current status | Licence / terms | Concern / note |
|---|---|---|---|
| MySQL | **8.4.13 LTS** | GPLv2 / commercial | Pin 8.4 LTS. **MySQL 8.0 reached EOL in April 2026.** Use `utf8mb4`, InnoDB, UTC timestamps, strict SQL mode. |
| Flyway | **13.12.0** | Apache-2.0 Community | MySQL core migrations supported; advanced features need paid editions. |
| MinIO OSS | **Archived / end of life** | AGPL-3.0 | No new features, bug fixes or security patches; source-only distribution. **Do not use for production.** Local development only, pinned and documented as dev-only. |
| MinIO AIStor Free | **Current proprietary tier** | Proprietary AIStor Free Agreement | Single-node only; no encryption at rest; redistribution prohibited. Not suitable as the production storage assumption without a commercial review. |
| Production object storage | **TBD** | TBD | Must be S3-compatible, maintained, encrypted at rest, with a clear licence and data-residency position. Evaluate SeaweedFS, Garage, Ceph or a managed S3 service. |
| JobRunr | **9.0.3 OSS** | LGPL-3.0 / commercial | OSS limit ~100 recurring jobs; fine for a small outbox workload. Pro if advanced scheduling is needed. |
| WhatsApp Business Platform | **Meta platform** | Meta terms / provider terms | Opt-in required; approved templates outside the 24-hour customer-service window. Business verification and template approval take time. |
| SMS provider | **TBD** | TBD | UAE sender-ID registration and provider rules must be checked. Do not assume a sender ID. |
| Email provider | **TBD** | TBD | SMTP/API provider, SPF/DKIM/DMARC, bounce handling. |
| Firebase Cloud Messaging | **Google service** | Google terms | Optional push; not required for core V1 acceptance. |
| Grafana | **Current** | AGPL-3.0 (self-hosted) | If self-hosted, review AGPL obligations or use a managed service. Not a runtime dependency of the app. |
| Prometheus | **Current** | Apache-2.0 | Metrics; no licence concern. |
| Chromium (Playwright) | **Bundled with Playwright 1.64.0** | BSD-style / Chromium licences | Large binary and OS dependencies; security updates must be tracked. |

---

## 6. Version-lock decisions for Phase 2

Phase 2 task 1 must:

1. Re-check every version in this document against pub.dev, Maven Central and official release pages.
2. Record the exact Flutter/Dart SDK, Java, Spring Boot, MySQL, Flyway and Node/tooling versions.
3. Generate and commit lockfiles:
   - `pubspec.lock` for the Melos workspace.
   - Maven dependency tree / effective POM or a dependency lock mechanism.
   - Docker image digests for MySQL, object storage and any browser runtime.
4. Run a licence scan and record every licence obligation, especially:
   - MySQL Connector/J (GPLv2).
   - JobRunr (LGPL-3.0).
   - OpenHTMLtoPDF (LGPL-2.1+).
   - MinIO (AGPL-3.0 / proprietary).
   - Grafana (AGPL-3.0, if self-hosted).
   - Fonts (verify OFL or other licences).
5. Run a vulnerability scan and record exceptions with expiry dates.
6. Prove the app and server build on Windows, macOS/Linux CI, and the target deployment OS.
7. Record the result as an ADR and update this table to “locked”.

---

## 7. Summary of the most important concerns

| Concern | Why it matters | Action |
|---|---|---|
| MySQL 8.0 is EOL | Security and support risk. | Pin **MySQL 8.4 LTS** and confirm D1. |
| MinIO OSS is EOL | No security patches; production evidence storage is at risk. | Re-decide production storage before Phase 2. |
| MySQL Connector/J is GPLv2 | Could affect distribution of a closed-source product. | Legal review; consider MariaDB Connector/J or a commercial licence. |
| OpenHTMLtoPDF is old and RTL-limited | Arabic PDF could be wrong. | Default to headless Chromium; spike both. |
| `sqlite3_flutter_libs` is obsolete | Wrong dependency would add dead weight. | Use `sqlite3` 3.x + `drift_flutter`. |
| `melos.yaml` no longer exists | Repository layout in `master.md` is outdated. | Use root `pubspec.yaml` with `workspace:`. |
| Flutter Web is canvas-based | Public report may be slower/inaccessible versus HTML. | Run the public-report spike. |
| WhatsApp requires opt-in/templates | Delivery can fail or be blocked. | Capture channel consent; start provider onboarding early. |
| UAE PDPL/India DPDP | Legal exposure. | Counsel review before real data; no compliance claims. |

---

## 8. Approval

This is a **preliminary** table for planning. It does not authorise installing, pinning or shipping any version. The Phase 2 version-lock task must produce the approved lock with licence and vulnerability review.

**No code has been written. Phase 1 has not started.**
