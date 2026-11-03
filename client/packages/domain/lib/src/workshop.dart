class Workshop {
  const Workshop({
    required this.id,
    required this.name,
    required this.status,
    required this.memberCount,
  });

  final String id;
  final String name;
  final String status;
  final int memberCount;

  factory Workshop.fromJson(Map<String, dynamic> json) => Workshop(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        memberCount: json['memberCount'] as int? ?? 0,
      );
}
