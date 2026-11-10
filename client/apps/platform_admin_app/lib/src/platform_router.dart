import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'platform_providers.dart';
import 'screens/auth/platform_login_page.dart';
import 'screens/audit/audit_log_screen.dart';
import 'screens/catalogues/data_catalogues_screen.dart';
import 'screens/equipment/equipment_library_screen.dart';
import 'screens/hierarchy/hierarchy_screen.dart';
import 'screens/hierarchy/register_workshop_screen.dart';
import 'screens/hierarchy/workshop_details_screen.dart';
import 'screens/master_library/master_item_editor_screen.dart';
import 'screens/master_library/master_library_screen.dart';
import 'screens/settings/platform_settings_screen.dart';

/// Notifies GoRouter to re-run `redirect` when auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

List<RouteBase> _buildRoutes() {
  return [
    GoRoute(
      path: '/',
      redirect: (_, _) => '/workshops',
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const PlatformLoginPage(),
    ),
    GoRoute(
      path: '/workshops',
      builder: (context, state) => const HierarchyScreen(),
      routes: [
        GoRoute(
          path: 'add-staff',
          builder: (context, state) => const _AddStaffRoutePage(),
        ),
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterWorkshopScreen(),
        ),
        GoRoute(
          path: 'details',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? 'workshop-1';
            return WorkshopDetailsScreen(workshopId: id);
          },
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => WorkshopDetailsScreen(
            workshopId: state.pathParameters['id'],
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/master-library',
      builder: (context, state) => const MasterLibraryScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const MasterItemEditorScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => MasterItemEditorScreen(
            itemId: state.pathParameters['id'],
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/data-catalogues',
      builder: (context, state) => const DataCataloguesScreen(),
    ),
    GoRoute(
      path: '/equipment',
      builder: (context, state) => const EquipmentLibraryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const PlatformSettingsScreen(),
    ),
    GoRoute(
      path: '/audit-log',
      builder: (context, state) => const AuditLogScreen(),
    ),
  ];
}

final platformRouterProvider = Provider<GoRouter>((ref) {
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
      if (location == '/signin') {
        return '/workshops';
      }
      return null;
    },
    routes: _buildRoutes(),
  );
});

final platformRouter = GoRouter(
  initialLocation: '/signin',
  routes: _buildRoutes(),
);

class _AddStaffRoutePage extends ConsumerStatefulWidget {
  const _AddStaffRoutePage();

  @override
  ConsumerState<_AddStaffRoutePage> createState() => _AddStaffRoutePageState();
}

class _AddStaffRoutePageState extends ConsumerState<_AddStaffRoutePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addStaffPanelOpenProvider.notifier).open();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HierarchyScreen();
  }
}

