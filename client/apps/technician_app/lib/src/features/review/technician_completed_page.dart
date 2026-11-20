import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/reference_ui.dart';

class TechnicianCompletedPage extends ConsumerWidget {
  const TechnicianCompletedPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
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
                        t(TechnicianKeys.technicianCompletedPendingReview),
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
                      label: jobStatusLabel(ref, 'PENDING_REVIEW'),
                      tone: jobStatusTone(ref, 'PENDING_REVIEW'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: t(TechnicianKeys.technicianBackToJobs),
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
