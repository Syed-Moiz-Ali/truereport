import 'package:intl/intl.dart';

/// Locale-aware date/time for checklist item `updatedAt` instants.
///
/// Offset-less ISO strings are treated as UTC and rendered in the UTC+4 wall
/// clock used by the workshop-facing apps. Invalid values render an em dash.
String checklistUpdatedAtLabel(String raw, String localeName) {
  final parsed = _parseUtc(raw);
  if (parsed == null) return '—';

  final wall = parsed.add(const Duration(hours: 4));
  final locale = localeName.trim().isEmpty ? 'en' : localeName.trim();
  try {
    return DateFormat.yMd(locale).add_Hm().format(wall);
  } on Exception {
    return DateFormat.yMd('en').add_Hm().format(wall);
  }
}

DateTime? _parseUtc(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final hasOffset = RegExp(r'([zZ]|[+-]\d{2}:?\d{2})$').hasMatch(text);
  try {
    return DateTime.parse(hasOffset ? text : '${text}Z').toUtc();
  } on FormatException {
    return null;
  }
}
