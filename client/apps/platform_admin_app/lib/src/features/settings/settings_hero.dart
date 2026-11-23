import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_providers.dart';
import 'settings_primitives.dart';
import 'settings_tokens.dart';

/// Region 1 — the count, nothing else (Direction A "Identity Hero").
///
/// The cover band already names the person and the page; the hero answers
/// the only remaining question: how many checks need attention. One giant
/// tabular number, one meta line. Loading renders the number's own skeleton;
/// error keeps a Retry. No buttons here — Review lives on the health row.
class SettingsHero extends ConsumerWidget {
  const SettingsHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final health = ref.watch(configHealthProvider);
    final compact = MediaQuery.sizeOf(context).width < 640;

    return DeckReveal(
      delay: 40,
      child: health.when(
        loading: () => const _HeroSkeleton(),
        error: (_, _) => _HeroError(
          message: strings.tKey(CommonKeys.stateError),
          retryLabel: strings.tKey(CommonKeys.buttonRetry),
          onRetry: () => ref.invalidate(configHealthProvider),
        ),
        data: (checks) {
          final total = checks.checks.length;
          final issues = checks.checks.where((c) => !c.ok).length;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$issues',
                style: DeckType.style(
                  compact ? 64 : 72,
                  compact ? 66 : 72,
                  FontWeight.w700,
                  DeckPalette.of(context).ink,
                  tracking: -3,
                  tabular: true,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 10,
                  bottom: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.tKey(
                        PlatformAdminKeys.checklistHealthIssuesFound,
                      ),
                      style: DeckType.style(
                        14,
                        19,
                        FontWeight.w700,
                        DeckPalette.of(context).ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${strings.tKey(PlatformAdminKeys.checklistHealthTotalChecks)}: $total',
                      style: DeckType.style(
                        12,
                        16,
                        FontWeight.w400,
                        DeckPalette.of(context).muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeckSkeleton(width: 96, height: 72, radius: 10),
        SizedBox(height: 12),
        DeckSkeleton(width: 180, height: 16, radius: 7),
      ],
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

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
          style: DeckType.style(
            16,
            22,
            FontWeight.w600,
            DeckPalette.of(context).ink,
          ),
        ),
        const SizedBox(height: 14),
        DeckButton(
          label: retryLabel,
          icon: Icons.refresh_rounded,
          primary: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
