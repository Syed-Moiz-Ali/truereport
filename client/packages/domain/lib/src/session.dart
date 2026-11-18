import 'package:domain/src/membership.dart';
import 'package:domain/src/role.dart';
import 'package:domain/src/user.dart';

class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.memberships,
  });

  final String accessToken;
  final String refreshToken;
  final User user;
  final List<Membership> memberships;

  Role get role {
    if (user.platformAdmin) {
      return Role.platformAdmin;
    }
    // Highest privilege wins — never `memberships.first`. The API does not
    // promise an order, so a user who is a technician in one workshop and an
    // admin in another must still reach the admin surface.
    var best = Role.leastPrivilege;
    for (final membership in memberships) {
      if (_privilege(membership.role) > _privilege(best)) {
        best = membership.role;
      }
    }
    return best;
  }

  static int _privilege(Role role) => switch (role) {
    Role.platformAdmin => 3,
    Role.workshopAdmin => 2,
    Role.technician => 1,
  };

  String? get workshopId =>
      memberships.isEmpty ? null : memberships.first.workshopId;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    memberships: (json['memberships'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Membership.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}
