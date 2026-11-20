import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_create.dart';

/// Create-job entry point. The single-page form lives under dispatch/.
class JobCreationWizardPage extends StatelessWidget {
  const JobCreationWizardPage({super.key});

  @override
  Widget build(BuildContext context) => const DispatchCreateJob();
}
