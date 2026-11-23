import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../platform_providers.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Region 2 — the single focal point. Live configuration health, derived only
/// from [configHealthProvider]; loading, error and empty are all designed.
class SettingsPulse extends ConsumerWidget {
  const SettingsPulse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DeckPalette.of(context);
    final strings = ref.watch(uiStringsProvider);
    final health = ref.watch(configHealthProvider);

    return DeckReveal(
      delay: 40,
      child: DeckPulseSurface(
        palette: palette,
        child: health.when(
          loading: () => DeckPulseSkeleton(palette: palette),
          error: (_, _) => DeckPulseError(
            palette: palette,
            message: strings.tKey(CommonKeys.stateError),
            retryLabel: strings.tKey(CommonKeys.buttonRetry),
            onRetry: () => ref.invalidate(configHealthProvider),
          ),
          data: (data) {
            if (data.checks.isEmpty) {
              return DeckPulseEmpty(
                palette: palette,
                title: 'No configuration checks reported yet.',
              );
            }
            final issues = data.checks.where((check) => !check.ok).length;
            final ok = data.checks.length - issues;
            final warning = data.checks
                .where((check) => check.severity == 'WARNING')
                .length;
            final errors = issues - warning;
            return DeckPulseData(
              palette: palette,
              strings: strings,
              issues: issues,
              total: data.checks.length,
              ok: ok,
              warning: warning,
              errors: errors,
              onReview: () => context.go('/checklist/health'),
            );
          },
        ),
      ),
    );
  }
}

class DeckPulseSurface extends StatelessWidget {
  const DeckPulseSurface({
    super.key,
    required this.palette,
    required this.child,
  });

  final DeckPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.hero,
        borderRadius: BorderRadius.circular(DeckRadius.hero),
      ),
      child: child,
    );
  }
}

class DeckPulseData extends StatelessWidget {
  const DeckPulseData({
    super.key,
    required this.palette,
    required this.strings,
    required this.issues,
    required this.total,
    required this.ok,
    required this.warning,
    required this.errors,
    required this.onReview,
  });

  final DeckPalette palette;
  final UiMessageStrings strings;
  final int issues;
  final int total;
  final int ok;
  final int warning;
  final int errors;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final segments = <(int, Color)>[
      (ok, palette.heroAccent),
      (warning, palette.warning),
      (errors, palette.danger),
    ].where((entry) => entry.$1 > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.tKey(PlatformAdminKeys.sidebarSystemOperational),
                style: DeckType.style(
                  11,
                  14,
                  FontWeight.w700,
                  palette.heroAccent,
                  tracking: 1.3,
                ),
              ),
            ),
            DeckChip(
              label: strings.tKey(
                issues == 0
                    ? CommonKeys.statusHealthy
                    : CommonKeys.statusUnhealthy,
              ),
              color: issues == 0 ? palette.heroAccent : palette.danger,
              soft: palette.heroInk.withValues(alpha: 0.08),
              onHero: true,
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          '$issues',
          style: DeckType.style(
            DeckSize.heroNumber,
            64,
            FontWeight.w700,
            palette.heroInk,
            tracking: -3,
            tabular: true,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          strings.tKey(PlatformAdminKeys.checklistHealthIssuesFound),
          style: DeckType.style(14, 19, FontWeight.w500, palette.heroMuted),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (var i = 0; i < segments.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    flex: segments[i].$1,
                    child: Container(color: segments[i].$2),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${strings.tKey(PlatformAdminKeys.checklistHealthTotalChecks)}: $total',
          style: DeckType.style(12, 17, FontWeight.w400, palette.heroMuted),
        ),
        const SizedBox(height: 22),
        DeckButton(
          label: strings.tKey(PlatformAdminKeys.buttonHealthReview),
          icon: Icons.fact_check_outlined,
          primary: false,
          onHero: true,
          onPressed: onReview,
        ),
      ],
    );
  }
}

class DeckPulseSkeleton extends StatelessWidget {
  const DeckPulseSkeleton({super.key, required this.palette});
  final DeckPalette palette;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeckSkeleton(width: 150, height: 14, radius: 7),
        SizedBox(height: 26),
        DeckSkeleton(width: 120, height: 64, radius: 10),
        SizedBox(height: 10),
        DeckSkeleton(width: 110, height: 16, radius: 7),
        SizedBox(height: 24),
        DeckSkeleton(width: double.infinity, height: 8, radius: 999),
        SizedBox(height: 16),
        DeckSkeleton(width: 140, height: 14, radius: 7),
        SizedBox(height: 22),
        DeckSkeleton(
          width: 160,
          height: DeckSize.buttonHeight,
          radius: DeckRadius.button,
        ),
      ],
    );
  }
}

class DeckPulseError extends StatelessWidget {
  const DeckPulseError({
    super.key,
    required this.palette,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final DeckPalette palette;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: DeckType.style(16, 22, FontWeight.w600, palette.heroInk),
        ),
        const SizedBox(height: 22),
        DeckButton(
          label: retryLabel,
          icon: Icons.refresh_rounded,
          primary: false,
          onHero: true,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class DeckPulseEmpty extends StatelessWidget {
  const DeckPulseEmpty({super.key, required this.palette, required this.title});
  final DeckPalette palette;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DeckType.style(18, 25, FontWeight.w600, palette.heroInk),
        ),
      ],
    );
  }
}
