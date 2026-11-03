import 'dart:typed_data';

import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/item_form_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:l10n/l10n.dart';

class MasterContentTab extends ConsumerStatefulWidget {
  const MasterContentTab({super.key});

  @override
  ConsumerState<MasterContentTab> createState() => _MasterContentTabState();
}

class _MasterContentTabState extends ConsumerState<MasterContentTab> {
  final _search = TextEditingController();
  String _categoryId = '';
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _itemKey => '${_search.text}\u0001$_categoryId\u0001$_status';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final items = ref.watch(itemsProvider(_itemKey));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(categoriesProvider);
        ref.invalidate(itemsProvider(_itemKey));
      },
      child: ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(
            title: l10n.categories,
            action: AppButton(
              label: l10n.newCategory,
              onPressed: () => _showCategoryDialog(context, ref),
              icon: Icons.add,
              variant: AppButtonVariant.tonal,
            ),
          ),
          categories.when(
            loading: () => const LoadingSkeleton(lines: 2),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(categoriesProvider),
              retryLabel: l10n.search,
            ),
            data: (list) => list.isEmpty
                ? EmptyState(title: l10n.noResults, body: l10n.noResults)
                : Column(
                    children: list
                        .map(
                          (category) => Card(
                            child: AppListTile(
                              title: category.labelEn,
                              subtitle:
                                  '${category.labelAr} · ${category.itemCount} ${l10n.itemCount} · ${category.status}',
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) => _categoryAction(
                                  context,
                                  ref,
                                  category,
                                  value,
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(l10n.edit),
                                  ),
                                  PopupMenuItem(
                                    value: 'retire',
                                    child: Text(l10n.retire),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          SizedBox(height: context.spacing.xl),
          SectionHeader(
            title: l10n.items,
            action: AppButton(
              label: l10n.newItem,
              onPressed: () => _openNewItem(context, ref),
              icon: Icons.add,
            ),
          ),
          AppTextField(
            controller: _search,
            label: l10n.search,
            hint: l10n.search,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: context.spacing.sm),
          categories.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
            data: (list) => DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _categoryId.isEmpty ? null : _categoryId,
              decoration: InputDecoration(labelText: l10n.category),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.filterAll)),
                ...list.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.labelEn),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _categoryId = value ?? ''),
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              AppSelectableText(
                label: l10n.filterAll,
                selected: _status.isEmpty,
                onTap: () => setState(() => _status = ''),
              ),
              AppSelectableText(
                label: l10n.draft,
                selected: _status == 'DRAFT',
                onTap: () => setState(() => _status = 'DRAFT'),
              ),
              AppSelectableText(
                label: l10n.published,
                selected: _status == 'PUBLISHED',
                onTap: () => setState(() => _status = 'PUBLISHED'),
              ),
              AppSelectableText(
                label: l10n.retired,
                selected: _status == 'RETIRED',
                onTap: () => setState(() => _status = 'RETIRED'),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          items.when(
            loading: () => const LoadingSkeleton(lines: 4),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(itemsProvider(_itemKey)),
              retryLabel: l10n.search,
            ),
            data: (list) => list.isEmpty
                ? EmptyState(title: l10n.noResults, body: l10n.noResults)
                : Column(
                    children: list
                        .map(
                          (item) => Card(
                            child: AppListTile(
                              key: Key('master-item-${item.id}'),
                              leading: const Icon(Icons.fact_check_outlined),
                              title: item.labelEn,
                              subtitle:
                                  '${item.stableCode} · ${item.labelAr} · v${item.currentVersion ?? '-'} · ${item.status}',
                              trailing: item.sampleData
                                  ? StatusChip(
                                      label: l10n.sampleData,
                                      tone: StatusTone.warning,
                                      icon: Icons.science_outlined,
                                    )
                                  : null,
                              onTap: () => _openItem(context, ref, item.id),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          SizedBox(height: context.spacing.xl),
          const GuideImageManager(),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, [
    Category? category,
  ]) async {
    final l10n = AppLocalizations.of(context);
    final slug = TextEditingController(text: category?.slug ?? '');
    final en = TextEditingController(text: category?.labelEn ?? '');
    final ar = TextEditingController(text: category?.labelAr ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? l10n.newCategory : l10n.edit),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: slug, label: l10n.slug),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: en, label: l10n.categoryNameEn),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: ar, label: l10n.categoryNameAr),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: l10n.save,
            onPressed: () async {
              try {
                if (category == null) {
                  await ref
                      .read(adminApiProvider)
                      .createCategory(
                        slug.text.trim(),
                        en.text.trim(),
                        ar.text.trim(),
                      );
                } else {
                  await ref
                      .read(adminApiProvider)
                      .updateCategory(
                        category.id,
                        slug.text.trim(),
                        en.text.trim(),
                        ar.text.trim(),
                        category.sortOrder,
                        category.status,
                      );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(auditProvider);
                }
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
                }
              }
            },
          ),
        ],
      ),
    );
    slug.dispose();
    en.dispose();
    ar.dispose();
  }

  Future<void> _categoryAction(
    BuildContext context,
    WidgetRef ref,
    Category category,
    String action,
  ) async {
    if (action == 'edit') {
      await _showCategoryDialog(context, ref, category);
      return;
    }
    try {
      await ref.read(adminApiProvider).retireCategory(category.id);
      ref.invalidate(categoriesProvider);
      ref.invalidate(auditProvider);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    }
  }

  void _openNewItem(BuildContext context, WidgetRef ref) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ItemFormPage()));
  }

  void _openItem(BuildContext context, WidgetRef ref, String itemId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ItemFormPage(itemId: itemId)),
    );
  }
}

class GuideImageManager extends ConsumerStatefulWidget {
  const GuideImageManager({super.key});

  @override
  ConsumerState<GuideImageManager> createState() => _GuideImageManagerState();
}

class _GuideImageManagerState extends ConsumerState<GuideImageManager> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final images = ref.watch(guideImagesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.guideImage,
          action: AppButton(
            label: l10n.uploadGuideImage,
            onPressed: _uploading ? null : _pick,
            icon: Icons.upload_file,
            variant: AppButtonVariant.tonal,
          ),
        ),
        images.when(
          loading: () => const LoadingSkeleton(lines: 2),
          error: (error, _) => ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () => ref.invalidate(guideImagesProvider),
            retryLabel: l10n.search,
          ),
          data: (list) => list.isEmpty
              ? EmptyState(title: l10n.noResults, body: l10n.noResults)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= AppBreakpoints.tablet
                        ? 3
                        : constraints.maxWidth >= AppBreakpoints.phone
                        ? 2
                        : 1;
                    final gap = context.spacing.md;
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: list
                          .map(
                            (image) => SizedBox(
                              width: cardWidth,
                              child: _GuideImageCard(image: image),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) {
      return;
    }
    final altEn = TextEditingController();
    final altAr = TextEditingController();
    final licence = TextEditingController();
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.uploadGuideImage),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: altEn, label: l10n.guideImageAltEn),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: altAr, label: l10n.guideImageAltAr),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: licence, label: l10n.licenceNote),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: l10n.uploadGuideImage,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (shouldUpload != true || !mounted) {
      altEn.dispose();
      altAr.dispose();
      licence.dispose();
      return;
    }
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await ref
          .read(adminApiProvider)
          .uploadGuideImage(
            bytes: bytes,
            filename: picked.name,
            altEn: altEn.text.trim(),
            altAr: altAr.text.trim(),
            licenceNote: licence.text.trim(),
          );
      ref.invalidate(guideImagesProvider);
      ref.invalidate(auditProvider);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
      altEn.dispose();
      altAr.dispose();
      licence.dispose();
    }
  }
}

class _GuideImageCard extends ConsumerWidget {
  const _GuideImageCard({required this.image});

  final GuideImage image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.md),
            child: FutureBuilder<List<int>>(
              future: ref.read(adminApiProvider).guideImageBytes(image.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    Uint8List.fromList(snapshot.data!),
                    height: context.spacing.huge * 2,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: image.altEn,
                  );
                }
                return SizedBox(
                  height: context.spacing.huge * 2,
                  child: const LoadingSkeleton(lines: 2),
                );
              },
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(image.altEn, style: context.texts.titleSmall),
          SizedBox(height: context.spacing.xs),
          Text(
            image.altAr,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          StatusChip(
            label: image.status,
            tone: image.status == 'ACTIVE'
                ? StatusTone.success
                : StatusTone.neutral,
          ),
        ],
      ),
    );
  }
}
