import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(
      templateVersionProvider('${widget.templateId}\u0001${widget.versionId}'),
    );
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.readOnlyVersion)),
      body: version.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(
                templateVersionProvider(
                  '${widget.templateId}\u0001${widget.versionId}',
                ),
              ),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
        data: (value) => ListView(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          children: [
            SectionHeader(
              title:
                  'v${value.versionNo} · ${contentStatusLabel(l10n, value.status)}',
              subtitle: value.publishedAt,
            ),
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                AppSelectableText(
                  label: l10n.previewEn,
                  selected: !_arabic,
                  onTap: () => setState(() => _arabic = false),
                ),
                AppSelectableText(
                  label: l10n.previewAr,
                  selected: _arabic,
                  onTap: () => setState(() => _arabic = true),
                ),
              ],
            ),
            SizedBox(height: context.spacing.md),
            ...value.items.map(
              (item) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
                child: Card(
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(context.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _arabic ? item.labelAr : item.labelEn,
                          style: context.texts.titleMedium,
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          _arabic ? item.instructionAr : item.instructionEn,
                          style: context.texts.bodyMedium,
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          '${item.categoryLabelEn} · v${item.versionNo} · '
                          '${item.noteRequirement}/${item.evidenceRequirement} · '
                          '${l10n.lockedByPlatform}',
                          style: context.texts.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
