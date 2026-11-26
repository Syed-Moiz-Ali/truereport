import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'fieldwork_ui.dart';

/// Job context for the item screen's top bar. All strings are resolved by the
/// page wrapper so the screen stays presentational.
class FieldworkItemHeader {
  const FieldworkItemHeader({
    required this.backLabel,
    required this.title,
    required this.reference,
    required this.done,
    required this.total,
    this.statusLabel,
    this.statusTone = StatusTone.neutral,
    required this.progressLabel,
  });

  final String backLabel;
  final String title;
  final String reference;
  final int done;
  final int total;
  final String? statusLabel;
  final StatusTone statusTone;
  final String progressLabel;
}

/// The item screen: one focus card (hero, verdict, detail chips, evidence,
/// notes) and one pinned action that owns saving.
class FieldworkItemScreen extends StatelessWidget {
  const FieldworkItemScreen({
    required this.header,
    required this.hero,
    required this.zones,
    required this.footer,
    this.banner,
    super.key,
  });

  final FieldworkItemHeader header;
  final Widget hero;

  /// Zones of the focus card, separated by hairlines. Each is laid out with
  /// the module's 20/16 padding; none draws its own outer card.
  final List<Widget> zones;
  final Widget footer;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return Column(
          children: [
            _ItemBar(header: header, wide: wide),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  wide ? 24 : 14,
                  wide ? 20 : 14,
                  wide ? 24 : 14,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: FieldworkMetrics.focusMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (banner != null) ...[
                          banner!,
                          const SizedBox(height: 12),
                        ],
                        FieldworkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FieldworkTint(child: hero),
                              for (
                                var index = 0;
                                index < zones.length;
                                index++
                              ) ...[
                                if (index > 0) const FieldworkDivider(),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    20,
                                    16,
                                    20,
                                    18,
                                  ),
                                  child: zones[index],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            footer,
          ],
        );
      },
    );
  }
}

class _ItemBar extends StatelessWidget {
  const _ItemBar({required this.header, required this.wide});

  final FieldworkItemHeader header;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(wide ? 16 : 10, 9, 14, 9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: Row(
            children: [
              FieldworkIconButton(
                icon: rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                semanticLabel: header.backLabel,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      header.title,
                      maxLines: 2,
                      style: fieldworkText(
                        context,
                        15,
                        weight: FontWeight.w800,
                        height: 19,
                        tracking: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (header.reference.trim().isNotEmpty)
                          Text(
                            header.reference,
                            textDirection: TextDirection.ltr,
                            style: fieldworkNumber(
                              context,
                              11.5,
                              weight: FontWeight.w600,
                              height: 15,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          header.progressLabel,
                          style: fieldworkNumber(
                            context,
                            11.5,
                            weight: FontWeight.w700,
                            height: 15,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        if (header.statusLabel != null)
                          FieldworkPill(
                            label: header.statusLabel!,
                            tone: header.statusTone,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 30,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    FieldworkMetrics.chipRadius,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${header.done}/${header.total}',
                  textDirection: TextDirection.ltr,
                  style: fieldworkNumber(
                    context,
                    11.5,
                    weight: FontWeight.w800,
                    height: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One read-only label/value pair.
class FieldworkValue {
  const FieldworkValue({required this.label, required this.value});

  final String label;
  final String value;
}

/// Read-only answer: the served result and every value the technician saved.
/// No field, no capture affordance, nothing to type into.
class FieldworkValues extends StatelessWidget {
  const FieldworkValues({
    required this.resultLabel,
    required this.resultTone,
    required this.values,
    this.resultCaption,
    super.key,
  });

  final String resultLabel;
  final StatusTone resultTone;
  final List<FieldworkValue> values;
  final String? resultCaption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resultCaption != null) ...[
          Text(resultCaption!, style: fieldworkEyebrow(context)),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FieldworkPill(label: resultLabel, tone: resultTone),
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (var index = 0; index < values.length; index++) ...[
            if (index > 0) const FieldworkDivider(),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      values[index].label,
                      style: fieldworkText(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        height: 18,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Text(
                      values[index].value,
                      textAlign: TextAlign.end,
                      style: fieldworkNumber(
                        context,
                        13,
                        weight: FontWeight.w700,
                        height: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// The conditional notes block. Only rendered when the served rule requires
/// notes; controllers and counters stay in the page.
class FieldworkNotes extends StatelessWidget {
  const FieldworkNotes({
    required this.title,
    required this.counter,
    required this.englishLabel,
    required this.arabicLabel,
    required this.englishController,
    required this.arabicController,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final String title;
  final String counter;
  final String englishLabel;
  final String arabicLabel;
  final TextEditingController englishController;
  final TextEditingController arabicController;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldworkSectionHeader(
          title: title,
          // The counter rides with its unit: numbers and characters.
          trailing: Text(
            counter,
            textDirection: TextDirection.ltr,
            style: fieldworkNumber(
              context,
              12.5,
              weight: FontWeight.w700,
              height: 16,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppTextField(
          controller: englishController,
          label: englishLabel,
          labelAbove: true,
          maxLines: 3,
          enabled: enabled,
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        AppTextField(
          controller: arabicController,
          label: arabicLabel,
          labelAbove: true,
          maxLines: 3,
          enabled: enabled,
          textDirection: TextDirection.rtl,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The pinned action bar: primary outcome (or Back when read-only) and an
/// optional secondary that moves on without saving.
class ItemFooter extends StatelessWidget {
  const ItemFooter({
    required this.primaryLabel,
    required this.onPrimary,
    this.saving = false,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool saving;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    final secondaryAction = onSecondary;
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > 1.2 ||
        MediaQuery.sizeOf(context).width < 360;
    final primary = FieldworkButton(
      label: primaryLabel,
      isLoading: saving,
      onPressed: saving ? null : onPrimary,
      expand: true,
    );
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FieldworkMetrics.focusMaxWidth,
          ),
          child: !stacked && secondary != null && secondaryAction != null
              ? Row(
                  children: [
                    Expanded(child: primary),
                    const SizedBox(width: 10),
                    FieldworkButton(
                      label: secondary,
                      variant: FieldworkButtonVariant.ghost,
                      onPressed: secondaryAction,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primary,
                    if (secondary != null && secondaryAction != null) ...[
                      const SizedBox(height: 8),
                      FieldworkButton(
                        label: secondary,
                        variant: FieldworkButtonVariant.ghost,
                        height: FieldworkMetrics.secondaryHeight,
                        expand: true,
                        onPressed: secondaryAction,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
