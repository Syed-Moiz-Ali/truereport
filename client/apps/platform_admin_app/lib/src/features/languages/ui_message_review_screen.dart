import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../download_file_stub.dart'
    if (dart.library.html) '../../download_file_web.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../../platform_translations.dart';

enum _ReviewFilter { all, changed, missing, untranslated }

class UiMessageReviewScreen extends ConsumerStatefulWidget {
  const UiMessageReviewScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  ConsumerState<UiMessageReviewScreen> createState() =>
      _UiMessageReviewScreenState();
}

class _UiMessageReviewScreenState extends ConsumerState<UiMessageReviewScreen> {
  late Future<UiMessageReview> _future;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _edits = {};
  _ReviewFilter _filter = _ReviewFilter.all;
  String _query = '';
  bool _saving = false;
  bool _approving = false;
  bool _retrying = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<UiMessageReview> _load() {
    _disposeControllers();
    _edits.clear();
    return ref
        .read(translationApiProvider)
        .fetchUiMessageReview(widget.languageCode);
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

  void _reload() {
    setState(() => _future = _load());
  }

  TextEditingController _controller(UiMessageReviewEntry entry) {
    return _controllers.putIfAbsent(
      entry.key,
      () => TextEditingController(text: entry.targetText)
        ..addListener(() {
          final controller = _controllers[entry.key];
          if (controller == null) return;
          if (controller.text == entry.targetText) {
            _edits.remove(entry.key);
          } else {
            _edits[entry.key] = controller.text;
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
          .saveUiMessageReview(widget.languageCode, Map.of(_edits));
      if (!mounted) return;
      _snack(strings.tKey(PlatformAdminKeys.toastUiMessagesReviewSaved));
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), isError: true);
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
          .approveUiMessageReview(widget.languageCode);
      if (!mounted) return;
      _snack(strings.tKey(PlatformAdminKeys.toastUiMessagesReviewApproved));
      ref.invalidate(platformLanguagesProvider);
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), isError: true);
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
          .retryFailedUiMessageGeneration(widget.languageCode);
      if (!mounted) return;
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), isError: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _download() async {
    if (_downloading) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(translationApiProvider)
          .downloadUiMessageJson(widget.languageCode);
      downloadBytes('${widget.languageCode}.ui-messages.json', bytes);
      if (!mounted) return;
      _snack(strings.tKey(PlatformAdminKeys.buttonUiMessagesReviewDownload));
    } catch (_) {
      if (!mounted) return;
      _snack(strings.tKey(CommonKeys.errorGeneric), isError: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _snack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(
          message,
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformShell(
      currentRoute: '/settings/languages',
      child: PlatformPage(
        maxWidth: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.pageUiMessagesReviewTitle),
              subtitle: strings.tKey(
                PlatformAdminKeys.pageUiMessagesReviewSubtitle,
              ),
              actions: [
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
                    PlatformAdminKeys.buttonLanguageRetryFailed,
                  ),
                  icon: Icons.refresh_rounded,
                  isLoading: _retrying,
                  onPressed: _retrying ? null : _retryFailed,
                ),
                PlatformPrimaryButton(
                  label: strings.tKey(
                    PlatformAdminKeys.buttonUiMessagesReviewApprove,
                  ),
                  icon: Icons.verified_rounded,
                  isLoading: _approving,
                  onPressed: _approving ? null : _approve,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<UiMessageReview>(
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
            ),
          ],
        ),
      ),
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

    return Column(
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
                      PlatformAdminKeys.filterUiMessagesReviewChanged,
                    ),
                    value: '${review.changedKeys}',
                  ),
                  PlatformMetaPill(
                    label: strings.tKey(
                      PlatformAdminKeys.filterUiMessagesReviewMissing,
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
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: PlatformPrimaryButton(
                  label: strings.tKey(
                    PlatformAdminKeys.buttonUiMessagesReviewSave,
                  ),
                  icon: Icons.save_rounded,
                  isLoading: _saving,
                  onPressed: _saving || _edits.isEmpty ? null : _save,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          PlatformEmptyView(
            icon: Icons.search_off_rounded,
            title: strings.tKey(PlatformAdminKeys.emptyUiMessagesReviewTitle),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in entries) ...[
                      _buildEntryCard(strings, entry),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in entries) ...[
                    _buildEntryCard(strings, entry),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
      ],
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

  Widget _buildEntryCard(UiMessageStrings strings, UiMessageReviewEntry entry) {
    final controller = _controller(entry);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final source = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.tKey(PlatformAdminKeys.tableUiMessagesReviewSource),
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.sourceText,
                style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
              ),
            ],
          );
          final target = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.tableUiMessagesReviewTarget),
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textDirection: entry.targetText.trim().isEmpty
                    ? null
                    : Directionality.of(context),
                decoration: InputDecoration(
                  errorText: entry.placeholderMismatch
                      ? strings.tKey(CommonKeys.stateError)
                      : null,
                ),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
                ],
              ),
              const SizedBox(height: 10),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: source),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: target),
                  ],
                )
              else ...[
                source,
                const SizedBox(height: 12),
                target,
              ],
            ],
          );
        },
      ),
    );
  }
}
