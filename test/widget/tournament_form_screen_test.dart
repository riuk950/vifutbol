import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/application/controllers/tournaments_controller.dart';
import 'package:vifutbol/application/providers/auth_providers.dart';
import 'package:vifutbol/application/providers/foundation_providers.dart';
import 'package:vifutbol/application/providers/tournaments_providers.dart';
import 'package:vifutbol/application/use_cases/manage_tournaments_use_case.dart';
import 'package:vifutbol/domain/entities/app_environment.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/local_storage_status.dart';
import 'package:vifutbol/domain/entities/role_permission_matrix.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/user_role.dart';
import 'package:vifutbol/domain/repositories/local_storage_repository.dart';
import 'package:vifutbol/infrastructure/repositories/local_tournaments_repository.dart';
import 'package:vifutbol/l10n/app_localizations.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_theme.dart';
import 'package:vifutbol/presentation/tournaments/tournament_form_screen.dart';

class _TestStorage implements LocalStorageRepository {
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
  late LocalTournamentsRepository repository;
  late ManageTournamentsUseCase useCase;
  late TournamentsController controller;

  setUp(() {
    repository = LocalTournamentsRepository(
      storage: _TestStorage(),
      config: EnvironmentConfig.production(),
    );
    useCase = ManageTournamentsUseCase(repository);
    controller = TournamentsController(
      tournamentsRepository: repository,
      manageTournamentsUseCase: useCase,
    );
  });

  Widget buildFormHarness({ChampionshipTournament? initialTournament}) {
    return ProviderScope(
      overrides: [
        environmentConfigProvider.overrideWithValue(
          EnvironmentConfig.production(),
        ),
        localStorageRepositoryProvider.overrideWithValue(_TestStorage()),
        tournamentsRepositoryProvider.overrideWithValue(repository),
        manageTournamentsUseCaseProvider.overrideWithValue(useCase),
        activeUserRoleProvider.overrideWithValue(UserRole.organizer),
        activeRoleCapabilitiesProvider.overrideWithValue(
          RolePermissionMatrix.capabilitiesForRole(UserRole.organizer),
        ),
        tournamentsControllerProvider.overrideWith((_) => controller),
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
        home: TournamentFormScreen(
          key: UniqueKey(),
          initialTournament: initialTournament,
        ),
      ),
    );
  }

  group('TournamentFormScreen Widget Tests (US1, US2 & US3)', () {
    testWidgets('creates a Knockout Cup with direct penalties and persists it', (
      tester,
    ) async {
      await tester.pumpWidget(buildFormHarness());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('tournament_name_input')),
        'Copa ViFutbol Campeones',
      );
      await tester.tap(find.byKey(const Key('format_chip_knockoutCup')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Desempate directo por penales al finalizar el tiempo reglamentario',
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('save_tournament_submit_button')),
      );
      await tester.tap(find.byKey(const Key('save_tournament_submit_button')));
      await tester.pumpAndSettle();

      expect(controller.state.tournaments.length, 1);
      expect(
        controller.state.tournaments.single.format,
        TournamentFormat.knockoutCup,
      );
      expect(
        controller.state.tournaments.single.status,
        TournamentStatus.openRegistration,
      );
    });

    testWidgets(
      'requires administrative audit reason when editing critical rules of an inProgress tournament',
      (tester) async {
        final inProgressTournament = ChampionshipTournament(
          id: 't-in-progress',
          name: 'Liga En Disputa 2026',
          category: 'Libre',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 8, 1),
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          updatedAt: DateTime(2026, 5, 2),
        );
        await repository.saveTournament(inProgressTournament);
        await controller.loadCatalog();

        await tester.pumpWidget(
          buildFormHarness(initialTournament: inProgressTournament),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('critical_rule_lock_banner')),
          findsOneWidget,
        );

        // Change pointsForWin from 3 to 2
        await tester.enterText(find.byKey(const Key('points_win_input')), '2');
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('save_tournament_submit_button')),
        );
        await tester.tap(
          find.byKey(const Key('save_tournament_submit_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // Administrative confirmation dialog appears
        expect(
          find.text('Confirmación Administrativa y Recálculo Auditado'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('audit_reason_input')),
          'Ajuste aprobado por junta directiva',
        );
        await tester.tap(
          find.byKey(const Key('confirm_audit_override_button')),
        );
        await tester.pumpAndSettle();

        expect(controller.state.tournaments.single.rules.pointsForWin, 2);
        expect(
          controller.state.tournaments.single.auditTrail.single.reason,
          'Ajuste aprobado por junta directiva',
        );
      },
    );

    testWidgets(
      'shows exit confirmation dialog on unsaved changes and saves/restores local draft',
      (tester) async {
        await tester.pumpWidget(buildFormHarness());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('tournament_name_input')),
          'Torneo Borrador Móvil',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('tournament_form_back_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('¿Deseas descartar los cambios o guardar como borrador?'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('save_tournament_draft_button')));
        await tester.pumpAndSettle();

        expect(controller.state.hasSavedDraft, isTrue);
        expect(controller.state.savedDraft?.name, 'Torneo Borrador Móvil');

        // Reopen form and verify restored draft banner
        await tester.pumpWidget(buildFormHarness());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('restored_draft_banner')), findsOneWidget);
        expect(find.text('Torneo Borrador Móvil'), findsOneWidget);
      },
    );
  });
}
