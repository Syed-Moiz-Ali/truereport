import 'package:flutter/widgets.dart';

import 'remote_english.dart';
import 'ui_messages/ui_message_key.dart';

/// One thin accessor for every user-visible string.
///
/// Keys come from the backend catalogs; values are resolved from the active
/// bundle. There is no English fallback in Dart: an unknown key resolves to an
/// empty string, matching the generated-localizations contract.
@immutable
class UiStrings {
  const UiStrings._(this.messages);

  factory UiStrings.fromMessages(Map<String, String> messages) =>
      UiStrings._(Map<String, String>.unmodifiable(messages));

  /// A bundle backed by the resolved backend messages.
  ///
  /// Used by tests and by the scope fallback; production always feeds the
  /// scope from the language selection.
  factory UiStrings.fromRemoteEnglish([Map<String, String>? overrides]) {
    if (overrides == null || overrides.isEmpty) {
      return UiStrings._(remoteEnglishValues);
    }
    return UiStrings.fromMessages(<String, String>{
      ...remoteEnglishValues,
      ...overrides,
    });
  }

  static const UiStrings empty = UiStrings._(<String, String>{});

  /// Convenience for `UiStrings.of(context)` call sites.
  static UiStrings of(BuildContext context) => UiStringsScope.of(context);

  final Map<String, String> messages;

  String call(UiMessageKey key, [Map<String, Object?>? args]) {
    final template = messages[key.key];
    if (template == null || template.isEmpty) {
      return '';
    }
    if (args == null) {
      return template;
    }
    return formatRemoteMessage(template, args);
  }

  /// Resolves a flat backend key (reference `labelKey`, test fixture, ...).
  String raw(String backendKey, [Map<String, Object?>? args]) {
    final template = messages[backendKey];
    if (template == null || template.isEmpty) {
      return '';
    }
    if (args == null) {
      return template;
    }
    return formatRemoteMessage(template, args);
  }
}

/// Provides [UiStrings] to the widget tree without Riverpod.
class UiStringsScope extends InheritedWidget {
  const UiStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final UiStrings strings;

  static UiStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UiStringsScope>();
    if (scope != null) {
      return scope.strings;
    }
    // Widget tests that pump a screen directly have no app shell. The backend
    // English bundle is already installed by their test config, so serve that
    // instead of failing the whole tree.
    return UiStrings.fromRemoteEnglish();
  }

  @override
  bool updateShouldNotify(UiStringsScope oldWidget) =>
      !identical(strings, oldWidget.strings) ||
      strings.messages != oldWidget.strings.messages;
}
