import 'package:vifutbol/domain/entities/role_profile_data.dart';
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
  final String? phone;
  final String? documentId;
  final RoleProfileData? roleProfile;

  /// Convenience getter for player or account photo avatar URL.
  String? get photoUrl => roleProfile?.photoUrl;

  UserAccount({
    required this.id,
    required this.fullName,
    required String email,
    required this.activeRole,
    Set<UserRole>? authorizedRoles,
    this.isGuestFan = false,
    this.onboardingCompleted = false,
    this.phone,
    this.documentId,
    this.roleProfile,
  }) : email = email.trim().toLowerCase(),
       authorizedRoles = {...?authorizedRoles, activeRole, UserRole.fan};

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  /// Evaluates whether the account has all mandatory profile data for its
  /// [activeRole]. Guest fan sessions are always treated as exempt.
  bool get isProfileCompleteForActiveRole {
    if (isGuestFan) return true;
    final hasPhone = _hasText(phone);
    final hasDoc = _hasText(documentId);

    switch (activeRole) {
      case UserRole.player:
        return hasPhone &&
            hasDoc &&
            _hasText(roleProfile?.firstName) &&
            _hasText(roleProfile?.firstSurname) &&
            _hasText(roleProfile?.sex) &&
            roleProfile?.birthDate != null &&
            _hasText(roleProfile?.bloodType) &&
            _hasText(roleProfile?.department) &&
            _hasText(roleProfile?.municipality) &&
            (roleProfile?.secondaryPositions.isNotEmpty ?? false) &&
            _hasText(roleProfile?.documentFrontUrl) &&
            _hasText(roleProfile?.documentBackUrl) &&
            _hasText(roleProfile?.photoUrl);
      case UserRole.referee:
        return hasPhone && hasDoc;
      case UserRole.coach:
        return hasPhone &&
            hasDoc &&
            _hasText(roleProfile?.clubName) &&
            _hasText(roleProfile?.licenseLevel);
      case UserRole.organizer:
        return hasPhone &&
            hasDoc &&
            _hasText(roleProfile?.organizationName) &&
            _hasText(roleProfile?.baseCity);
      case UserRole.fan:
        return hasPhone && _hasText(roleProfile?.city);
    }
  }

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
    String? phone,
    String? documentId,
    RoleProfileData? roleProfile,
  }) {
    return UserAccount(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      activeRole: activeRole ?? this.activeRole,
      authorizedRoles: authorizedRoles ?? this.authorizedRoles,
      isGuestFan: isGuestFan ?? this.isGuestFan,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      phone: phone ?? this.phone,
      documentId: documentId ?? this.documentId,
      roleProfile: roleProfile ?? this.roleProfile,
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
      if (phone != null) 'phone': phone,
      if (documentId != null) 'documentId': documentId,
      if (roleProfile != null) 'roleProfile': roleProfile!.toJson(),
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final activeRole = UserRole.values.byName(json['activeRole'] as String);
    final rawRoles = json['authorizedRoles'] as List<dynamic>? ?? [];
    final authorizedRoles = rawRoles
        .map((r) => UserRole.values.byName(r as String))
        .toSet();
    final rawRoleProfile = json['roleProfile'];

    return UserAccount(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      activeRole: activeRole,
      authorizedRoles: authorizedRoles,
      isGuestFan: json['isGuestFan'] as bool? ?? false,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      phone: json['phone'] as String?,
      documentId: json['documentId'] as String?,
      roleProfile: rawRoleProfile is Map<String, dynamic>
          ? RoleProfileData.fromJson(rawRoleProfile)
          : (rawRoleProfile is Map
                ? RoleProfileData.fromJson(
                    Map<String, dynamic>.from(rawRoleProfile),
                  )
                : null),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activeRole == other.activeRole &&
          onboardingCompleted == other.onboardingCompleted &&
          phone == other.phone &&
          documentId == other.documentId &&
          roleProfile == other.roleProfile;

  @override
  int get hashCode => Object.hash(
        id,
        activeRole,
        onboardingCompleted,
        phone,
        documentId,
        roleProfile,
      );

  @override
  String toString() =>
      'UserAccount(id: $id, fullName: $fullName, email: $email, activeRole: ${activeRole.name}, isGuest: $isGuestFan)';
}
