import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/templates/template_index.dart';

/// Workshop Admin templates section.
///
/// The section is an index; the route editor lives on its own pushed page so a
/// 40-item sequence never competes with tab navigation.
class TemplatesTab extends StatelessWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context) => const TemplateIndex();
}
