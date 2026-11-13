import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform_config_models.dart';
import '../platform_providers.dart';
import '../platform_theme.dart';
import 'platform_dialogs.dart';
import 'platform_form.dart';

import 'package:l10n/l10n.dart';

/// Searchable category picker contract (shared by the Checklist items tab
/// and the template builder):
///
/// ```dart
/// PlatformCategoryPicker(
///   categories: categories,
///   selectedId: _categoryId, // '' or null means "all categories"
///   onChanged: (id) => setState(() => _categoryId = id ?? ''),
/// )
/// ```
///
/// Shows one removable chip for the selection (or the "all" label) and
/// opens a searchable dialog. Never renders a wall of chips.
class PlatformCategoryPicker extends ConsumerWidget {
  const PlatformCategoryPicker({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    this.label,
  });

  final List<PlatformCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final id = (selectedId ?? '').isEmpty ? null : selectedId;
    PlatformCategory? selected;
    if (id != null) {
      for (final c in categories) {
        if (c.id == id) {
          selected = c;
          break;
        }
      }
    }
    final display = selected == null
        ? strings.tKey(PlatformAdminKeys.filterAllCategories)
        : (selected.name.isEmpty ? selected.code : selected.name);

    return Semantics(
      button: true,
      label: label ?? strings.tKey(PlatformAdminKeys.filterCategory),
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.category_outlined,
                size: 18,
                color: PtTheme.muted,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  display,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: selected == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: selected == null ? PtTheme.muted : PtTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => onChanged(null),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: PtTheme.muted,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: PtTheme.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) {
    final strings = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(uiStringsProvider);
    return showPlatformDialog<void>(
      context: context,
      title: strings.tKey(PlatformAdminKeys.filterCategory),
      body: _CategoryPickerBody(
        categories: categories,
        selectedId: (selectedId ?? '').isEmpty ? null : selectedId,
        onSelected: (id) {
          Navigator.of(context).pop();
          onChanged(id);
        },
      ),
    );
  }
}

class _CategoryPickerBody extends ConsumerStatefulWidget {
  const _CategoryPickerBody({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PlatformCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  ConsumerState<_CategoryPickerBody> createState() =>
      _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends ConsumerState<_CategoryPickerBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.categories
        : widget.categories
              .where((c) {
                final name = (c.name.isEmpty ? c.code : c.name).toLowerCase();
                return name.contains(q) || c.code.toLowerCase().contains(q);
              })
              .toList(growable: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformTextField(
          hint: strings.tKey(PlatformAdminKeys.filterCategorySearch),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final selected = widget.selectedId == null;
                return _PickerTile(
                  title: strings.tKey(PlatformAdminKeys.filterAllCategories),
                  subtitle: null,
                  selected: selected,
                  onTap: () => widget.onSelected(null),
                );
              }
              final category = filtered[index - 1];
              final title = category.name.isEmpty
                  ? category.code
                  : category.name;
              return _PickerTile(
                title: title,
                subtitle:
                    '${category.code} · ${category.itemCount} ${strings.tKey(CommonKeys.labelItems)}',
                selected: widget.selectedId == category.id,
                onTap: () => widget.onSelected(category.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? PtTheme.deepGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: PtTheme.font(
                      14,
                      lineHeight: 20,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? PtTheme.deepGreen : PtTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        color: PtTheme.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: PtTheme.deepGreen,
              ),
          ],
        ),
      ),
    );
  }
}
