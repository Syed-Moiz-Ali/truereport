import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';

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

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/signin',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading && !auth.hasError) {
        return null;
      }
      // A failed restore is signed out. Riverpod keeps the previous value on
      // an error state; trusting it left the app on a protected screen while
      // every request 401'd instead of returning to sign-in.
      final session = auth.hasError ? null : auth.value;
      final location = state.matchedLocation;
      if (session == null) {
        return location == '/signin' ? null : '/signin';
      }
      if (session.role == Role.workshopAdmin) {
        return location == '/workshop' ? null : '/workshop';
      }
      return location == '/unauthorized' ? null : '/unauthorized';
    },
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const WorkshopLoginPage(),
      ),
      GoRoute(
        path: '/workshop',
        builder: (context, state) => const WorkshopAdminHomePage(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const _UnauthorizedPage(),
      ),
    ],
  );
});

class _UnauthorizedPage extends ConsumerWidget {
  const _UnauthorizedPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    return AppScaffold(
      appBar: AppBar(title: Text(t(WorkshopAdminKeys.appTitle))),
      body: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: EmptyState(
            title: t(WorkshopAdminKeys.error),
            body: t(WorkshopAdminKeys.signInSubtitle),
            icon: Icons.lock_outline,
            action: AppButton(
              label: t(WorkshopAdminKeys.signOut),
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
