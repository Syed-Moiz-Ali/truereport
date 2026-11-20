/// Backend-driven English UI text.
///
/// The generated English getters call [remoteEnglish]; parameterized getters
/// call [remoteFormat]. The app fills this map from
/// `/api/v1/i18n/ui-messages/<client>/bundle`. Flutter never ships an English
/// fallback: an unresolved key renders as an empty string.
final Map<String, String> _remoteEnglish = <String, String>{};

void setRemoteEnglish(Map<String, String> values) {
  _remoteEnglish
    ..clear()
    ..addAll(values);
}

void clearRemoteEnglish() => _remoteEnglish.clear();

/// A read-only view of the resolved backend messages.
///
/// Used by `UiStrings` bootstrapping and by tests that need a bundle without
/// constructing the generated localizations class.
Map<String, String> get remoteEnglishValues =>
    Map<String, String>.unmodifiable(_remoteEnglish);

String remoteEnglish(String key) => _remoteEnglish[key] ?? '';

/// Formats a backend template with simple `{name}` placeholders and ICU
/// `{count, plural, =1{...} other{...}}` clauses.
String remoteFormat(String key, Map<String, Object?> params) {
  final template = _remoteEnglish[key];
  if (template == null || template.isEmpty) return '';
  return formatRemoteMessage(template, params);
}

String formatRemoteMessage(String template, Map<String, Object?> params) {
  final out = StringBuffer();
  var index = 0;
  while (index < template.length) {
    if (template[index] != '{') {
      out.write(template[index]);
      index += 1;
      continue;
    }
    final end = _matchingBrace(template, index);
    if (end < 0) {
      out.write(template[index]);
      index += 1;
      continue;
    }
    final body = template.substring(index + 1, end);
    final pluralAt = body.indexOf(', plural,');
    if (pluralAt > 0) {
      final name = body.substring(0, pluralAt).trim();
      final value = params[name];
      final count = value is num ? value.toInt() : 0;
      final clauses = body.substring(pluralAt + ', plural,'.length);
      out.write(_selectPlural(clauses, count, params));
    } else {
      final name = body.trim();
      out.write(params[name]?.toString() ?? '{$body}');
    }
    index = end + 1;
  }
  return out.toString();
}

int _matchingBrace(String text, int open) {
  var depth = 0;
  for (var i = open; i < text.length; i += 1) {
    if (text[i] == '{') depth += 1;
    if (text[i] == '}') {
      depth -= 1;
      if (depth == 0) return i;
    }
  }
  return -1;
}

String _selectPlural(String clauses, int count, Map<String, Object?> params) {
  String? exact;
  String? other;
  var index = 0;
  while (index < clauses.length) {
    while (index < clauses.length && clauses[index].trim().isEmpty) {
      index += 1;
    }
    final keyStart = index;
    while (index < clauses.length &&
        clauses[index] != '{' &&
        clauses[index] != '}') {
      index += 1;
    }
    if (index >= clauses.length || clauses[index] != '{') break;
    final key = clauses.substring(keyStart, index).trim();
    final end = _matchingBrace(clauses, index);
    if (end < 0) break;
    final value = clauses.substring(index + 1, end);
    if (key == 'other') {
      other = value;
    } else if (key == '=$count') {
      exact = value;
    }
    index = end + 1;
  }
  return formatRemoteMessage(exact ?? other ?? '', params);
}

bool get hasRemoteEnglish => _remoteEnglish.isNotEmpty;
