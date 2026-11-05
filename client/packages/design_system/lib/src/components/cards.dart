import 'package:design_system/src/components/figma_components.dart';
import 'package:design_system/src/components/icons.dart';
import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

enum AppCardVariant { raised, flat, tonal }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.variant = AppCardVariant.raised,
    this.onTap,
    this.semanticLabel,
    this.radius,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Figma uses 24 for compact cards and 32/48 for large cards and sheets.
  /// When null the product `radii.card` (24) is used.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final radii = context.radii;
    final sizing = context.sizing;
    final radius = BorderRadius.circular(this.radius ?? radii.card);

    final (Color background, List<BoxShadow>? shadow) = switch (variant) {
      AppCardVariant.raised => (
        colors.surfaceContainerLowest,
        context.shadows.card,
      ),
      AppCardVariant.flat => (colors.surfaceContainerLow, null),
      AppCardVariant.tonal => (brand.container, null),
    };

    final content = Padding(
      padding: padding ?? EdgeInsetsDirectional.all(sizing.cardPadding),
      child: child,
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        boxShadow: shadow,
      ),
      child: onTap == null
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
            ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: card,
    );
  }
}

class AppTonalCard extends StatelessWidget {
  const AppTonalCard({
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.tonal,
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

/// Product delivery-status card derived from the Figma card.
///
/// The structure, radii, spacing and shadows are the Figma values. Only the
/// copy and the data change: the Figma channel names are replaced with the
/// product's report-link and workshop-copy labels.
class AppDeliveryStatusCard extends StatelessWidget {
  const AppDeliveryStatusCard({
    required this.reportLinkLabel,
    required this.reportLinkStatus,
    required this.workshopCopyLabel,
    required this.workshopCopyStatus,
    this.semanticLabel,
    super.key,
  });

  final String reportLinkLabel;
  final String reportLinkStatus;
  final String workshopCopyLabel;
  final String workshopCopyStatus;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FigmaDeliveryStatusCard(
      semanticLabel: semanticLabel,
      items: [
        FigmaDeliveryItem(
          icon: AppIconName.deliveryReportLink,
          label: reportLinkLabel,
          status: reportLinkStatus,
        ),
        FigmaDeliveryItem(
          icon: AppIconName.deliveryWorkshopCopy,
          label: workshopCopyLabel,
          status: workshopCopyStatus,
          iconWidth: 18.33,
          iconHeight: 13.33,
        ),
      ],
    );
  }
}

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.variant = AppCardVariant.raised,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    return AppCard(
      variant: variant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: context.sizing.iconLg,
                  color: context.brand.ink,
                ),
                SizedBox(width: spacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            value,
            style: context.texts.headlineLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: spacing.xs),
            Text(
              caption!,
              style: context.texts.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
