import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/user_account.dart';
import 'package:vifutbol/domain/entities/user_role.dart';

void main() {
  group('UserAccount.isProfileCompleteForActiveRole', () {
    test('guest fan is always exempt (returns true)', () {
      final guest = UserAccount.guestFan(id: 'guest-1');
      expect(guest.isProfileCompleteForActiveRole, isTrue);
    });

    test('player requires phone and documentId', () {
      final incomplete = UserAccount(
        id: 'u1',
        fullName: 'Carlos Ruiz',
        email: 'carlos@test.com',
        activeRole: UserRole.player,
        phone: '3001234567',
      );
      expect(incomplete.isProfileCompleteForActiveRole, isFalse);

      final complete = incomplete.copyWith(documentId: '10203040');
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
  });
}
