import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/domain/repositories/teams_repository.dart';
import 'package:vifutbol/domain/repositories/tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/directories/teams_directory_screen.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String prefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: prefix);
  @override
  Future<String?> readString(String key) async => null;
  @override
  Future<void> writeString(String key, String value) async {}
}

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Stream<NetworkConnectionStatus> get onConnectivityChanged =>
      Stream.value(NetworkConnectionStatus.connected);
  @override
  Future<NetworkConnectionStatus> checkConnectivity() async =>
      NetworkConnectionStatus.connected;
}

class _FakeTeamsRepository implements TeamsRepository {
  _FakeTeamsRepository(this.teams);
  final List<TournamentTeam> teams;
  @override
  Future<List<TournamentTeam>> loadTeams() async => teams;
  @override
  Future<List<TournamentTeam>> loadTeamsForTournament(String tournamentId) async =>
      teams.where((t) => t.tournamentId == tournamentId).toList();
  @override
  Future<TournamentTeam> saveTeam(TournamentTeam team) async => team;
  @override
  Future<void> deleteTeam(String teamId) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTournamentsRepository implements TournamentsRepository {
  _FakeTournamentsRepository(this.tournaments);
  final List<ChampionshipTournament> tournaments;
  @override
  Future<List<ChampionshipTournament>> loadTournaments() async => tournaments;
  @override
  Future<ChampionshipTournament> saveTournament(ChampionshipTournament t) async => t;
  @override
  Future<void> deleteTournament(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final tournament = ChampionshipTournament(
    id: 't-1',
    name: 'Copa Viña',
    category: 'Libre',
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2026, 11, 30),
    format: TournamentFormat.league,
    status: TournamentStatus.openRegistration,
    updatedAt: DateTime(2026, 3, 1),
  );

  final team = TournamentTeam(
    id: 'team-1',
    tournamentId: 't-1',
    name: 'Everton',
    shortCode: 'EVE',
  );

  Widget createTestApp(UserRole role) {
    return ProviderScope(
      key: ValueKey(role),
      overrides: [
        environmentConfigProvider.overrideWithValue(
          EnvironmentConfig.development(),
        ),
        localStorageRepositoryProvider.overrideWithValue(
          _FakeLocalStorageRepository(),
        ),
        connectivityRepositoryProvider.overrideWithValue(
          _FakeConnectivityRepository(),
        ),
        teamsRepositoryProvider.overrideWithValue(
          _FakeTeamsRepository([team]),
        ),
        tournamentsRepositoryProvider.overrideWithValue(
          _FakeTournamentsRepository([tournament]),
        ),
        activeUserRoleProvider.overrideWith((ref) => role),
        activeRoleCapabilitiesProvider.overrideWithValue(
          RolePermissionMatrix.capabilitiesForRole(role),
        ),
      ],
      child: MaterialApp(
        theme: KickPulseTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const TeamsDirectoryScreen(),
      ),
    );
  }

  group('TeamsDirectoryScreen Role Visibility Tests (US2)', () {
    testWidgets(
      'create_team_from_directory_button is visible ONLY for UserRole.coach and hidden for organizer, referee, player, fan',
      (tester) async {
        for (final role in UserRole.values) {
          await tester.pumpWidget(createTestApp(role));
          await tester.pumpAndSettle();

          final buttonFinder = find.byKey(
            const Key('create_team_from_directory_button'),
          );

          if (role == UserRole.coach) {
            expect(
              buttonFinder,
              findsOneWidget,
              reason: 'Coach must see create_team_from_directory_button',
            );
          } else {
            expect(
              buttonFinder,
              findsNothing,
              reason: '${role.name} must NOT see create_team_from_directory_button',
            );
          }
        }
      },
    );
  });
}
