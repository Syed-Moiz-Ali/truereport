import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'template_builder_screen.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.templates,
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
                      _TemplatesActionBar(
                        compact: compact,
                        onCreate: () => _createTemplate(context, ref),
                      ),
                      const SizedBox(height: 20),
                      templates.when(
                        loading: () => const _LoadingState(),
                        error: (error, stackTrace) => _ErrorState(
                          onRetry: () => ref.invalidate(templatesProvider),
                        ),
                        data: (items) => _TemplatesContent(
                          templates: items,
                          onOpen: (id) => _openBuilder(context, id),
                          onRetire: (template) =>
                              _retireTemplate(context, ref, template),
                        ),
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

  Future<void> _createTemplate(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _CreateTemplateDialog(),
    );
    if (created != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).createTemplate),
        backgroundColor: PtTheme.deepGreen,
      ),
    );
  }

  void _openBuilder(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => TemplateBuilderScreen(templateId: id),
      ),
    );
  }

  Future<void> _retireTemplate(
    BuildContext context,
    WidgetRef ref,
    GlobalTemplate template,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.retired),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Text(
              l10n.retireConfirm,
              style: PtTheme.font(14, color: PtTheme.muted),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: PtTheme.rose),
            child: Text(l10n.retire),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(platformConfigActionsProvider).retireTemplate(template.id);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.genericError)));
    }
  }
}

class _TemplatesActionBar extends StatelessWidget {
  const _TemplatesActionBar({required this.compact, required this.onCreate});

  final bool compact;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
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
                l10n.templates,
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
                l10n.templateBuilder,
                style: PtTheme.font(14, color: PtTheme.muted),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.createTemplate),
          style: FilledButton.styleFrom(
            backgroundColor: PtTheme.deepGreen,
            foregroundColor: PtTheme.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplatesContent extends StatelessWidget {
  const _TemplatesContent({
    required this.templates,
    required this.onOpen,
    required this.onRetire,
  });

  final List<GlobalTemplate> templates;
  final ValueChanged<String> onOpen;
  final ValueChanged<GlobalTemplate> onRetire;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const _EmptyState();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          return _TemplatesTable(
            templates: templates,
            onOpen: onOpen,
            onRetire: onRetire,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < templates.length; index++) ...[
              _TemplateCard(
                template: templates[index],
                onOpen: () => onOpen(templates[index].id),
                onRetire: () => onRetire(templates[index]),
              ),
              if (index != templates.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _TemplatesTable extends StatelessWidget {
  const _TemplatesTable({
    required this.templates,
    required this.onOpen,
    required this.onRetire,
  });

  final List<GlobalTemplate> templates;
  final ValueChanged<String> onOpen;
  final ValueChanged<GlobalTemplate> onRetire;

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
            DataColumn(label: Text(l10n.templateCode)),
            DataColumn(label: Text(l10n.templateNameEn)),
            DataColumn(label: Text(l10n.templateNameAr)),
            DataColumn(label: Text(l10n.status)),
            DataColumn(label: Text(l10n.versions)),
            DataColumn(label: Text(l10n.published)),
            DataColumn(label: Text(l10n.actions)),
          ],
          rows: [
            for (final template in templates)
              DataRow(
                onSelectChanged: (_) => onOpen(template.id),
                cells: [
                  DataCell(Text(template.code)),
                  DataCell(Text(template.nameEn)),
                  DataCell(Text(template.nameAr)),
                  DataCell(_TemplateStatusChip(status: template.status)),
                  DataCell(
                    Text(
                      '${template.versionCount}'
                      '${template.currentVersionNo == null ? '' : ' / v${template.currentVersionNo}'}',
                    ),
                  ),
                  DataCell(Text(_publishedVersionLabel(template))),
                  DataCell(
                    IconButton(
                      tooltip: l10n.retire,
                      icon: const Icon(
                        Icons.archive_outlined,
                        color: PtTheme.rose,
                        size: 20,
                      ),
                      onPressed: () => onRetire(template),
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onOpen,
    required this.onRetire,
  });

  final GlobalTemplate template;
  final VoidCallback onOpen;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: PtTheme.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
                  _CodeChip(label: template.code),
                  _TemplateStatusChip(status: template.status),
                  Text(
                    '${template.versionCount} ${l10n.versions}',
                    style: PtTheme.font(12, color: PtTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.nameEn.isEmpty ? template.nameAr : template.nameEn,
                style: PtTheme.font(
                  17,
                  lineHeight: 22,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              if (template.nameAr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  template.nameAr,
                  textDirection: TextDirection.rtl,
                  style: PtTheme.font(13, color: PtTheme.muted),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${l10n.published}: ${_publishedVersionLabel(template)}',
                    style: PtTheme.font(12, color: PtTheme.muted),
                  ),
                  TextButton.icon(
                    onPressed: onRetire,
                    icon: const Icon(
                      Icons.archive_outlined,
                      size: 16,
                      color: PtTheme.rose,
                    ),
                    label: Text(
                      l10n.retire,
                      style: PtTheme.font(12, color: PtTheme.rose),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateStatusChip extends StatelessWidget {
  const _TemplateStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      'PUBLISHED' => PtTheme.emerald,
      'PENDING_APPROVAL' => PtTheme.amber,
      'RETIRED' => PtTheme.rose,
      _ => PtTheme.deepGreen,
    };
    final label = switch (status) {
      'PUBLISHED' => l10n.published,
      'PENDING_APPROVAL' => l10n.pendingApproval,
      'RETIRED' => l10n.retired,
      'DRAFT' => l10n.draft,
      _ => status,
    };
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

class _CreateTemplateDialog extends ConsumerStatefulWidget {
  const _CreateTemplateDialog();

  @override
  ConsumerState<_CreateTemplateDialog> createState() =>
      _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionArController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(platformConfigActionsProvider).createTemplate({
        'code': _codeController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'nameAr': _nameArController.text.trim(),
        'descriptionEn': _descriptionEnController.text.trim(),
        'descriptionAr': _descriptionArController.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.createTemplate),
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
                  label: l10n.templateCode,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nameEnController,
                  label: l10n.templateNameEn,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nameArController,
                  label: l10n.templateNameAr,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _descriptionEnController,
                  label: l10n.templateDescriptionEn,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _descriptionArController,
                  label: l10n.templateDescriptionAr,
                  maxLines: 3,
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
              : Text(l10n.create),
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
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? requiredMessage;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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
          const Icon(
            Icons.description_outlined,
            size: 36,
            color: PtTheme.muted,
          ),
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

String _publishedVersionLabel(GlobalTemplate template) {
  if (template.currentPublishedVersionId.isEmpty) return '-';
  for (final version in template.versions) {
    if (version.id == template.currentPublishedVersionId) {
      return 'v${version.versionNo}';
    }
  }
  return template.currentPublishedVersionId;
}
