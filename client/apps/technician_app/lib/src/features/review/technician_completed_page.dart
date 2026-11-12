import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/ui_helpers.dart';

class TechnicianCompletedPage extends StatelessWidget {
  const TechnicianCompletedPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      backgroundColor: context.colors.surface,
      appBar: TechnicianAppBar(
        title: l10n.technicianJobCompleted,
        showBack: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.all(context.spacing.gutter),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: context.sizing.iconXl,
                    color: context.statusColors.success.foreground,
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(
                    l10n.technicianCompletedPendingReview,
                    style: context.texts.headlineSmall,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusChip(
                      label: technicianStatusLabel(l10n, 'PENDING_REVIEW'),
                      tone: StatusTone.warning,
                    ),
                  ),
                  SizedBox(height: context.spacing.lg),
                  AppButton(
                    label: l10n.technicianBackToJobs,
                    icon: Icons.arrow_back,
                    expand: true,
                    onPressed: () => context.go('/jobs'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
