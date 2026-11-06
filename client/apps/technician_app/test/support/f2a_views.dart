import 'dart:ui' as ui;

import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/screens/f2a/assigned_jobs_view.dart';
import 'package:technician_app/src/screens/f2a/consent_view.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2a/equipment_view.dart';
import 'package:technician_app/src/screens/f2a/inspection_hub_view.dart';
import 'package:technician_app/src/screens/f2a/job_intake_view.dart';

import 'f2a_fixture_data.dart';

const f2aScreenIds = <String>[
  'login',
  'assigned-jobs',
  'empty-state',
  'job-intake',
  'consent',
  'equipment',
  'inspection-hub',
];

Widget f2aScreen(
  String id, {
  bool figma = true,
  ui.Image? avatarImage,
  ui.Image? vehicleImage,
}) {
  switch (id) {
    case 'login':
      return SignInView(
        emailController: TextEditingController(),
        passwordController: TextEditingController(),
        codeController: TextEditingController(),
        formKey: GlobalKey<FormState>(),
        isArabic: false,
        onLocaleChanged: (_) {},
        onSubmit: () {},
        onValidateEmail: (_) => null,
        onValidateRequired: (_) => null,
        copy: figma
            ? const SignInCopy(
                brand: 'TechInspect',
                forgotLabel: 'Forgot password?',
                accessAction: 'Request ID',
                securityLabel: 'Authorised workshop staff only',
              )
            : null,
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
        figmaText: figma,
        avatarImage: avatarImage,
      );
    case 'empty-state':
      return EmptyJobsView(
        technicianName: figma ? 'David Vance' : 'Layla Hassan',
        pendingSyncCount: 0,
        onRefresh: () async {},
        onWalkIn: () {},
        onSync: () {},
        onProfile: () {},
        figmaText: figma,
        avatarImage: avatarImage,
      );
    case 'job-intake':
      return JobIntakeView(
        job: figma ? figmaJob() : productJobs.first,
        onStart: () {},
        onEditCustomer: () {},
        onEditVehicle: () {},
        onConsent: () {},
        onEquipment: () {},
        onProfile: () {},
        figmaText: figma,
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
        figmaText: figma,
        figmaPreview: figma,
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
        figmaText: figma,
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
        figmaText: figma,
        avatarImage: avatarImage,
        vehicleImage: vehicleImage,
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
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: theme,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: appChild ?? const SizedBox.shrink(),
    ),
    home: child,
  );
}

