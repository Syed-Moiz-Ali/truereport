import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';

/// The shared bay uses the app ARB for its structural labels (example job,
/// show/hide password) while each app supplies its product copy via
/// [SignInBayCopy].
///
/// Platform Admin deliberately does not import `AppLocalizations` in its own
/// lib (it is backend-string driven), so it spreads this list instead. The
/// symbol stays in the auth package.
const List<LocalizationsDelegate<dynamic>> signInBayLocalizationsDelegates =
    AppLocalizations.localizationsDelegates;
