import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

/// Served operation copy for the outbox lines. The type code stays in the
/// payload; this is the only mapping from it to a user-visible label.
String syncOperationTitle(UiStrings t, String type) {
  switch (type.replaceAll('_clean', '')) {
    case 'assessment':
      return t(TechnicianKeys.technicianOpAssessment);
    case 'evidence':
      return t(TechnicianKeys.technicianOpEvidence);
    case 'customer':
      return t(TechnicianKeys.technicianOpCustomer);
    case 'vehicle':
      return t(TechnicianKeys.technicianOpVehicle);
    case 'consent':
      return t(TechnicianKeys.technicianOpConsent);
    default:
      return type;
  }
}

IconData syncOperationIcon(String type) {
  switch (type.replaceAll('_clean', '')) {
    case 'evidence':
      return Icons.photo_camera_outlined;
    case 'customer':
      return Icons.person_outline;
    case 'vehicle':
      return Icons.directions_car_outlined;
    case 'consent':
      return Icons.verified_user_outlined;
    default:
      return Icons.checklist_rounded;
  }
}

/// A queued change's clock time, localized (never a raw ISO string).
String syncClockLabel(MaterialLocalizations localizations, DateTime value) {
  return localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(value.toLocal()),
    alwaysUse24HourFormat: true,
  );
}

/// The oldest change's age as humanized, localized text: the clock time when it
/// happened today, otherwise the short date plus the time.
String syncOldestLabel(
  MaterialLocalizations localizations,
  DateTime oldest,
  DateTime now,
) {
  final local = oldest.toLocal();
  final today = now.toLocal();
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  final clock = syncClockLabel(localizations, local);
  if (sameDay) {
    return clock;
  }
  return '${localizations.formatShortDate(local)} · $clock';
}

/// One field of a conflict payload, with the phone and server values.
class ConflictField {
  const ConflictField({
    required this.label,
    required this.phone,
    required this.server,
    required this.phoneOnly,
    required this.serverOnly,
  });

  final String label;
  final String? phone;
  final String? server;

  /// True when the field exists only in the phone payload.
  final bool phoneOnly;

  /// True when the field exists only in the server payload.
  final bool serverOnly;
}

/// A readable, diff-first view of two conflict payloads.
class ConflictDiff {
  const ConflictDiff({
    required this.structured,
    required this.fields,
    required this.rawPhone,
    required this.rawServer,
  });

  /// False when either payload is not a JSON object; the board then shows the
  /// pretty-printed payload instead of a fabricated field list.
  final bool structured;
  final List<ConflictField> fields;
  final String rawPhone;
  final String rawServer;
}

/// Builds a diff that only carries what actually differs. If nothing differs
/// (or the maps are tiny) every field is shown so the screen is never empty.
ConflictDiff buildConflictDiff(String? clientJson, String? serverJson) {
  final clientText = clientJson?.trim() ?? '';
  final serverText = serverJson?.trim() ?? '';
  final client = _asMap(clientText);
  final server = _asMap(serverText);
  final structured =
      (clientText.isEmpty || client != null) &&
      (serverText.isEmpty || server != null) &&
      (client != null || server != null);
  if (!structured) {
    return ConflictDiff(
      structured: false,
      fields: const <ConflictField>[],
      rawPhone: _pretty(clientText),
      rawServer: _pretty(serverText),
    );
  }

  final clientMap = client ?? const <String, dynamic>{};
  final serverMap = server ?? const <String, dynamic>{};
  final keys = <String>[
    ...clientMap.keys,
    for (final key in serverMap.keys)
      if (!clientMap.containsKey(key)) key,
  ];

  final all = <ConflictField>[
    for (final key in keys)
      ConflictField(
        label: _fieldLabel(key),
        phone: _valueText(clientMap[key]),
        server: _valueText(serverMap[key]),
        phoneOnly: clientMap.containsKey(key) && !serverMap.containsKey(key),
        serverOnly: serverMap.containsKey(key) && !clientMap.containsKey(key),
      ),
  ];
  final changed = all
      .where(
        (field) =>
            field.phoneOnly || field.serverOnly || field.phone != field.server,
      )
      .toList(growable: false);

  return ConflictDiff(
    structured: true,
    fields: changed.isEmpty ? all : changed,
    rawPhone: '',
    rawServer: '',
  );
}

Map<String, dynamic>? _asMap(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on Object {
    return null;
  }
}

String? _valueText(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return '$value';
  }
  return jsonEncode(value);
}

String _pretty(String raw) {
  if (raw.isEmpty) {
    return '';
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
  } on Object {
    return raw;
  }
}

/// Turns `clientRevision` / `item_code` into readable field labels without
/// pretending to know a served translation that does not exist.
String _fieldLabel(String key) {
  final spaced = key
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceAll(RegExp('[_-]+'), ' ')
      .trim();
  if (spaced.isEmpty) {
    return key;
  }
  return spaced
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) {
        const acronyms = <String>{'id', 'vin', 'url', 'api', 'uuid'};
        if (acronyms.contains(word.toLowerCase())) {
          return word.toUpperCase();
        }
        return word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
