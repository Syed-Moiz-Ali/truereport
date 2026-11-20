import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/jobs/assigned_jobs_view.dart'
    hide EmptyJobsView;
import 'package:technician_app/src/features/jobs/empty_jobs_view.dart';
import 'package:technician_app/src/features/auth/signin/technician_sign_in_view.dart';
import 'package:technician_app/src/features/jobs/consent_view.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/features/jobs/equipment_view.dart';
import 'package:technician_app/src/features/inspection/inspection_hub_view.dart';
import 'package:technician_app/src/features/inspection/exterior_wireframe_view.dart';
import 'package:technician_app/src/features/jobs/job_intake_view.dart';

import 'f2a_fixture_data.dart';
import 'ui_strings_harness.dart';
import 'test_reference_overrides.dart';

const f2aScreenIds = <String>[
  'login',
  'assigned-jobs',
  'empty-state',
  'job-intake',
  'consent',
  'equipment',
  'inspection-hub',
  'exterior-wireframe',
];

/// Builds an F2-A screen for tests.
///
/// [figma] selects *data* fixtures only (technician name, jobs, checklist).
/// Screens always render product widgets; there is no `figmaText` switch in
/// `lib/` anymore. To render Figma *copy*, pump the result with
/// [f2aHost] and `figmaStrings: true` (English only), which swaps in the
/// test-only [FigmaTestLocalizations] override.
Widget f2aScreen(
  String id, {
  bool figma = true,
  ui.Image? avatarImage,
  ui.Image? vehicleImage,
}) {
  switch (id) {
    case 'login':
      return TechnicianSignInView(
        emailController: TextEditingController(),
        passwordController: TextEditingController(),
        codeController: TextEditingController(),
        formKey: GlobalKey<FormState>(),
        onSubmit: () {},
        onValidateEmail: (_) => null,
        onValidateRequired: (_) => null,
        onValidateCode: (_) => null,
        emailFocus: FocusNode(),
        passwordFocus: FocusNode(),
        codeFocus: FocusNode(),
      );
    case 'assigned-jobs':
      return AssignedJobsView(
        technicianName: figma ? 'David Vance' : 'Layla Hassan',
        jobs: figma ? figmaJobs : productJobs,
        pendingSyncCount: 0,
        online: true,
        onOpenJob: (_) {},
        onRefresh: () async {},
        onWalkIn: () {},
        onSync: () {},
        onProfile: () {},
        nowUtc: figmaNow,
        showSearch: false,
        avatarImage: avatarImage,
        snapshotPendingValue: figma ? '3 Tasks' : null,
        snapshotSecondaryValue: figma ? '45 min' : null,
        snapshotSecondaryLabel: figma ? 'Avg. turnover' : null,
      );
    case 'empty-state':
      return EmptyJobsView(
        technicianName: figma ? 'David Vance' : 'Layla Hassan',
        pendingSyncCount: 0,
        completedToday: figma ? 14 : 0,
        onRefresh: () async {},
        onWalkIn: () {},
        onSync: () {},
        onProfile: () {},
        avatarImage: avatarImage,
      );
    case 'job-intake':
      return JobIntakeView(
        job: figma
            ? figmaJob(template: 'Vehicle Walkaround Inspection')
            : productJobs.first,
        onStart: () {},
        onEditCustomer: () {},
        onEditVehicle: () {},
        onConsent: () {},
        onEquipment: () {},
        onProfile: () {},
        avatarImage: avatarImage,
        vehicleImage: vehicleImage,
      );
    case 'consent':
      return ConsentView(
        selectedType: null,
        selectedStatus: null,
        onTypeChanged: (_) {},
        onStatusChanged: (_) {},
        onSave: () async {},
        onBack: () {},
        onProfile: () {},
        title: figma ? 'Vehicle Walkaround Inspection' : null,
      );
    case 'equipment':
      return EquipmentView(
        equipment: const [
          EquipmentItem(
            equipmentId: 'eq-1',
            code: 'TDG',
            labelEn: 'Tire Depth Gauge',
            labelAr: 'مقياس عمق الإطار',
            status: 'ACTIVE',
            sortOrder: 1,
          ),
          EquipmentItem(
            equipmentId: 'eq-2',
            code: 'OBD',
            labelEn: 'OBD Scanner',
            labelAr: 'ماسح OBD',
            status: 'ACTIVE',
            sortOrder: 2,
          ),
          EquipmentItem(
            equipmentId: 'eq-3',
            code: 'TW',
            labelEn: 'Torque Wrench',
            labelAr: 'مفتاح عزم',
            status: 'ACTIVE',
            sortOrder: 3,
          ),
          EquipmentItem(
            equipmentId: 'eq-4',
            code: 'PDG',
            labelEn: 'Paint Depth Gauge',
            labelAr: 'مقياس عمق الطلاء',
            status: 'ACTIVE',
            sortOrder: 4,
          ),
        ],
        onProceed: () {},
        onBack: () {},
        onProfile: () {},
        title: figma ? 'Diagnostic Checklist' : null,
      );
    case 'inspection-hub':
      final checklist = figma ? figmaChecklist() : productChecklist();
      return InspectionHubView(
        job: checklist.job,
        checklist: checklist,
        onOpenModule: (_) {},
        onContinue: () {},
        onVehicle: () {},
        onSync: () {},
        onProfile: () {},
        avatarImage: avatarImage,
        vehicleImage: vehicleImage,
      );
    case 'exterior-wireframe':
      return ExteriorWireframeView(
        onBack: () {},
        onProfile: () {},
        avatarImage: avatarImage,
      );
    default:
      throw ArgumentError('Unknown F2-A screen: $id');
  }
}

Widget f2aHost({
  required Widget child,
  required Locale locale,
  required ThemeData theme,
  double textScale = 1,
  bool figmaStrings = false,
}) {
  return ProviderScope(
    overrides: testReferenceStatusOverrides(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: testLocalizationsDelegates,
      theme: theme,
      builder: (context, appChild) => UiStringsScope(
        strings: figmaStrings ? figmaStringsBundle() : baseStrings(),
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: appChild ?? const SizedBox.shrink(),
        ),
      ),
      home: child,
    ),
  );
}
