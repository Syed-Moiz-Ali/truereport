import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppIconName {
  mail,
  lock,
  eye,
  arrowForward,
  shieldCheck,
  deliveryReportLink,
  deliveryWorkshopCopy,
}

extension AppIconNameAsset on AppIconName {
  String get asset => switch (this) {
    AppIconName.mail => 'assets/icons/mail.svg',
    AppIconName.lock => 'assets/icons/lock.svg',
    AppIconName.eye => 'assets/icons/eye.svg',
    AppIconName.arrowForward => 'assets/icons/arrow_forward.svg',
    AppIconName.shieldCheck => 'assets/icons/shield_check.svg',
    AppIconName.deliveryReportLink =>
      'assets/icons/delivery_report_link.svg',
    AppIconName.deliveryWorkshopCopy =>
      'assets/icons/delivery_workshop_copy.svg',
  };

  bool get mirrorInRtl => this == AppIconName.arrowForward;
}

/// SVG icon from the provided Figma export, with a stable semantic name.
///
/// The asset names are owned by this package. New icons must be added through
/// the integration lead and recorded in the F1 report.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    this.size,
    this.height,
    this.color,
    this.semanticLabel,
    this.mirror,
    super.key,
  });

  final AppIconName name;
  final double? size;
  final double? height;
  final Color? color;
  final String? semanticLabel;
  final bool? mirror;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? context.sizing.iconLg;
    final resolvedColor = color ?? context.colors.onSurfaceVariant;
    final shouldMirror =
        mirror ??
        (name.mirrorInRtl && Directionality.of(context) == TextDirection.rtl);
    Widget icon = SvgPicture.asset(
      name.asset,
      width: resolvedSize,
      height: height ?? resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
    if (shouldMirror) {
      icon = Transform.flip(flipX: true, child: icon);
    }
    return icon;
  }
}
