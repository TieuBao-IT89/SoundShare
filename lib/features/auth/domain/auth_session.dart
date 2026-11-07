class AuthSession {
  const AuthSession({
    required this.subject,
    required this.name,
    this.sessionId,
  });
  final String subject;
  final String name;
  final String? sessionId;
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    subject: json['id'] as String,
    name: (json['name'] as String?) ?? 'Người yêu nhạc',
    sessionId: json['sessionId'] as String?,
  );
}
