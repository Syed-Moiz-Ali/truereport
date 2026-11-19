import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import 'dashboard_activity.dart';
import 'dashboard_attention.dart';
import 'dashboard_commands.dart';
import 'dashboard_data.dart';
import 'dashboard_hero.dart';
import 'dashboard_palette.dart';
import 'dashboard_primitives.dart';
import 'dashboard_states.dart';

/// Platform Admin dashboard — Signal Room.
///
/// One verdict, one operating rail, one work queue, one feed. All figures come
/// from the existing overview/config providers; nothing is derived or invented.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformShell(
      currentRoute: '/dashboard',
      showSearch: false,
      onNavigate: (route) => context.go(route),
      child: const DashboardBody(),
    );
  }
}

/// The dashboard surface without the app shell. Exposed so the visual harness
/// can render it against the dark palette.
class DashboardBody extends ConsumerWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final overview = ref.watch(overviewProvider);
    final palette = DashboardPalette.of(context);
    final localeName = Localizations.localeOf(context).toString();

    void refresh() {
      ref.invalidate(overviewProvider);
      ref.invalidate(configHealthProvider);
      ref.invalidate(platformLanguagesProvider);
      ref.invalidate(auditEventsProvider);
    }

    return ColoredBox(
      color: palette.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final gutter = compact ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              compact ? 16 : 24,
              gutter,
              36,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kDashboardMaxWidth),
                child: overview.when(
                  loading: () => const DashboardSkeleton(),
                  error: (error, stackTrace) =>
                      DashboardError(strings: strings, onRetry: refresh),
                  data: (summary) {
                    if (summary.isEmpty) {
                      return DashboardReveal(
                        child: DashboardEmpty(
                          strings: strings,
                          onRegister: () => context.go('/workshops'),
                        ),
                      );
                    }
                    return _DashboardData(
                      summary: summary,
                      strings: strings,
                      localeName: localeName,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Secondary providers (health, languages, audit) are only watched once the
/// overview has data — the page must not fire three extra calls to render a
/// skeleton or an onboarding state.
class _DashboardData extends ConsumerWidget {
  const _DashboardData({
    required this.summary,
    required this.strings,
    required this.localeName,
  });

  final OverviewSummary summary;
  final UiMessageStrings strings;
  final String localeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(configHealthProvider).asData?.value;
    final languages =
        ref.watch(platformLanguagesProvider).asData?.value ??
        const <PlatformLanguage>[];
    final events =
        ref.watch(auditEventsProvider).asData?.value ??
        const <PlatformAuditEvent>[];
    return _DashboardContent(
      summary: summary,
      strings: strings,
      health: health,
      languages: languages,
      events: events,
      localeName: localeName,
      onRefresh: () {
        ref.invalidate(overviewProvider);
        ref.invalidate(configHealthProvider);
        ref.invalidate(platformLanguagesProvider);
        ref.invalidate(auditEventsProvider);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.summary,
    required this.strings,
    required this.health,
    required this.languages,
    required this.events,
    required this.localeName,
    required this.onRefresh,
  });

  final OverviewSummary summary;
  final UiMessageStrings strings;
  final ConfigHealth? health;
  final List<PlatformLanguage> languages;
  final List<PlatformAuditEvent> events;
  final String localeName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final attention = buildAttentionEntries(
      summary: summary,
      strings: strings,
      health: health,
      languages: languages,
    );
    final activity = buildActivityEntries(
      summary: summary,
      auditEvents: events,
      localeName: localeName,
    );
    final segments = buildJobRail(summary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardReveal(
          child: DashboardHero(
            summary: summary,
            strings: strings,
            segments: segments,
            attentionCount: attention.length,
            onRefresh: onRefresh,
            onReviewHealth: () => context.go('/checklist/health'),
          ),
        ),
        const SizedBox(height: 16),
        DashboardReveal(
          delay: const Duration(milliseconds: 80),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final queue = DashboardAttention(
                entries: attention,
                strings: strings,
                onOpen: (route) => context.go(route),
                onViewAll: () => context.go(
                  attention.isEmpty
                      ? '/checklist/health'
                      : attention.first.route,
                ),
                onOpenHealth: () => context.go('/checklist/health'),
              );
              final feed = DashboardActivity(
                entries: activity,
                strings: strings,
                onOpenAudit: () => context.go('/audit-log'),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: queue),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: feed),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [queue, const SizedBox(height: 16), feed],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        DashboardReveal(
          delay: const Duration(milliseconds: 160),
          child: DashboardCommands(
            strings: strings,
            onOpen: (route) => context.go(route),
          ),
        ),
      ],
    );
  }
}
