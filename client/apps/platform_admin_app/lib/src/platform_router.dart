import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/platform_login_page.dart';
import 'features/audit/audit_log_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/documents/document_types_screen.dart';
import 'features/languages/languages_screen.dart';
import 'features/languages/translation_queue_screen.dart';
import 'features/languages/ui_message_review_screen.dart';
import 'features/master_library/master_item_editor_screen.dart';
import 'features/master_library/master_library_screen.dart';
import 'features/master_library/categories_screen.dart';
import 'features/master_library/option_sets_screen.dart';
import 'features/templates/templates_screen.dart';
import 'features/templates/template_builder_screen.dart';
import 'features/governance/config_health_screen.dart';
import 'features/settings/platform_settings_screen.dart';
import 'features/workshops/workshop_detail_screen.dart';
import 'features/workshops/workshops_screen.dart';
import 'features/workshops/workshop_form.dart';

/// Notifies GoRouter to re-run `redirect` when auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

List<RouteBase> _buildRoutes() {
  return [
    GoRoute(path: '/', redirect: (_, _) => '/dashboard'),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const PlatformLoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/workshops',
      builder: (context, state) => const WorkshopsScreen(),
      routes: [
        // Static children first: go_router matches in order, so 'new'
        // (and the legacy aliases below) must precede ':id'.
        GoRoute(
          path: 'new',
          builder: (context, state) => const WorkshopFormPage(),
        ),
        // Removed staff-registration flow: staff is managed in detail tabs.
        GoRoute(path: 'add-staff', redirect: (_, _) => '/workshops'),
        GoRoute(path: 'register', redirect: (_, _) => '/workshops/new'),
        GoRoute(
          path: 'details',
          redirect: (context, state) {
            final id = state.uri.queryParameters['id'];
            return id == null || id.isEmpty ? '/workshops' : '/workshops/$id';
          },
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              WorkshopDetailScreen(workshopId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/checklist', redirect: (_, _) => '/checklist/items'),
    GoRoute(
      path: '/checklist/items',
      builder: (context, state) => const MasterLibraryScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const MasterItemEditorScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) =>
              MasterItemEditorScreen(itemId: state.pathParameters['id']),
        ),
      ],
    ),
    GoRoute(
      path: '/checklist/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/checklist/option-sets',
      builder: (context, state) => const OptionSetsScreen(),
    ),
    GoRoute(
      path: '/checklist/templates',
      builder: (context, state) => const TemplatesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              TemplateBuilderScreen(templateId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/checklist/health',
      builder: (context, state) => const ConfigHealthScreen(),
    ),
    GoRoute(path: '/reports', redirect: (_, _) => '/reports/document-types'),
    GoRoute(
      path: '/reports/document-types',
      builder: (context, state) => const DocumentTypesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const PlatformSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/languages',
      builder: (context, state) => const LanguagesScreen(),
    ),
    GoRoute(
      path: '/settings/languages/:code/translations',
      builder: (context, state) =>
          TranslationQueueScreen(languageCode: state.pathParameters['code']!),
    ),
    GoRoute(
      path: '/settings/languages/:code/review',
      builder: (context, state) =>
          UiMessageReviewScreen(languageCode: state.pathParameters['code']!),
    ),
    GoRoute(
      path: '/audit-log',
      builder: (context, state) => const AuditLogScreen(),
    ),
    // Legacy IA redirects (no 404s for bookmarked / deep-linked old routes).
    GoRoute(path: '/master-library', redirect: (_, _) => '/checklist/items'),
    GoRoute(
      path: '/master-library/categories',
      redirect: (_, _) => '/checklist/categories',
    ),
    GoRoute(
      path: '/master-library/option-sets',
      redirect: (_, _) => '/checklist/option-sets',
    ),
    GoRoute(
      path: '/master-library/new',
      redirect: (_, _) => '/checklist/items/new',
    ),
    GoRoute(
      path: '/master-library/:id/edit',
      redirect: (context, state) =>
          '/checklist/items/${state.pathParameters['id']}/edit',
    ),
    GoRoute(path: '/templates', redirect: (_, _) => '/checklist/templates'),
    GoRoute(
      path: '/templates/:id',
      redirect: (context, state) =>
          '/checklist/templates/${state.pathParameters['id']}',
    ),
    GoRoute(path: '/config-health', redirect: (_, _) => '/checklist/health'),
    GoRoute(
      path: '/document-types',
      redirect: (_, _) => '/reports/document-types',
    ),
    GoRoute(path: '/languages', redirect: (_, _) => '/settings/languages'),
    GoRoute(
      path: '/data-catalogues',
      redirect: (_, _) => '/checklist/option-sets',
    ),
    GoRoute(path: '/equipment', redirect: (_, _) => '/checklist/items'),
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
        return '/dashboard';
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
