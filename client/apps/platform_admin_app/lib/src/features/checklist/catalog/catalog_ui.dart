import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_theme.dart';

/// Catalog-local semantics for the checklist library.
/// Colours reuse PtTheme; radii/heights follow the premium house style.
abstract final class Catalog {
  static const buttonHeight = 48.0;
  static const buttonRadius = 999.0;
  static const surfaceRadius = 16.0;
  static const fieldHeight = 56.0;
  static const fieldRadius = 16.0;
  static const dialogRadius = 20.0;
  static const fast = Duration(milliseconds: 140);

  static const tint = Color(0xFFE9F3EF);
  static const neutralTint = Color(0xFFF3F1F7);
  static const amberTint = Color(0xFFFBF1E2);
  static const roseTint = Color(0xFFFCEBEF);
  static const blue = Color(0xFF1D4ED8);
  static const blueTint = Color(0xFFE9EEFC);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
    double tracking = 0,
    Color color = PtTheme.ink,
    bool tabular = false,
  }) =>
      PtTheme.font(
        size,
        lineHeight: size * height,
        weight: weight,
        tracking: tracking,
        color: color,
      ).copyWith(
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );

  static TextStyle get eyebrow =>
      text(10.5, weight: FontWeight.w800, tracking: 1.1, color: PtTheme.muted);
  static TextStyle get pageTitle =>
      text(30, weight: FontWeight.w800, tracking: -0.9, height: 1.15);
  static TextStyle get body => text(13, height: 1.5, color: PtTheme.muted);
}

class CatalogSurface extends StatelessWidget {
  const CatalogSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = PtTheme.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(Catalog.surfaceRadius),
      border: Border.all(color: PtTheme.border),
    ),
    child: child,
  );
}

class CatalogButton extends StatefulWidget {
  const CatalogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.danger = false,
    this.compact = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool danger;
  final bool compact;
  final bool isLoading;

  @override
  State<CatalogButton> createState() => _CatalogButtonState();
}

class _CatalogButtonState extends State<CatalogButton> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final bg = widget.secondary
        ? (_hover ? Catalog.neutralTint : PtTheme.white)
        : widget.danger
        ? (_hover ? const Color(0xFFB3123B) : PtTheme.rose)
        : (_hover ? const Color(0xFF04523A) : PtTheme.deepGreen);
    final fg = widget.secondary ? PtTheme.ink : PtTheme.white;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
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
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: Catalog.fast,
              height: Catalog.buttonHeight,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: enabled ? bg : Catalog.neutralTint,
                borderRadius: BorderRadius.circular(Catalog.buttonRadius),
                border: Border.all(
                  color: _focused
                      ? PtTheme.deepGreen
                      : widget.secondary
                      ? PtTheme.border
                      : Colors.transparent,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else if (widget.icon != null)
                    Icon(
                      widget.icon,
                      size: 17,
                      color: enabled ? fg : PtTheme.muted,
                    ),
                  if (widget.isLoading || widget.icon != null)
                    const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Catalog.text(
                        12.5,
                        weight: FontWeight.w700,
                        color: enabled ? fg : PtTheme.muted,
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

enum CatalogTone { good, warn, bad, neutral, info }

class CatalogPill extends StatelessWidget {
  const CatalogPill({
    super.key,
    required this.label,
    this.tone = CatalogTone.neutral,
  });

  final String label;
  final CatalogTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      CatalogTone.good => (PtTheme.deepGreen, Catalog.tint),
      CatalogTone.warn => (PtTheme.gold, Catalog.amberTint),
      CatalogTone.bad => (PtTheme.rose, Catalog.roseTint),
      CatalogTone.info => (Catalog.blue, Catalog.blueTint),
      CatalogTone.neutral => (PtTheme.muted, Catalog.neutralTint),
    };
    return Container(
      height: 30,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Catalog.text(11, weight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class CatalogSearch extends StatelessWidget {
  const CatalogSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: Catalog.fieldHeight,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      textAlignVertical: TextAlignVertical.center,
      style: Catalog.text(12.5),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: Catalog.text(12, color: PtTheme.muted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 17,
          color: PtTheme.muted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: PtTheme.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Catalog.fieldRadius),
          borderSide: const BorderSide(color: PtTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Catalog.fieldRadius),
          borderSide: const BorderSide(color: PtTheme.deepGreen, width: 1.6),
        ),
      ),
    ),
  );
}

class CatalogTabs extends StatelessWidget {
  const CatalogTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 22,
    runSpacing: 6,
    children: [
      for (var i = 0; i < labels.length; i++)
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onSelected(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels[i],
                  style: Catalog.text(
                    12.5,
                    weight: selected == i ? FontWeight.w700 : FontWeight.w500,
                    color: selected == i ? PtTheme.ink : PtTheme.muted,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: Catalog.fast,
                  height: 2,
                  width: selected == i ? 22 : 0,
                  color: PtTheme.deepGreen,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class CatalogField extends StatelessWidget {
  const CatalogField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.hint,
    this.keyboardType,
    this.helper,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final String? hint;
  final TextInputType? keyboardType;
  final String? helper;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Catalog.text(11.5, weight: FontWeight.w700)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textAlignVertical: TextAlignVertical.center,
        style: Catalog.text(12.5),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: Catalog.text(12, color: PtTheme.muted),
          helperText: helper,
          helperStyle: Catalog.text(10.5, color: PtTheme.muted),
          filled: true,
          fillColor: enabled ? PtTheme.white : PtTheme.canvas,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          constraints: const BoxConstraints(minHeight: Catalog.fieldHeight),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Catalog.fieldRadius),
            borderSide: const BorderSide(color: PtTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Catalog.fieldRadius),
            borderSide: const BorderSide(color: PtTheme.deepGreen, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Catalog.fieldRadius),
            borderSide: const BorderSide(color: PtTheme.rose),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Catalog.fieldRadius),
            borderSide: const BorderSide(color: PtTheme.rose, width: 1.6),
          ),
        ),
      ),
    ],
  );
}

class CatalogDialog extends StatelessWidget {
  const CatalogDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.maxWidth = 480,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(Catalog.dialogRadius),
          border: Border.all(color: PtTheme.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Catalog.text(18, weight: FontWeight.w800)),
              const SizedBox(height: 16),
              body,
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CatalogEmpty extends StatelessWidget {
  const CatalogEmpty({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Catalog.text(15, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: Catalog.body),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          CatalogButton(
            label: actionLabel!,
            onPressed: onAction,
            secondary: true,
          ),
        ],
      ],
    ),
  );
}

class CatalogError extends StatelessWidget {
  const CatalogError({super.key, required this.strings, required this.onRetry});

  final UiMessageStrings strings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: CatalogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.tKey(CommonKeys.stateError),
            style: Catalog.text(13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonRetry),
            onPressed: onRetry,
            secondary: true,
          ),
        ],
      ),
    ),
  );
}

class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < rows; i++)
        Container(
          height: 58,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: PtTheme.border.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
    ],
  );
}
