# Phase 3.5 Environment Report

**Project:** TrueReport  
**Date:** 3 November 2026  
**Scope:** Use the downloaded JDK 25.0.5 and Flutter 3.47.9 toolchains, keep Java 17 installed, back up the old environment, and verify the client/server on the new tools. No Phase 4 feature was added.

---

## 1. Sources used

Found in `C:\Users\sanja\AppData\Local\Temp\opencode`:

| Archive | Size | SHA-256 |
|---|---:|---|
| `jdk25.zip` | 141,285,173 bytes | `636BDC13DC649DDC7D5921C5C7D23CCA6E44FD19D662B45CC9C02135A6C96C42` |
| `flutter_windows_3.47.9-stable.zip` | 1,939,451,626 bytes | `D8E2B5977E09082C6440F89DC1AA887B94C8FBCC3B39222797046295A3F68A9E` |

Archive top-level entries confirmed:

- `jdk-25.0.5+8/`
- `flutter/`

No substitute download was made.

---

## 2. JDK result

| Item | Result |
|---|---|
| Installed path | `C:\Users\sanja\jdk-25.0.5+8` |
| `java -version` (direct executable) | `openjdk version "25.0.5" 2026-10-20 LTS` / `Temurin-25.0.5+8` |
| `javac -version` (direct executable) | `javac 25.0.5` |
| User `JAVA_HOME` | `C:\Users\sanja\jdk-25.0.5+8` |
| Maven | `Apache Maven 3.9.16` |
| Maven Java runtime | `Java version: 25.0.5, vendor: Eclipse Adoptium`, runtime `C:\Users\sanja\jdk-25.0.5+8` |
| Java 17 | Still installed at `C:\Program Files\Java\jdk-17`; no uninstall/removal performed |

### Important limitation: `java`/`javac` on PATH still resolve to Java 17

The user `Path` now starts with `%JAVA_HOME%\bin`, but Windows composes the machine `Path` before the user `Path`. The machine `Path` starts with:

```text
C:\Program Files\Java\jdk-17\bin;...
```

Therefore, in a new shell:

```text
where java
C:\Program Files\Java\jdk-17\bin\java.exe
C:\Program Files\Common Files\Oracle\Java\javapath\java.exe
C:\Users\sanja\jdk-25.0.5+8\bin\java.exe

java -version
java version "17.0.12" 2024-07-16 LTS
javac 17.0.12
```

This is a Windows path-precedence limitation, not a failed JDK install. The approved user-level-only rule prevented removing Java 17 entries or editing the machine `Path`. Maven and the build use JDK 25 because `JAVA_HOME` is set; `java` from a shell still needs `%JAVA_HOME%\bin\java.exe` or an administrator-level machine `Path` change.

---

## 3. Flutter result

| Item | Result |
|---|---|
| Installed path | `C:\Users\sanja\flutter_3.47.9` |
| `flutter --version` | `Flutter 3.47.9 • channel stable`; framework revision `c197ca5199`; Dart `3.13.7`; DevTools `2.60.0` |
| `where flutter` | `C:\Users\sanja\flutter_3.47.9\bin\flutter` |
| `where dart` | `C:\Users\sanja\flutter_3.47.9\bin\dart` |
| User `Path` entry | `C:\Users\sanja\flutter_3.47.9\bin` added near the front |
| Old Flutter user `Path` entry | Removed |
| Old Flutter SDK | Renamed, not deleted: `C:\Users\sanja\Downloads\flutter_windows_3.35.7-stable\flutter_old_backup` |
| Old Flutter size | 17,604 files, 3,126,821,786 bytes (2.91 GiB) |
| `flutter config --no-analytics` | Run; analytics reporting disabled |

`flutter doctor -v` reports Flutter 3.47.9 and Dart 3.13.7 correctly. It reports Android toolchain issues unrelated to this phase:

- Multiple `adb` binaries.
- Some Android licences not accepted.
- Android Studio bundled JDK 21 is used for Android tooling.

No Android/iOS device test was performed.

---

## 4. User environment state

Current user variables after the change:

```text
USER JAVA_HOME = C:\Users\sanja\jdk-25.0.5+8
USER Path = %JAVA_HOME%\bin;C:\Users\sanja\flutter_3.47.9\bin;C:\Users\sanja\.local\bin;...
```

The pre-change values are saved in `docs/phase-3.5/env-backup.txt`.

Old Java 17 PATH entries were left installed. The old Flutter PATH entry was removed; the old SDK folder was renamed to `flutter_old_backup`.

---

## 5. Pinned files checked

| File | Value | Match |
|---|---|---|
| `client/.fvmrc` | `{"flutter":"3.47.9"}` | Yes |
| `server/pom.xml` | `<java.version>25</java.version>` | Yes; installed JDK is 25.0.5 |
| `docs/phase-2/version-lock.md` | Flutter 3.47.9, Dart 3.13.7, Java 25.0.5 | Yes |

No pinned version was changed.

---

## 6. Verification results on the new tools

### Flutter

```powershell
cd client
flutter pub get
flutter analyze --fatal-infos
```

Result: **No issues found!**

```powershell
cd client\apps\technician_app
flutter test
```

Result: **4 tests passed.**

```powershell
cd client\apps\admin_app
flutter test
```

Result: **53 tests passed.**

This includes the existing admin tests, the new responsive/theme/text-scale matrix, the reduce-motion check, the API endpoint source scan, and the hardcoded colour/font scan.

```powershell
cd client\apps\admin_app
flutter build web --release --dart-define-from-file=config/dev.json
```

Result: **Built `build\web`.**

The web build emitted a non-fatal warning that `CupertinoIcons` font assets were not found. The build completed successfully.

### Server

```powershell
$env:JAVA_HOME='C:\Users\sanja\jdk-25.0.5+8'
$env:Path='C:\Users\sanja\jdk-25.0.5+8\bin;'+$env:Path
cd server
mvn test
```

Result:

```text
Tests run: 23, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

`MySqlMigrationIT` remains skipped because Docker is not installed. No server code was changed in Phase 3.5.

---

## 7. Not verified

- `java -version` from a normal new shell does **not** show 25 because of the machine `Path` precedence described above.
- Android/iOS emulator or physical-device rendering.
- Real browser interaction beyond the release web build and headless widget tests.
- `flutter doctor` Android licence/adb cleanup.
- Docker Compose and MySQL Testcontainers.
- Cupertino icon font warning in the web build.

---

## 8. Rollback steps

1. Restore the user variables from `docs/phase-3.5/env-backup.txt`:

```powershell
[Environment]::SetEnvironmentVariable(
  'JAVA_HOME',
  'C:\Program Files\Java\jdk-17',
  'User'
)
[Environment]::SetEnvironmentVariable(
  'Path',
  '<the USER PATH value from env-backup.txt>',
  'User'
)
```

2. Rename the old Flutter SDK back:

```powershell
Rename-Item `
  -LiteralPath 'C:\Users\sanja\Downloads\flutter_windows_3.35.7-stable\flutter_old_backup' `
  -NewName 'flutter'
```

3. The restored user `Path` already points back to:
   `C:\Users\sanja\Downloads\flutter_windows_3.35.7-stable\flutter\bin`
4. The new SDKs may remain installed at `C:\Users\sanja\jdk-25.0.5+8` and `C:\Users\sanja\flutter_3.47.9`; deleting them is optional and should be done by the user.
5. Restart shells, VS Code, and any terminal sessions after restoring.
