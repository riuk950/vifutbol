import 'package:vifutbol/domain/entities/user_role.dart';

/// User account representation within vifutbol championships.
class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final UserRole activeRole;
  final Set<UserRole> authorizedRoles;
  final bool isGuestFan;
  final bool onboardingCompleted;

  UserAccount({
    required this.id,
    required this.fullName,
    required String email,
    required this.activeRole,
    Set<UserRole>? authorizedRoles,
    this.isGuestFan = false,
    this.onboardingCompleted = false,
  }) : email = email.trim().toLowerCase(),
       authorizedRoles = {...?authorizedRoles, activeRole, UserRole.fan};

  /// Factory for creating an anonymous guest fan session.
  factory UserAccount.guestFan({required String id}) {
    return UserAccount(
      id: id,
      fullName: 'Aficionado Invitado',
      email: '',
      activeRole: UserRole.fan,
      authorizedRoles: {UserRole.fan},
      isGuestFan: true,
      onboardingCompleted: true,
    );
  }

  UserAccount copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? activeRole,
    Set<UserRole>? authorizedRoles,
    bool? isGuestFan,
    bool? onboardingCompleted,
  }) {
    return UserAccount(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      activeRole: activeRole ?? this.activeRole,
      authorizedRoles: authorizedRoles ?? this.authorizedRoles,
      isGuestFan: isGuestFan ?? this.isGuestFan,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'activeRole': activeRole.name,
      'authorizedRoles': authorizedRoles.map((r) => r.name).toList(),
      'isGuestFan': isGuestFan,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final activeRole = UserRole.values.byName(json['activeRole'] as String);
    final rawRoles = json['authorizedRoles'] as List<dynamic>? ?? [];
    final authorizedRoles = rawRoles
        .map((r) => UserRole.values.byName(r as String))
        .toSet();

    return UserAccount(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      activeRole: activeRole,
      authorizedRoles: authorizedRoles,
      isGuestFan: json['isGuestFan'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activeRole == other.activeRole &&
          onboardingCompleted == other.onboardingCompleted;

  @override
  int get hashCode => Object.hash(id, activeRole, onboardingCompleted);

  @override
  String toString() =>
      'UserAccount(id: $id, fullName: $fullName, email: $email, activeRole: ${activeRole.name}, isGuest: $isGuestFan)';
}
