import 'package:vifutbol/domain/entities/user_account.dart';

/// Persistent session representation stored locally in isolated namespace.
class AuthSession {
  final String sessionId;
  final UserAccount user;
  final String sessionToken;
  final DateTime authenticatedAt;

  const AuthSession({
    required this.sessionId,
    required this.user,
    required this.sessionToken,
    required this.authenticatedAt,
  });

  /// Whether this session belongs to an anonymous guest fan.
  bool get isGuestFan => user.isGuestFan;

  AuthSession copyWith({
    String? sessionId,
    UserAccount? user,
    String? sessionToken,
    DateTime? authenticatedAt,
  }) {
    return AuthSession(
      sessionId: sessionId ?? this.sessionId,
      user: user ?? this.user,
      sessionToken: sessionToken ?? this.sessionToken,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'user': user.toJson(),
      'sessionToken': sessionToken,
      'authenticatedAt': authenticatedAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      sessionId: json['sessionId'] as String,
      user: UserAccount.fromJson(json['user'] as Map<String, dynamic>),
      sessionToken: json['sessionToken'] as String,
      authenticatedAt: DateTime.parse(json['authenticatedAt'] as String),
    );
  }

  /// Safe diagnostic representation with credentials redacted (FR-010).
  Map<String, dynamic> toSafeDiagnosticMap() {
    return {
      'sessionId': sessionId,
      'user': user.toJson(),
      'sessionToken': '[REDACTED]',
      'authenticatedAt': authenticatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AuthSession(sessionId: $sessionId, user: ${user.fullName}, '
        'activeRole: ${user.activeRole.name}, sessionToken: [REDACTED], '
        'authenticatedAt: $authenticatedAt)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          user == other.user;

  @override
  int get hashCode => Object.hash(sessionId, user);
}
