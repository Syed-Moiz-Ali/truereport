import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class FinalizedPage extends ConsumerWidget {
  const FinalizedPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final checklist = ref.watch(inspectionChecklistProvider(jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.finalizedReadOnly)),
      body: checklist.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 7),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(inspectionChecklistProvider(jobId)),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (value) => ListView(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          children: [
            SectionHeader(
              title: value.job.reference,
              subtitle: l10n.finalizedReadOnly,
            ),
            StatusChip(
              label: l10n.finalizedReadOnly,
              tone: StatusTone.success,
              icon: Icons.lock_outline,
            ),
            SizedBox(height: context.spacing.sm),
            ref
                .watch(technicianReportProvider(jobId))
                .when(
                  loading: () => const LoadingSkeleton(lines: 1),
                  error: (error, _) => StatusChip(
                    label: l10n.reportUnavailable,
                    tone: StatusTone.warning,
                    icon: Icons.description_outlined,
                  ),
                  data: (report) => StatusChip(
                    label: '${l10n.report}: ${report.generationStatus}',
                    tone: report.ready
                        ? StatusTone.success
                        : StatusTone.warning,
                    icon: Icons.description_outlined,
                  ),
                ),
            SizedBox(height: context.spacing.md),
            SectionHeader(title: l10n.deliveryHistory),
            ref
                .watch(technicianDeliveriesProvider(jobId))
                .when(
                  loading: () => const LoadingSkeleton(lines: 2),
                  error: (error, _) =>
                      Text(l10n.genericError, style: context.texts.bodySmall),
                  data: (items) {
                    if (items.isEmpty) {
                      return Text(
                        l10n.noDeliveries,
                        style: context.texts.bodySmall,
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              bottom: context.spacing.sm,
                            ),
                            child: Card(
                              child: Padding(
                                padding: EdgeInsetsDirectional.all(
                                  context.spacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: context.spacing.xs,
                                      runSpacing: context.spacing.xs,
                                      children: [
                                        StatusChip(
                                          label: item.channel,
                                          tone: StatusTone.info,
                                        ),
                                        StatusChip(
                                          label: item.status,
                                          tone: switch (item.status) {
                                            'SENT' ||
                                            'DELIVERED' => StatusTone.success,
                                            'FAILED' ||
                                            'DEAD_LETTER' => StatusTone.danger,
                                            _ => StatusTone.warning,
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: context.spacing.xs),
                                    Text(
                                      '${l10n.deliveryRecipient}: ${item.recipientMasked}',
                                      style: context.texts.bodySmall,
                                    ),
                                    Text(
                                      '${l10n.deliveryAttempts}: ${item.attempts} / ${item.maxAttempts}',
                                      style: context.texts.bodySmall,
                                    ),
                                    if (item.pdfAttached)
                                      Text(
                                        l10n.deliveryPdfAttached,
                                        style: context.texts.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            SizedBox(height: context.spacing.md),
            Text(
              '${value.job.vehicleMake} ${value.job.vehicleModel} - ${value.job.customerName}',
              style: context.texts.bodyMedium,
            ),
            SizedBox(height: context.spacing.lg),
            ...value.items.map(
              (item) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
                child: Card(
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(context.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.labelEn, style: context.texts.titleMedium),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          item.assessment == null
                              ? l10n.notStarted
                              : resultLabel(l10n, item.assessment!.resultCode),
                          style: context.texts.bodyMedium,
                        ),
                        if (item.assessment?.note != null &&
                            item.assessment!.note!.isNotEmpty) ...[
                          SizedBox(height: context.spacing.xs),
                          Text(
                            item.assessment!.note!,
                            style: context.texts.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
