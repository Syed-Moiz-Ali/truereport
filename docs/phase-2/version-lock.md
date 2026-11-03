# Phase 2 Version Lock

**Project:** TrueReport  
**Document:** docs/phase-2/version-lock.md  
**Lock date:** 3 November 2026  
**Status:** Exact pins for Phase 2. Re-verify before Phase 3 upgrades; do not use floating ranges in build files.

---

## 1. How this lock was produced

- Flutter/Dart: official Flutter Windows release feed (`releases_windows.json`).
- Dart packages: `pub.dev` package API and score tags (licence data) on 3 November 2026.
- Java libraries: Maven Central `maven-metadata.xml` and POM metadata.
- Container images: Docker Hub tags inspected on 3 November 2026.
- No version was guessed. Where a package could not be verified, it is marked **NOT VERIFIED** and not used.

**Local toolchains actually used for the Phase 2 test run:**

| Tool | Version | Note |
|---|---|---|
| Flutter | **3.47.9** (stable, 29 Oct 2026) | Downloaded and used for analyze/test; the machine’s previous Flutter 3.35.7 was not used. |
| Dart | **3.13.7** | Bundled with Flutter 3.47.9. |
| Java | **25.0.5** (Temurin 25.0.5+8) | Downloaded and used for Maven tests. |
| Maven | **3.9.16** | Local Maven. |
| OS | Windows 11 / PowerShell 5.1 | Windows-only verification. |
| Docker | **NOT INSTALLED** | Docker Compose and Testcontainers MySQL could not run locally. |

---

## 2. Flutter SDK and tooling

| Item | Pin | Licence | Note |
|---|---|---|---|
| Flutter SDK | **3.47.9** | BSD-3-Clause | Pin with FVM in a shared environment; local Phase 2 used the downloaded SDK. |
| Dart SDK | **3.13.7** | BSD-3-Clause | Bundled with Flutter 3.47.9. |
| Melos | **8.10.0** | Apache-2.0 | Declared in root `client/pubspec.yaml`; uses Dart pub workspaces, no `melos.yaml`. |
| FVM | **4.3.2** | MIT | Recommended for team version pinning; not installed in this environment. |

---

## 3. Flutter packages (exact)

| Package | Pin | Licence |
|---|---|---|
| `flutter_riverpod` | **3.4.3** | MIT |
| `go_router` | **18.1.2** | BSD-3-Clause |
| `flutter_animate` | **4.5.2** | BSD-3-Clause |
| `dio` | **5.11.1** | MIT |
| `flutter_secure_storage` | **11.2.0** | BSD-3-Clause |
| `intl` | **0.20.3** | BSD-3-Clause |
| `uuid` | **4.6.0** | MIT |
| `image_picker` | **1.2.4** | Apache-2.0 / BSD-3-Clause |
| `flutter_lints` | **6.0.0** | BSD-3-Clause |
| `flutter_localizations` | Flutter SDK **3.47.9** | BSD-3-Clause |

**Not used in Phase 2 but reserved for later phases (re-verify before adding):**
`drift` 2.35.3, `drift_flutter` 0.3.1, `sqlite3` 3.8.0, `flutter_image_compress` 2.5.1, `connectivity_plus` 7.3.2, `shared_preferences` 2.5.6, `freezed` 4.0.3, `json_serializable` 6.15.2, `riverpod_generator` 4.0.9, `build_runner` 2.17.1. These are **not** in Phase 2 build files.

**Note:** `test 1.33.0` was rejected because Flutter 3.47.9 pins `test_api 0.7.12`; `test` was removed from pure-Dart packages rather than forcing an incompatible `test_api`. Flutter `flutter_test` is used for app tests.

---

## 4. Java and server

| Item | Pin | Licence | Concern |
|---|---|---|---|
| Java | **25.0.5** Temurin | GPLv2 + Classpath Exception | Current LTS used for build/test. |
| Spring Boot | **4.1.2** | Apache-2.0 | Current stable; no RC. |
| Spring Modulith | **2.1.2** | Apache-2.0 | BOM imported. |
| Spring Framework | Boot-managed (7.0.10 in the resolved tree) | Apache-2.0 | Use Boot BOM. |
| Flyway | **13.12.0** | Apache-2.0 | `flyway-core` + `flyway-mysql`. |
| MySQL Connector/J | **26.10.0** | GPLv2 + Universal FOSS Exception | **Licence concern for distribution.** Legal review required; hosted-only use differs from shipping a Docker image. |
| springdoc-openapi | **3.2.0** | Apache-2.0 | OpenAPI generation. |
| Testcontainers BOM | **2.0.5** | MIT | Testcontainers 2 renamed artifacts; `testcontainers-mysql` and `testcontainers-junit-jupiter` are used. |
| H2 (tests) | **2.5.252** | MPL-2.0 / EPL-1.0 | Test-only, MySQL mode. |
| ArchUnit JUnit 5 | **1.5.1** | Apache-2.0 | Architecture checks. |
| Bouncy Castle | **1.86** | Bouncy Castle Licence (MIT-style) | Argon2 support. |
| Spring Security | Boot-managed (7.1.2) | Apache-2.0 | JWT resource server, Argon2. |
| Hibernate ORM | Boot-managed (7.4.13.Final resolved) | Apache-2.0 (LGPL for some modules; verify) | MySQL/H2 mappings. |
| JUnit Jupiter | Boot-managed (6.0.3 resolved) | EPL-2.0 | Tests. |
| Mockito / AssertJ | Boot-managed | MIT / Apache-2.0 | Tests. |

**Version-lock caveats**

- Spring Boot 4.1.2 manages many transitive versions; do not override without a compatibility test.
- The resolved tree is recorded in Maven’s dependency tree in the CI/build log; the pins above are the direct decisions.
- Testcontainers 2.0.5 is the current artifact line; the MySQL test is skipped locally because Docker is absent.
- MySQL Connector/J GPLv2 is a real distribution concern; this is not resolved by this lock.
- No production object-storage SDK/provider is pinned; D6 remains Pending. The app uses an S3-compatible interface, not a vendor SDK yet.
- No PDF engine dependency is added in Phase 2; D5 Chromium is Phase 6.

---

## 5. Infrastructure images

| Service | Image pin | Licence | Use |
|---|---|---|---|
| MySQL | **mysql:8.4.13** | GPLv2 / commercial | Local/dev and CI; production MySQL 8.4 LTS. |
| MinIO | **minio/minio:RELEASE.2025-09-07T16-13-09Z** | AGPL-3.0 (archived) | **Local development only.** No security patches; never production. |
| Mailpit | **axllent/mailpit:v1.33.0** | MIT | Local SMTP capture. |
| Server build | **maven:3.9.16-amazoncorretto-25** | Maven Apache-2.0 / Corretto GPLv2+CE | Dockerfile build stage. |
| Server runtime | **eclipse-temurin:25.0.5_8-jre-noble** | GPLv2 + Classpath Exception | Dockerfile runtime stage. |

**Not verified:** image digests (only tags), Compose startup, MySQL-on-Docker, MinIO-on-Docker, server image build. Docker is not installed in the Phase 2 environment.

---

## 6. What is intentionally not locked

- D6 production object storage and its SDK/provider.
- D7 forms package (no complex forms yet).
- D8 WhatsApp/SMS/email providers.
- D11 photo limits and compression settings.
- PDF/Chromium runtime (D5 approved; Phase 6).
- Production host, domain, TLS certificates.
- Native Android/iOS signing keys and store configuration.

---

## 7. Reproduce the lock check

```powershell
# Flutter
flutter --version
cd client
flutter pub get
flutter pub deps --style=compact

# Java
cd server
mvn -version
mvn dependency:tree
```

Re-run the version checks at the start of every phase. A version is not approved just because it is in this table; licence and vulnerability review still apply.
