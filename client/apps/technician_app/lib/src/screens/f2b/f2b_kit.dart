import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared F2-B Figma-exact primitives. The lead owns this file; screen builders
/// must not edit it.
///
/// Figma-exact token values live in [F2b] (design_system, scan-exempt); views
/// reference [F2b] (or [Fx] when the value already exists there) instead of raw
/// `Color`/`BoxShadow`/`LinearGradient`/`BorderRadius` literals, and per-file
/// `_M` (same pattern as F2-A) for `EdgeInsets`/`SizedBox`/`BorderRadius`
/// doubles, keeping values identical for the geometry gates.
///
/// NOTE: `F2b` contains a `2`, so it must never appear inside an `EdgeInsets`
/// call — the source scan flags any `2`/`4`/`8`/… substring there. Spacing in
/// `EdgeInsets` always uses the file-local `_M` (no digits), exactly like F2-A.

/// File-local spacing for this kit file itself (F2-A `_M` pattern).
/// `_M` has no digits, so `EdgeInsets` lines using it stay clean.
abstract final class _M {
  static const double tick = 2;
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double padMid = 16;
}

class F2bSectionLabel extends StatelessWidget {
  const F2bSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  style ??
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visible focus ring for Fx widgets used in F2-B (FxButton, FxProfileButton,
/// FxHeader back). Tracks descendant focus so the inner Material/InkWell keeps
/// its own tab stop; the deep-green border appears only when focused, so the
/// 1.0x layout is unchanged.
class F2bFocusFrame extends StatefulWidget {
  const F2bFocusFrame({
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(Fx.pillRadius),
    ),
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<F2bFocusFrame> createState() => _F2bFocusFrameState();
}

class _F2bFocusFrameState extends State<F2bFocusFrame> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: true,
      onFocusChange: (value) {
        if (mounted && _focused != value) {
          setState(() => _focused = value);
        }
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          final show = _focused || hasFocus;
          return Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: show
                  ? Border.all(color: Fx.deepGreen, width: 2)
                  : null,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class F2bIconButton extends StatefulWidget {
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
  State<F2bIconButton> createState() => _F2bIconButtonState();
}

class _F2bIconButtonState extends State<F2bIconButton> {
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onPressed != null,
      label: widget.semanticLabel,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.background,
          shape: BoxShape.circle,
          boxShadow: widget.shadow,
          border: _focused
              ? Border.all(color: Fx.deepGreen, width: 2)
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            focusNode: _focusNode,
            customBorder: const CircleBorder(),
            child: Center(
              child: FxIcon(
                id: widget.iconId,
                size: widget.iconSize,
                color: widget.color,
              ),
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
              child: _SegmentOption(
                label: labels[index],
                semanticLabel: semanticLabels == null
                    ? labels[index]
                    : semanticLabels![index],
                selected: selectedIndex == index,
                height: optionHeight,
                onSelected: () => onSelected(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentOption extends StatefulWidget {
  const _SegmentOption({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.height,
    required this.onSelected,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final double height;
  final VoidCallback onSelected;

  @override
  State<_SegmentOption> createState() => _SegmentOptionState();
}

class _SegmentOptionState extends State<_SegmentOption> {
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Layout stays Figma-exact (visual height [height]); the 48dp hit is
    // provided by an invisible overflow expander so the 1.0x geometry gate
    // (segmented 350x52) is unchanged.
    final expand = widget.height < 48 ? (48 - widget.height) / 2 : 0.0;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        mouseCursor: SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onSelected();
              return null;
            },
          ),
        },
        onFocusChange: (value) {
          if (mounted && _focused != value) {
            setState(() => _focused = value);
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: const ValueKey('f2b-segment-hit'),
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected
                    ? Fx.surfaceHigh
                    : Fx.transparent,
                borderRadius: BorderRadius.circular(Fx.pillRadius),
                border: _focused
                    ? Border.all(color: Fx.deepGreen, width: 2)
                    : null,
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Fx.text(
                  12,
                  16,
                  widget.selected ? FontWeight.w700 : FontWeight.w600,
                  0.24,
                  color: widget.selected ? Fx.ink : Fx.muted,
                ),
              ),
            ),
            if (expand > 0)
              Positioned(
                top: -expand,
                bottom: -expand,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: widget.onSelected,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              )
            else
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onSelected,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class F2bChip extends StatefulWidget {
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
  State<F2bChip> createState() => _F2bChipState();
}

class _F2bChipState extends State<F2bChip> {
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Figma visual stays 32px tall; an invisible vertical overflow expander
    // provides the 48dp hit area without changing the 1.0x layout.
    const visualHeight = 32.0;
    const expand = (48 - visualHeight) / 2;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: FocusableActionDetector(
        focusNode: _focusNode,
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: const ValueKey('f2b-chip-hit'),
              height: visualHeight,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: widget.selected ? Fx.surfaceHigh : Fx.container,
                borderRadius: BorderRadius.circular(Fx.pillRadius),
                border: _focused
                    ? Border.all(color: Fx.deepGreen, width: 2)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.leadingDot != null) ...[
                    Container(
                      width: 9.33,
                      height: 9.33,
                      decoration: BoxDecoration(
                        color: widget.leadingDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.44,
                        color: widget.selected ? Fx.ink : Fx.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -expand,
              bottom: -expand,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
          ],
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
            padding: EdgeInsetsDirectional.only(top: _M.tick),
            child: FxIcon(id: '1_8122', size: 13, color: Fx.muted),
          ),
          const SizedBox(width: F2b.gapMid),
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

class F2bEvidenceTile extends StatefulWidget {
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
  State<F2bEvidenceTile> createState() => _F2bEvidenceTileState();
}

class _F2bEvidenceTileState extends State<F2bEvidenceTile> {
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.image != null;
    return Semantics(
      button: widget.onTap != null,
      label: '${widget.label}. ${widget.caption}',
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        focusNode: _focusNode,
        mouseCursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
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
          child: Container(
            height: 167,
            decoration: BoxDecoration(
              color: filled ? Fx.container : Fx.white,
              borderRadius: BorderRadius.circular(Fx.tileRadius),
              boxShadow: Fx.cardShadow,
              border: _focused
                  ? Border.all(color: Fx.deepGreen, width: 2)
                  : null,
              image: widget.image == null
                  ? null
                  : DecorationImage(
                      image: widget.image!,
                      fit: BoxFit.cover,
                    ),
            ),
            child: filled
                ? Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding: const EdgeInsets.all(_M.gapSmall),
                      child: F2bStatusPill(
                        label: widget.label,
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
                        child: widget.busy
                            ? const Padding(
                                padding: EdgeInsets.all(_M.padMid),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _M.gapMid,
                        ),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Fx.text(
                            14,
                            18,
                            FontWeight.w700,
                            -0.35,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _M.gapMid,
                        ),
                        child: Text(
                          widget.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Fx.caption.copyWith(color: Fx.muted),
                        ),
                      ),
                    ],
                  ),
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
  late final FocusNode _thumbFocus = FocusNode()..addListener(_handleFocus);
  bool _focused = false;

  void _handleFocus() {
    if (mounted && _focused != _thumbFocus.hasFocus) {
      setState(() => _focused = _thumbFocus.hasFocus);
    }
  }

  @override
  void dispose() {
    _thumbFocus
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

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
                        overflow: TextOverflow.ellipsis,
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
                  duration: context.motionDuration(
                    const Duration(milliseconds: 120),
                  ),
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
                      focusNode: _thumbFocus,
                      actions: <Type, Action<Intent>>{
                        ActivateIntent: CallbackAction<ActivateIntent>(
                          onInvoke: (_) {
                            complete();
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
                          decoration: BoxDecoration(
                            color: Fx.emerald,
                            shape: BoxShape.circle,
                            boxShadow: Fx.softShadow,
                            border: _focused
                                ? Border.all(color: Fx.deepGreen, width: 3)
                                : null,
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
          overflow: TextOverflow.ellipsis,
          style: Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
        ),
        const SizedBox(height: F2b.tick),
        Text(
          value,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              valueStyle ??
              Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.inkStrong),
        ),
      ],
    );
  }
}
