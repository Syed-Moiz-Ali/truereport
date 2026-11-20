import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

/// Keeps the shared [ApiClient] aligned with the app's active locale.
///
/// Without this the workshop app sends no `Accept-Language` and no `X-Client`
/// (the platform app does — `platform_admin_app/lib/main.dart:38-39`), so
/// server-localized error text and audit attribution are wrong for every
/// workshop request.
///
/// Recomputes whenever [localeProvider] changes; watching this provider from
/// the root widget is enough to keep the client in sync.
final apiLanguageSyncProvider = Provider<void>((ref) {
  final api = ref.watch(apiClientProvider);
  api.clientName = 'workshop_admin';
  final locale = ref.watch(localeProvider);
  api.acceptLanguage = locale.languageCode;
});
