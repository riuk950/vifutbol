import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';

void main() {
  group('UserAccount.isProfileCompleteForActiveRole', () {
    test('guest fan is always exempt (returns true)', () {
      final guest = UserAccount.guestFan(id: 'guest-1');
      expect(guest.isProfileCompleteForActiveRole, isTrue);
    });

    test(
        'player requires phone, documentId, and all mandatory HU 21.1 and HU 21.2 fields including front/back document URLs',
        () {
      final incomplete = UserAccount(
        id: 'u1',
        fullName: 'Carlos Ruiz',
        email: 'carlos@test.com',
        activeRole: UserRole.player,
        phone: '3001234567',
        documentId: '10203040',
      );
      // Fails because RoleProfileData is missing
      expect(incomplete.isProfileCompleteForActiveRole, isFalse);

      final partialProfile = incomplete.copyWith(
        roleProfile: RoleProfileData(
          firstName: 'Carlos',
          firstSurname: 'Ruiz',
          sex: 'male',
          birthDate: DateTime(1998, 5, 20),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          secondaryPositions: const [], // empty positions
        ),
      );
      expect(partialProfile.isProfileCompleteForActiveRole, isFalse);

      final missingImages = partialProfile.copyWith(
        roleProfile: partialProfile.roleProfile!.copyWith(
          secondaryPositions: ['LD', 'CAD'],
          primaryPosition: PlayerPosition.defender,
        ),
      );
      // Fails because front/back document URLs are missing
      expect(missingImages.isProfileCompleteForActiveRole, isFalse);

      final missingBackImage = missingImages.copyWith(
        roleProfile: missingImages.roleProfile!.copyWith(
          documentFrontUrl: 'path/to/front.jpg',
        ),
      );
      expect(missingBackImage.isProfileCompleteForActiveRole, isFalse);

      final complete = missingBackImage.copyWith(
        roleProfile: missingBackImage.roleProfile!.copyWith(
          documentBackUrl: 'path/to/back.jpg',
        ),
      );
      expect(complete.isProfileCompleteForActiveRole, isTrue);
    });

    test('referee requires phone and documentId', () {
      final incomplete = UserAccount(
        id: 'u2',
        fullName: 'Ana Referee',
        email: 'ana@test.com',
        activeRole: UserRole.referee,
        documentId: '9876543',
      );
      expect(incomplete.isProfileCompleteForActiveRole, isFalse);

      final complete = incomplete.copyWith(phone: '3109998877');
      expect(complete.isProfileCompleteForActiveRole, isTrue);
    });

    test('coach requires phone, documentId, clubName, and licenseLevel', () {
      final missingClub = UserAccount(
        id: 'u3',
        fullName: 'DT Luis',
        email: 'luis@test.com',
        activeRole: UserRole.coach,
        phone: '3001112233',
        documentId: '77665544',
        roleProfile: const RoleProfileData(licenseLevel: 'PRO'),
      );
      expect(missingClub.isProfileCompleteForActiveRole, isFalse);

      final complete = missingClub.copyWith(
        roleProfile: const RoleProfileData(
          clubName: 'Club Deportivo Norte',
          licenseLevel: 'PRO',
        ),
      );
      expect(complete.isProfileCompleteForActiveRole, isTrue);
    });

    test('organizer requires phone, documentId, organizationName, and baseCity',
        () {
      final incomplete = UserAccount(
        id: 'u4',
        fullName: 'Org Maria',
        email: 'maria@test.com',
        activeRole: UserRole.organizer,
        phone: '3012223344',
        documentId: '55443322',
        roleProfile: const RoleProfileData(organizationName: 'Liga Central'),
      );
      expect(incomplete.isProfileCompleteForActiveRole, isFalse);

      final complete = incomplete.copyWith(
        roleProfile: const RoleProfileData(
          organizationName: 'Liga Central',
          baseCity: 'Bogotá',
        ),
      );
      expect(complete.isProfileCompleteForActiveRole, isTrue);
    });

    test('authenticated fan requires phone and city, without documentId', () {
      final incomplete = UserAccount(
        id: 'u5',
        fullName: 'Fan Pedro',
        email: 'pedro@test.com',
        activeRole: UserRole.fan,
        phone: '3150001122',
      );
      expect(incomplete.isProfileCompleteForActiveRole, isFalse);

      final complete = incomplete.copyWith(
        roleProfile: const RoleProfileData(city: 'Medellín'),
      );
      expect(complete.isProfileCompleteForActiveRole, isTrue);
    });

    test('toJson / fromJson round-trip preserves phone, documentId, roleProfile',
        () {
      final original = UserAccount(
        id: 'u6',
        fullName: 'Coach Roundtrip',
        email: 'coach@test.com',
        activeRole: UserRole.coach,
        authorizedRoles: {UserRole.coach, UserRole.fan},
        onboardingCompleted: true,
        phone: '3201234567',
        documentId: '12345678',
        roleProfile: const RoleProfileData(
          clubName: 'Academia Sur',
          licenseLevel: 'A',
          linkedPlayerId: 'p-1',
        ),
      );

      final restored = UserAccount.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.phone, '3201234567');
      expect(restored.documentId, '12345678');
      expect(restored.roleProfile?.clubName, 'Academia Sur');
      expect(restored.roleProfile?.linkedPlayerId, 'p-1');
    });

    test('toJson / fromJson preserves all HU 21.1 player fields', () {
      final birth = DateTime(1995, 10, 15);
      final playerAccount = UserAccount(
        id: 'u-player',
        fullName: 'Mateo Andrés Gómez Ruiz',
        email: 'mateo@test.com',
        activeRole: UserRole.player,
        authorizedRoles: {UserRole.player, UserRole.fan},
        onboardingCompleted: true,
        phone: '3009876543',
        documentId: '1098765432',
        roleProfile: RoleProfileData(
          firstName: 'Mateo',
          secondName: 'Andrés',
          firstSurname: 'Gómez',
          secondSurname: 'Ruiz',
          sex: 'male',
          birthDate: birth,
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          primaryPosition: PlayerPosition.defender,
          secondaryPositions: const ['DFC', 'LD'],
          linkedPlayerId: 'player-uuid-123',
          documentFrontUrl: 'https://storage/front.jpg',
          documentBackUrl: 'https://storage/back.jpg',
        ),
      );

      final json = playerAccount.toJson();
      final restored = UserAccount.fromJson(json);

      expect(restored.roleProfile?.firstName, 'Mateo');
      expect(restored.roleProfile?.secondName, 'Andrés');
      expect(restored.roleProfile?.firstSurname, 'Gómez');
      expect(restored.roleProfile?.secondSurname, 'Ruiz');
      expect(restored.roleProfile?.sex, 'male');
      expect(restored.roleProfile?.birthDate, equals(birth));
      expect(restored.roleProfile?.bloodType, 'O+');
      expect(restored.roleProfile?.department, 'Antioquia');
      expect(restored.roleProfile?.municipality, 'Medellín');
      expect(restored.roleProfile?.primaryPosition, PlayerPosition.defender);
      expect(restored.roleProfile?.secondaryPositions, equals(['DFC', 'LD']));
      expect(restored.roleProfile?.documentFrontUrl, 'https://storage/front.jpg');
      expect(restored.roleProfile?.documentBackUrl, 'https://storage/back.jpg');
      expect(restored.isProfileCompleteForActiveRole, isTrue);
    });
  });
}
