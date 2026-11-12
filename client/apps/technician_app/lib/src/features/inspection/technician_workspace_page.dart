import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/shared/technician_intl.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class TechnicianWorkspacePage extends ConsumerStatefulWidget {
  const TechnicianWorkspacePage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<TechnicianWorkspacePage> createState() =>
      _TechnicianWorkspacePageState();
}

class _TechnicianWorkspacePageState
    extends ConsumerState<TechnicianWorkspacePage> {
  String? _categoryCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checklistAsync = ref.watch(technicianChecklistProvider(widget.jobId));
    return AppScaffold(
      backgroundColor: context.colors.surface,
      appBar: TechnicianAppBar(
        title: l10n.technicianInspectionHub,
        showBack: true,
      ),
      body: checklistAsync.when(
        loading: () => const Padding(
          padding: EdgeInsetsDirectional.all(24),
          child: LoadingSkeleton(lines: 8),
        ),
        error: (error, _) => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.gutter),
          child: ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () =>
                ref.invalidate(technicianChecklistProvider(widget.jobId)),
            retryLabel: l10n.retryAction,
          ),
        ),
        data: (checklist) => _WorkspaceBody(
          checklist: checklist,
          jobId: widget.jobId,
          selectedCategory: _categoryCode,
          onSelectCategory: (code) => setState(() => _categoryCode = code),
        ),
      ),
    );
  }
}

class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({
    required this.checklist,
    required this.jobId,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final Checklist checklist;
  final String jobId;
  final String? selectedCategory;
  final ValueChanged<String> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final categories = [...checklist.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final code = selectedCategory ??
        (categories.isEmpty ? null : categories.first.code);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = [
          _JobHeader(checklist: checklist, jobId: jobId),
          SizedBox(height: context.spacing.md),
        ];
        if (categories.isEmpty) {
          content.add(
            EmptyState(
              title: l10n.technicianNoCategories,
              body: l10n.technicianNoItems,
              icon: Icons.checklist_rounded,
            ),
          );
        } else if (wide) {
          content.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      maxWidth: 300,
                    ),
                    child: _CategoryRail(
                      categories: categories,
                      selectedCode: code,
                      locale: locale,
                      onSelected: onSelectCategory,
                    ),
                  ),
                ),
                SizedBox(width: context.spacing.lg),
                Expanded(
                  flex: 3,
                  child: _CategoryItems(
                    checklist: checklist,
                    categoryCode: code,
                    jobId: jobId,
                  ),
                ),
              ],
            ),
          );
        } else {
          content.add(
            _CategoryTabs(
              categories: categories,
              selectedCode: code,
              onSelected: onSelectCategory,
            ),
          );
          SizedBox(height: context.spacing.md);
          content.add(
            _CategoryItems(
              checklist: checklist,
              categoryCode: code,
              jobId: jobId,
            ),
          );
        }
        return Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsetsDirectional.all(context.spacing.gutter),
              children: content,
            ),
          ),
        );
      },
    );
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.checklist, required this.jobId});

  final Checklist checklist;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final job = checklist.job;
    final pinned = checklist.pinned;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      job.reference,
                      style: context.texts.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      '${job.vehicleMake} ${job.vehicleModel}'
                      '${job.vehicleYear == null ? '' : ' · ${job.vehicleYear}'}',
                      style: context.texts.bodyLarge,
                    ),
                    Text(
                      job.customerName,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.spacing.sm),
              StatusChip(
                label: technicianStatusLabel(l10n, job.status),
                tone: technicianStatusTone(job.status),
              ),
            ],
          ),
          if (pinned != null) ...[
            SizedBox(height: context.spacing.sm),
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                StatusChip(
                  label:
                      '${l10n.technicianPinnedTemplate} ${pinned.templateVersionNo ?? ''}',
                  tone: StatusTone.info,
                  icon: Icons.lock_outline,
                ),
                StatusChip(
                  label: job.templateNameFor(
                    Localizations.localeOf(context).languageCode,
                  ),
                  tone: StatusTone.neutral,
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ],
          SizedBox(height: context.spacing.md),
          AppCoverageBar(
            covered: checklist.completed,
            total: checklist.total,
            label: l10n.technicianAssessmentProgress,
            valueLabel: formatCountPairLocalized(
              checklist.completed,
              checklist.total,
              locale,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              label: l10n.technicianOpenSummary,
              icon: Icons.arrow_forward,
              variant: AppButtonVariant.tonal,
              onPressed: () => context.push('/jobs/$jobId/summary'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selectedCode,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            AppFilterChip(
              label: category.nameFor(locale),
              selected: category.code == selectedCode,
              icon: categoryIconFor(category.iconCode),
              onSelected: (_) => onSelected(category.code),
            ),
            SizedBox(width: context.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedCode,
    required this.locale,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedCode;
  final String locale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final category in categories) ...[
            AppListTile(
              title: category.nameFor(locale),
              leading: Icon(
                categoryIconFor(category.iconCode),
                color: category.code == selectedCode
                    ? context.brand.ink
                    : context.colors.onSurfaceVariant,
              ),
              trailing: category.code == selectedCode
                  ? Icon(Icons.chevron_right, color: context.brand.ink)
                  : null,
              onTap: () => onSelected(category.code),
            ),
            SizedBox(height: context.spacing.xxs),
          ],
        ],
      ),
    );
  }
}

class _CategoryItems extends StatelessWidget {
  const _CategoryItems({
    required this.checklist,
    required this.categoryCode,
    required this.jobId,
  });

  final Checklist checklist;
  final String? categoryCode;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (categoryCode == null) {
      return const SizedBox.shrink();
    }
    final items = checklist.itemsForCategory(categoryCode!);
    if (items.isEmpty) {
      return EmptyState(
        title: l10n.technicianNoItems,
        body: l10n.technicianNoItems,
        icon: Icons.playlist_add_check,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items) ...[
          _ItemCard(
            item: item,
            onTap: () => context.push(
              '/jobs/$jobId/items/${Uri.encodeComponent(item.itemCode)}',
            ),
          ),
          SizedBox(height: context.spacing.sm),
        ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});

  final ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final assessment = item.assessment;
    final result = assessment?.resultCode;
    final photos = assessment?.evidence.where((e) => e.isPhoto).length ?? 0;
    final videos = assessment?.evidence.where((e) => e.isVideo).length ?? 0;
    final documents =
        assessment?.evidence.where((e) => e.isDocument).length ?? 0;
    final instruction = item.instructionFor(language);
    final spec = item.standardSpecFor(language);
    return AppCard(
      onTap: onTap,
      semanticLabel: item.labelFor(language),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.labelFor(language),
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.sm),
              StatusChip(
                label: result == null
                    ? l10n.notChecked
                    : resultLabel(l10n, result),
                tone: resultTone(result),
              ),
            ],
          ),
          if (instruction != null && instruction.isNotEmpty) ...[
            SizedBox(height: context.spacing.xxs),
            Text(
              '${l10n.technicianInstructions}: $instruction',
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (spec != null && spec.isNotEmpty) ...[
            SizedBox(height: context.spacing.xxs),
            Text(
              '${l10n.technicianStandardSpec}: $spec',
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: context.spacing.xs),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              if (item.safetyCritical)
                StatusChip(
                  label: l10n.technicianSafetyCritical,
                  tone: StatusTone.danger,
                  icon: Icons.health_and_safety_outlined,
                ),
              if (item.multiPoint)
                StatusChip(
                  label: l10n.technicianMultiPoint,
                  tone: StatusTone.info,
                  icon: Icons.grid_on_outlined,
                ),
              if (item.measurementUnit != null)
                StatusChip(
                  label:
                      '${l10n.technicianUnit}: ${item.measurementUnit}',
                  tone: StatusTone.neutral,
                  icon: Icons.straighten,
                ),
              if (item.sensorTool != null && item.sensorTool!.isNotEmpty)
                StatusChip(
                  label: '${l10n.technicianTool}: ${item.sensorTool}',
                  tone: StatusTone.neutral,
                  icon: Icons.handyman_outlined,
                ),
            ],
          ),
          SizedBox(height: context.spacing.xs),
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.xs,
            children: [
              Text(
                '${l10n.technicianPhoto} $photos',
                style: context.texts.bodySmall,
              ),
              Text(
                '${l10n.technicianVideo} $videos',
                style: context.texts.bodySmall,
              ),
              if (documents > 0)
                Text(
                  '${l10n.technicianDocument} $documents',
                  style: context.texts.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
