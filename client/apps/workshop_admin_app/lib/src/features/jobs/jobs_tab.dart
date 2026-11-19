import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_queue.dart';

/// Shell host for the jobs module. The public class name is part of the shell
/// contract; the screen itself lives under `dispatch/`.
class JobsTab extends StatelessWidget {
  const JobsTab({super.key});

  @override
  Widget build(BuildContext context) => const DispatchQueuePage();
}
