import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';

/// Localized job status pill.
///
/// Label and tone come from `statusesProvider('job')`. When the taxonomy has no
/// record the code is humanized and the tone is neutral; no local status table
/// is consulted.
class JobStatusBadge extends ConsumerWidget {
  const JobStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final records = ref.watch(statusesProvider('job')).value;
    final label = status.isEmpty
        ? t(WorkshopAdminKeys.jobsStatusUnknown)
        : referenceStatusText(records, status);
    return WorkshopStatusBadge(
      label: label,
      tone: referenceStatusTone(records, status),
    );
  }
}

/// Review sub-status pill, only rendered when it adds information.
class JobReviewStatusBadge extends ConsumerWidget {
  const JobReviewStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    if (status.isEmpty || status == 'NOT_SUBMITTED') {
      return const SizedBox.shrink();
    }
    final records = ref.watch(statusesProvider('review')).value;
    return WorkshopStatusBadge(
      label:
          '${t(WorkshopAdminKeys.jobsReviewTitle)}: ${referenceStatusText(records, status)}',
      tone: referenceStatusTone(records, status),
      icon: Icons.rate_review_outlined,
    );
  }
}

/// Publication pill served by `statusesProvider('publication')`.
class JobPublicationBadge extends ConsumerWidget {
  const JobPublicationBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(statusesProvider('publication')).value;
    return WorkshopStatusBadge(
      label: referenceStatusText(records, status),
      tone: referenceStatusTone(records, status),
      icon: Icons.public_outlined,
    );
  }
}
