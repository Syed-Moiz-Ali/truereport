import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'report_actions.dart';

/// Pushed-page chrome: back, the `Jobs / <reference>` breadcrumb and the PDF
/// action. Refresh stays available in every state so a stuck generation can be
/// re-pulled without leaving the page.
class ReportTopBar extends StatelessWidget {
  const ReportTopBar({
    required this.reference,
    required this.isRtl,
    required this.reportReady,
    required this.isBusy,
    required this.onBack,
    required this.onRefresh,
    required this.onDownload,
    super.key,
  });

  final String reference;
  final bool isRtl;
  final bool reportReady;
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onDownload;

  static const double _contentMax = 1200;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final t = UiStrings.of(context);
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final compact = MediaQuery.sizeOf(context).width < 560;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        border: Border(bottom: BorderSide(color: ws.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: ws.topBarHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMax),
                child: Row(
                  children: [
                    WorkshopIconButton(
                      icon: isRtl ? Icons.arrow_forward : Icons.arrow_back,
                      semanticLabel: t(WorkshopAdminKeys.commonBack),
                      onPressed: onBack,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(child: _Breadcrumb(reference: reference)),
                    SizedBox(width: spacing.sm),
                    WorkshopIconButton(
                      icon: Icons.refresh,
                      semanticLabel: t(WorkshopAdminKeys.refresh),
                      onPressed: onRefresh,
                    ),
                    if (reportReady) ...[
                      SizedBox(width: spacing.sm),
                      if (compact)
                        WorkshopIconButton(
                          icon: Icons.download_outlined,
                          semanticLabel: t(WorkshopAdminKeys.downloadPdf),
                          tooltip: t(WorkshopAdminKeys.downloadPdf),
                          onPressed: isBusy ? null : onDownload,
                        )
                      else
                        ReportActionButton(
                          label: t(WorkshopAdminKeys.downloadPdf),
                          onPressed: isBusy ? null : onDownload,
                          loading: isBusy,
                          icon: Icons.download_outlined,
                          variant: ReportActionVariant.secondary,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final t = UiStrings.of(context);
    return Semantics(
      container: true,
      label: '${t(WorkshopAdminKeys.jobsTab)}, $reference',
      child: Row(
        children: [
          Text(
            t(WorkshopAdminKeys.jobsTab),
            style: ws.meta.copyWith(color: ws.muted),
          ),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.sm),
            child: ExcludeSemantics(
              child: Text('/', style: ws.meta.copyWith(color: ws.muted)),
            ),
          ),
          Flexible(
            child: Text(
              reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
          ),
        ],
      ),
    );
  }
}
