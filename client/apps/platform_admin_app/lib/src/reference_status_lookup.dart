import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

/// Reference-backed status labels and tones.
///
/// The platform no longer owns a status label/tone table: every value comes
/// from `statusesProvider`. When the taxonomy has not arrived yet (or a store
/// is offline), the code is humanized unchanged from the previous unknown-code
/// behavior. No label/tone map is re-introduced here.

/// Canonical comparison form: `DEPOT HUB`, `depot-hub` and `DEPOT_HUB` match.
String normalizeStatusCode(String raw) =>
    raw.trim().replaceAll(RegExp(r'[\s_-]+'), '_').toUpperCase();

ReferenceRecord? referenceRecordForStatus(
  Iterable<ReferenceRecord>? records,
  String code,
) {
  if (records == null) return null;
  final target = normalizeStatusCode(code);
  if (target.isEmpty) return null;
  for (final record in records) {
    if (normalizeStatusCode(record.code) == target) return record;
  }
  return null;
}

/// Resolves a served `labelKey` through the active UI bundle.
String? referenceStatusLabelFrom(
  UiMessageStrings strings,
  ReferenceRecord? record,
) {
  if (record == null || record.labelKey.isEmpty) return null;
  final text = strings.resolveFlatKey(record.labelKey);
  if (text == null || text.trim().isEmpty) return null;
  return text;
}

/// Resolves a served label for a status/enum code, falling back to a
/// humanized code only. This is the shared replacement for local maps.
String referenceCodeLabel(
  UiMessageStrings strings,
  Iterable<ReferenceRecord>? records,
  String code,
) {
  if (code.trim().isEmpty) return '';
  final record = referenceRecordForStatus(records, code);
  return referenceStatusLabelFrom(strings, record) ?? humanizeStatusCode(code);
}

/// Reference domain names added for Phase 6. Keep them in one place so the
/// client and the backend catalog cannot drift silently.
const String contentTypeEnum = 'content-type';
const String translationStatusDomain = 'translation-status';
const String inputTypeEnum = 'input-type';
const String measurementDirectionEnum = 'measurement-direction';
const String documentTypeStatusDomain = 'document-type-status';

/// Title-cases an unknown code without inventing a label.
String humanizeStatusCode(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[\s_-]+'), ' ');
  if (cleaned.isEmpty) return '';
  return cleaned
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

/// Domains searched for a generic status code, in visual-stability order.
const List<String> _statusDomains = <String>[
  'workshop',
  'checklist',
  'health',
  'document',
  'chip',
];

/// Served tone token for one status code.
///
/// DISABLED resolves through `chip`; PENDING/FAILED through `document`; every
/// other code searches the taxonomy in [_statusDomains]. Null means "not
/// loaded / not found", so the caller keeps its neutral presentation.
final statusToneTokenProvider = Provider.autoDispose.family<String?, String>((
  ref,
  status,
) {
  final code = normalizeStatusCode(status);
  if (code.isEmpty) return null;
  final preferred = <String>[
    if (code == 'DISABLED') 'chip',
    if (code == 'PENDING' || code == 'FAILED') 'document',
    ..._statusDomains,
  ];
  for (final domain in preferred) {
    final record = referenceRecordForStatus(
      ref.watch(statusesProvider(domain)).value,
      code,
    );
    if (record != null && record.tone.isNotEmpty) return record.tone;
  }
  return null;
});
