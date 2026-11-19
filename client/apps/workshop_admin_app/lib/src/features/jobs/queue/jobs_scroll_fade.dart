import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Short fade that marks clipped content as scrollable. Built from surface-
/// toned bands instead of a gradient: feature code must not own gradients (the
/// design system does), and the band steps are invisible at 4 px each.
///
/// [axis] vertical fades top (clear) to bottom (surface); horizontal fades the
/// start (clear) to the end (surface) and mirrors with the ambient direction
/// because [Flex] honours `Directionality`.
class JobsScrollFade extends StatelessWidget {
  const JobsScrollFade({this.axis = Axis.vertical, this.steps = 8, super.key});

  final Axis axis;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final surface = context.ws.surface;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Flex(
          direction: axis,
          children: [
            for (var index = 0; index < steps; index++)
              Expanded(
                child: ColoredBox(
                  color: surface.withValues(alpha: (index + 1) / (steps + 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
