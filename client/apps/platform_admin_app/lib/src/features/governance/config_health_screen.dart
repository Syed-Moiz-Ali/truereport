import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'impact_dialog.dart';

class ConfigHealthScreen extends ConsumerStatefulWidget {
  const ConfigHealthScreen({super.key});

  @override
  ConsumerState<ConfigHealthScreen> createState() => _ConfigHealthScreenState();
}

class _ConfigHealthScreenState extends ConsumerState<ConfigHealthScreen> {
  final _entityIdController = TextEditingController();
  String _entityType = 'CATEGORY';

  @override
  void dispose() {
    _entityIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final health = ref.watch(configHealthProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.configHealth,
          style: PtTheme.font(
            18,
            lineHeight: 24,
            weight: FontWeight.w800,
            color: PtTheme.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(configHealthProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      health.when(
                        loading: () => const _LoadingState(),
                        error: (error, stackTrace) => _ErrorState(
                          onRetry: () => ref.invalidate(configHealthProvider),
                        ),
                        data: (data) => _HealthContent(health: data),
                      ),
                      const SizedBox(height: 20),
                      _ImpactHelper(
                        entityType: _entityType,
                        entityIdController: _entityIdController,
                        onEntityTypeChanged: (value) =>
                            setState(() => _entityType = value),
                        onEntityIdChanged: (_) => setState(() {}),
                        onOpen: () => showImpactDialog(
                          context,
                          ref,
                          entityType: _entityType,
                          entityId: _entityIdController.text.trim(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HealthContent extends StatelessWidget {
  const _HealthContent({required this.health});

  final ConfigHealth health;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issueCount = health.checks.where((check) => !check.ok).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: health.healthy
                  ? PtTheme.emerald.withValues(alpha: 0.4)
                  : PtTheme.rose.withValues(alpha: 0.4),
            ),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (health.healthy ? PtTheme.emerald : PtTheme.rose)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  health.healthy
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: health.healthy ? PtTheme.emerald : PtTheme.rose,
                  size: 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    health.healthy ? l10n.healthy : l10n.unhealthy,
                    style: PtTheme.font(
                      20,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.configHealth} · '
                    '${health.checks.length} checks · $issueCount issues',
                    style: PtTheme.font(12, color: PtTheme.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (health.checks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PtTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PtTheme.border),
            ),
            child: Text(
              l10n.noData,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          )
        else
          for (final check in health.checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HealthCheckCard(check: check),
            ),
      ],
    );
  }
}

class _HealthCheckCard extends StatelessWidget {
  const _HealthCheckCard({required this.check});

  final HealthCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = check.ok ? PtTheme.emerald : PtTheme.rose;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoChip(label: check.code, color: PtTheme.deepGreen),
              _InfoChip(label: check.severity, color: color),
              Text(
                '${l10n.affectedItems}: ${check.affected}',
                style: PtTheme.font(11, color: PtTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (check.messageEn.isNotEmpty)
            Text(
              check.messageEn,
              style: PtTheme.font(
                14,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
            ),
          if (check.messageAr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              check.messageAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
          if (check.references.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reference in check.references)
                  _ReferenceChip(label: reference),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactHelper extends StatelessWidget {
  const _ImpactHelper({
    required this.entityType,
    required this.entityIdController,
    required this.onEntityTypeChanged,
    required this.onEntityIdChanged,
    required this.onOpen,
  });

  final String entityType;
  final TextEditingController entityIdController;
  final ValueChanged<String> onEntityTypeChanged;
  final ValueChanged<String> onEntityIdChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasId = entityIdController.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.impactAnalysis,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(l10n.blocked, style: PtTheme.font(12, color: PtTheme.muted)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width > 700 ? 3 : 1;
              final fieldWidth = (width - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: entityType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'CATEGORY',
                          child: Text('CATEGORY'),
                        ),
                        DropdownMenuItem(value: 'ITEM', child: Text('ITEM')),
                        DropdownMenuItem(
                          value: 'TEMPLATE',
                          child: Text('TEMPLATE'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onEntityTypeChanged(value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: entityIdController,
                      onChanged: onEntityIdChanged,
                      decoration: InputDecoration(
                        labelText: l10n.itemCode,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        onPressed: hasId ? onOpen : null,
                        icon: const Icon(
                          Icons.travel_explore_rounded,
                          size: 18,
                        ),
                        label: Text(l10n.impactAnalysis),
                        style: FilledButton.styleFrom(
                          backgroundColor: PtTheme.deepGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(label, style: PtTheme.font(11, color: PtTheme.muted)),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: PtTheme.deepGreen),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).loading,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.rose.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: PtTheme.rose, size: 34),
          const SizedBox(height: 12),
          Text(
            l10n.unhealthy,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
