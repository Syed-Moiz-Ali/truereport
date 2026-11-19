import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/technician_router.dart';

Session _session({required Role role}) => Session(
  accessToken: 'access',
  refreshToken: 'refresh',
  user: User(
    id: 'u1',
    email: 'user@example.com',
    displayName: 'User',
    platformAdmin: role == Role.platformAdmin,
    totpEnabled: false,
  ),
  memberships: role == Role.platformAdmin
      ? const []
      : [Membership(workshopId: 'w1', workshopName: 'Workshop', role: role)],
);

void main() {
  test('loading never redirects', () {
    expect(
      technicianRedirect(loading: true, session: null, location: '/jobs'),
      isNull,
    );
    expect(
      technicianRedirect(
        loading: true,
        session: _session(role: Role.technician),
        location: '/signin',
      ),
      isNull,
    );
  });

  test('signed out is sent to /signin', () {
    expect(
      technicianRedirect(loading: false, session: null, location: '/jobs'),
      '/signin',
    );
    expect(
      technicianRedirect(loading: false, session: null, location: '/signin'),
      isNull,
    );
  });

  test('a technician at /signin is sent to /jobs', () {
    final technician = _session(role: Role.technician);
    expect(
      technicianRedirect(
        loading: false,
        session: technician,
        location: '/signin',
      ),
      '/jobs',
    );
    expect(
      technicianRedirect(
        loading: false,
        session: technician,
        location: '/jobs',
      ),
      isNull,
    );
  });

  test('any other role is sent to /unauthorized', () {
    for (final role in const [Role.workshopAdmin, Role.platformAdmin]) {
      final session = _session(role: role);
      expect(
        technicianRedirect(
          loading: false,
          session: session,
          location: '/signin',
        ),
        '/unauthorized',
        reason: role.name,
      );
      expect(
        technicianRedirect(
          loading: false,
          session: session,
          location: '/unauthorized',
        ),
        isNull,
        reason: '${role.name} at /unauthorized',
      );
    }
  });
}
