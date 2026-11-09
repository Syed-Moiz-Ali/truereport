import 'dart:ui' as ui;

import 'package:admin_app/src/screens/f3b/deactivation_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen 10 — Share-Link Deactivation (destructive modal dialog).
///
/// Pixel-perfect layout matching Figma spec `10_10._Share-Link_Deactivation`
/// (node `1:2502`, dialog frame `1:2610`, 448 x 576.1).
class ShareLinkDeactivationDialog extends StatefulWidget {
  const ShareLinkDeactivationDialog({
    super.key,
    this.initialReason,
    this.onConfirm,
    this.onCancel,
  });

  final String? initialReason;
  final ValueChanged<String>? onConfirm;
  final VoidCallback? onCancel;

  static Future<String?> show(
    BuildContext context, {
    String? initialReason,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x33000000),
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: ShareLinkDeactivationDialog(
                initialReason: initialReason,
                onConfirm: (reason) => Navigator.of(ctx).pop(reason),
                onCancel: () => Navigator.of(ctx).pop(null),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<ShareLinkDeactivationDialog> createState() =>
      _ShareLinkDeactivationDialogState();
}

class _ShareLinkDeactivationDialogState
    extends State<ShareLinkDeactivationDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Widget _svg(String raw, double w, double h) {
    return SvgPicture.string(
      raw,
      width: w,
      height: h,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 448,
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Red Shield Warning Icon (56x56, r:16, bg: #FFDAD699)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0x99FFDAD6),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: _svg(DeactivationAssets.Icon_1_2614, 25.8, 24.8),
            ),
          ),
          const SizedBox(height: 16),
          // Heading: Deactivate Public Link
          const Text(
            'Deactivate Public Link',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Color(0xFF1A1B1F),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customer and fleet manager will no longer be able to\nview this live report.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xFF5E5D69),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Pastel Red Warning Box (368x76, r:16, bg: #FFDAD666, border: #FFDAD6)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x66FFDAD6),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: const Color(0xFFFFDAD6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFDAD6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg(DeactivationAssets.Icon_1_2623, 13.3, 16.7),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'This will instantly block customer access',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF93000A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Reason input label
          const Text(
            'REASON FOR DEACTIVATION (REQUIRED)',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
              color: Color(0xFF5E5D69),
            ),
          ),
          const SizedBox(height: 8),
          // Reason text input (height: 52, r:16, border: #E3E2E7)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'e.g. Disputed damage markup or revised intake',
                hintStyle: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Color(0xB25E5D69),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF1A1B1F),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons Row: Cancel + Confirm Deactivation
          Row(
            children: [
              TextButton(
                onPressed: () {
                  if (widget.onCancel != null) {
                    widget.onCancel!();
                  } else {
                    Navigator.of(context).pop(null);
                  }
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF5E5D69),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final reason = _reasonController.text.trim();
                      if (widget.onConfirm != null) {
                        widget.onConfirm!(reason.isEmpty ? 'CUSTOMER_REQUEST' : reason);
                      } else {
                        Navigator.of(context).pop(reason.isEmpty ? 'CUSTOMER_REQUEST' : reason);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _svg(DeactivationAssets.Icon_1_2637, 16.7, 16.7),
                        const SizedBox(width: 8),
                        const Text(
                          'Confirm Deactivation',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Audit Trail Stamp
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _svg(DeactivationAssets.Icon_1_2642, 9.3, 11.7),
              const SizedBox(width: 8),
              const Text(
                'Action logged to Shop Audit Trail (ID #ACT-9902)',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  color: Color(0xFF5E5D69),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
