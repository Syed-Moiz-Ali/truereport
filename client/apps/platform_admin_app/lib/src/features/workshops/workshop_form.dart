import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

import 'package:l10n/l10n.dart';

class WorkshopForm extends ConsumerStatefulWidget {
  const WorkshopForm({super.key, this.workshop, this.onSaved});

  final HierarchyWorkshop? workshop;

  final ValueChanged<HierarchyWorkshop>? onSaved;

  @override
  ConsumerState<WorkshopForm> createState() => _WorkshopFormState();
}

class _WorkshopFormState extends ConsumerState<WorkshopForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _branchController;
  late final TextEditingController _emailController;

  String? _selectedTemplateId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final workshop = widget.workshop;
    _nameController = TextEditingController(text: workshop?.name ?? '');
    _branchController = TextEditingController(text: workshop?.branchName ?? '');
    _emailController = TextEditingController(
      text: workshop?.contactEmail ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.workshop == null;

  Future<void> _submit() async {
    final strings = ref.watch(uiStringsProvider);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final name = _nameController.text.trim();
    final branch = _branchController.text.trim();
    final email = _emailController.text.trim();

    String? templateId = _selectedTemplateId;
    if (_isCreate && templateId == null) {
      final templates = switch (ref.read(templatesProvider)) {
        AsyncData(:final value) => value,
        _ => null,
      };
      if (templates != null && templates.isNotEmpty) {
        templateId = templates.first.id;
        _selectedTemplateId = templateId;
      } else {
        setState(() => _error = strings.tKey(CommonKeys.stateError));
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = ref.read(platformApiProvider);
      final saved = _isCreate
          ? await api.registerWorkshop(
              name: name,
              location: branch,
              contactEmail: email,
              initialTemplate: templateId!,
            )
          : await api.updateWorkshop(
              widget.workshop!.id,
              name: name,
              location: branch,
              contactEmail: email,
            );
      ref.invalidate(hierarchyStateProvider);
      if (!mounted) return;
      widget.onSaved?.call(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = strings.tKey(CommonKeys.stateError));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _cancel() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/workshops');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFFFCA5A5)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _FormSection(
            step: '1',
            title: strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PlatformTextField(
                  key: const Key('input-workshop-name'),
                  controller: _nameController,
                  label:
                      '${strings.tKey(PlatformAdminKeys.fieldWorkshopName)} *',
                  hint: strings.tKey(PlatformAdminKeys.fieldWorkshopName),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? strings.tKey(CommonKeys.stateError)
                      : null,
                ),
                const SizedBox(height: 14),
                PlatformTextField(
                  key: const Key('input-workshop-branch'),
                  controller: _branchController,
                  label:
                      '${strings.tKey(PlatformAdminKeys.fieldWorkshopBranch)} *',
                  hint: strings.tKey(PlatformAdminKeys.fieldWorkshopBranch),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? strings.tKey(CommonKeys.stateError)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FormSection(
            step: '2',
            title: strings.tKey(PlatformAdminKeys.sectionWorkshopContact),
            child: PlatformTextField(
              key: const Key('input-workshop-email'),
              controller: _emailController,
              label:
                  '${strings.tKey(PlatformAdminKeys.fieldWorkshopContactEmail)} *',
              hint: strings.tKey(PlatformAdminKeys.fieldWorkshopContactEmail),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty || !text.contains('@')) {
                  return strings.tKey(CommonKeys.stateError);
                }
                return null;
              },
            ),
          ),
          if (_isCreate) ...[
            const SizedBox(height: 14),
            _FormSection(
              step: '3',
              title: strings.tKey(PlatformAdminKeys.pageTemplatesTitle),
              child: _TemplatePicker(
                selectedId: _selectedTemplateId,
                onSelected: (id) => setState(() => _selectedTemplateId = id),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: strings.tKey(CommonKeys.buttonCancel),
                onPressed: _submitting ? null : _cancel,
              ),
              PlatformPrimaryButton(
                label: strings.tKey(CommonKeys.buttonSave),
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormSection extends ConsumerWidget {
  const _FormSection({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: PtTheme.deepGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w800,
                      color: PtTheme.deepGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TemplatePicker extends ConsumerWidget {
  const _TemplatePicker({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final templates = ref.watch(templatesProvider);
    return templates.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Row(
        children: [
          Expanded(child: Text(strings.tKey(CommonKeys.stateError))),
          TextButton(
            onPressed: () => ref.invalidate(templatesProvider),
            child: Text(strings.tKey(CommonKeys.buttonRetry)),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text(strings.tKey(CommonKeys.emptyTitle));
        }
        final value = items.any((item) => item.id == selectedId)
            ? selectedId
            : items.first.id;
        return PlatformDropdown<String>(
          label: '${strings.tKey(PlatformAdminKeys.pageTemplatesTitle)} *',
          value: value!,
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item.id,
                child: Text(
                  item.nameEn.isNotEmpty ? item.nameEn : item.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onSelected,
        );
      },
    );
  }
}

class WorkshopFormPage extends ConsumerWidget {
  const WorkshopFormPage({super.key, this.workshop});

  final HierarchyWorkshop? workshop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformShell(
      currentRoute: '/workshops',
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: workshop == null
                  ? strings.tKey(PlatformAdminKeys.pageWorkshopsAdd)
                  : strings.tKey(PlatformAdminKeys.pageWorkshopsEdit),
              subtitle: strings.tKey(PlatformAdminKeys.pageWorkshopsSubtitle),
            ),
            const SizedBox(height: 20),
            PlatformSectionCard(
              child: WorkshopForm(
                workshop: workshop,
                onSaved: (_) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/workshops');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showReasonDialog({
  required BuildContext context,
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _ReasonDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

class _ReasonDialog extends ConsumerStatefulWidget {
  const _ReasonDialog({
    required this.title,
    this.body,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String? body;
  final String confirmLabel;
  final bool destructive;

  @override
  ConsumerState<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends ConsumerState<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: PlatformDialogShell(
        title: widget.title,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.body != null && widget.body!.isNotEmpty) ...[
              Text(
                widget.body!,
                style: const TextStyle(color: Color(0xFF5E5D69)),
              ),
              const SizedBox(height: 14),
            ],
            PlatformTextField(
              controller: _controller,
              label: strings.tKey(CommonKeys.fieldReason),
              hint: strings.tKey(CommonKeys.fieldReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.tKey(CommonKeys.buttonCancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: widget.destructive
                  ? const Color(0xFFE11D48)
                  : const Color(0xFF006C49),
            ),
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}
