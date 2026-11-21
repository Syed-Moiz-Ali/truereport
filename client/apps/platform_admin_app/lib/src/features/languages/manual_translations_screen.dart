import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../components/platform_toolbar.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../reference_status_lookup.dart';
import 'manual_translation_models.dart';
import 'manual_translation_providers.dart';

/// Manual translation workspace for one language.
///
/// Route: `/settings/languages/:code/manual`.
///
/// Lists every canonical content field (translated or not) with the English
/// source, lets the platform admin type a translation and save it, and keeps
/// the header totals honest by reading the server `total`, never the page
/// length. Saves are authored/reviewed only, never machine translated.
class ManualTranslationsScreen extends ConsumerStatefulWidget {
  const ManualTranslationsScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  ConsumerState<ManualTranslationsScreen> createState() =>
      _ManualTranslationsScreenState();
}

class _ManualTranslationsScreenState
    extends ConsumerState<ManualTranslationsScreen> {
  static const int _pageSize = 50;
  static const String _allTypes = 'ALL';

  final TextEditingController _searchController = TextEditingController();
  final Map<String, ManualTranslationUnit> _saved = {};
  final Set<String> _hidden = {};

  /// Typed but unsaved text, keyed by unit. Kept across filter/page changes so
  /// moving around the queue never discards the admin's work.
  final Map<String, String> _edits = {};

  Timer? _searchDebounce;
  String _search = '';
  String? _entityType;
  String _filter = ManualTranslationFilter.all;
  int _page = 0;

  String get _code => widget.languageCode;

  ManualTranslationQuery get _query => ManualTranslationQuery(
    lang: _code,
    entityType: _entityType,
    filter: _filter,
    search: _search,
    page: _page,
    size: _pageSize,
  );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 0;
        _clearOverlays();
      });
    });
  }

  void _clearOverlays() {
    _saved.clear();
    _hidden.clear();
  }

  void _clearAllLocal() {
    _clearOverlays();
    _edits.clear();
  }

  void _refresh() {
    setState(_clearAllLocal);
    ref.invalidate(manualTranslationSummaryProvider(_code));
    ref.invalidate(manualTranslationsPageProvider(_query));
  }

  void _goToPage(int page) {
    if (page < 0 || page == _page) return;
    setState(() {
      _page = page;
      // The next page is fetched from the server, so local save overlays and
      // the local missing-filter removals no longer apply. Unsaved text stays
      // keyed by unit so it is restored if the admin comes back.
      _clearOverlays();
    });
  }

  Future<bool> _save(ManualTranslationUnit unit, String text) async {
    final strings = ref.read(uiStringsProvider);
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _snack(strings.tKey(CommonKeys.validationRequired), error: true);
      return false;
    }
    try {
      final response = await ref
          .read(platformConfigApiProvider)
          .writeContentTranslation(
            entityType: unit.entityType,
            entityId: unit.entityId,
            field: unit.field,
            lang: _code,
            text: trimmed,
          );
      if (!mounted) return false;
      // The write contract returns the stored row, but a minimal response must
      // still show the text the admin just saved.
      var updated = response.withIdentity(unit);
      if (updated.trimmedText.isEmpty) {
        updated = updated.copyWith(text: trimmed);
      }
      setState(() {
        _saved[unit.key] = updated;
        _edits.remove(unit.key);
        if (_filter == ManualTranslationFilter.missing) {
          // The row is no longer missing; remove it from the current filter
          // locally instead of waiting for a refetch.
          _hidden.add(unit.key);
        }
      });
      ref.invalidate(manualTranslationSummaryProvider(_code));
      _snack(strings.tKey(PlatformAdminKeys.manualTranslationsToastSaved));
      return true;
    } on AppFailure catch (failure) {
      if (mounted) _snack(failure.messageKey, error: true);
      return false;
    } catch (_) {
      if (mounted) _snack(strings.tKey(CommonKeys.errorGeneric), error: true);
      return false;
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
    final contentTypes = ref.watch(enumsProvider(contentTypeEnum)).value;
    final language = _language(ref.watch(platformLanguagesProvider).value);
    final summary = ref.watch(manualTranslationSummaryProvider(_code)).value;
    final query = _query;
    final pageAsync = ref.watch(manualTranslationsPageProvider(query));
    final page = pageAsync.value;
    // The server total counts rows before this session's local saves; remove
    // the rows already removed from the missing filter so the page count stays
    // honest until the next fetch.
    final loadedTotal = page?.total ?? 0;
    final total = loadedTotal <= 0
        ? 0
        : math.max(0, loadedTotal - _hidden.length);
    final pages = total <= 0
        ? 1
        : math.max(1, (total + _pageSize - 1) ~/ _pageSize);

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
          ContextBreadcrumbItem(
            label: _code,
            onTap: () => context.go('/settings/languages/$_code'),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.manualTranslationsTitle),
          ),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              code: _code,
              nativeName: language?.displayName ?? _code,
              summary: summary,
              onRefresh: _refresh,
            ),
            const SizedBox(height: 12),
            PlatformToolbar(
              searchController: _searchController,
              searchHint: strings.tKey(
                PlatformAdminKeys.manualTranslationsSearch,
              ),
              onSearchChanged: _onSearchChanged,
              filters: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: PlatformDropdown<String>(
                    label: strings.tKey(
                      PlatformAdminKeys.manualTranslationsEntityType,
                    ),
                    value: _entityType ?? _allTypes,
                    items: [
                      DropdownMenuItem(
                        value: _allTypes,
                        child: Text(strings.tKey(CommonKeys.filterAll)),
                      ),
                      for (final type in ManualTranslationEntityType.all)
                        DropdownMenuItem(
                          value: type,
                          child: Text(
                            referenceCodeLabel(strings, contentTypes, type),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _entityType = value == _allTypes ? null : value;
                        _page = 0;
                        _clearOverlays();
                      });
                    },
                  ),
                ),
                PlatformFilterChip(
                  label: strings.tKey(
                    PlatformAdminKeys.manualTranslationsFilterAll,
                  ),
                  selected: _filter == ManualTranslationFilter.all,
                  onTap: () {
                    if (_filter == ManualTranslationFilter.all) return;
                    setState(() {
                      _filter = ManualTranslationFilter.all;
                      _page = 0;
                      _clearOverlays();
                    });
                  },
                ),
                PlatformFilterChip(
                  label: strings.tKey(
                    PlatformAdminKeys.manualTranslationsFilterMissing,
                  ),
                  selected: _filter == ManualTranslationFilter.missing,
                  onTap: () {
                    if (_filter == ManualTranslationFilter.missing) return;
                    setState(() {
                      _filter = ManualTranslationFilter.missing;
                      _page = 0;
                      _clearOverlays();
                    });
                  },
                ),
              ],
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (page != null)
                    Text(
                      strings.tArgsKey(
                        PlatformAdminKeys.manualTranslationsPageInfo,
                        <String, Object?>{
                          'page': '${_page + 1}',
                          'pages': '$pages',
                          'total': '$total',
                        },
                      ),
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w500,
                        color: PtTheme.muted,
                      ),
                    ),
                  PlatformSecondaryButton(
                    label: strings.tKey(CommonKeys.buttonPrevious),
                    icon: Icons.arrow_back_rounded,
                    onPressed: _page > 0 ? () => _goToPage(_page - 1) : null,
                  ),
                  PlatformSecondaryButton(
                    label: strings.tKey(CommonKeys.buttonNext),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: page != null && _page + 1 < pages
                        ? () => _goToPage(_page + 1)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (page == null && pageAsync.isLoading)
              const PlatformSkeletonList(rows: 6)
            else if (page == null && pageAsync.hasError)
              PlatformErrorView(
                message: strings.tKey(CommonKeys.stateError),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: _refresh,
              )
            else
              _Results(
                page: page,
                strings: strings,
                contentTypes: contentTypes,
                filter: _filter,
                saved: _saved,
                hidden: _hidden,
                edits: _edits,
                onEdited: (key, value) => _edits[key] = value,
                onSave: _save,
                onShowAll: () {
                  setState(() {
                    _filter = ManualTranslationFilter.all;
                    _page = 0;
                    _clearOverlays();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  PlatformLanguage? _language(List<PlatformLanguage>? languages) {
    if (languages == null) return null;
    for (final language in languages) {
      if (language.code == _code) return language;
    }
    return null;
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.code,
    required this.nativeName,
    required this.summary,
    required this.onRefresh,
  });

  final String code;
  final String nativeName;
  final ManualTranslationSummary? summary;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final progress = summary == null
        ? '—'
        : '${summary!.translated}/${summary!.total}';
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
                nativeName,
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
              PlatformMetaPill(
                label: strings.tKey(
                  PlatformAdminKeys.manualTranslationsFieldProgress,
                ),
                value: progress,
              ),
              PlatformSecondaryButton(
                key: const Key('btn-manual-translations-refresh'),
                label: strings.tKey(CommonKeys.buttonRefresh),
                icon: Icons.refresh_rounded,
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.tKey(PlatformAdminKeys.manualTranslationsSubtitle),
            style: PtTheme.font(12, lineHeight: 18, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.page,
    required this.strings,
    required this.contentTypes,
    required this.filter,
    required this.saved,
    required this.hidden,
    required this.edits,
    required this.onEdited,
    required this.onSave,
    required this.onShowAll,
  });

  final ManualTranslationPage? page;
  final UiMessageStrings strings;
  final Iterable<ReferenceRecord>? contentTypes;
  final String filter;
  final Map<String, ManualTranslationUnit> saved;
  final Set<String> hidden;
  final Map<String, String> edits;
  final void Function(String key, String value) onEdited;
  final Future<bool> Function(ManualTranslationUnit unit, String text) onSave;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final units = <ManualTranslationUnit>[];
    for (final item in page?.items ?? const <ManualTranslationUnit>[]) {
      final unit = saved[item.key] ?? item;
      if (hidden.contains(item.key)) continue;
      if (filter == ManualTranslationFilter.missing && !unit.isMissing) {
        continue;
      }
      units.add(unit);
    }

    if (units.isEmpty) {
      if (filter == ManualTranslationFilter.missing) {
        return PlatformEmptyView(
          icon: Icons.translate_rounded,
          title: strings.tKey(PlatformAdminKeys.manualTranslationsEmptyMissing),
          body: strings.tKey(
            PlatformAdminKeys.manualTranslationsEmptyMissingBody,
          ),
          actionLabel: strings.tKey(CommonKeys.filterAll),
          onAction: onShowAll,
        );
      }
      return PlatformEmptyView(
        icon: Icons.search_off_rounded,
        title: strings.tKey(PlatformAdminKeys.manualTranslationsEmptyNone),
      );
    }

    final grouped = <String, List<ManualTranslationUnit>>{};
    for (final unit in units) {
      grouped.putIfAbsent(unit.entityType, () => []).add(unit);
    }
    final orderedTypes = <String>[
      ...ManualTranslationEntityType.all.where(grouped.containsKey),
      ...grouped.keys.where(
        (type) => !ManualTranslationEntityType.all.contains(type),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final type in orderedTypes) ...[
          if (grouped[type] case final rows?) ...[
            PlatformSectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: PlatformSectionHeader(
                      title: referenceCodeLabel(strings, contentTypes, type),
                      subtitle: strings.tArgsKey(
                        PlatformAdminKeys.manualTranslationsGroupCount,
                        <String, Object?>{'count': '${rows.length}'},
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  for (var index = 0; index < rows.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: _ManualUnitRow(
                        key: ValueKey(rows[index].key),
                        unit: rows[index],
                        initialText:
                            edits[rows[index].key] ?? rows[index].trimmedText,
                        onEdited: (value) => onEdited(rows[index].key, value),
                        onSave: onSave,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _ManualUnitRow extends StatefulWidget {
  const _ManualUnitRow({
    super.key,
    required this.unit,
    required this.initialText,
    required this.onEdited,
    required this.onSave,
  });

  final ManualTranslationUnit unit;

  /// Server text with any unsaved edit from a previous filter/page.
  final String initialText;

  final ValueChanged<String> onEdited;
  final Future<bool> Function(ManualTranslationUnit unit, String text) onSave;

  @override
  State<_ManualUnitRow> createState() => _ManualUnitRowState();
}

class _ManualUnitRowState extends State<_ManualUnitRow> {
  late TextEditingController _controller;
  late String _savedText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savedText = widget.unit.trimmedText;
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant _ManualUnitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit.key != widget.unit.key) {
      _controller.dispose();
      _savedText = widget.unit.trimmedText;
      _saving = false;
      _controller = TextEditingController(text: widget.initialText);
      return;
    }
    final serverText = widget.unit.trimmedText;
    if (!_saving && _controller.text.trim() == _savedText) {
      if (serverText != _savedText) {
        _savedText = serverText;
        _controller.text = widget.initialText;
      } else if (widget.initialText != _controller.text) {
        _controller.text = widget.initialText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      _controller.text.trim().isNotEmpty &&
      _controller.text.trim() != _savedText.trim();

  Future<void> _handleSave() async {
    if (!_canSave) return;
    final text = _controller.text.trim();
    setState(() => _saving = true);
    final success = await widget.onSave(widget.unit, text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) {
        _savedText = text;
        _controller.text = text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ProviderScope.containerOf(context).read(uiStringsProvider);
    final unit = widget.unit;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final source = _SourceBlock(
          label: strings.tKey(PlatformAdminKeys.manualTranslationsSource),
          value: unit.sourceText.isEmpty ? '—' : unit.sourceText,
        );
        final target = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.tKey(PlatformAdminKeys.manualTranslationsTranslation),
              style: PtTheme.font(11, color: PtTheme.muted),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: strings.tKey(
                PlatformAdminKeys.manualTranslationsTranslation,
              ),
              child: TextField(
                key: ValueKey('manual-translation-${unit.key}'),
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                enabled: !_saving,
                onChanged: (value) {
                  widget.onEdited(value);
                  setState(() {});
                },
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.ink),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: unit.isMissing
                      ? strings.tKey(
                          PlatformAdminKeys.manualTranslationsHintMissing,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PlatformSecondaryButton(
                label: strings.tKey(CommonKeys.buttonSave),
                icon: Icons.save_outlined,
                isLoading: _saving,
                onPressed: _canSave ? _handleSave : null,
              ),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.manualTranslationsEntity,
                  ),
                  value: unit.entityId,
                ),
                PlatformMetaPill(
                  label: strings.tKey(
                    PlatformAdminKeys.manualTranslationsField,
                  ),
                  value: unit.field,
                ),
                if (unit.hasStatus)
                  PlatformStatusChip(
                    status: unit.status!.trim().toUpperCase(),
                    // Tone comes from the served taxonomy; the content state is
                    // humanized, never string-switched into local labels.
                    label: humanizeStatusCode(unit.status!),
                  ),
                if (unit.safetyCritical) _SafetyCriticalBadge(strings: strings),
              ],
            ),
            const SizedBox(height: 8),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: source),
                  const SizedBox(width: 16),
                  Expanded(child: target),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [source, const SizedBox(height: 12), target],
              ),
          ],
        );
      },
    );
  }
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({required this.label, required this.value});

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
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
        ),
      ],
    );
  }
}

class _SafetyCriticalBadge extends StatelessWidget {
  const _SafetyCriticalBadge({required this.strings});

  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PtTheme.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: PtTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.health_and_safety_rounded,
            size: 13,
            color: PtTheme.gold,
          ),
          const SizedBox(width: 4),
          Text(
            strings.tKey(PlatformAdminKeys.manualTranslationsSafetyCritical),
            style: PtTheme.font(
              11,
              lineHeight: 14,
              weight: FontWeight.w600,
              color: PtTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
