import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../download_file_stub.dart'
    if (dart.library.html) '../../download_file_web.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../platform_translations.dart';

/// Tab identifiers shared with readiness blockers (`blocker.tab`).
abstract final class LanguageWorkspaceTab {
  static const String overview = 'overview';
  static const String uiText = 'ui-text';
  static const String categories = 'categories';
  static const String items = 'items';
  static const String optionSets = 'option-sets';
  static const String optionValues = 'option-values';
  static const String templates = 'templates';
  static const String documentTypes = 'document-types';
  static const String issueFields = 'issue-fields';
  static const String publish = 'publish';

  static const List<String> ids = [
    overview,
    uiText,
    categories,
    items,
    optionSets,
    optionValues,
    templates,
    documentTypes,
    issueFields,
    publish,
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
  bool _generatingAll = false;
  bool _approving = false;
  bool _publishing = false;

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

  Future<void> _generateAll() async {
    if (_generatingAll) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _generatingAll = true);
    try {
      await ref
          .read(translationApiProvider)
          .generateUiMessages(code: _code, force: true);
      await ref
          .read(platformConfigActionsProvider)
          .generateContent(
            _code,
            entityTypes: const [
              TranslationEntityType.category,
              TranslationEntityType.item,
              TranslationEntityType.optionSet,
              TranslationEntityType.optionValue,
              TranslationEntityType.template,
              TranslationEntityType.documentType,
              TranslationEntityType.issueField,
            ],
            force: true,
          );
      if (!mounted) return;
      _snack(
        strings.tKey(PlatformAdminKeys.languageWorkspaceToastGenerationStarted),
      );
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _generatingAll = false);
    }
  }

  Future<void> _approveUiText() async {
    if (_approving) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _approving = true);
    try {
      await ref.read(translationApiProvider).approveUiMessageReview(_code);
      if (!mounted) return;
      ref.invalidate(readinessProvider(_code));
      ref.invalidate(platformLanguagesProvider);
      _snack(strings.tKey(PlatformAdminKeys.languageWorkspaceToastApproved));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _publish({required bool enabled}) async {
    if (!enabled || _publishing) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _publishing = true);
    try {
      await ref.read(translationApiProvider).publishLanguage(_code);
      if (!mounted) return;
      ref.invalidate(readinessProvider(_code));
      ref.invalidate(platformLanguagesProvider);
      _snack(strings.tKey(PlatformAdminKeys.languageWorkspaceToastPublished));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _validate() {
    final strings = ref.read(uiStringsProvider);
    ref.invalidate(readinessProvider(_code));
    ref.invalidate(contentGenerationProvider(_code));
    ref.invalidate(languageBacklogProvider(_code));
    _snack(strings.tKey(PlatformAdminKeys.languageWorkspaceToastValidated));
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
    final readiness = ref.watch(readinessProvider(_code));
    final generation = ref.watch(contentGenerationProvider(_code));
    final readinessData = readiness.asData?.value;
    final generationData = generation.asData?.value;
    final activeGeneration = generationData?.isRunning ?? false;
    final ready =
        readinessData != null &&
        readinessData.readinessPercent >= 100 &&
        readinessData.blockers.isEmpty &&
        !activeGeneration;

    return PlatformShell(
      currentRoute: '/settings/languages',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageSettingsTitle),
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
              readiness: readinessData,
              generation: generationData,
              generatingAll: _generatingAll,
              approving: _approving,
              publishing: _publishing,
              publishEnabled: ready,
              onGenerateAll: _generateAll,
              onReview: () => _openTab(LanguageWorkspaceTab.uiText),
              onValidate: _validate,
              onApprove: _approveUiText,
              onPublish: () => _publish(enabled: ready),
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
                      PlatformAdminKeys.languageWorkspaceTabUiText,
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
                  Tab(
                    text: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceTabPublishBlockers,
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
                    generation: generation,
                    onOpenTab: _openTab,
                  ),
                  _UiTextTab(code: _code),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.category,
                    tabId: LanguageWorkspaceTab.categories,
                    sourceRoute: '/checklist/categories',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.item,
                    tabId: LanguageWorkspaceTab.items,
                    sourceRoute: '/checklist/items',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.optionSet,
                    tabId: LanguageWorkspaceTab.optionSets,
                    sourceRoute: '/checklist/option-sets',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.optionValue,
                    tabId: LanguageWorkspaceTab.optionValues,
                    sourceRoute: '/checklist/option-sets',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.template,
                    tabId: LanguageWorkspaceTab.templates,
                    sourceRoute: '/checklist/templates',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.documentType,
                    tabId: LanguageWorkspaceTab.documentTypes,
                    sourceRoute: '/reports/document-types',
                  ),
                  _ContentTab(
                    code: _code,
                    entityType: TranslationEntityType.issueField,
                    tabId: LanguageWorkspaceTab.issueFields,
                    sourceRoute: '/checklist/items',
                  ),
                  _PublishTab(
                    code: _code,
                    readiness: readiness,
                    generation: generation,
                    publishing: _publishing,
                    onOpenTab: _openTab,
                    onValidate: _validate,
                    onPublish: () => _publish(enabled: ready),
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

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.code,
    required this.readiness,
    required this.generation,
    required this.generatingAll,
    required this.approving,
    required this.publishing,
    required this.publishEnabled,
    required this.onGenerateAll,
    required this.onReview,
    required this.onValidate,
    required this.onApprove,
    required this.onPublish,
  });

  final String code;
  final LanguageReadiness? readiness;
  final ContentGeneration? generation;
  final bool generatingAll;
  final bool approving;
  final bool publishing;
  final bool publishEnabled;
  final VoidCallback onGenerateAll;
  final VoidCallback onReview;
  final VoidCallback onValidate;
  final VoidCallback onApprove;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
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
                PlatformStatusChip(status: readiness!.status),
                if (readiness!.isDefault)
                  PlatformStatusChip(
                    status: strings.tKey(
                      PlatformAdminKeys.languageWorkspaceFieldDefaultFlag,
                    ),
                  ),
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.languageWorkspaceFieldReadiness,
                  ),
                  value: '${readiness!.readinessPercent}%',
                ),
              ],
              PlatformStatusChip(
                status: _generationLabel(strings, generation?.jobStatus ?? ''),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PlatformPrimaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonGenerateAll,
                ),
                icon: Icons.auto_awesome_rounded,
                isLoading: generatingAll,
                onPressed: generatingAll ? null : onGenerateAll,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonLanguageReview),
                icon: Icons.rate_review_outlined,
                onPressed: onReview,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonValidate,
                ),
                icon: Icons.fact_check_outlined,
                onPressed: onValidate,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(
                  PlatformAdminKeys.buttonUiMessagesReviewApprove,
                ),
                icon: Icons.verified_rounded,
                isLoading: approving,
                onPressed: approving ? null : onApprove,
              ),
              PlatformPrimaryButton(
                key: const ValueKey('languageHeaderPublish'),
                label: strings.tKey(
                  PlatformAdminKeys.languageWorkspaceButtonPublish,
                ),
                icon: Icons.publish_rounded,
                isLoading: publishing,
                onPressed: publishEnabled && !publishing ? onPublish : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.code,
    required this.readiness,
    required this.generation,
    required this.onOpenTab,
  });

  final String code;
  final AsyncValue<LanguageReadiness> readiness;
  final AsyncValue<ContentGeneration> generation;
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
      data: (data) {
        final ui = data.uiMessages;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlatformSectionHeader(
                      title: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceTabOverview,
                      ),
                      subtitle: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceOverviewSubtitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldReadiness,
                          ),
                          value: '${data.readinessPercent}%',
                        ),
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceOverviewUiText,
                          ),
                          value: '${ui.approved}/${ui.total}',
                        ),
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldMissing,
                          ),
                          value: '${ui.missing}',
                        ),
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldChanged,
                          ),
                          value: '${ui.changed}',
                        ),
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceOverviewContent,
                          ),
                          value: '${data.contentApproved}/${data.contentTotal}',
                        ),
                        PlatformStatusChip(
                          status: _generationLabel(
                            strings,
                            generation.asData?.value.jobStatus ?? '',
                          ),
                        ),
                      ],
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
                        _EntityReadinessRow(entry: entry),
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
        );
      },
    );
  }
}

class _EntityReadinessRow extends StatelessWidget {
  const _EntityReadinessRow({required this.entry});

  final MapEntry<String, EntityReadiness> entry;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            entry.key,
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

enum _ReviewFilter { all, changed, missing, untranslated }

class _UiTextTab extends ConsumerStatefulWidget {
  const _UiTextTab({required this.code});

  final String code;

  @override
  ConsumerState<_UiTextTab> createState() => _UiTextTabState();
}

class _UiTextTabState extends ConsumerState<_UiTextTab> {
  late Future<UiMessageReview> _future;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _edits = {};
  _ReviewFilter _filter = _ReviewFilter.all;
  String _query = '';
  bool _saving = false;
  bool _approving = false;
  bool _retrying = false;
  bool _downloading = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UiMessageReview> _load() {
    _disposeControllers();
    _edits.clear();
    return ref.read(translationApiProvider).fetchUiMessageReview(widget.code);
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _reload() => setState(() => _future = _load());

  TextEditingController _controller(UiMessageReviewEntry entry) {
    return _controllers.putIfAbsent(
      entry.key,
      () => TextEditingController(text: entry.targetText)
        ..addListener(() {
          final controller = _controllers[entry.key];
          if (controller == null || !mounted) return;
          if (controller.text == entry.targetText) {
            if (_edits.remove(entry.key) != null) setState(() {});
          } else if (_edits[entry.key] != controller.text) {
            setState(() => _edits[entry.key] = controller.text);
          }
        }),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _saving = true);
    try {
      await ref
          .read(translationApiProvider)
          .saveUiMessageReview(widget.code, Map.of(_edits));
      if (!mounted) return;
      _snack(strings.tKey(PlatformAdminKeys.languageWorkspaceToastSaved));
      ref.invalidate(readinessProvider(widget.code));
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _approve() async {
    if (_approving) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _approving = true);
    try {
      await ref
          .read(translationApiProvider)
          .approveUiMessageReview(widget.code);
      if (!mounted) return;
      _snack(strings.tKey(PlatformAdminKeys.languageWorkspaceToastApproved));
      ref.invalidate(readinessProvider(widget.code));
      ref.invalidate(platformLanguagesProvider);
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _retryFailed() async {
    if (_retrying) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _retrying = true);
    try {
      await ref
          .read(translationApiProvider)
          .retryFailedUiMessageGeneration(widget.code);
      if (!mounted) return;
      _snack(
        strings.tKey(PlatformAdminKeys.languageWorkspaceToastGenerationRetried),
      );
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _generate() async {
    if (_generating) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _generating = true);
    try {
      await ref
          .read(translationApiProvider)
          .generateUiMessages(code: widget.code, force: true);
      if (!mounted) return;
      _snack(
        strings.tKey(PlatformAdminKeys.languageWorkspaceToastGenerationStarted),
      );
      ref.invalidate(readinessProvider(widget.code));
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _download() async {
    if (_downloading) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(translationApiProvider)
          .downloadUiMessageJson(widget.code);
      downloadBytes('${widget.code}.ui-messages.json', bytes);
      if (!mounted) return;
      _snack(strings.tKey(PlatformAdminKeys.buttonUiMessagesReviewDownload));
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
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
    return FutureBuilder<UiMessageReview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PlatformLoadingView();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return PlatformErrorView(
            message: strings.tKey(CommonKeys.statusUnhealthy),
            retryLabel: strings.tKey(CommonKeys.buttonRetry),
            onRetry: _reload,
          );
        }
        return _buildReview(strings, snapshot.data!);
      },
    );
  }

  Widget _buildReview(UiMessageStrings strings, UiMessageReview review) {
    final query = _query.trim().toLowerCase();
    final entries = review.entries
        .where((entry) {
          switch (_filter) {
            case _ReviewFilter.changed:
              if (!entry.changed) return false;
            case _ReviewFilter.missing:
              if (!entry.missing) return false;
            case _ReviewFilter.untranslated:
              if (!entry.untranslated) return false;
            case _ReviewFilter.all:
              break;
          }
          if (query.isEmpty) return true;
          return entry.key.toLowerCase().contains(query) ||
              entry.sourceText.toLowerCase().contains(query) ||
              entry.targetText.toLowerCase().contains(query);
        })
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlatformMetaPill(
                      label: strings.tKey(PlatformAdminKeys.queueTotal),
                      value: '${review.totalKeys}',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceFieldChanged,
                      ),
                      value: '${review.changedKeys}',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceFieldMissing,
                      ),
                      value: '${review.missingKeys}',
                    ),
                    if (review.path.isNotEmpty)
                      PlatformStatusChip(status: review.path),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: strings.tKey(
                      PlatformAdminKeys.filterUiMessagesReviewSearch,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in _ReviewFilter.values)
                      ChoiceChip(
                        label: Text(_filterLabel(strings, filter)),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonUiMessagesReviewDownload,
                      ),
                      icon: Icons.download_rounded,
                      isLoading: _downloading,
                      onPressed: _downloading ? null : _download,
                    ),
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.languageWorkspaceButtonGenerateUiText,
                      ),
                      icon: Icons.cloud_download_rounded,
                      isLoading: _generating,
                      onPressed: _generating ? null : _generate,
                    ),
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonLanguageRetryFailed,
                      ),
                      icon: Icons.refresh_rounded,
                      isLoading: _retrying,
                      onPressed: _retrying ? null : _retryFailed,
                    ),
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonUiMessagesReviewApprove,
                      ),
                      icon: Icons.verified_rounded,
                      isLoading: _approving,
                      onPressed: _approving ? null : _approve,
                    ),
                    PlatformPrimaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonUiMessagesReviewSave,
                      ),
                      icon: Icons.save_rounded,
                      isLoading: _saving,
                      onPressed: _saving || _edits.isEmpty ? null : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            PlatformEmptyView(
              icon: Icons.search_off_rounded,
              title: strings.tKey(PlatformAdminKeys.emptyUiMessagesReviewTitle),
            )
          else
            for (final entry in entries) ...[
              _UiTextEntryCard(entry: entry, controller: _controller(entry)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  String _filterLabel(UiMessageStrings strings, _ReviewFilter filter) {
    switch (filter) {
      case _ReviewFilter.all:
        return strings.tKey(PlatformAdminKeys.filterUiMessagesReviewAll);
      case _ReviewFilter.changed:
        return strings.tKey(PlatformAdminKeys.filterUiMessagesReviewChanged);
      case _ReviewFilter.missing:
        return strings.tKey(PlatformAdminKeys.filterUiMessagesReviewMissing);
      case _ReviewFilter.untranslated:
        return strings.tKey(
          PlatformAdminKeys.filterUiMessagesReviewUntranslated,
        );
    }
  }
}

class _UiTextEntryCard extends StatelessWidget {
  const _UiTextEntryCard({required this.entry, required this.controller});

  final UiMessageReviewEntry entry;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final source = _TextBlock(
            label: strings.tKey(PlatformAdminKeys.tableUiMessagesReviewSource),
            value: entry.sourceText,
          );
          final target = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.tableUiMessagesReviewTarget),
                style: PtTheme.font(11, color: PtTheme.muted),
              ),
              const SizedBox(height: 4),
              TextField(
                key: ValueKey('ui-text-target-${entry.key}'),
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(isDense: true),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    entry.key,
                    style: PtTheme.font(
                      12,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                    ),
                  ),
                  if (entry.changed)
                    PlatformStatusChip(
                      status: strings.tKey(
                        PlatformAdminKeys.filterUiMessagesReviewChanged,
                      ),
                    ),
                  if (entry.missing)
                    PlatformStatusChip(
                      status: strings.tKey(
                        PlatformAdminKeys.filterUiMessagesReviewMissing,
                      ),
                    ),
                  if (entry.untranslated)
                    PlatformStatusChip(
                      status: strings.tKey(
                        PlatformAdminKeys.filterUiMessagesReviewUntranslated,
                      ),
                    ),
                  if (entry.placeholderMismatch)
                    PlatformStatusChip(
                      status: strings.tKey(
                        PlatformAdminKeys
                            .languageWorkspaceUiTextPlaceholderMismatch,
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
                    const SizedBox(width: 12),
                    Expanded(child: target),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [source, const SizedBox(height: 8), target],
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

enum _ContentFilter { all, missing, pending, active }

class _ContentTab extends ConsumerStatefulWidget {
  const _ContentTab({
    required this.code,
    required this.entityType,
    required this.tabId,
    required this.sourceRoute,
  });

  final String code;
  final String entityType;
  final String tabId;
  final String sourceRoute;

  @override
  ConsumerState<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends ConsumerState<_ContentTab> {
  final Map<String, String> _edits = {};
  final Set<String> _selected = {};
  String _query = '';
  _ContentFilter _contentFilter = _ContentFilter.all;
  bool _busy = false;
  bool _generating = false;

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

  Future<void> _generate() async {
    if (_generating) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _generating = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .generateContent(
            _code,
            entityTypes: [widget.entityType],
            force: true,
          );
      if (!mounted) return;
      _snack(
        strings.tKey(PlatformAdminKeys.languageWorkspaceToastGenerationStarted),
      );
      _invalidate();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey, error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _invalidate() {
    ref.invalidate(languageBacklogProvider(_code));
    ref.invalidate(readinessProvider(_code));
    ref.invalidate(contentGenerationProvider(_code));
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
    final generation = ref.watch(contentGenerationProvider(_code));
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
        final generationData = generation.asData?.value;
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
                        PlatformStatusChip(
                          status: _generationLabel(
                            strings,
                            generationData?.jobStatus ?? '',
                          ),
                        ),
                      ],
                    ),
                    if (generationData != null &&
                        (generationData.isRunning ||
                            generationData.isFailed)) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: generationData.progress),
                      const SizedBox(height: 4),
                      Text(
                        '${strings.tKey(PlatformAdminKeys.languageWorkspaceContentProgress)}: '
                        '${generationData.completed}/${generationData.total}',
                        style: PtTheme.font(11, color: PtTheme.muted),
                      ),
                      if (generationData.failedKeys.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${strings.tKey(PlatformAdminKeys.languageWorkspaceFieldFailedKeys)}: '
                          '${generationData.failedKeys.length}',
                          style: PtTheme.font(11, color: PtTheme.rose),
                        ),
                      ],
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: strings.tKey(
                          PlatformAdminKeys.filterQueueSearch,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
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
                            onSelected: (_) =>
                                setState(() => _contentFilter = filter),
                          ),
                        PlatformSecondaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceButtonOpenSource,
                          ),
                          icon: Icons.open_in_new_rounded,
                          onPressed: () => context.go(widget.sourceRoute),
                        ),
                        PlatformSecondaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys
                                .languageWorkspaceButtonGenerateEntity,
                          ),
                          icon: Icons.cloud_download_rounded,
                          isLoading: _generating,
                          onPressed: _generating ? null : _generate,
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

class _ContentRow extends StatefulWidget {
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
  State<_ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends State<_ContentRow> {
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
    // Keep an in-progress edit, otherwise sync to refreshed server text.
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
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
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
                decoration: const InputDecoration(isDense: true),
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
                      status: _contentStatusLabel(strings, item.contentStatus),
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

class _PublishTab extends ConsumerWidget {
  const _PublishTab({
    required this.code,
    required this.readiness,
    required this.generation,
    required this.publishing,
    required this.onOpenTab,
    required this.onValidate,
    required this.onPublish,
  });

  final String code;
  final AsyncValue<LanguageReadiness> readiness;
  final AsyncValue<ContentGeneration> generation;
  final bool publishing;
  final ValueChanged<String> onOpenTab;
  final VoidCallback onValidate;
  final VoidCallback onPublish;

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
      data: (data) {
        final generationData = generation.asData?.value;
        final activeGeneration = generationData?.isRunning ?? false;
        final enabled =
            data.readinessPercent >= 100 &&
            data.blockers.isEmpty &&
            !activeGeneration;
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
                        PlatformAdminKeys.languageWorkspacePublishTitle,
                      ),
                      subtitle: strings.tKey(
                        PlatformAdminKeys.languageWorkspacePublishSubtitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PlatformMetaPill(
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceFieldReadiness,
                          ),
                          value: '${data.readinessPercent}%',
                        ),
                        PlatformStatusChip(
                          status: enabled
                              ? strings.tKey(
                                  PlatformAdminKeys
                                      .languageWorkspacePublishReady,
                                )
                              : strings.tKey(
                                  PlatformAdminKeys
                                      .languageWorkspacePublishBlocked,
                                ),
                        ),
                        if (activeGeneration)
                          PlatformStatusChip(
                            status: strings.tKey(
                              PlatformAdminKeys
                                  .languageWorkspacePublishActiveGeneration,
                            ),
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
                            PlatformAdminKeys.languageWorkspaceButtonValidate,
                          ),
                          icon: Icons.fact_check_outlined,
                          onPressed: onValidate,
                        ),
                        PlatformPrimaryButton(
                          key: const ValueKey('languagePublishButton'),
                          label: strings.tKey(
                            PlatformAdminKeys.languageWorkspaceButtonPublish,
                          ),
                          icon: Icons.publish_rounded,
                          isLoading: publishing,
                          onPressed: enabled && !publishing ? onPublish : null,
                        ),
                      ],
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
                          PlatformAdminKeys.languageWorkspacePublishNoBlockers,
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
        );
      },
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

String _contentStatusLabel(UiMessageStrings strings, String status) {
  switch (status.toUpperCase()) {
    case 'DRAFT':
      return strings.tKey(PlatformAdminKeys.statusContentDraft);
    case 'ACTIVE':
    case 'PUBLISHED':
      return strings.tKey(PlatformAdminKeys.statusContentActive);
    default:
      return status;
  }
}

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
