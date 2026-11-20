import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reference_data/reference_data.dart';

import '../../platform_providers.dart';
import '../../reference_status_lookup.dart';

/// Returns the served label for a checklist status.
///
/// The label comes from `statusesProvider('checklist')`; unknown values are
/// humanized. There is no local status→label table.
String checklistStatusLabel(WidgetRef ref, String status) {
  if (status.trim().isEmpty) return '—';
  final strings = ref.watch(uiStringsProvider);
  final record = referenceRecordForStatus(
    ref.watch(statusesProvider('checklist')).value,
    status,
  );
  return referenceStatusLabelFrom(strings, record) ??
      humanizeStatusCode(status);
}

/// Canonical comparison form for punctuation and spacing differences.
String normalizeChecklistStatus(String status) => normalizeStatusCode(status);
