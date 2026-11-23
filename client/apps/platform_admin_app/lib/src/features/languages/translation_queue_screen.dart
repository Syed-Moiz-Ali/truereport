import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../components/platform_toolbar.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../platform_translations.dart';
import '../../reference_status_lookup.dart';
import 'language_cards.dart';

import 'package:reference_data/reference_data.dart';

/// Dedicated translation work queue for one language.
///
/// Route: `/settings/languages/:code/translations` (registered by the
/// router owner). This is the single source of truth for completing a
/// language: header with coverage + publish gate, summary cards, filters,
/// per-entity groups rendered dynamically from the backlog, inline editing
/// with next/previous navigation, bulk approve, and JSON export. New
/// languages start as DRAFT and become selectable everywhere only after
/// publish moves them to LIVE.
///
/// The publish action lives in the context bar above the scrollable page so
/// it stays reachable (sticky) while working through long queues.
class TranslationQueueScreen extends ConsumerStatefulWidget {
  const TranslationQueueScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  ConsumerState<TranslationQueueScreen> createState() =>
      _TranslationQueueScreenState();
}

class _TranslationQueueScreenState
    extends ConsumerState<TranslationQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final backlog = ref.watch(languageBacklogProvider(widget.languageCode));
    final languagesAsync = ref.watch(platformLanguagesProvider);
    PlatformLanguage? language;
    if (languagesAsync case AsyncData(:final value)) {
      for (final entry in value) {
        if (entry.code == widget.languageCode) language = entry;
      }
    }
    final nativeName = language != null && language.nativeName.isNotEmpty
        ? language.nativeName
        : widget.languageCode;
    return PlatformShell(
      currentRoute: '/settings/languages',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageProfileTitle),
            onTap: () => context.go('/settings'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.sectionLanguagesCoverage),
            onTap: () => context.go('/settings/languages'),
          ),
          ContextBreadcrumbItem(label: widget.languageCode),
        ],
      ),
      // The data branch owns its own bounded layout (fixed header + scrolling
      // ledger + pinned action bar), so it must not sit inside a scroll view.
      // Loading and error keep the plain scrolling page.
      child: backlog.when(
        loading: () => const PlatformPage(child: PlatformLoadingView()),
        error: (error, stackTrace) => PlatformPage(
          child: PlatformErrorView(
            message: strings.tKey(CommonKeys.stateError),
            retryLabel: strings.tKey(CommonKeys.buttonRetry),
            onRetry: () {
              ref.invalidate(languageBacklogProvider(widget.languageCode));
              ref.invalidate(platformLanguagesProvider);
            },
          ),
        ),
        data: (data) => _QueueBody(
          backlog: data,
          languageCode: widget.languageCode,
          nativeName: nativeName,
          registryStatus: language?.status,
        ),
      ),
    );
  }
}

String _entityLabel(
  UiMessageStrings strings,
  Iterable<ReferenceRecord>? records,
  String entityType,
) => referenceCodeLabel(strings, records, entityType);

String _itemStatusLabel(UiMessageStrings strings, String status) {
  switch (status) {
    case TranslationStatus.approved:
      return strings.tKey(PlatformAdminKeys.queueApproved);
    case TranslationStatus.reviewed:
      return strings.tKey(PlatformAdminKeys.queueReviewed);
    case TranslationStatus.draft:
    case TranslationStatus.translating:
      return strings.tKey(PlatformAdminKeys.queueDraft);
    case TranslationStatus.missing:
    default:
      return strings.tKey(PlatformAdminKeys.queueMissing);
  }
}

String _languageStatusLabel(
  UiMessageStrings strings,
  Iterable<ReferenceRecord>? records,
  String status,
) => referenceCodeLabel(strings, records, status);

class _QueueBody extends ConsumerStatefulWidget {
  const _QueueBody({
    required this.backlog,
    required this.languageCode,
    required this.nativeName,
    required this.registryStatus,
  });

  final TranslationBacklog backlog;
  final String languageCode;
  final String nativeName;
  final String? registryStatus;

  @override
  ConsumerState<_QueueBody> createState() => _QueueBodyState();
}

class _QueueBodyState extends ConsumerState<_QueueBody> {
  static const String _allTypes = 'ALL';

  final TextEditingController _searchController = TextEditingController();
  String _entityFilter = _allTypes;
  String _search = '';
  bool _missingOnly = false;
  final Set<String> _selected = <String>{};
  bool _bulkSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TranslationItem> _filtered() {
    final query = _search.trim().toLowerCase();
    return widget.backlog.allItems
        .where((item) {
          if (_entityFilter != _allTypes &&
              item.entityType.toUpperCase() != _entityFilter) {
            return false;
          }
          if (_missingOnly && !item.isMissing) return false;
          if (query.isNotEmpty) {
            final haystack =
                '${item.entityCode} ${item.field} ${item.defaultText} ${item.text ?? ''}'
                    .toLowerCase();
            if (!haystack.contains(query)) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  ({int missing, int draft, int reviewed, int approved}) _counts() {
    var missing = 0;
    var draft = 0;
    var reviewed = 0;
    var approved = 0;
    for (final item in widget.backlog.allItems) {
      switch (item.status) {
        case TranslationStatus.approved:
          approved++;
        case TranslationStatus.reviewed:
          reviewed++;
        case TranslationStatus.missing:
          missing++;
        default:
          // DRAFT + TRANSLATING fold into the Draft card (only five summary
          // cards exist: Missing/Draft/Reviewed/Approved/Total).
          draft++;
      }
    }
    return (
      missing: missing,
      draft: draft,
      reviewed: reviewed,
      approved: approved,
    );
  }

  Future<void> _openEditor(List<TranslationItem> items, int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: _TranslationEditorDialog(
          items: items,
          startIndex: index,
          languageCode: widget.languageCode,
        ),
      ),
    );
    if (!mounted) return;
    // Saves already invalidated these from inside the dialog; refresh once
    // more so a save racing the dialog close is never lost.
    ref.invalidate(languageBacklogProvider(widget.languageCode));
    ref.invalidate(languageCoverageProvider(widget.languageCode));
  }

  Future<void> _approveSelected(List<TranslationItem> filtered) async {
    final strings = ref.read(uiStringsProvider);
    final targets = filtered
        .where(
          (item) =>
              _selected.contains(item.key) &&
              (item.text != null && item.text!.trim().isNotEmpty),
        )
        .toList(growable: false);
    if (targets.isEmpty || _bulkSaving) return;
    setState(() => _bulkSaving = true);
    var done = 0;
    try {
      final api = ref.read(translationApiProvider);
      for (final item in targets) {
        await api.upsertTranslation(
          entityType: item.entityType,
          entityId: item.entityId,
          field: item.field,
          language: widget.languageCode,
          text: item.text!.trim(),
          status: TranslationStatus.approved,
        );
        done++;
      }
    } on AppFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tKey(CommonKeys.stateError))),
      );
    } finally {
      if (mounted) setState(() => _bulkSaving = false);
    }
    if (!mounted) return;
    setState(() => _selected.clear());
    ref.invalidate(languageBacklogProvider(widget.languageCode));
    ref.invalidate(languageCoverageProvider(widget.languageCode));
    if (mounted && done > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.tKey(PlatformAdminKeys.buttonQueueApproveSelected)}: $done',
          ),
        ),
      );
    }
  }

  Future<void> _export(List<TranslationItem> filtered) async {
    final strings = ref.read(uiStringsProvider);
    final missing = filtered
        .where((item) => item.isMissing)
        .map((item) => item.toJson())
        .toList(growable: false);
    final payload = const JsonEncoder.withIndent('  ')
        .convert({'language': widget.languageCode, 'missing': missing});
    try {
      await Clipboard.setData(ClipboardData(text: payload));
    } catch (_) {
      // Clipboard is unavailable in some test/embedded shells; the payload
      // is still shown in the confirmation snackbar path below.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${strings.tKey(PlatformAdminKeys.buttonQueueExport)}: ${strings.tKey(CommonKeys.labelDone)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final contentTypes = ref.watch(enumsProvider(contentTypeEnum)).value;
    final translationStatuses = ref
        .watch(statusesProvider(translationStatusDomain))
        .value;
    final backlog = widget.backlog;
    final filtered = _filtered();
    final counts = _counts();
    final status = widget.registryStatus ?? backlog.languageStatus;
    final entityTypes =
        backlog.groups
            .map((group) => group.entityType.toUpperCase())
            .toSet()
            .toList(growable: false)
          ..sort();

    final percent = backlog.totalRequired == 0
        ? 0.0
        : (backlog.approvedCount / backlog.totalRequired)
              .clamp(0, 1)
              .toDouble();
    final compact = MediaQuery.sizeOf(context).width < 700;
    final pad = compact ? 16.0 : 24.0;
    final hasSelection = _selected.isNotEmpty;

    Widget listBody;
    if (backlog.totalRequired == 0) {
      listBody = PlatformEmptyView(
        icon: Icons.translate_rounded,
        title: strings.tKey(PlatformAdminKeys.emptyQueueTitle),
        body: strings.tKey(PlatformAdminKeys.emptyQueueBody),
      );
    } else if (filtered.isEmpty) {
      if (_missingOnly && !backlog.allItems.any((item) => item.isMissing)) {
        listBody = PlatformEmptyView(
          icon: Icons.translate_rounded,
          title: strings.tKey(PlatformAdminKeys.emptyQueueTitle),
          body: strings.tKey(PlatformAdminKeys.emptyQueueBody),
        );
      } else {
        listBody = PlatformEmptyView(
          icon: Icons.search_off_rounded,
          title: strings.tKey(CommonKeys.emptyTitle),
        );
      }
    } else {
      listBody = LanguageLedger(
        children: [
          for (final group in backlog.groups)
            if (_entityFilter == _allTypes ||
                group.entityType.toUpperCase() == _entityFilter)
              Builder(
                builder: (context) {
                  final rows = filtered
                      .where(
                        (item) =>
                            item.entityType.toUpperCase() ==
                            group.entityType.toUpperCase(),
                      )
                      .toList(growable: false);
                  if (rows.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          14,
                          16,
                          6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _entityLabel(
                                  strings,
                                  contentTypes,
                                  group.entityType,
                                ),
                                style: PtTheme.font(
                                  13,
                                  lineHeight: 18,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${group.approved}/${group.total}',
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
                      for (var i = 0; i < rows.length; i++)
                        _QueueRow(
                          item: rows[i],
                          selected: _selected.contains(rows[i].key),
                          onSelected: (value) => setState(() {
                            if (value == true) {
                              _selected.add(rows[i].key);
                            } else {
                              _selected.remove(rows[i].key);
                            }
                          }),
                          onEdit: () =>
                              _openEditor(filtered, filtered.indexOf(rows[i])),
                        ),
                    ],
                  );
                },
              ),
        ],
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformPageHeader(
                title: strings.tKey(
                  PlatformAdminKeys.pageTranslationQueueTitle,
                ),
                subtitle:
                    '${widget.nativeName} · ${_languageStatusLabel(strings, translationStatuses, status)} · ${(percent * 100).round()}%',
                actions: [
                  PlatformSecondaryButton(
                    label: strings.tKey(PlatformAdminKeys.buttonQueueExport),
                    icon: Icons.ios_share_rounded,
                    onPressed: _bulkSaving ? null : () => _export(filtered),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LanguageCardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(percent * 100).round()}%',
                          style:
                              PtTheme.font(
                                44,
                                lineHeight: 44,
                                weight: FontWeight.w800,
                              ).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${backlog.approvedCount} ${strings.tKey(PlatformAdminKeys.queueApproved)} · ${counts.missing} ${strings.tKey(PlatformAdminKeys.queueMissing)}',
                              style: PtTheme.font(
                                12.5,
                                lineHeight: 18,
                                weight: FontWeight.w600,
                                color: PtTheme.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LanguageCoverageMeter(value: percent),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    label: strings.tKey(PlatformAdminKeys.queueMissing),
                    value: counts.missing,
                  ),
                  _SummaryCard(
                    label: strings.tKey(PlatformAdminKeys.queueDraft),
                    value: counts.draft,
                  ),
                  _SummaryCard(
                    label: strings.tKey(PlatformAdminKeys.queueReviewed),
                    value: counts.reviewed,
                  ),
                  _SummaryCard(
                    label: strings.tKey(PlatformAdminKeys.queueApproved),
                    value: counts.approved,
                  ),
                  _SummaryCard(
                    label: strings.tKey(PlatformAdminKeys.queueTotal),
                    value: backlog.totalRequired,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PlatformToolbar(
                searchController: _searchController,
                searchHint: strings.tKey(PlatformAdminKeys.filterQueueSearch),
                onSearchChanged: (value) => setState(() => _search = value),
                filters: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: PlatformDropdown<String>(
                      label: strings.tKey(
                        PlatformAdminKeys.tableQueueEntityType,
                      ),
                      value: _entityFilter,
                      items: [
                        DropdownMenuItem(
                          value: _allTypes,
                          child: Text(strings.tKey(CommonKeys.filterAll)),
                        ),
                        for (final type in entityTypes)
                          DropdownMenuItem(
                            value: type,
                            child: Text(
                              _entityLabel(strings, contentTypes, type),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _entityFilter = value);
                      },
                    ),
                  ),
                  PlatformFilterChip(
                    label: strings.tKey(
                      PlatformAdminKeys.filterQueueMissingOnly,
                    ),
                    selected: _missingOnly,
                    onTap: () => setState(() => _missingOnly = !_missingOnly),
                  ),
                ],
                countLabel:
                    '${strings.tKey(PlatformAdminKeys.queueTotal)}: ${filtered.length}',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: hasSelection ? 96 : 0),
                      child: listBody,
                    ),
                    if (hasSelection)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _QueueActionBar(
                          count: _selected.length,
                          saving: _bulkSaving,
                          onClear: () => setState(() => _selected.clear()),
                          onApprove: () => _approveSelected(filtered),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky bulk-action bar for the queue (Direction A).
///
/// Appears when at least one row is selected. Same house chrome as the rest:
/// one bordered card, tabular count, ghost Clear, primary Approve.
class _QueueActionBar extends ConsumerWidget {
  const _QueueActionBar({
    required this.count,
    required this.saving,
    required this.onClear,
    required this.onApprove,
  });

  final int count;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.tArgsKey(
                PlatformAdminKeys.queueSelectedCount,
                <String, Object?>{'count': '$count'},
              ),
              style: PtTheme.font(13, lineHeight: 18, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          PlatformGhostButton(
            key: const Key('btn-queue-clear-selection'),
            label: strings.tKey(PlatformAdminKeys.queueClearSelection),
            onPressed: saving ? null : onClear,
          ),
          const SizedBox(width: 8),
          PlatformPrimaryButton(
            key: const Key('btn-queue-approve-selected'),
            label: strings.tKey(PlatformAdminKeys.buttonQueueApproveSelected),
            icon: Icons.check_rounded,
            isLoading: saving,
            onPressed: saving ? null : onApprove,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PtTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: PtTheme.font(
                28,
                lineHeight: 32,
                weight: FontWeight.w800,
                color: PtTheme.ink,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
  });

  final TranslationItem item;
  final bool selected;
  final ValueChanged<bool?> onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    final translation = (item.text ?? '').trim();
    final missing = translation.isEmpty;
    return Semantics(
      button: true,
      selected: selected,
      label: item.defaultText,
      child: Material(
        color: selected
            ? PtTheme.deepGreen.withValues(alpha: 0.06)
            : Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LedgerCheckbox(
                  selected: selected,
                  onTap: () => onSelected(!selected),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: PtTheme.canvas,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.entityCode.isEmpty
                                  ? '${item.entityType} · ${item.field}'
                                  : '${item.entityCode} · ${item.field}',
                              style: PtTheme.font(
                                10.5,
                                lineHeight: 14,
                                weight: FontWeight.w700,
                                color: PtTheme.muted,
                              ),
                            ),
                          ),
                          PlatformStatusChip(
                            status: _itemStatusLabel(strings, item.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.defaultText.isEmpty ? '—' : item.defaultText,
                        style: PtTheme.font(
                          14,
                          lineHeight: 20,
                          weight: FontWeight.w600,
                          color: PtTheme.ink,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        missing ? 'Not translated yet' : translation,
                        style: PtTheme.font(
                          13,
                          lineHeight: 19,
                          weight: FontWeight.w400,
                          color: missing ? PtTheme.muted : PtTheme.ink,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: strings.tKey(PlatformAdminKeys.dialogQueueEditTitle),
                  onPressed: onEdit,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded 22px selection box — the house checkbox, not Material's square.
class _LedgerCheckbox extends StatelessWidget {
  const _LedgerCheckbox({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: selected ? PtTheme.deepGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? PtTheme.deepGreen : PtTheme.border,
              width: 1.5,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
class _TranslationEditorDialog extends ConsumerStatefulWidget {
  const _TranslationEditorDialog({
    required this.items,
    required this.startIndex,
    required this.languageCode,
  });

  final List<TranslationItem> items;
  final int startIndex;
  final String languageCode;

  @override
  ConsumerState<_TranslationEditorDialog> createState() =>
      _TranslationEditorDialogState();
}

class _TranslationEditorDialogState
    extends ConsumerState<_TranslationEditorDialog> {
  late List<TranslationItem> _items;
  late int _index;
  late TextEditingController _textController;
  late String _status;
  bool _saving = false;

  static String _initialStatus(TranslationItem item) {
    switch (item.status) {
      case TranslationStatus.approved:
        return TranslationStatus.approved;
      case TranslationStatus.reviewed:
        return TranslationStatus.reviewed;
      default:
        return TranslationStatus.draft;
    }
  }

  @override
  void initState() {
    super.initState();
    _items = List<TranslationItem>.of(widget.items);
    _index = widget.startIndex.clamp(0, _items.length - 1);
    _textController = TextEditingController(text: _items[_index].text ?? '');
    _status = _initialStatus(_items[_index]);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _moveTo(int next) {
    if (next < 0 || next >= _items.length || _saving) return;
    setState(() {
      _index = next;
      _textController.text = _items[next].text ?? '';
      _status = _initialStatus(_items[next]);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final item = _items[_index];
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(translationApiProvider)
          .upsertTranslation(
            entityType: item.entityType,
            entityId: item.entityId,
            field: item.field,
            language: widget.languageCode,
            text: _textController.text.trim(),
            status: _status,
          );
      setState(() {
        _items[_index] = updated;
      });
      // Refresh the queue underneath the dialog so counts, filters and rows
      // stay consistent while the editor remains open.
      ref.invalidate(languageBacklogProvider(widget.languageCode));
      ref.invalidate(languageCoverageProvider(widget.languageCode));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ProviderScope.containerOf(context)
                .read(uiStringsProvider)
                .tKey(CommonKeys.stateError),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final item = _items[_index];
    return PlatformDialogShell(
      title: strings.tKey(PlatformAdminKeys.dialogQueueEditTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformMetaPill(
                label: item.entityCode.isEmpty
                    ? item.entityType
                    : item.entityCode,
                value: item.field,
              ),
              PlatformStatusChip(
                status: _itemStatusLabel(strings, item.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strings.tKey(PlatformAdminKeys.tableQueueDefaultText),
            style: PtTheme.font(
              12,
              weight: FontWeight.w700,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.defaultText.isEmpty ? '—' : item.defaultText,
            style: PtTheme.font(14, color: PtTheme.ink),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _textController,
            label: strings.tKey(PlatformAdminKeys.tableQueueTranslation),
            maxLines: 3,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          PlatformDropdown<String>(
            label: strings.tKey(CommonKeys.tableStatus),
            value: _status,
            items: [
              DropdownMenuItem(
                value: TranslationStatus.draft,
                child: Text(strings.tKey(PlatformAdminKeys.queueDraft)),
              ),
              DropdownMenuItem(
                value: TranslationStatus.reviewed,
                child: Text(strings.tKey(PlatformAdminKeys.queueReviewed)),
              ),
              DropdownMenuItem(
                value: TranslationStatus.approved,
                child: Text(strings.tKey(PlatformAdminKeys.queueApproved)),
              ),
            ],
            onChanged: _saving
                ? (_) {}
                : (value) {
                    if (value != null) setState(() => _status = value);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            '${_index + 1} ${strings.tKey(PlatformAdminKeys.paginationOf)} ${_items.length}',
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
        ],
      ),
      actions: [
        PlatformSecondaryButton(
          label: strings.tKey(CommonKeys.buttonPrevious),
          icon: Icons.arrow_back_rounded,
          onPressed: _index > 0 && !_saving ? () => _moveTo(_index - 1) : null,
        ),
        PlatformSecondaryButton(
          label: strings.tKey(CommonKeys.buttonNext),
          icon: Icons.arrow_forward_rounded,
          onPressed: _index < _items.length - 1 && !_saving
              ? () => _moveTo(_index + 1)
              : null,
        ),
        PlatformPrimaryButton(
          label: strings.tKey(CommonKeys.buttonSave),
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
