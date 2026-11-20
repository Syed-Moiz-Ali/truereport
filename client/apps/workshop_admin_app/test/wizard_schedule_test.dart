import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_form_state.dart';

void main() {
  test('immediate job sends a null scheduledAt', () {
    final form = WizardFormState()
      ..templateVersionId = 'version-1'
      ..customerName.text = 'Demo Customer'
      ..customerPhone.text = '+971500000000'
      ..vehicleMake.text = 'Toyota'
      ..vehicleModel.text = 'Land Cruiser';

    final request = form.toRequest();
    expect(request.scheduledAt, isNull);
  });

  test('scheduled job sends the chosen wall time', () {
    final form = WizardFormState()
      ..templateVersionId = 'version-1'
      ..customerName.text = 'Demo Customer'
      ..customerPhone.text = '+971500000000'
      ..vehicleMake.text = 'Toyota'
      ..vehicleModel.text = 'Land Cruiser'
      ..scheduleAt(DateTime(2030, 1, 15, 9, 30));

    final request = form.toRequest();
    expect(request.scheduledAt, '2030-01-15T09:30:00');
  });

  test('start immediately clears an existing schedule', () {
    final form = WizardFormState()..scheduleAt(DateTime(2030, 1, 15, 9, 30));
    form.startImmediately();
    expect(form.scheduledAt, isNull);
  });
}
