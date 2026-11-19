import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The four wizard stages. Vertical on desktop (a quiet rail beside the form),
/// a wrapping row of pills on narrower screens.
class WizardStepRail extends StatelessWidget {
  const WizardStepRail({
    required this.current,
    required this.labels,
    this.vertical = false,
    super.key,
  });

  final int current;
  final List<String> labels;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    if (!vertical) {
      return Semantics(
        container: true,
        label: current >= 0 && current < labels.length ? labels[current] : null,
        child: Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          children: [
            for (var index = 0; index < labels.length; index++)
              _stepPill(context, index),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < labels.length; index++)
          Padding(
            padding: EdgeInsetsDirectional.only(
              bottom: index == labels.length - 1 ? 0 : spacing.xs,
            ),
            child: _StepRow(
              number: index + 1,
              label: labels[index],
              state: _stateFor(index),
            ),
          ),
      ],
    );
  }

  Widget _stepPill(BuildContext context, int index) {
    final state = _stateFor(index);
    final tone = switch (state) {
      _StepState.done => WorkshopStatusTone.success,
      _StepState.current => WorkshopStatusTone.accent,
      _StepState.upcoming => WorkshopStatusTone.neutral,
    };
    final icon = switch (state) {
      _StepState.done => Icons.check_circle_outline,
      _StepState.current => Icons.radio_button_checked,
      _StepState.upcoming => Icons.circle_outlined,
    };
    return WorkshopStatusBadge(
      key: Key('jobs-wizard-step-$index'),
      label: '${index + 1}. ${labels[index]}',
      tone: tone,
      icon: icon,
    );
  }

  _StepState _stateFor(int index) {
    if (index < current) {
      return _StepState.done;
    }
    if (index == current) {
      return _StepState.current;
    }
    return _StepState.upcoming;
  }
}

enum _StepState { done, current, upcoming }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.label,
    required this.state,
  });

  final int number;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final current = state == _StepState.current;
    final done = state == _StepState.done;
    final background = current
        ? ws.accentSoft
        : done
        ? ws.successSoft
        : ws.surface;
    final border = current
        ? ws.accent
        : done
        ? ws.success
        : ws.border;
    return Semantics(
      container: true,
      label: '$number. $label',
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ws.chipRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current ? ws.accent : ws.surface,
                border: Border.all(color: border),
              ),
              child: done
                  ? Icon(Icons.check, size: 16, color: ws.success)
                  : Text(
                      '$number',
                      style: ws.meta.copyWith(
                        color: current ? ws.onAccent : ws.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                label,
                style: current
                    ? ws.bodyStrong.copyWith(color: ws.ink)
                    : ws.body.copyWith(color: done ? ws.ink : ws.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
