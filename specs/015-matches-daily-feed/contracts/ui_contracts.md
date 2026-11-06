# Contracts: Daily Matches Feed & Temporal Navigation

**Feature**: `015-matches-daily-feed`  
**Date**: 2026-11-06  
**Status**: Completed

Este archivo formaliza los contratos de interfaz entre las capas de dominio/aplicación y la capa de presentación para el feed diario de partidos.

---

## 1. Provider & Controller Contract

### 1.1. `DailyMatchesFeedController` Interface

Controlador de Riverpod encargado de orquestar la fecha activa y calcular los grupos de competiciones y partidos del día.

```dart
abstract class DailyMatchesFeedControllerContract {
  /// Selecciona una de las pestañas rápidas: yesterday, today, tomorrow.
  void selectQuickTab(MatchesDailyTab tab);

  /// Selecciona una fecha arbitraria (típicamente desde el DatePicker).
  void selectCustomDate(DateTime date);

  /// Refresca los partidos y torneos para la fecha actual.
  Future<void> refresh();

  /// Reinicia la fecha a 'today' (usado por ejemplo al cambiar de día en segundo plano).
  void resetToToday();
}
```

### 1.2. Public Providers
- `dailyMatchesFeedControllerProvider`: `NotifierProvider<DailyMatchesFeedController, DailyMatchesFeedState>`
- `isMatchdayCalendarActionVisibleProvider`: Provider booleano que devuelve `true` cuando `appShellSection == AppShellSection.matchday`.

---

## 2. UI Component Contracts & Accessibility Keys

| Componente | Tipo / Key | Props / Contrato | Comportamiento |
|---|---|---|---|
| `CalendarAppBarAction` | `IconButton` (`Key('app_bar_calendar_action')`) | `VoidCallback onTap` | Despliega modal de calendario (`showDatePicker`). Solo visible en la pestaña Partidos. |
| `DailyMatchesTabBar` | Widget (`Key('daily_matches_tab_bar')`) | `DailyMatchesDateState state, ValueChanged<MatchesDailyTab> onTabSelected` | Muestra pestañas "Ayer", "Hoy", "Mañana" y pill de fecha personalizada si aplica. |
| `YesterdayTabButton` | `InkWell` (`Key('quick_tab_yesterday')`) | `isSelected: bool` | Activa la fecha de ayer. |
| `TodayTabButton` | `InkWell` (`Key('quick_tab_today')`) | `isSelected: bool` | Activa la fecha de hoy. |
| `TomorrowTabButton` | `InkWell` (`Key('quick_tab_tomorrow')`) | `isSelected: bool` | Activa la fecha de mañana. |
| `TournamentMatchesGroupCard` | Widget (`Key('tournament_group_${tournament.id}')`) | `TournamentMatchesGroup group, ValueChanged<ChampionshipMatch> onMatchTap` | Muestra el bloque del torneo y sus partidos del día. |
| `TournamentHeader` | Widget | `onTournamentTap: VoidCallback` | Navega al detalle de la competición en el directorio. |
| `MatchCenterRow` | Widget (`Key('match_center_row_${match.id}')`) | `ChampionshipMatch match, TournamentTeam? homeTeam, TournamentTeam? awayTeam` | Tarjeta simétrica (Local - Score/Time - Visitante). |
| `OrganizerPendingBanner` | Widget (`Key('organizer_pending_matches_banner')`) | `int pendingCount, int unseededTournamentsCount, VoidCallback onManageTap` | Banner destacado visible solo para organizadores con pendientes. |

---

## 3. Localization Keys (l10n)

Nuevas entradas requeridas en `AppLocalizations`:

```arb
"tabYesterday": "Ayer",
"tabToday": "Hoy",
"tabTomorrow": "Mañana",
"calendarPickerTooltip": "Seleccionar fecha del calendario",
"emptyMatchesForDate": "No hay partidos programados para esta fecha",
"emptyMatchesSuggestion": "Prueba seleccionando otro día o consulta el calendario completo",
"liveMatchBadge": "EN VIVO",
"finalMatchBadge": "Final",
"cancelledMatchBadge": "Cancelado",
"organizerPendingMatchesAlert": "{count, plural, =1{1 partido pendiente de programar} other{{count} partidos pendientes de programar}}",
"organizerPendingMatchesAction": "Programar partidos"
```
