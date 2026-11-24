# TrueReport Admin App

Workshop Admin app. Run from the workspace root:

```powershell
cd client
flutter pub get
cd apps/admin_app
flutter test
flutter run -d chrome

# staging / prod: edit the ONE shared file (same url for every app)
# client/packages/auth/.env -> API_BASE_URL=https://api.staging.example.com
```

The app contains sign-in and a role-based home shell for Workshop Admin and Platform Admin, including the workshop job board, job creation, review/approval, publishing, documents and notification screens.
