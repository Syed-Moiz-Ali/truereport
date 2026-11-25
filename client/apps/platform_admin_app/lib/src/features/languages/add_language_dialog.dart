import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'language_failures.dart';

/// Opens the Add-language dialog and returns the created/reactivated language.
///
/// The dialog owns the POST so a 409 can keep the chosen language on screen; the
/// calling page only navigates and confirms.
Future<PlatformLanguage?> showAddLanguageDialog(BuildContext context) {
  return showDialog<PlatformLanguage>(
    context: context,
    builder: (dialogContext) => const Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: AddLanguageDialog(),
    ),
  );
}

/// Adds a language from the curated list, so the admin never has to invent a
/// language tag or know whether it reads right-to-left.
class AddLanguageDialog extends ConsumerStatefulWidget {
  const AddLanguageDialog({super.key});

  @override
  ConsumerState<AddLanguageDialog> createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends ConsumerState<AddLanguageDialog> {
  final TextEditingController _searchController = TextEditingController();
  LanguageCatalogEntry? _selected;
  String? _serverError;
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final choice = _selected;
    if (_busy || choice == null) return;
    setState(() => _serverError = null);
    final strings = ref.read(uiStringsProvider);
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(platformConfigActionsProvider)
          .createLanguage(
            code: choice.code,
            nativeName: choice.displayName,
            direction: choice.direction,
          );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      setState(() => _serverError = languageCreateErrorText(strings, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final catalog = ref.watch(languageCatalogProvider);
    final choice = _selected;

    return PlatformDialogShell(
      title: strings.tKey(PlatformAdminKeys.languagesAddButton),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PlatformTextField(
            key: const Key('add-language-search'),
            controller: _searchController,
            autofocus: true,
            label: strings.tKey(PlatformAdminKeys.languagesAddSearch),
            hint: strings.tKey(PlatformAdminKeys.languagesAddSearchHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 268,
            child: catalog.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  languageCreateErrorText(strings, error),
                  style: PtTheme.bodyMuted,
                  textAlign: TextAlign.center,
                ),
              ),
              data: (entries) {
                final results = _filter(entries, _searchController.text);
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      strings.tKey(PlatformAdminKeys.languagesAddSearchEmpty),
                      style: PtTheme.bodyMuted,
                    ),
                  );
                }
                return ListView.separated(
                  key: const Key('add-language-results'),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _CatalogRow(
                    entry: results[index],
                    selected: results[index].code == choice?.code,
                    onTap: () => setState(() => _selected = results[index]),
                  ),
                );
              },
            ),
          ),
          if (choice != null) ...[
            const SizedBox(height: 12),
            _SelectionSummary(entry: choice),
          ],
          if (_serverError != null) ...[
            const SizedBox(height: 12),
            _DialogError(message: _serverError!),
          ],
        ],
      ),
      actions: [
        PlatformGhostButton(
          key: const Key('add-language-cancel'),
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        PlatformPrimaryButton(
          key: const Key('add-language-submit'),
          label: strings.tKey(PlatformAdminKeys.languagesAddSubmit),
          isLoading: _busy,
          onPressed: choice == null ? null : _submit,
        ),
      ],
    );
  }

  /// Languages that are already live are hidden: adding them again would 409.
  List<LanguageCatalogEntry> _filter(
    List<LanguageCatalogEntry> entries,
    String query,
  ) {
    final needle = query.trim().toLowerCase();
    return entries
        .where((entry) => !entry.added)
        .where((entry) {
          if (needle.isEmpty) return true;
          return entry.code.toLowerCase().contains(needle) ||
              entry.name.toLowerCase().contains(needle) ||
              entry.nativeName.toLowerCase().contains(needle);
        })
        .toList(growable: false);
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final LanguageCatalogEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PtTheme.deepGreen.withValues(alpha: 0.06)
          : PtTheme.white,
      child: InkWell(
        key: Key('add-language-option-${entry.code}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.name} · ${entry.code}',
                      style: PtTheme.font(
                        11.5,
                        lineHeight: 15,
                        color: PtTheme.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: PtTheme.deepGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the admin is about to add: label, tag and the writing direction the
/// apps will use.
class _SelectionSummary extends ConsumerWidget {
  const _SelectionSummary({required this.entry});

  final LanguageCatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return Container(
      key: const Key('add-language-summary'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${entry.displayName} · ${entry.code}',
              style: PtTheme.font(
                12.5,
                lineHeight: 17,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
            ),
          ),
          Icon(
            entry.isRtl
                ? Icons.format_textdirection_r_to_l
                : Icons.format_textdirection_l_to_r,
            size: 16,
            color: PtTheme.muted,
          ),
          const SizedBox(width: 6),
          Text(
            strings.tKey(
              entry.isRtl
                  ? PlatformAdminKeys.labelDirectionRtl
                  : PlatformAdminKeys.labelDirectionLtr,
            ),
            style: PtTheme.font(11.5, lineHeight: 16, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

/// Server rejection (409 / 422) shown inside the still-open dialog.
class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('add-language-error'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: PtTheme.rose.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PtTheme.rose.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: PtTheme.rose,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: PtTheme.font(12, lineHeight: 17, color: PtTheme.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
