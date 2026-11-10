# Research & Technical Decisions: Gestión Integral (CRUD) y Ciclo de Vida de Competiciones en Panel del Organizador (HU 16.1)

**Feature**: `028-organizer-competitions-crud`
**Date**: 2026-11-10

## 1. Context & Objectives

The goal is to provide tournament organizers with full CRUD and lifecycle management capabilities directly from the Organizer Panel (`OrganizerPanelContent`). Specifically:
1. **Filtering & Listing**: Display exclusively the championships created by or assigned to the current organizer (`organizerId == currentUserId`).
2. **Empty State & Creation**: When no tournaments exist for the organizer, display a KickPulse empty state with a call to create one. Provide a "Crear Competición" action.
3. **Editing Metadata**: Form/modal dialog to edit name, category, format, scoring system (points for win/draw/loss), and rules without corrupting existing fixtures or teams.
4. **Lifecycle State Machine**: Strict unidirectional progression `openRegistration` → `inProgress` → `finished`.
   - Transitioning `openRegistration` → `inProgress` requires:
     - At least 2 teams enrolled/active in the tournament.
     - Fixture generated (matches exist for this tournament in `matchesCatalogControllerProvider` or `TournamentMatchesRepository`).
   - Reverting to previous states is blocked to maintain historical integrity.
5. **Restricted Deletion**:
   - Deletion allowed **only** when `status == TournamentStatus.openRegistration` and no matches have been played or are in progress (`match.status != inProgress && match.status != completed`) and no digital match reports exist.
   - Deletion blocked if the tournament is `inProgress` or `finished`.
   - Requires explicit destructive confirmation dialog with KickPulse visual styling.

---

## 2. Research Questions & Decisions

### Decision 1: Entity Modification (`ChampionshipTournament.organizerId`)
- **Question**: How should tournaments be associated with an organizer?
- **Analysis**:
  - `ChampionshipTournament` in `lib/domain/entities/championship_tournament.dart` currently has: `id`, `name`, `category`, `startDate`, `endDate`, `format`, `status`, `teams`, `rules`, `scoringSystem`, `editionNumber`, `location`, `logoUrl`, `createdAt`, `updatedAt`.
  - It lacks an `organizerId` field.
- **Decision**:
  - Add optional `final String? organizerId` to `ChampionshipTournament`.
  - In `fromJson(Map<String, dynamic> json)`: `organizerId: json['organizerId'] as String? ?? 'org-seed-1'`. Defaulting to `'org-seed-1'` guarantees backward compatibility with existing stored JSON in development environments.
  - In `_buildSeedTournaments()` in `LocalTournamentsRepository`: set `organizerId: 'org-seed-1'`.
  - In `LocalAuthRepository` or active session fallback: when an organizer is authenticated or switching to `UserRole.organizer`, if session user ID is empty or default, match with `'org-seed-1'`.
  - Update `TournamentDraft` and tournament creation use case to persist `organizerId` from the active user's session.

### Decision 2: Reactive State & Filtering (`organizerTournamentsProvider`)
- **Question**: Where and how should organizer tournaments be queried and refreshed?
- **Analysis**:
  - `tournamentsControllerProvider` exposes `TournamentsState` with `tournaments` (`List<ChampionshipTournament>`).
  - `authControllerProvider` exposes `AuthFlowState` with `session?.user.id`.
- **Decision**:
  - Create a dedicated provider in `lib/application/providers/tournaments_providers.dart`:
    ```dart
    final organizerTournamentsProvider = Provider<List<ChampionshipTournament>>((ref) {
      final state = ref.watch(tournamentsControllerProvider);
      final authState = ref.watch(authControllerProvider);
      final currentUserId = authState.session?.user.id ?? 'org-seed-1';
      return state.tournaments.where((t) => (t.organizerId ?? 'org-seed-1') == currentUserId).toList();
    });
    ```
  - This guarantees reactive updates whenever a tournament is created, edited, transitioned, or deleted.

### Decision 3: Repository & Controller API Expansion (`deleteTournament` and `updateTournament`)
- **Question**: Does `TournamentsRepository` and `TournamentsController` support update and deletion?
- **Analysis**:
  - `TournamentsRepository.saveTournament` already behaves as an upsert (updates existing if id matches, inserts otherwise).
  - `TournamentsRepository` currently lacks `deleteTournament(String id)`.
  - `TournamentsController` has `createTournament`, `selectTournament`, etc., but needs explicit methods:
    - `Future<bool> updateTournament(ChampionshipTournament tournament)`
    - `Future<bool> deleteTournament(String tournamentId)`
    - `Future<bool> transitionTournamentStatus(String tournamentId, TournamentStatus newStatus)`
- **Decision**:
  - Add `Future<void> deleteTournament(String tournamentId);` to `TournamentsRepository`.
  - Implement in `LocalTournamentsRepository`: remove from list and persist to `storage`.
  - Add use cases or controller methods in `TournamentsController`:
    - `updateTournament(ChampionshipTournament tournament)`
    - `deleteTournament(String tournamentId)`
    - `transitionTournamentStatus(String tournamentId, TournamentStatus targetStatus)`

### Decision 4: Lifecycle Transition Safeguards (`openRegistration` → `inProgress` → `finished`)
- **Question**: What exact checks are required before allowing transition to `inProgress`?
- **Analysis**:
  - Requirement FR-009: Must have at least 2 teams registered, and fixture generated.
  - Matches can be queried from `matchesCatalogControllerProvider` or `TournamentMatchesRepository`.
  - If `teams.length < 2`, transition must fail with a localized explanatory message: e.g. "El torneo requiere al menos 2 equipos inscritos para iniciar."
  - If no matches exist for this `tournamentId`, transition must fail with: "Debes generar el calendario de partidos (fixture) antes de iniciar el campeonato."
  - Transition to `finished`: can be performed whenever the tournament is `inProgress`.
  - Reversion (e.g. `inProgress` -> `openRegistration`, `finished` -> anything) is strictly disallowed and hidden/disabled in UI.

### Decision 5: Restricted Deletion Verification
- **Question**: What exact conditions block deletion?
- **Analysis**:
  - If `tournament.status == TournamentStatus.inProgress || tournament.status == TournamentStatus.finished`: Deletion is prohibited.
  - If `tournament.status == TournamentStatus.openRegistration`:
    - Check if any matches associated with `tournament.id` have status `inProgress` or `completed`.
    - Check if any digital match reports exist for those matches.
    - If any match is played/active, deletion is blocked.
    - If only scheduled matches exist (or no matches), allow deletion, but clean up associated matches from matches repository to avoid orphan data.
  - Deletion prompt requires a KickPulse destructive dialog confirming the action.

### Decision 6: UI Presentation & Layout in Organizer Panel
- **Question**: How should this be presented in `OrganizerPanelContent`?
- **Analysis**:
  - `OrganizerPanelContent` currently displays Metric Cards and Quick Actions.
  - Add `OrganizerCompetitionsSection` with:
    - Header: "Mis Competiciones" with count badge.
    - Action button: "+ Nueva Competición" (opens existing tournament creation dialog or flow).
    - If empty: KickPulse card with `Icons.emoji_events_outlined`, text "No has creado ninguna competición aún", and button "Crear mi primera competición".
    - If populated: ListView / Column of `KickPulseCard` for each tournament showing:
      - Tournament Name (title)
      - Category & Format chip
      - Teams count (`${tournament.teams.length} equipos`)
      - KickPulseBadge for status (`openRegistration` -> warning/secondary, `inProgress` -> live/accentPrimary, `finished` -> neutral/surface)
      - PopupMenuButton or action buttons: "Editar", "Cambiar Estado", "Eliminar".
  - Ensure all texts use `AppLocalizations` (`l10n`).
  - Ensure minimum screen size 320x640 with 130% font scale has zero RenderFlex overflow.

---

## 3. Technology & Dependencies

- Flutter 3.x / Dart 3.x
- Riverpod (`flutter_riverpod`)
- Localization (`package:flutter_gen/gen_l10n/app_localizations.dart` and `lib/l10n/app_es.arb`)
- KickPulse Design System (`KickPulseColors`, `KickPulseTypography`, `KickPulseRadiiSpacing`, `KickPulseCard`, `KickPulseButton`, `KickPulseBadge`)
