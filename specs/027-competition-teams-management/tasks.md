# Tasks: Gestión de Equipos Inscritos en Competición (Opción en FAB Menu, Pestaña de Equipos, Retiro y Traslado de Grupo) (HU 15.4)

**Input**: Design documents from `/specs/027-competition-teams-management/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-competition-teams-contracts.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Spanish localization keys and code generation required across all stories.

- [X] T001 Define the 21 Spanish localization keys (`competitionDetailTabTeams`, `competitionFabAddTeamLabel`, `competitionTeamsEmptyTitle`, `competitionTeamsEmptyDescription`, `competitionTeamsHeaderCount`, `competitionTeamPlayersCount`, `competitionTeamMoveGroupTooltip`, `competitionTeamRemoveTooltip`, `competitionMoveGroupDialogTitle`, `competitionMoveGroupSuccess`, `competitionRemoveTeamConfirmTitle`, `competitionRemoveTeamConfirmMessage`, `competitionRemoveTeamConfirmAction`, `competitionRemoveTeamSuccess`, `competitionRemoveTeamHasPlayedMatchesError`, `competitionEnrollTeamDialogTitle`, `competitionEnrollTeamExistingClubLabel`, `competitionEnrollTeamNewClubOption`, `competitionEnrollTeamGroupLabel`, `competitionEnrollTeamSubmitAction`, `competitionEnrollTeamSuccess`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate localization classes with `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain entity extensions, repository contracts, and standings calculation logic that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Extend `TournamentTeam` in `lib/domain/entities/tournament_team.dart` with optional `final String? groupName`, updating constructor, `copyWith`, `toJson` (`'groupName': groupName`), and `fromJson` (`groupName: json['groupName'] as String?`) preserving backward compatibility
- [X] T004 [P] Add `Future<void> deleteTeam(String teamId);` to `TeamsRepository` in `lib/domain/repositories/teams_repository.dart` and implement it in `LocalTeamsRepository` in `lib/infrastructure/repositories/local_teams_repository.dart`
- [X] T005 [P] Update `StandingsCalculatorService` in `lib/domain/services/standings_calculator_service.dart` to respect explicit `team.groupName` matching valid tournament groups in `calculateGroupStageTables`, falling back to deterministic modular distribution for teams with null/invalid groups, and expose helper `resolveEffectiveGroupName`
- [X] T006 [P] Add unit tests in `test/unit/domain/standings_calculator_service_test.dart` verifying group table calculation with explicit `groupName` assignments and fallback deterministic distribution

**Checkpoint**: Foundation ready — domain models, repository contracts, and standings group services are ready for user stories.

---

## Phase 3: User Story 1 - Inscripción de Equipos al Campeonato desde el FAB Menu de la Competición (Priority: P1) 🎯 MVP

**Goal**: Enable the Organizer to open an enrollment dialog from the FAB Speed Dial Menu in `CompetitionDetailScreen` (`/competitions/:id`) to register a new club or copy an existing club into the competition, optionally assigning an initial group for `mixedGroupsAndKnockout` tournaments with automatic balancing.

**Independent Test**: Log in as Organizer, open `/competitions/:id` for an editable tournament, expand the FAB Menu, tap `"Agregar Equipo"` (`Key('competition_detail_fab_add_team')`), submit a valid team name and short code in `CompetitionEnrollTeamDialog`, and verify the team is enrolled in `tournamentId` and a confirmation SnackBar appears.

### Implementation for User Story 1

- [X] T007 [US1] Add `enrollTeamInCompetition` use case method in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` and action in `lib/application/controllers/teams_controller.dart` validating `RoleCapability.manageTournaments`, `tournament.status.isEditable`, name length ($\ge 3$), unique normalized name in tournament, shortCode ($2\text{–}4$ chars), with single-flight protection
- [X] T008 [P] [US1] Create `CompetitionEnrollTeamDialog` in `lib/presentation/tournaments/widgets/competition_enroll_team_dialog.dart` (`Key('competition_enroll_team_dialog')`) with optional existing club pre-fill dropdown (`Key('enroll_team_existing_club_dropdown')`), name field (`Key('enroll_team_name_field')`), short code field (`Key('enroll_team_short_code_field')`), group dropdown (`Key('enroll_team_group_dropdown')`) auto-selecting the group with fewest teams when `mixedGroupsAndKnockout`, and submit button (`Key('enroll_team_submit_button')`)
- [X] T009 [US1] Extend `_buildFloatingActionButton` in `lib/presentation/tournaments/competition_detail_screen.dart` to render `FloatingActionButton.extended` for `"Agregar Equipo"` (`Key('competition_detail_fab_add_team')`, icon `Icons.group_add`) when `_isSpeedDialOpen == true`, invoking `CompetitionEnrollTeamDialog.show(context, tournament: tournament)`
- [X] T010 [P] [US1] Add unit tests in `test/unit/application/manage_teams_eligibility_use_case_test.dart` and `test/unit/application/teams_controller_test.dart` verifying `enrollTeamInCompetition` validations (role permissions, editable status, name uniqueness, short code format, and single-flight lock)
- [X] T011 [P] [US1] Add widget tests in `test/presentation/tournaments/competition_detail_screen_test.dart` verifying `"Agregar Equipo"` FAB action visibility for Organizer, opening `CompetitionEnrollTeamDialog`, form validation, and successful team enrollment

**Checkpoint**: User Story 1 is functional and independently testable as an MVP increment.

---

## Phase 4: User Story 2 - Pestaña de Equipos Inscritos en el Detalle de la Competición (Priority: P1)

**Goal**: Display a dedicated 4th tab `"Equipos"` in `CompetitionDetailScreen` (`/competitions/:id`) listing all enrolled clubs for the competition, showing crest, name, short code, player count, eligibility badge, and group sections (for `mixedGroupsAndKnockout`) or alphabetical order (for leagues/cups), with empty state and navigation to `/teams/:id`.

**Independent Test**: Open `/competitions/:id` as any role, select the `"Equipos"` tab (`Key('competition_detail_tab_teams')`), verify the enrolled teams are rendered in group sections (if tournament has groups) or list, tapping a team card navigates to `/teams/:id`, and an empty state is shown if no teams are enrolled.

### Implementation for User Story 2

- [X] T012 [US2] Create `CompetitionTeamsTabView` in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart` (`Key('competition_teams_tab_view')`) watching `teamsControllerProvider`, rendering empty state (`Key('competition_teams_empty_state')`) when no teams exist, section headers per group (`Key('competition_team_group_header_${groupName}')`) for `mixedGroupsAndKnockout`, team cards (`Key('competition_team_card_${team.id}')`) with crest, short code, players count, eligibility badge, group badge (`Key('competition_team_group_badge_${team.id}')`), and card tap navigation to `/teams/:id`
- [X] T013 [US2] Update `CompetitionDetailScreen` in `lib/presentation/tournaments/competition_detail_screen.dart` to use `DefaultTabController(length: 4)` with tabs: *Partidos* (`competition_detail_tab_matches`), *Clasificación* (`competition_detail_tab_standings`), *Equipos* (`competition_detail_tab_teams`, label `l10n.competitionDetailTabTeams`), and *Información* (`competition_detail_tab_info`), embedding `CompetitionTeamsTabView(tournamentId: widget.tournamentId)` into `TabBarView`
- [X] T014 [P] [US2] Add widget tests in `test/presentation/tournaments/competition_teams_tab_view_test.dart` verifying `CompetitionTeamsTabView` renders enrolled teams, group section headers in `mixedGroupsAndKnockout`, simple list in league/cup, empty state, and team detail navigation

**Checkpoint**: User Stories 1 and 2 work independently and together.

---

## Phase 5: User Story 3 - Retiro de Equipos del Campeonato y Traslado entre Grupos por el Organizador (Priority: P2)

**Goal**: Empower the Organizer to move an enrolled team to another group in `mixedGroupsAndKnockout` tournaments (immediately updating both Teams tab and Standings tab group tables) and remove an enrolled team from the competition (validating that the team has no `inProgress` or `completed` matches, and cleaning up pending matches), keeping administrative controls hidden for non-organizers and finished tournaments.

**Independent Test**: As Organizer in an editable `mixedGroupsAndKnockout` tournament, tap `"Trasladar de Grupo"` on a team in *Grupo A* and select *Grupo B*, verifying the group updates in Teams and Standings tabs; tap `"Quitar del campeonato"`, confirm in the dialog, and verify the team is removed; verify a team with played matches cannot be removed; verify non-organizers cannot see administrative buttons.

### Implementation for User Story 3

- [X] T015 [US3] Add `moveTeamToGroup` and `removeTeamFromCompetition` methods in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` and `lib/application/controllers/teams_controller.dart` checking `RoleCapability.manageTournaments`, `tournament.status.isEditable`, blocking team removal if team has matches with `MatchStatus.inProgress` or `MatchStatus.completed`, deleting pending matches from matches repository when team removal succeeds, and executing with single-flight protection
- [X] T016 [US3] Add group move action (`Key('competition_team_move_group_${team.id}')`), group selection dialog (`Key('competition_move_group_dialog')`, options `Key('competition_move_group_option_${groupName}')`), team removal action (`Key('competition_team_remove_${team.id}')`), and safety confirmation dialog (`Key('competition_remove_team_confirm_dialog')`, confirm button `Key('competition_remove_team_confirm_button')`) in `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart`, conditional on Organizer role and editable tournament status
- [X] T017 [P] [US3] Add unit tests in `test/unit/application/manage_teams_eligibility_use_case_test.dart` and `test/unit/application/teams_controller_test.dart` for `moveTeamToGroup` and `removeTeamFromCompetition` (verifying role authorization, successful group update, successful removal without played matches, and blocked removal with played matches)
- [X] T018 [P] [US3] Add widget tests in `test/presentation/tournaments/competition_teams_tab_view_test.dart` verifying group move dialog and reactivity, team removal confirmation flow, played matches alert, and administrative button visibility restricted to Organizer on editable tournaments

**Checkpoint**: All user stories (US1, US2, US3) are complete and independently tested.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Compact viewport responsiveness ($320\times 640\text{ px}$ @ $130\%$ text scaling) and full quality gate verification.

- [X] T019 [P] Add compact viewport ($320\times 640\text{ px}$) with $130\%$ text scaling tests in `test/presentation/tournaments/competition_teams_tab_view_test.dart` and `test/presentation/directories_responsive_widget_test.dart` verifying zero `RenderFlex` overflows in `CompetitionDetailScreen` across all 4 tabs and in `CompetitionEnrollTeamDialog`
- [X] T020 Execute `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, and the full feature test suite per `specs/027-competition-teams-management/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup (`T001`–`T002`)**: No dependencies — start immediately.
- **Phase 2: Foundational (`T003`–`T006`)**: Depends on Phase 1 completion — blocks all user stories.
- **Phase 3: User Story 1 (`T007`–`T011`)**: Depends on Phase 2 completion (MVP!).
- **Phase 4: User Story 2 (`T012`–`T014`)**: Depends on Phase 2 completion; can run in parallel with US1 or sequentially.
- **Phase 5: User Story 3 (`T015`–`T018`)**: Depends on Phase 3 and Phase 4 completion (operates on enrolled teams in `CompetitionTeamsTabView`).
- **Phase 6: Polish (`T019`–`T020`)**: Depends on all user stories (US1–US3) being completed.

---

## Parallel Example: User Story 1

```bash
# Launch use case & controller logic and dialog widget in parallel:
Task: "Add enrollTeamInCompetition in lib/application/use_cases/manage_teams_eligibility_use_case.dart and lib/application/controllers/teams_controller.dart"
Task: "Create CompetitionEnrollTeamDialog in lib/presentation/tournaments/widgets/competition_enroll_team_dialog.dart"

# Once complete, wire to FAB menu:
Task: "Extend _buildFloatingActionButton in lib/presentation/tournaments/competition_detail_screen.dart"

# Run tests in parallel:
Task: "Add unit tests in test/unit/application/manage_teams_eligibility_use_case_test.dart"
Task: "Add widget tests in test/presentation/tournaments/competition_detail_screen_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`).
2. Complete Phase 2: Foundational (`T003`–`T006`).
3. Complete Phase 3: User Story 1 (`T007`–`T011`).
4. **Validate MVP**: Inscribe a team from the FAB Menu and verify it saves with its group.

### Incremental Delivery

1. Setup + Foundational (`T001`–`T006`) → Foundation ready.
2. User Story 1 (`T007`–`T011`) → FAB enrollment ready (MVP!).
3. User Story 2 (`T012`–`T014`) → 4th tab `"Equipos"` visible and interactive for all roles.
4. User Story 3 (`T015`–`T018`) → Group move and safe team removal enabled for Organizer.
5. Polish (`T019`–`T020`) → Responsive $320\times 640$ @ $130\%$ verification, `flutter analyze`, and `dart format`.
