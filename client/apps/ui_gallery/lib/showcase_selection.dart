import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:ui_gallery/gallery_keys.dart';
import 'package:ui_gallery/support/gallery_widgets.dart';

class ChipsShowcase extends StatelessWidget {
  const ChipsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Status tones', style: context.texts.titleMedium),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            for (final tone in StatusTone.values)
              StatusChip(label: tone.name, tone: tone),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        Text('Severity', style: context.texts.titleMedium),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            for (final severity in AppSeverity.values)
              SeverityBadge(
                label: _severityLabel(t, severity),
                appSeverity: severity,
              ),
          ],
        ),
      ],
    );
  }
}

String _severityLabel(UiStrings t, AppSeverity severity) {
  return switch (severity) {
    AppSeverity.minor => t(GalleryKeys.minor),
    AppSeverity.moderate => t(GalleryKeys.moderate),
    AppSeverity.major => t(GalleryKeys.major),
    AppSeverity.safetyCritical => t(GalleryKeys.safetyCritical),
  };
}

class SegmentedShowcase extends StatefulWidget {
  const SegmentedShowcase({super.key});

  @override
  State<SegmentedShowcase> createState() => _SegmentedShowcaseState();
}

class _SegmentedShowcaseState extends State<SegmentedShowcase> {
  String _selected = 'Week';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GalleryTile(
          label: 'Segmented control',
          child: AppSegmentedControl<String>(
            segments: const [
              AppSegment<String>(value: 'Day', label: 'Day'),
              AppSegment<String>(value: 'Week', label: 'Week'),
              AppSegment<String>(value: 'Month', label: 'Month'),
            ],
            selected: _selected,
            onChanged: (value) => setState(() => _selected = value),
          ),
        ),
        SizedBox(height: context.spacing.lg),
      ],
    );
  }
}

class ResultSelectorShowcase extends StatefulWidget {
  const ResultSelectorShowcase({super.key});

  @override
  State<ResultSelectorShowcase> createState() => _ResultSelectorShowcaseState();
}

class _ResultSelectorShowcaseState extends State<ResultSelectorShowcase> {
  InspectionResult _selected = InspectionResult.noIssueObserved;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final labels = <InspectionResult, String>{
      InspectionResult.noIssueObserved: t(GalleryKeys.noIssueObserved),
      InspectionResult.attentionRecommended: t(
        GalleryKeys.attentionRecommended,
      ),
      InspectionResult.defectFound: t(GalleryKeys.defectFound),
      InspectionResult.notChecked: t(GalleryKeys.notChecked),
      InspectionResult.notApplicable: t(GalleryKeys.notApplicable),
      InspectionResult.couldNotVerify: t(GalleryKeys.couldNotVerify),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionResultSelector(
          selected: _selected,
          labelBuilder: (result) => labels[result]!,
          onChanged: (value) => setState(() => _selected = value),
        ),
        SizedBox(height: context.spacing.md),
        Text(
          'Selected: ${labels[_selected]}',
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ProgressShowcase extends StatelessWidget {
  const ProgressShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Wrap(
      spacing: context.spacing.xl,
      runSpacing: context.spacing.lg,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const GalleryTile(
          label: 'Progress ring',
          child: AppProgressRing(value: 0.62, label: '62%'),
        ),
        const GalleryTile(
          label: 'Progress ring complete',
          child: AppProgressRing(value: 1, label: '100%'),
        ),
        GalleryTile(
          label: 'Coverage bar',
          width: 320,
          child: AppCoverageBar(
            covered: 12,
            total: 19,
            label: t(GalleryKeys.coverage),
          ),
        ),
        GalleryTile(
          label: 'Coverage bar empty',
          width: 320,
          child: AppCoverageBar(
            covered: 0,
            total: 19,
            label: t(GalleryKeys.coverage),
          ),
        ),
      ],
    );
  }
}
