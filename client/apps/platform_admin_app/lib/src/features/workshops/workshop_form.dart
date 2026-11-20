import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'atlas/atlas_ui.dart';
import 'workshop_reason_dialog.dart';

class WorkshopForm extends ConsumerStatefulWidget {
  const WorkshopForm({
    super.key,
    this.workshop,
    this.onSaved,
    this.embedded = false,
  });

  final HierarchyWorkshop? workshop;
  final ValueChanged<HierarchyWorkshop>? onSaved;

  /// Embedded in a dialog: groups are plain, not separate surfaces.
  final bool embedded;

  @override
  ConsumerState<WorkshopForm> createState() => _WorkshopFormState();
}

class _WorkshopFormState extends ConsumerState<WorkshopForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _branchController;
  late final TextEditingController _emailController;
  final _nameFocus = FocusNode();
  final _branchFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _submitting = false;
  String? _error;

  bool get _isCreate => widget.workshop == null;

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
    _nameFocus.dispose();
    _branchFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value, UiMessageStrings strings) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return strings.tKey(CommonKeys.validationRequiredField);
    if (text.length < 2) {
      return strings.tKey(CommonKeys.validationRequiredField);
    }
    return null;
  }

  String? _validateBranch(String? value, UiMessageStrings strings) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return strings.tKey(CommonKeys.validationRequiredField);
    return null;
  }

  String? _validateEmail(String? value, UiMessageStrings strings) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return strings.tKey(CommonKeys.validationRequiredField);
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) {
      return strings.tKey(CommonKeys.validationInvalidEmail);
    }
    return null;
  }

  void _focusFirstInvalid(UiMessageStrings strings) {
    if (_validateName(_nameController.text, strings) != null) {
      _nameFocus.requestFocus();
      return;
    }
    if (_validateBranch(_branchController.text, strings) != null) {
      _branchFocus.requestFocus();
      return;
    }
    _emailFocus.requestFocus();
  }

  Future<void> _submit() async {
    final strings = ref.read(uiStringsProvider);
    if (!(_formKey.currentState?.validate() ?? false)) {
      _focusFirstInvalid(strings);
      return;
    }
    if (_submitting) return;
    final name = _nameController.text.trim();
    final branch = _branchController.text.trim();
    final email = _emailController.text.trim();

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
      if (mounted) setState(() => _submitting = false);
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
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtlasTextField(
          key: const Key('input-workshop-name'),
          controller: _nameController,
          focusNode: _nameFocus,
          label: strings.tKey(PlatformAdminKeys.fieldWorkshopName),
          hint: strings.tKey(PlatformAdminKeys.fieldWorkshopName),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _branchFocus.requestFocus(),
          validator: (value) => _validateName(value, strings),
        ),
        const SizedBox(height: 14),
        AtlasTextField(
          key: const Key('input-workshop-branch'),
          controller: _branchController,
          focusNode: _branchFocus,
          label: strings.tKey(PlatformAdminKeys.fieldWorkshopBranch),
          hint: strings.tKey(PlatformAdminKeys.fieldWorkshopBranch),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
          validator: (value) => _validateBranch(value, strings),
        ),
      ],
    );
    final contact = AtlasTextField(
      key: const Key('input-workshop-email'),
      controller: _emailController,
      focusNode: _emailFocus,
      label: strings.tKey(PlatformAdminKeys.fieldWorkshopContactEmail),
      hint: strings.tKey(PlatformAdminKeys.fieldWorkshopContactEmail),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      autofillHints: const [AutofillHints.email],
      validator: (value) => _validateEmail(value, strings),
    );

    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: [
        AtlasButton(
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: _submitting ? null : _cancel,
          variant: AtlasButtonVariant.secondary,
        ),
        AtlasButton(
          label: strings.tKey(
            widget.workshop == null
                ? PlatformAdminKeys.pageWorkshopsAdd
                : CommonKeys.buttonSave,
          ),
          onPressed: _submitting ? null : _submit,
          isLoading: _submitting,
        ),
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Atlas.roseTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PtTheme.rose.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: PtTheme.rose,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: Atlas.text(
                      12.5,
                      weight: FontWeight.w600,
                      color: PtTheme.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.embedded) ...[
          Text(
            strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
            style: Atlas.eyebrow,
          ),
          const SizedBox(height: 12),
          identity,
          const SizedBox(height: 22),
          Text(
            strings.tKey(PlatformAdminKeys.sectionWorkshopContact),
            style: Atlas.eyebrow,
          ),
          const SizedBox(height: 12),
          contact,
        ] else ...[
          AtlasSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
                  style: Atlas.sectionTitle,
                ),
                const SizedBox(height: 18),
                identity,
              ],
            ),
          ),
          const SizedBox(height: 16),
          AtlasSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.tKey(PlatformAdminKeys.sectionWorkshopContact),
                  style: Atlas.sectionTitle,
                ),
                const SizedBox(height: 18),
                contact,
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        actions,
      ],
    );

    return Form(key: _formKey, child: content);
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AtlasButton(
                    label: strings.tKey(PlatformAdminKeys.navWorkshops),
                    icon: Icons.arrow_back_rounded,
                    variant: AtlasButtonVariant.ghost,
                    compact: true,
                    onPressed: () => context.go('/workshops'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.tKey(
                    workshop == null
                        ? PlatformAdminKeys.pageWorkshopsAdd
                        : PlatformAdminKeys.pageWorkshopsEdit,
                  ),
                  style: Atlas.pageTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.tKey(PlatformAdminKeys.pageWorkshopsSubtitle),
                  style: Atlas.body.copyWith(color: PtTheme.muted),
                ),
                const SizedBox(height: 24),
                WorkshopForm(
                  workshop: workshop,
                  onSaved: (_) {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/workshops');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showWorkshopFormDialog({
  required BuildContext context,
  required UiMessageStrings strings,
  HierarchyWorkshop? workshop,
  required VoidCallback onSaved,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AtlasDialogShell(
      title: strings.tKey(
        workshop == null
            ? PlatformAdminKeys.pageWorkshopsAdd
            : PlatformAdminKeys.pageWorkshopsEdit,
      ),
      body: WorkshopForm(
        workshop: workshop,
        embedded: true,
        onSaved: (_) {
          Navigator.of(dialogContext).pop();
          onSaved();
        },
      ),
      actions: const [],
    ),
  );
}

/// Dialog used for deactivation/reactivation and staff state changes.
Future<String?> showReasonDialog({
  required BuildContext context,
  required UiMessageStrings strings,
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => WorkshopReasonDialog(
      strings: strings,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}
