import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/reference_ui.dart';

/// One queued change, as a ledger line: when, what, and its state as a dot
/// *and* a word.
class SyncOperationRow extends ConsumerWidget {
  const SyncOperationRow({required this.operation, super.key});

  final SyncOperation operation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final failed = operation.state == 'FAILED';
    final tone = context.statusColors.forTone(
      syncStatusTone(ref, operation.state),
    );
    final itemCode =
        operation.payload['itemCode'] as String? ??
        operation.payload['itemId'] as String?;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(operation.createdAt.toLocal()),
      alwaysUse24HourFormat: true,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                time,
                style: context.texts.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  syncOperationTitle(t, operation.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tone.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      syncStatusLabel(ref, operation.state),
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (itemCode != null && itemCode.isNotEmpty) ...[
                      Text(
                        ' · $itemCode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (failed && operation.lastError != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${t(TechnicianKeys.technicianSyncLastError)}: '
                    '${operation.lastError}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.statusColors.danger.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (failed && operation.attempts > 1) ...[
                  const SizedBox(height: 1),
                  Text(
                    t(TechnicianKeys.technicianSyncAttempts, {
                      'count': operation.attempts,
                    }),
                    style: context.texts.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
