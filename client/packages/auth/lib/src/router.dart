import 'package:auth/src/auth_controller.dart';
import 'package:auth/src/role_home.dart';
import 'package:auth/src/sign_in_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/signin',
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (auth.isLoading) {
        return null;
      }
      final session = auth.value;
      if (session == null) {
        return location == '/signin' ? null : '/signin';
      }
      final home = _homeFor(session.role);
      if (location == '/signin' || location != home) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/signin', builder: (context, state) => const SignInPage()),
      GoRoute(
        path: '/technician',
        builder: (context, state) => const RoleHomeShell(role: Role.technician),
      ),
      GoRoute(
        path: '/workshop',
        builder: (context, state) =>
            const RoleHomeShell(role: Role.workshopAdmin),
      ),
      GoRoute(
        path: '/platform',
        builder: (context, state) =>
            const RoleHomeShell(role: Role.platformAdmin),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return AppScaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: state.error?.toString() ?? l10n.genericError,
            ),
          ),
        ),
      );
    },
  );
});

String _homeFor(Role role) => switch (role) {
  Role.technician => '/technician',
  Role.workshopAdmin => '/workshop',
  Role.platformAdmin => '/platform',
};
