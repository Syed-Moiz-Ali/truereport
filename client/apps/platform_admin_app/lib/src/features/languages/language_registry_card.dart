import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../localization/translation_review_models.dart';
import '../localization/translation_review_providers.dart';
import 'language_cards.dart';
import 'language_failures.dart';

/// One language card (Direction B).
///
/// Human name first, lifecycle state as words, one big coverage number with
/// a meter, and verb-first actions. Same contract as the retired row-card:
/// the host stamps `ValueKey('language-card-<code>')`, actions keep the
/// `view-<code>` / `translate-<code>` keys, registry-only rows keep their
/// awaiting-catalog copy.
class _CoverageLine extends StatelessWidget {
  const _CoverageLine({
    required this.strings,
    required this.label,
    required this.translated,
    required this.total,
    required this.missing,
  });

  final UiMessageStrings strings;
  final String label;
  final int translated;
  final int total;
  final int missing;

  @override
  Widget build(BuildContext context) {
    final counts = total > 0
        ? strings.tArgsKey(
            PlatformAdminKeys.pageLanguagesCardCount,
            <String, Object?>{'translated': translated, 'total': total},
          )
        : strings.tArgsKey(
            PlatformAdminKeys.pageLanguagesCardCountOnly,
            <String, Object?>{'translated': translated},
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PtTheme.font(
                  11.5,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              counts,
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ratio = total > 0
                    ? (translated / total).clamp(0.0, 1.0)
                    : 0.0;
                // A 99.7% bar looks identical to a full one, so the gap always
                // keeps at least 4px: "almost done" must still read as "not done".
                final gap = missing > 0
                    ? (constraints.maxWidth * (1 - ratio)).clamp(
                        4.0,
                        constraints.maxWidth,
                      )
                    : 0.0;
                return Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: PtTheme.border),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      right: gap,
                      child: const ColoredBox(color: PtTheme.deepGreen),
                    ),
                    if (gap > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: gap,
                        child: const ColoredBox(color: PtTheme.gold),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // Always rendered (empty when nothing is missing) so cards in a row
        // keep the same height and their buttons line up.
        const SizedBox(height: 4),
        Text(
          missing > 0
              ? strings.tArgsKey(
                  PlatformAdminKeys.pageLanguagesCardMissingInline,
                  <String, Object?>{'count': missing},
                )
              : '',
          style: PtTheme.font(
            11,
            lineHeight: 15,
            weight: FontWeight.w700,
            color: PtTheme.gold,
          ),
        ),
      ],
    );
  }
}

/// Namespace -> display key. A const map keeps this a lookup, not a status map.
const Map<String, UiMessageKey> _appLabelKeys = <String, UiMessageKey>{
  'common': PlatformAdminKeys.pageLanguagesAppCommon,
  'platform_admin': PlatformAdminKeys.pageLanguagesAppPlatformAdmin,
  'workshop_admin': PlatformAdminKeys.pageLanguagesAppWorkshopAdmin,
  'technician': PlatformAdminKeys.pageLanguagesAppTechnician,
};

class _AppCoverageRow extends StatelessWidget {
  const _AppCoverageRow({required this.strings, required this.row});

  final UiMessageStrings strings;
  final AppCoverageRow row;

  @override
  Widget build(BuildContext context) {
    final labelKey = _appLabelKeys[row.app];
    final label = labelKey == null ? row.app : strings.tKey(labelKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: PtTheme.font(
                    12.5,
                    lineHeight: 17,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
              ),
              Text(
                strings.tArgsKey(
                  PlatformAdminKeys.pageLanguagesAppsCount,
                  <String, Object?>{
                    'translated': row.translated,
                    'total': row.total,
                  },
                ),
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                  color: row.missing > 0 ? PtTheme.gold : PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final ratio = row.total > 0
                      ? (row.translated / row.total).clamp(0.0, 1.0)
                      : 0.0;
                  final gap = row.missing > 0
                      ? (constraints.maxWidth * (1 - ratio)).clamp(
                          4.0,
                          constraints.maxWidth,
                        )
                      : 0.0;
                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: PtTheme.border),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: gap,
                        child: const ColoredBox(color: PtTheme.deepGreen),
                      ),
                      if (gap > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: gap,
                          child: const ColoredBox(color: PtTheme.gold),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (!row.catalog) ...[
            const SizedBox(height: 4),
            Text(
              strings.tKey(PlatformAdminKeys.pageLanguagesAppsNoCatalog),
              style: PtTheme.font(11, lineHeight: 15, color: PtTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

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
    final contentSummary = registry == null
        ? null
        : ref
              .watch(
                translationReviewSummaryProvider((
                  lang: code,
                  entityType: contentScopeType,
                )),
              )
              .asData
              ?.value;
    final uiSummary = registry == null
        ? null
        : ref
              .watch(
                translationReviewSummaryProvider((
                  lang: code,
                  entityType: interfaceTextScopeType,
                )),
              )
              .asData
              ?.value;
    final displayName = registry?.displayName ?? manifest?.displayName ?? code;

    final contentTranslated = contentSummary?.covered ?? 0;
    final contentTargets = contentSummary?.targets ?? 0;
    final uiTranslated = uiSummary?.covered ?? 0;
    final uiTargets = uiSummary?.targets ?? 0;
    final contentMissing = contentSummary?.missing ?? 0;
    final uiMissing = uiSummary?.missing ?? 0;
    final missingTotal = contentMissing + uiMissing;
    final hasCoverage =
        contentTranslated > 0 ||
        uiTranslated > 0 ||
        contentTargets > 0 ||
        uiTargets > 0;

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
          if (!isDefault && registry != null && hasCoverage) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              missingTotal > 0 ? '$missingTotal' : '100%',
              style: PtTheme.font(
                40,
                lineHeight: 42,
                weight: FontWeight.w800,
                color: missingTotal > 0 ? PtTheme.ink : PtTheme.deepGreen,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 2),
            Text(
              strings.tKey(
                missingTotal > 0
                    ? PlatformAdminKeys.pageLanguagesCardToTranslate
                    : PlatformAdminKeys.pageLanguagesCardTranslated,
              ),
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w400,
                color: PtTheme.muted,
              ),
            ),
            const SizedBox(height: 12),
            _CoverageLine(
              strings: strings,
              label: strings.tKey(PlatformAdminKeys.pageLanguagesCardContent),
              translated: contentTranslated,
              total: contentTargets,
              missing: contentMissing,
            ),
            const SizedBox(height: 10),
            _CoverageLine(
              strings: strings,
              label: strings.tKey(
                PlatformAdminKeys.pageLanguagesCardInterfaceText,
              ),
              translated: uiTranslated,
              total: uiTargets,
              missing: uiMissing,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                key: ValueKey('language-apps-$code'),
                onTap: () => _showAppCoverage(context, ref, strings),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 8, 2),
                  child: Text(
                    strings.tKey(PlatformAdminKeys.pageLanguagesAppsOpen),
                    style: PtTheme.font(
                      11.5,
                      lineHeight: 16,
                      weight: FontWeight.w700,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (manifest?.hasCatalog != true && registry != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              strings.tKey(PlatformAdminKeys.languagesRegistryNoCatalog),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ],
          if (registry != null && isDefault) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              strings.tKey(PlatformAdminKeys.languagesSourceLanguage),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ],
          if (!hasCoverage && registry != null && !isDefault) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              strings.tKey(PlatformAdminKeys.languagesCardNoContent),
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
                  key: ValueKey('review-$code'),
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewTitle,
                  ),
                  icon: Icons.rate_review_outlined,
                  onPressed: () => context.go(
                    uiMissing > 0
                        ? '/configuration/translations?lang=$code&scope=ui'
                        : '/configuration/translations?lang=$code',
                  ),
                ),
                PlatformSecondaryButton(
                  key: ValueKey('retire-$code'),
                  label: strings.tKey(PlatformAdminKeys.languagesRetireAction),
                  icon: Icons.archive_outlined,
                  destructive: true,
                  onPressed: () => _retire(context, ref, strings),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAppCoverage(
    BuildContext context,
    WidgetRef ref,
    UiMessageStrings strings,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => PlatformDialogShell(
        title: strings.tKey(PlatformAdminKeys.pageLanguagesAppsTitle),
        body: SizedBox(
          width: 460,
          height: 300,
          child: Consumer(
            builder: (context, ref, _) => ref
                .watch(appCoverageProvider(code))
                .when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      strings.tKey(CommonKeys.stateError),
                      style: PtTheme.bodyMuted,
                    ),
                  ),
                  data: (rows) => ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _AppCoverageRow(strings: strings, row: rows[index]),
                  ),
                ),
          ),
        ),
        actions: [
          PlatformGhostButton(
            key: const Key('language-apps-close'),
            label: strings.tKey(CommonKeys.buttonClose),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _retire(
    BuildContext context,
    WidgetRef ref,
    UiMessageStrings strings,
  ) async {
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(PlatformAdminKeys.languagesRetireTitle),
      body: strings.tKey(PlatformAdminKeys.languagesRetireBody),
      confirmLabel: strings.tKey(PlatformAdminKeys.languagesRetireConfirm),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(platformConfigActionsProvider).retireLanguage(code);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: PtTheme.rose,
            content: Text(languageRetireErrorText(strings, error)),
          ),
        );
    }
  }
}
