class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.platformAdmin,
    required this.totpEnabled,
  });

  final String id;
  final String email;
  final String displayName;
  final bool platformAdmin;
  final bool totpEnabled;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        platformAdmin: json['platformAdmin'] as bool? ?? false,
        totpEnabled: json['totpEnabled'] as bool? ?? false,
      );
}
