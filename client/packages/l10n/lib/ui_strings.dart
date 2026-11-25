/// Backend-driven UI strings for every app.
///
/// This is the only l10n entry point: the generated accessor is gone, so
/// strings are addressed by [UiMessageKey] (the four key classes
/// below) and resolved through [UiStrings] / [UiStringsScope].
library;

export 'src/locale_controller.dart';
export 'src/remote_english.dart';
export 'src/ui_strings.dart';
export 'src/ui_messages/backend_language_selector.dart';
export 'src/ui_messages/ui_message_api.dart';
export 'src/ui_messages/ui_message_cache.dart';
export 'src/ui_messages/ui_message_catalog.dart';
export 'src/ui_messages/ui_message_controller.dart';
export 'src/ui_messages/ui_message_gate.dart';
export 'src/ui_messages/ui_message_key.dart';
export 'src/ui_messages/ui_message_manifest.dart';
export 'src/ui_messages/ui_directionality.dart';
export 'src/ui_messages/keys/common_keys.dart';
export 'src/ui_messages/keys/platform_admin_keys.dart';
export 'src/ui_messages/keys/technician_keys.dart';
export 'src/ui_messages/keys/workshop_admin_keys.dart';
