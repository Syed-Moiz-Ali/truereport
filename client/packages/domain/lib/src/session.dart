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
    if (memberships.isEmpty) {
      return Role.technician;
    }
    return memberships.first.role;
  }

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
