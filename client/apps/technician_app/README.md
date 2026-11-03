# TrueReport Technician App

Phase 2 foundation only. Run from the workspace root:

```powershell
cd client
flutter pub get
cd apps/technician_app
flutter test
flutter run --dart-define-from-file=config/dev.json
```

The app currently contains sign-in and a role-based home shell. No inspection, checklist, camera or offline feature is implemented in Phase 2.
