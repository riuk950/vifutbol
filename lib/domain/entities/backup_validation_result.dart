import 'package:vifutbol/domain/entities/tournament_backup_package.dart';

/// Immutable evaluation result of a tournament backup payload inspection.
class BackupValidationResult {
  const BackupValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.package,
  });

  const BackupValidationResult.valid(TournamentBackupPackage package)
    : this._(isValid: true, package: package);

  const BackupValidationResult.invalid(String errorMessage)
    : this._(isValid: false, errorMessage: errorMessage);

  final bool isValid;
  final String? errorMessage;
  final TournamentBackupPackage? package;
}
