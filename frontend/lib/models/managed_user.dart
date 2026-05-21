class ManagedUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'] as String),
    );
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'kierownik':
        return 'Kierownik';
      case 'pracownik':
        return 'Pracownik';
      default:
        return role;
    }
  }
}
