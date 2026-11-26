import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';

import '../jobs/technician_jobs_clean_page.dart';
import '../profile/profile_page.dart';
import 'fieldwork/shell_nav.dart';

/// The app's two surfaces — today's jobs and the technician's own screen —
/// held alive in one [IndexedStack] under Fieldwork navigation.
///
/// Below 900 the navigation is a full-width bottom dock; at 900 and above it is
/// a left rail. Sync is not a destination: it is an action the profile reaches.
class TechnicianShell extends StatelessWidget {
  const TechnicianShell({required this.index, super.key});

  /// 0 = jobs, 1 = profile.
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return TechnicianShellFrame(
      index: index,
      data: TechnicianNavData(
        jobsLabel: t(TechnicianKeys.technicianJobsTitle),
        profileLabel: t(TechnicianKeys.technicianProfileTitle),
        markLabel: t(TechnicianKeys.appTitle),
      ),
      onSelected: (next) {
        if (next == index) {
          return;
        }
        context.go(next == 1 ? '/profile' : '/jobs');
      },
      body: IndexedStack(
        index: index,
        children: const [TechnicianJobsCleanPage(), TechnicianProfilePage()],
      ),
    );
  }
}
