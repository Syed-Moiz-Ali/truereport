import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/pages/assessment_page.dart';
import 'package:technician_app/src/pages/checklist_page.dart';
import 'package:technician_app/src/pages/finalized_page.dart';
import 'package:technician_app/src/pages/inspection_hub_page.dart';
import 'package:technician_app/src/pages/job_detail_page.dart';
import 'package:technician_app/src/pages/review_page.dart';
import 'package:technician_app/src/pages/sync_queue_page.dart';
import 'package:technician_app/src/pages/technician_jobs_page.dart';
import 'package:technician_app/src/pages/walk_in_job_page.dart';

final technicianRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/signin',
    redirect: (context, state) {
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
