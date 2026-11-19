import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the full-screen technician profile.
Future<void> showTechnicianProfile(BuildContext context, WidgetRef ref) {
  return context.push('/profile');
}
