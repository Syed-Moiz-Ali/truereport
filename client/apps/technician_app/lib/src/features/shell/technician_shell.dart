import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';

import '../jobs/queue/jobs_queue_page.dart';
import '../profile/profile_page.dart';

/// The app's two surfaces — today's jobs and the technician's own screen —
/// held alive in one [IndexedStack] under a two-item dock.
///
/// Sync is not a tab: it is an action the profile reaches, because it is
/// something you go and do, not a place you live in.
class TechnicianShell extends ConsumerWidget {
  const TechnicianShell({required this.index, super.key});

  /// 0 = jobs, 1 = profile.
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppBottomNavDock(
            selectedIndex: index,
            onSelected: (next) {
              if (next == index) {
                return;
              }
              context.go(next == 1 ? '/profile' : '/jobs');
            },
            items: [
              AppBottomNavItem(
                label: t(TechnicianKeys.technicianJobsTitle),
                icon: Icons.work_outline,
                selectedIcon: Icons.work,
              ),
              AppBottomNavItem(
                label: t(TechnicianKeys.technicianProfileTitle),
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: const [JobsQueuePage(), TechnicianProfilePage()],
      ),
    );
  }
}
