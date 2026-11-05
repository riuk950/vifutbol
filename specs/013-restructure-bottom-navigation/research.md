# Phase 0 Research: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)

**Feature**: `013-restructure-bottom-navigation` (HU 10.1)  
**Date**: 2026-11-05

## 1. Bottom Navigation Bar Restructuring & Role Consistency

- **Decision**: Update `AppShellSection` in `lib/domain/entities/app_shell_section.dart` to represent the four primary navigation destinations (`matches`, `explore`, `news`, `profile`, while providing static aliases `matchday` and `standings` if needed for route compatibility) and configure `AppShellScreen` (`lib/presentation/shell/app_shell_screen.dart`) to render an `IndexedStack` with `[MatchdayTabView, StandingsTabView, NewsTabView, ProfileTabView]` and a 4-item Material 3 `NavigationBar` for all 5 roles (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador`, `Aficionado`).
- **Rationale**:
  - `IndexedStack` guarantees in-memory state preservation (`< 100ms` tab switching, preserving scroll offsets and active filter chips across tab switches and app background/foreground lifecycle transitions), fulfilling `FR-008` and `SC-003`.
  - Removing `VenuesTabView` from `AppShellScreen` while retaining `lib/presentation/shell/tabs/venues_tab_view.dart` and the venues domain/application/infrastructure layers intact ensures zero regressions in match scheduling (`ScheduleMatchDialog`) and prepares for secondary access in HU 10.2 (Drawer).
- **Alternatives Considered**:
  - *Dynamic destination list per role*: Rejected because `FR-001` and `SC-001` explicitly mandate the exact same 4 destinations (`Partidos`, `Explorar`, `Noticias`, `Perfil`) across all 5 user roles.
  - *PageView without IndexedStack*: Rejected because `IndexedStack` already exists in `AppShellScreen` and deterministically preserves subtree state without swipe conflicts against horizontal filter chip lists.

## 2. Calendar Date Filtering & Unscheduled Matches in "Partidos"

- **Decision**:
  - Remove the internal `SegmentedButton` (`matchday_segmented_button`) from `MatchdayTabView`.
  - Extend `MatchesCatalogState` and `MatchesCatalogController` with calendar-day selection (`selectedDate`, `availableCalendarDates`, `scheduledMatchesForSelectedDate`, `unscheduledMatches`, and `selectDate(DateTime)`).
  - Render a horizontal calendar date selector (`matchday_date_chips_list`) in `MatchdayTabView` offering `Hoy`, `Mañana`, and specific calendar dates that have scheduled matches (`scheduledStartTime != null`).
  - Highlight `MatchStatus.inProgress` matches in the top `"EN VIVO"` section (`live_matches_section`).
  - Filter the main daily match list exclusively by the selected calendar date (`scheduledStartTime != null` on the selected year/month/day), hiding unscheduled matches (`scheduledStartTime == null`) from the calendar list.
  - Render an exclusive `"Por programar (N)"` section (`unscheduled_matches_section`) in `MatchdayTabView` **only** when the active user role has `RoleCapability.manageTournaments` (`Organizador`) and `unscheduledMatches.isNotEmpty`. When the organizer schedules a match via `ScheduleMatchDialog`, update `selectedDate` to the newly assigned calendar date so the match immediately appears under its scheduled calendar day.
- **Rationale**:
  - Directly satisfies Clarifications Q1 (Option C) and Q2 (Option A) as well as `FR-004`.
  - Preserves existing round-based properties (`selectedRound`, `availableRounds`, `filteredMatches`) on `MatchesCatalogState` so existing domain/unit tests remain backward-compatible while adding full calendar-day filtering semantics.
- **Alternatives Considered**:
  - *Mixing unscheduled matches into every calendar day for all roles*: Rejected in Clarification Q1 (Option C) because fans, players, referees, and coaches should only see matches scheduled for the selected calendar date.
  - *Moving unscheduled match scheduling out of "Partidos" into "Explorar"*: Rejected in Clarification Q2 (Option A) to keep all match scheduling workflows centralized in `"Partidos"` for the `Organizador`.

## 3. Standalone "Noticias" Tab & Global Tournament Context Synchronization

- **Decision**:
  - Create `NewsTabView` in `lib/presentation/shell/tabs/news_tab_view.dart` as the third destination of `AppShellScreen`.
  - Synchronize the active tournament across `"Partidos"` (`MatchdayTabView`), `"Explorar"` (`StandingsTabView`), and `"Noticias"` (`NewsTabView`) using `tournamentsControllerProvider` (`selectedTournamentId` / `selectedTournament`).
  - Display a tournament selector in `"Partidos"` and `"Noticias"` when multiple tournaments exist (and always display the active tournament name), invoking `tournamentsControllerProvider.notifier.selectTournament(tournamentId)` on selection change.
  - When `selectedTournamentId` changes in `tournamentsControllerProvider`, `MatchdayTabView` automatically reloads matches for the newly selected tournament, and `NewsTabView` passes the active `tournamentId` and `isHistoricalReadOnly: currentTournament.status == TournamentStatus.finished` to `TournamentNewsFeedView`.
- **Rationale**:
  - Directly satisfies Clarification Q3 (Option A), `FR-006`, and `Edge Cases` regarding global tournament synchronization and historical read-only mode in finished tournaments.
  - Reuses `TournamentNewsFeedView` and `TournamentNewsController` without duplicating news domain/application logic.
- **Alternatives Considered**:
  - *Independent local `_selectedTournamentId` per tab*: Rejected in Clarification Q3 (Option A) because users expect a unified active championship context when switching between `"Partidos"`, `"Explorar"`, and `"Noticias"`.

## 4. Localization (`l10n`) & Layout Adaptation (320px @ 130% Text Scale)

- **Decision**:
  - Update `lib/l10n/app_es.arb` and generated localization classes (`app_localizations.dart`, `app_localizations_es.dart`) so that:
    - `tabMatchday` / `tabMatches` -> `"Partidos"`
    - `tabStandings` / `tabExplore` -> `"Explorar"`
    - `tabNews` -> `"Noticias"`
    - `tabProfile` -> `"Perfil"`
    - Calendar date labels (`matchdayDateToday` -> `"Hoy"`, `matchdayDateTomorrow` -> `"Mañana"`, `matchdayUnscheduledSectionTitle` -> `"Por programar ({count})"`, `matchdayNoMatchesForDate` -> `"No hay partidos programados para esta fecha."`).
  - Use `Flexible` / `Expanded` with `TextOverflow.ellipsis` in header rows and horizontal `SingleChildScrollView` for date chips and category filter chips so `320x640` viewports at `130%` text scale render with zero `RenderFlex` overflows (`SC-004`).
- **Rationale**:
  - Strictly enforces Constitution Principle VI (Language & Naming Conventions: 100% Spanish UI via `l10n`, 100% English technical identifiers) and Principle VII (`docs/MOBILE_GUIDELINES.md`).
- **Alternatives Considered**:
  - *Hardcoding Spanish labels in widgets*: Prohibited by Constitution Principle VI.
