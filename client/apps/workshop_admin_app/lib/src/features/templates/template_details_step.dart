import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Step 1 — the template's own identity.
///
/// Four fields, label above, hint inside, required validation owned by the
/// page's Form. No helper copy is invented: the only guidance is the field
/// label and the hint the app already ships.
class TemplateDetailsStep extends StatelessWidget {
  const TemplateDetailsStep({
    required this.formKey,
    required this.name,
    required this.description,
    required this.serviceType,
    required this.vehicleType,
    required this.enabled,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController serviceType;
  final TextEditingController vehicleType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ws.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.details, style: ws.cardTitle.copyWith(color: ws.ink)),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 620;
                final service = _field(
                  context,
                  controller: serviceType,
                  label: l10n.serviceType,
                  hint: l10n.serviceType,
                  enabled: enabled,
                );
                final vehicle = _field(
                  context,
                  controller: vehicleType,
                  label: l10n.vehicleType,
                  hint: l10n.vehicleType,
                  enabled: enabled,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      context,
                      controller: name,
                      label: l10n.templateName,
                      hint: l10n.templateName,
                      enabled: enabled,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: service),
                          const SizedBox(width: 14),
                          Expanded(child: vehicle),
                        ],
                      )
                    else ...[
                      service,
                      const SizedBox(height: 14),
                      vehicle,
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            _field(
              context,
              controller: description,
              label: l10n.templateDescription,
              hint: l10n.templateDescription,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    bool required = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return WorkshopTextField(
      controller: controller,
      label: label,
      hint: hint,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
                ? l10n.requiredField
                : null
          : null,
    );
  }
}
