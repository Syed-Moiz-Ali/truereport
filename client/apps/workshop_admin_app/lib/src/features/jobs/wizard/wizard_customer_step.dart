import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Step 1: the customer the job is opened for. Phone is required; email is
/// optional but must look like an address when present (validated on Next).
class WizardCustomerStep extends StatelessWidget {
  const WizardCustomerStep({
    required this.name,
    required this.phone,
    required this.email,
    super.key,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopTextField(
          key: const Key('jobs-wizard-customer-name'),
          controller: name,
          label: l10n.customerName,
          hint: l10n.fullNameHint,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          prefixIcon: const Icon(Icons.person_outline),
        ),
        SizedBox(height: spacing.md),
        WorkshopTextField(
          key: const Key('jobs-wizard-customer-phone'),
          controller: phone,
          label: l10n.customerPhone,
          hint: l10n.contactPhone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        SizedBox(height: spacing.md),
        WorkshopTextField(
          key: const Key('jobs-wizard-customer-email'),
          controller: email,
          label: l10n.customerEmail,
          hint: l10n.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          prefixIcon: const Icon(Icons.email_outlined),
        ),
      ],
    );
  }
}
