import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../signin_tokens.dart';
import 'signin_error_row.dart';
import 'signin_field.dart';
import 'signin_meta_row.dart';
import 'signin_primary.dart';

/// The credential sheet of "Bay Door".
///
/// One translucent panel over the photograph: heading, two cells (in the
/// two-factor state the second cell becomes the code), the primary action, and
/// the access/security meta line. Floating with 24px corners on desktop,
/// pinned to the bottom edge with 26px top corners on phones.
///
/// Every field, the primary action and the meta line keep the keys the host
/// passes in, so the sign-in contract is unchanged.
class SignInSheet extends StatelessWidget {
  const SignInSheet({
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.codeFocus,
    required this.emailLabel,
    required this.passwordLabel,
    required this.codeLabel,
    this.emailHint,
    this.passwordHint,
    required this.primaryLabel,
    this.busyLabel,
    required this.accessPrompt,
    required this.helpLabel,
    required this.securityLine,
    required this.emailValidator,
    required this.passwordValidator,
    required this.codeValidator,
    required this.obscure,
    required this.revealLabel,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.heading,
    required this.subheading,
    this.challenge = false,
    this.busy = false,
    this.pinned = false,
    this.autofocusEmail = false,
    this.errorText,
    this.submitKey,
    this.accessKey,
    this.securityKey,
    this.emailFieldKey,
    this.passwordFieldKey,
    this.codeFieldKey,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FocusNode codeFocus;
  final String emailLabel;
  final String passwordLabel;
  final String codeLabel;
  final String? emailHint;
  final String? passwordHint;
  final String primaryLabel;

  /// Announced while the sign-in request is in flight.
  final String? busyLabel;
  final String accessPrompt;
  final String helpLabel;
  final String securityLine;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> codeValidator;
  final bool obscure;

  /// Action label for the password reveal control: "Show password" while the
  /// value is obscured, "Hide password" while it is visible.
  final String revealLabel;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final String heading;
  final String subheading;
  final bool challenge;
  final bool busy;

  /// True when the sheet is pinned to the bottom edge (phone layout).
  final bool pinned;
  final bool autofocusEmail;
  final String? errorText;
  final Key? submitKey;
  final Key? accessKey;
  final Key? securityKey;
  final Key? emailFieldKey;
  final Key? passwordFieldKey;
  final Key? codeFieldKey;

  @override
  Widget build(BuildContext context) {
    final pad = pinned ? SignInDims.sheetPadPhone : SignInDims.sheetPadWide;
    final radius = pinned
        ? SignInDims.sheetRadiusPhone
        : SignInDims.sheetRadius;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        pad,
        pad,
        pad,
        pinned ? 18 + bottomInset : pad,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radius),
          bottom: Radius.circular(pinned ? 0 : radius),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              heading,
              style: Fx.text(
                pinned ? 20 : 21,
                pinned ? 26 : 27,
                FontWeight.w800,
                -0.3,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subheading,
              style: Fx.text(
                12.5,
                18,
                FontWeight.w400,
                0,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 18),
            _fields(),
            const SizedBox(height: 8),
            SignInErrorRow(message: errorText, onDark: true),
            const SizedBox(height: 6),
            SignInPrimary(
              label: primaryLabel,
              busyLabel: busyLabel,
              onPressed: busy ? null : onSubmit,
              busy: busy,
              blockKey: submitKey,
              onGlass: true,
            ),
            const SizedBox(height: 14),
            SignInMetaRow(
              accessPrompt: accessPrompt,
              helpLabel: helpLabel,
              securityLine: securityLine,
              compact: true,
              accessKey: accessKey,
              securityKey: securityKey,
              onDark: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Two visible cells. In the challenge state the first cell is the
  /// (read-only) account and the second is the one-time code.
  Widget _fields() {
    final email = SignInField(
      controller: emailController,
      label: emailLabel,
      hint: emailHint,
      hintTextDirection: TextDirection.ltr,
      validator: emailValidator,
      focusNode: emailFocus,
      enabled: !challenge,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autofocus: autofocusEmail && !challenge,
      fieldKey: emailFieldKey,
      onDark: true,
    );
    final password = SignInField(
      controller: passwordController,
      label: passwordLabel,
      hint: passwordHint,
      validator: passwordValidator,
      focusNode: passwordFocus,
      obscure: obscure,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      autofillHints: const [AutofillHints.password],
      fieldKey: passwordFieldKey,
      onDark: true,
      suffix: _RevealButton(
        obscured: obscure,
        label: revealLabel,
        onPressed: onToggleObscure,
      ),
    );
    final code = SignInField(
      controller: codeController,
      label: codeLabel,
      validator: codeValidator,
      focusNode: codeFocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      autofillHints: const [AutofillHints.oneTimeCode],
      textCapitalization: TextCapitalization.characters,
      fieldKey: codeFieldKey,
      onDark: true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        email,
        const SizedBox(height: 12),
        challenge ? code : password,
      ],
    );
  }
}

/// 44 x 44 reveal control, announced as a toggle.
class _RevealButton extends StatelessWidget {
  const _RevealButton({
    required this.obscured,
    required this.label,
    required this.onPressed,
  });

  final bool obscured;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: !obscured,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        iconSize: 20,
        color: Colors.white.withValues(alpha: 0.66),
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}
