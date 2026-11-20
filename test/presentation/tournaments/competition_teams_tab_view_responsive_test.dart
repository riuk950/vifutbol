import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/connectivity_status.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/team_enums.dart';
import 'package:vifutbol/domain/entities/teams_catalog_state.dart';
import 'package:vifutbol/domain/entities/tournament_team.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/connectivity_repository.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/widgets/competition_teams_tab_view.dart';

import '../../test_helpers/teams_eligibility_test_helper.dart';

class _FakeLocalStorageRepository implements LocalStorageRepository {
  @override
  bool get isUsingFallbackMemory => false;
  @override
  Future<void> clearNamespace() async {}
  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);
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

class _FakeTournamentsController extends StateNotifier<TournamentsCatalogState>
    implements TournamentsController {
  _FakeTournamentsController(ChampionshipTournament tournament)
    : super(
        TournamentsCatalogState(
          viewState: UiSuccessState<List<ChampionshipTournament>>([tournament]),
          tournaments: [tournament],
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTeamsController extends StateNotifier<TeamsCatalogState>
    implements TeamsController {
  _FakeTeamsController(List<TournamentTeam> teams)
    : super(TeamsCatalogState(teams: teams));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CompetitionTeamsTabView Responsive Tests (HU 16.3 / Polish)', () {
    testWidgets(
      'renders cleanly on 320x640 with 130% text scaling without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final tournament = createTestTournament(minPlayers: 11);
        final teamIncomplete = createTestTeam(
          id: 'team-inc',
          tournamentId: tournament.id,
          name: 'Club Atlético Defensores del Rosario',
          shortCode: 'CADR',
          playerCount: 8,
          status: TeamEligibilityStatus.pendingVerification,
        );
        final teamEligible = createTestTeam(
          id: 'team-eli',
          tournamentId: tournament.id,
          name: 'Sociedad Deportiva Universitaria de Viña',
          shortCode: 'SDUV',
          playerCount: 14,
          status: TeamEligibilityStatus.eligible,
        );

        await tester.pumpWidget(
          ProviderScope(
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
              tournamentsControllerProvider.overrideWith(
                (ref) => _FakeTournamentsController(tournament),
              ),
              teamsControllerProvider.overrideWith(
                (ref) => _FakeTeamsController([teamIncomplete, teamEligible]),
              ),
              activeUserRoleProvider.overrideWithValue(UserRole.organizer),
            ],
            child: MaterialApp(
              theme: KickPulseTheme.darkTheme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('es'),
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.3),
                  size: Size(320, 640),
                ),
                child: Scaffold(
                  body: CompetitionTeamsTabView(tournamentId: tournament.id),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(Key('competition_team_card_${teamIncomplete.id}')),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('competition_team_card_${teamEligible.id}')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            Key('competition_team_action_approve_${teamIncomplete.id}'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('competition_team_action_revoke_${teamEligible.id}')),
          findsOneWidget,
        );
      },
    );
  });
}
