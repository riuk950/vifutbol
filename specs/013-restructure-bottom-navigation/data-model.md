# Data Model: Reestructuración del Navigation Bar Inferior (Partidos por Fecha, Explorar, Noticias y Perfil)

**Feature**: `013-restructure-bottom-navigation` (HU 10.1)  
**Date**: 2026-11-05

## 1. Domain Entities & Value Objects

### 1.1 `AppShellSection` (`lib/domain/entities/app_shell_section.dart`)

Represents the 4 top-level destinations of the bottom `NavigationBar` in exact fixed order across all 5 user roles (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador`, `Aficionado`).

| Value | Index | Spanish UI Label (`l10n`) | Outlined Icon | Selected Icon | Description |
|---|---|---|---|---|---|
| `matches` (alias `matchday`) | `0` | `"Partidos"` | `Icons.sports_soccer_outlined` | `Icons.sports_soccer` | Live matches (`"EN VIVO"`), calendar date selector (`Hoy`, `Mañana`, specific dates), and Organizer-only `"Por programar (N)"` section. |
| `explore` (alias `standings`) | `1` | `"Explorar"` | `Icons.explore_outlined` | `Icons.explore` | Championship catalog, rules, standings tables, knockout brackets, season honor roll, teams, and sports rankings. |
| `news` | `2` | `"Noticias"` | `Icons.newspaper_outlined` | `Icons.newspaper` | Standalone tournament news & official announcements feed with category filters (`Todos`, `General`, `Reprogramación`, `Disciplinario`). |
| `profile` | `3` | `"Perfil"` | `Icons.person_outline` | `Icons.person` | User profile, active role switcher, and session settings. |

### 1.2 `AppShellState` (`lib/domain/entities/app_shell_section.dart`)

| Field | Type | Default | Description |
|---|---|---|---|
| `activeSection` | `AppShellSection` | `AppShellSection.matches` | Currently selected bottom navigation destination. |

---

## 2. State Models & Derived Collections

### 2.1 `MatchesCatalogState` (`lib/domain/entities/matches_catalog_state.dart`)

Extended with calendar-date filtering properties to power the `"Partidos"` tab while preserving existing round/status/team filtering capabilities.

| Field / Getter | Type | Description |
|---|---|---|
| `matches` | `List<ChampionshipMatch>` | All matches loaded for the active championship tournament. |
| `referees` | `List<MatchReferee>` | Official referees available for match scheduling. |
| `selectedDate` | `DateTime?` | Currently selected calendar day normalized to `DateTime(year, month, day)`. Defaults to `Hoy` if matches exist today, or the nearest scheduled match date if matches exist on another day, or `Hoy` when empty. |
| `selectedRound` | `int` | Selected round number (retained for round-based domain/unit operations). |
| `statusFilter` | `MatchStatus?` | Optional match status filter (`scheduled`, `completed`, etc.). |
| `teamFilter` | `String?` | Optional team ID filter. |
| `availableCalendarDates` | `List<DateTime>` | Sorted list of distinct normalized calendar dates (`DateTime(y, m, d)`) always including `Hoy` and `Mañana` plus all calendar dates on which at least one match has `scheduledStartTime != null`. |
| `scheduledMatchesForSelectedDate` | `List<ChampionshipMatch>` | Matches with `scheduledStartTime != null` whose calendar date (`year`, `month`, `day`) matches `selectedDate` (and optional `statusFilter` / `teamFilter`), sorted chronologically by `scheduledStartTime`. Excludes unscheduled matches (`scheduledStartTime == null`). |
| `unscheduledMatches` | `List<ChampionshipMatch>` | Matches without an assigned date/time (`scheduledStartTime == null` or `status == MatchStatus.pendingSchedule`), exposed exclusively to the `Organizador` in the `"Por programar (N)"` section. |
| `liveMatches` | `List<ChampionshipMatch>` | Matches currently in `MatchStatus.inProgress`, highlighted at the top in the `"EN VIVO"` section. |

### 2.2 Global Championship Context (`TournamentsCatalogState`)

- `selectedTournamentId` and `selectedTournament` in `TournamentsController` (`tournamentsControllerProvider`) act as the single source of truth for the active championship across:
  1. **Partidos** (`MatchdayTabView`)
  2. **Explorar** (`StandingsTabView`)
  3. **Noticias** (`NewsTabView`)

---

## 3. State Transitions & Validation Rules

1. **Bottom Navigation Selection (`AppShellController`)**:
   - `setSection(AppShellSection)` / `setSectionByIndex(int index)` transitions `activeSection` in `O(1)` time without disposing inactive tab subtrees inside `IndexedStack`.
   - Out-of-range indices (`index < 0 || index >= 4`) are ignored safely.
2. **Calendar Date Selection (`MatchesCatalogController.selectDate`)**:
   - Normalizes incoming `DateTime` to `DateTime(date.year, date.month, date.day)` and updates `state.selectedDate`.
   - `scheduledMatchesForSelectedDate` immediately recomputes the matches scheduled for that calendar day.
3. **Scheduling an Unscheduled Match (`MatchesCatalogController.scheduleMatch`)**:
   - Only `UserRole.organizer` (`RoleCapability.manageTournaments`) can see `"Por programar (N)"` and invoke `scheduleMatch`.
   - Upon assigning `scheduledStartTime`, `venue`, `pitch`, and `referee`, the match status transitions from `MatchStatus.pendingSchedule` to `MatchStatus.scheduled`, `selectedDate` updates to `DateTime(scheduledStartTime.year, scheduledStartTime.month, scheduledStartTime.day)`, and the match moves from `"Por programar (N)"` to its calendar date list.
4. **Global Tournament Switching (`TournamentsController.selectTournament`)**:
   - Selecting a tournament in `"Partidos"`, `"Explorar"`, or `"Noticias"` updates `tournamentsControllerProvider.selectedTournamentId`.
   - `"Partidos"` listens to `selectedTournamentId` changes and invokes `loadTournamentMatches(newTournamentId)`.
   - `"Noticias"` passes the active `tournamentId` and `isHistoricalReadOnly: tournament.status == TournamentStatus.finished` to `TournamentNewsFeedView`.
