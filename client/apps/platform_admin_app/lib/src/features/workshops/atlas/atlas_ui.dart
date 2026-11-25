import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../platform_theme.dart';

/// Module-local semantic additions for the Atlas workspace.
///
/// Only layout/elevation semantics are added; every colour comes from the
/// existing [PtTheme] roles. Flagged as a divergence in the sprint report:
/// these radii are the premium house style (14/16/999) and are not yet shared
/// with the rest of Platform Admin.
abstract final class Atlas {
  static const double buttonHeight = 48;
  static const double fieldHeight = 56;
  static const double buttonRadius = 999;
  static const double fieldRadius = 16;
  static const double surfaceRadius = 16;
  static const double dialogRadius = 20;
  static const double pillHeight = 30;
  static const double panelGap = 20;
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration settle = Duration(milliseconds: 220);

  static const Color accentTint = Color(0xFFE9F3EF);
  static const Color accentDeep = Color(0xFF04523A);
  static const Color neutralTint = Color(0xFFF1F0F5);
  static const Color amberTint = Color(0xFFFBF1E2);
  static const Color roseTint = Color(0xFFFCEBEF);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double tracking = 0,
    Color color = PtTheme.ink,
    bool tabular = false,
  }) {
    return PtTheme.font(
      size,
      lineHeight: height == null ? null : size * height,
      weight: weight,
      tracking: tracking,
      color: color,
    ).copyWith(
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static TextStyle get eyebrow =>
      text(10.5, weight: FontWeight.w800, tracking: 1.1, color: PtTheme.muted);

  static TextStyle get pageTitle =>
      text(30, weight: FontWeight.w800, tracking: -0.9, height: 1.2);

  static TextStyle get sectionTitle =>
      text(17, weight: FontWeight.w800, tracking: -0.2);

  static TextStyle get body => text(13, height: 1.5, color: PtTheme.ink);

  static TextStyle get meta => text(11.5, height: 1.4, color: PtTheme.muted);

  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return parts.isEmpty ? '—' : parts;
  }
}

class AtlasSurface extends StatelessWidget {
  const AtlasSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = PtTheme.white,
    this.radius = Atlas.surfaceRadius,
    this.borderColor = PtTheme.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

enum AtlasButtonVariant { primary, secondary, ghost, ghostDanger, danger }

class AtlasButton extends StatefulWidget {
  const AtlasButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AtlasButtonVariant.primary,
    this.isLoading = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AtlasButtonVariant variant;
  final bool isLoading;
  final bool compact;

  @override
  State<AtlasButton> createState() => _AtlasButtonState();
}

class _AtlasButtonState extends State<AtlasButton> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final v = widget.variant;
    final background = switch (v) {
      AtlasButtonVariant.primary =>
        _hover ? Atlas.accentDeep : PtTheme.deepGreen,
      AtlasButtonVariant.secondary =>
        _hover ? Atlas.neutralTint : PtTheme.white,
      AtlasButtonVariant.ghost =>
        _hover ? Atlas.neutralTint : Colors.transparent,
      AtlasButtonVariant.ghostDanger =>
        _hover ? Atlas.roseTint : Colors.transparent,
      AtlasButtonVariant.danger =>
        _hover ? const Color(0xFFB3123B) : PtTheme.rose,
    };
    final foreground = switch (v) {
      AtlasButtonVariant.primary || AtlasButtonVariant.danger => PtTheme.white,
      AtlasButtonVariant.secondary => PtTheme.ink,
      AtlasButtonVariant.ghost => PtTheme.muted,
      AtlasButtonVariant.ghostDanger => PtTheme.rose,
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: Atlas.fast,
              height: Atlas.buttonHeight,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 14 : 20,
              ),
              decoration: BoxDecoration(
                color: enabled ? background : Atlas.neutralTint,
                borderRadius: BorderRadius.circular(Atlas.buttonRadius),
                border: Border.all(
                  color: _focused
                      ? PtTheme.deepGreen
                      : v == AtlasButtonVariant.secondary
                      ? PtTheme.border
                      : Colors.transparent,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  else if (widget.icon != null)
                    Icon(
                      widget.icon,
                      size: 18,
                      color: enabled
                          ? foreground
                          : PtTheme.muted.withValues(alpha: 0.6),
                    ),
                  if (widget.isLoading || widget.icon != null)
                    const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Atlas.text(
                        13.5,
                        weight: FontWeight.w700,
                        color: enabled
                            ? foreground
                            : PtTheme.muted.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AtlasIconButton extends StatelessWidget {
  const AtlasIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PtTheme.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 19,
                color: danger ? PtTheme.rose : PtTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AtlasTone { positive, neutral, warning, danger, info }

class AtlasPill extends StatelessWidget {
  const AtlasPill({
    super.key,
    required this.label,
    this.tone = AtlasTone.neutral,
    this.dot = true,
  });

  final String label;
  final AtlasTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      AtlasTone.positive => (PtTheme.deepGreen, Atlas.accentTint),
      AtlasTone.neutral => (PtTheme.muted, Atlas.neutralTint),
      AtlasTone.warning => (PtTheme.gold, Atlas.amberTint),
      AtlasTone.danger => (PtTheme.rose, Atlas.roseTint),
      AtlasTone.info => (const Color(0xFF1D4ED8), const Color(0xFFE9EEFC)),
    };
    return Container(
      height: Atlas.pillHeight,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Atlas.text(11.5, weight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasMonogram extends StatelessWidget {
  const AtlasMonogram({
    super.key,
    required this.name,
    this.size = 40,
    this.muted = false,
  });

  final String name;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tone = muted ? PtTheme.muted : PtTheme.deepGreen;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Text(
        Atlas.initials(name),
        maxLines: 1,
        style: Atlas.text(
          size * 0.32,
          weight: FontWeight.w800,
          color: tone,
          tracking: 0.2,
        ),
      ),
    );
  }
}

/// Underline tab row used by the record. Keyboard reachable, no Material TabBar.
class AtlasTabs extends StatelessWidget {
  const AtlasTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          Semantics(
            selected: selected == i,
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onSelected(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[i],
                        style: Atlas.text(
                          12.5,
                          weight: selected == i
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected == i ? PtTheme.ink : PtTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: Atlas.fast,
                        height: 2,
                        width: selected == i ? 24 : 0,
                        color: PtTheme.deepGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AtlasGauge extends StatelessWidget {
  const AtlasGauge({
    super.key,
    required this.value,
    this.size = 104,
    this.stroke = 9,
  });

  final int value;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final tone = value >= 90 ? PtTheme.amber : PtTheme.deepGreen;
    final textTone = value >= 90 ? PtTheme.gold : PtTheme.deepGreen;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(value / 100, stroke, tone),
        child: Center(
          child: Text(
            '$value%',
            style: Atlas.text(
              size * 0.28,
              weight: FontWeight.w800,
              tracking: -0.8,
              tabular: true,
              color: value == 0 ? PtTheme.muted : textTone,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value, this.stroke, this.tone);

  final double value;
  final double stroke;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = PtTheme.border;
    canvas.drawCircle(center, radius, track);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = tone;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * value.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.tone != tone || old.stroke != stroke;
}

class AtlasCapacityBar extends StatelessWidget {
  const AtlasCapacityBar({super.key, required this.value, this.height = 6});

  final int value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tone = value >= 90
        ? PtTheme.amber
        : value == 0
        ? PtTheme.border
        : PtTheme.deepGreen;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: PtTheme.border.withValues(alpha: 0.8)),
            FractionallySizedBox(
              widthFactor: (value / 100).clamp(0.0, 1.0),
              child: Container(color: tone),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label above + hint + helper + on-blur-then-live validation.
class AtlasTextField extends StatefulWidget {
  const AtlasTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
    this.helperText,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLength,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final FormFieldValidator<String> validator;
  final String? helperText;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  State<AtlasTextField> createState() => _AtlasTextFieldState();
}

class _AtlasTextFieldState extends State<AtlasTextField> {
  bool _touched = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: Atlas.text(12, weight: FontWeight.w700)),
        const SizedBox(height: 7),
        Focus(
          onFocusChange: (value) {
            if (!value) setState(() => _touched = true);
          },
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: widget.validator,
            maxLength: widget.maxLength,
            autofillHints: widget.autofillHints,
            obscureText: widget.obscureText,
            autovalidateMode: _touched
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            style: Atlas.text(13.5),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: Atlas.text(13.5, color: PtTheme.muted),
              filled: true,
              fillColor: PtTheme.white,
              counterText: '',
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              constraints: const BoxConstraints(minHeight: Atlas.fieldHeight),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Atlas.fieldRadius),
                borderSide: const BorderSide(color: PtTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Atlas.fieldRadius),
                borderSide: const BorderSide(
                  color: PtTheme.deepGreen,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Atlas.fieldRadius),
                borderSide: const BorderSide(color: PtTheme.rose),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Atlas.fieldRadius),
                borderSide: const BorderSide(color: PtTheme.rose, width: 1.6),
              ),
              errorStyle: Atlas.text(
                11.5,
                weight: FontWeight.w600,
                color: PtTheme.rose,
              ),
              helperText: widget.helperText,
              helperStyle: Atlas.text(11.5, color: PtTheme.muted),
              helperMaxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class AtlasSearchField extends StatelessWidget {
  const AtlasSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: Atlas.text(13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: Atlas.text(12.5, color: PtTheme.muted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: PtTheme.muted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 42),
          filled: true,
          fillColor: PtTheme.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Atlas.fieldRadius),
            borderSide: const BorderSide(color: PtTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Atlas.fieldRadius),
            borderSide: const BorderSide(color: PtTheme.deepGreen, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class AtlasDialogShell extends StatelessWidget {
  const AtlasDialogShell({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.maxWidth = 520,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(Atlas.dialogRadius),
            border: Border.all(color: PtTheme.border),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Atlas.text(
                    19,
                    weight: FontWeight.w800,
                    tracking: -0.3,
                  ),
                ),
                const SizedBox(height: 18),
                body,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AtlasSkeletonRows extends StatefulWidget {
  const AtlasSkeletonRows({super.key, this.rows = 5, this.height = 72});

  final int rows;
  final double height;

  @override
  State<AtlasSkeletonRows> createState() => _AtlasSkeletonRowsState();
}

class _AtlasSkeletonRowsState extends State<AtlasSkeletonRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = animate ? 0.45 + (_controller.value * 0.35) : 0.6;
        return Column(
          children: [
            for (var i = 0; i < widget.rows; i++)
              Container(
                height: widget.height,
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: PtTheme.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: PtTheme.border.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 11,
                            decoration: BoxDecoration(
                              color: PtTheme.border.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 110,
                            height: 9,
                            decoration: BoxDecoration(
                              color: PtTheme.border.withValues(
                                alpha: opacity * 0.8,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class AtlasKeyRow extends StatelessWidget {
  const AtlasKeyRow({
    super.key,
    required this.label,
    required this.value,
    this.last = false,
    this.valueColor = PtTheme.ink,
  });

  final String label;
  final String value;
  final bool last;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: PtTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Atlas.text(11.5, color: PtTheme.muted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Atlas.text(
                12.5,
                weight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AtlasEmpty extends StatelessWidget {
  const AtlasEmpty({
    super.key,
    required this.title,
    this.body,
    this.icon = Icons.storefront_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Atlas.accentTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: PtTheme.deepGreen),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Atlas.text(15, weight: FontWeight.w700),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: Atlas.text(12, height: 1.5, color: PtTheme.muted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            AtlasButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AtlasButtonVariant.secondary,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

AtlasTone workshopTone(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized == 'ACTIVE' || normalized == 'PUBLISHED') {
    return AtlasTone.positive;
  }
  if (normalized == 'STANDBY') return AtlasTone.warning;
  if (normalized == 'RETIRED' || normalized == 'DISABLED') {
    return AtlasTone.danger;
  }
  return AtlasTone.neutral;
}
