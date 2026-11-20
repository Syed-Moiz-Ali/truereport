import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Read-only view of one published (or drafting) template version.
///
/// Same provider, same EN/AR switch, same per-item content as before — laid
/// out as a numbered route with pill language chips and a sticky-free header.
class TemplateVersionPage extends ConsumerStatefulWidget {
  const TemplateVersionPage({
    required this.templateId,
    required this.versionId,
    super.key,
  });

  final String templateId;
  final String versionId;

  @override
  ConsumerState<TemplateVersionPage> createState() =>
      _TemplateVersionPageState();
}

class _TemplateVersionPageState extends ConsumerState<TemplateVersionPage> {
  bool _arabic = false;

  String get _key => '${widget.templateId}\u0001${widget.versionId}';

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final version = ref.watch(templateVersionProvider(_key));
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: ws.topBarHeight,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.pageGutter(width),
              ),
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                  child: Row(
                    children: [
                      WorkshopIconButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        semanticLabel: t(WorkshopAdminKeys.commonBack),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t(WorkshopAdminKeys.readOnlyVersion),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                      ),
                      Icon(Icons.lock_outline, size: 16, color: ws.muted),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: version.when(
                loading: () => SingleChildScrollView(
                  padding: ws.pagePadding(width),
                  child: const WorkshopSkeleton(lines: 6, card: true),
                ),
                error: (error, _) => SingleChildScrollView(
                  padding: ws.pagePadding(width),
                  child: WorkshopErrorState(
                    title: t(WorkshopAdminKeys.error),
                    body: t(WorkshopAdminKeys.genericError),
                    retryLabel: t(WorkshopAdminKeys.retryAction),
                    onRetry: () =>
                        ref.invalidate(templateVersionProvider(_key)),
                  ),
                ),
                data: (value) => _body(context, t, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, UiStrings t, TemplateVersionView value) {
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      padding: ws.pagePadding(width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'v${value.versionNo}',
                          style: ws.pageTitle.copyWith(
                            fontSize: 34,
                            letterSpacing: -0.8,
                            color: ws.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TemplateStatusPill(status: value.status),
                            if (value.publishedAt.isNotEmpty)
                              Text(
                                value.publishedAt,
                                style: ws.meta.copyWith(color: ws.muted),
                              ),
                            Text(
                              t(WorkshopAdminKeys.templateItemsCount, {
                                'count': value.items.length,
                              }),
                              style: ws.meta.copyWith(color: ws.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TemplatePillChip(
                        label: t(WorkshopAdminKeys.previewEn),
                        selected: !_arabic,
                        onTap: () => setState(() => _arabic = false),
                      ),
                      const SizedBox(width: 8),
                      TemplatePillChip(
                        label: t(WorkshopAdminKeys.previewAr),
                        selected: _arabic,
                        onTap: () => setState(() => _arabic = true),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: ws.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ws.border),
                ),
                child: value.items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          t(WorkshopAdminKeys.noItems),
                          textAlign: TextAlign.center,
                          style: ws.body.copyWith(color: ws.muted),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < value.items.length; i++)
                            _row(context, ws, value.items[i], i),
                        ],
                      ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    WorkshopTokens ws,
    TemplateItemView item,
    int index,
  ) {
    final t = UiStrings.of(context);
    final label = _arabic ? item.labelAr : item.labelEn;
    final instruction = _arabic ? item.instructionAr : item.instructionEn;
    final category = _arabic ? item.categoryLabelAr : item.categoryLabelEn;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: ws.meta.copyWith(
              color: ws.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ws.bodyStrong.copyWith(color: ws.ink, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  instruction,
                  style: ws.body.copyWith(color: ws.ink, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category · v${item.versionNo} · '
                  '${item.noteRequirement}/${item.evidenceRequirement} · '
                  '${t(WorkshopAdminKeys.lockedByPlatform)}',
                  style: ws.meta.copyWith(color: ws.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
