import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:l10n/ui_strings.dart';

import 'figma_l10n_override.dart';

/// Flutter's global delegates. The technician app no longer ships the
/// generated localization delegate; strings come from [UiStringsScope].
const List<LocalizationsDelegate<dynamic>> testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];

/// Backend English bundle, installed by `flutter_test_config.dart`.
UiStrings baseStrings() => UiStrings.fromRemoteEnglish();

/// Backend English with the Figma copy layered on top.
UiStrings figmaStringsBundle() => figmaStrings();
