import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_page.dart';

/// Shell host for the job queue. The public class name is part of the shell
/// contract; the screen itself lives under `queue/`.
class JobsTab extends StatelessWidget {
  const JobsTab({super.key});

  @override
  Widget build(BuildContext context) => const JobsQueuePage();
}
