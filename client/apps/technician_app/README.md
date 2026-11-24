# TrueReport Technician App

Phase 2 foundation only. Run from the workspace root:

```powershell
cd client
flutter pub get
cd apps/technician_app
flutter test
flutter run

# staging / prod: edit the ONE shared file (same url for every app)
# client/packages/auth/.env -> API_BASE_URL=https://api.staging.example.com
```

The app currently contains sign-in and a role-based home shell. No inspection, checklist, camera or offline feature is implemented in Phase 2.
