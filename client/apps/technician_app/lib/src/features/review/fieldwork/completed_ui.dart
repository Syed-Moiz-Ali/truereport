import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';
import 'review_ui.dart';

/// The handover moment: one calm success mark, what was completed, and one way
/// out. The page supplies the served status and the receipt rows.
class CompletedView extends StatelessWidget {
  const CompletedView({
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.statusTone,
    required this.receiptRows,
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
  });

  final String title;
  final String body;
  final String statusLabel;
  final StatusTone statusTone;
  final List<ReviewReceiptRow> receiptRows;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 28, 20, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ReviewSuccessMark(),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: fieldworkText(
                  context,
                  26,
                  weight: FontWeight.w800,
                  height: 32,
                  tracking: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: fieldworkText(
                  context,
                  13.5,
                  height: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: FieldworkPill(label: statusLabel, tone: statusTone),
              ),
              if (receiptRows.isNotEmpty) ...[
                const SizedBox(height: 26),
                ReviewReceipt(rows: receiptRows),
              ],
              const SizedBox(height: 28),
              FieldworkButton(
                label: primaryLabel,
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
