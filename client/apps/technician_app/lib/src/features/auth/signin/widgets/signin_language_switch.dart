import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Two-language switch with 44 px targets.
///
/// On the paper canvas it is a light segmented pill. Over the photo hero it is
/// a single dark pill with white text (no nested light pill), so it stays
/// legible and looks like one control.
class SignInLanguageSwitch extends StatelessWidget {
  const SignInLanguageSwitch({
    required this.isArabic,
    required this.onChanged,
    required this.englishLabel,
    required this.arabicLabel,
    this.englishKey,
    this.arabicKey,
    this.onImage = false,
    super.key,
  });

  final bool isArabic;
  final ValueChanged<bool> onChanged;
  final String englishLabel;
  final String arabicLabel;
  final Key? englishKey;
  final Key? arabicKey;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    if (onImage) {
      return Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(Fx.pillRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _imageSegment(
              key: englishKey,
              label: englishLabel,
              selected: !isArabic,
              onTap: () => onChanged(false),
            ),
            _imageSegment(
              key: arabicKey,
              label: arabicLabel,
              selected: isArabic,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _segment(
          key: englishKey,
          label: englishLabel,
          selected: !isArabic,
          onTap: () => onChanged(false),
        ),
        _segment(
          key: arabicKey,
          label: arabicLabel,
          selected: isArabic,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }

  Widget _imageSegment({
    required Key? key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      key: key,
      button: true,
      selected: selected,
      label: label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48),
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Fx.pillRadius),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Fx.label12.copyWith(
                color: selected ? Fx.white : Fx.white.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segment({
    required Key? key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      key: key,
      button: true,
      selected: selected,
      label: label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: onTap,
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
                  color: selected ? Fx.white : Fx.transparent,
                  borderRadius: BorderRadius.circular(Fx.pillRadius),
                  boxShadow: selected ? Fx.pillShadow : null,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Fx.label12.copyWith(
                    color: selected ? Fx.ink : Fx.muted,
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
