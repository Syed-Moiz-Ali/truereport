import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class LanguagesScreen extends ConsumerWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languages = ref.watch(platformLanguagesProvider);
    final coverage = ref.watch(translationCoverageProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.languageRegistry,
          style: PtTheme.font(
            18,
            lineHeight: 24,
            weight: FontWeight.w800,
            color: PtTheme.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.languageRegistry,
                                  style: PtTheme.font(
                                    compact ? 22 : 28,
                                    lineHeight: compact ? 28 : 34,
                                    weight: FontWeight.w800,
                                    color: PtTheme.ink,
                                    tracking: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.translationCoverage,
                                  style: PtTheme.font(14, color: PtTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _edit(context, null),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.addLanguage),
                            style: FilledButton.styleFrom(
                              backgroundColor: PtTheme.deepGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      languages.when(
                        loading: () => const _LoadingState(),
                        error: (error, stackTrace) => _ErrorState(
                          onRetry: () =>
                              ref.invalidate(platformLanguagesProvider),
                        ),
                        data: (items) => items.isEmpty
                            ? const _EmptyState()
                            : _LanguagesContent(
                                items: items,
                                onEdit: (item) => _edit(context, item),
                                onToggleActive: (item) =>
                                    _toggleActive(context, ref, item),
                                onSetDefault: (item) =>
                                    _setDefault(context, ref, item),
                              ),
                      ),
                      const SizedBox(height: 20),
                      _CoverageSection(
                        coverage: coverage,
                        onRetry: () =>
                            ref.invalidate(translationCoverageProvider),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, PlatformLanguage? initial) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _LanguageDialog(initial: initial),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).save),
          backgroundColor: PtTheme.deepGreen,
        ),
      );
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    try {
      final api = ref.read(platformConfigApiProvider);
      if (language.active) {
        await api.deactivateLanguage(language.code);
      } else {
        await api.activateLanguage(language.code);
      }
      if (!context.mounted) return;
      ref.invalidate(platformLanguagesProvider);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
      );
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    PlatformLanguage language,
  ) async {
    try {
      await ref
          .read(platformConfigActionsProvider)
          .setDefaultLanguage(language.code);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
      );
    }
  }
}

class _LanguagesContent extends StatelessWidget {
  const _LanguagesContent({
    required this.items,
    required this.onEdit,
    required this.onToggleActive,
    required this.onSetDefault,
  });

  final List<PlatformLanguage> items;
  final ValueChanged<PlatformLanguage> onEdit;
  final ValueChanged<PlatformLanguage> onToggleActive;
  final ValueChanged<PlatformLanguage> onSetDefault;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          return _LanguagesTable(
            items: items,
            onEdit: onEdit,
            onToggleActive: onToggleActive,
            onSetDefault: onSetDefault,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _LanguageCard(
                language: items[index],
                onEdit: () => onEdit(items[index]),
                onToggleActive: () => onToggleActive(items[index]),
                onSetDefault: () => onSetDefault(items[index]),
              ),
              if (index != items.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _LanguagesTable extends StatelessWidget {
  const _LanguagesTable({
    required this.items,
    required this.onEdit,
    required this.onToggleActive,
    required this.onSetDefault,
  });

  final List<PlatformLanguage> items;
  final ValueChanged<PlatformLanguage> onEdit;
  final ValueChanged<PlatformLanguage> onToggleActive;
  final ValueChanged<PlatformLanguage> onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.languageCode)),
            DataColumn(label: Text(l10n.labelEn)),
            DataColumn(label: Text(l10n.labelAr)),
            DataColumn(label: Text(l10n.nativeName)),
            DataColumn(label: Text(l10n.direction)),
            DataColumn(label: Text(l10n.active)),
            DataColumn(label: Text(l10n.defaultLanguage)),
            DataColumn(label: Text(l10n.actions)),
          ],
          rows: [
            for (final language in items)
              DataRow(
                cells: [
                  DataCell(Text(language.code)),
                  DataCell(Text(language.nameEn)),
                  DataCell(Text(language.nameAr)),
                  DataCell(Text(language.nativeName)),
                  DataCell(Text(language.direction)),
                  DataCell(
                    _InfoChip(
                      label: language.active ? l10n.active : l10n.retired,
                      color: language.active ? PtTheme.emerald : PtTheme.muted,
                    ),
                  ),
                  DataCell(
                    language.isDefault
                        ? _InfoChip(
                            label: l10n.defaultLanguage,
                            color: PtTheme.deepGreen,
                          )
                        : const Text('-'),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.edit,
                          onPressed: () => onEdit(language),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: language.active ? l10n.retired : l10n.active,
                          onPressed: () => onToggleActive(language),
                          icon: Icon(
                            language.active
                                ? Icons.toggle_on_rounded
                                : Icons.toggle_off_rounded,
                            size: 22,
                            color: language.active
                                ? PtTheme.emerald
                                : PtTheme.muted,
                          ),
                        ),
                        if (!language.isDefault)
                          TextButton(
                            onPressed: () => onSetDefault(language),
                            child: Text(l10n.defaultLanguage),
                          ),
                      ],
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.onEdit,
    required this.onToggleActive,
    required this.onSetDefault,
  });

  final PlatformLanguage language;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CodeChip(label: language.code),
              _InfoChip(
                label: language.active ? l10n.active : l10n.retired,
                color: language.active ? PtTheme.emerald : PtTheme.muted,
              ),
              _InfoChip(label: language.direction, color: PtTheme.deepGreen),
              if (language.isDefault)
                _InfoChip(label: l10n.defaultLanguage, color: PtTheme.gold),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            language.nameEn,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          if (language.nameAr.isNotEmpty)
            Text(
              language.nameAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          if (language.nativeName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n.nativeName}: ${language.nativeName}',
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.edit),
              ),
              TextButton.icon(
                onPressed: onToggleActive,
                icon: Icon(
                  language.active
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  size: 18,
                  color: language.active ? PtTheme.emerald : PtTheme.muted,
                ),
                label: Text(language.active ? l10n.retired : l10n.active),
              ),
              if (!language.isDefault)
                TextButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(
                    Icons.star_outline_rounded,
                    size: 16,
                    color: PtTheme.gold,
                  ),
                  label: Text(l10n.defaultLanguage),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverageSection extends StatelessWidget {
  const _CoverageSection({required this.coverage, required this.onRetry});

  final AsyncValue<TranslationCoverage> coverage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: coverage.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PtTheme.deepGreen,
            ),
          ),
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translationCoverage,
              style: PtTheme.font(
                16,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
        data: (data) {
          final namespaces = data.namespaces.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translationCoverage,
                style: PtTheme.font(
                  16,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in data.languages)
                    _CodeChip(label: language),
                ],
              ),
              const SizedBox(height: 8),
              if (namespaces.isEmpty)
                Text(l10n.noData, style: PtTheme.font(13, color: PtTheme.muted))
              else
                for (final entry in namespaces)
                  Material(
                    type: MaterialType.transparency,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      title: Text(
                        entry.key,
                        style: PtTheme.font(
                          14,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                      ),
                      subtitle: Text(
                        'Total: ${entry.value.total} · '
                        '${l10n.missingTranslations}: ${entry.value.missing.length}',
                        style: PtTheme.font(12, color: PtTheme.muted),
                      ),
                      children: [
                        if (entry.value.missing.isEmpty)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              l10n.noData,
                              style: PtTheme.font(12, color: PtTheme.muted),
                            ),
                          )
                        else
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final reference in entry.value.missing)
                                  _ReferenceChip(label: reference),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageDialog extends ConsumerStatefulWidget {
  const _LanguageDialog({this.initial});

  final PlatformLanguage? initial;

  @override
  ConsumerState<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends ConsumerState<_LanguageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _nativeNameController;
  late final TextEditingController _sortOrderController;
  late String _direction;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _codeController = TextEditingController(text: initial?.code ?? '');
    _nameEnController = TextEditingController(text: initial?.nameEn ?? '');
    _nameArController = TextEditingController(text: initial?.nameAr ?? '');
    _nativeNameController = TextEditingController(
      text: initial?.nativeName ?? '',
    );
    _sortOrderController = TextEditingController(
      text: '${initial?.sortOrder ?? 0}',
    );
    final direction = initial?.direction ?? '';
    _direction = direction.isEmpty ? 'LTR' : direction;
    _active = initial?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _nativeNameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveLanguage(
            code: _codeController.text.trim(),
            nameEn: _nameEnController.text.trim(),
            nameAr: _nameArController.text.trim(),
            nativeName: _nativeNameController.text.trim(),
            direction: _direction,
            active: _active,
            sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
            isNew: widget.initial == null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genericError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.addLanguage : l10n.languageRegistry,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  controller: _codeController,
                  label: l10n.languageCode,
                  requiredMessage: l10n.required,
                  enabled: widget.initial == null,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nameEnController,
                  label: l10n.labelEn,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nameArController,
                  label: l10n.labelAr,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nativeNameController,
                  label: l10n.nativeName,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _direction,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.direction,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'LTR', child: Text('LTR')),
                    DropdownMenuItem(value: 'RTL', child: Text('RTL')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _direction = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _sortOrderController,
                  label: 'Order',
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: Text(l10n.active),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PtTheme.white,
                  ),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.requiredMessage,
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? requiredMessage;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: PtTheme.font(14, color: PtTheme.ink),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (value) {
        if (requiredMessage != null &&
            (value == null || value.trim().isEmpty)) {
          return requiredMessage;
        }
        return null;
      },
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: PtTheme.muted,
          tracking: 0.4,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PtTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: PtTheme.font(11, color: PtTheme.gold)),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: PtTheme.deepGreen),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).loading,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.rose.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: PtTheme.rose, size: 34),
          const SizedBox(height: 12),
          Text(
            l10n.unhealthy,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.translate_rounded, size: 36, color: PtTheme.muted),
          const SizedBox(height: 12),
          Text(
            l10n.noData,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
