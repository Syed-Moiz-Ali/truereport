import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../platform_providers.dart';
import '../workshops/workshop_activity.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Region 2 — one continuous ledger for every destination (Direction A).
///
/// Rows with live values, hairline dividers, no group chrome: the cover and
/// the count already set context, so the ledger only routes. The mutating
/// seed action arrives as [seedTrailing] from the screen, which owns the
/// confirm dialog and the seeding state.
class SettingsLedger extends ConsumerWidget {
  const SettingsLedger({super.key, required this.seedTrailing});

  final Widget seedTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);

    return DeckReveal(
      delay: 90,
      child: Container(
        decoration: BoxDecoration(
          color: DeckPalette.of(context).surface,
          borderRadius: BorderRadius.circular(DeckRadius.card),
          border: Border.all(color: DeckPalette.of(context).border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DeckRadius.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LanguagesRow(strings: strings),
              const _Hairline(),
              _AuditRow(strings: strings),
              const _Hairline(),
              _HealthRow(strings: strings),
              const _Hairline(),
              _NavRow(
                icon: Icons.rate_review_outlined,
                title: strings.tKey(
                  PlatformAdminKeys.settingsTranslationReviewTitle,
                ),
                route: '/configuration/translations',
              ),
              const _Hairline(),
              _NavRow(
                icon: Icons.account_tree_outlined,
                title: strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
                route: '/checklist/option-sets',
              ),
              const _Hairline(),
              _NavRow(
                icon: Icons.swap_horiz_rounded,
                title: strings.tKey(
                  PlatformAdminKeys.referenceTransitionsTitle,
                ),
                route: '/configuration/transitions',
              ),
              const _Hairline(),
              _SeedRow(strings: strings, trailing: seedTrailing),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.title,
    required this.route,
    this.meta,
    this.value,
    this.valueLabel,
  });

  final IconData icon;
  final String title;
  final String route;
  final String? meta;
  final Widget? value;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: valueLabel == null ? title : '$title, $valueLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          hoverColor: palette.canvas,
          highlightColor: palette.canvas,
          child: Container(
            constraints: const BoxConstraints(minHeight: DeckSize.rowHeight),
            padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(DeckRadius.tile),
                  ),
                  child: Icon(icon, size: 17, color: palette.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: DeckType.style(
                          13.5,
                          19,
                          FontWeight.w500,
                          palette.ink,
                        ),
                        maxLines: 2,
                      ),
                      if (meta != null && meta!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta!,
                          style: DeckType.style(
                            11.5,
                            16,
                            FontWeight.w400,
                            palette.muted,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 10),
                  value!,
                  const SizedBox(width: 10),
                ],
                Transform.scale(
                  scaleX: rtl ? -1 : 1,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.faint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bare navigation row with no live value: title and chevron only, never a
/// fabricated status.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.title, required this.route});

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) =>
      _RowShell(icon: icon, title: title, route: route);
}

class _LanguagesRow extends ConsumerWidget {
  const _LanguagesRow({required this.strings});
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(platformLanguagesProvider);
    return languages.when(
      loading: () => _RowShell(
        icon: Icons.translate_rounded,
        title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
        route: '/settings/languages',
        value: const DeckSkeleton(width: 96, height: 28, radius: 999),
      ),
      error: (_, _) => _RowShell(
        icon: Icons.translate_rounded,
        title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
        route: '/settings/languages',
        value: _RowRetry(
          label: strings.tKey(CommonKeys.buttonRetry),
          onRetry: () => ref.invalidate(platformLanguagesProvider),
        ),
      ),
      data: (list) {
        final live = list.where((item) => item.isLive).toList();
        final setup = list.where((item) => item.isInSetup).length;
        final names = live
            .map((item) => item.nativeName)
            .where((name) => name.isNotEmpty)
            .join(' · ');
        final Widget? value = list.isEmpty
            ? null
            : DeckChip(
                label: strings.tArgsKey(
                  PlatformAdminKeys.sidebarLanguagesStatus,
                  <String, Object?>{
                    'live': '${live.length}',
                    'setup': '$setup',
                  },
                ),
                color: DeckPalette.of(context).accent,
                soft: DeckPalette.of(context).accentSoft,
              );
        return _RowShell(
          icon: Icons.translate_rounded,
          title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
          meta: names.isEmpty ? null : names,
          route: '/settings/languages',
          value: value,
        );
      },
    );
  }
}

class _AuditRow extends ConsumerWidget {
  const _AuditRow({required this.strings});
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = ref.watch(auditEventsProvider);
    final localeName = Localizations.localeOf(context).toString();
    return audit.when(
      loading: () => _RowShell(
        icon: Icons.policy_outlined,
        title: strings.tKey(PlatformAdminKeys.settingsAuditTitle),
        route: '/audit-log',
        value: const DeckSkeleton(width: 96, height: 28, radius: 999),
      ),
      error: (_, _) => _RowShell(
        icon: Icons.policy_outlined,
        title: strings.tKey(PlatformAdminKeys.settingsAuditTitle),
        route: '/audit-log',
        value: _RowRetry(
          label: strings.tKey(CommonKeys.buttonRetry),
          onRetry: () => ref.invalidate(auditEventsProvider),
        ),
      ),
      data: (events) {
        final Widget value = events.isEmpty
            ? DeckChip(
                label: strings.tKey(PlatformAdminKeys.settingsAuditNoEvents),
                color: DeckPalette.of(context).faint,
                soft: DeckPalette.of(context).surface,
              )
            : DeckChip(
                label: strings.tArgsKey(
                  PlatformAdminKeys.settingsAuditEventsCount,
                  <String, Object?>{'count': '${events.length}'},
                ),
                color: DeckPalette.of(context).accent,
                soft: DeckPalette.of(context).accentSoft,
              );
        String? meta;
        if (events.isNotEmpty) {
          final latest = events.first;
          meta =
              '${humanizeAuditCode(latest.action)} · ${auditTimestampLabel(latest.occurredAt, localeName)}';
        }
        return _RowShell(
          icon: Icons.policy_outlined,
          title: strings.tKey(PlatformAdminKeys.settingsAuditTitle),
          meta: meta,
          route: '/audit-log',
          value: value,
        );
      },
    );
  }
}

class _HealthRow extends ConsumerWidget {
  const _HealthRow({required this.strings});
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeckPalette.of(context);
    final health = ref.watch(configHealthProvider);
    return health.when(
      loading: () => _RowShell(
        icon: Icons.health_and_safety_outlined,
        title: strings.tKey(PlatformAdminKeys.pageHealthTitle),
        route: '/checklist/health',
        value: const DeckSkeleton(width: 96, height: 28, radius: 999),
      ),
      error: (_, _) => _RowShell(
        icon: Icons.health_and_safety_outlined,
        title: strings.tKey(PlatformAdminKeys.pageHealthTitle),
        route: '/checklist/health',
        value: _RowRetry(
          label: strings.tKey(CommonKeys.buttonRetry),
          onRetry: () => ref.invalidate(configHealthProvider),
        ),
      ),
      data: (data) {
        final issues = data.checks.where((c) => !c.ok).length;
        final Widget value = issues == 0
            ? DeckChip(
                label: strings.tKey(CommonKeys.statusHealthy),
                color: palette.success,
                soft: palette.success.withValues(alpha: 0.12),
              )
            : DeckChip(
                label: strings.tKey(PlatformAdminKeys.buttonHealthReview),
                color: palette.warning,
                soft: palette.warning.withValues(alpha: 0.14),
              );
        String? meta;
        if (issues > 0) {
          final first = data.checks.firstWhere((c) => !c.ok);
          // No Arabic catalog in the backend: English message with a
          // humanized code fallback, never a raw code.
          meta = first.messageEn.isNotEmpty
              ? first.messageEn
              : humanizeAuditCode(first.code);
        } else if (data.checks.isNotEmpty) {
          meta =
              '${strings.tKey(PlatformAdminKeys.checklistHealthTotalChecks)}: ${data.checks.length}';
        }
        return _RowShell(
          icon: Icons.health_and_safety_outlined,
          title: strings.tKey(PlatformAdminKeys.pageHealthTitle),
          meta: meta,
          route: '/checklist/health',
          value: value,
          valueLabel: issues == 0
              ? strings.tKey(CommonKeys.statusHealthy)
              : '$issues',
        );
      },
    );
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({required this.strings, required this.trailing});

  final UiMessageStrings strings;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 14, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceTitle),
                style: DeckType.style(14, 19, FontWeight.w600, palette.ink),
              ),
              const SizedBox(height: 5),
              Text(
                strings.tKey(PlatformAdminKeys.settingsMaintenanceBody),
                style: DeckType.style(12.5, 18, FontWeight.w400, palette.muted),
              ),
            ],
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 14), trailing],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              trailing,
            ],
          );
        },
      ),
    );
  }
}

class _RowRetry extends StatelessWidget {
  const _RowRetry({required this.label, required this.onRetry});
  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onRetry,
        child: Text(
          label,
          style: DeckType.style(12, 16, FontWeight.w600, palette.accent),
        ),
      ),
    );
  }
}

/// 1px hairline in the palette border color, so dark mode keeps the ledger
/// readable.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: DeckPalette.of(context).border);
  }
}
