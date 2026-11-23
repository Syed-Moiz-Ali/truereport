import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

// Local group labels: the message catalog has no keys for these three intents.
// Flagged in the report as a local-copy addition.
const String _monitor = 'MONITOR';
const String _configure = 'CONFIGURE';

/// Region 3 — grouped navigation. One surface per intent, hairline rows with a
/// live value only where a real provider supplies one.
class SettingsJumpList extends ConsumerWidget {
  const SettingsJumpList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeckPalette.of(context);
    final strings = ref.watch(uiStringsProvider);
    final audit = ref.watch(auditEventsProvider);
    final languages = ref.watch(platformLanguagesProvider);
    final health = ref.watch(configHealthProvider);

    final monitor = <Widget>[
      DeckJumpRow(
        icon: Icons.translate_rounded,
        title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
        value: _languagesValue(strings, languages, ref, palette),
        route: '/settings/languages',
      ),
      DeckJumpRow(
        icon: Icons.policy_outlined,
        title: strings.tKey(PlatformAdminKeys.settingsAuditTitle),
        value: _auditValue(strings, audit, ref, palette),
        route: '/audit-log',
      ),
      DeckJumpRow(
        icon: Icons.health_and_safety_outlined,
        title: strings.tKey(PlatformAdminKeys.pageHealthTitle),
        value: _healthValue(strings, health, palette),
        route: '/checklist/health',
      ),
    ];

    final configure = <Widget>[
      DeckJumpRow(
        icon: Icons.rate_review_outlined,
        title: strings.tKey(PlatformAdminKeys.settingsTranslationReviewTitle),
        route: '/configuration/translations',
      ),
      DeckJumpRow(
        icon: Icons.account_tree_outlined,
        title: strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
        route: '/checklist/option-sets',
      ),
      DeckJumpRow(
        icon: Icons.swap_horiz_rounded,
        title: strings.tKey(PlatformAdminKeys.referenceTransitionsTitle),
        route: '/configuration/transitions',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeckReveal(
          delay: 90,
          child: _Group(label: _monitor, palette: palette, rows: monitor),
        ),
        const SizedBox(height: 20),
        DeckReveal(
          delay: 130,
          child: _Group(label: _configure, palette: palette, rows: configure),
        ),
      ],
    );
  }

  Widget? _languagesValue(
    UiMessageStrings strings,
    AsyncValue<List<PlatformLanguage>> languages,
    WidgetRef ref,
    DeckPalette palette,
  ) {
    return languages.when(
      loading: () => const DeckRowValueSkeleton(),
      error: (_, _) => DeckRowValueRetry(
        label: strings.tKey(CommonKeys.buttonRetry),
        onRetry: () => ref.invalidate(platformLanguagesProvider),
      ),
      data: (list) {
        if (list.isEmpty) return null;
        final live = list.where((item) => item.isLive).length;
        final setup = list.where((item) => item.isInSetup).length;
        return DeckChip(
          label: strings.tArgsKey(
            PlatformAdminKeys.sidebarLanguagesStatus,
            <String, Object?>{'live': '$live', 'setup': '$setup'},
          ),
          color: palette.accent,
          soft: palette.accentSoft,
        );
      },
    );
  }

  Widget? _auditValue(
    UiMessageStrings strings,
    AsyncValue<List<PlatformAuditEvent>> audit,
    WidgetRef ref,
    DeckPalette palette,
  ) {
    return audit.when(
      loading: () => const DeckRowValueSkeleton(),
      error: (_, _) => DeckRowValueRetry(
        label: strings.tKey(CommonKeys.buttonRetry),
        onRetry: () => ref.invalidate(auditEventsProvider),
      ),
      data: (events) {
        if (events.isEmpty) {
          return DeckChip(
            label: strings.tKey(PlatformAdminKeys.settingsAuditNoEvents),
            color: palette.faint,
            soft: palette.surface,
          );
        }
        return DeckChip(
          label: strings.tArgsKey(
            PlatformAdminKeys.settingsAuditEventsCount,
            <String, Object?>{'count': '${events.length}'},
          ),
          color: palette.accent,
          soft: palette.accentSoft,
        );
      },
    );
  }

  Widget? _healthValue(
    UiMessageStrings strings,
    AsyncValue<ConfigHealth> health,
    DeckPalette palette,
  ) {
    return health.when(
      loading: () => const DeckRowValueSkeleton(),
      error: (_, _) =>
          DeckRowValueError(label: strings.tKey(CommonKeys.stateError)),
      data: (data) {
        if (data.checks.isEmpty) return null;
        final issues = data.checks.where((check) => !check.ok).length;
        return DeckChip(
          label:
              '${strings.tKey(PlatformAdminKeys.checklistHealthIssuesFound)}: $issues',
          color: issues == 0 ? palette.success : palette.warning,
          soft: (issues == 0 ? palette.success : palette.warning).withValues(
            alpha: 0.12,
          ),
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.palette,
    required this.rows,
  });

  final String label;
  final DeckPalette palette;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeckGroupLabel(label: label),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(DeckRadius.card),
            border: Border.all(color: palette.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DeckRadius.card),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: palette.border),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DeckJumpRow extends StatelessWidget {
  const DeckJumpRow({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
    this.value,
  });

  final IconData icon;
  final String title;
  final String route;
  final Widget? value;

  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(route),
        child: Container(
          height: DeckSize.rowHeight,
          padding: const EdgeInsetsDirectional.only(start: 18, end: 14),
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
                child: Text(
                  title,
                  style: DeckType.style(13.5, 19, FontWeight.w500, palette.ink),
                  maxLines: 2,
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 10),
                value!,
                const SizedBox(width: 10),
              ],
              Transform.scale(
                scaleX: Directionality.of(context) == TextDirection.rtl
                    ? -1
                    : 1,
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
    );
  }
}

class DeckRowValueSkeleton extends StatelessWidget {
  const DeckRowValueSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const DeckSkeleton(
    width: 96,
    height: DeckSize.chipHeight,
    radius: DeckRadius.chip,
  );
}

class DeckRowValueError extends StatelessWidget {
  const DeckRowValueError({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final palette = DeckPalette.of(context);
    return Text(
      label,
      style: DeckType.style(12, 16, FontWeight.w500, palette.danger),
    );
  }
}

class DeckRowValueRetry extends StatelessWidget {
  const DeckRowValueRetry({
    super.key,
    required this.label,
    required this.onRetry,
  });
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
