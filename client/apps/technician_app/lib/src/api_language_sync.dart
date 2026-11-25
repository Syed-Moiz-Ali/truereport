import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import 'technician_providers.dart';

/// Keeps the shared [ApiClient] aligned with the app's active language.
///
/// The technician app previously sent neither `Accept-Language` nor `X-Client`:
/// job content, categories and server error text stayed English, and audit
/// attribution could not tell the technician client apart.
final apiLanguageSyncProvider = Provider<void>((ref) {
  final api = ref.watch(apiClientProvider);
  api.clientName = 'technician';
  api.acceptLanguage = ref
      .watch(languageSelectionProvider(technicianUiMessageClient))
      .activeLanguage;
});
