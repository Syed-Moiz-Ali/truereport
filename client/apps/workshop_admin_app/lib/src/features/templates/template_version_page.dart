import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Read-only template version view.
///
/// Consistency pass only: the same top bar and card language as the builder,
/// with every existing behaviour preserved — the version provider, the integer
/// version + status heading, the published date, the EN/AR switch and the
/// per-item read-only lines (label, instruction, category/version and the
/// platform-locked rule).
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
    final ws = context.ws;
    final version = ref.watch(
      templateVersionProvider('${widget.templateId}\u0001${widget.versionId}'),
    );
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
            child: Column(
              children: [
                _topBar(context, l10n),
                Expanded(
                  child: version.when(
                    loading: () => const WorkshopPageScroll(
                      children: [WorkshopSkeleton(lines: 6, card: true)],
                    ),
                    error: (error, _) => WorkshopPageScroll(
                      children: [
                        WorkshopErrorState(
                          title: l10n.error,
                          body: l10n.genericError,
                          retryLabel: l10n.retryAction,
                          onRetry: () => ref.invalidate(
                            templateVersionProvider(
                              '${widget.templateId}\u0001${widget.versionId}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    data: (value) => _body(context, l10n, value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppLocalizations l10n) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      height: ws.topBarHeight,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
      ),
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      child: Row(
        children: [
          WorkshopIconButton(
            icon: Icons.arrow_back,
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              l10n.readOnlyVersion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    TemplateVersionView value,
  ) {
    final spacing = context.spacing;
    final rows = <Widget>[];
    for (var index = 0; index < value.items.length; index++) {
      if (index > 0) {
        rows.add(const WorkshopDivider());
      }
      rows.add(_itemRow(context, l10n, value.items[index]));
    }
    return WorkshopPageScroll(
      children: [
        WorkshopPageHeader(
          title:
              'v${value.versionNo} · '
              '${contentStatusLabel(l10n, value.status)}',
          subtitle: value.publishedAt.isEmpty ? null : value.publishedAt,
        ),
        SizedBox(height: spacing.lg),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            WorkshopFilterChip(
              label: l10n.previewEn,
              selected: !_arabic,
              onTap: () => setState(() => _arabic = false),
            ),
            WorkshopFilterChip(
              label: l10n.previewAr,
              selected: _arabic,
              onTap: () => setState(() => _arabic = true),
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        if (rows.isEmpty)
          WorkshopCard(
            child: WorkshopEmptyState(
              title: l10n.noItems,
              body: l10n.addItems,
              icon: Icons.playlist_add_check,
            ),
          )
        else
          WorkshopCard(
            padding: EdgeInsetsDirectional.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: rows,
            ),
          ),
      ],
    );
  }

  Widget _itemRow(
    BuildContext context,
    AppLocalizations l10n,
    TemplateItemView item,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _arabic ? item.labelAr : item.labelEn,
            style: ws.cardTitle.copyWith(color: ws.ink),
          ),
          SizedBox(height: spacing.xs),
          Text(
            _arabic ? item.instructionAr : item.instructionEn,
            style: ws.body.copyWith(color: ws.ink),
          ),
          SizedBox(height: spacing.xs),
          Text(
            '${_arabic ? item.categoryLabelAr : item.categoryLabelEn} · '
            'v${item.versionNo} · '
            '${item.noteRequirement}/${item.evidenceRequirement} · '
            '${l10n.lockedByPlatform}',
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ],
      ),
    );
  }
}
