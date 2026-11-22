import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';

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
import 'translation_review_models.dart';
import 'translation_review_providers.dart';

/// Phase D review queue: `/configuration/translations`.
///
/// The list, the counters and every decision come from the backend review API;
/// after each action the queue and summary are invalidated and re-fetched, so
/// no state exists only on the client.
class TranslationReviewScreen extends ConsumerStatefulWidget {
  const TranslationReviewScreen({this.initialLanguage, super.key});

  final String? initialLanguage;

  @override
  ConsumerState<TranslationReviewScreen> createState() =>
      _TranslationReviewScreenState();
}

class _TranslationReviewScreenState
    extends ConsumerState<TranslationReviewScreen> {
  String? _busyId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLanguage;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(translationReviewLanguageProvider.notifier).select(initial);
      });
    }
  }

  void _resolveLanguage(List<PlatformLanguage> languages) {
    final current = ref.read(translationReviewLanguageProvider);
    if (current != null && languages.any((item) => item.code == current)) {
      return;
    }
    final active = ref.read(uiMessageControllerProvider).activeLanguage;
    final pick = languages.any((item) => item.code == active)
        ? active
        : (languages.isEmpty ? 'en' : languages.first.code);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(translationReviewLanguageProvider) != pick) {
        ref.read(translationReviewLanguageProvider.notifier).select(pick);
      }
    });
  }

  void _refresh() {
    ref.invalidate(translationReviewLanguagesProvider);
    ref.invalidate(translationReviewQueueProvider);
    ref.invalidate(translationReviewSummaryProvider);
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(
          message,
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
      ),
    );
  }

  String _failureCopy(UiMessageStrings strings, Object error) {
    if (error is AppFailure) {
      final byKey = strings.resolveFlatKey(error.messageKey) ?? '';
      if (byKey.isNotEmpty) return byKey;
      if ((error.detail ?? '').isNotEmpty) return error.detail!;
    }
    return strings.tKey(CommonKeys.errorGeneric);
  }

  Future<void> _review(
    TranslationReviewItem item,
    Future<TranslationReviewItem> Function(TranslationReviewActions actions)
    run, {
    required UiMessageKey successKey,
  }) async {
    final strings = ref.read(uiStringsProvider);
    setState(() => _busyId = item.id);
    try {
      await run(ref.read(translationReviewActionsProvider));
      if (!mounted) return;
      _toast(strings.tKey(successKey));
    } on Object catch (error) {
      if (!mounted) return;
      _toast(_failureCopy(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _approve(TranslationReviewItem item) => _review(
    item,
    (actions) => actions.approve(item),
    successKey: PlatformAdminKeys.pageTranslationReviewToastApproved,
  );

  Future<void> _edit(TranslationReviewItem item) async {
    final strings = ref.read(uiStringsProvider);
    final controller = TextEditingController(text: item.body);
    var body = item.body;
    try {
      final result = await showPlatformDialog<String>(
        context: context,
        title: strings.tKey(PlatformAdminKeys.pageTranslationReviewEditTitle),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.sourceText.isEmpty ? item.field : item.sourceText,
              style: PtTheme.font(12, lineHeight: 17, color: PtTheme.muted),
            ),
            const SizedBox(height: 8),
            PlatformTextField(
              key: const Key('translation-review-edit-body'),
              controller: controller,
              label: strings.tKey(
                PlatformAdminKeys.pageTranslationReviewEditBody,
              ),
              maxLines: 4,
              onChanged: (value) => body = value,
            ),
          ],
        ),
        actionsBuilder: (dialogContext) => _dialogActions(
          dialogContext,
          strings: strings,
          onSave: () => Navigator.of(dialogContext).pop(body),
        ),
      );
      if (result == null || result.trim().isEmpty) return;
      await _review(
        item,
        (actions) => actions.edit(item, result),
        successKey: PlatformAdminKeys.pageTranslationReviewToastSaved,
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _reject(TranslationReviewItem item) async {
    final strings = ref.read(uiStringsProvider);
    final controller = TextEditingController();
    var note = '';
    try {
      final result = await showPlatformDialog<String>(
        context: context,
        title: strings.tKey(PlatformAdminKeys.pageTranslationReviewRejectTitle),
        body: PlatformTextField(
          key: const Key('translation-review-reject-note'),
          controller: controller,
          label: strings.tKey(
            PlatformAdminKeys.pageTranslationReviewRejectNote,
          ),
          maxLines: 3,
          onChanged: (value) => note = value,
        ),
        actionsBuilder: (dialogContext) => _dialogActions(
          dialogContext,
          strings: strings,
          onSave: () => Navigator.of(dialogContext).pop(note),
        ),
      );
      if (result == null) return;
      await _review(
        item,
        (actions) => actions.reject(item, result),
        successKey: PlatformAdminKeys.pageTranslationReviewToastRejected,
      );
    } finally {
      controller.dispose();
    }
  }

  List<Widget> _dialogActions(
    BuildContext dialogContext, {
    required UiMessageStrings strings,
    required VoidCallback onSave,
  }) => <Widget>[
    TextButton(
      onPressed: () => Navigator.of(dialogContext).pop(),
      child: Text(strings.tKey(CommonKeys.buttonCancel)),
    ),
    FilledButton(
      key: const Key('translation-review-dialog-save'),
      onPressed: onSave,
      style: FilledButton.styleFrom(
        backgroundColor: PtTheme.deepGreen,
        minimumSize: const Size(96, PtTheme.controlHeight),
      ),
      child: Text(strings.tKey(CommonKeys.buttonSave)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final languagesAsync = ref.watch(translationReviewLanguagesProvider);
    final language = ref.watch(translationReviewLanguageProvider);
    final filter = ref.watch(translationReviewStateProvider);
    final active = language ?? 'en';
    final queue = ref.watch(
      translationReviewQueueProvider((lang: active, state: filter)),
    );
    final summary = ref.watch(translationReviewSummaryProvider(active));

    return PlatformShell(
      currentRoute: '/configuration/translations',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageSettingsTitle),
            onTap: () => context.go('/settings'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageTranslationReviewTitle),
            onTap: () {},
          ),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.tKey(PlatformAdminKeys.pageTranslationReviewTitle),
              style: PtTheme.font(24, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              strings.tKey(PlatformAdminKeys.pageTranslationReviewSubtitle),
              style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
            ),
            const SizedBox(height: 18),
            languagesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => PlatformErrorView(
                message: _failureCopy(strings, error),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: _refresh,
              ),
              data: (languages) {
                _resolveLanguage(languages);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Controls(
                      strings: strings,
                      languages: languages,
                      language: active,
                      filter: filter,
                      onLanguage: (value) {
                        if (value == null) return;
                        ref
                            .read(translationReviewLanguageProvider.notifier)
                            .select(value);
                      },
                      onFilter: (value) => ref
                          .read(translationReviewStateProvider.notifier)
                          .select(value),
                    ),
                    const SizedBox(height: 14),
                    summary.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (value) =>
                          _Summary(strings: strings, summary: value),
                    ),
                    const SizedBox(height: 14),
                    queue.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => PlatformErrorView(
                        message: _failureCopy(strings, error),
                        retryLabel: strings.tKey(CommonKeys.buttonRetry),
                        onRetry: () =>
                            ref.invalidate(translationReviewQueueProvider),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return PlatformEmptyView(
                            title: strings.tKey(
                              PlatformAdminKeys.pageTranslationReviewEmptyTitle,
                            ),
                            body: strings.tKey(
                              PlatformAdminKeys.pageTranslationReviewEmptyBody,
                            ),
                            actionLabel: strings.tKey(CommonKeys.buttonRefresh),
                            onAction: () =>
                                ref.invalidate(translationReviewQueueProvider),
                          );
                        }
                        return Column(
                          children: [
                            for (final item in items)
                              _ReviewRow(
                                strings: strings,
                                item: item,
                                busy: _busyId == item.id,
                                onApprove: () => _approve(item),
                                onEdit: () => _edit(item),
                                onReject: () => _reject(item),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.strings,
    required this.languages,
    required this.language,
    required this.filter,
    required this.onLanguage,
    required this.onFilter,
  });

  final UiMessageStrings strings;
  final List<PlatformLanguage> languages;
  final String language;
  final String filter;
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String> onFilter;

  String _stateLabel(String state) => switch (state) {
    TranslationReviewState.reviewed => strings.tKey(
      PlatformAdminKeys.pageTranslationReviewFilterReviewed,
    ),
    TranslationReviewState.stale => strings.tKey(
      PlatformAdminKeys.pageTranslationReviewFilterStale,
    ),
    _ => strings.tKey(PlatformAdminKeys.pageTranslationReviewFilterPending),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: PlatformDropdown<String>(
            key: const Key('translation-review-language'),
            label: strings.tKey(
              PlatformAdminKeys.pageTranslationReviewLanguage,
            ),
            value: language,
            items: [
              for (final item in languages)
                DropdownMenuItem<String>(
                  value: item.code,
                  child: Text(
                    item.nativeName.isEmpty ? item.code : item.nativeName,
                  ),
                ),
            ],
            onChanged: onLanguage,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final state in TranslationReviewState.filters)
              PlatformFilterChip(
                key: Key('translation-review-filter-$state'),
                label: _stateLabel(state),
                selected: filter == state,
                onTap: () => onFilter(state),
              ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.strings, required this.summary});

  final UiMessageStrings strings;
  final TranslationReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, int)>[
      (
        strings.tKey(PlatformAdminKeys.pageTranslationReviewSummaryPending),
        summary.countOf(TranslationReviewState.pending),
      ),
      (
        strings.tKey(PlatformAdminKeys.pageTranslationReviewSummaryReviewed),
        summary.countOf(TranslationReviewState.reviewed),
      ),
      (
        strings.tKey(PlatformAdminKeys.pageTranslationReviewSummaryStale),
        summary.countOf(TranslationReviewState.stale),
      ),
      (
        strings.tKey(
          PlatformAdminKeys.pageTranslationReviewSummarySafetyPending,
        ),
        summary.safetyCriticalPendingReview,
      ),
      (
        strings.tKey(
          PlatformAdminKeys.pageTranslationReviewSummarySafetyBlocked,
        ),
        summary.safetyCriticalBlocked,
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in entries)
          PlatformMetaPill(label: entry.$1, value: '${entry.$2}'),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.strings,
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onEdit,
    required this.onReject,
  });

  final UiMessageStrings strings;
  final TranslationReviewItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  Widget _labelled(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PtTheme.font(
            10,
            weight: FontWeight.w700,
            color: PtTheme.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: PtTheme.font(13, lineHeight: 19),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${item.entityType} ${item.entityId} ${item.field}',
      child: Container(
        key: Key('translation-review-row-${item.id}'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PtTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewColumnEntity,
                  ),
                  value: '${item.entityType} · ${item.entityId}',
                ),
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewColumnField,
                  ),
                  value: item.field,
                ),
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewLanguage,
                  ),
                  value: item.lang,
                ),
                if (item.safetyCritical)
                  PlatformStatusChip(
                    status: 'ERROR',
                    label: strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewSafetyBadge,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _labelled(
              strings.tKey(PlatformAdminKeys.pageTranslationReviewColumnSource),
              item.sourceText,
            ),
            _labelled(
              strings.tKey(
                PlatformAdminKeys.pageTranslationReviewColumnMachine,
              ),
              item.body,
            ),
            if (item.provider.isNotEmpty)
              _labelled(
                strings.tKey(
                  PlatformAdminKeys.pageTranslationReviewColumnProvider,
                ),
                item.provider,
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: 44,
                  child: PlatformPrimaryButton(
                    key: const Key('translation-review-approve'),
                    label: strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewActionApprove,
                    ),
                    icon: Icons.check_rounded,
                    isLoading: busy,
                    onPressed: busy ? null : onApprove,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: PlatformSecondaryButton(
                    key: const Key('translation-review-edit'),
                    label: strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewActionEdit,
                    ),
                    onPressed: busy ? null : onEdit,
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: PlatformDestructiveButton(
                    key: const Key('translation-review-reject'),
                    label: strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewActionReject,
                    ),
                    onPressed: busy ? null : onReject,
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
