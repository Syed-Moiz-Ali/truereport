enum Role {
  technician('TECHNICIAN'),
  workshopAdmin('WORKSHOP_ADMIN'),
  platformAdmin('PLATFORM_ADMIN');

  const Role(this.apiValue);

  final String apiValue;

  static Role? fromApi(String? value) {
    for (final role in Role.values) {
      if (role.apiValue == value) {
        return role;
      }
    }
    return null;
  }

  /// Deliberate least-privilege answer for an unrecognised API role.
  ///
  /// A role string this client does not know must never grant access, and it
  /// must never crash a sign-in either (that would lock out every user of a
  /// newer server build). So it degrades to the weakest role, and the routing
  /// test in `test/signin_behaviour_fixes_test.dart` pins that outcome.
  static const Role leastPrivilege = Role.technician;

  bool get isAdmin => this == Role.workshopAdmin || this == Role.platformAdmin;
}
