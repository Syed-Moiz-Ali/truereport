import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

/// The account lifecycle confirmation strip for one member.
///
/// The action itself lives in the page's pill row; this widget owns only the
/// reason field and the call. Active accounts can be deactivated and disabled
/// accounts reactivated, both with a reason, so the transition opens in place
/// instead of a dialog. There is no invitation flow in this module: staff are
/// created with credentials, so only Active and Disabled offer a transition.
class StaffLifecycleSection extends StatefulWidget {
  const StaffLifecycleSection({
    required this.member,
    required this.open,
    required this.onClose,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  final StaffMember member;

  /// Parent-owned visibility: the pill row opens it, success cancels it.
  final bool open;
  final VoidCallback onClose;
  final Future<void> Function(String reason) onDeactivate;
  final Future<void> Function(String reason) onReactivate;

  @override
  State<StaffLifecycleSection> createState() => _StaffLifecycleSectionState();
}

class _StaffLifecycleSectionState extends State<StaffLifecycleSection> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _busy = false;

  bool get _isDisabled => widget.member.status == 'DISABLED';

  @override
  void didUpdateWidget(StaffLifecycleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open && !widget.open) {
      _reason.clear();
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final t = UiStrings.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _busy = true);
    try {
      final reason = _reason.text.trim();
      if (_isDisabled) {
        await widget.onReactivate(reason);
      } else {
        await widget.onDeactivate(reason);
      }
      if (!mounted) {
        return;
      }
      _reason.clear();
      widget.onClose();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.contentSaved))),
        );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(t(WorkshopAdminKeys.actionFailed))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) {
      return const SizedBox.shrink();
    }
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final tone = _isDisabled ? ws.accentSoft : ws.dangerSoft;
    return Container(
      key: const Key('staff-lifecycle-confirm'),
      padding: EdgeInsetsDirectional.all(spacing.lg),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(ws.cardLargeRadius),
        border: Border.all(color: ws.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isDisabled
                  ? t(WorkshopAdminKeys.reactivate)
                  : t(WorkshopAdminKeys.deactivate),
              style: ws.sectionTitle.copyWith(color: ws.ink),
            ),
            const SizedBox(height: 10),
            WorkshopTextField(
              key: const Key('staff-lifecycle-reason'),
              controller: _reason,
              label: _isDisabled
                  ? t(WorkshopAdminKeys.reason)
                  : t(WorkshopAdminKeys.deactivateReason),
              hint: t(WorkshopAdminKeys.reason),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _confirm(),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? t(WorkshopAdminKeys.requiredField)
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TemplatePillButton(
                  label: t(WorkshopAdminKeys.cancel),
                  variant: TemplatePillVariant.ghost,
                  onPressed: _busy ? null : widget.onClose,
                ),
                const SizedBox(width: 10),
                TemplatePillButton(
                  label: _isDisabled
                      ? t(WorkshopAdminKeys.reactivate)
                      : t(WorkshopAdminKeys.deactivate),
                  variant: _isDisabled
                      ? TemplatePillVariant.outline
                      : TemplatePillVariant.danger,
                  loading: _busy,
                  onPressed: _busy ? null : _confirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
