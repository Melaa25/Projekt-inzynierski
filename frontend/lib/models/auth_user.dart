class AuthUser {
  final int id;
  final String name;
  final String login;
  final String email;
  final String role;
  final bool mustChangePassword;

  const AuthUser({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.role,
    required this.mustChangePassword,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      login: json['login'] as String? ?? '',
      email: json['email'] as String,
      role: json['role'] as String,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
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
