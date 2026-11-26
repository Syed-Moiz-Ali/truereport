import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../signin_tokens.dart';

/// A labelled credential cell for "The dock".
///
/// The label is persistent above the cell (never a placeholder), the input is
/// LTR in both locales, and validation messages render under the cell so the
/// dock grows upward from its fixed bottom edge instead of shifting the
/// primary action.
class SignInField extends StatefulWidget {
  const SignInField({
    required this.controller,
    required this.label,
    required this.validator,
    this.focusNode,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.hint,
    this.hintTextDirection,
    this.suffix,
    this.fieldKey,
    this.onDark = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final FocusNode? focusNode;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final String? hint;

  /// Direction for the raised hint. LTR credentials (email) keep their hint
  /// aligned with the LTR input instead of the RTL interface.
  final TextDirection? hintTextDirection;
  final Widget? suffix;
  final Key? fieldKey;

  /// Renders the cell for a dark translucent surface (the "Bay Door" sheet):
  /// white label, translucent white fill and border, white input text.
  final bool onDark;

  @override
  State<SignInField> createState() => _SignInFieldState();
}

class _SignInFieldState extends State<SignInField> {
  FocusNode? _internalFocus;

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void dispose() {
    _internalFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onDark = widget.onDark;
    final labelStyle = Fx.label12Wide.copyWith(
      color: onDark
          ? Colors.white.withValues(alpha: 0.86)
          : scheme.onSurfaceVariant,
    );
    final errorColor = onDark ? const Color(0xFFFFC9C4) : scheme.error;

    return FormField<String>(
      validator: (_) => widget.validator(widget.controller.text),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
            const SizedBox(height: SignInDims.labelGap),
            ListenableBuilder(
              listenable: _focus,
              builder: (context, _) {
                final focused = _focus.hasFocus;
                final invalid = state.hasError;
                final Color borderColor;
                if (invalid) {
                  borderColor = errorColor;
                } else if (onDark) {
                  borderColor = focused
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.30);
                } else {
                  borderColor = focused
                      ? scheme.primary
                      : scheme.outlineVariant;
                }
                return Semantics(
                  label: widget.label,
                  textField: true,
                  child: GestureDetector(
                    // The visible cell is 56 high; the TextField itself is
                    // only one line. Tapping the cell's padding must focus the
                    // field (the 44 px target is the cell, not the glyph).
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: widget.enabled ? () => _focus.requestFocus() : null,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: SignInDims.cellHeight,
                      ),
                      padding: const EdgeInsetsDirectional.only(
                        start: 14,
                        end: 2,
                      ),
                      decoration: BoxDecoration(
                        color: onDark
                            ? Colors.white.withValues(
                                alpha: widget.enabled ? 0.14 : 0.07,
                              )
                            : widget.enabled
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          SignInDims.cellRadius,
                        ),
                        border: Border.all(
                          color: borderColor,
                          width: focused || invalid ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: widget.fieldKey,
                              controller: widget.controller,
                              focusNode: _focus,
                              enabled: widget.enabled,
                              obscureText: widget.obscure,
                              keyboardType: widget.keyboardType,
                              textInputAction: widget.textInputAction,
                              textCapitalization: widget.textCapitalization,
                              autofillHints: widget.autofillHints,
                              inputFormatters: widget.inputFormatters,
                              autofocus: widget.autofocus,
                              autocorrect: widget.autocorrect,
                              enableSuggestions: widget.enableSuggestions,
                              onSubmitted: widget.onSubmitted,
                              onChanged: (value) {
                                widget.onChanged?.call(value);
                                state.didChange(value);
                              },
                              // Identifiers and codes stay LTR in both locales.
                              textDirection: TextDirection.ltr,
                              style: Fx.text(
                                16,
                                24,
                                FontWeight.w500,
                                -0.16,
                                color: onDark ? Colors.white : scheme.onSurface,
                              ),
                              cursorColor: onDark
                                  ? Colors.white
                                  : scheme.primary,
                              decoration: InputDecoration(
                                isDense: true,
                                // The app theme fills inputs by default; on the
                                // dark glass sheet that fill would paint an
                                // opaque bar over the photograph (and hide the
                                // white input text).
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.hint,
                                hintTextDirection: widget.hintTextDirection,
                                hintStyle: Fx.text(
                                  16,
                                  24,
                                  FontWeight.w400,
                                  0,
                                  color: onDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : scheme.onSurfaceVariant.withValues(
                                          alpha: 0.55,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          ?widget.suffix,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    state.errorText!,
                    maxLines: 2,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w500,
                      0,
                      color: errorColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
