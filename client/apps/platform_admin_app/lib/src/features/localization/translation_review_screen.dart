import 'package:core/core.dart';
import 'package:flutter/material.dart';
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
  const TranslationReviewScreen({this.initialLanguage, super.key});

  final String? initialLanguage;

  @override
  ConsumerState<TranslationReviewScreen> createState() =>
      _TranslationReviewScreenState();
}

class _TranslationReviewScreenState
    extends ConsumerState<TranslationReviewScreen> {
  String? _busyId;
  String? _selectedId;

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
      translationReviewQueueProvider((lang: active, state: filter)),
    );
    final summary = ref.watch(translationReviewSummaryProvider(active));

    return PlatformShell(
      currentRoute: '/configuration/translations',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageProfileTitle),
            onTap: () => context.go('/settings'),
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
            onLanguage: (value) {
              if (value == null) return;
              setState(() => _selectedId = null);
              ref
                  .read(translationReviewLanguageProvider.notifier)
                  .select(value);
            },
            onFilter: (value) {
              setState(() => _selectedId = null);
              ref.read(translationReviewStateProvider.notifier).select(value);
            },
            summary: summary.asData?.value,
            queue: queue,
            selectedId: _selectedId,
            onSelect: (id) => setState(() => _selectedId = id),
            busyId: _busyId,
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
    required this.onLanguage,
    required this.onFilter,
    required this.summary,
    required this.queue,
    required this.selectedId,
    required this.onSelect,
    required this.busyId,
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
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String> onFilter;
  final TranslationReviewSummary? summary;
  final AsyncValue<List<TranslationReviewItem>> queue;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final String? busyId;
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
                      subtitle:
                          '$nativeName${count == null ? '' : ' · $pendingLabel: $count'}',
                    ),
                    const SizedBox(height: 12),
                    _Toolbar(
                      strings: strings,
                      languages: languages,
                      language: language,
                      filter: filter,
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
                            return PlatformEmptyView(
                              title: strings.tKey(
                                PlatformAdminKeys
                                    .pageTranslationReviewEmptyTitle,
                              ),
                              body: strings.tKey(
                                PlatformAdminKeys
                                    .pageTranslationReviewEmptyBody,
                              ),
                              actionLabel: strings.tKey(
                                CommonKeys.buttonRefresh,
                              ),
                              onAction: onRetryQueue,
                            );
                          }
                          final index = items.indexWhere(
                            (item) => item.id == selectedId,
                          );
                          final activeIndex = index < 0 ? 0 : index;
                          final item = items[activeIndex];
                          final rail = _QueueRail(
                            strings: strings,
                            items: items,
                            selectedIndex: activeIndex,
                            busyId: busyId,
                            stateLabel: _stateLabel,
                            onSelect: onSelect,
                            horizontal: compact,
                          );
                          final panel = _ReviewPanel(
                            strings: strings,
                            item: item,
                            position: activeIndex + 1,
                            total: items.length,
                            busy: busyId == item.id,
                            stateLabel: _stateLabel,
                            onApprove: () =>
                                onApprove(item, items, activeIndex),
                            onEdit: () => onEdit(item, items, activeIndex),
                            onReject: () => onReject(item, items, activeIndex),
                          );
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                rail,
                                const SizedBox(height: 12),
                                Expanded(child: panel),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 288, child: rail),
                              const SizedBox(width: 16),
                              Expanded(child: panel),
                            ],
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

/// Language picker + state filters, above the desk.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.strings,
    required this.languages,
    required this.language,
    required this.filter,
    required this.onLanguage,
    required this.onFilter,
    required this.stateLabel,
  });

  final UiMessageStrings strings;
  final List<PlatformLanguage> languages;
  final String language;
  final String filter;
  final ValueChanged<String?> onLanguage;
  final ValueChanged<String> onFilter;
  final String Function(String) stateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    required this.onSelect,
    required this.horizontal,
  });

  final UiMessageStrings strings;
  final List<TranslationReviewItem> items;
  final int selectedIndex;
  final String? busyId;
  final String Function(String) stateLabel;
  final ValueChanged<String> onSelect;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _RailChip(
                item: items[i],
                selected: i == selectedIndex,
                label: stateLabel(items[i].status),
                onTap: () => onSelect(items[i].id),
              ),
            ],
          ],
        ),
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
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, i) => _RailRow(
            item: items[i],
            selected: i == selectedIndex,
            busy: busyId == items[i].id,
            label: stateLabel(items[i].status),
            onTap: () => onSelect(items[i].id),
          ),
        ),
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.item,
    required this.selected,
    required this.busy,
    required this.label,
    required this.onTap,
  });

  final TranslationReviewItem item;
  final bool selected;
  final bool busy;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.sourceText.isEmpty ? item.field : item.sourceText;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        key: Key('translation-review-row-${item.id}'),
        color: selected
            ? PtTheme.deepGreen.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 11, 12, 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: PtTheme.border.withValues(alpha: 0.7),
                ),
              ),
            ),
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
                        child: CircularProgressIndicator(strokeWidth: 1.6),
                      ),
                    ],
                  ],
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
    required this.label,
    required this.onTap,
  });

  final TranslationReviewItem item;
  final bool selected;
  final String label;
  final VoidCallback onTap;

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
  final bool busy;
  final String Function(String) stateLabel;
  final VoidCallback onApprove;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(enumsProvider(contentTypeEnum)).value;
    final entityLabel = referenceCodeLabel(strings, types, item.entityType);
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
                      color: PtTheme.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tKey(
                            PlatformAdminKeys
                                .pageTranslationReviewColumnMachine,
                          ),
                          style: PtTheme.font(
                            10.5,
                            lineHeight: 14,
                            weight: FontWeight.w700,
                            color: PtTheme.gold,
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
                        '${strings.tArgsKey(PlatformAdminKeys.referencePositionLabel, <String, Object?>{'index': '$position', 'total': '$total'})} · $entityLabel · ${reviewFieldLabel(item.field)}',
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
              children: [
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
