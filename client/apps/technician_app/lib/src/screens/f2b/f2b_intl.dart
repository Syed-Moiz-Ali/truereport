import 'package:intl/intl.dart';

/// Locale-aware number/date formatting for F2-B technician surfaces.
///
/// Views in this folder must never render raw ISO-8601 instants or ungrouped
/// ASCII numbers to users. All helpers take an explicit BCP-47 [localeName]
/// (pass `Localizations.localeOf(context).toString()` from the view) so the
/// output follows the active locale even where `Intl.defaultLocale` is not
/// wired to the widget tree.
///
/// Instant semantics match the F2-A helpers (`scheduledTimeUtc4` in
/// `screens/f2a/assigned_jobs_view.dart`): an ISO string without an explicit
/// offset is parsed as UTC, then displayed in the Asia/Dubai (UTC+4) wall
/// clock used across the technician app.
///
/// Digit shaping: `intl`'s bare `ar` symbols use Western digits (Gulf
/// convention), so an Arabic UI locale is normalized to `ar_EG` (CLDR `arab`
/// numbering) to render Arabic-Indic digits (`٣٤٬١٨٠`) as F3-B requires.
/// Number symbols are compiled into `intl`, so number helpers never need
/// async initialization. Date symbols load lazily: date helpers fall back to
/// English when date data was not initialized (call
/// `initializeDateFormatting` at app startup; tests do this in `setUpAll`),
/// so a view can never crash on locale data.
String _intlLocale(String? localeName) {
  final name = (localeName ?? Intl.getCurrentLocale()).trim();
  if (name.isEmpty) {
    return 'en';
  }
  final language = name.split(RegExp(r'[_-]')).first.toLowerCase();
  if (language == 'ar') {
    return 'ar_EG';
  }
  return name;
}

/// Parses [raw] as an instant, treating offset-less ISO strings as UTC.
/// Returns null when the string is empty or unparseable.
DateTime? parseInstantAsUtc(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final hasOffset = RegExp(r'([zZ]|[+-]\d{2}:?\d{2})$').hasMatch(text);
  final normalized = hasOffset ? text : '${text}Z';
  try {
    return DateTime.parse(normalized).toUtc();
  } on FormatException {
    return null;
  }
}

DateTime _dubaiWallClock(DateTime instantUtc) =>
    instantUtc.toUtc().add(const Duration(hours: 4));

/// Locale-shaped integer (grouping + locale digits, e.g. `34,180` vs `٣٤٬١٨٠`).
String formatCountLocalized(num value, String? localeName) =>
    NumberFormat.decimalPattern(_intlLocale(localeName)).format(value);

/// Locale-shaped `completed / total` pair.
String formatCountPairLocalized(num completed, num total, String? localeName) =>
    '${formatCountLocalized(completed, localeName)} / '
    '${formatCountLocalized(total, localeName)}';

/// Locale-shaped whole percent, keeping the ASCII `%` used by the Figma slot.
String formatPercentLocalized(num percent, String? localeName) =>
    '${formatCountLocalized(percent, localeName)}%';

/// Locale-shaped odometer (`48,210 KM` vs `٤٨٬٢١٠ KM`), mirroring F2-A
/// `formatOdometer` but bound to the view's active locale.
String formatOdometerLocalized(int? value, String? unit, String? localeName) {
  if (value == null) {
    return '';
  }
  final formatted = formatCountLocalized(value, localeName);
  return '$formatted ${(unit ?? 'KM').toUpperCase()}';
}

DateFormat _dateFormat(
  DateFormat Function(String locale) build,
  String? localeName,
) {
  final locale = _intlLocale(localeName);
  try {
    return build(locale);
  } on Exception {
    // Date data not initialized for [locale] (tests call
    // `initializeDateFormatting`; production startup should too). Fall back
    // to English rather than throwing from a view build.
    return build('en');
  }
}

/// Locale-shaped full date+time of an instant in the Dubai wall clock.
String formatInstantDubaiLocalized(String raw, String? localeName) {
  final parsed = parseInstantAsUtc(raw);
  if (parsed == null) {
    return '';
  }
  return _dateFormat(
    (locale) => DateFormat.yMMMd(locale).add_Hm(),
    localeName,
  ).format(_dubaiWallClock(parsed));
}

/// Locale-shaped wall-clock time of an instant in the Dubai wall clock,
/// mirroring F2-A `scheduledTimeUtc4` but bound to the active locale.
String formatTimeDubaiLocalized(String raw, String? localeName) {
  final parsed = parseInstantAsUtc(raw);
  if (parsed == null) {
    return '';
  }
  final time = _dateFormat(
    (locale) => DateFormat.Hm(locale),
    localeName,
  ).format(_dubaiWallClock(parsed));
  return '$time UTC+4';
}
