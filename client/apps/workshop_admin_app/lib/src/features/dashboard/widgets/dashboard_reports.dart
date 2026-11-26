import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_format.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_controls.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Delivery side of the floor: reports, generated documents, public links and
/// export volume. All counts come from the insights endpoint.
class DashboardReportsCard extends StatelessWidget {
  const DashboardReportsCard({
    required this.reports,
    required this.onOpenQueue,
    super.key,
  });

  final DashboardReports reports;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);

    final documents = reports.readyDocuments + reports.failedDocuments;
    final health = documents == 0 ? 0.0 : reports.readyDocuments / documents;

    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t(WorkshopAdminKeys.dashReportsTitle),
                  style: DashboardType.cardTitle(ws),
                ),
              ),
              QueueTextAction(
                label: t(WorkshopAdminKeys.dashViewAll),
                onTap: onOpenQueue,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  label: t(WorkshopAdminKeys.dashFlowPublished),
                  value: number.format(reports.published),
                  color: ws.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BigStat(
                  label: t(WorkshopAdminKeys.dashActiveLinks),
                  value: number.format(reports.activeLinks),
                  color: ws.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MiniRow(
            label: t(WorkshopAdminKeys.dashReportVersions),
            value: number.format(reports.versions),
          ),
          const SizedBox(height: 8),
          _MiniRow(
            label: t(WorkshopAdminKeys.dashDocumentsReady),
            value: number.format(reports.readyDocuments),
          ),
          const SizedBox(height: 8),
          _MiniRow(
            label: t(WorkshopAdminKeys.dashDocumentsFailed),
            value: number.format(reports.failedDocuments),
            valueColor: reports.failedDocuments > 0 ? ws.danger : ws.ink,
          ),
          const SizedBox(height: 8),
          _MiniRow(
            label: t(WorkshopAdminKeys.dashExports),
            value: dashboardBytes(reports.exportBytes),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(DashboardShape.pill),
            child: Container(
              height: 6,
              color: ws.canvas,
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: health.clamp(0, 1),
                child: ColoredBox(color: ws.success),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${number.format(reports.readyDocuments)} / ${number.format(documents)}',
            style: DashboardType.registerLabel(ws),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: ws.meta.copyWith(fontSize: 11.5, color: ws.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: DashboardType.tileNumber(ws)),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Row(
      children: [
        Expanded(child: Text(label, style: DashboardType.registerLabel(ws))),
        Text(
          value,
          style: DashboardType.registerCount(ws)
              .copyWith(color: valueColor, fontSize: 13),
        ),
      ],
    );
  }
}
