import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'platform_providers.dart';
import 'features/auth/platform_login_page.dart';
import 'features/audit/audit_log_screen.dart';
import 'features/catalogues/data_catalogues_screen.dart';
import 'features/equipment/equipment_library_screen.dart';
import 'features/hierarchy/hierarchy_screen.dart';
import 'features/hierarchy/register_workshop_screen.dart';
import 'features/hierarchy/workshop_details_screen.dart';
import 'features/master_library/master_item_editor_screen.dart';
import 'features/master_library/master_library_screen.dart';
import 'features/master_library/categories_screen.dart';
import 'features/master_library/option_sets_screen.dart';
import 'features/templates/templates_screen.dart';
import 'features/templates/template_builder_screen.dart';
import 'features/scoring/scoring_screen.dart';
import 'features/documents/document_types_screen.dart';
import 'features/languages/languages_screen.dart';
import 'features/governance/config_health_screen.dart';
import 'features/settings/platform_settings_screen.dart';

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
        GoRoute(
          path: 'categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: 'option-sets',
          builder: (context, state) => const OptionSetsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/templates',
      builder: (context, state) => const TemplatesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => TemplateBuilderScreen(
            templateId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/scoring',
      builder: (context, state) => const ScoringScreen(),
    ),
    GoRoute(
      path: '/document-types',
      builder: (context, state) => const DocumentTypesScreen(),
    ),
    GoRoute(
      path: '/languages',
      builder: (context, state) => const LanguagesScreen(),
    ),
    GoRoute(
      path: '/config-health',
      builder: (context, state) => const ConfigHealthScreen(),
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

