import 'package:admin_app/src/pages/platform_admin_home.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
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
      if (session.role == Role.platformAdmin) {
        return location == '/platform' ? null : '/platform';
      }
      if (session.role == Role.workshopAdmin) {
        return location == '/workshop' ? null : '/workshop';
      }
      return location == '/unauthorized' ? null : '/unauthorized';
    },
    routes: [
      GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
      GoRoute(
        path: '/platform',
        builder: (context, state) => const PlatformAdminHomePage(),
      ),
      GoRoute(
        path: '/workshop',
        builder: (context, state) =>
            const RoleHomeShell(role: Role.workshopAdmin),
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
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
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
