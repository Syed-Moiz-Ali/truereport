import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared F2-B Figma-exact primitives. The lead owns this file; screen builders
/// must not edit it.
class F2bSectionLabel extends StatelessWidget {
  const F2bSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
    );
  }
}

class F2bStatusPill extends StatelessWidget {
  const F2bStatusPill({
    required this.label,
    this.background = Fx.container,
    this.foreground = Fx.muted,
    this.dot,
    this.style,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? dot;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style:
                style ??
                Fx.text(11, 14, FontWeight.w600, 0.44, color: foreground),
          ),
        ],
      ),
    );
  }
}

class F2bIconButton extends StatelessWidget {
  const F2bIconButton({
    required this.iconId,
    required this.semanticLabel,
    this.onPressed,
    this.size = 48,
    this.iconSize = 15,
    this.background = Fx.white,
    this.color = Fx.ink,
    this.shadow = Fx.softShadow,
    super.key,
  });

  final String iconId;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color background;
  final Color color;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onPressed != null,
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: shadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(
              child: FxIcon(id: iconId, size: iconSize, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma three-way pill toggle (52 px track, 40 px options). The caller supplies
/// the labels; selecting an option never changes the drawn geometry.
class F2bSegmented extends StatelessWidget {
  const F2bSegmented({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 52,
    this.optionHeight = 40,
    this.semanticLabels,
    super.key,
  });

  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  final double optionHeight;
  final List<String>? semanticLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                button: true,
                selected: selectedIndex == index,
                label: semanticLabels == null
                    ? labels[index]
                    : semanticLabels![index],
                child: GestureDetector(
                  onTap: () => onSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: optionHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedIndex == index
                          ? Fx.surfaceHigh
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Fx.pillRadius),
                    ),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                      style: Fx.text(
                        12,
                        16,
                        selectedIndex == index
                            ? FontWeight.w700
                            : FontWeight.w600,
                        0.24,
                        color: selectedIndex == index ? Fx.ink : Fx.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class F2bChip extends StatelessWidget {
  const F2bChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingDot,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? leadingDot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected ? Fx.surfaceHigh : Fx.container,
            borderRadius: BorderRadius.circular(Fx.pillRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingDot != null) ...[
                Container(
                  width: 9.33,
                  height: 9.33,
                  decoration: BoxDecoration(
                    color: leadingDot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Fx.text(
                  11,
                  14,
                  FontWeight.w600,
                  0.44,
                  color: selected ? Fx.ink : Fx.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class F2bNoteField extends StatelessWidget {
  const F2bNoteField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(Fx.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 2),
            child: FxIcon(id: '1_8122', size: 13, color: Fx.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: 1,
              style: Fx.body13.copyWith(color: Fx.ink),
              cursorColor: Fx.emerald,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: Fx.body13.copyWith(color: Fx.muted),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class F2bEvidenceTile extends StatelessWidget {
  const F2bEvidenceTile({
    required this.label,
    required this.caption,
    this.image,
    this.onTap,
    this.busy = false,
    super.key,
  });

  final String label;
  final String caption;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final filled = image != null;
    return Semantics(
      button: onTap != null,
      label: '$label. $caption',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 167,
          decoration: BoxDecoration(
            color: filled ? Fx.container : Fx.white,
            borderRadius: BorderRadius.circular(Fx.tileRadius),
            boxShadow: Fx.cardShadow,
            image: image == null
                ? null
                : DecorationImage(image: image!, fit: BoxFit.cover),
          ),
          child: filled
              ? Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: F2bStatusPill(
                      label: label,
                      background: Fx.whiteE5,
                      foreground: Fx.ink,
                      dot: Fx.emerald,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Fx.tintEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Fx.emerald,
                              ),
                            )
                          : const Center(
                              child: FxIcon(
                                id: '1_8115',
                                size: 25,
                                color: Fx.emerald,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Fx.text(
                        14,
                        18,
                        FontWeight.w700,
                        -0.35,
                        color: Fx.ink,
                      ),
                    ),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: Fx.caption.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Slide-to-confirm control. The visible thumb is exactly the Figma 52 px
/// control; the same action is also exposed as an ordinary semantic button so
/// switch access / keyboard users never have to perform the gesture.
class F2bSlideToConfirm extends StatefulWidget {
  const F2bSlideToConfirm({
    required this.label,
    required this.onConfirmed,
    this.enabled = true,
    this.semanticActionLabel,
    super.key,
  });

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;
  final String? semanticActionLabel;

  @override
  State<F2bSlideToConfirm> createState() => _F2bSlideToConfirmState();
}

class _F2bSlideToConfirmState extends State<F2bSlideToConfirm> {
  double _progress = 0;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      label: widget.label,
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Fx.surfaceHighest,
          borderRadius: BorderRadius.circular(Fx.pillRadius),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const thumb = 52.0;
            final travel = math.max(0, constraints.maxWidth - thumb - 12);
            void complete() {
              if (!widget.enabled || _busy) return;
              setState(() {
                _progress = 1;
                _busy = true;
              });
              widget.onConfirmed();
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 52,
                        end: 12,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        style: Fx.text(
                          14,
                          18,
                          FontWeight.w700,
                          0.35,
                          color: Fx.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  left: rtl ? travel * (1 - _progress) : travel * _progress,
                  top: 0,
                  bottom: 0,
                  child: Semantics(
                    button: true,
                    enabled: widget.enabled,
                    label: widget.semanticActionLabel ?? widget.label,
                    onTap: widget.enabled ? complete : null,
                    child: FocusableActionDetector(
                      enabled: widget.enabled,
                      actions: <Type, Action<Intent>>{
                        ActivateIntent: CallbackAction<ActivateIntent>(
                          onInvoke: (_) {
                            complete();
                            return null;
                          },
                        ),
                      },
                      child: GestureDetector(
                        onHorizontalDragUpdate: widget.enabled
                            ? (details) {
                                setState(() {
                                  _progress =
                                      (_progress +
                                              (rtl
                                                      ? -details.delta.dx
                                                      : details.delta.dx) /
                                                  travel)
                                          .clamp(0.0, 1.0);
                                });
                              }
                            : null,
                        onHorizontalDragEnd: widget.enabled
                            ? (_) {
                                if (_progress >= 0.92) {
                                  complete();
                                } else {
                                  setState(() => _progress = 0);
                                }
                              }
                            : null,
                        child: Container(
                          width: thumb,
                          height: thumb,
                          decoration: const BoxDecoration(
                            color: Fx.emerald,
                            shape: BoxShape.circle,
                            boxShadow: Fx.softShadow,
                          ),
                          child: const Center(
                            child: FxIcon(
                              id: '1_8919',
                              size: 16,
                              color: Fx.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class F2bKeyValue extends StatelessWidget {
  const F2bKeyValue({
    required this.label,
    required this.value,
    this.valueStyle,
    this.alignEnd = false,
    super.key,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style:
              valueStyle ??
              Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.inkStrong),
        ),
      ],
    );
  }
}
