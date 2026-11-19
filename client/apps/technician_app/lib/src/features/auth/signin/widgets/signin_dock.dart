import 'package:flutter/material.dart';

import '../signin_tokens.dart';
import 'signin_error_row.dart';
import 'signin_field.dart';
import 'signin_meta_row.dart';
import 'signin_primary.dart';

/// The credential band of "The dock".
///
/// One responsive composition with three modes:
/// - **horizontal** (>= 1024 and normal text): email, password, primary in a row
/// - **twoRow** (600..1023): fields in a row, primary full width
/// - **stacked** (< 600 or text scale >= 1.4): everything full width, primary
///   last, meta line above the band
///
/// The band's bottom edge is fixed to the viewport; error text grows the band
/// upward, so the primary action never jumps.
class SignInDock extends StatelessWidget {
  const SignInDock({
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
    required this.accessPrompt,
    required this.helpLabel,
    required this.securityLine,
    required this.emailValidator,
    required this.passwordValidator,
    required this.codeValidator,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    this.challenge = false,
    this.busy = false,
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
  final String accessPrompt;
  final String helpLabel;
  final String securityLine;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> codeValidator;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool challenge;
  final bool busy;
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
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final horizontal =
        width >= SignInDims.bandRow && scale < SignInDims.stackScale;
    final stacked =
        width < SignInDims.stacked || scale >= SignInDims.stackScale;
    final gutter = width >= SignInDims.wide
        ? SignInDims.gutterWide
        : width >= SignInDims.stacked
        ? SignInDims.gutterTablet
        : SignInDims.gutterPhone;

    final meta = SignInMetaRow(
      accessPrompt: accessPrompt,
      helpLabel: helpLabel,
      securityLine: securityLine,
      compact: stacked,
      accessKey: accessKey,
      securityKey: securityKey,
    );
    final primary = SignInPrimary(
      label: primaryLabel,
      onPressed: busy ? null : onSubmit,
      busy: busy,
      blockKey: submitKey,
    );

    final fields = _fields(horizontal: horizontal);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: horizontal ? 32 : SignInDims.dockPadTop,
              bottom:
                  (horizontal
                      ? SignInDims.dockPadBottomWide
                      : SignInDims.dockPadBottom) +
                  bottomInset,
              start: gutter,
              end: gutter,
            ),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (horizontal)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(flex: 4, child: fields[0]),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: fields[1]),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: SignInDims.primaryWidth,
                          child: primary,
                        ),
                      ],
                    )
                  else if (!stacked)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 24),
                        Expanded(child: fields[1]),
                      ],
                    )
                  else ...[
                    fields[0],
                    const SizedBox(height: 14),
                    fields[1],
                  ],
                  SizedBox(height: errorText == null ? 12 : 8),
                  SignInErrorRow(message: errorText, alignEnd: horizontal),
                  if (!horizontal) ...[
                    SizedBox(height: errorText == null ? 12 : 4),
                    primary,
                  ],
                  const SizedBox(height: 16),
                  meta,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the two visible cells. In the challenge state the first cell is
  /// the (read-only) account and the second is the code.
  List<Widget> _fields({required bool horizontal}) {
    final email = SignInField(
      controller: emailController,
      label: emailLabel,
      hint: emailHint,
      validator: emailValidator,
      focusNode: emailFocus,
      enabled: !challenge,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autofocus: autofocusEmail && !challenge,
      fieldKey: emailFieldKey,
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
      suffix: _RevealButton(
        obscured: obscure,
        label: passwordLabel,
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
    );
    return [email, challenge ? code : password];
  }
}

/// 44 x 44 reveal control with a state that is announced.
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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      toggled: !obscured,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        iconSize: 20,
        color: scheme.onSurfaceVariant,
        icon: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}
