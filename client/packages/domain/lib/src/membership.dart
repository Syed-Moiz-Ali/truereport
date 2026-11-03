import 'package:domain/src/role.dart';

class Membership {
  const Membership({
    required this.workshopId,
    required this.workshopName,
    required this.role,
  });

  final String workshopId;
  final String workshopName;
  final Role role;

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        workshopId: json['workshopId'] as String,
        workshopName: json['workshopName'] as String,
        role: Role.fromApi(json['role'] as String?) ?? Role.technician,
      );
}
