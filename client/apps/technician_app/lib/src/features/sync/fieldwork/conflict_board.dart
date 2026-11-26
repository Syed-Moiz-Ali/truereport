import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';
import 'sync_board.dart';

/// One conflict, side by side in the Fieldwork language: the revision that
/// moved, what differs, and the only supported resolution.
///
/// Presentation only: the page resolves copy, parses the payloads and owns the
/// resolve call.

class ConflictHeaderData {
  const ConflictHeaderData({required this.title, this.counterLabel});

  final String title;

  /// "1 / 3"; null hides the counter pill.
  final String? counterLabel;
}

class ConflictIdentityData {
  const ConflictIdentityData({
    required this.itemCode,
    required this.jobLabel,
    required this.phoneRevision,
    required this.serverRevision,
    required this.phoneRevLabel,
    required this.serverRevLabel,
  });

  final String itemCode;
  final String jobLabel;

  /// Rendered LTR so RTL cannot reorder the revision pair.
  final String phoneRevision;
  final String serverRevision;
  final String phoneRevLabel;
  final String serverRevLabel;
}

class ConflictFieldData {
  const ConflictFieldData({
    required this.label,
    required this.phoneValue,
    required this.serverValue,
    required this.phoneMuted,
    required this.serverMuted,
  });

  final String label;
  final String phoneValue;
  final String serverValue;

  /// True when the phone card is showing a "only on the server" explanation
  /// instead of a value.
  final bool phoneMuted;
  final bool serverMuted;
}

class ConflictCompareData {
  const ConflictCompareData({
    required this.caption,
    required this.phoneCaption,
    required this.serverCaption,
    required this.structured,
    this.fields = const <ConflictFieldData>[],
    this.rawPhone = '',
    this.rawServer = '',
  });

  final String caption;
  final String phoneCaption;
  final String serverCaption;

  /// False when the payloads are not JSON objects; the board then shows the
  /// pretty-printed payload instead of a fabricated field list.
  final bool structured;
  final List<ConflictFieldData> fields;
  final String rawPhone;
  final String rawServer;
}

class ConflictNoteData {
  const ConflictNoteData({
    required this.message,
    required this.tone,
    required this.icon,
  });

  final String message;
  final StatusTone tone;
  final IconData icon;
}

class ConflictMissingData {
  const ConflictMissingData({required this.title, required this.body});

  final String title;
  final String body;
}

class ConflictErrorData {
  const ConflictErrorData({
    required this.title,
    required this.body,
    required this.retryLabel,
  });

  final String title;
  final String body;
  final String retryLabel;
}

/// The whole conflict screen. The page owns the record lookup and resolution;
/// this widget owns layout and every visual state.
class ConflictBoard extends StatelessWidget {
  const ConflictBoard({
    required this.header,
    required this.actionLabel,
    required this.busy,
    required this.loading,
    required this.onBack,
    required this.onUseServer,
    required this.onRetry,
    this.identity,
    this.compare,
    this.notes = const <ConflictNoteData>[],
    this.missing,
    this.error,
    super.key,
  });

  final ConflictHeaderData header;
  final ConflictIdentityData? identity;
  final ConflictCompareData? compare;
  final List<ConflictNoteData> notes;
  final ConflictMissingData? missing;
  final ConflictErrorData? error;
  final String actionLabel;
  final bool busy;
  final bool loading;

  final VoidCallback onBack;
  final VoidCallback onUseServer;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    final ready =
        identity != null &&
        compare != null &&
        !loading &&
        error == null &&
        missing == null;
    return Column(
      children: [
        SyncTopBar(
          header: SyncHeaderData(title: header.title),
          onBack: onBack,
          trailing: header.counterLabel == null
              ? null
              : FieldworkPill(
                  label: header.counterLabel!,
                  tone: StatusTone.danger,
                  icon: Icons.sync_problem_rounded,
                  dense: true,
                ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: context.brand.ink,
            backgroundColor: context.colors.surface,
            onRefresh: () async => onRetry(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final centre = loading || error != null || missing != null;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsetsDirectional.fromSTEB(hPad, 18, hPad, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: FieldworkMetrics.focusMaxWidth,
                      ),
                      child: centre
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: (constraints.maxHeight - 42).clamp(
                                  0,
                                  double.infinity,
                                ),
                              ),
                              child: Center(child: _stateBody(context)),
                            )
                          : _contentBody(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (ready)
          _ConflictActionBar(
            label: actionLabel,
            busy: busy,
            onPressed: busy ? null : onUseServer,
          ),
      ],
    );
  }

  Widget _stateBody(BuildContext context) {
    if (loading) {
      return const _ConflictSkeleton();
    }
    final errorData = error;
    if (errorData != null) {
      return _ConflictStatePanel(
        icon: Icons.error_outline_rounded,
        tone: StatusTone.danger,
        title: errorData.title,
        body: errorData.body,
        action: FieldworkButton(
          label: errorData.retryLabel,
          icon: Icons.refresh_rounded,
          height: FieldworkMetrics.secondaryHeight,
          onPressed: onRetry,
        ),
      );
    }
    final missingData = missing;
    if (missingData != null) {
      return _ConflictStatePanel(
        icon: Icons.task_alt_rounded,
        tone: StatusTone.success,
        title: missingData.title,
        body: missingData.body,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _contentBody(BuildContext context) {
    final identityData = identity;
    final compareData = compare;
    if (identityData == null || compareData == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          identityData.itemCode,
          maxLines: 2,
          style: fieldworkText(
            context,
            26,
            weight: FontWeight.w800,
            height: 31,
            tracking: -0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          identityData.jobLabel,
          style: fieldworkText(
            context,
            13,
            weight: FontWeight.w600,
            height: 18,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _RevisionStrip(data: identityData),
        const SizedBox(height: 20),
        Text(
          compareData.caption.toUpperCase(),
          style: fieldworkEyebrow(context),
        ),
        const SizedBox(height: 8),
        _Comparison(data: compareData),
        if (notes.isNotEmpty) const SizedBox(height: 16),
        for (var index = 0; index < notes.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          FieldworkNote(
            message: notes[index].message,
            tone: notes[index].tone,
            icon: notes[index].icon,
          ),
        ],
      ],
    );
  }
}

class _RevisionStrip extends StatelessWidget {
  const _RevisionStrip({required this.data});

  final ConflictIdentityData data;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _RevisionColumn(
              value: data.phoneRevision,
              label: data.phoneRevLabel,
              tone: StatusTone.info,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            child: Icon(
              rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _RevisionColumn(
              value: data.serverRevision,
              label: data.serverRevLabel,
              tone: StatusTone.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevisionColumn extends StatelessWidget {
  const _RevisionColumn({
    required this.value,
    required this.label,
    required this.tone,
  });

  final String value;
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: fieldworkNumber(
            context,
            26,
            weight: FontWeight.w800,
            height: 30,
            tracking: -0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fieldworkText(
            context,
            11,
            weight: FontWeight.w700,
            height: 14,
            tracking: 0.6,
            color: pair.foreground,
          ),
        ),
      ],
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.data});

  final ConflictCompareData data;

  @override
  Widget build(BuildContext context) {
    if (!data.structured) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.rawPhone.isNotEmpty)
            _RawPayloadCard(
              caption: data.phoneCaption,
              tone: StatusTone.info,
              icon: Icons.smartphone_rounded,
              payload: data.rawPhone,
            ),
          if (data.rawPhone.isNotEmpty && data.rawServer.isNotEmpty)
            const SizedBox(height: 10),
          if (data.rawServer.isNotEmpty)
            _RawPayloadCard(
              caption: data.serverCaption,
              tone: StatusTone.success,
              icon: Icons.cloud_outlined,
              payload: data.rawServer,
            ),
        ],
      );
    }

    final phone = _PayloadCard(
      caption: data.phoneCaption,
      tone: StatusTone.info,
      icon: Icons.smartphone_rounded,
      fields: [
        for (final field in data.fields)
          _PanelField(
            label: field.label,
            value: field.phoneValue,
            muted: field.phoneMuted,
          ),
      ],
    );
    final server = _PayloadCard(
      caption: data.serverCaption,
      tone: StatusTone.success,
      icon: Icons.cloud_outlined,
      fields: [
        for (final field in data.fields)
          _PanelField(
            label: field.label,
            value: field.serverValue,
            muted: field.serverMuted,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return _WideComparison(data: data);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [phone, const SizedBox(height: 10), server],
        );
      },
    );
  }
}

/// On wide screens the two payloads share one aligned table, so a field's phone
/// and server values sit on the same line and the eye can scan the difference.
class _WideComparison extends StatelessWidget {
  const _WideComparison({required this.data});

  final ConflictCompareData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phonePair = context.statusColors.forTone(StatusTone.info);
    final serverPair = context.statusColors.forTone(StatusTone.success);
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colors.surfaceContainerLow,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 9),
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox.shrink()),
                Expanded(
                  flex: 4,
                  child: _ColumnCaption(
                    caption: data.phoneCaption,
                    color: phonePair.foreground,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: _ColumnCaption(
                    caption: data.serverCaption,
                    color: serverPair.foreground,
                  ),
                ),
              ],
            ),
          ),
          if (data.fields.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.all(14),
              child: Text(
                '—',
                style: fieldworkText(
                  context,
                  14,
                  height: 19,
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < data.fields.length; index++) ...[
              if (index > 0) const FieldworkDivider(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        data.fields[index].label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: fieldworkText(
                          context,
                          11,
                          weight: FontWeight.w700,
                          height: 14,
                          tracking: 0.2,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: _ColumnValue(
                        value: data.fields[index].phoneValue,
                        muted: data.fields[index].phoneMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: _ColumnValue(
                        value: data.fields[index].serverValue,
                        muted: data.fields[index].serverMuted,
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

class _ColumnCaption extends StatelessWidget {
  const _ColumnCaption({required this.caption, required this.color});

  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            caption.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: fieldworkText(
              context,
              11,
              weight: FontWeight.w700,
              height: 14,
              tracking: 0.8,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColumnValue extends StatelessWidget {
  const _ColumnValue({required this.value, required this.muted});

  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textDirection: _isNumericValue(value) ? TextDirection.ltr : null,
      style: fieldworkText(
        context,
        13,
        weight: muted ? FontWeight.w500 : FontWeight.w600,
        height: 18,
        color: muted
            ? context.colors.onSurfaceVariant
            : context.colors.onSurface,
      ),
    );
  }
}

class _PayloadCard extends StatelessWidget {
  const _PayloadCard({
    required this.caption,
    required this.tone,
    required this.icon,
    required this.fields,
  });

  final String caption;
  final StatusTone tone;
  final IconData icon;
  final List<_PanelField> fields;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: pair.background,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 9),
            child: Row(
              children: [
                Icon(icon, size: 15, color: pair.foreground),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    caption.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fieldworkText(
                      context,
                      11,
                      weight: FontWeight.w700,
                      height: 14,
                      tracking: 0.8,
                      color: pair.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (fields.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.all(14),
              child: Text(
                '—',
                style: fieldworkText(
                  context,
                  14,
                  height: 19,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var index = 0; index < fields.length; index++) ...[
              if (index > 0) const FieldworkDivider(indent: 14),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fields[index].label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        11,
                        weight: FontWeight.w700,
                        height: 14,
                        tracking: 0.2,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fields[index].value,
                      textDirection: _isNumericValue(fields[index].value)
                          ? TextDirection.ltr
                          : null,
                      style: fieldworkText(
                        context,
                        13.5,
                        weight: fields[index].muted
                            ? FontWeight.w500
                            : FontWeight.w600,
                        height: 19,
                        color: fields[index].muted
                            ? context.colors.onSurfaceVariant
                            : context.colors.onSurface,
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

class _PanelField {
  const _PanelField({
    required this.label,
    required this.value,
    required this.muted,
  });

  final String label;
  final String value;
  final bool muted;
}

class _RawPayloadCard extends StatelessWidget {
  const _RawPayloadCard({
    required this.caption,
    required this.tone,
    required this.icon,
    required this.payload,
  });

  final String caption;
  final StatusTone tone;
  final IconData icon;
  final String payload;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return FieldworkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: pair.background,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 14, 9),
            child: Row(
              children: [
                Icon(icon, size: 15, color: pair.foreground),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    caption.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fieldworkText(
                      context,
                      11,
                      weight: FontWeight.w700,
                      height: 14,
                      tracking: 0.8,
                      color: pair.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(14),
            child: SelectableText(
              payload,
              style: fieldworkText(
                context,
                12,
                height: 17,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictSkeleton extends StatelessWidget {
  const _ConflictSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeleton(lines: 1, height: 26),
        SizedBox(height: 8),
        LoadingSkeleton(lines: 1, height: 14),
        SizedBox(height: 18),
        FieldworkCard(
          padding: EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: LoadingSkeleton(lines: 1, height: 30),
        ),
        SizedBox(height: 16),
        FieldworkCard(
          padding: EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: LoadingSkeleton(lines: 4, height: 32),
        ),
        SizedBox(height: 10),
        FieldworkCard(
          padding: EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: LoadingSkeleton(lines: 4, height: 32),
        ),
      ],
    );
  }
}

class _ConflictStatePanel extends StatelessWidget {
  const _ConflictStatePanel({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final StatusTone tone;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: pair.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: pair.foreground),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              18,
              weight: FontWeight.w800,
              height: 24,
              tracking: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              13,
              height: 19,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: FieldworkButton(
            label: label,
            icon: Icons.cloud_download_outlined,
            expand: true,
            isLoading: busy,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// Measurement-like values (`4.1 mm`, `12 %`) must keep LTR order in RTL.
bool _isNumericValue(String value) =>
    RegExp(r'^[\d.,]+\s*[A-Za-z%]+$').hasMatch(value.trim());
