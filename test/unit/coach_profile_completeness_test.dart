import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';

void main() {
  RoleProfileData buildCompleteCoachProfile({
    DateTime? birthDate,
    String? secondName = 'Andrés',
    String? secondSurname = 'Gómez',
    String? clubName = 'Atlético Real',
    String? licenseLevel = 'Licencia B',
    String? documentFrontUrl = 'coach/front.jpg',
    String? documentBackUrl = 'coach/back.jpg',
  }) {
    return RoleProfileData(
      firstName: 'Carlos',
      secondName: secondName,
      firstSurname: 'Martínez',
      secondSurname: secondSurname,
      sex: 'M',
      birthDate: birthDate ?? DateTime(1990, 5, 14),
      bloodType: 'O+',
      department: 'Antioquia',
      municipality: 'Medellín',
      clubName: clubName,
      licenseLevel: licenseLevel,
      documentFrontUrl: documentFrontUrl,
      documentBackUrl: documentBackUrl,
    );
  }

  UserAccount buildCoachAccount({
    String? phone = '3001234567',
    String? documentId = '1020304050',
    RoleProfileData? roleProfile,
  }) {
    return UserAccount(
      id: 'coach-1',
      fullName: 'Carlos Martínez',
      email: 'coach@vifutbol.com',
      activeRole: UserRole.coach,
      phone: phone,
      documentId: documentId,
      roleProfile: roleProfile,
    );
  }

  group('UserAccount.isProfileCompleteForActiveRole (UserRole.coach)', () {
    test('returns true when all 13 required fields and photos are present', () {
      final account = buildCoachAccount(roleProfile: buildCompleteCoachProfile());
      expect(account.isProfileCompleteForActiveRole, isTrue);
    });

    test('returns true when optional secondName and secondSurname are omitted', () {
      final account = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(
          secondName: null,
          secondSurname: '',
        ),
      );
      expect(account.isProfileCompleteForActiveRole, isTrue);
    });

    test('returns true for Independent club and Sin licencia values', () {
      final account = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(
          clubName: 'Independiente',
          licenseLevel: 'Sin licencia',
        ),
      );
      expect(account.isProfileCompleteForActiveRole, isTrue);
    });

    test('returns false for legacy partial coach with only club and license', () {
      final account = buildCoachAccount(
        roleProfile: const RoleProfileData(
          clubName: 'Club Deportivo',
          licenseLevel: 'Licencia C',
        ),
      );
      expect(account.isProfileCompleteForActiveRole, isFalse);
    });

    test('returns false when coach is under 18 years old', () {
      final now = DateTime.now();
      final minorBirthDate = DateTime(now.year - 17, now.month, now.day);
      final account = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(birthDate: minorBirthDate),
      );
      expect(account.isProfileCompleteForActiveRole, isFalse);
    });

    test('returns false when front or back ID document URL is missing', () {
      final missingFront = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(documentFrontUrl: ''),
      );
      final missingBack = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(documentBackUrl: null),
      );
      expect(missingFront.isProfileCompleteForActiveRole, isFalse);
      expect(missingBack.isProfileCompleteForActiveRole, isFalse);
    });

    test('returns false when clubName or licenseLevel is blank', () {
      final missingClub = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(clubName: '   '),
      );
      final missingLicense = buildCoachAccount(
        roleProfile: buildCompleteCoachProfile(licenseLevel: null),
      );
      expect(missingClub.isProfileCompleteForActiveRole, isFalse);
      expect(missingLicense.isProfileCompleteForActiveRole, isFalse);
    });
  });

  group('RoleProfileData coach JSON roundtrip', () {
    test('serializes and deserializes coach identity, location, technical and ID fields', () {
      final original = buildCompleteCoachProfile();
      final roundtrip = RoleProfileData.fromJson(original.toJson());
      expect(roundtrip, equals(original));
    });
  });
}
