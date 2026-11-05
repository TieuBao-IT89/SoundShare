class AuthSession {
  const AuthSession({required this.subject, required this.name});
  final String subject;
  final String name;
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    subject: json['id'] as String,
    name: (json['name'] as String?) ?? 'Music lover',
  );
}
