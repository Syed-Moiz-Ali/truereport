import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

/// Test-only Figma-exact fixtures and the owner's pending primary-button
/// options. This section is hidden in release builds by `FixtureGuard`.
class FidelityShowcase extends StatelessWidget {
  const FidelityShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GalleryTile(
          label: 'Figma-exact primary button (option 1, node 342 x 56)',
          child: _FigmaPlane(
            width: 390,
            height: 120,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: FigmaGeometry.planeButtonStart,
                top: FigmaGeometry.planeButtonTop,
              ),
              child: FigmaPrimaryButton(
                label: 'Sign In',
                onPressed: _noop,
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        GalleryTile(
          label: 'Figma-exact delivery status card (350 x 145)',
          child: _FigmaPlane(
            width: 390,
            height: 185,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FigmaGeometry.planeCardStart,
                top: FigmaGeometry.planeCardTop,
              ),
              child: FigmaDeliveryStatusCard(
                semanticLabel: 'Delivery status',
                items: const [
                  FigmaDeliveryItem(
                    icon: AppIconName.deliveryReportLink,
                    label: 'WhatsApp',
                    status: 'Sent',
                  ),
                  FigmaDeliveryItem(
                    icon: AppIconName.deliveryWorkshopCopy,
                    label: 'Fleet Portal',
                    status: 'Synced',
                    iconWidth: 18.33,
                    iconHeight: 13.33,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        GalleryTile(
          label: 'Figma-exact result selector (Pass / Minor / Major)',
          child: _FigmaPlane(
            width: 390,
            height: 110,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: FigmaGeometry.planeSelectorStart,
                top: FigmaGeometry.planeSelectorTop,
              ),
              child: FigmaThreeWaySelector<String>(
                label: 'Inspection status',
                semanticLabel: 'INSPECTION STATUS',
                options: const [
                  FigmaResultOption(value: 'pass', label: 'Pass'),
                  FigmaResultOption(value: 'minor', label: 'Minor'),
                  FigmaResultOption(value: 'major', label: 'Major'),
                ],
                selected: 'minor',
                onChanged: _ignore,
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.xxl),
        Text(
          'Product variants (approved copy and data only)',
          style: context.texts.titleMedium,
        ),
        SizedBox(height: context.spacing.sm),
        const GalleryTile(
          label: 'Product delivery status card',
          child: AppDeliveryStatusCard(
            reportLinkLabel: 'Report link',
            reportLinkStatus: 'Sent',
            workshopCopyLabel: 'Workshop copy',
            workshopCopyStatus: 'Synced',
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const GalleryTile(
          label: 'Product result selector: three-way toggle + secondary chips',
          child: InspectionResultSelector(
            groupLabel: 'Inspection status',
            selected: InspectionResult.attentionRecommended,
            onChanged: _ignore,
            labelBuilder: _resultLabel,
          ),
        ),
      ],
    );
  }
}

/// The four primary-button options, in English and Arabic, at 1.0x and 2.0x.
class PrimaryButtonOptionsShowcase extends StatelessWidget {
  const PrimaryButtonOptionsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final spec in FigmaPrimaryButtonSpec.all) ...[
          Text(spec.title, style: context.texts.titleMedium),
          SizedBox(height: context.spacing.sm),
          Wrap(
            spacing: context.spacing.xl,
            runSpacing: context.spacing.lg,
            children: [
              for (final scale in const <double>[1, 2])
                for (final arabic in const <bool>[false, true])
                  _OptionPreview(
                    key: ValueKey('${spec.option.name}-$scale-$arabic'),
                    spec: spec,
                    scale: scale,
                    arabic: arabic,
                  ),
            ],
          ),
          SizedBox(height: context.spacing.xl),
        ],
      ],
    );
  }
}

class _OptionPreview extends StatelessWidget {
  const _OptionPreview({
    required this.spec,
    required this.scale,
    required this.arabic,
    super.key,
  });

  final FigmaPrimaryButtonSpec spec;
  final double scale;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final label = arabic ? 'تسجيل الدخول' : 'Sign In';
    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${arabic ? 'AR' : 'EN'} ${scale.toStringAsFixed(1)}x',
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: FigmaPrimaryButton(
              label: label,
              spec: spec,
              onPressed: _noop,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaPlane extends StatelessWidget {
  const _FigmaPlane({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: FigmaColors.surface,
      alignment: AlignmentDirectional.topStart,
      child: child,
    );
  }
}

String _resultLabel(InspectionResult result) => switch (result) {
  InspectionResult.noIssueObserved => 'No issue observed',
  InspectionResult.attentionRecommended => 'Attention recommended',
  InspectionResult.defectFound => 'Defect found',
  InspectionResult.notChecked => 'Not checked',
  InspectionResult.notApplicable => 'Not applicable',
  InspectionResult.couldNotVerify => 'Could not verify',
};

void _noop() {}

void _ignore<T>(T value) {}
