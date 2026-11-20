import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import 'dashboard_feed.dart';
import 'trellis/trellis_actions.dart';
import 'trellis/trellis_activity.dart';
import 'trellis/trellis_attention_sheet.dart';
import 'trellis/trellis_header.dart';
import 'trellis/trellis_modules.dart';
import 'trellis/trellis_ribbon.dart';
import 'trellis/trellis_ui.dart';

/// Platform Admin dashboard — Trellis.
///
/// A board of six real domains, an attention ribbon, quick actions, and a
/// quiet activity ledger. Every figure comes from the existing overview,
/// health, language, and audit providers.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformShell(
      currentRoute: '/dashboard',
      showSearch: false,
      onNavigate: (route) => context.go(route),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final overview = ref.watch(overviewProvider);

    void refresh() {
      ref.invalidate(overviewProvider);
      ref.invalidate(configHealthProvider);
      ref.invalidate(platformLanguagesProvider);
      ref.invalidate(auditEventsProvider);
    }

    return overview.when(
      loading: () => const TrellisSkeleton(),
      error: (_, _) => TrellisError(strings: strings, onRetry: refresh),
      data: (summary) {
        if (summary.isEmpty) {
          return TrellisEmpty(
            title: strings.tKey(PlatformAdminKeys.emptyWorkshopsTitle),
            body: strings.tKey(PlatformAdminKeys.emptyWorkshopsBody),
            actionLabel: strings.tKey(PlatformAdminKeys.pageWorkshopsAdd),
            onAction: () => context.go('/workshops/new'),
          );
        }
        return _DashboardContent(
          strings: strings,
          summary: summary,
          onRefresh: refresh,
        );
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.strings,
    required this.summary,
    required this.onRefresh,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(configHealthProvider).asData?.value;
    final languages =
        ref.watch(platformLanguagesProvider).asData?.value ??
        const <PlatformLanguage>[];
    final events =
        ref.watch(auditEventsProvider).asData?.value ??
        const <PlatformAuditEvent>[];
    final localeName = Localizations.localeOf(context).toString();

    final attention = buildDashboardAttention(
      summary: summary,
      strings: strings,
      health: health,
      languages: languages,
    );
    final activity = buildDashboardActivity(
      summary: summary,
      auditEvents: events,
      localeName: localeName,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TrellisHeader(
                    strings: strings,
                    onRefresh: onRefresh,
                    width: constraints.maxWidth,
                  ),
                  const SizedBox(height: 16),
                  TrellisRibbon(
                    strings: strings,
                    entries: attention,
                    onDetails: () => showTrellisAttentionSheet(
                      context: context,
                      strings: strings,
                      entries: attention,
                      onOpen: (route) => context.go(route),
                      onHealth: () => context.go('/checklist/health'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TrellisBento(
                    strings: strings,
                    summary: summary,
                    languages: languages,
                    onOpen: (route) => context.go(route),
                  ),
                  const SizedBox(height: 24),
                  TrellisActions(
                    strings: strings,
                    onOpen: (route) => context.go(route),
                  ),
                  const SizedBox(height: 24),
                  TrellisActivity(
                    strings: strings,
                    entries: activity,
                    onViewAll: () => context.go('/audit-log'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
