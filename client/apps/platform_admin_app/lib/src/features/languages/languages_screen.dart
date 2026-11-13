import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../platform_translations.dart' hide TranslationCoverage;

class LanguagesScreen extends ConsumerWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final languages = ref.watch(platformLanguagesProvider);
    final coverage = ref.watch(translationCoverageProvider);

    return PlatformShell(
      currentRoute: '/settings/languages',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageSettingsTitle),
            onTap: () => context.go('/settings'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
          ),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
              subtitle: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
              actions: [
                PlatformPrimaryButton(
                  label: strings.tKey(PlatformAdminKeys.buttonLanguageAdd),
                  icon: Icons.add_rounded,
                  onPressed: () => _edit(context, null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lifecycle helper: new languages start as DRAFT and stay hidden
            // from Workshop/Technician/public until published to LIVE.
            // Steps use existing localized labels; no language is hardcoded.
            PlatformSectionCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: PtTheme.canvas,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.translate_rounded,
                        color: PtTheme.deepGreen,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(
                            14,
                            weight: FontWeight.w700,
                            color: PtTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              strings.tKey(PlatformAdminKeys.buttonLanguageAdd),
                              style: PtTheme.font(
                                12,
                                weight: FontWeight.w700,
                                color: PtTheme.ink,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: PtTheme.muted,
                            ),
                            Text(
                              strings.tKey(
                                PlatformAdminKeys
                                    .buttonLanguageCompleteTranslations,
                              ),
                              style: PtTheme.font(
                                12,
                                weight: FontWeight.w700,
                                color: PtTheme.ink,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: PtTheme.muted,
                            ),
                            Text(
                              '${strings.tKey(PlatformAdminKeys.buttonLanguagePublish)} (${strings.tKey(PlatformAdminKeys.statusLanguageLive)})',
                              style: PtTheme.font(
                                12,
                                weight: FontWeight.w700,
                                color: PtTheme.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${strings.tKey(PlatformAdminKeys.statusLanguageDraft)} · ${strings.tKey(PlatformAdminKeys.statusLanguageTranslating)} · ${strings.tKey(PlatformAdminKeys.statusLanguageReview)} · ${strings.tKey(PlatformAdminKeys.statusLanguageLive)} · ${strings.tKey(PlatformAdminKeys.statusLanguageRetired)}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: PtTheme.font(12, color: PtTheme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            languages.when(
              loading: () => const PlatformLoadingView(),
              error: (error, stackTrace) => PlatformErrorView(
                message: strings.tKey(CommonKeys.statusUnhealthy),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: () => ref.invalidate(platformLanguagesProvider),
              ),
              data: (items) => items.isEmpty
                  ? PlatformEmptyView(
                      icon: Icons.translate_rounded,
                      title: strings.tKey(CommonKeys.emptyTitle),
                      actionLabel: strings.tKey(
                        PlatformAdminKeys.buttonLanguageAdd,
                      ),
                      onAction: () => _edit(context, null),
                    )
                  : _LanguagesContent(
                      items: items,
                      onEdit: (item) => _edit(context, item),
                      onCompleteTranslations: (item) => context.go(
                        '/settings/languages/${item.code}/translations',
                      ),
                      onToggleActive: (item) =>
                          _toggleActive(context, ref, item),
                      onSetDefault: (item) => _setDefault(context, ref, item),
                      onReorder: (items, index, delta) =>
                          _reorder(context, ref, items, index, delta),
                    ),
            ),
            const SizedBox(height: 20),
            _CoverageSection(
              coverage: coverage,
              onRetry: () => ref.invalidate(translationCoverageProvider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, PlatformLanguage? initial) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: _LanguageDialog(initial: initial),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ProviderScope.containerOf(context)
                .read(uiStringsProvider)
                .tKey(CommonKeys.buttonSave),
          ),
          backgroundColor: PtTheme.deepGreen,
        ),
      );
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    try {
      final api = ref.read(platformConfigApiProvider);
      if (language.active) {
        await api.deactivateLanguage(language.code);
      } else {
        await api.activateLanguage(language.code);
      }
      if (!context.mounted) return;
      ref.invalidate(platformLanguagesProvider);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric),
          ),
        ),
      );
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    try {
      await ref
          .read(platformConfigActionsProvider)
          .setDefaultLanguage(language.code);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric),
          ),
        ),
      );
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<PlatformLanguage> items,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= items.length) return;
    final codes = items.map((item) => item.code).toList();
    final moved = codes.removeAt(index);
    codes.insert(target, moved);
    try {
      await ref.read(platformConfigActionsProvider).reorderLanguages(codes);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric),
          ),
        ),
      );
    }
  }
}

/// Summary card for the Settings landing (`/settings`).
///
/// Shows the language count, active count, default language and translation
/// coverage state plus a single action that opens the full
/// [LanguagesScreen] (`/settings/languages`). Compact, stacked and
/// wrap-safe; directional padding comes from the shared section card.
class LanguagesCoverageSummaryCard extends ConsumerWidget {
  const LanguagesCoverageSummaryCard({super.key, this.onOpen});

  /// Overrides the default navigation to `/settings/languages`.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final languages = ref.watch(platformLanguagesProvider);
    final coverage = ref.watch(translationCoverageProvider);

    void open() {
      if (onOpen != null) {
        onOpen!();
        return;
      }
      try {
        GoRouter.of(context).go('/settings/languages');
      } catch (_) {
        // No router in scope (e.g. isolated widget test): stay put.
      }
    }

    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
            subtitle: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
          ),
          const SizedBox(height: 12),
          languages.when(
            loading: () => const PlatformLoadingView(),
            error: (error, stackTrace) => PlatformErrorView(
              message: strings.tKey(CommonKeys.statusUnhealthy),
              retryLabel: strings.tKey(CommonKeys.buttonRetry),
              onRetry: () => ref.invalidate(platformLanguagesProvider),
            ),
            data: (items) {
              PlatformLanguage? fallback;
              for (final language in items) {
                if (language.isDefault) {
                  fallback = language;
                  break;
                }
              }
              fallback ??= items.isEmpty ? null : items.first;
              final activeCount = items.where((e) => e.active).length;
              return coverage.when(
                loading: () => const PlatformLoadingView(),
                error: (error, stackTrace) => PlatformErrorView(
                  message: strings.tKey(CommonKeys.statusUnhealthy),
                  retryLabel: strings.tKey(CommonKeys.buttonRetry),
                  onRetry: () => ref.invalidate(translationCoverageProvider),
                ),
                data: (data) {
                  var missing = 0;
                  for (final namespace in data.namespaces.values) {
                    missing += namespace.missing.length;
                  }
                  final healthy = missing == 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          PlatformMetaPill(
                            label: strings.tKey(
                              PlatformAdminKeys.pageLanguagesTitle,
                            ),
                            value: '${items.length}',
                          ),
                          PlatformMetaPill(
                            label: strings.tKey(CommonKeys.statusActive),
                            value: '$activeCount',
                          ),
                          if (fallback != null)
                            PlatformStatusChip(
                              status:
                                  '${strings.tKey(PlatformAdminKeys.pageLanguagesDefaultLanguage)}: ${fallback.code}',
                            ),
                          PlatformStatusChip(
                            status: healthy
                                ? strings.tKey(CommonKeys.statusHealthy)
                                : strings.tKey(CommonKeys.statusUnhealthy),
                          ),
                          if (missing > 0)
                            PlatformMetaPill(
                              label: strings.tKey(
                                PlatformAdminKeys
                                    .pageLanguagesMissingTranslations,
                              ),
                              value: '$missing',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PlatformSecondaryButton(
                            label: strings.tKey(
                              PlatformAdminKeys.pageLanguagesTitle,
                            ),
                            icon: Icons.translate_rounded,
                            onPressed: open,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

String _activeLabel(UiMessageStrings strings, bool active) => active
    ? strings.tKey(CommonKeys.statusActive)
    : strings.tKey(CommonKeys.statusRetired);

/// Per-language translation progress from the queue coverage endpoint.
///
/// Renders approved/total plus a missing count using existing localized
/// labels. Loading or backend errors collapse to nothing so the list still
/// renders while coverage loads.
class _LanguageCoveragePill extends ConsumerWidget {
  const _LanguageCoveragePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final coverage = ref.watch(languageCoverageProvider(code));
    return coverage.maybeWhen(
      data: (data) {
        final missing = data.totalRequired - data.approvedCount;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformMetaPill(
              label: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
              value: '${data.approvedCount}/${data.totalRequired}',
            ),
            if (missing > 0) ...[
              const SizedBox(width: 8),
              PlatformMetaPill(
                label: strings.tKey(
                  PlatformAdminKeys.pageLanguagesMissingTranslations,
                ),
                value: '$missing',
              ),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Maps a language lifecycle status (DRAFT → TRANSLATING → REVIEW → LIVE →
/// RETIRED) to its localized label. Unknown values fall back to the raw
/// status so future backend states still render.
String _languageStatusLabel(UiMessageStrings strings, String status) {
  switch (status.toUpperCase()) {
    case 'DRAFT':
      return strings.tKey(PlatformAdminKeys.statusLanguageDraft);
    case 'TRANSLATING':
      return strings.tKey(PlatformAdminKeys.statusLanguageTranslating);
    case 'REVIEW':
      return strings.tKey(PlatformAdminKeys.statusLanguageReview);
    case 'LIVE':
      return strings.tKey(PlatformAdminKeys.statusLanguageLive);
    case 'RETIRED':
      return strings.tKey(PlatformAdminKeys.statusLanguageRetired);
    default:
      return status.isEmpty
          ? strings.tKey(PlatformAdminKeys.statusLanguageDraft)
          : status;
  }
}

class _LanguagesContent extends StatelessWidget {
  const _LanguagesContent({
    required this.items,
    required this.onEdit,
    required this.onCompleteTranslations,
    required this.onToggleActive,
    required this.onSetDefault,
    required this.onReorder,
  });

  final List<PlatformLanguage> items;
  final ValueChanged<PlatformLanguage> onEdit;
  final ValueChanged<PlatformLanguage> onCompleteTranslations;
  final ValueChanged<PlatformLanguage> onToggleActive;
  final ValueChanged<PlatformLanguage> onSetDefault;
  final void Function(List<PlatformLanguage> items, int index, int delta)
  onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          return _LanguagesTable(
            items: items,
            onEdit: onEdit,
            onCompleteTranslations: onCompleteTranslations,
            onToggleActive: onToggleActive,
            onSetDefault: onSetDefault,
            onReorder: onReorder,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _LanguageCard(
                language: items[index],
                onEdit: () => onEdit(items[index]),
                onCompleteTranslations: () =>
                    onCompleteTranslations(items[index]),
                onToggleActive: () => onToggleActive(items[index]),
                onSetDefault: () => onSetDefault(items[index]),
                onMoveUp: index == 0 ? null : () => onReorder(items, index, -1),
                onMoveDown: index == items.length - 1
                    ? null
                    : () => onReorder(items, index, 1),
              ),
              if (index != items.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _LanguagesTable extends StatelessWidget {
  const _LanguagesTable({
    required this.items,
    required this.onEdit,
    required this.onCompleteTranslations,
    required this.onToggleActive,
    required this.onSetDefault,
    required this.onReorder,
  });

  final List<PlatformLanguage> items;
  final ValueChanged<PlatformLanguage> onEdit;
  final ValueChanged<PlatformLanguage> onCompleteTranslations;
  final ValueChanged<PlatformLanguage> onToggleActive;
  final ValueChanged<PlatformLanguage> onSetDefault;
  final void Function(List<PlatformLanguage> items, int index, int delta)
  onReorder;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return PlatformSectionCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Text(strings.tKey(PlatformAdminKeys.fieldLanguageCode)),
            ),
            DataColumn(
              label: Text(strings.tKey(PlatformAdminKeys.fieldItemLabelEn)),
            ),
            DataColumn(
              label: Text(strings.tKey(PlatformAdminKeys.fieldItemLabelAr)),
            ),
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.fieldLanguageNativeName),
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.fieldLanguageDirection),
              ),
            ),
            DataColumn(label: Text(strings.tKey(CommonKeys.tableStatus))),
            DataColumn(label: Text(strings.tKey(CommonKeys.statusActive))),
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.pageLanguagesDefaultLanguage),
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(label: Text(strings.tKey(CommonKeys.tableActions))),
          ],
          rows: [
            for (final language in items)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      language.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      language.nameEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      language.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      language.nativeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      language.direction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    PlatformStatusChip(
                      status: _languageStatusLabel(strings, language.status),
                    ),
                  ),
                  DataCell(
                    PlatformStatusChip(
                      status: _activeLabel(strings, language.active),
                    ),
                  ),
                  DataCell(
                    language.isDefault
                        ? PlatformStatusChip(
                            status: strings.tKey(
                              PlatformAdminKeys.pageLanguagesDefaultLanguage,
                            ),
                          )
                        : const Text('-'),
                  ),
                  DataCell(_LanguageCoveragePill(code: language.code)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: strings.tKey(CommonKeys.buttonReorder),
                          visualDensity: VisualDensity.compact,
                          onPressed: items.indexOf(language) == 0
                              ? null
                              : () => onReorder(
                                  items,
                                  items.indexOf(language),
                                  -1,
                                ),
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.tKey(CommonKeys.buttonReorder),
                          visualDensity: VisualDensity.compact,
                          onPressed: items.indexOf(language) == items.length - 1
                              ? null
                              : () => onReorder(
                                  items,
                                  items.indexOf(language),
                                  1,
                                ),
                          icon: const Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.tKey(CommonKeys.buttonEdit),
                          onPressed: () => onEdit(language),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: strings.tKey(
                            PlatformAdminKeys
                                .buttonLanguageCompleteTranslations,
                          ),
                          onPressed: () => onCompleteTranslations(language),
                          icon: const Icon(Icons.translate_rounded, size: 18),
                        ),
                        IconButton(
                          tooltip: language.active
                              ? strings.tKey(CommonKeys.statusRetired)
                              : strings.tKey(CommonKeys.statusActive),
                          onPressed: () => onToggleActive(language),
                          icon: Icon(
                            language.active
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            size: 22,
                            color: language.active
                                ? PtTheme.emerald
                                : PtTheme.muted,
                          ),
                        ),
                        if (!language.isDefault)
                          PlatformSecondaryButton(
                            label: strings.tKey(
                              PlatformAdminKeys.pageLanguagesDefaultLanguage,
                            ),
                            onPressed: () => onSetDefault(language),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.onEdit,
    required this.onCompleteTranslations,
    required this.onToggleActive,
    required this.onSetDefault,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final PlatformLanguage language;
  final VoidCallback onEdit;
  final VoidCallback onCompleteTranslations;
  final VoidCallback onToggleActive;
  final VoidCallback onSetDefault;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldLanguageCode),
                value: language.code,
              ),
              PlatformStatusChip(
                status: _languageStatusLabel(strings, language.status),
              ),
              PlatformStatusChip(
                status: _activeLabel(strings, language.active),
              ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldLanguageDirection),
                value: language.direction,
              ),
              if (language.isDefault)
                PlatformStatusChip(
                  status: strings.tKey(
                    PlatformAdminKeys.pageLanguagesDefaultLanguage,
                  ),
                ),
              _LanguageCoveragePill(code: language.code),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            language.nameEn,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          if (language.nameAr.isNotEmpty)
            Text(
              language.nameAr,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          if (language.nativeName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${strings.tKey(PlatformAdminKeys.fieldLanguageNativeName)}: ${language.nativeName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonReorder),
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonReorder),
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              ),
              PlatformSecondaryButton(
                label: strings.tKey(CommonKeys.buttonEdit),
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.buttonLanguageCompleteTranslations,
                ),
                icon: Icons.translate_rounded,
                onPressed: onCompleteTranslations,
              ),
              PlatformSecondaryButton(
                label: language.active
                    ? strings.tKey(CommonKeys.statusRetired)
                    : strings.tKey(CommonKeys.statusActive),
                icon: language.active
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                onPressed: onToggleActive,
              ),
              if (!language.isDefault)
                PlatformSecondaryButton(
                  label: strings.tKey(
                    PlatformAdminKeys.pageLanguagesDefaultLanguage,
                  ),
                  icon: Icons.star_outline_rounded,
                  onPressed: onSetDefault,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverageSection extends StatelessWidget {
  const _CoverageSection({required this.coverage, required this.onRetry});

  final AsyncValue<TranslationCoverage> coverage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return PlatformSectionCard(
      child: coverage.when(
        loading: () => const PlatformLoadingView(),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformSectionHeader(
              title: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
            ),
            const SizedBox(height: 12),
            PlatformSecondaryButton(
              label: strings.tKey(CommonKeys.buttonRetry),
              onPressed: onRetry,
            ),
          ],
        ),
        data: (data) {
          final namespaces = data.namespaces.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformSectionHeader(
                title: strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in data.languages)
                    PlatformStatusChip(status: language),
                ],
              ),
              const SizedBox(height: 16),
              if (namespaces.isEmpty)
                Text(
                  strings.tKey(CommonKeys.emptyTitle),
                  style: PtTheme.font(13, color: PtTheme.muted),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 720) {
                      return _CoverageTable(namespaces: namespaces);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in namespaces) ...[
                          _CoverageCard(entry: entry),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CoverageTable extends StatelessWidget {
  const _CoverageTable({required this.namespaces});

  final List<MapEntry<String, CoverageNamespace>> namespaces;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PtTheme.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    strings.tKey(PlatformAdminKeys.pageLanguagesCoverage),
                  ),
                ),
                DataColumn(
                  label: Text(strings.tKey(PlatformAdminKeys.queueTotal)),
                ),
                DataColumn(
                  label: Text(
                    strings.tKey(
                      PlatformAdminKeys.pageLanguagesMissingTranslations,
                    ),
                  ),
                ),
              ],
              rows: [
                for (final entry in namespaces)
                  DataRow(
                    cells: [
                      DataCell(Text(entry.key)),
                      DataCell(Text('${entry.value.total}')),
                      DataCell(Text('${entry.value.missing.length}')),
                    ],
                  ),
              ],
            ),
          ),
        ),
        for (final entry in namespaces)
          if (entry.value.missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.key,
              style: PtTheme.font(
                13,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reference in entry.value.missing)
                  PlatformStatusChip(status: reference),
              ],
            ),
          ],
      ],
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.entry});

  final MapEntry<String, CoverageNamespace> entry;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.key,
            style: PtTheme.font(
              14,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${strings.tKey(PlatformAdminKeys.queueTotal)}: ${entry.value.total} · '
            '${strings.tKey(PlatformAdminKeys.pageLanguagesMissingTranslations)}: ${entry.value.missing.length}',
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
          if (entry.value.missing.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              strings.tKey(CommonKeys.emptyTitle),
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reference in entry.value.missing)
                  PlatformStatusChip(status: reference),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageDialog extends ConsumerStatefulWidget {
  const _LanguageDialog({this.initial});

  final PlatformLanguage? initial;

  @override
  ConsumerState<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends ConsumerState<_LanguageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _nativeNameController;
  late final TextEditingController _sortOrderController;
  late String _direction;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _codeController = TextEditingController(text: initial?.code ?? '');
    _nameEnController = TextEditingController(text: initial?.nameEn ?? '');
    _nameArController = TextEditingController(text: initial?.nameAr ?? '');
    _nativeNameController = TextEditingController(
      text: initial?.nativeName ?? '',
    );
    _sortOrderController = TextEditingController(
      text: '${initial?.sortOrder ?? 0}',
    );
    final direction = initial?.direction ?? '';
    _direction = direction.isEmpty ? 'LTR' : direction;
    _active = initial?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _nativeNameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveLanguage(
            code: _codeController.text.trim(),
            nameEn: _nameEnController.text.trim(),
            nameAr: _nameArController.text.trim(),
            nativeName: _nativeNameController.text.trim(),
            direction: _direction,
            active: _active,
            sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
            isNew: widget.initial == null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformDialogShell(
      title: widget.initial == null
          ? strings.tKey(PlatformAdminKeys.buttonLanguageAdd)
          : strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformTextField(
              controller: _codeController,
              label: strings.tKey(PlatformAdminKeys.fieldLanguageCode),
              enabled: widget.initial == null,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? strings.tKey(CommonKeys.validationRequired)
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _nameEnController,
              label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? strings.tKey(CommonKeys.validationRequired)
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _nameArController,
              label: strings.tKey(PlatformAdminKeys.fieldItemLabelAr),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _nativeNameController,
              label: strings.tKey(PlatformAdminKeys.fieldLanguageNativeName),
            ),
            const SizedBox(height: 12),
            PlatformDropdown<String>(
              label: strings.tKey(PlatformAdminKeys.fieldLanguageDirection),
              value: _direction,
              items: [
                DropdownMenuItem(
                  value: 'LTR',
                  child: Text(
                    strings.tKey(PlatformAdminKeys.labelDirectionLtr),
                  ),
                ),
                DropdownMenuItem(
                  value: 'RTL',
                  child: Text(
                    strings.tKey(PlatformAdminKeys.labelDirectionRtl),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _direction = value);
                }
              },
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _sortOrderController,
              label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: Text(strings.tKey(CommonKeys.statusActive)),
            ),
          ],
        ),
      ),
      actions: [
        PlatformSecondaryButton(
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        PlatformPrimaryButton(
          label: strings.tKey(CommonKeys.buttonSave),
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
