import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Primitives for the Workshop Admin sign-in rebuild (direction B, "The bay").
///
/// They live in the app, not in `design_system`, because that package's public
/// barrel (`lib/src/components.dart`) is write-locked — an explicit deny ACL on
/// the file. The guard is deliberate, so this rebuild does not bypass it by
/// editing ACLs; it keeps the screen-specific kit local instead of forking the
/// shared package. Promote them only if the barrel is deliberately reopened.
///
/// Both are parameterised by colour so they hold no palette of their own: the
/// screen passes `ws.*` tokens in, which keeps `source_scan_test` honest and
/// lets the same kit work on ink or on paper.

/// A top-down chassis line drawing used as the workshop's identity mark.
///
/// The bundled SVG is a Figma export with baked greys; it is rendered through a
/// `srcIn` colour filter so only the silhouette survives. The drawing is
/// **always LTR**: mirroring a car in an Arabic build is a credibility bug, so
/// the widget pins its own [Directionality] instead of inheriting the page's.
class WorkshopChassisMark extends StatelessWidget {
  const WorkshopChassisMark({
    super.key,
    required this.color,
    this.width = 340,
    this.semanticLabel,
  });

  static const String asset =
      'packages/design_system/assets/icons/figma/'
      'Minimalist_SVG_Top-Down_Car_Chassis-1_8499.svg';

  final Color color;
  final double width;

  /// When null the drawing is decorative and excluded from semantics.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final picture = Directionality(
      textDirection: TextDirection.ltr,
      child: SvgPicture.asset(
        asset,
        width: width,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );

    final label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: picture);
    }
    return Semantics(image: true, label: label, child: picture);
  }
}

/// Progress expressed as physical ticks rather than a bar.
///
/// Used where a progress bar would read as generic chrome: the sign-in surface
/// shows a 24-item checklist as 24 marks, [done] of them filled. The fill can
/// animate on first paint; it is zero-duration under
/// `MediaQuery.disableAnimations` because the duration comes from
/// `context.motionDuration`.
class WorkshopTickSpine extends StatelessWidget {
  const WorkshopTickSpine({
    super.key,
    required this.done,
    required this.total,
    required this.fillColor,
    required this.trackColor,
    this.semanticLabel,
    this.tickWidth = 7,
    this.tickHeight = 16,
    this.gap = 4,
    this.runGap = 6,
    this.animate = true,
  });

  final int done;
  final int total;
  final Color fillColor;
  final Color trackColor;

  /// Localized description (for example "18 of 24 items"). When null the spine
  /// is treated as decorative and excluded from semantics.
  final String? semanticLabel;

  final double tickWidth;
  final double tickHeight;
  final double gap;
  final double runGap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final clamped = done.clamp(0, total);
    final target = total == 0 ? 0.0 : clamped / total;

    Widget buildTicks(double value) {
      final filled = (value * total).round().clamp(0, total);
      return Wrap(
        spacing: gap,
        runSpacing: runGap,
        children: List<Widget>.generate(
          total,
          (index) => Container(
            width: tickWidth,
            height: tickHeight,
            decoration: BoxDecoration(
              color: index < filled ? fillColor : trackColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    }

    final ticks = animate
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target),
            duration: context.motionDuration(const Duration(milliseconds: 400)),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => buildTicks(value),
          )
        : buildTicks(target);

    final label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: ticks);
    }
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: ticks),
    );
  }
}
