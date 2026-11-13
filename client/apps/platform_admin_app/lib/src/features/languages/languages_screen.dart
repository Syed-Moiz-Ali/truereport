import 'dart:async';

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
                      onManage: (item) =>
                          context.go('/settings/languages/${item.code}'),
                      onEdit: (item) => _edit(context, item),
                      onGenerateUiMessages: (item) =>
                          _generateUiMessages(context, ref, item),
                      onReviewUiMessages: (item) => context.go(
                        '/settings/languages/${item.code}?tab=ui-text',
                      ),
                      onApproveUiMessages: (item) =>
                          _approveUiMessages(context, ref, item),
                      onPublish: (item) => _publish(context, ref, item),
                      onToggleActive: (item) =>
                          _toggleActive(context, ref, item),
                      onRetire: (item) =>
                          _setStatus(context, ref, item, 'RETIRED'),
                      onReopen: (item) =>
                          _setStatus(context, ref, item, 'REVIEW'),
                      onDeleteOrRetire: (item) =>
                          _confirmDeleteOrRetire(context, ref, item),
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

  Future<void> _generateUiMessages(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    try {
      final generation = await ref
          .read(translationApiProvider)
          .generateUiMessages(code: language.code);
      if (!context.mounted) return;
      ref.invalidate(platformLanguagesProvider);
      await showDialog<void>(
        context: context,
        builder: (_) => _UiMessageGenerationDialog(
          languageCode: language.code,
          initial: generation,
        ),
      );
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

  Future<void> _approveUiMessages(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    final strings = ref.read(uiStringsProvider);
    try {
      await ref
          .read(translationApiProvider)
          .approveUiMessageReview(language.code);
      if (!context.mounted) return;
      ref.invalidate(platformLanguagesProvider);
      ref.invalidate(readinessProvider(language.code));
      _showSnack(
        context,
        strings.tKey(PlatformAdminKeys.toastUiMessagesReviewApproved),
      );
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      _showSnack(context, failure.messageKey, error: true);
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, strings.tKey(CommonKeys.errorGeneric), error: true);
    }
  }

  Future<void> _publish(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    final strings = ref.read(uiStringsProvider);
    try {
      await ref.read(translationApiProvider).publishLanguage(language.code);
      if (!context.mounted) return;
      ref.invalidate(platformLanguagesProvider);
      ref.invalidate(readinessProvider(language.code));
      _showSnack(
        context,
        strings.tKey(PlatformAdminKeys.languageWorkspaceToastPublished),
      );
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      _showSnack(context, failure.messageKey, error: true);
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, strings.tKey(CommonKeys.errorGeneric), error: true);
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
    String status,
  ) async {
    final strings = ref.read(uiStringsProvider);
    try {
      await ref
          .read(translationApiProvider)
          .setLanguageStatus(language.code, status);
      if (!context.mounted) return;
      ref.invalidate(platformLanguagesProvider);
      ref.invalidate(readinessProvider(language.code));
      _showSnack(
        context,
        status == 'RETIRED'
            ? strings.tKey(PlatformAdminKeys.languageWorkspaceToastRetired)
            : strings.tKey(PlatformAdminKeys.languageWorkspaceToastReopened),
      );
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      _showSnack(context, failure.messageKey, error: true);
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, strings.tKey(CommonKeys.errorGeneric), error: true);
    }
  }

  Future<void> _confirmDeleteOrRetire(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          strings.tKey(PlatformAdminKeys.languageWorkspaceDialogDeleteOrRetire),
        ),
        content: Text(
          strings.tKey(
            PlatformAdminKeys.languageWorkspaceDialogDeleteOrRetireBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.tKey(CommonKeys.buttonCancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.tKey(PlatformAdminKeys.buttonRetire)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _setStatus(context, ref, language, 'RETIRED');
  }

  void _showSnack(BuildContext context, String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: error ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(message),
      ),
    );
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

/// Readiness-driven coverage pills for a single language.
///
/// Shows UI-text approved/total, content approved/total and the latest
/// generation state. Loading or backend errors collapse to a dash so the
/// registry keeps rendering while coverage loads.
class _LanguageCoveragePills extends ConsumerWidget {
  const _LanguageCoveragePills({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final readiness = ref.watch(readinessProvider(code));
    final generation = ref.watch(contentGenerationProvider(code));
    final genStatus = _generationLabel(
      strings,
      generation.asData?.value.jobStatus ?? '',
    );
    return readiness.maybeWhen(
      data: (data) {
        final ui = data.uiMessages;
        final contentMissing = data.contentTotal - data.contentApproved;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PlatformMetaPill(
              label: strings.tKey(
                PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage,
              ),
              value: '${ui.approved}/${ui.total}',
            ),
            PlatformMetaPill(
              label: strings.tKey(
                PlatformAdminKeys.languageWorkspaceFieldContentCoverage,
              ),
              value: '${data.contentApproved}/${data.contentTotal}',
            ),
            if (contentMissing > 0)
              PlatformMetaPill(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceFieldMissing,
                ),
                value: '$contentMissing',
              ),
            PlatformStatusChip(status: genStatus),
          ],
        );
      },
      orElse: () => Text('-', style: PtTheme.font(12, color: PtTheme.muted)),
    );
  }
}

enum _CoverageMetric { uiText, content, generation }

class _LanguageCoverageCell extends ConsumerWidget {
  const _LanguageCoverageCell({required this.code, required this.metric});

  final String code;
  final _CoverageMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final readiness = ref.watch(readinessProvider(code));
    final generation = ref.watch(contentGenerationProvider(code));
    return readiness.maybeWhen(
      data: (data) {
        switch (metric) {
          case _CoverageMetric.uiText:
            return Text('${data.uiMessages.approved}/${data.uiMessages.total}');
          case _CoverageMetric.content:
            return Text('${data.contentApproved}/${data.contentTotal}');
          case _CoverageMetric.generation:
            return PlatformStatusChip(
              status: _generationLabel(
                strings,
                generation.asData?.value.jobStatus ?? '',
              ),
            );
        }
      },
      orElse: () => Text('-', style: PtTheme.font(12, color: PtTheme.muted)),
    );
  }
}

String _generationLabel(UiMessageStrings strings, String status) {
  switch (status.toUpperCase()) {
    case 'QUEUED':
    case 'RUNNING':
      return strings.tKey(PlatformAdminKeys.languageWorkspaceGenerationRunning);
    case 'COMPLETED':
      return strings.tKey(
        PlatformAdminKeys.languageWorkspaceGenerationCompleted,
      );
    case 'FAILED':
    case 'CANCELLED':
    case 'INTERRUPTED':
      return strings.tKey(PlatformAdminKeys.languageWorkspaceGenerationFailed);
    case 'SKIPPED':
      return strings.tKey(PlatformAdminKeys.languageWorkspaceGenerationSkipped);
    default:
      return strings.tKey(PlatformAdminKeys.languageWorkspaceGenerationIdle);
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
    required this.onManage,
    required this.onEdit,
    required this.onGenerateUiMessages,
    required this.onReviewUiMessages,
    required this.onApproveUiMessages,
    required this.onPublish,
    required this.onToggleActive,
    required this.onRetire,
    required this.onReopen,
    required this.onDeleteOrRetire,
    required this.onSetDefault,
    required this.onReorder,
  });

  final List<PlatformLanguage> items;
  final ValueChanged<PlatformLanguage> onManage;
  final ValueChanged<PlatformLanguage> onEdit;
  final ValueChanged<PlatformLanguage> onGenerateUiMessages;
  final ValueChanged<PlatformLanguage> onReviewUiMessages;
  final ValueChanged<PlatformLanguage> onApproveUiMessages;
  final ValueChanged<PlatformLanguage> onPublish;
  final ValueChanged<PlatformLanguage> onToggleActive;
  final ValueChanged<PlatformLanguage> onRetire;
  final ValueChanged<PlatformLanguage> onReopen;
  final ValueChanged<PlatformLanguage> onDeleteOrRetire;
  final ValueChanged<PlatformLanguage> onSetDefault;
  final void Function(List<PlatformLanguage> items, int index, int delta)
  onReorder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1180) {
          return _LanguagesTable(
            items: items,
            onManage: onManage,
            onEdit: onEdit,
            onGenerateUiMessages: onGenerateUiMessages,
            onReviewUiMessages: onReviewUiMessages,
            onApproveUiMessages: onApproveUiMessages,
            onPublish: onPublish,
            onToggleActive: onToggleActive,
            onRetire: onRetire,
            onReopen: onReopen,
            onDeleteOrRetire: onDeleteOrRetire,
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
                onManage: () => onManage(items[index]),
                onEdit: () => onEdit(items[index]),
                onGenerateUiMessages: () => onGenerateUiMessages(items[index]),
                onReviewUiMessages: () => onReviewUiMessages(items[index]),
                onApproveUiMessages: () => onApproveUiMessages(items[index]),
                onPublish: () => onPublish(items[index]),
                onToggleActive: () => onToggleActive(items[index]),
                onRetire: () => onRetire(items[index]),
                onReopen: () => onReopen(items[index]),
                onDeleteOrRetire: () => onDeleteOrRetire(items[index]),
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
    required this.onManage,
    required this.onEdit,
    required this.onGenerateUiMessages,
    required this.onReviewUiMessages,
    required this.onApproveUiMessages,
    required this.onPublish,
    required this.onToggleActive,
    required this.onRetire,
    required this.onReopen,
    required this.onDeleteOrRetire,
    required this.onSetDefault,
    required this.onReorder,
  });

  final List<PlatformLanguage> items;
  final ValueChanged<PlatformLanguage> onManage;
  final ValueChanged<PlatformLanguage> onEdit;
  final ValueChanged<PlatformLanguage> onGenerateUiMessages;
  final ValueChanged<PlatformLanguage> onReviewUiMessages;
  final ValueChanged<PlatformLanguage> onApproveUiMessages;
  final ValueChanged<PlatformLanguage> onPublish;
  final ValueChanged<PlatformLanguage> onToggleActive;
  final ValueChanged<PlatformLanguage> onRetire;
  final ValueChanged<PlatformLanguage> onReopen;
  final ValueChanged<PlatformLanguage> onDeleteOrRetire;
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
            DataColumn(
              label: Text(
                strings.tKey(
                  PlatformAdminKeys.languageWorkspaceFieldDefaultFlag,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.fieldLanguageUiMessagesPath),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(
                  PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(
                  PlatformAdminKeys.languageWorkspaceFieldContentCoverage,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(
                  PlatformAdminKeys.languageWorkspaceFieldGenerationStatus,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(label: Text(strings.tKey(CommonKeys.tableActions))),
          ],
          rows: [
            for (var index = 0; index < items.length; index++)
              _row(context, strings, items[index], index),
          ],
        ),
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    UiMessageStrings strings,
    PlatformLanguage language,
    int index,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(language.code, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        DataCell(
          Text(
            language.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text(language.direction)),
        DataCell(
          PlatformStatusChip(
            status: _languageStatusLabel(strings, language.status),
          ),
        ),
        DataCell(
          language.isDefault
              ? PlatformStatusChip(
                  status: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceFieldDefaultFlag,
                  ),
                )
              : const Text('-'),
        ),
        DataCell(
          Text(
            language.uiMessagesPath.isEmpty ? '-' : language.uiMessagesPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          _LanguageCoverageCell(
            code: language.code,
            metric: _CoverageMetric.uiText,
          ),
        ),
        DataCell(
          _LanguageCoverageCell(
            code: language.code,
            metric: _CoverageMetric.content,
          ),
        ),
        DataCell(
          _LanguageCoverageCell(
            code: language.code,
            metric: _CoverageMetric.generation,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformPrimaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonManage,
                ),
                onPressed: () => onManage(language),
              ),
              PopupMenuButton<String>(
                tooltip: strings.tKey(CommonKeys.tableActions),
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit(language);
                    case 'default':
                      onSetDefault(language);
                    case 'up':
                      onReorder(items, index, -1);
                    case 'down':
                      onReorder(items, index, 1);
                    case 'active':
                      onToggleActive(language);
                    case 'retire':
                      onRetire(language);
                    case 'reopen':
                      onReopen(language);
                    case 'deleteRetire':
                      onDeleteOrRetire(language);
                    case 'generate':
                      onGenerateUiMessages(language);
                    case 'review':
                      onReviewUiMessages(language);
                    case 'approve':
                      onApproveUiMessages(language);
                    case 'publish':
                      onPublish(language);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonEditMetadata,
                      ),
                    ),
                  ),
                  if (language.code == 'en' && !language.isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: Text(
                        strings.tKey(
                          PlatformAdminKeys.languageWorkspaceButtonSetDefault,
                        ),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'up',
                    enabled: index > 0,
                    child: Text(strings.tKey(CommonKeys.buttonMoveUp)),
                  ),
                  PopupMenuItem(
                    value: 'down',
                    enabled: index < items.length - 1,
                    child: Text(strings.tKey(CommonKeys.buttonMoveDown)),
                  ),
                  PopupMenuItem(
                    value: 'active',
                    child: Text(
                      language.active
                          ? strings.tKey(
                              PlatformAdminKeys
                                  .languageWorkspaceButtonDeactivate,
                            )
                          : strings.tKey(
                              PlatformAdminKeys.languageWorkspaceButtonActivate,
                            ),
                    ),
                  ),
                  PopupMenuItem(
                    value: language.status == 'RETIRED' ? 'reopen' : 'retire',
                    child: Text(
                      language.status == 'RETIRED'
                          ? strings.tKey(
                              PlatformAdminKeys.languageWorkspaceButtonReopen,
                            )
                          : strings.tKey(
                              PlatformAdminKeys.languageWorkspaceButtonRetire,
                            ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'deleteRetire',
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonDeleteOrRetire,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'generate',
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonGenerateUiText,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'review',
                    child: Text(
                      strings.tKey(PlatformAdminKeys.buttonLanguageReview),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'approve',
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.buttonUiMessagesReviewApprove,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonPublish,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.onManage,
    required this.onEdit,
    required this.onGenerateUiMessages,
    required this.onReviewUiMessages,
    required this.onApproveUiMessages,
    required this.onPublish,
    required this.onToggleActive,
    required this.onRetire,
    required this.onReopen,
    required this.onDeleteOrRetire,
    required this.onSetDefault,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final PlatformLanguage language;
  final VoidCallback onManage;
  final VoidCallback onEdit;
  final VoidCallback onGenerateUiMessages;
  final VoidCallback onReviewUiMessages;
  final VoidCallback onApproveUiMessages;
  final VoidCallback onPublish;
  final VoidCallback onToggleActive;
  final VoidCallback onRetire;
  final VoidCallback onReopen;
  final VoidCallback onDeleteOrRetire;
  final VoidCallback onSetDefault;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    final retired = language.status == 'RETIRED';
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
                    PlatformAdminKeys.languageWorkspaceFieldDefaultFlag,
                  ),
                ),
              _LanguageCoveragePills(code: language.code),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            language.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${strings.tKey(PlatformAdminKeys.fieldLanguageUiMessagesPath)}: '
            '${language.uiMessagesPath.isEmpty ? '-' : language.uiMessagesPath}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
          if (language.reviewedBy.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldLastReviewed)}: '
              '${language.reviewedBy} · ${language.reviewedAt}',
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
              PlatformPrimaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonManage,
                ),
                onPressed: onManage,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonEditMetadata,
                ),
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              if (language.code == 'en' && !language.isDefault)
                PlatformSecondaryButton(
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceButtonSetDefault,
                  ),
                  icon: Icons.star_outline_rounded,
                  onPressed: onSetDefault,
                ),
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonMoveUp),
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonMoveDown),
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              ),
              PlatformSecondaryButton(
                label: language.active
                    ? strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonDeactivate,
                      )
                    : strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonActivate,
                      ),
                icon: language.active
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                onPressed: onToggleActive,
              ),
              PlatformSecondaryButton(
                label: retired
                    ? strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonReopen,
                      )
                    : strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonRetire,
                      ),
                icon: retired
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                onPressed: retired ? onReopen : onRetire,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonDeleteOrRetire,
                ),
                icon: Icons.delete_outline_rounded,
                onPressed: onDeleteOrRetire,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonGenerateUiText,
                ),
                icon: Icons.cloud_download_rounded,
                onPressed: onGenerateUiMessages,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonLanguageReview),
                icon: Icons.rate_review_outlined,
                onPressed: onReviewUiMessages,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.buttonUiMessagesReviewApprove,
                ),
                icon: Icons.verified_rounded,
                onPressed: onApproveUiMessages,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonPublish,
                ),
                icon: Icons.publish_rounded,
                onPressed: onPublish,
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
  late final TextEditingController _nativeNameController;
  late final TextEditingController _sortOrderController;
  late String _direction;
  late bool _active;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _codeController = TextEditingController(text: initial?.code ?? '');
    _nativeNameController = TextEditingController(
      text: initial?.nativeName ?? '',
    );
    _sortOrderController = TextEditingController(
      text: '${initial?.sortOrder ?? 0}',
    );
    final direction = initial?.direction ?? '';
    _direction = direction.isEmpty ? 'LTR' : direction.toUpperCase();
    _active = initial?.active ?? true;
    _isDefault = initial?.isDefault ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
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
            nativeName: _nativeNameController.text.trim(),
            direction: _direction,
            active: _active,
            sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
            isDefault: _isDefault,
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
              controller: _nativeNameController,
              label: strings.tKey(PlatformAdminKeys.fieldLanguageNativeName),
              textDirection: Directionality.of(context) == TextDirection.rtl
                  ? TextDirection.rtl
                  : null,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? strings.tKey(CommonKeys.validationRequired)
                  : null,
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: widget.initial != null && widget.initial!.code != 'en'
                  ? null
                  : (value) => setState(() => _isDefault = value),
              title: Text(
                strings.tKey(
                  PlatformAdminKeys.languageWorkspaceFieldDefaultFlag,
                ),
              ),
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

class _UiMessageGenerationDialog extends ConsumerStatefulWidget {
  const _UiMessageGenerationDialog({
    required this.languageCode,
    required this.initial,
  });

  final String languageCode;
  final UiMessageGeneration initial;

  @override
  ConsumerState<_UiMessageGenerationDialog> createState() =>
      _UiMessageGenerationDialogState();
}

class _UiMessageGenerationDialogState
    extends ConsumerState<_UiMessageGenerationDialog> {
  late UiMessageGeneration _generation = widget.initial;
  Timer? _timer;
  bool _retrying = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _schedulePolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedulePolling() {
    _timer?.cancel();
    if (!_generation.isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final generation = await ref
          .read(translationApiProvider)
          .fetchUiMessageGeneration(widget.languageCode);
      if (!mounted) return;
      setState(() => _generation = generation);
      if (generation.isFinished) {
        _timer?.cancel();
        ref.invalidate(platformLanguagesProvider);
      }
    } catch (_) {
      _timer?.cancel();
    }
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final generation = await ref
          .read(translationApiProvider)
          .generateUiMessages(code: widget.languageCode, force: true);
      if (!mounted) return;
      setState(() {
        _generation = generation;
        _retrying = false;
      });
      _schedulePolling();
      ref.invalidate(platformLanguagesProvider);
    } catch (_) {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _retryFailed() async {
    setState(() => _retrying = true);
    try {
      final generation = await ref
          .read(translationApiProvider)
          .retryFailedUiMessageGeneration(widget.languageCode);
      if (!mounted) return;
      setState(() {
        _generation = generation;
        _retrying = false;
      });
      _schedulePolling();
      ref.invalidate(platformLanguagesProvider);
    } catch (_) {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      final generation = await ref
          .read(translationApiProvider)
          .cancelUiMessageGeneration(widget.languageCode);
      if (!mounted) return;
      setState(() {
        _generation = generation;
        _cancelling = false;
      });
      _timer?.cancel();
      ref.invalidate(platformLanguagesProvider);
    } catch (_) {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final generation = _generation;
    final progressLabel = generation.totalKeys <= 0
        ? ''
        : '${generation.completedKeys}/${generation.totalKeys}';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: PlatformSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformSectionHeader(
                title: strings.tKey(PlatformAdminKeys.buttonLanguageGenerate),
                subtitle: widget.languageCode,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  PlatformStatusChip(
                    status: _languageStatusLabel(strings, generation.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progressLabel,
                    style: PtTheme.font(12, color: PtTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: generation.progress,
                  minHeight: 8,
                  backgroundColor: PtTheme.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    PtTheme.deepGreen,
                  ),
                ),
              ),
              if (generation.path.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${strings.tKey(PlatformAdminKeys.fieldLanguageUiMessagesPath)}: '
                  '${generation.path}',
                  style: PtTheme.font(12, color: PtTheme.muted),
                ),
              ],
              if (generation.error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  generation.error,
                  style: PtTheme.font(12, color: PtTheme.rose),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  PlatformSecondaryButton(
                    label: strings.tKey(CommonKeys.buttonClose),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (generation.isRunning)
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonLanguageCancelGeneration,
                      ),
                      icon: Icons.stop_circle_outlined,
                      isLoading: _cancelling,
                      onPressed: _cancelling ? null : _cancel,
                    ),
                  if (generation.isFailed)
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonLanguageRetryFailed,
                      ),
                      icon: Icons.refresh_rounded,
                      isLoading: _retrying,
                      onPressed: _retrying ? null : _retryFailed,
                    ),
                  PlatformPrimaryButton(
                    label: strings.tKey(CommonKeys.buttonRetry),
                    icon: Icons.autorenew_rounded,
                    isLoading: _retrying && !generation.isFailed,
                    onPressed: generation.isRunning || _retrying
                        ? null
                        : _retry,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
