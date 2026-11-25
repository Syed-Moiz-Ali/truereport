import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags for the platform admin console.
///
/// Localization is backend-driven, so the translation review desk is part of
/// the product and is always visible. Only the expert workflow editor is gated.
///
/// ```
/// flutter run --dart-define=TRUEREPORT_WORKFLOW_EDITING=true
/// ```

/// Expert workflow editing at `/configuration/transitions`.
///
/// Off by default because a wrong edit changes which job actions a workshop
/// admin is allowed to take. Enable it only for operators who own the
/// lifecycle configuration.
final workflowEditingEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('TRUEREPORT_WORKFLOW_EDITING'),
);
