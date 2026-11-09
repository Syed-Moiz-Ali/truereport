import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/screens/f3a/job_detail_view.dart';
import 'package:admin_app/src/screens/f3b/staff_detail_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkshopJobDetailView renders all hero and telemetry blocks and triggers back', (tester) async {
    tester.view.physicalSize = const Size(1280, 1125);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var backPressed = false;
    const testJob = WorkshopJob(
      id: 'job-1',
      reference: 'JOB-2024-0891',
      status: 'IN_PROGRESS',
      templateVersionId: 'tmpl-100pt',
      templateName: '100-Point Standard Check v2.0',
      templateVersionNo: 2,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Marcus Vance',
      scheduledAt: '2026-11-09T09:30:00',
      customerName: 'Enterprise Holdings Fleet Operations',
      customerPhone: '+1 (555) 019-2834',
      customerEmail: 'fleet.dispatch@enterprise.corp',
      vehicleMake: 'Porsche',
      vehicleModel: '2024 Porsche 911 GT3 RS',
      vehicleYear: 2024,
      vehicleVin: 'WP0AB2A87LS290042',
      vehiclePlate: 'CA 8XYZ901',
      scope: 'Standard Fleet ANSI Tier-4 Pre-Delivery Audit',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WorkshopJobDetailView(
            job: testJob,
            onBack: () => backPressed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Hero
    expect(find.text('2024 Porsche 911 GT3 RS'), findsOneWidget);
    expect(find.text('Back to Live Queue'), findsOneWidget);
    expect(find.textContaining('WP0AB2A87LS290042'), findsOneWidget);
    expect(find.textContaining('CA 8XYZ901'), findsOneWidget);

    // Verify Vehicle Specs & Protocol
    expect(find.text('Vehicle Specifications'), findsOneWidget);
    expect(find.text('14,280 mi'), findsOneWidget);
    expect(find.text('Inspection Protocol & Progress'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);

    // Verify Assigned Tech
    expect(find.text('Assigned Bay'), findsOneWidget);
    expect(find.text('Marcus Vance'), findsWidgets);

    // Tap Back
    await tester.tap(find.text('Back to Live Queue'));
    await tester.pumpAndSettle();
    expect(backPressed, isTrue);
  });

  testWidgets('WorkshopStaffDetailView renders hero, metrics strip, certifications and triggers back', (tester) async {
    tester.view.physicalSize = const Size(1280, 1125);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var backPressed = false;
    const testStaff = StaffMember(
      userId: 'staff-0',
      displayName: 'David Vance',
      emailMasked: 'd.vance@apexfleet.io',
      role: 'Senior Technician \u2022 Bay 02',
      status: 'ACTIVE',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: WorkshopStaffDetailView(
            staff: testStaff,
            onBack: () => backPressed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Hero
    expect(find.text('David Vance'), findsOneWidget);
    expect(find.text('Back to Staff Management'), findsOneWidget);
    expect(find.text('ACTIVE ON SHIFT'), findsOneWidget);

    // Verify Metrics Strip
    expect(find.text('INSPECTIONS DONE'), findsOneWidget);
    expect(find.text('142'), findsOneWidget);
    expect(find.text('AVG TURNAROUND'), findsOneWidget);
    expect(find.text('38m'), findsOneWidget);

    // Verify Certifications
    expect(find.text('Certifications & Skills'), findsOneWidget);
    expect(find.text('EV Certified Level 4'), findsWidgets);

    // Tap Back
    await tester.tap(find.text('Back to Staff Management'));
    await tester.pumpAndSettle();
    expect(backPressed, isTrue);
  });
}
