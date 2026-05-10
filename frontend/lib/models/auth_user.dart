class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
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
