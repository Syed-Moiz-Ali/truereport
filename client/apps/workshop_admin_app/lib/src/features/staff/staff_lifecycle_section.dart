import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/models.dart';

/// `01 Status` — the account lifecycle for one member.
///
/// Active accounts can be deactivated; disabled accounts can be reactivated.
/// Both transitions require a reason, so the action expands into an in-place
/// confirmation strip instead of opening a dialog. A pending invitation has no
/// lifecycle transition in the API surface this app holds, so no action is
/// offered for it.
class StaffLifecycleSection extends StatefulWidget {
  const StaffLifecycleSection({
    required this.title,
    required this.member,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  final String title;
  final StaffMember member;
  final Future<void> Function(String reason) onDeactivate;
  final Future<void> Function(String reason) onReactivate;

  @override
  State<StaffLifecycleSection> createState() => _StaffLifecycleSectionState();
}

class _StaffLifecycleSectionState extends State<StaffLifecycleSection> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _open = false;
  bool _busy = false;

  bool get _isActive => widget.member.status == 'ACTIVE';
  bool get _isDisabled => widget.member.status == 'DISABLED';

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _open = true);
  }

  void _cancel() {
    _reason.clear();
    setState(() {
      _open = false;
      _busy = false;
    });
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
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
      setState(() {
        _open = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final showAction = _isActive || _isDisabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StaffSectionHead(number: '01', title: widget.title),
        const SizedBox(height: 16),
        Row(
          children: [
            StaffStatusPill(status: widget.member.status),
            const Spacer(),
            if (showAction && !_open)
              WorkshopButton(
                label: _isDisabled ? l10n.reactivate : l10n.deactivate,
                variant: _isDisabled
                    ? WorkshopButtonVariant.secondary
                    : WorkshopButtonVariant.danger,
                icon: _isDisabled ? Icons.lock_open_outlined : Icons.lock_outline,
                onPressed: _start,
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topStart,
          child: _open
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: 16),
                  child: Container(
                    key: const Key('staff-lifecycle-confirm'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_isDisabled ? ws.accentSoft : ws.dangerSoft)
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(ws.cardRadius - 4),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WorkshopTextField(
                            key: const Key('staff-lifecycle-reason'),
                            controller: _reason,
                            label: _isDisabled
                                ? l10n.reason
                                : l10n.deactivateReason,
                            hint: l10n.reason,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _confirm(),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? l10n.requiredField
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WorkshopButton(
                                label: l10n.cancel,
                                variant: WorkshopButtonVariant.ghost,
                                onPressed: _busy ? null : _cancel,
                              ),
                              const SizedBox(width: 8),
                              WorkshopButton(
                                label: _isDisabled
                                    ? l10n.reactivate
                                    : l10n.deactivate,
                                variant: _isDisabled
                                    ? WorkshopButtonVariant.secondary
                                    : WorkshopButtonVariant.danger,
                                isLoading: _busy,
                                onPressed: _busy ? null : _confirm,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
