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
import '../../platform_translations.dart';
import '../../reference_status_lookup.dart';
import 'language_failures.dart';

import 'package:reference_data/reference_data.dart';

/// Tab identifiers for dynamic content translation only.
///
/// Static UI text is JSON-backed and has no workspace tab, generation,
/// review, approve or publish step.
abstract final class LanguageWorkspaceTab {
  static const String overview = 'overview';
  static const String categories = 'categories';
  static const String items = 'items';
  static const String optionSets = 'option-sets';
  static const String optionValues = 'option-values';
  static const String templates = 'templates';
  static const String documentTypes = 'document-types';
  static const String issueFields = 'issue-fields';

  static const List<String> ids = [
    overview,
    categories,
    items,
    optionSets,
    optionValues,
    templates,
    documentTypes,
    issueFields,
  ];
}

class LanguageWorkspaceScreen extends ConsumerStatefulWidget {
  const LanguageWorkspaceScreen({
    super.key,
    required this.languageCode,
    this.initialTab,
  });

  final String languageCode;
  final String? initialTab;

  @override
  ConsumerState<LanguageWorkspaceScreen> createState() =>
      _LanguageWorkspaceScreenState();
}

class _LanguageWorkspaceScreenState
    extends ConsumerState<LanguageWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _retiring = false;

  String get _code => widget.languageCode;

  @override
  void initState() {
    super.initState();
    final initialIndex = LanguageWorkspaceTab.ids.indexOf(
      widget.initialTab ?? LanguageWorkspaceTab.overview,
    );
    _tabController = TabController(
      length: LanguageWorkspaceTab.ids.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openTab(String tab) {
    final index = LanguageWorkspaceTab.ids.indexOf(tab);
    if (index < 0) return;
    _tabController.animateTo(index);
  }

  Future<void> _retire() async {
    if (_retiring) return;
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(PlatformAdminKeys.languagesRetireTitle),
      body: strings.tKey(PlatformAdminKeys.languagesRetireBody),
      confirmLabel: strings.tKey(PlatformAdminKeys.languagesRetireConfirm),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _retiring = true);
    try {
      await ref.read(platformConfigActionsProvider).retireLanguage(_code);
      if (!mounted) return;
      context.go('/settings/languages');
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.deepGreen,
          content: Text(strings.tKey(PlatformAdminKeys.languagesRetireToast)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.rose,
          content: Text(languageRetireErrorText(strings, error)),
        ),
      );
    } finally {
      if (mounted) setState(() => _retiring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final readiness = ref.watch(readinessProvider(_code));

    return PlatformShell(
      currentRoute: '/settings/languages',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageProfileTitle),
            onTap: () => context.go('/settings'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
            onTap: () => context.go('/settings/languages'),
          ),
          ContextBreadcrumbItem(label: _code),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkspaceHeader(
              code: _code,
              readiness: readiness.asData?.value,
              retiring: _retiring,
              onRetire: _retire,
            ),
            const SizedBox(height: 12),
            PlatformSectionCard(
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabOverview,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabCategories,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabChecklistItems,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabOptionSets,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabOptionValues,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabTemplates,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabDocumentTypes,
                    ),
                  ),
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabIssueFields,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 560,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    code: _code,
                    readiness: readiness,
                    onOpenTab: _openTab,
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.category,
                    sourceRoute: '/checklist/categories',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.item,
                    sourceRoute: '/checklist/items',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.optionSet,
                    sourceRoute: '/checklist/option-sets',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.optionValue,
                    sourceRoute: '/checklist/option-sets',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.template,
                    sourceRoute: null,
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.documentType,
                    sourceRoute: '/reports/document-types',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.issueField,
                    sourceRoute: '/checklist/items',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  const _WorkspaceHeader({
    required this.code,
    required this.readiness,
    required this.retiring,
    required this.onRetire,
  });

  final String code;
  final LanguageReadiness? readiness;
  final bool retiring;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    // The registry is the authority for "is default"; readiness is the
    // fallback when the registry has not loaded yet.
    final registry = ref.watch(platformLanguagesProvider).asData?.value;
    PlatformLanguage? registryLanguage;
    for (final language in registry ?? const <PlatformLanguage>[]) {
      if (language.code == code) {
        registryLanguage = language;
        break;
      }
    }
    final isDefault =
        registryLanguage?.isDefault ?? readiness?.isDefault ?? false;
    final statusLabel = readiness == null
        ? null
        : referenceCodeLabel(
            strings,
            ref.watch(statusesProvider(translationStatusDomain)).value,
            readiness!.status,
          );

    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                readiness?.displayName.isNotEmpty == true
                    ? readiness!.displayName
                    : code,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: PtTheme.font(
                  20,
                  lineHeight: 26,
                  weight: FontWeight.w800,
                  color: PtTheme.ink,
                ),
              ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldLanguageCode),
                value: code,
              ),
              if (readiness != null) ...[
                PlatformMetaPill(
                  label: strings.tKey(PlatformAdminKeys.fieldLanguageDirection),
                  value: readiness!.direction,
                ),
                PlatformStatusChip(
                  status: readiness!.status,
                  label: statusLabel,
                ),
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage,
                  ),
                  value:
                      '${readiness!.uiMessages.approved}/${readiness!.uiMessages.total}',
                ),
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceFieldContentCoverage,
                  ),
                  value:
                      '${readiness!.contentApproved}/${readiness!.contentTotal}',
                ),
              ],
              PlatformSecondaryButton(
                key: const Key('btn-manual-translations'),
                label: strings.tKey(
                  PlatformAdminKeys.manualTranslationsButtonOpen,
                ),
                icon: Icons.edit_note_rounded,
                onPressed: () => context.go('/settings/languages/$code/manual'),
              ),
              if (!isDefault)
                PlatformSecondaryButton(
                  key: const Key('btn-retire-language'),
                  label: strings.tKey(PlatformAdminKeys.languagesRetireAction),
                  icon: Icons.archive_outlined,
                  destructive: true,
                  isLoading: retiring,
                  onPressed: onRetire,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.tKey(PlatformAdminKeys.languageWorkspaceHeaderSubtitle),
            style: PtTheme.font(12, color: PtTheme.muted),
          ),
          if (readiness != null && readiness!.uiMessagesPath.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${strings.tKey(PlatformAdminKeys.fieldLanguageUiMessagesPath)}: '
              '${readiness!.uiMessagesPath}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.code,
    required this.readiness,
    required this.onOpenTab,
  });

  final String code;
  final AsyncValue<LanguageReadiness> readiness;
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return readiness.when(
      loading: () => const PlatformLoadingView(),
      error: (error, stackTrace) => PlatformErrorView(
        message: strings.tKey(CommonKeys.statusUnhealthy),
        retryLabel: strings.tKey(CommonKeys.buttonRetry),
        onRetry: () => ref.invalidate(readinessProvider(code)),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlatformSectionHeader(
                    title: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceOverviewContent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data.content.isEmpty)
                    Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceContentNoItems,
                      ),
                      style: PtTheme.font(12, color: PtTheme.muted),
                    )
                  else
                    for (final entry in data.content.entries)
                      _EntityReadinessRow(
                        entry: entry,
                        onOpenTab: () =>
                            onOpenTab(_tabForEntityType(entry.key)),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PlatformSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlatformSectionHeader(
                    title: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceOverviewBlockers,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data.blockers.isEmpty)
                    Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceOverviewNoBlockers,
                      ),
                      style: PtTheme.font(12, color: PtTheme.muted),
                    )
                  else
                    for (final blocker in data.blockers)
                      _BlockerRow(
                        blocker: blocker,
                        onOpen: () => onOpenTab(blocker.tab),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tabForEntityType(String entityType) {
  // gate-allow: behaviour - entity code selects a workspace tab, not a label.
  switch (entityType.toUpperCase()) {
    case 'CATEGORY':
      return LanguageWorkspaceTab.categories;
    case 'ITEM':
      return LanguageWorkspaceTab.items;
    case 'OPTION_SET':
      return LanguageWorkspaceTab.optionSets;
    case 'OPTION_VALUE':
      return LanguageWorkspaceTab.optionValues;
    case 'TEMPLATE':
      return LanguageWorkspaceTab.templates;
    case 'DOCUMENT_TYPE':
      return LanguageWorkspaceTab.documentTypes;
    case 'ISSUE_FIELD':
      return LanguageWorkspaceTab.issueFields;
    default:
      return LanguageWorkspaceTab.overview;
  }
}

String _localizedEntityName(
  UiMessageStrings strings,
  Iterable<ReferenceRecord>? records,
  String entityType,
) => referenceCodeLabel(strings, records, entityType);

class _EntityReadinessRow extends ConsumerWidget {
  const _EntityReadinessRow({required this.entry, required this.onOpenTab});

  final MapEntry<String, EntityReadiness> entry;
  final VoidCallback onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final types = ref.watch(enumsProvider(contentTypeEnum)).value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _localizedEntityName(strings, types, entry.key),
                  style: PtTheme.font(
                    13,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                Text(
                  '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldApproved)}: '
                  '${entry.value.approved}/${entry.value.total}',
                  style: PtTheme.font(12, color: PtTheme.muted),
                ),
                if (entry.value.missing > 0)
                  PlatformStatusChip(
                    status:
                        '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldMissing)}: '
                        '${entry.value.missing}',
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PlatformSecondaryButton(
            label: strings.tKey(
              PlatformAdminKeys.languageWorkspaceOverviewOpenTab,
            ),
            onPressed: onOpenTab,
          ),
        ],
      ),
    );
  }
}

class _BlockerRow extends StatelessWidget {
  const _BlockerRow({required this.blocker, required this.onOpen});

  final ReadinessBlocker blocker;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          PlatformStatusChip(status: '${blocker.count}'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              blocker.message,
              style: PtTheme.font(12, color: PtTheme.ink),
            ),
          ),
          const SizedBox(width: 8),
          PlatformSecondaryButton(
            label: strings.tKey(
              PlatformAdminKeys.languageWorkspaceOverviewOpenTab,
            ),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

enum _ContentFilter { all, missing, pending, active }

class _ContentTab extends ConsumerStatefulWidget {
  const _ContentTab({
    required this.code,
    required this.entityType,
    required this.sourceRoute,
  });

  final String code;
  final String entityType;
  final String? sourceRoute;

  @override
  ConsumerState<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends ConsumerState<_ContentTab> {
  final Map<String, String> _edits = {};
  final Set<String> _selected = {};
  String _query = '';
  _ContentFilter _contentFilter = _ContentFilter.all;
  bool _busy = false;

  String get _code => widget.code;

  List<TranslationItem> _items(TranslationBacklog? backlog) {
    if (backlog == null) return const [];
    final group = backlog.groups.where(
      (group) => group.entityType == widget.entityType,
    );
    if (group.isEmpty) return const [];
    final query = _query.trim().toLowerCase();
    return group.first.items
        .where((item) {
          switch (_contentFilter) {
            case _ContentFilter.missing:
              if (!item.isMissing) return false;
            case _ContentFilter.pending:
              if (!item.isPendingActivation) return false;
            case _ContentFilter.active:
              if (!item.isActive) return false;
            case _ContentFilter.all:
              break;
          }
          if (query.isEmpty) return true;
          return item.entityCode.toLowerCase().contains(query) ||
              item.entityId.toLowerCase().contains(query) ||
              item.defaultText.toLowerCase().contains(query) ||
              (item.text ?? '').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  String _textFor(TranslationItem item) => _edits[item.key] ?? item.text ?? '';

  Future<void> _save(TranslationItem item, {String? status}) async {
    final text = _textFor(item).trim();
    if (text.isEmpty) {
      final strings = ref.read(uiStringsProvider);
      _snack(strings.tKey(CommonKeys.validationRequired), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(translationApiProvider)
          .upsertTranslation(
            entityType: item.entityType,
            entityId: item.entityId,
            field: item.field,
            language: _code,
            text: text,
            status: status ?? TranslationStatus.draft,
          );
      if (!mounted) return;
      _edits.remove(item.key);
      _selected.remove(item.key);
      final strings = ref.read(uiStringsProvider);
      _snack(
        status == TranslationStatus.approved
            ? strings.tKey(PlatformAdminKeys.languageWorkspaceToastApproved)
            : strings.tKey(PlatformAdminKeys.languageWorkspaceToastSaved),
      );
      _invalidate();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(
        ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approveMany(List<TranslationItem> items) async {
    if (items.isEmpty || _busy) return;
    setState(() => _busy = true);
    var approved = 0;
    try {
      for (final item in items) {
        final text = _textFor(item).trim();
        if (text.isEmpty) continue;
        await ref
            .read(translationApiProvider)
            .upsertTranslation(
              entityType: item.entityType,
              entityId: item.entityId,
              field: item.field,
              language: _code,
              text: text,
              status: TranslationStatus.approved,
            );
        approved++;
      }
      if (!mounted) return;
      _selected.clear();
      _edits.clear();
      final strings = ref.read(uiStringsProvider);
      _snack(
        approved == 0
            ? strings.tKey(
                PlatformAdminKeys.languageWorkspaceToastNothingToSave,
              )
            : strings.tKey(PlatformAdminKeys.languageWorkspaceToastApproved),
      );
      _invalidate();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(
        ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidate() {
    ref.invalidate(languageBacklogProvider(_code));
    ref.invalidate(readinessProvider(_code));
  }

  void _snack(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: error ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final backlog = ref.watch(languageBacklogProvider(_code));
    return backlog.when(
      loading: () => const PlatformLoadingView(),
      error: (error, stackTrace) => PlatformErrorView(
        message: strings.tKey(CommonKeys.statusUnhealthy),
        retryLabel: strings.tKey(CommonKeys.buttonRetry),
        onRetry: () => ref.invalidate(languageBacklogProvider(_code)),
      ),
      data: (data) {
        final items = _items(data);
        final group = data.groups.where(
          (group) => group.entityType == widget.entityType,
        );
        final total = group.isEmpty ? 0 : group.first.total;
        final approved = group.isEmpty ? 0 : group.first.approved;
        final selectedItems = items
            .where((item) => _selected.contains(item.key))
            .toList(growable: false);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlatformSectionHeader(
                      title: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceContentTitle,
                      ),
                      subtitle: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceContentSubtitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldTotal,
                          ),
                          value: '$total',
                        ),
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldApproved,
                          ),
                          value: '$approved',
                        ),
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldMissing,
                          ),
                          value:
                              '${total - approved < 0 ? 0 : total - approved}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: PtTheme.fieldDecoration(
                        hint: strings.tKey(PlatformAdminKeys.filterQueueSearch),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: PtTheme.muted,
                        ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final filter in _ContentFilter.values)
                          ChoiceChip(
                            label: Text(_contentFilterLabel(strings, filter)),
                            selected: _contentFilter == filter,
                            showCheckmark: false,
                            shape: const StadiumBorder(),
                            side: BorderSide(
                              color: _contentFilter == filter
                                  ? PtTheme.deepGreen.withValues(alpha: 0.35)
                                  : PtTheme.border,
                            ),
                            backgroundColor: PtTheme.canvas,
                            selectedColor: PtTheme.deepGreen.withValues(
                              alpha: 0.12,
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            labelPadding: EdgeInsets.zero,
                            labelStyle: PtTheme.font(
                              12,
                              weight: FontWeight.w600,
                              color: _contentFilter == filter
                                  ? PtTheme.deepGreen
                                  : PtTheme.muted,
                            ),
                            onSelected: (_) =>
                                setState(() => _contentFilter = filter),
                          ),
                        if (widget.sourceRoute != null)
                          PlatformSecondaryButton(
                            label: strings.tKey(
                              PlatformAdminKeys
                                  .languageWorkspaceButtonOpenSource,
                            ),
                            icon: Icons.open_in_new_rounded,
                            onPressed: () => context.go(widget.sourceRoute!),
                          ),
                        PlatformSecondaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys.buttonQueueApproveSelected,
                          ),
                          icon: Icons.done_all_rounded,
                          isLoading: _busy,
                          onPressed: _busy || selectedItems.isEmpty
                              ? null
                              : () => _approveMany(selectedItems),
                        ),
                        PlatformPrimaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys
                                .languageWorkspaceButtonBulkApprove,
                          ),
                          icon: Icons.verified_rounded,
                          isLoading: _busy,
                          onPressed: _busy || items.isEmpty
                              ? null
                              : () => _approveMany(items),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                PlatformEmptyView(
                  icon: Icons.inbox_outlined,
                  title: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceContentNoItems,
                  ),
                )
              else
                for (final item in items) ...[
                  _ContentRow(
                    key: ValueKey(item.key),
                    item: item,
                    selected: _selected.contains(item.key),
                    controllerText: _textFor(item),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selected.add(item.key);
                        } else {
                          _selected.remove(item.key);
                        }
                      });
                    },
                    onChanged: (value) {
                      _edits[item.key] = value;
                    },
                    onSave: () => _save(item),
                    onApprove: () =>
                        _save(item, status: TranslationStatus.approved),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _ContentRow extends ConsumerStatefulWidget {
  const _ContentRow({
    super.key,
    required this.item,
    required this.selected,
    required this.controllerText,
    required this.onSelected,
    required this.onChanged,
    required this.onSave,
    required this.onApprove,
  });

  final TranslationItem item;
  final bool selected;
  final String controllerText;
  final ValueChanged<bool> onSelected;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onApprove;

  @override
  ConsumerState<_ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends ConsumerState<_ContentRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.controllerText)
      ..addListener(() => widget.onChanged(_controller.text));
  }

  @override
  void didUpdateWidget(covariant _ContentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text.isEmpty && widget.controllerText.isNotEmpty) {
      _controller.text = widget.controllerText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final contentStatuses = ref.watch(statusesProvider('checklist')).value;
    final item = widget.item;
    return PlatformSectionCard(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final source = _TextBlock(
            label: strings.tKey(PlatformAdminKeys.tableQueueDefaultText),
            value: item.defaultText,
          );
          final target = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.tableQueueTranslation),
                style: PtTheme.font(11, color: PtTheme.muted),
              ),
              const SizedBox(height: 4),
              TextField(
                key: ValueKey('content-edit-${item.key}'),
                controller: _controller,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: PtTheme.fieldDecoration(),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Checkbox(
                    value: widget.selected,
                    onChanged: (value) => widget.onSelected(value ?? false),
                    semanticLabel: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceContentSelectRow,
                    ),
                  ),
                  Text(
                    item.entityCode.isEmpty ? item.entityId : item.entityCode,
                    style: PtTheme.font(
                      12,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                    ),
                  ),
                  Text(
                    item.field,
                    style: PtTheme.font(11, color: PtTheme.muted),
                  ),
                  PlatformStatusChip(
                    status: _statusLabel(strings, item.status),
                  ),
                  if (item.contentStatus.isNotEmpty)
                    PlatformStatusChip(
                      status: _contentStatusLabel(
                        strings,
                        contentStatuses,
                        item.contentStatus,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: source),
                    const SizedBox(width: 12),
                    Expanded(child: target),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [source, const SizedBox(height: 8), target],
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  PlatformSecondaryButton(
                    label: strings.tKey(CommonKeys.buttonSaveDraft),
                    icon: Icons.save_outlined,
                    onPressed: widget.onSave,
                  ),
                  PlatformSecondaryButton(
                    label: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceButtonApprove,
                    ),
                    icon: Icons.check_rounded,
                    onPressed: widget.onApprove,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PtTheme.font(11, color: PtTheme.muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.ink),
        ),
      ],
    );
  }
}

String _contentFilterLabel(UiMessageStrings strings, _ContentFilter filter) {
  switch (filter) {
    case _ContentFilter.all:
      return strings.tKey(PlatformAdminKeys.filterContentAll);
    case _ContentFilter.missing:
      return strings.tKey(PlatformAdminKeys.filterContentMissing);
    case _ContentFilter.pending:
      return strings.tKey(PlatformAdminKeys.filterContentPending);
    case _ContentFilter.active:
      return strings.tKey(PlatformAdminKeys.filterContentActive);
  }
}

String _contentStatusLabel(
  UiMessageStrings strings,
  Iterable<ReferenceRecord>? records,
  String status,
) => referenceCodeLabel(strings, records, status);

String _statusLabel(UiMessageStrings strings, String status) {
  switch (TranslationStatus.normalize(status)) {
    case TranslationStatus.approved:
      return strings.tKey(PlatformAdminKeys.queueApproved);
    case TranslationStatus.reviewed:
      return strings.tKey(PlatformAdminKeys.queueReviewed);
    case TranslationStatus.draft:
      return strings.tKey(PlatformAdminKeys.queueDraft);
    case TranslationStatus.translating:
      return strings.tKey(PlatformAdminKeys.statusLanguageTranslating);
    default:
      return strings.tKey(PlatformAdminKeys.queueMissing);
  }
}
