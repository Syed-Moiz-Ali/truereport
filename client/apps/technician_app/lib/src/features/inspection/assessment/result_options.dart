import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../jobs/queue/jobs_queue_style.dart';

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

/// The verdict in the thumb zone: the served options as 64 px buttons, never
/// disabled, plus any remaining codes as chips below.
///
/// Labels and tones arrive resolved from the served enums; this widget maps
/// nothing itself.
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
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(TechnicianKeys.technicianResult).toUpperCase(),
            style: queueEyebrow(context),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < options.length; index++) ...[
                Expanded(
                  child: _ResultButton(
                    option: options[index],
                    selected: selected == options[index].code,
                    onTap: () => onSelect(options[index].code),
                  ),
                ),
                if (index != options.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in rest)
                  _RestChip(
                    option: option,
                    selected: selected == option.code,
                    onTap: () => onSelect(option.code),
                  ),
              ],
            ),
          ],
          if (suggestion != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 2),
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: 14,
                    color: context.statusColors.info.foreground,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suggestion!,
                    maxLines: 3,
                    style: queueText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      height: 18,
                      color: context.statusColors.info.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: queueText(
                context,
                12.5,
                weight: FontWeight.w600,
                height: 18,
                color: context.statusColors.danger.foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultButton extends StatefulWidget {
  const _ResultButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ResultOptionView option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ResultButton> createState() => _ResultButtonState();
}

class _ResultButtonState extends State<_ResultButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(widget.option.tone);
    final selected = widget.selected;
    return Semantics(
      button: true,
      selected: selected,
      label: widget.option.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: context.motionDuration(const Duration(milliseconds: 120)),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 140),
              ),
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 6,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? pair.background
                    : _hovered
                    ? colors.surfaceContainerLow
                    : colors.surfaceLowest,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusButton),
                border: Border.all(
                  color: _focused
                      ? colors.focus
                      : selected
                      ? pair.foreground
                      : colors.outlineVariant,
                  width: _focused || selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? pair.foreground.withValues(alpha: 0.12)
                          : colors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.option.icon,
                      size: 19,
                      color: selected
                          ? pair.foreground
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.option.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: queueText(
                        context,
                        12.5,
                        weight: FontWeight.w700,
                        height: 16,
                        color: selected ? pair.foreground : colors.onSurface,
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

class _RestChip extends StatelessWidget {
  const _RestChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ResultOptionView option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppFilterChip(
      label: option.label,
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
