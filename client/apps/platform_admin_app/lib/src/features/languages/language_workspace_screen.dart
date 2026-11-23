import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../platform_translations.dart';
import '../../reference_status_lookup.dart';
import 'language_cards.dart';
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
    final displayName = readiness?.displayName.isNotEmpty == true
        ? readiness!.displayName
        : code;

    return PlatformSectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hero = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        26,
                        lineHeight: 32,
                        weight: FontWeight.w800,
                        color: PtTheme.ink,
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
                    if (statusLabel != null) ...[
                      const SizedBox(height: 8),
                      LanguageStateChip(
                        label: statusLabel,
                        warn: readiness?.status != 'LIVE',
                      ),
                    ],
                  ],
                ),
              ),
              if (readiness != null) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${readiness!.readinessPercent}',
                      style:
                          PtTheme.font(
                            48,
                            lineHeight: 48,
                            weight: FontWeight.w800,
                            color: PtTheme.ink,
                          ).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                    Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceFieldReadiness,
                      ),
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w600,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
          final meta = readiness == null
              ? null
              : Text(
                  '${readiness!.uiMessages.approved}/${readiness!.uiMessages.total} '
                  '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldUiTextCoverage)}'
                  ' · ${readiness!.contentApproved}/${readiness!.contentTotal} '
                  '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldContentCoverage)}',
                  style: PtTheme.font(12, lineHeight: 18, color: PtTheme.muted),
                );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hero,
                if (meta != null) ...[const SizedBox(height: 8), meta],
                const SizedBox(height: 14),
                actions,
                const SizedBox(height: 12),
                Text(
                  strings.tKey(
                    PlatformAdminKeys.languageWorkspaceHeaderSubtitle,
                  ),
                  style: PtTheme.font(12, color: PtTheme.muted),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              if (meta != null) ...[const SizedBox(height: 8), meta],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.tKey(
                        PlatformAdminKeys.languageWorkspaceHeaderSubtitle,
                      ),
                      style: PtTheme.font(12, color: PtTheme.muted),
                    ),
                  ),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
            ],
          );
        },
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
            if (data.content.isEmpty)
              PlatformSectionCard(
                child: Text(
                  strings.tKey(
                    PlatformAdminKeys.languageWorkspaceContentNoItems,
                  ),
                  style: PtTheme.font(12, color: PtTheme.muted),
                ),
              )
            else
              LanguageGrid(
                children: [
                  for (final entry in data.content.entries)
                    _EntityCard(
                      entry: entry,
                      onOpenTab: () => onOpenTab(_tabForEntityType(entry.key)),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            LanguageCardShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tKey(
                      PlatformAdminKeys.languageWorkspaceOverviewBlockers,
                    ),
                    style: PtTheme.font(
                      15,
                      lineHeight: 21,
                      weight: FontWeight.w700,
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

/// One entity readiness card (Direction B overview).
///
/// Human name, approved-of-total as a big number with a meter, and one
/// verb: open the entity tab. Replaces the old readiness rows.
class _EntityCard extends ConsumerWidget {
  const _EntityCard({required this.entry, required this.onOpenTab});

  final MapEntry<String, EntityReadiness> entry;
  final VoidCallback onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final types = ref.watch(enumsProvider(contentTypeEnum)).value;
    final total = entry.value.total;
    final approved = entry.value.approved;
    final fraction = total <= 0 ? 0.0 : (approved / total).clamp(0.0, 1.0);
    final complete = total > 0 && approved >= total;
    return LanguageCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _localizedEntityName(strings, types, entry.key),
                  style: PtTheme.font(
                    15,
                    lineHeight: 21,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (complete)
                LanguageStateChip(label: strings.tKey(CommonKeys.statusHealthy))
              else
                LanguageStateChip(
                  label:
                      '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldApproved)} $approved/$total',
                  warn: true,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$approved / $total',
            textDirection: TextDirection.ltr,
            style: PtTheme.font(
              32,
              lineHeight: 36,
              weight: FontWeight.w800,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 2),
          Text(
            strings.tKey(PlatformAdminKeys.languageWorkspaceFieldApproved),
            style: PtTheme.font(12, lineHeight: 16, color: PtTheme.muted),
          ),
          const SizedBox(height: 8),
          LanguageCoverageMeter(value: fraction),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PlatformGhostButton(
              label: strings.tKey(
                PlatformAdminKeys.languageWorkspaceOverviewOpenTab,
              ),
              icon: Icons.arrow_forward_rounded,
              onPressed: onOpenTab,
            ),
          ),
        ],
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
        final showBar = selectedItems.isNotEmpty;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: showBar ? 96 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlatformSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$approved / $total',
                              textDirection: TextDirection.ltr,
                              style:
                                  PtTheme.font(
                                    32,
                                    lineHeight: 36,
                                    weight: FontWeight.w800,
                                    color: PtTheme.ink,
                                  ).copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  strings.tKey(
                                    PlatformAdminKeys
                                        .languageWorkspaceFieldApproved,
                                  ),
                                  style: PtTheme.font(
                                    12.5,
                                    lineHeight: 18,
                                    weight: FontWeight.w600,
                                    color: PtTheme.muted,
                                  ),
                                ),
                              ),
                            ),
                            if (total - approved > 0)
                              LanguageStateChip(
                                label: strings.tArgsKey(
                                  PlatformAdminKeys
                                      .pageLanguagesCardMissingCount,
                                  <String, Object?>{
                                    'count': '${total - approved}',
                                  },
                                ),
                                warn: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LanguageCoverageMeter(
                          value: total <= 0 ? 0 : approved / total,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          textAlignVertical: TextAlignVertical.center,
                          decoration: PtTheme.fieldDecoration(
                            hint: strings.tKey(
                              PlatformAdminKeys.filterQueueSearch,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: PtTheme.muted,
                            ),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final filter in _ContentFilter.values)
                              PlatformFilterChip(
                                label: _contentFilterLabel(strings, filter),
                                selected: _contentFilter == filter,
                                onTap: () =>
                                    setState(() => _contentFilter = filter),
                              ),
                            if (widget.sourceRoute != null)
                              PlatformSecondaryButton(
                                label: strings.tKey(
                                  PlatformAdminKeys
                                      .languageWorkspaceButtonOpenSource,
                                ),
                                icon: Icons.open_in_new_rounded,
                                onPressed: () =>
                                    context.go(widget.sourceRoute!),
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
                    LanguageLedger(
                      children: [
                        for (final item in items)
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
                      ],
                    ),
                ],
              ),
            ),
            if (showBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _WorkspaceSelectionBar(
                  count: selectedItems.length,
                  busy: _busy,
                  onClear: () => setState(() => _selected.clear()),
                  onApprove: () => _approveMany(selectedItems),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Sticky selection bar for the workspace content tab (Direction A).
///
/// Sits at the foot of the content panel when rows are selected: tabular
/// count, ghost Clear, primary Approve selected — the same chrome as the
/// queue bar so the two work surfaces feel like one product.
class _WorkspaceSelectionBar extends ConsumerWidget {
  const _WorkspaceSelectionBar({
    required this.count,
    required this.busy,
    required this.onClear,
    required this.onApprove,
  });

  final int count;
  final bool busy;
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
                PlatformAdminKeys.languageWorkspaceSelectedCount,
                <String, Object?>{'count': '$count'},
              ),
              style: PtTheme.font(13, lineHeight: 18, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          PlatformGhostButton(
            key: const Key('btn-workspace-clear-selection'),
            label: strings.tKey(
              PlatformAdminKeys.languageWorkspaceButtonClearSelection,
            ),
            onPressed: busy ? null : onClear,
          ),
          const SizedBox(width: 8),
          PlatformPrimaryButton(
            key: const Key('btn-workspace-approve-selected'),
            label: strings.tKey(PlatformAdminKeys.buttonQueueApproveSelected),
            icon: Icons.done_all_rounded,
            isLoading: busy,
            onPressed: busy ? null : onApprove,
          ),
        ],
      ),
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
    final missing = (item.text ?? '').trim().isEmpty;
    return Container(
      color: widget.selected
          ? PtTheme.deepGreen.withValues(alpha: 0.06)
          : Colors.transparent,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final source = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.tableQueueDefaultText),
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.defaultText.isEmpty ? '—' : item.defaultText,
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w600,
                  color: PtTheme.ink,
                ),
              ),
            ],
          );
          final target = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.tableQueueTranslation),
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                key: ValueKey('content-edit-${item.key}'),
                controller: _controller,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: PtTheme.font(13, lineHeight: 19),
                decoration: PtTheme.fieldDecoration(
                  hint: missing ? 'Type the translation…' : null,
                ),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LedgerCheck(
                    selected: widget.selected,
                    onTap: () => widget.onSelected(!widget.selected),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
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
                            '${item.entityCode.isEmpty ? item.entityId : item.entityCode} · ${item.field}',
                            style: PtTheme.font(
                              10.5,
                              lineHeight: 14,
                              weight: FontWeight.w700,
                              color: PtTheme.muted,
                            ),
                          ),
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
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: source),
                    const SizedBox(width: 14),
                    Expanded(child: target),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [source, const SizedBox(height: 8), target],
                ),
              const SizedBox(height: 10),
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

/// Rounded 22px selection box shared by the work-surface rows.
class _LedgerCheck extends StatelessWidget {
  const _LedgerCheck({required this.selected, required this.onTap});

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
