import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Step 2, right pane — the approved master items that can be added.
///
/// Search + category pills + one row per approved item. An item already in the
/// sequence shows a check and cannot be added twice.
class TemplateCatalogPanel extends StatelessWidget {
  const TemplateCatalogPanel({
    required this.items,
    required this.categories,
    required this.search,
    required this.categoryId,
    required this.selectedIds,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onAdd,
    super.key,
  });

  final List<PublishedItem> items;
  final List<Category> categories;
  final TextEditingController search;
  final String categoryId;
  final Set<String> selectedIds;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<PublishedItem> onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                l10n.builderMasterItems,
                style: ws.cardTitle.copyWith(color: ws.ink),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: ws.meta.copyWith(
                  color: ws.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WorkshopSearchField(
            controller: search,
            hint: l10n.searchItems,
            semanticLabel: l10n.searchItems,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TemplatePillChip(
                  label: l10n.allCategories,
                  selected: categoryId.isEmpty,
                  onTap: () => onCategoryChanged(''),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: 6),
                  TemplatePillChip(
                    label: category.labelEn,
                    selected: categoryId == category.id,
                    onTap: () => onCategoryChanged(category.id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                l10n.noResults,
                textAlign: TextAlign.center,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            )
          else
            for (final item in items)
              _row(context, ws, item, selectedIds.contains(item.versionId)),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    WorkshopTokens ws,
    PublishedItem item,
    bool added,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.labelEn,
                  maxLines: 2,
                  style: ws.meta.copyWith(color: ws.ink, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.stableCode} · ${item.categoryLabelEn}',
                  style: ws.meta.copyWith(color: ws.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (added)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(Icons.check_rounded, size: 18, color: ws.accent),
            )
          else
            TemplatePillButton(
              label: '',
              icon: Icons.add,
              variant: TemplatePillVariant.ghost,
              compact: true,
              onPressed: () => onAdd(item),
            ),
        ],
      ),
    );
  }
}
