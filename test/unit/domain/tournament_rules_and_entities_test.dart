import 'package:flutter_test/flutter_test.dart';
import 'package:vifutbol/domain/entities/championship_tournament.dart';
import 'package:vifutbol/domain/entities/rule_audit_entry.dart';
import 'package:vifutbol/domain/entities/tournament_draft.dart';
import 'package:vifutbol/domain/entities/tournament_enums.dart';
import 'package:vifutbol/domain/entities/tournament_rules_config.dart';
import 'package:vifutbol/domain/entities/tournaments_catalog_state.dart';
import 'package:vifutbol/domain/entities/ui_view_state.dart';

void main() {
  group('TournamentEnums & KnockoutStageConfig', () {
    test(
      'provides activeRoundsSequence from startingRound through finalMatch',
      () {
        const fromRoundOf16 = KnockoutStageConfig(
          startingRound: KnockoutRound.roundOf16,
        );
        expect(fromRoundOf16.activeRoundsSequence, <KnockoutRound>[
          KnockoutRound.roundOf16,
          KnockoutRound.quarterFinals,
          KnockoutRound.semiFinals,
          KnockoutRound.finalMatch,
        ]);
        expect(KnockoutRound.roundOf16.teamSlots, 16);
        expect(KnockoutRound.roundOf16.tieCount, 8);

        const fromSemi = KnockoutStageConfig(
          startingRound: KnockoutRound.semiFinals,
          twoLeggedTies: true,
          directPenaltyShootoutOnDraw: false,
        );
        expect(fromSemi.activeRoundsSequence, <KnockoutRound>[
          KnockoutRound.semiFinals,
          KnockoutRound.finalMatch,
        ]);

        final roundTrip = KnockoutStageConfig.fromJson(fromSemi.toJson());
        expect(roundTrip, fromSemi);
      },
    );

    test(
      'validates GroupStageConfig independent bounds (2..8 groups, 1..4 advancing)',
      () {
        const valid = GroupStageConfig(groupCount: 6, advancingPerGroup: 3);
        expect(valid.isValid, isTrue);
        expect(GroupStageConfig.fromJson(valid.toJson()), valid);

        const invalidGroups = GroupStageConfig(
          groupCount: 1,
          advancingPerGroup: 2,
        );
        expect(invalidGroups.isValid, isFalse);

        const invalidAdvancing = GroupStageConfig(
          groupCount: 4,
          advancingPerGroup: 5,
        );
        expect(invalidAdvancing.isValid, isFalse);
      },
    );

    test('checks TournamentFormat and TournamentStatus capabilities', () {
      expect(TournamentFormat.league.hasStandingsTable, isTrue);
      expect(TournamentFormat.league.hasKnockoutBracket, isFalse);
      expect(TournamentFormat.knockoutCup.hasKnockoutBracket, isTrue);
      expect(TournamentFormat.mixedGroupsAndKnockout.hasGroupStage, isTrue);

      expect(TournamentStatus.openRegistration.isEditable, isTrue);
      expect(
        TournamentStatus.openRegistration.requiresAuditForCriticalRules,
        isFalse,
      );
      expect(TournamentStatus.inProgress.requiresAuditForCriticalRules, isTrue);
      expect(TournamentStatus.finished.isEditable, isFalse);
    });
  });

  group('TournamentRulesConfig & ChampionshipTournament', () {
    test('enforces default official rules and validates invariants', () {
      const defaults = TournamentRulesConfig();
      expect(defaults.pointsForWin, 3);
      expect(defaults.pointsForDraw, 1);
      expect(defaults.pointsForLoss, 0);
      expect(defaults.hasValidPointsDistribution, isTrue);
      expect(defaults.hasValidTiebreakerOrder, isTrue);
      expect(defaults.hasValidYellowCardLimit, isTrue);
      expect(defaults.hasValidSquadSizeRange, isTrue);
      expect(defaults.hasValidHalfDuration, isTrue);
      expect(defaults.hasValidLeagueRounds, isTrue);

      final invalidPoints = defaults.copyWith(
        pointsForWin: 1,
        pointsForDraw: 2,
      );
      expect(invalidPoints.hasValidPointsDistribution, isFalse);

      final invalidSquad = defaults.copyWith(
        minPlayersPerTeam: 20,
        maxPlayersPerTeam: 15,
      );
      expect(invalidSquad.hasValidSquadSizeRange, isFalse);

      final roundTrip = TournamentRulesConfig.fromJson(defaults.toJson());
      expect(roundTrip, defaults);
    });

    test(
      'detects critical rule changes and serializes ChampionshipTournament with audit trail',
      () {
        final baseTournament = ChampionshipTournament(
          id: 't-1',
          name: 'Torneo Clausura ViFutbol 2026',
          category: 'Libre Masculino',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 8, 30),
          format: TournamentFormat.league,
          status: TournamentStatus.inProgress,
          rules: const TournamentRulesConfig(),
          auditTrail: <RuleAuditEntry>[
            RuleAuditEntry(
              recordedAt: DateTime(2026, 5, 10, 14, 30),
              summary: 'Puntos Victoria: 3 -> 2',
              reason: 'Resolución comité oficial',
            ),
          ],
          updatedAt: DateTime(2026, 5, 10, 14, 30),
        );

        final sameCritical = baseTournament.copyWith(
          rules: baseTournament.rules.copyWith(yellowCardSuspensionLimit: 5),
        );
        expect(baseTournament.hasCriticalRulesChanged(sameCritical), isFalse);

        final changedScoring = baseTournament.copyWith(
          rules: baseTournament.rules.copyWith(pointsForWin: 2),
        );
        expect(baseTournament.hasCriticalRulesChanged(changedScoring), isTrue);

        final changedFormat = baseTournament.copyWith(
          format: TournamentFormat.knockoutCup,
        );
        expect(baseTournament.hasCriticalRulesChanged(changedFormat), isTrue);

        final roundTrip = ChampionshipTournament.fromJson(
          baseTournament.toJson(),
        );
        expect(roundTrip, baseTournament);
      },
    );

    test('serializes TournamentDraft and filters TournamentsCatalogState', () {
      final draft = TournamentDraft(
        name: 'Borrador Copa',
        category: 'Sub-20',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 15),
        format: TournamentFormat.knockoutCup,
        savedAt: DateTime(2026, 5, 20),
      );
      expect(TournamentDraft.fromJson(draft.toJson()), draft);

      final league = ChampionshipTournament(
        id: 'league-1',
        name: 'Liga 2026',
        category: 'Libre',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 8, 1),
        format: TournamentFormat.league,
        updatedAt: DateTime(2026, 5, 1),
      );
      final cup = ChampionshipTournament(
        id: 'cup-1',
        name: 'Copa 2026',
        category: 'Libre',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 6, 1),
        format: TournamentFormat.knockoutCup,
        updatedAt: DateTime(2026, 5, 2),
      );

      final catalogState = TournamentsCatalogState(
        viewState: UiContentState<List<ChampionshipTournament>>(
          <ChampionshipTournament>[league, cup],
        ),
        tournaments: <ChampionshipTournament>[league, cup],
        selectedTournamentId: 'cup-1',
        savedDraft: draft,
      );

      expect(catalogState.hasSavedDraft, isTrue);
      expect(catalogState.selectedTournament, cup);

      final filteredOnlyLeague = catalogState.copyWith(
        selectedFormatFilter: TournamentFormat.league,
      );
      expect(filteredOnlyLeague.filteredTournaments, <ChampionshipTournament>[
        league,
      ]);
      expect(filteredOnlyLeague.selectedTournament, league);
    });
  });
}
