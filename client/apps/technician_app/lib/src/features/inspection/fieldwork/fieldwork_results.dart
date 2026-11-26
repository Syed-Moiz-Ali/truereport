import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'fieldwork_ui.dart';

/// The glyph for a served result code. Unknown codes get a neutral circle.
IconData resultIcon(String code) => switch (code) {
  'NO_ISSUE_OBSERVED' => Icons.check_rounded,
  'ATTENTION_RECOMMENDED' => Icons.priority_high_rounded,
  'DEFECT_FOUND' => Icons.close_rounded,
  _ => Icons.circle_outlined,
};

/// One served result option, already resolved to copy, tone and icon.
class ResultOptionView {
  const ResultOptionView({
    required this.code,
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String code;
  final String label;
  final StatusTone tone;
  final IconData icon;
}

/// The verdict: exactly the served options as selectable tiles, never
/// disabled. Extra served codes follow as chips. Labels and tones arrive
/// resolved from the served enums; this widget maps nothing itself.
class ResultOptions extends StatelessWidget {
  const ResultOptions({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.rest = const [],
    this.suggestion,
    this.error,
    super.key,
  });

  final List<ResultOptionView> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<ResultOptionView> rest;
  final String? suggestion;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldworkSectionHeader(title: t(TechnicianKeys.technicianResult)),
        const SizedBox(height: 10),
        _ResultGrid(options: options, selected: selected, onSelect: onSelect),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in rest)
                AppFilterChip(
                  label: option.label,
                  selected: selected == option.code,
                  onSelected: (_) => onSelect(option.code),
                ),
            ],
          ),
        ],
        if (suggestion != null) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: suggestion!,
            tone: StatusTone.info,
            icon: Icons.auto_awesome_outlined,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: error!,
            tone: StatusTone.danger,
            icon: Icons.error_outline_rounded,
          ),
        ],
      ],
    );
  }
}

class _ResultGrid extends StatelessWidget {
  const _ResultGrid({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<ResultOptionView> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final stacked =
            width < FieldworkMetrics.stackedResultsBreakpoint || scale > 1.2;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < options.length; index++) ...[
                _ResultTile(
                  option: options[index],
                  selected: selected == options[index].code,
                  stacked: true,
                  onTap: () => onSelect(options[index].code),
                ),
                if (index != options.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        final perRow = width / options.length >= 96 ? options.length : 2;
        final tileWidth = (width - 8 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              SizedBox(
                width: tileWidth,
                child: _ResultTile(
                  option: option,
                  selected: selected == option.code,
                  stacked: false,
                  onTap: () => onSelect(option.code),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResultTile extends StatefulWidget {
  const _ResultTile({
    required this.option,
    required this.selected,
    required this.stacked,
    required this.onTap,
  });

  final ResultOptionView option;
  final bool selected;
  final bool stacked;
  final VoidCallback onTap;

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  bool _hover = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(widget.option.tone);
    final selected = widget.selected;
    final foreground = selected ? pair.foreground : colors.onSurface;
    final icon = Container(
      width: widget.stacked ? 30 : 28,
      height: widget.stacked ? 30 : 28,
      decoration: BoxDecoration(
        color: selected
            ? pair.foreground.withValues(alpha: 0.12)
            : colors.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.option.icon,
        size: widget.stacked ? 17 : 16,
        color: selected ? pair.foreground : colors.onSurfaceVariant,
      ),
    );
    final label = Text(
      widget.option.label,
      textAlign: widget.stacked ? TextAlign.start : TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: fieldworkText(
        context,
        widget.stacked ? 14 : 12.5,
        weight: FontWeight.w700,
        height: widget.stacked ? 18 : 16,
        tracking: -0.1,
        color: foreground,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: widget.option.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hover = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? context.motion.pressScale : 1,
              duration: context.motionDuration(context.motion.fast),
              curve: context.motion.enterCurve,
              child: AnimatedContainer(
                duration: context.motionDuration(context.motion.fast),
                height: widget.stacked ? FieldworkMetrics.primaryHeight : 90,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: widget.stacked ? 14 : 6,
                  vertical: widget.stacked ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? pair.background
                      : _hover
                      ? colors.surfaceContainer
                      : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    FieldworkMetrics.controlRadius,
                  ),
                  border: Border.all(
                    color: _focused
                        ? colors.focus
                        : selected
                        ? pair.foreground
                        : colors.outlineVariant,
                    width: _focused || selected ? 1.6 : 1,
                  ),
                ),
                child: widget.stacked
                    ? Row(
                        children: [
                          icon,
                          const SizedBox(width: 10),
                          Expanded(child: label),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: pair.foreground,
                            ),
                          ],
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [icon, const SizedBox(height: 6), label],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
