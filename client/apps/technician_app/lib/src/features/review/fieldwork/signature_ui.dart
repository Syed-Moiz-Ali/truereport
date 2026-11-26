import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';

/// The editable signing sheet: the signer's name above the pad, the pad as the
/// hero, then the signed state and any failure with its retry.
class SignatureSigningCard extends StatelessWidget {
  const SignatureSigningCard({
    required this.title,
    required this.hint,
    required this.nameController,
    required this.nameFocus,
    required this.nameLabel,
    required this.nameHint,
    required this.nameHelper,
    required this.nameError,
    required this.onNameChanged,
    required this.onNameSubmitted,
    required this.pad,
    required this.signedName,
    required this.signedLabel,
    required this.error,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String hint;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final String nameLabel;
  final String nameHint;
  final String nameHelper;
  final String? nameError;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onNameSubmitted;
  final Widget pad;

  /// Non-null while the sheet holds both a name and ink.
  final String? signedName;
  final String signedLabel;
  final String? error;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final signed = signedName;
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: fieldworkText(
              context,
              16,
              weight: FontWeight.w800,
              height: 21,
              tracking: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          if (hint.trim().isNotEmpty)
            Text(
              hint,
              style: fieldworkText(
                context,
                12,
                height: 17,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 14),
          AppTextField(
            key: const Key('signature-name'),
            controller: nameController,
            focusNode: nameFocus,
            label: nameLabel,
            labelAbove: true,
            hint: nameHint,
            helperText: nameHelper,
            errorText: nameError,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.done,
            maxLength: 80,
            // The name is spoken, not autocompleted: no autofill hints.
            onChanged: onNameChanged,
            onFieldSubmitted: onNameSubmitted,
          ),
          const SizedBox(height: 16),
          pad,
          if (signed != null && signed.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: context.statusColors.success.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: context.statusColors.success.foreground,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$signed · $signedLabel',
                    maxLines: 2,
                    style: fieldworkText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      height: 18,
                      color: context.statusColors.success.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            FieldworkNote(
              message: error!,
              tone: StatusTone.danger,
              icon: Icons.error_outline_rounded,
            ),
            const SizedBox(height: 8),
            FieldworkButton(
              label: retryLabel,
              icon: Icons.refresh_rounded,
              variant: FieldworkButtonVariant.tonal,
              height: FieldworkMetrics.secondaryHeight,
              expand: true,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// View-only jobs: the reason, nothing to sign, one way back.
class SignatureReadOnlyCard extends StatelessWidget {
  const SignatureReadOnlyCard({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.statusColors.warning.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.visibility_outlined,
              size: 22,
              color: context.statusColors.warning.foreground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: fieldworkText(
                context,
                13.5,
                height: 20,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
