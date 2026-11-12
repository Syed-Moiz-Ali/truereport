# TrueReport Admin App

Workshop Admin app. Run from the workspace root:

```powershell
cd client
flutter pub get
cd apps/admin_app
flutter test
flutter run -d chrome --dart-define-from-file=config/dev.json
```

The app contains sign-in and a role-based home shell for Workshop Admin and Platform Admin, including the workshop job board, job creation, review/approval, publishing, documents and notification screens.
