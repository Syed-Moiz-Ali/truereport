import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The single primary action.
///
/// `WorkshopButton` cannot serve the submitting state here: its loading variant
/// drops the accent fill and the label, so on the paper canvas the screen's only
/// filled control turns into an empty ghost pill exactly when the user needs to
/// see that something is happening. The design-system widget is write-locked, so
/// this is a local, behaviour-equivalent button:
///
/// - stays accent-filled while busy, with an `onAccent` spinner;
/// - announces the in-flight state through a live region and keeps the
///   accessible name (Flutter has no `busy` semantics flag);
/// - disables taps while busy (a second tap is impossible);
/// - draws the same 2 px focus ring the kit uses, without shifting layout;
/// - keeps the stable `sign-in-submit` key.
class SigninSubmitButton extends StatefulWidget {
  const SigninSubmitButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;

  /// Announced (never shown) while the request is in flight.
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback onPressed;

  /// Gallery only: shows the focus ring in a capture.
  final bool autofocus;

  @override
  State<SigninSubmitButton> createState() => _SigninSubmitButtonState();
}

class _SigninSubmitButtonState extends State<SigninSubmitButton> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final loading = widget.isLoading;

    final button = TextButton(
      key: const Key('sign-in-submit'),
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onPressed: loading ? null : widget.onPressed,
      style: TextButton.styleFrom(
        backgroundColor: ws.accent,
        foregroundColor: ws.onAccent,
        disabledBackgroundColor: ws.accent,
        disabledForegroundColor: ws.onAccent,
        // 4 px reserved for the focus ring so it never shifts layout.
        minimumSize: Size.fromHeight(ws.controlHeight),
        // `padded` adds a 48 px outer box that detached the ring from the fill
        // by 1 px top and bottom; the fill is the tap target.
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ws.controlRadius),
        ),
        padding: EdgeInsets.zero,
        textStyle: ws.bodyStrong,
      ),
      child: loading
          ? ExcludeSemantics(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ws.onAccent,
                ),
              ),
            )
          : Text(
              widget.label,
              style: ws.bodyStrong.copyWith(color: ws.onAccent),
            ),
    );

    final ring = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ws.controlRadius + 2),
        // Always drawn, so the focused state is a colour change, not a resize.
        border: Border.all(color: _focused ? ws.focus : ws.accent, width: 2),
      ),
      child: button,
    );

    if (!loading) {
      return ring;
    }
    return Semantics(
      container: true,
      liveRegion: true,
      enabled: false,
      label: widget.loadingLabel,
      child: ring,
    );
  }
}
