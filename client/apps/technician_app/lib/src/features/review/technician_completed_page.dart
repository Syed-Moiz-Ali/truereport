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
    final colors = context.colors;
    return AppScaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: context.statusColors.success.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 44,
                        color: context.statusColors.success.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(
                        l10n.technicianCompletedPendingReview,
                        textAlign: TextAlign.center,
                        style: context.texts.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: StatusChip(
                      label: technicianStatusLabel(l10n, 'PENDING_REVIEW'),
                      tone: StatusTone.warning,
                    ),
                  ),
                  const SizedBox(height: 28),
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
