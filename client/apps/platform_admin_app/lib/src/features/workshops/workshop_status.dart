import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reference_data/reference_data.dart';

import '../../platform_providers.dart';
import '../../reference_status_lookup.dart';

/// Converts a backend workshop status into its served label.
///
/// The label comes from `statusesProvider('workshop')`; unknown free-form values
/// are humanized instead of leaking raw uppercase snake case. There is no local
/// status→label table.
String workshopStatusLabel(WidgetRef ref, String status) {
  if (status.trim().isEmpty) return '—';
  final strings = ref.watch(uiStringsProvider);
  final record = referenceRecordForStatus(
    ref.watch(statusesProvider('workshop')).value,
    status,
  );
  return referenceStatusLabelFrom(strings, record) ??
      humanizeStatusCode(status);
}

/// Localized staff-account status used inside workshop detail.
///
/// Member statuses are served by the same `workshop` domain.
String workshopMemberStatusLabel(WidgetRef ref, String status) =>
    workshopStatusLabel(ref, status);

/// Kept for callers that need the canonical comparison form.
String normalizeWorkshopStatus(String status) => normalizeStatusCode(status);
