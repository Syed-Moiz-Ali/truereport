import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Step 3 — what is about to go live, and everything that can be done to it.
///
/// Publish state, the version list and the destructive retire action all live
/// here, away from the editing steps so a mis-click cannot publish.
class TemplatePublishStep extends StatelessWidget {
  const TemplatePublishStep({
    required this.name,
    required this.status,
    required this.itemCount,
    required this.versions,
    required this.busy,
    required this.hasDraft,
    required this.onPublish,
    required this.onPreview,
    required this.onRetire,
    required this.onOpenVersion,
    super.key,
  });

  final String name;
  final String status;
  final int itemCount;
  final List<TemplateVersionSummary> versions;
  final bool busy;
  final bool hasDraft;
  final VoidCallback onPublish;
  final VoidCallback onPreview;
  final VoidCallback onRetire;
  final ValueChanged<String> onOpenVersion;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ws.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TemplateStatusPill(status: status),
                  const Spacer(),
                  Text(
                    t(WorkshopAdminKeys.templateItemsCount, {
                      'count': itemCount,
                    }),
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: ws.sectionTitle.copyWith(fontSize: 22, color: ws.ink),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (hasDraft)
                    TemplatePillButton(
                      label: t(WorkshopAdminKeys.publishTemplate),
                      icon: Icons.publish_outlined,
                      loading: busy,
                      onPressed: busy ? null : onPublish,
                    ),
                  TemplatePillButton(
                    label: t(WorkshopAdminKeys.preview),
                    icon: Icons.visibility_outlined,
                    variant: TemplatePillVariant.outline,
                    onPressed: busy ? null : onPreview,
                  ),
                  if (status != 'RETIRED')
                    TemplatePillButton(
                      label: t(WorkshopAdminKeys.retire),
                      variant: TemplatePillVariant.danger,
                      onPressed: busy ? null : onRetire,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 6),
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ws.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t(WorkshopAdminKeys.versionHistory),
                style: ws.cardTitle.copyWith(color: ws.ink),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < versions.length; i++)
                _versionRow(context, ws, versions[i], i == 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _versionRow(
    BuildContext context,
    WorkshopTokens ws,
    TemplateVersionSummary version,
    bool first,
  ) {
    final t = UiStrings.of(context);
    return InkWell(
      onTap: () => onOpenVersion(version.id),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: first
              ? null
              : BorderDirectional(top: BorderSide(color: ws.border)),
        ),
        child: Row(
          children: [
            Text(
              'v${version.versionNo}',
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
            const SizedBox(width: 12),
            TemplateStatusPill(status: version.status),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${t(WorkshopAdminKeys.templateItemsCount, {'count': version.itemCount})}'
                '${version.publishedAt.isEmpty ? '' : ' · ${version.publishedAt}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: ws.muted),
          ],
        ),
      ),
    );
  }
}
