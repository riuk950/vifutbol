/// The five official ecosystem roles of vifutbol championships.
enum UserRole {
  organizer,
  coach,
  referee,
  player,
  fan;

  /// Whether this role requires an official authorization code in Production environment.
  bool get requiresAuthorizationCodeInProd =>
      this == UserRole.organizer || this == UserRole.referee;
}
