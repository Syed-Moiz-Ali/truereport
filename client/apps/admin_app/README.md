# TrueReport Admin App

Phase 2 foundation only. Run from the workspace root:

```powershell
cd client
flutter pub get
cd apps/admin_app
flutter test
flutter run -d chrome --dart-define-from-file=config/dev.json
```

The app currently contains sign-in and a role-based home shell for Workshop Admin and Platform Admin. No job, template, report, delivery or platform-admin screen is implemented in Phase 2.
