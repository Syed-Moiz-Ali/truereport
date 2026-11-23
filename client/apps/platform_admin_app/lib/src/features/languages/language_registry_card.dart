import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'language_cards.dart';

/// One language card (Direction B).
///
/// Human name first, lifecycle state as words, one big coverage number with
/// a meter, and verb-first actions. Same contract as the retired row-card:
/// the host stamps `ValueKey('language-card-<code>')`, actions keep the
/// `view-<code>` / `translate-<code>` keys, registry-only rows keep their
/// awaiting-catalog copy.
class LanguageRegistryCard extends ConsumerWidget {
  const LanguageRegistryCard({
    super.key,
    required this.code,
    required this.manifestLanguage,
    required this.registryLanguage,
    required this.isDefault,
  });

  final String code;
  final UiMessageLanguage? manifestLanguage;
  final PlatformLanguage? registryLanguage;
  final bool isDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final manifest = manifestLanguage;
    final registry = registryLanguage;
    final readiness = registry == null
        ? null
        : ref.watch(readinessProvider(code)).asData?.value;
    final displayName = registry?.displayName ?? manifest?.displayName ?? code;

    double? fraction;
    String? fractionLabel;
    int? missing;
    if (manifest != null && manifest.totalKeys > 0) {
      final approved = manifest.totalKeys - manifest.missingKeys;
      fraction = approved / manifest.totalKeys;
      fractionLabel = strings.tKey(
        PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage,
      );
      missing = manifest.missingKeys;
    } else if (readiness != null && readiness.contentTotal > 0) {
      fraction = readiness.contentApproved / readiness.contentTotal;
      fractionLabel = strings.tKey(
        PlatformAdminKeys.languageWorkspaceFieldContentCoverage,
      );
      final rest = readiness.contentTotal - readiness.contentApproved;
      missing = rest < 0 ? 0 : rest;
    }

    final Widget stateChip;
    if (registry != null) {
      final live = registry.status == 'LIVE';
      stateChip = LanguageStateChip(
        label: strings.tKey(languageStatusKey(registry.status)),
        warn: !live,
      );
    } else if (manifest != null) {
      final live =
          manifest.missingKeys == 0 && manifest.placeholderMismatch == 0;
      stateChip = LanguageStateChip(
        label: strings.tKey(
          live
              ? PlatformAdminKeys.statusLanguageLive
              : PlatformAdminKeys.statusLanguageReview,
        ),
        warn: !live,
      );
    } else {
      stateChip = const SizedBox.shrink();
    }

    return LanguageCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        19,
                        lineHeight: 25,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w600,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              stateChip,
            ],
          ),
          if (manifest != null && fraction != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '${(fraction * 100).round()}%',
              style: PtTheme.font(
                40,
                lineHeight: 42,
                weight: FontWeight.w800,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 2),
            Text(
              fractionLabel!,
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w400,
                color: PtTheme.muted,
              ),
            ),
            const SizedBox(height: 8),
            LanguageCoverageMeter(value: fraction),
            if ((missing ?? 0) > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                strings.tArgsKey(
                  PlatformAdminKeys.pageLanguagesCardMissingCount,
                  <String, Object?>{'count': '$missing'},
                ),
                style: PtTheme.font(
                  12.5,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.gold,
                ),
              ),
            ],
          ],
          if (manifest == null && registry != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              strings.tKey(PlatformAdminKeys.languagesRegistryNoCatalog),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ],
          if (registry != null && !isDefault) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                PlatformPrimaryButton(
                  key: ValueKey('view-$code'),
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceButtonManage,
                  ),
                  icon: Icons.tune_rounded,
                  onPressed: () => context.go('/settings/languages/$code'),
                ),
                PlatformSecondaryButton(
                  key: ValueKey('translate-$code'),
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationQueueTitle,
                  ),
                  icon: Icons.translate_rounded,
                  onPressed: () =>
                      context.go('/settings/languages/$code/translations'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
