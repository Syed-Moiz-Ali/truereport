import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

/// Reference-backed status labels and tones for the technician app.
///
/// The taxonomy endpoint is the only source of truth. There is deliberately no
/// job/sync/evidence status -> label or tone table anywhere in this app.
String normalizeStatusCode(String raw) =>
    raw.trim().replaceAll(RegExp(r'[\s_-]+'), '_').toUpperCase();

ReferenceRecord? referenceRecordForStatus(
  Iterable<ReferenceRecord>? records,
  String code,
) {
  if (records == null) {
    return null;
  }
  final target = normalizeStatusCode(code);
  if (target.isEmpty) {
    return null;
  }
  for (final record in records) {
    if (normalizeStatusCode(record.code) == target) {
      return record;
    }
  }
  return null;
}

/// Title-cases an unknown code without inventing a label.
String humanizeStatusCode(String raw) {
  final cleaned = raw.trim().replaceAll(RegExp(r'[\s_-]+'), ' ');
  if (cleaned.isEmpty) {
    return '';
  }
  return cleaned
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

/// Resolves a served `labelKey` through the active backend English bundle.
String referenceStatusCodeLabel(
  Iterable<ReferenceRecord>? records,
  String code,
) {
  final record = referenceRecordForStatus(records, code);
  if (record != null && record.labelKey.isNotEmpty) {
    final label = remoteEnglish(record.labelKey).trim();
    if (label.isNotEmpty) {
      return label;
    }
  }
  return humanizeStatusCode(code);
}

StatusTone referenceStatusCodeTone(
  Iterable<ReferenceRecord>? records,
  String code,
) {
  final record = referenceRecordForStatus(records, code);
  return statusToneFromToken(record?.tone ?? '');
}

String jobStatusLabel(WidgetRef ref, String code) =>
    referenceStatusCodeLabel(ref.watch(statusesProvider('job')).value, code);

StatusTone jobStatusTone(WidgetRef ref, String code) =>
    referenceStatusCodeTone(ref.watch(statusesProvider('job')).value, code);

String syncStatusLabel(WidgetRef ref, String code) =>
    referenceStatusCodeLabel(ref.watch(statusesProvider('sync')).value, code);

StatusTone syncStatusTone(WidgetRef ref, String code) =>
    referenceStatusCodeTone(ref.watch(statusesProvider('sync')).value, code);

String evidenceStatusLabel(WidgetRef ref, String code) =>
    referenceStatusCodeLabel(
      ref.watch(statusesProvider('evidence')).value,
      code,
    );

StatusTone evidenceStatusTone(WidgetRef ref, String code) =>
    referenceStatusCodeTone(
      ref.watch(statusesProvider('evidence')).value,
      code,
    );
