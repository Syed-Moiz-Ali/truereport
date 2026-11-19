import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Two-language switch with 44 px targets and full keyboard access.
///
/// Each segment is a [FocusableActionDetector] (Tab-reachable, activated by
/// Enter/Space) wrapped in a [Semantics] button. The visual pill is 32 px; the
/// hit area is 44 px. The pill is the only shadowed element on the screen.
class SignInLanguageSwitch extends StatelessWidget {
  const SignInLanguageSwitch({
    required this.isArabic,
    required this.onChanged,
    required this.englishLabel,
    required this.arabicLabel,
    this.englishKey,
    this.arabicKey,
    super.key,
  });

  final bool isArabic;
  final ValueChanged<bool> onChanged;
  final String englishLabel;
  final String arabicLabel;
  final Key? englishKey;
  final Key? arabicKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LanguageSegment(
          segmentKey: englishKey,
          label: englishLabel,
          selected: !isArabic,
          onTap: () => onChanged(false),
        ),
        _LanguageSegment(
          segmentKey: arabicKey,
          label: arabicLabel,
          selected: isArabic,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _LanguageSegment extends StatefulWidget {
  const _LanguageSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.segmentKey,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Key? segmentKey;

  @override
  State<_LanguageSegment> createState() => _LanguageSegmentState();
}

class _LanguageSegmentState extends State<_LanguageSegment> {
  late final FocusNode _focus = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted && _focused != _focus.hasFocus) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: widget.segmentKey,
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        focusNode: _focus,
        mouseCursor: SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        onFocusChange: (value) {
          if (mounted && _focused != value) {
            setState(() => _focused = value);
          }
        },
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: widget.selected ? scheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(Fx.pillRadius),
                  boxShadow: widget.selected ? Fx.pillShadow : null,
                  border: _focused
                      ? Border.all(color: scheme.primary, width: 2)
                      : null,
                ),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Fx.label12.copyWith(
                    color: widget.selected
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
