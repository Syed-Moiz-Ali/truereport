import 'package:flutter/material.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_detail.dart';

/// Clean job detail entry point. The record itself lives under dispatch/.
class JobDetailPage extends StatelessWidget {
  const JobDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context) => DispatchJobDetail(jobId: jobId);
}
