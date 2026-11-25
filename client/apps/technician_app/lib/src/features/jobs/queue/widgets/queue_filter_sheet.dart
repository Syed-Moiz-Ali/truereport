import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../../../reference_ui.dart';
import '../jobs_queue_format.dart';
import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';

/// The queue's whole date/status control, as a bottom sheet.
///
/// This is what replaced the 7-cell day rail: one entry point, one visible
/// selection, and every option (including dates before today and the hidden
/// cancelled jobs) reachable without horizontal scrolling.
class QueueFilterSheet extends ConsumerWidget {
  const QueueFilterSheet({
    required this.selectedDay,
    required this.selectedStatus,
    required this.cancelledCount,
    required this.onDaySelected,
    required this.onStatusSelected,
    required this.onClear,
    super.key,
  });

  /// Null means "all dates".
  final DateTime? selectedDay;

  /// Empty means "all statuses".
  final String selectedStatus;
  final int cancelledCount;

  final ValueChanged<DateTime?> onDaySelected;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = queueTodayKey();
    final tomorrow = today.add(const Duration(days: 1));
    final rawSelected = selectedDay;
    final selected = rawSelected == null
        ? null
        : DateTime(rawSelected.year, rawSelected.month, rawSelected.day);
    final custom =
        selected != null &&
        !_isSameDay(selected, today) &&
        !_isSameDay(selected, tomorrow);
    final statuses =
        ref.watch(statusesProvider('job')).value ?? const <ReferenceRecord>[];
    final cancelledRecord = _cancelledRecord(statuses);
    final cancelledLabel = cancelledRecord == null
        ? t(TechnicianKeys.technicianQueueCancelled)
        : jobStatusLabel(ref, cancelledRecord.code);
    final cancelledCode = cancelledRecord?.code ?? 'CANCELLED';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t(TechnicianKeys.technicianFilter),
            style: queueSection(context),
          ),
          const SizedBox(height: 10),
          Text(
            t(TechnicianKeys.technicianQueueFilterDates),
            style: queueEyebrow(context),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QueueChip(
                label: t(TechnicianKeys.technicianQueueSectionToday),
                selected: selected != null && _isSameDay(selected, today),
                onPressed: () => _selectDay(context, today),
              ),
              QueueChip(
                label: t(TechnicianKeys.technicianQueueFilterTomorrow),
                selected: selected != null && _isSameDay(selected, tomorrow),
                onPressed: () => _selectDay(context, tomorrow),
              ),
              QueueChip(
                label: t(TechnicianKeys.technicianQueueFilterAllDates),
                selected: selected == null,
                onPressed: () => _selectDay(context, null),
              ),
              QueueChip(
                label: custom
                    ? queueDayLabel(selected, t, locale)
                    : t(TechnicianKeys.technicianQueueFilterPickDate),
                selected: custom,
                onPressed: () => _pickDate(context, t, selected),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(t(TechnicianKeys.status), style: queueEyebrow(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QueueChip(
                label: t(TechnicianKeys.technicianAllStatuses),
                selected: selectedStatus.isEmpty,
                onPressed: () => _selectStatus(context, ''),
              ),
              for (final record in statuses.where(
                (value) =>
                    value.selectable && !_isCancelledCode(record: value.code),
              ))
                QueueChip(
                  label: jobStatusLabel(ref, record.code),
                  selected:
                      normalizeStatusCode(selectedStatus) ==
                      normalizeStatusCode(record.code),
                  onPressed: () => _selectStatus(context, record.code),
                ),
              // Always present and always counted: cancelled work is hidden
              // from the sections, never from the technician.
              QueueChip(
                label: '$cancelledLabel · $cancelledCount',
                selected: _isCancelledCode(record: selectedStatus),
                onPressed: () => _selectStatus(context, cancelledCode),
              ),
            ],
          ),
          if (selected != null || selectedStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: QueueButton(
                label: t(TechnicianKeys.technicianQueueClearFilters),
                variant: QueueButtonVariant.soft,
                onPressed: () {
                  onClear();
                  Navigator.of(context).maybePop();
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _selectDay(BuildContext context, DateTime? day) {
    onDaySelected(day);
    Navigator.of(context).maybePop();
  }

  void _selectStatus(BuildContext context, String status) {
    onStatusSelected(status);
    Navigator.of(context).maybePop();
  }

  Future<void> _pickDate(
    BuildContext context,
    UiStrings t,
    DateTime? selected,
  ) async {
    final initial = selected ?? queueTodayKey();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 2, 12, 31),
      helpText: t(TechnicianKeys.technicianQueueFilterPickDate),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    onDaySelected(DateTime(picked.year, picked.month, picked.day));
    Navigator.of(context).maybePop();
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isCancelledCode({required String record}) =>
    normalizeStatusCode(record) == 'CANCELLED';

ReferenceRecord? _cancelledRecord(List<ReferenceRecord> statuses) {
  for (final record in statuses) {
    if (_isCancelledCode(record: record.code)) {
      return record;
    }
  }
  return null;
}
