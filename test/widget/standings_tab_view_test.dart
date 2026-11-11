import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/teams_controller.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/teams_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_teams_eligibility_use_case.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_teams_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/shell/tabs/standings_tab_view.dart';

class _MemoryStorage implements LocalStorageRepository {
  _MemoryStorage() {
    final tournaments = [
      ChampionshipTournament(
        id: 't-clausura-1',
        name: 'Liga Clausura ViFutbol 2026',
        category: 'Libre Masculino',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 12, 30),
        format: TournamentFormat.league,
        status: TournamentStatus.openRegistration,
        rules: const TournamentRulesConfig(),
        updatedAt: DateTime(2026, 4, 17),
      ),
      ChampionshipTournament(
        id: 't-copa-1',
        name: 'Copa Relámpago Nocturna',
        category: 'Libre Abierta',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 12, 30),
        format: TournamentFormat.knockoutCup,
        status: TournamentStatus.inProgress,
        rules: const TournamentRulesConfig(),
        updatedAt: DateTime(2026, 4, 17),
      ),
    ];
    _map[LocalTournamentsRepository.catalogStorageKey] = jsonEncode(
      tournaments.map((t) => t.toJson()).toList(),
    );
  }

  final Map<String, String> _map = <String, String>{};

  @override
  Future<LocalStorageStatus> initialize(String storagePrefix) async =>
      LocalStorageStatus(isPersistent: true, storageNamespace: storagePrefix);

  @override
  Future<String?> readString(String key) async => _map[key];

  @override
  Future<void> writeString(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> clearNamespace() async => _map.clear();

  @override
  bool get isUsingFallbackMemory => false;
}

void main() {
  Widget buildStandingsTestApp({required UserRole role}) {
    final devConfig = EnvironmentConfig.development();
    final storage = _MemoryStorage();
    final repo = LocalTournamentsRepository(
      storage: storage,
      config: devConfig,
    );
    final useCase = ManageTournamentsUseCase(repo);
    final teamsRepo = LocalTeamsRepository(storage: storage, config: devConfig);
    final teamsUseCase = ManageTeamsEligibilityUseCase(teamsRepo);

    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(devConfig),
        localStorageRepositoryProvider.overrideWithValue(storage),
        tournamentsRepositoryProvider.overrideWithValue(repo),
        manageTournamentsUseCaseProvider.overrideWithValue(useCase),
        teamsRepositoryProvider.overrideWithValue(teamsRepo),
        manageTeamsEligibilityUseCaseProvider.overrideWithValue(teamsUseCase),
        activeUserRoleProvider.overrideWithValue(role),
        activeRoleCapabilitiesProvider.overrideWithValue(
          RolePermissionMatrix.capabilitiesForRole(role),
        ),
        tournamentsControllerProvider.overrideWith(
          (ref) => TournamentsController(
            tournamentsRepository: repo,
            manageTournamentsUseCase: useCase,
          ),
        ),
        teamsControllerProvider.overrideWith(
          (ref) => TeamsController(
            teamsRepository: teamsRepo,
            manageTeamsEligibilityUseCase: teamsUseCase,
          ),
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
        home: const Scaffold(body: StandingsTabView()),
      ),
    );
  }

  group('StandingsTabView Widget Tests (US1 & US2)', () {
    testWidgets(
      'hides mutation controls for non-organizer roles while displaying official rules',
      (tester) async {
        await tester.pumpWidget(buildStandingsTestApp(role: UserRole.fan));
        await tester.pumpAndSettle();

        expect(find.text('Campeonatos y Reglas'), findsOneWidget);
        expect(find.text('Liga Clausura ViFutbol 2026'), findsWidgets);
        expect(find.text('Sistema de Puntuación'), findsOneWidget);
        expect(find.text('Criterios de Desempate en Tabla'), findsOneWidget);
        expect(find.byKey(const Key('create_tournament_button')), findsNothing);
        expect(
          find.byKey(const Key('edit_tournament_rules_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('start_tournament_status_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows Create, Edit, and Status Transition actions for Organizer and filters by format',
      (tester) async {
        await tester.pumpWidget(
          buildStandingsTestApp(role: UserRole.organizer),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('create_tournament_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('edit_tournament_rules_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('start_tournament_status_button')),
          findsOneWidget,
        );

        // Start tournament -> transitions to En Curso
        await tester.tap(
          find.byKey(const Key('start_tournament_status_button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('finish_tournament_status_button')),
          findsOneWidget,
        );

        // Filter by Knockout Cup
        await tester.tap(find.byKey(const Key('filter_format_knockoutCup')));
        await tester.pumpAndSettle();
        expect(find.text('Copa Relámpago Nocturna'), findsWidgets);
        expect(find.text('Estructura de Llaves Eliminatorias'), findsOneWidget);
      },
    );
  });
}
