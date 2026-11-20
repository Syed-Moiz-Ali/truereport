import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Create a template — a full page, not a dialog.
///
/// Same payload as the dialog it replaces: trimmed name, description, service
/// type and vehicle type via `createTemplate`. Name is required; the other
/// three are optional and default to the values the dialog pre-filled.
class TemplateCreatePage extends ConsumerStatefulWidget {
  const TemplateCreatePage({super.key});

  @override
  ConsumerState<TemplateCreatePage> createState() => _TemplateCreatePageState();
}

class _TemplateCreatePageState extends ConsumerState<TemplateCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _serviceType = TextEditingController(text: 'FULL');
  final _vehicleType = TextEditingController(text: 'CAR');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _serviceType.dispose();
    _vehicleType.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = UiStrings.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(adminApiProvider)
          .createTemplate(
            name: _name.text.trim(),
            description: _description.text.trim(),
            serviceType: _serviceType.text.trim(),
            vehicleType: _vehicleType.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop<TemplateDetail>(created);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = t(WorkshopAdminKeys.actionFailed);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: ws.topBarHeight,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.pageGutter(width),
              ),
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                  child: Row(
                    children: [
                      WorkshopIconButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        semanticLabel: t(WorkshopAdminKeys.commonBack),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t(WorkshopAdminKeys.newTemplate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ws.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            t(WorkshopAdminKeys.newTemplate),
                            style: ws.pageTitle.copyWith(
                              fontSize: width < 520 ? 26 : 30,
                              letterSpacing: -0.6,
                              color: ws.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(WorkshopAdminKeys.templatesSubtitle),
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: ws.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: ws.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                WorkshopTextField(
                                  key: const Key('template-create-name'),
                                  controller: _name,
                                  label: t(WorkshopAdminKeys.templateName),
                                  hint: t(WorkshopAdminKeys.templateName),
                                  textInputAction: TextInputAction.next,
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                      ? t(WorkshopAdminKeys.requiredField)
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                LayoutBuilder(
                                  builder: (context, c) {
                                    final service = WorkshopTextField(
                                      controller: _serviceType,
                                      label: t(WorkshopAdminKeys.serviceType),
                                      hint: t(WorkshopAdminKeys.serviceType),
                                    );
                                    final vehicle = WorkshopTextField(
                                      controller: _vehicleType,
                                      label: t(WorkshopAdminKeys.vehicleType),
                                      hint: t(WorkshopAdminKeys.vehicleType),
                                    );
                                    if (c.maxWidth < 520) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          service,
                                          const SizedBox(height: 14),
                                          vehicle,
                                        ],
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: service),
                                        const SizedBox(width: 14),
                                        Expanded(child: vehicle),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                                WorkshopTextField(
                                  controller: _description,
                                  label: t(
                                    WorkshopAdminKeys.templateDescription,
                                  ),
                                  hint: t(
                                    WorkshopAdminKeys.templateDescription,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _error!,
                                    style: ws.meta.copyWith(color: ws.danger),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(top: BorderSide(color: ws.border)),
              ),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.pageGutter(width),
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TemplatePillButton(
                        label: t(WorkshopAdminKeys.cancel),
                        variant: TemplatePillVariant.ghost,
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      TemplatePillButton(
                        label: t(WorkshopAdminKeys.create),
                        icon: Icons.add,
                        loading: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
