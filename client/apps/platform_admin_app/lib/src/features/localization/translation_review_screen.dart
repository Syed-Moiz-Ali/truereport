import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

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
import '../../reference_status_lookup.dart';
import 'translation_review_models.dart';
import 'translation_review_providers.dart';

/// The two translation scopes shown as tabs on the Content review desk.
enum ReviewScope {
  content(
    contentScopeType,
    PlatformAdminKeys.pageTranslationReviewScopeContent,
  ),
  interfaceText(
    interfaceTextScopeType,
    PlatformAdminKeys.pageTranslationReviewScopeInterfaceText,
  );

  const ReviewScope(this.entityType, this.labelKey);

  final String entityType;
  final UiMessageKey labelKey;
}

/// Dynamic business content types (the old content scope).
// gate-allow: codes - backend wire values, not a UI taxonomy.
const List<String> _contentEntityTypes = <String>[
  'CATEGORY',
  'ITEM',
  'OPTION_SET',
  'OPTION_VALUE',
  'TEMPLATE',
  'DOCUMENT_TYPE',
  'ISSUE_FIELD',
];

const List<String> _uiEntityTypes = <String>[interfaceTextScopeType];

/// Display direction for translated content: the body is in the target
/// language, so an Arabic string in an English UI still reads right-to-left.
TextDirection reviewDirection(String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'ar':
    case 'he':
    case 'fa':
    case 'ur':
      return TextDirection.rtl;
    default:
      return TextDirection.ltr;
  }
}

/// `labelEn` → `Label`, `helpEn` → `Help`, `name` → `Name`.
///
/// The backend field is a column name with a locale suffix; an admin reads a
/// field, not a schema. The suffix is stripped only for display.
String reviewFieldLabel(String field) {
  var text = field.trim();
  if (text.length > 2) {
    final lower = text.toLowerCase();
    if (lower.endsWith('en') || lower.endsWith('ar')) {
      text = text.substring(0, text.length - 2);
    }
  }
  if (text.isEmpty) return field;
  final spaced = text.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (spaced.isEmpty) return field;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Phase D review queue: `/configuration/translations`.
///
/// Direction C "Triage Desk": the queue is a rail, the selected string is one
/// focused panel, and every decision lives in that panel's footer. Deciding a
/// string advances to the next one, so a reviewer never has to re-find their
/// place. The list, the counters and every decision come from the backend
/// review API; after each action the queue and summary are re-fetched, so no
/// state exists only on the client.
class TranslationReviewScreen extends ConsumerStatefulWidget {
  const TranslationReviewScreen({
    this.initialLanguage,
    this.initialScope,
    super.key,
  });

  final String? initialLanguage;

  /// `ui` opens the Interface text tab, so a language card can land on the tab
  /// that actually has work.
  final String? initialScope;

  @override
  ConsumerState<TranslationReviewScreen> createState() =>
      _TranslationReviewScreenState();
}

class _TranslationReviewScreenState
    extends ConsumerState<TranslationReviewScreen> {
  String? _busyId;
  String? _selectedId;
  ReviewScope _scope = ReviewScope.content;
  int _page = 0;
  bool _bulkBusy = false;
  bool _generatingTranslations = false;
  final Set<String> _selectedIds = <String>{};
  bool _selectionBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialScope == 'ui') {
      _scope = ReviewScope.interfaceText;
    }
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
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

  /// Runs one decision, then moves the desk to the next string so the
  /// reviewer keeps their place.
  Future<void> _review(
    TranslationReviewItem item,
    Future<TranslationReviewItem> Function(TranslationReviewActions actions)
    run, {
    required UiMessageKey successKey,
    List<TranslationReviewItem> siblings = const <TranslationReviewItem>[],
    int index = 0,
  }) async {
    final strings = ref.read(uiStringsProvider);
    setState(() => _busyId = item.id);
    try {
      await run(ref.read(translationReviewActionsProvider));
      if (!mounted) return;
      _toast(strings.tKey(successKey));
      final next = siblings.length > index + 1 ? siblings[index + 1] : null;
      setState(() => _selectedId = next?.id);
    } on Object catch (error) {
      if (!mounted) return;
      _toast(_failureCopy(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _approve(
    TranslationReviewItem item, {
    List<TranslationReviewItem> siblings = const <TranslationReviewItem>[],
    int index = 0,
  }) => _review(
    item,
    (actions) => actions.approve(item),
    successKey: PlatformAdminKeys.pageTranslationReviewToastApproved,
    siblings: siblings,
    index: index,
  );

  Future<void> _edit(
    TranslationReviewItem item, {
    List<TranslationReviewItem> siblings = const <TranslationReviewItem>[],
    int index = 0,
  }) async {
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
        siblings: siblings,
        index: index,
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _reject(
    TranslationReviewItem item, {
    List<TranslationReviewItem> siblings = const <TranslationReviewItem>[],
    int index = 0,
  }) async {
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
        siblings: siblings,
        index: index,
      );
    } finally {
      controller.dispose();
    }
  }

  void _selectScope(ReviewScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _page = 0;
      _selectedId = null;
      _selectedIds.clear();
    });
    ref
        .read(translationReviewStateProvider.notifier)
        .select(TranslationReviewState.pending);
  }

  Future<void> _bulkApprove(
    UiMessageStrings strings,
    String lang,
    String languageName,
    List<String> entityTypes,
  ) async {
    if (_bulkBusy) return;
    setState(() => _bulkBusy = true);
    try {
      final interfaceText =
          entityTypes.length == 1 &&
          entityTypes.first == interfaceTextScopeType;
      final preview = await ref
          .read(translationReviewActionsProvider)
          .bulkApprove(lang, dryRun: true, entityTypes: entityTypes);
      if (!mounted) return;
      if (preview.approved == 0) {
        _toast(
          strings.tKey(PlatformAdminKeys.pageTranslationReviewBulkApproveEmpty),
        );
        return;
      }
      final confirmed = await showPlatformConfirmDialog(
        context: context,
        title: strings.tKey(
          PlatformAdminKeys.pageTranslationReviewBulkApproveTitle,
        ),
        body: strings.tArgsKey(
          interfaceText
              ? PlatformAdminKeys.pageTranslationReviewBulkApproveBodyUi
              : PlatformAdminKeys.pageTranslationReviewBulkApproveBody,
          <String, Object?>{
            'count': preview.approved,
            'language': _isolate(languageName),
          },
        ),
        confirmLabel: strings.tArgsKey(
          PlatformAdminKeys.pageTranslationReviewBulkApproveConfirm,
          <String, Object?>{'count': preview.approved},
        ),
      );
      if (confirmed != true || !mounted) return;
      final result = await ref
          .read(translationReviewActionsProvider)
          .bulkApprove(lang, entityTypes: entityTypes);
      if (!mounted) return;
      _toast(
        strings.tArgsKey(
          interfaceText
              ? PlatformAdminKeys.pageTranslationReviewBulkApproveToastUi
              : PlatformAdminKeys.pageTranslationReviewBulkApproveToast,
          <String, Object?>{'count': result.approved},
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      _toast(_failureCopy(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  void _toggleSelect(TranslationReviewItem item) {
    if (!_isActionable(item)) return;
    setState(() {
      if (!_selectedIds.add(item.id)) {
        _selectedIds.remove(item.id);
      }
    });
  }

  void _toggleSelectAll(List<TranslationReviewItem> items) {
    final selectable = items.where(_isActionable).toList(growable: false);
    setState(() {
      final allSelected =
          selectable.isNotEmpty &&
          selectable.every((item) => _selectedIds.contains(item.id));
      _selectedIds.clear();
      if (!allSelected) {
        _selectedIds.addAll(selectable.map((item) => item.id));
      }
    });
  }

  Future<void> _generateTranslations(
    UiMessageStrings strings,
    String lang,
    String languageName,
    List<String> entityTypes,
  ) async {
    if (_generatingTranslations) return;
    setState(() => _generatingTranslations = true);
    try {
      final api = ref.read(platformConfigApiProvider);
      final interfaceText =
          entityTypes.length == 1 &&
          entityTypes.first == interfaceTextScopeType;
      final preview = await api.backfillContent(
        lang: lang,
        dryRun: true,
        entityTypes: entityTypes,
      );
      if (!mounted) return;
      if (preview.enqueued == 0) {
        _toast(
          strings.tKey(PlatformAdminKeys.pageTranslationReviewGenerateEmpty),
        );
        return;
      }
      final confirmed = await showPlatformConfirmDialog(
        context: context,
        title: strings.tKey(
          interfaceText
              ? PlatformAdminKeys.pageTranslationReviewGenerateTitleUi
              : PlatformAdminKeys.pageTranslationReviewGenerateTitle,
        ),
        body: strings.tArgsKey(
          interfaceText
              ? PlatformAdminKeys.pageTranslationReviewGenerateBodyUi
              : PlatformAdminKeys.pageTranslationReviewGenerateBody,
          <String, Object?>{
            'count': preview.enqueued,
            'language': _isolate(languageName),
          },
        ),
        confirmLabel: strings.tArgsKey(
          PlatformAdminKeys.pageTranslationReviewGenerateConfirm,
          <String, Object?>{'count': preview.enqueued},
        ),
      );
      if (confirmed != true || !mounted) return;
      final result = await api.backfillContent(
        lang: lang,
        entityTypes: entityTypes,
      );
      if (!mounted) return;
      _toast(
        strings.tArgsKey(
          interfaceText
              ? PlatformAdminKeys.pageTranslationReviewGenerateToastUi
              : PlatformAdminKeys.pageTranslationReviewGenerateToast,
          <String, Object?>{'count': result.enqueued},
        ),
      );
      ref.invalidate(translationReviewQueueProvider);
      ref.invalidate(translationReviewSummaryProvider);
      // The worker runs on a short schedule; refresh once so the first rows
      // appear without the admin pressing Refresh.
      Future<void>.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        ref.invalidate(translationReviewQueueProvider);
        ref.invalidate(translationReviewSummaryProvider);
      });
    } on Object catch (error) {
      if (!mounted) return;
      _toast(_failureCopy(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _generatingTranslations = false);
    }
  }

  Future<void> _approveSelected(
    UiMessageStrings strings,
    String lang,
    String languageName,
    List<TranslationReviewItem> items,
    bool interfaceText,
  ) async {
    if (_selectionBusy) return;
    final selected = items
        .where((item) => _selectedIds.contains(item.id))
        .toList(growable: false);
    if (selected.isEmpty) return;
    setState(() => _selectionBusy = true);
    try {
      final confirmed = await showPlatformConfirmDialog(
        context: context,
        title: strings.tKey(
          PlatformAdminKeys.pageTranslationReviewApproveSelectedTitle,
        ),
        body: strings.tArgsKey(
          interfaceText
              ? PlatformAdminKeys.pageTranslationReviewApproveSelectedBodyUi
              : PlatformAdminKeys.pageTranslationReviewApproveSelectedBody,
          <String, Object?>{
            'count': selected.length,
            'language': _isolate(languageName),
          },
        ),
        confirmLabel: strings.tArgsKey(
          PlatformAdminKeys.pageTranslationReviewApproveSelectedConfirm,
          <String, Object?>{'count': selected.length},
        ),
      );
      if (confirmed != true || !mounted) return;
      final result = await ref
          .read(translationReviewActionsProvider)
          .approveSelected(lang, selected);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      _toast(
        strings.tArgsKey(
          PlatformAdminKeys.pageTranslationReviewApproveSelectedToast,
          <String, Object?>{'count': result.approved},
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      _toast(_failureCopy(strings, error), error: true);
    } finally {
      if (mounted) setState(() => _selectionBusy = false);
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
    // The selected language must be one the backend actually offers, otherwise
    // the picker renders a value that is not in its own item list.
    final available =
        languagesAsync.asData?.value ?? const <PlatformLanguage>[];
    final codes = available.map((item) => item.code).toSet();
    final active = language != null && codes.contains(language)
        ? language
        : (codes.contains('en')
              ? 'en'
              : (available.isEmpty ? 'en' : available.first.code));
    final queue = ref.watch(
      translationReviewQueueProvider((
        lang: active,
        state: filter,
        entityType: _scope.entityType,
        page: _page,
      )),
    );
    final summary = ref.watch(
      translationReviewSummaryProvider((
        lang: active,
        entityType: _scope.entityType,
      )),
    );

    return PlatformShell(
      currentRoute: '/configuration/translations',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageProfileTitle),
            onTap: () => context.go('/profile'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageTranslationReviewTitle),
          ),
        ],
      ),
      child: languagesAsync.when(
        loading: () => const PlatformPage(
          child: SizedBox(height: 420, child: _DeskSkeleton()),
        ),
        error: (error, _) => PlatformPage(
          child: PlatformErrorView(
            message: _failureCopy(strings, error),
            retryLabel: strings.tKey(CommonKeys.buttonRetry),
            onRetry: _refresh,
          ),
        ),
        data: (languages) {
          _resolveLanguage(languages);
          final nativeName = languages
              .where((item) => item.code == active)
              .map((item) => item.nativeName)
              .firstWhere((name) => name.isNotEmpty, orElse: () => active);
          return _TriageDesk(
            strings: strings,
            languages: languages,
            language: active,
            nativeName: nativeName,
            filter: filter,
            scope: _scope,
            onScope: _selectScope,
            onLanguage: (value) {
              if (value == null) return;
              setState(() {
                _page = 0;
                _selectedId = null;
                _selectedIds.clear();
              });
              ref
                  .read(translationReviewLanguageProvider.notifier)
                  .select(value);
            },
            onFilter: (value) {
              setState(() {
                _page = 0;
                _selectedId = null;
                _selectedIds.clear();
              });
              ref.read(translationReviewStateProvider.notifier).select(value);
            },
            page: _page,
            onPage: (page) => setState(() {
              _page = page;
              _selectedId = null;
              _selectedIds.clear();
            }),
            summary: summary.asData?.value,
            queue: queue,
            selectedId: _selectedId,
            onSelect: (id) => setState(() => _selectedId = id),
            busyId: _busyId,
            bulkBusy: _bulkBusy,
            selectedIds: _selectedIds,
            selectionBusy: _selectionBusy,
            onToggleSelect: _toggleSelect,
            onToggleSelectAll: _toggleSelectAll,
            onApproveSelected: (items) => _approveSelected(
              strings,
              active,
              nativeName,
              items,
              _scope == ReviewScope.interfaceText,
            ),
            generatingTranslations: _generatingTranslations,
            onGenerateTranslations: () => _generateTranslations(
              strings,
              active,
              nativeName,
              _scope == ReviewScope.interfaceText
                  ? _uiEntityTypes
                  : _contentEntityTypes,
            ),
            onBulkApprove: () => _bulkApprove(
              strings,
              active,
              nativeName,
              _scope == ReviewScope.interfaceText
                  ? _uiEntityTypes
                  : _contentEntityTypes,
            ),
            onApprove: (item, siblings, index) =>
                _approve(item, siblings: siblings, index: index),
            onEdit: (item, siblings, index) =>
                _edit(item, siblings: siblings, index: index),
            onReject: (item, siblings, index) =>
                _reject(item, siblings: siblings, index: index),
            onRetryQueue: () => ref.invalidate(translationReviewQueueProvider),
          );
        },
      ),
    );
  }
}

/// The desk itself: filter toolbar, queue rail, focused review panel.
class _TriageDesk extends StatelessWidget {
  const _TriageDesk({
    required this.strings,
    required this.languages,
    required this.language,
    required this.nativeName,
    required this.filter,
    required this.scope,
    required this.onScope,
    required this.onLanguage,
    required this.onFilter,
    required this.page,
    required this.onPage,
    required this.summary,
    required this.queue,
    required this.selectedId,
    required this.onSelect,
    required this.busyId,
    required this.bulkBusy,
    required this.selectedIds,
    required this.selectionBusy,
    required this.onToggleSelect,
    required this.onToggleSelectAll,
    required this.onApproveSelected,
    required this.generatingTranslations,
    required this.onGenerateTranslations,
    required this.onBulkApprove,
    required this.onApprove,
    required this.onEdit,
    required this.onReject,
    required this.onRetryQueue,
  });

  final UiMessageStrings strings;
  final List<PlatformLanguage> languages;
  final String language;
  final String nativeName;
  final String filter;
  final ReviewScope scope;
  final ValueChanged<ReviewScope> onScope;
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String> onFilter;
  final int page;
  final ValueChanged<int> onPage;
  final TranslationReviewSummary? summary;
  final AsyncValue<List<TranslationReviewItem>> queue;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final String? busyId;
  final bool bulkBusy;
  final Set<String> selectedIds;
  final bool selectionBusy;
  final ValueChanged<TranslationReviewItem> onToggleSelect;
  final void Function(List<TranslationReviewItem>) onToggleSelectAll;
  final void Function(List<TranslationReviewItem>) onApproveSelected;
  final bool generatingTranslations;
  final VoidCallback onGenerateTranslations;
  final VoidCallback onBulkApprove;
  final void Function(TranslationReviewItem, List<TranslationReviewItem>, int)
  onApprove;
  final void Function(TranslationReviewItem, List<TranslationReviewItem>, int)
  onEdit;
  final void Function(TranslationReviewItem, List<TranslationReviewItem>, int)
  onReject;
  final VoidCallback onRetryQueue;

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
    final compact = MediaQuery.sizeOf(context).width < 860;
    final pad = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 24.0;
    final pendingLabel = strings.tKey(
      PlatformAdminKeys.pageTranslationReviewSummaryPending,
    );
    final count = summary?.countOf(TranslationReviewState.pending);
    final pendingNonSafety =
        (count ?? 0) - (summary?.safetyCriticalPendingReview ?? 0);
    final currentItems = queue.asData?.value ?? const <TranslationReviewItem>[];
    final summaryTotal = summary?.total ?? 0;
    final targets = summary?.targets ?? 0;
    final missing = summary?.missing ?? 0;
    final headerActions = <Widget>[];
    if (summaryTotal == 0 ||
        (scope == ReviewScope.interfaceText && missing > 0)) {
      headerActions.add(
        PlatformPrimaryButton(
          key: const Key('translation-review-generate'),
          label: missing > 0
              ? strings.tArgsKey(
                  PlatformAdminKeys.pageTranslationReviewGenerateCount,
                  <String, Object?>{'count': missing},
                )
              : strings.tKey(
                  scope == ReviewScope.interfaceText
                      ? PlatformAdminKeys.pageTranslationReviewGenerateUi
                      : PlatformAdminKeys.pageTranslationReviewGenerate,
                ),
          icon: Icons.auto_awesome_rounded,
          isLoading: generatingTranslations,
          onPressed: generatingTranslations ? null : onGenerateTranslations,
        ),
      );
    }
    if (selectedIds.isNotEmpty) {
      headerActions.add(
        PlatformPrimaryButton(
          key: const Key('translation-review-approve-selected'),
          label: strings.tArgsKey(
            PlatformAdminKeys.pageTranslationReviewApproveSelected,
            <String, Object?>{'count': selectedIds.length},
          ),
          icon: Icons.check_rounded,
          isLoading: selectionBusy,
          onPressed: selectionBusy
              ? null
              : () => onApproveSelected(currentItems),
        ),
      );
    }
    if (pendingNonSafety > 0) {
      headerActions.add(
        PlatformSecondaryButton(
          key: const Key('translation-review-bulk-approve'),
          label: strings.tArgsKey(
            scope == ReviewScope.interfaceText
                ? PlatformAdminKeys.pageTranslationReviewBulkApproveCountUi
                : PlatformAdminKeys.pageTranslationReviewBulkApproveCount,
            <String, Object?>{'count': pendingNonSafety},
          ),
          icon: Icons.done_all_rounded,
          isLoading: bulkBusy,
          onPressed: bulkBusy ? null : onBulkApprove,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 1280
            ? 1280.0
            : constraints.maxWidth;
        return Row(
          // Stretch keeps the desk's height bounded so the rail and the panel
          // can each own their own scroll view.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            SizedBox(
              width: width,
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 24, pad, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlatformPageHeader(
                      title: strings.tKey(
                        PlatformAdminKeys.pageTranslationReviewTitle,
                      ),
                      subtitle: targets > 0
                          ? strings.tArgsKey(
                              PlatformAdminKeys
                                  .pageTranslationReviewSummaryCoverage,
                              <String, Object?>{
                                'language': _isolate(nativeName),
                                'translated': summary?.covered ?? 0,
                                'total': targets,
                                'pending': count ?? 0,
                              },
                            )
                          : '$nativeName${count == null ? '' : ' · $pendingLabel: $count'}',
                      actions: headerActions,
                    ),
                    _TranslationProgress(
                      strings: strings,
                      lang: language,
                      entityType: scope.entityType,
                    ),
                    if ((summary?.jobs.failed ?? 0) > 0)
                      _FailedJobsNotice(
                        strings: strings,
                        lang: language,
                        entityType: scope.entityType,
                        count: summary!.jobs.failed,
                      ),
                    const SizedBox(height: 12),
                    _Toolbar(
                      strings: strings,
                      languages: languages,
                      language: language,
                      filter: filter,
                      scope: scope,
                      onScope: onScope,
                      onLanguage: onLanguage,
                      onFilter: onFilter,
                      stateLabel: _stateLabel,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: queue.when(
                        loading: () => const _DeskSkeleton(),
                        error: (error, _) => PlatformErrorView(
                          message: strings.tKey(CommonKeys.stateError),
                          retryLabel: strings.tKey(CommonKeys.buttonRetry),
                          onRetry: onRetryQueue,
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            final notTranslatedYet =
                                filter == TranslationReviewState.pending &&
                                summaryTotal == 0 &&
                                missing > 0;
                            return PlatformEmptyView(
                              title: strings.tKey(
                                notTranslatedYet
                                    ? PlatformAdminKeys
                                          .pageTranslationReviewEmptyNotTranslatedTitle
                                    : PlatformAdminKeys
                                          .pageTranslationReviewEmptyTitle,
                              ),
                              body: notTranslatedYet
                                  ? strings.tArgsKey(
                                      PlatformAdminKeys
                                          .pageTranslationReviewEmptyNotTranslatedBody,
                                      <String, Object?>{
                                        'count': missing,
                                        'language': _isolate(nativeName),
                                      },
                                    )
                                  : strings.tKey(
                                      PlatformAdminKeys
                                          .pageTranslationReviewEmptyBody,
                                    ),
                              // Put the primary action where the message is,
                              // instead of making the admin find the header.
                              actionLabel: notTranslatedYet
                                  ? strings.tArgsKey(
                                      PlatformAdminKeys
                                          .pageTranslationReviewGenerateCount,
                                      <String, Object?>{'count': missing},
                                    )
                                  : strings.tKey(CommonKeys.buttonRefresh),
                              onAction: notTranslatedYet
                                  ? onGenerateTranslations
                                  : onRetryQueue,
                            );
                          }
                          final index = items.indexWhere(
                            (item) => item.id == selectedId,
                          );
                          final activeIndex = index < 0 ? 0 : index;
                          final item = items[activeIndex];
                          final stateTotal = switch (filter) {
                            TranslationReviewState.reviewed =>
                              summary?.countOf(
                                    TranslationReviewState.reviewed,
                                  ) ??
                                  0,
                            TranslationReviewState.stale =>
                              summary?.countOf(TranslationReviewState.stale) ??
                                  0,
                            _ => count ?? 0,
                          };
                          final pageStart = page * _kReviewPageSize + 1;
                          final pageEnd =
                              page * _kReviewPageSize + items.length;
                          final rail = _QueueRail(
                            strings: strings,
                            items: items,
                            selectedIndex: activeIndex,
                            busyId: busyId,
                            stateLabel: _stateLabel,
                            selectedIds: selectedIds,
                            allSelected:
                                items.isNotEmpty &&
                                items
                                    .where(_isActionable)
                                    .every(
                                      (candidate) =>
                                          selectedIds.contains(candidate.id),
                                    ),
                            onToggle: onToggleSelect,
                            onToggleSelectAll: () => onToggleSelectAll(items),
                            onSelect: onSelect,
                            horizontal: compact,
                            pageStart: pageStart,
                            pageEnd: pageEnd,
                            total: stateTotal,
                            onPrevious: page == 0
                                ? null
                                : () => onPage(page - 1),
                            onNext: pageEnd >= stateTotal
                                ? null
                                : () => onPage(page + 1),
                          );
                          final panel = _ReviewPanel(
                            strings: strings,
                            item: item,
                            position: activeIndex + 1,
                            total: items.length,
                            pageStart: pageStart,
                            stateTotal: stateTotal,
                            busy: busyId == item.id,
                            stateLabel: _stateLabel,
                            onApprove: () =>
                                onApprove(item, items, activeIndex),
                            onEdit: () => onEdit(item, items, activeIndex),
                            onReject: () => onReject(item, items, activeIndex),
                          );
                          final body = compact
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    rail,
                                    const SizedBox(height: 12),
                                    Expanded(child: panel),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(width: 288, child: rail),
                                    const SizedBox(width: 16),
                                    Expanded(child: panel),
                                  ],
                                );
                          // A/R/E act on the focused string; J/K move through
                          // the page. Plain letters only, so they never fight
                          // the dialog text fields (which own their focus).
                          final actionable = _isActionable(item);
                          return CallbackShortcuts(
                            bindings: <ShortcutActivator, VoidCallback>{
                              const SingleActivator(
                                LogicalKeyboardKey.keyJ,
                              ): () => onSelect(
                                items[(activeIndex + 1) % items.length].id,
                              ),
                              const SingleActivator(
                                LogicalKeyboardKey.keyK,
                              ): () => onSelect(
                                items[(activeIndex - 1 + items.length) %
                                        items.length]
                                    .id,
                              ),
                              const SingleActivator(
                                LogicalKeyboardKey.keyE,
                              ): () =>
                                  onEdit(item, items, activeIndex),
                              if (actionable) ...{
                                const SingleActivator(
                                  LogicalKeyboardKey.keyA,
                                ): () =>
                                    onApprove(item, items, activeIndex),
                                const SingleActivator(
                                  LogicalKeyboardKey.keyR,
                                ): () =>
                                    onReject(item, items, activeIndex),
                              },
                            },
                            child: Focus(autofocus: true, child: body),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

/// Machine-translation progress for the selected language + scope.
///
/// Renders nothing when no job is queued or running. While work is in flight it
/// refreshes the summary and the queue every few seconds, so "Pending: 0" is
/// never mistaken for "nothing is happening".
class _TranslationProgress extends ConsumerStatefulWidget {
  const _TranslationProgress({
    required this.strings,
    required this.lang,
    required this.entityType,
  });

  final UiMessageStrings strings;
  final String lang;
  final String entityType;

  @override
  ConsumerState<_TranslationProgress> createState() =>
      _TranslationProgressState();
}

class _TranslationProgressState extends ConsumerState<_TranslationProgress> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Poll whether or not work is running: a Generate pressed a second ago must
    // surface its banner without the admin hunting for Refresh.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      ref.invalidate(translationReviewSummaryProvider);
      ref.invalidate(translationReviewQueueProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref
        .watch(
          translationReviewSummaryProvider((
            lang: widget.lang,
            entityType: widget.entityType,
          )),
        )
        .asData
        ?.value;
    final jobs = summary?.jobs ?? const TranslationJobProgress.empty();
    if (jobs.active == 0) return const SizedBox.shrink();

    final strings = widget.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: PtTheme.deepGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PtTheme.deepGreen.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PtTheme.deepGreen,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewProgressTitle,
                    ),
                    style: PtTheme.font(
                      12,
                      lineHeight: 16,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: jobs.fraction,
                      minHeight: 4,
                      backgroundColor: PtTheme.border,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              strings.tArgsKey(
                PlatformAdminKeys.pageTranslationReviewProgressCount,
                <String, Object?>{'done': jobs.done, 'total': jobs.total},
              ),
              style: PtTheme.font(
                12,
                lineHeight: 16,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
            ),
            if (jobs.failed > 0) ...[
              const SizedBox(width: 10),
              Text(
                strings.tArgsKey(
                  PlatformAdminKeys.pageTranslationReviewProgressFailed,
                  <String, Object?>{'count': jobs.failed},
                ),
                style: PtTheme.font(
                  11.5,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                  color: PtTheme.rose,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The strings the provider could not translate, with a retry that requeues
/// them without spending another attempt.
class _FailedJobsNotice extends ConsumerWidget {
  const _FailedJobsNotice({
    required this.strings,
    required this.lang,
    required this.entityType,
    required this.count,
  });

  final UiMessageStrings strings;
  final String lang;
  final String entityType;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: PlatformSecondaryButton(
          key: const Key('translation-review-failed'),
          label: strings.tArgsKey(
            PlatformAdminKeys.pageTranslationReviewFailedView,
            <String, Object?>{'count': count},
          ),
          icon: Icons.error_outline_rounded,
          onPressed: () => _open(context, ref),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final retried = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _FailedJobsDialog(
        strings: strings,
        lang: lang,
        entityType: entityType,
      ),
    );
    if (retried == null || !context.mounted) return;
    ref.invalidate(translationReviewSummaryProvider);
    ref.invalidate(translationReviewQueueProvider);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          strings.tArgsKey(
            PlatformAdminKeys.pageTranslationReviewFailedRetried,
            <String, Object?>{'count': retried},
          ),
        ),
      ),
    );
  }
}

class _FailedJobsDialog extends ConsumerStatefulWidget {
  const _FailedJobsDialog({
    required this.strings,
    required this.lang,
    required this.entityType,
  });

  final UiMessageStrings strings;
  final String lang;
  final String entityType;

  @override
  ConsumerState<_FailedJobsDialog> createState() => _FailedJobsDialogState();
}

class _FailedJobsDialogState extends ConsumerState<_FailedJobsDialog> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final retried = await ref
          .read(platformConfigApiProvider)
          .retryFailedJobs(
            lang: widget.lang,
            entityType: widget.entityType.isEmpty ? null : widget.entityType,
          );
      if (!mounted) return;
      Navigator.of(context).pop(retried);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final jobs = ref.watch(
      failedTranslationJobsProvider((
        lang: widget.lang,
        entityType: widget.entityType,
      )),
    );
    return PlatformDialogShell(
      title: strings.tKey(PlatformAdminKeys.pageTranslationReviewFailedTitle),
      body: SizedBox(
        width: 640,
        height: 360,
        child: jobs.when(
          loading: () => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) =>
              Center(child: Text(strings.tKey(CommonKeys.stateError))),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewFailedEmpty,
                  ),
                  style: PtTheme.bodyMuted,
                ),
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final job = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.source.isEmpty ? job.entityId : job.source,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          12.5,
                          lineHeight: 17,
                          weight: FontWeight.w600,
                          color: PtTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${job.entityId} · ${_errorLabel(strings, job.error)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          11,
                          lineHeight: 15,
                          color: PtTheme.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        PlatformGhostButton(
          key: const Key('failed-jobs-close'),
          label: strings.tKey(CommonKeys.buttonClose),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        PlatformPrimaryButton(
          key: const Key('failed-jobs-retry'),
          label: strings.tKey(
            PlatformAdminKeys.pageTranslationReviewFailedRetry,
          ),
          isLoading: _busy,
          onPressed: _busy ? null : _retry,
        ),
      ],
    );
  }
}

/// The job error is a machine code with internal token names; the admin gets a
/// plain reason instead.
String _errorLabel(UiMessageStrings strings, String error) {
  if (error.startsWith('PLACEHOLDER_LOST')) {
    return strings.tKey(
      PlatformAdminKeys.pageTranslationReviewFailedErrorPlaceholder,
    );
  }
  return switch (error) {
    // Provider failure codes map to plain copy; they are not lifecycle states.
    // gate-allow: behaviour
    'TRUNCATED' => strings.tKey(
      PlatformAdminKeys.pageTranslationReviewFailedErrorTruncated,
    ),
    // gate-allow: behaviour
    'NO_CHANGE' => strings.tKey(
      PlatformAdminKeys.pageTranslationReviewFailedErrorNoChange,
    ),
    // gate-allow: behaviour
    'RATE_LIMITED' => strings.tKey(
      PlatformAdminKeys.pageTranslationReviewFailedErrorRateLimited,
    ),
    _ => strings.tKey(PlatformAdminKeys.pageTranslationReviewFailedErrorOther),
  };
}

/// Two-up segmented control that switches between content and interface text.
///
/// Deliberately different from the state filter chips below it: scope is a
/// mode (what am I translating), the chips are a filter (which rows).
class _ScopeSwitcher extends StatelessWidget {
  const _ScopeSwitcher({
    required this.strings,
    required this.scope,
    required this.onScope,
  });

  final UiMessageStrings strings;
  final ReviewScope scope;
  final ValueChanged<ReviewScope> onScope;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final candidate in ReviewScope.values)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: candidate == ReviewScope.values.first ? 0 : 3,
              ),
              child: _ScopeSegment(
                key: Key('translation-review-scope-${candidate.entityType}'),
                label: strings.tKey(candidate.labelKey),
                icon: candidate == ReviewScope.content
                    ? Icons.inventory_2_outlined
                    : Icons.text_fields_rounded,
                selected: scope == candidate,
                onTap: () => onScope(candidate),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScopeSegment extends StatelessWidget {
  const _ScopeSegment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? PtTheme.deepGreen : PtTheme.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: selected ? PtTheme.white : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? PtTheme.deepGreen.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: PtTheme.font(
                    12.5,
                    lineHeight: 16,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
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

/// Language picker + state filters, above the desk.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.strings,
    required this.languages,
    required this.language,
    required this.filter,
    required this.scope,
    required this.onScope,
    required this.onLanguage,
    required this.onFilter,
    required this.stateLabel,
  });

  final UiMessageStrings strings;
  final List<PlatformLanguage> languages;
  final String language;
  final String filter;
  final ReviewScope scope;
  final ValueChanged<ReviewScope> onScope;
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String> onFilter;
  final String Function(String) stateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ScopeSwitcher(strings: strings, scope: scope, onScope: onScope),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                strings.tKey(PlatformAdminKeys.pageTranslationReviewScopeHelp),
                style: PtTheme.bodyMuted.copyWith(fontSize: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 220,
              height: 78,
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
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final state in TranslationReviewState.filters) ...[
                        if (state != TranslationReviewState.filters.first)
                          const SizedBox(width: 8),
                        PlatformFilterChip(
                          key: Key('translation-review-filter-$state'),
                          label: stateLabel(state),
                          selected: filter == state,
                          onTap: () => onFilter(state),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The queue as a rail (vertical on desktop, chip strip on phones).
class _QueueRail extends StatelessWidget {
  const _QueueRail({
    required this.strings,
    required this.items,
    required this.selectedIndex,
    required this.busyId,
    required this.stateLabel,
    required this.selectedIds,
    required this.allSelected,
    required this.onToggle,
    required this.onToggleSelectAll,
    required this.onSelect,
    required this.horizontal,
    required this.pageStart,
    required this.pageEnd,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final UiMessageStrings strings;
  final List<TranslationReviewItem> items;
  final int selectedIndex;
  final String? busyId;
  final String Function(String) stateLabel;
  final Set<String> selectedIds;
  final bool allSelected;
  final ValueChanged<TranslationReviewItem> onToggle;
  final VoidCallback onToggleSelectAll;
  final ValueChanged<String> onSelect;
  final bool horizontal;
  final int pageStart;
  final int pageEnd;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final selectable = items.where(_isActionable).toList(growable: false);
    final pager = _QueuePager(
      strings: strings,
      pageStart: pageStart,
      pageEnd: pageEnd,
      total: total,
      onPrevious: onPrevious,
      onNext: onNext,
    );
    if (horizontal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (selectable.isNotEmpty) ...[
                  _SelectAllChip(
                    strings: strings,
                    allSelected: allSelected,
                    onTap: onToggleSelectAll,
                  ),
                  const SizedBox(width: 8),
                ],
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _RailChip(
                    item: items[i],
                    selected: i == selectedIndex,
                    checked: selectedIds.contains(items[i].id),
                    label: stateLabel(items[i].status),
                    onTap: () => onSelect(items[i].id),
                    onToggle: _isActionable(items[i])
                        ? () => onToggle(items[i])
                        : null,
                  ),
                ],
              ],
            ),
          ),
          if (total > items.length) ...[const SizedBox(height: 8), pager],
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            if (selectable.isNotEmpty) ...[
              _SelectAllRow(
                strings: strings,
                allSelected: allSelected,
                count: selectable.length,
                onTap: onToggleSelectAll,
              ),
              const Divider(height: 1, color: PtTheme.border),
            ],
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, i) => _RailRow(
                  item: items[i],
                  selected: i == selectedIndex,
                  checked: selectedIds.contains(items[i].id),
                  busy: busyId == items[i].id,
                  label: stateLabel(items[i].status),
                  onTap: () => onSelect(items[i].id),
                  onToggle: _isActionable(items[i])
                      ? () => onToggle(items[i])
                      : null,
                ),
              ),
            ),
            if (total > items.length) ...[
              const Divider(height: 1, color: PtTheme.border),
              pager,
            ],
          ],
        ),
      ),
    );
  }
}

/// "‹ 1–50 of 3913 ›": the rail only ever holds one page, so the pager must say
/// how much of the language is still outside it.
class _QueuePager extends StatelessWidget {
  const _QueuePager({
    required this.strings,
    required this.pageStart,
    required this.pageEnd,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final UiMessageStrings strings;
  final int pageStart;
  final int pageEnd;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 6, 6),
      child: Row(
        children: [
          _PagerButton(
            key: const Key('translation-review-page-prev'),
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          Expanded(
            child: Text(
              strings.tArgsKey(
                PlatformAdminKeys.pageTranslationReviewPageRange,
                <String, Object?>{
                  'start': pageStart,
                  'end': pageEnd,
                  'total': total,
                },
              ),
              textAlign: TextAlign.center,
              style: PtTheme.font(
                11.5,
                lineHeight: 16,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
          ),
          _PagerButton(
            key: const Key('translation-review-page-next'),
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PtTheme.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? PtTheme.ink : PtTheme.border,
        ),
      ),
    );
  }
}

class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({
    required this.strings,
    required this.allSelected,
    required this.count,
    required this.onTap,
  });

  final UiMessageStrings strings;
  final bool allSelected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 12, 2),
        child: Row(
          children: [
            IgnorePointer(
              child: Checkbox(
                value: allSelected,
                onChanged: (_) {},
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: PtTheme.deepGreen,
              ),
            ),
            Expanded(
              child: Text(
                strings.tKey(PlatformAdminKeys.pageTranslationReviewSelectAll),
                style: PtTheme.font(12, weight: FontWeight.w700),
              ),
            ),
            Text(
              '$count',
              style: PtTheme.font(
                11,
                weight: FontWeight.w700,
                color: PtTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectAllChip extends StatelessWidget {
  const _SelectAllChip({
    required this.strings,
    required this.allSelected,
    required this.onTap,
  });

  final UiMessageStrings strings;
  final bool allSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PtTheme.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: 4,
            end: 14,
            top: 5,
            bottom: 5,
          ),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) {},
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: PtTheme.deepGreen,
                ),
              ),
              Text(
                strings.tKey(PlatformAdminKeys.pageTranslationReviewSelectAll),
                style: PtTheme.font(12, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row can be acted on unless it is already approved.
bool _isActionable(TranslationReviewItem item) => item.status != 'REVIEWED';

/// Queue page size; must match the API call below and the pager copy.
const int _kReviewPageSize = 50;

/// Wraps a language name in a first-strong isolate so an Arabic (or any RTL)
/// name does not scramble the order of a Latin sentence around it.
String _isolate(String value) => '\u2068$value\u2069';

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.item,
    required this.selected,
    required this.checked,
    required this.busy,
    required this.label,
    required this.onTap,
    this.onToggle,
  });

  final TranslationReviewItem item;
  final bool selected;
  final bool checked;
  final bool busy;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final title = item.sourceText.isEmpty ? item.field : item.sourceText;
    return Semantics(
      button: true,
      selected: selected,
      checked: checked,
      label: title,
      child: Material(
        key: Key('translation-review-row-${item.id}'),
        color: selected
            ? PtTheme.deepGreen.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 12, 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: PtTheme.border.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggle != null)
                  Checkbox(
                    value: checked,
                    onChanged: (_) => onToggle!(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: PtTheme.deepGreen,
                  )
                else
                  const SizedBox(width: 40, height: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          12.5,
                          lineHeight: 17,
                          weight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? PtTheme.deepGreen : PtTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PtTheme.font(
                                11,
                                lineHeight: 15,
                                weight: FontWeight.w600,
                                color: PtTheme.muted,
                              ),
                            ),
                          ),
                          if (item.safetyCritical)
                            const Icon(
                              Icons.shield_outlined,
                              size: 13,
                              color: PtTheme.rose,
                            ),
                          if (busy) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _RailChip extends StatelessWidget {
  const _RailChip({
    required this.item,
    required this.selected,
    required this.checked,
    required this.label,
    required this.onTap,
    this.onToggle,
  });

  final TranslationReviewItem item;
  final bool selected;
  final bool checked;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  /// A queue chip has to say *which string* it is; the state is the panel's
  /// job. Long sources are clipped to a readable stub.
  String get _snippet {
    final text = item.sourceText.isEmpty
        ? reviewFieldLabel(item.field)
        : item.sourceText;
    if (text.length <= 26) return text;
    return '${text.substring(0, 26).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: _snippet,
      child: Material(
        key: Key('translation-review-row-${item.id}'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: selected ? PtTheme.ink : PtTheme.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? PtTheme.ink : PtTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onToggle != null)
                  Checkbox(
                    value: checked,
                    onChanged: (_) => onToggle!(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: PtTheme.deepGreen,
                    checkColor: PtTheme.white,
                    side: BorderSide(
                      color: selected ? PtTheme.white : PtTheme.muted,
                    ),
                  ),
                const SizedBox(width: 4),
                if (item.safetyCritical) ...[
                  Icon(
                    Icons.shield_outlined,
                    size: 13,
                    color: selected ? PtTheme.white : PtTheme.rose,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  _snippet,
                  textDirection: TextDirection.ltr,
                  style: PtTheme.font(
                    12.5,
                    lineHeight: 17,
                    weight: FontWeight.w600,
                    color: selected ? PtTheme.white : PtTheme.ink,
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

/// One focused string with its decision bar.
class _ReviewPanel extends ConsumerWidget {
  const _ReviewPanel({
    required this.strings,
    required this.item,
    required this.position,
    required this.total,
    required this.pageStart,
    required this.stateTotal,
    required this.busy,
    required this.stateLabel,
    required this.onApprove,
    required this.onEdit,
    required this.onReject,
  });

  final UiMessageStrings strings;
  final TranslationReviewItem item;
  final int position;
  final int total;
  final int pageStart;
  final int stateTotal;
  final bool busy;
  final String Function(String) stateLabel;
  final VoidCallback onApprove;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(enumsProvider(contentTypeEnum)).value;
    final isUiMessage = item.entityType == interfaceTextScopeType;
    final approved = item.status == 'REVIEWED';
    final entityLabel = isUiMessage
        ? strings.tKey(
            PlatformAdminKeys.pageTranslationReviewScopeInterfaceText,
          )
        : referenceCodeLabel(strings, types, item.entityType);
    final detail = isUiMessage ? item.entityId : reviewFieldLabel(item.field);
    final source = item.sourceText.isEmpty ? item.field : item.sourceText;
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.safetyCritical
              ? PtTheme.rose.withValues(alpha: 0.35)
              : PtTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PlatformStatusChip(
                        status: item.status,
                        label: stateLabel(item.status),
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
                  const SizedBox(height: 14),
                  Text(
                    strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewColumnSource,
                    ),
                    style: PtTheme.font(
                      10.5,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source,
                    // Source copy is English; an RTL paragraph direction would
                    // push its closing punctuation to the wrong end.
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: PtTheme.font(
                      19,
                      lineHeight: 28,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: approved
                          ? PtTheme.deepGreen.withValues(alpha: 0.07)
                          : PtTheme.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tKey(
                            approved
                                ? PlatformAdminKeys
                                      .pageTranslationReviewColumnApproved
                                : PlatformAdminKeys
                                      .pageTranslationReviewColumnMachine,
                          ),
                          style: PtTheme.font(
                            10.5,
                            lineHeight: 14,
                            weight: FontWeight.w700,
                            color: approved ? PtTheme.deepGreen : PtTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.body.isEmpty ? '—' : item.body,
                          // The body is in the target language, so its
                          // direction comes from the language, not the UI.
                          textDirection: reviewDirection(item.lang),
                          textAlign: TextAlign.start,
                          style: PtTheme.font(
                            14.5,
                            lineHeight: 22,
                            weight: FontWeight.w500,
                            color: PtTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.provider.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${strings.tKey(PlatformAdminKeys.pageTranslationReviewColumnProvider)}'
                      ' · ${item.provider}',
                      style: PtTheme.font(
                        11.5,
                        lineHeight: 16,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                  if (item.reviewNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.reviewNote,
                      style: PtTheme.font(
                        12,
                        lineHeight: 18,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tArgsKey(
                          PlatformAdminKeys.pageTranslationReviewPosition,
                          <String, Object?>{
                            'index': position,
                            'total': total,
                            'scopeTotal': stateTotal,
                          },
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: PtTheme.font(
                          11.5,
                          lineHeight: 16,
                          weight: FontWeight.w600,
                          color: PtTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$entityLabel · $detail',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: PtTheme.font(
                          11.5,
                          lineHeight: 16,
                          weight: FontWeight.w600,
                          color: PtTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PtTheme.border)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (MediaQuery.sizeOf(context).width >= 860)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.pageTranslationReviewShortcuts,
                      ),
                      style: PtTheme.font(
                        11,
                        lineHeight: 15,
                        color: PtTheme.muted,
                      ),
                    ),
                  ),
                if (!approved)
                  PlatformDestructiveButton(
                    key: const Key('translation-review-reject'),
                    label: strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewActionReject,
                    ),
                    onPressed: busy ? null : onReject,
                  ),
                PlatformSecondaryButton(
                  key: const Key('translation-review-edit'),
                  label: strings.tKey(
                    PlatformAdminKeys.pageTranslationReviewActionEdit,
                  ),
                  onPressed: busy ? null : onEdit,
                ),
                if (!approved)
                  PlatformPrimaryButton(
                    key: const Key('translation-review-approve'),
                    label: strings.tKey(
                      PlatformAdminKeys.pageTranslationReviewActionApprove,
                    ),
                    icon: Icons.check_rounded,
                    isLoading: busy,
                    onPressed: busy ? null : onApprove,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shaped placeholders — never a spinner for a page-level load.
class _DeskSkeleton extends StatelessWidget {
  const _DeskSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: PtTheme.border.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 288,
          child: Container(
            decoration: BoxDecoration(
              color: PtTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PtTheme.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 6; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  bar(200, 12),
                  const SizedBox(height: 6),
                  bar(80, 10),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: PtTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PtTheme.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(120, 26),
                const SizedBox(height: 18),
                bar(320, 22),
                const SizedBox(height: 10),
                bar(260, 22),
                const SizedBox(height: 18),
                bar(double.infinity, 76),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
