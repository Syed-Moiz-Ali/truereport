import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:l10n/ui_strings.dart';

/// Flutter's global delegates. The workshop app no longer ships the generated
/// localization delegate; strings come from [UiStringsScope].
const List<LocalizationsDelegate<dynamic>> testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

/// Backend English bundle, installed by `flutter_test_config.dart`.
UiStrings baseStrings() => UiStrings.fromRemoteEnglish();

/// Wraps a pumped tree with the bundle the app shell provides in production.
Widget uiStringsScope({required Widget child, UiStrings? strings}) =>
    UiStringsScope(strings: strings ?? baseStrings(), child: child);
