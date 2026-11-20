import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Showcase for the reference-driven status, dropdown and transition widgets.
class ReferenceWidgetsShowcase extends StatefulWidget {
  const ReferenceWidgetsShowcase({super.key});

  @override
  State<ReferenceWidgetsShowcase> createState() =>
      _ReferenceWidgetsShowcaseState();
}

class _ReferenceWidgetsShowcaseState extends State<ReferenceWidgetsShowcase> {
  String _status = 'ASSIGNED';
  final List<String> _transitioned = <String>[];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: <Widget>[
            for (final token in const <String>[
              'neutral',
              'info',
              'success',
              'warning',
              'danger',
            ])
              StatusChip(label: token, tone: statusToneFromToken(token)),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        SizedBox(
          width: 280,
          child: OptionDropdown<String>(
            key: const Key('gallery-reference-dropdown'),
            items: const <String>['DRAFT', 'ASSIGNED', 'PUBLISHED'],
            value: _status,
            labelOf: (value) => value,
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
        ),
        SizedBox(height: context.spacing.lg),
        TransitionActions<String>(
          key: const Key('gallery-reference-transitions'),
          records: const <String>['ASSIGNED', 'APPROVE', 'REJECT', 'PUBLISH'],
          allowedOf: (code) => code == 'APPROVE' || code == 'REJECT',
          labelOf: (code) => 'Click $code',
          iconOf: (code) => code == 'APPROVE'
              ? Icons.check_circle_outline
              : Icons.block_outlined,
          onTap: (code) => setState(() => _transitioned.add(code)),
        ),
        if (_transitioned.isNotEmpty) ...<Widget>[
          SizedBox(height: context.spacing.sm),
          Text(
            'Tapped: ${_transitioned.join(', ')}',
            style: context.texts.bodySmall,
          ),
        ],
      ],
    );
  }
}
