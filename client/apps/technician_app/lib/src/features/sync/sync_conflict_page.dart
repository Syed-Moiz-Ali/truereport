import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/sync/sync_providers.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

/// One conflict, side by side: what this phone saved and what the server holds.
/// Keeping the server version is the only supported resolution, so it is the
/// only action on the screen.
class TechnicianConflictPage extends ConsumerStatefulWidget {
  const TechnicianConflictPage({required this.conflictId, super.key});

  final String conflictId;

  @override
  ConsumerState<TechnicianConflictPage> createState() =>
      _TechnicianConflictPageState();
}

class _TechnicianConflictPageState
    extends ConsumerState<TechnicianConflictPage> {
  bool _busy = false;

  Future<void> _useServer(SyncConflictRecord conflict) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    await ref.read(offlineStoreProvider).resolveConflict(conflict.id);
    ref.invalidate(allTechnicianConflictsProvider);
    ref.invalidate(syncQueueStatusProvider);
    ref.invalidate(pendingOperationsProvider);
    ref.invalidate(technicianChecklistProvider);
    ref.invalidate(technicianSummaryProvider);
    ref.invalidate(technicianJobPageProvider);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    showAppSnackBar(context, message: l10n.technicianConflictReloaded);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conflictsAsync = ref.watch(allTechnicianConflictsProvider);
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: conflictsAsync.when(
        loading: () => Column(
          children: [
            _ConflictBar(title: l10n.technicianSyncConflictTitle),
            const Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.all(20),
                child: LoadingSkeleton(lines: 6),
              ),
            ),
          ],
        ),
        error: (error, _) => Column(
          children: [
            _ConflictBar(title: l10n.technicianSyncConflictTitle),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(20),
                child: ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () => ref.invalidate(allTechnicianConflictsProvider),
                  retryLabel: l10n.retryAction,
                ),
              ),
            ),
          ],
        ),
        data: (conflicts) {
          final index = conflicts.indexWhere(
            (record) => record.id == widget.conflictId,
          );
          if (index == -1) {
            return _MissingConflict(
              title: l10n.technicianSyncConflictTitle,
              message: l10n.technicianConflictUnavailable,
              body: l10n.technicianSyncNothing,
            );
          }
          final conflict = conflicts[index];
          return Column(
            children: [
              _ConflictBar(
                title: l10n.technicianSyncConflictTitle,
                counter: '${index + 1} / ${conflicts.length}',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 20),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              conflict.itemCode,
                              style: context.texts.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.technicianConflictJob(conflict.jobId),
                              style: context.texts.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RevisionCard(conflict: conflict),
                            const SizedBox(height: 20),
                            _PayloadComparison(conflict: conflict),
                            const SizedBox(height: 16),
                            _Note(
                              icon: Icons.info_outline,
                              text: l10n.technicianConflictPhoneHint,
                              tone: StatusTone.warning,
                            ),
                            const SizedBox(height: 8),
                            _Note(
                              icon: Icons.check_circle_outline,
                              text: l10n.technicianConflictRevalidate,
                              tone: StatusTone.neutral,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _ConflictActionBar(
                label: l10n.technicianConflictUseServer,
                busy: _busy,
                onPressed: _busy ? null : () => _useServer(conflict),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConflictBar extends StatelessWidget {
  const _ConflictBar({required this.title, this.counter});

  final String title;
  final String? counter;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (counter != null)
                StatusChip(label: counter!, tone: StatusTone.danger),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevisionCard extends StatelessWidget {
  const _RevisionCard({required this.conflict});

  final SyncConflictRecord conflict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    Widget column(String value, String label) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: context.texts.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          column('${conflict.clientRevision}', l10n.technicianConflictPhoneRev),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
          column(
            '${conflict.serverRevision}',
            l10n.technicianConflictServerRev,
          ),
        ],
      ),
    );
  }
}

class _PayloadComparison extends StatelessWidget {
  const _PayloadComparison({required this.conflict});

  final SyncConflictRecord conflict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final client = _asMap(conflict.clientPayloadJson);
    final server = _asMap(conflict.serverPayloadJson);

    if (client == null && server == null) {
      final clientRaw = prettyPayload(conflict.clientPayloadJson);
      final serverRaw = prettyPayload(conflict.serverPayloadJson);
      if (clientRaw.isEmpty && serverRaw.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Caption(label: l10n.technicianConflictCompare),
          const SizedBox(height: 6),
          if (clientRaw.isNotEmpty) ...[
            _RawPayload(
              caption: l10n.technicianConflictPhone,
              payload: clientRaw,
            ),
            const SizedBox(height: 8),
          ],
          if (serverRaw.isNotEmpty)
            _RawPayload(
              caption: l10n.technicianConflictServer,
              payload: serverRaw,
            ),
        ],
      );
    }

    final keys = <String>[
      ...?client?.keys,
      for (final key in server?.keys ?? const <String>[])
        if (!(client?.containsKey(key) ?? false)) key,
    ];
    final onlyClient = <String>{
      for (final key in client?.keys ?? const <String>[])
        if (!(server?.containsKey(key) ?? false)) key,
    };
    final onlyServer = <String>{
      for (final key in server?.keys ?? const <String>[])
        if (!(client?.containsKey(key) ?? false)) key,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caption(label: l10n.technicianConflictCompare),
        const SizedBox(height: 6),
        _PayloadCard(
          caption: l10n.technicianConflictPhone,
          tone: StatusTone.info,
          icon: Icons.smartphone,
          keys: keys,
          valueOf: (key) => onlyServer.contains(key)
              ? l10n.technicianConflictOnlyServer
              : _valueText(client?[key]),
        ),
        const SizedBox(height: 8),
        _PayloadCard(
          caption: l10n.technicianConflictServer,
          tone: StatusTone.success,
          icon: Icons.cloud_outlined,
          keys: keys,
          valueOf: (key) => onlyClient.contains(key)
              ? l10n.technicianConflictOnlyPhone
              : _valueText(server?[key]),
        ),
      ],
    );
  }
}

class _PayloadCard extends StatelessWidget {
  const _PayloadCard({
    required this.caption,
    required this.tone,
    required this.icon,
    required this.keys,
    required this.valueOf,
  });

  final String caption;
  final StatusTone tone;
  final IconData icon;
  final List<String> keys;
  final String? Function(String key) valueOf;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 9),
            color: pair.background,
            child: Row(
              children: [
                Icon(icon, size: 15, color: pair.foreground),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    caption.toUpperCase(),
                    style: context.texts.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: pair.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (keys.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.all(14),
              child: Text(
                '—',
                style: context.texts.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < keys.length; index++) ...[
              if (index != 0)
                Divider(
                  height: 1,
                  color: colors.outlineVariant,
                  indent: 14,
                  endIndent: 14,
                ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        keys[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: Text(
                        valueOf(keys[index]) ?? '—',
                        style: context.texts.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _RawPayload extends StatelessWidget {
  const _RawPayload({required this.caption, required this.payload});

  final String caption;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Caption(label: caption),
          const SizedBox(height: 4),
          SelectableText(
            payload,
            style: context.texts.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: tone == StatusTone.neutral ? colors.surface : pair.background,
        borderRadius: BorderRadius.circular(14),
        border: tone == StatusTone.neutral
            ? Border.all(color: colors.outlineVariant)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: tone == StatusTone.neutral
                ? colors.onSurfaceVariant
                : pair.foreground,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodySmall?.copyWith(
                color: tone == StatusTone.neutral
                    ? colors.onSurfaceVariant
                    : pair.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.texts.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class _ConflictActionBar extends StatelessWidget {
  const _ConflictActionBar({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppButton(
            label: label,
            icon: Icons.cloud_download_outlined,
            large: true,
            expand: true,
            isLoading: busy,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _MissingConflict extends StatelessWidget {
  const _MissingConflict({
    required this.title,
    required this.message,
    required this.body,
  });

  final String title;
  final String message;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConflictBar(title: title),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(20),
              child: EmptyState(
                title: message,
                body: body,
                icon: Icons.task_alt,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic>? _asMap(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(text);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on Object {
    return null;
  }
}

String? _valueText(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return '$value';
  }
  return jsonEncode(value);
}
