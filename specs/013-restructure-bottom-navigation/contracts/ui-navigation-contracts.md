# UI & Navigation Contracts: Reestructuración del Navigation Bar Inferior (HU 10.1)

**Feature**: `013-restructure-bottom-navigation` (HU 10.1)  
**Date**: 2026-11-05

## 1. Bottom `NavigationBar` Contract (`AppShellScreen`)

The primary `NavigationBar` in `AppShellScreen` MUST expose the exact 4 destinations below in fixed order for all 5 system roles (`Organizador`, `Entrenador / Capitán`, `Árbitro`, `Jugador`, `Aficionado`), with `"Sedes"` removed from the bottom bar:

| Index | Enum (`AppShellSection`) | Route | Spanish Label (`l10n`) | Outlined Icon | Selected Icon (`KickPulseColors.accentPrimary`) | Root Tab View Widget |
|---|---|---|---|---|---|---|
| `0` | `AppShellSection.matches` | `/matches` (alias `/matchday`) | `"Partidos"` (`l10n.tabMatches` / `l10n.tabMatchday`) | `Icons.sports_soccer_outlined` | `Icons.sports_soccer` | `MatchdayTabView` |
| `1` | `AppShellSection.explore` | `/explore` (alias `/standings`) | `"Explorar"` (`l10n.tabExplore` / `l10n.tabStandings`) | `Icons.explore_outlined` | `Icons.explore` | `StandingsTabView` |
| `2` | `AppShellSection.news` | `/news` | `"Noticias"` (`l10n.tabNews`) | `Icons.newspaper_outlined` | `Icons.newspaper` | `NewsTabView` |
| `3` | `AppShellSection.profile` | `/profile` | `"Perfil"` (`l10n.tabProfile`) | `Icons.person_outline` | `Icons.person` | `ProfileTabView` |

- **Preserved Secondary Route**: `/venues` remains registered in `AppRouter` (rendering `VenuesTabView` inside a `Scaffold`) so venue management and future HU 10.2 Drawer navigation remain 100% functional.

---

## 2. Widget Key & Interaction Contracts

### 2.1 First Tab: `"Partidos"` (`MatchdayTabView`)

| Element | Widget Key | Role Visibility | Contract Behavior |
|---|---|---|---|
| **Screen Header** | `Key('matches_tab_header')` | All 5 roles | Displays localized `"Partidos"` title and `"OFICIAL"` badge. |
| **Tournament Selector** | `Key('matches_tournament_selector')` | All 5 roles (when `tournaments.length > 1`) | Synchronizes with `tournamentsControllerProvider.selectTournament(id)`. |
| **Generate Fixture Action** | `Key('generate_fixture_button')` | `Organizador` only (`canManageTournaments`) | Opens `GenerateFixtureConfirmationDialog` and generates matches. |
| **Removed Segmented Control** | `Key('matchday_segmented_button')` | **REMOVED** (`findsNothing`) | Must NOT exist in `MatchdayTabView`. |
| **Live Matches Section** | `Key('live_matches_section')` | All 5 roles (when `liveMatches.isNotEmpty`) | Highlights `MatchStatus.inProgress` matches at top with `"EN VIVO"` badge. |
| **Calendar Date Selector** | `Key('matchday_date_chips_list')` | All 5 roles | Horizontal `ChoiceChip` strip with `Key('date_chip_YYYY-MM-DD')` (`Hoy`, `Mañana`, and scheduled match dates). |
| **Daily Scheduled Matches** | `Key('match_card_${match.id}')` | All 5 roles | Lists only matches with `scheduledStartTime` matching `selectedDate`. |
| **Unscheduled Matches Section** | `Key('unscheduled_matches_section')` | `Organizador` **ONLY** (when `unscheduledMatches.isNotEmpty`) | Displays `"Por programar (N)"` header and unscheduled `MatchCard` items with `"Programar"` action (`ScheduleMatchDialog`). Hidden (`findsNothing`) for all non-organizer roles. |

### 2.2 Second Tab: `"Explorar"` (`StandingsTabView`)

| Element | Widget Key | Role Visibility | Contract Behavior |
|---|---|---|---|
| **Bottom Tab Destination** | — | All 5 roles | Displays label `"Explorar"` and keeps all championship catalog, standings, brackets, honor roll, teams, and rankings intact. |

### 2.3 Third Tab: `"Noticias"` (`NewsTabView`)

| Element | Widget Key | Role Visibility | Contract Behavior |
|---|---|---|---|
| **Screen Header** | `Key('news_tab_header')` | All 5 roles | Displays localized `"Noticias"` screen title and `"OFICIAL"` badge. |
| **Tournament Selector** | `Key('news_tournament_selector')` | All 5 roles (when `tournaments.length > 1`) | Displays active tournament and synchronizes globally via `tournamentsControllerProvider.selectTournament(id)`. |
| **Embedded News Feed** | `Key('tournament_news_feed_${tournament.id}')` | All 5 roles | Renders `TournamentNewsFeedView` with category filter bar (`Todos`, `General`, `Reprogramación`, `Disciplinario`), `Organizador` publish/delete controls, and `news_readonly_badge` when tournament status is `Finalizado`. |

### 2.4 Fourth Tab: `"Perfil"` (`ProfileTabView`)

- Remains at index `3` with unchanged behavior.
