import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Chrome for the three-step template route: bar, stepper, footer, lock panel.
class TemplateRouteTopBar extends StatelessWidget {
  const TemplateRouteTopBar({
    required this.title,
    required this.template,
    required this.readOnly,
    required this.busy,
    required this.onSaveDraft,
    super.key,
  });

  final String title;
  final TemplateDetail? template;
  final bool readOnly;
  final bool busy;
  final VoidCallback onSaveDraft;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Container(
      height: ws.topBarHeight,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
      ),
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Row(
            children: [
              WorkshopIconButton(
                icon: isRtl ? Icons.arrow_forward : Icons.arrow_back,
                semanticLabel: t(WorkshopAdminKeys.commonBack),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
              ),
              if (template != null && !narrow) ...[
                TemplateStatusPill(status: template!.status),
                const SizedBox(width: 12),
              ],
              if (!readOnly && !narrow)
                TemplatePillButton(
                  label: t(WorkshopAdminKeys.saveDraft),
                  icon: Icons.save_outlined,
                  variant: TemplatePillVariant.ghost,
                  compact: true,
                  loading: busy,
                  onPressed: busy ? null : onSaveDraft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplateRouteStepper extends StatelessWidget {
  const TemplateRouteStepper({
    required this.step,
    required this.onSelect,
    super.key,
  });

  final int step;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final steps = [
      t(WorkshopAdminKeys.details),
      t(WorkshopAdminKeys.builderSequenceTitle),
      t(WorkshopAdminKeys.publishTemplate),
    ];
    return Container(
      color: ws.surface,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(width),
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: width < 520
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _pill(context, step, '${step + 1}/3 · ${steps[step]}'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < steps.length; i++) ...[
                        _pill(context, i, steps[i]),
                        if (i < steps.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, int index, String label) {
    final ws = context.ws;
    final active = step == index;
    final done = index < step;
    final bg = active
        ? ws.ink
        : done
        ? ws.accentSoft
        : ws.canvas;
    final fg = active
        ? ws.canvas
        : done
        ? ws.accent
        : ws.muted;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 32,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? ws.ink : ws.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: ws.meta.copyWith(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: ws.meta.copyWith(color: fg, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplateRouteFooter extends StatelessWidget {
  const TemplateRouteFooter({
    required this.step,
    required this.busy,
    required this.onBack,
    required this.onNext,
    required this.onSaveDraft,
    super.key,
  });

  final int step;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSaveDraft;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 520;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(width),
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: Row(
            children: [
              if (narrow)
                TemplatePillButton(
                  label: t(WorkshopAdminKeys.saveDraft),
                  variant: TemplatePillVariant.ghost,
                  compact: true,
                  loading: busy,
                  onPressed: busy ? null : onSaveDraft,
                )
              else if (step > 0)
                TemplatePillButton(
                  label: t(WorkshopAdminKeys.commonBack),
                  icon: Icons.arrow_back,
                  variant: TemplatePillVariant.ghost,
                  onPressed: onBack,
                ),
              const Spacer(),
              TemplatePillButton(
                label: step == 0
                    ? t(WorkshopAdminKeys.commonNext)
                    : t(WorkshopAdminKeys.publishTemplate),
                icon: step == 0 ? null : Icons.arrow_forward,
                variant: step == 0
                    ? TemplatePillVariant.filled
                    : TemplatePillVariant.outline,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplateRouteLockedPanel extends StatelessWidget {
  const TemplateRouteLockedPanel({
    required this.busy,
    required this.onCreateDraft,
    super.key,
  });

  final bool busy;
  final VoidCallback onCreateDraft;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: ws.muted),
              const SizedBox(width: 8),
              Text(
                t(WorkshopAdminKeys.readOnlyVersion),
                style: ws.cardTitle.copyWith(color: ws.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t(WorkshopAdminKeys.createDraft),
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 16),
          TemplatePillButton(
            label: t(WorkshopAdminKeys.createDraft),
            icon: Icons.add,
            onPressed: busy ? null : onCreateDraft,
          ),
        ],
      ),
    );
  }
}
