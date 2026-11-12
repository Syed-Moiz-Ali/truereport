import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'features/inspection/technician_dynamic_item_page.dart';
import 'package:technician_app/src/features/inspection/technician_workspace_page.dart';
import 'package:technician_app/src/features/jobs/technician_jobs_clean_page.dart';
import 'package:technician_app/src/features/review/technician_completed_page.dart';
import 'package:technician_app/src/features/review/technician_signature_page.dart';
import 'package:technician_app/src/features/review/technician_summary_page.dart';
import 'package:technician_app/src/features/sync/technician_sync_page.dart';

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
        builder: (context, state) => const TechnicianJobsCleanPage(),
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const TechnicianSyncPage(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) =>
            TechnicianWorkspacePage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/items/:itemCode',
        builder: (context, state) => TechnicianItemPage(
          jobId: state.pathParameters['id']!,
          itemCode: state.pathParameters['itemCode']!,
        ),
      ),
      GoRoute(
        path: '/jobs/:id/summary',
        builder: (context, state) =>
            TechnicianSummaryPage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/signature',
        builder: (context, state) =>
            TechnicianSignaturePage(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/jobs/:id/completed',
        builder: (context, state) =>
            TechnicianCompletedPage(jobId: state.pathParameters['id']!),
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
