import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/assessment_page.dart';
import 'package:technician_app/src/features/inspection/checklist_page.dart';
import 'package:technician_app/src/features/review/finalized_page.dart';
import 'package:technician_app/src/features/inspection/inspection_hub_page.dart';
import 'package:technician_app/src/features/jobs/job_detail_page.dart';
import 'package:technician_app/src/features/review/review_page.dart';
import 'package:technician_app/src/features/sync/sync_queue_page.dart';
import 'package:technician_app/src/features/jobs/technician_jobs_page.dart';
import 'package:technician_app/src/features/jobs/walk_in_job_page.dart';

/// Notifies GoRouter to re-run `redirect` when auth state changes.
///
/// The router instance itself is created ONCE. Recreating GoRouter on every
/// auth change (via `ref.watch`) disposes the current page, which wiped the
/// sign-in form text and swallowed the error message on failed logins.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final technicianRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/signin',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) {
        return null;
      }
      final session = auth.value;
      final location = state.matchedLocation;
      if (session == null) {
        return location == '/signin' ? null : '/signin';
      }
      if (session.role != Role.technician) {
        return location == '/unauthorized' ? null : '/unauthorized';
      }
      return location == '/signin' ? '/jobs' : null;
    },
    routes: [
      GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const TechnicianJobsPage(),
      ),
      GoRoute(
        path: '/jobs/new',
        builder: (context, state) => const WalkInJobPage(),
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncQueuePage(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) =>
            JobDetailPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/hub',
        builder: (context, state) =>
            InspectionHubPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/checklist',
        builder: (context, state) =>
            ChecklistPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/items/:itemId',
        builder: (context, state) => AssessmentPage(
          jobId: state.pathParameters['id']!,
          itemId: state.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:id/review',
        builder: (context, state) =>
            ReviewPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/finalized',
        builder: (context, state) =>
            FinalizedPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const _TechnicianUnauthorizedPage(),
      ),
    ],
  );
});

class _TechnicianUnauthorizedPage extends ConsumerWidget {
  const _TechnicianUnauthorizedPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.technicianHomeTitle)),
      body: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: EmptyState(
            title: l10n.error,
            body: l10n.signInSubtitle,
            icon: Icons.lock_outline,
            action: AppButton(
              label: l10n.signOut,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              variant: AppButtonVariant.tonal,
            ),
          ),
        ),
      ),
    );
  }
}
