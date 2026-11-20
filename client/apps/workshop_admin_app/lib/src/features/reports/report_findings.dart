import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';

import 'report_copy.dart';
import 'report_data.dart';
import 'report_pills.dart';

/// Key findings block. Each row is a real snapshot item: label, result,
/// severity and the inspector's note. Nothing is summarised or re-worded.
class ReportKeyFindings extends StatelessWidget {
  const ReportKeyFindings({required this.items, super.key});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final t = UiStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReportEyebrow(label: t(WorkshopAdminKeys.keyFindings)),
        SizedBox(height: spacing.sm),
        if (items.isEmpty)
          _Note(text: copy.noKeyFindings)
        else
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) ...[
              SizedBox(height: spacing.md),
              const WorkshopDivider(),
              SizedBox(height: spacing.md),
            ],
            _FindingRow(item: items[index], strong: true),
          ],
      ],
    );
  }
}

/// Findings grouped by the snapshot's own categories and order.
class ReportCategoryFindings extends StatelessWidget {
  const ReportCategoryFindings({required this.categories, super.key});

  final List<Map<String, dynamic>> categories;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final copy = context.reportCopy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReportEyebrow(label: copy.findingsByCategory),
        SizedBox(height: spacing.sm),
        if (categories.isEmpty)
          _Note(text: copy.noCategoryFindings)
        else
          for (var index = 0; index < categories.length; index++) ...[
            if (index > 0) ...[
              SizedBox(height: spacing.lg),
              const WorkshopDivider(),
              SizedBox(height: spacing.md),
            ],
            _CategoryBlock(category: categories[index]),
          ],
      ],
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({required this.category});

  final Map<String, dynamic> category;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final items = ReportData.maps(category['items']);
    final label = ReportData.localized(category, 'label');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label.isEmpty ? '—' : label,
                style: ws.cardTitle.copyWith(color: ws.ink),
              ),
            ),
            SizedBox(width: spacing.sm),
            Text(
              '${items.length}',
              style: ws.meta.copyWith(
                color: ws.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        if (items.isEmpty)
          Text('—', style: ws.meta.copyWith(color: ws.muted))
        else
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) SizedBox(height: spacing.sm),
            _FindingRow(item: items[index], strong: false),
          ],
      ],
    );
  }
}

class _FindingRow extends ConsumerWidget {
  const _FindingRow({required this.item, required this.strong});

  final Map<String, dynamic> item;
  final bool strong;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = context.ws;
    final spacing = context.spacing;
    final results = ref.watch(enumsProvider('result')).value;
    final severities = ref.watch(enumsProvider('severity')).value;

    final label = ReportData.localized(item, 'label');
    final localizedResult = ReportData.localized(item, 'result');
    final resultCode = ReportData.text(item['resultCode']);
    final result = localizedResult.isNotEmpty
        ? localizedResult
        : resultCode.isEmpty
        ? ''
        : referenceStatusText(results, resultCode);
    final severityCode = ReportData.text(item['severityCode']).toUpperCase();
    final localizedSeverity = ReportData.localized(item, 'severity');
    final severity = localizedSeverity.isNotEmpty
        ? localizedSeverity
        : severityCode.isEmpty
        ? ''
        : referenceStatusText(severities, severityCode);
    final note = ReportData.text(item['note']);

    return Semantics(
      container: true,
      label: [
        label,
        if (result.isNotEmpty) result,
        if (severity.isNotEmpty) severity,
        if (note.isNotEmpty) note,
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                label.isEmpty ? '—' : label,
                style: (strong ? ws.bodyStrong : ws.body).copyWith(
                  color: ws.ink,
                ),
              ),
              if (severity.isNotEmpty)
                ReportStatusPill(
                  label: severity,
                  tone: referenceStatusTone(severities, severityCode),
                ),
            ],
          ),
          if (result.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            Text(result, style: ws.meta.copyWith(color: ws.muted)),
          ],
          if (note.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            Text(
              note,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return WorkshopInlineNote(text: text, icon: Icons.search_off);
  }
}
