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

  bool get isAdmin => this == Role.workshopAdmin || this == Role.platformAdmin;
}
