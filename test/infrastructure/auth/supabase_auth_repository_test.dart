import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/role_profile_data.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/failures/app_failure.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/auth/supabase_auth_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockProfileDataSource extends Mock
    implements SupabaseUserProfileDataSource {}

class _MockStorage extends Mock implements LocalStorageRepository {}

class _MockConnectivity extends Mock implements ConnectivityRepository {}

class _MockEnvironmentConfig extends Mock implements EnvironmentConfig {}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient goTrue;
  late _MockProfileDataSource dataSource;
  late _MockStorage storage;
  late _MockConnectivity connectivity;
  late _MockEnvironmentConfig config;
  late SupabaseAuthRepository repository;

  final session = Session(
    accessToken: 'token-123',
    tokenType: 'bearer',
    user: User(
      id: 'auth-1',
      appMetadata: const {},
      userMetadata: const {'full_name': 'Carlos Ruiz'},
      aud: 'authenticated',
      email: 'carlos@test.com',
      createdAt: '2026-11-13T00:00:00Z',
    ),
  );

  setUp(() {
    client = _MockSupabaseClient();
    goTrue = _MockGoTrueClient();
    dataSource = _MockProfileDataSource();
    storage = _MockStorage();
    connectivity = _MockConnectivity();
    config = _MockEnvironmentConfig();

    when(() => client.auth).thenReturn(goTrue);
    when(() => goTrue.currentSession).thenReturn(session);
    when(() => storage.writeString(any(), any())).thenAnswer((_) async {});
    when(() => storage.readString(any())).thenAnswer((_) async => null);
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => NetworkConnectionStatus.connected);
    when(() => config.environment).thenReturn(AppEnvironment.development);
    when(() => config.supabase).thenReturn(
      const SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon',
        schema: 'vifutboldev',
      ),
    );

    repository = SupabaseAuthRepository(
      client: client,
      storage: storage,
      connectivity: connectivity,
      config: config,
      profileDataSource: dataSource,
    );
  });

  group('SupabaseAuthRepository role persistence & profile completion', () {
    test('completeRoleOnboarding invokes atomic completeRoleProfile RPC',
        () async {
      when(() => dataSource.fetchByAuthUserId('auth-1')).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'Carlos Ruiz',
          'email': 'carlos@test.com',
          'active_role': 'fan',
          'authorized_roles': ['fan'],
          'is_guest_fan': false,
          'onboarding_completed': false,
        },
      );
      when(
        () => dataSource.fetchRoleProfileDetails('auth-1'),
      ).thenAnswer((_) async => null);
      when(
        () => dataSource.completeRoleProfile(
          activeRole: 'player',
          authorizedRoles: any(named: 'authorizedRoles'),
          onboardingCompleted: true,
          fullName: 'Carlos Ruiz',
          phone: null,
          documentId: null,
          roleProfile: null,
        ),
      ).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'Carlos Ruiz',
          'email': 'carlos@test.com',
          'active_role': 'player',
          'authorized_roles': ['fan', 'player'],
          'is_guest_fan': false,
          'onboarding_completed': true,
        },
      );

      final account = await repository.completeRoleOnboarding(
        userId: 'auth-1',
        selectedRole: UserRole.player,
      );

      expect(account.activeRole, UserRole.player);
      expect(account.authorizedRoles, contains(UserRole.player));
      expect(account.onboardingCompleted, isTrue);
    });

    test(
        'updateRoleProfile forwards fullName, phone/documentId and all player fields',
        () async {
      when(() => dataSource.fetchByAuthUserId('auth-1')).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'Carlos Ruiz',
          'email': 'carlos@test.com',
          'active_role': 'player',
          'authorized_roles': ['fan', 'player'],
          'is_guest_fan': false,
          'onboarding_completed': true,
        },
      );
      when(
        () => dataSource.fetchRoleProfileDetails('auth-1'),
      ).thenAnswer((_) async => null);
      when(
        () => dataSource.completeRoleProfile(
          activeRole: 'player',
          authorizedRoles: any(named: 'authorizedRoles'),
          onboardingCompleted: true,
          fullName: 'Carlos Andrés Ruiz Pérez',
          phone: '3001234567',
          documentId: '10203040',
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'Carlos Andrés Ruiz Pérez',
          'email': 'carlos@test.com',
          'active_role': 'player',
          'authorized_roles': ['fan', 'player'],
          'is_guest_fan': false,
          'onboarding_completed': true,
          'phone': '3001234567',
          'document_id': '10203040',
          'role_profile': {
            'linked_player_id': 'player-existing-1',
            'first_name': 'Carlos',
            'second_name': 'Andrés',
            'first_surname': 'Ruiz',
            'second_surname': 'Pérez',
            'sex': 'male',
            'birth_date': '1998-05-20',
            'blood_type': 'O+',
            'department': 'Antioquia',
            'municipality': 'Medellín',
            'primary_position': 'defender',
            'secondary_positions': ['LD', 'CAD'],
            'document_front_url': 'players/auth-1/front.jpg',
            'document_back_url': 'players/auth-1/back.jpg',
            'photo_url': 'players/auth-1/avatar.jpg',
          },
        },
      );

      final updated = await repository.updateRoleProfile(
        userId: 'auth-1',
        role: UserRole.player,
        fullName: 'Carlos Andrés Ruiz Pérez',
        phone: '3001234567',
        documentId: '10203040',
        roleProfile: RoleProfileData(
          firstName: 'Carlos',
          secondName: 'Andrés',
          firstSurname: 'Ruiz',
          secondSurname: 'Pérez',
          sex: 'male',
          birthDate: DateTime(1998, 5, 20),
          bloodType: 'O+',
          department: 'Antioquia',
          municipality: 'Medellín',
          primaryPosition: PlayerPosition.defender,
          secondaryPositions: const ['LD', 'CAD'],
          documentFrontUrl: 'players/auth-1/front.jpg',
          documentBackUrl: 'players/auth-1/back.jpg',
          photoUrl: 'players/auth-1/avatar.jpg',
        ),
      );

      expect(updated.fullName, 'Carlos Andrés Ruiz Pérez');
      expect(updated.phone, '3001234567');
      expect(updated.documentId, '10203040');
      expect(updated.roleProfile?.linkedPlayerId, 'player-existing-1');
      expect(updated.roleProfile?.firstName, 'Carlos');
      expect(updated.roleProfile?.municipality, 'Medellín');
      expect(updated.roleProfile?.secondaryPositions, equals(['LD', 'CAD']));
      expect(updated.roleProfile?.documentFrontUrl, 'players/auth-1/front.jpg');
      expect(updated.roleProfile?.documentBackUrl, 'players/auth-1/back.jpg');
      expect(updated.isProfileCompleteForActiveRole, isTrue);
    });

    test('updateRoleProfile maps DOCUMENT_ALREADY_LINKED to DocumentAlreadyLinkedFailure',
        () async {
      when(() => dataSource.fetchByAuthUserId('auth-1')).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'Carlos Ruiz',
          'email': 'carlos@test.com',
          'active_role': 'player',
          'authorized_roles': ['fan', 'player'],
          'is_guest_fan': false,
          'onboarding_completed': true,
        },
      );
      when(
        () => dataSource.fetchRoleProfileDetails('auth-1'),
      ).thenAnswer((_) async => null);
      when(
        () => dataSource.completeRoleProfile(
          activeRole: any(named: 'activeRole'),
          authorizedRoles: any(named: 'authorizedRoles'),
          onboardingCompleted: any(named: 'onboardingCompleted'),
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          documentId: any(named: 'documentId'),
          roleProfile: any(named: 'roleProfile'),
        ),
      ).thenThrow(
        const PostgrestException(message: 'DOCUMENT_ALREADY_LINKED', code: 'P0001'),
      );

      await expectLater(
        repository.updateRoleProfile(
          userId: 'auth-1',
          role: UserRole.player,
          phone: '3001234567',
          documentId: '10203040',
        ),
        throwsA(isA<DocumentAlreadyLinkedFailure>()),
      );
    });

    test('updateRoleProfile fails fast when offline', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => NetworkConnectionStatus.disconnected);

      await expectLater(
        repository.updateRoleProfile(
          userId: 'auth-1',
          role: UserRole.player,
          phone: '3001234567',
          documentId: '10203040',
        ),
        throwsA(isA<OfflineAuthOperationFailure>()),
      );
    });

    test('hydrates coach satellite profile via fetchRoleProfileDetails',
        () async {
      when(() => dataSource.fetchByAuthUserId('auth-1')).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'DT Luis',
          'email': 'luis@test.com',
          'active_role': 'coach',
          'authorized_roles': ['fan', 'coach'],
          'is_guest_fan': false,
          'onboarding_completed': true,
          'phone': '3001112233',
          'document_id': '77665544',
        },
      );
      when(() => dataSource.fetchRoleProfileDetails('auth-1')).thenAnswer(
        (_) async => {
          'club_name': 'Club Norte',
          'license_level': 'PRO',
        },
      );

      final restored = await repository.restoreSession();

      expect(restored?.user.roleProfile?.clubName, 'Club Norte');
      expect(restored?.user.roleProfile?.licenseLevel, 'PRO');
      expect(restored?.user.isProfileCompleteForActiveRole, isTrue);
    });

    test('hydrates player document URLs via fetchRoleProfileDetails', () async {
      when(() => dataSource.fetchByAuthUserId('auth-1')).thenAnswer(
        (_) async => {
          'id': 'auth-1',
          'auth_user_id': 'auth-1',
          'full_name': 'Carlos Ruiz',
          'email': 'carlos@test.com',
          'active_role': 'player',
          'authorized_roles': ['fan', 'player'],
          'is_guest_fan': false,
          'onboarding_completed': true,
          'phone': '3001234567',
          'document_id': '10203040',
        },
      );
      when(() => dataSource.fetchRoleProfileDetails('auth-1')).thenAnswer(
        (_) async => {
          'first_name': 'Carlos',
          'first_surname': 'Ruiz',
          'sex': 'male',
          'birth_date': '1998-05-20',
          'blood_type': 'O+',
          'department': 'Antioquia',
          'municipality': 'Medellín',
          'secondary_positions': ['LD'],
          'document_front_url': 'auth-1/document_front.jpg',
          'document_back_url': 'auth-1/document_back.jpg',
          'photo_url': 'auth-1/avatar.jpg',
        },
      );

      final restored = await repository.restoreSession();

      expect(restored?.user.roleProfile?.documentFrontUrl,
          'auth-1/document_front.jpg');
      expect(restored?.user.roleProfile?.documentBackUrl,
          'auth-1/document_back.jpg');
      expect(restored?.user.isProfileCompleteForActiveRole, isTrue);
    });
  });
}
