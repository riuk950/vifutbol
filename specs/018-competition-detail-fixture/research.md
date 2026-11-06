# Research: Pantalla de Detalle de Competición con Pestañas y Partidos por Jornadas (Fixture Completo)

**Feature**: `018-competition-detail-fixture`
**Date**: 2026-11-06

---

## 1. Technical Context & State Management

### 1.1 Consumo Reactivo de Datos del Torneo y Fixture
- **Torneo Activo**: Se obtiene mediante `tournamentsControllerProvider`. La pantalla `CompetitionDetailScreen` recibe el parámetro `tournamentId` desde la ruta `/competitions/:id` o desde el constructor. Se extrae el torneo mediante:
  ```dart
  final tournamentsState = ref.watch(tournamentsControllerProvider);
  final tournament = tournamentsState.tournaments.firstWhereOrNull((t) => t.id == tournamentId);
  ```
- **Partidos del Campeonato**: Se leen a través de `matchesCatalogControllerProvider`. Se filtran reactivamente por `match.tournamentId == tournamentId`:
  ```dart
  final matchesCatalogState = ref.watch(matchesCatalogControllerProvider);
  final tournamentMatches = matchesCatalogState.matches.where((m) => m.tournamentId == tournamentId).toList();
  ```
- **Equipos del Torneo**: Para resolver nombres y escudos en las tarjetas de partido, se consulta `teamsControllerProvider` (`teamsState.teams`).

---

## 2. Decisiones de Diseño y Navegación

### 2.1 Enrutamiento Declarativo
- Se define la ruta `/competitions/:id` en `AppRouter`:
  ```dart
  final competitionDetailHandler = Handler(
    handlerFunc: (context, parameters) {
      final id = parameters['id']?.first ?? '';
      return CompetitionDetailScreen(tournamentId: id);
    },
  );
  router.define('/competitions/:id', handler: competitionDetailHandler, transitionType: TransitionType.native);
  ```
- En `CompetitionsDirectoryScreen`, `_onTournamentTapped` navega a `/competitions/${tournament.id}` con botón de retroceso (`Navigator.of(context).pushNamed(...)`).

### 2.2 Estructura de Pestañas Horizontales Fijas (`TabBar`)
- Se implementa un `DefaultTabController(length: 3, child: Scaffold(...))` con un `TabBar` fijado como `bottom` del `AppBar` o inmediatamente debajo en una cabecera con `surfaceBase`.
- Pestañas:
  1. **"Partidos"**: Pestaña por defecto (índice 0).
  2. **"Clasificación"**: Índice 1. Conecta con `StandingsAndRankingsController(tournamentId)` reutilizando la tabla de posiciones calculada (o estado vacío si aún no hay partidos).
  3. **"Información"**: Índice 2. Muestra `CompetitionInfoContent` con vista descriptiva de preparación (`KickPulseStateView`) sobre el reglamento y puntuación hasta HU 13.3.

### 2.3 Agrupación y Rendimiento del Fixture por Jornadas (FR-012)
- Función determinista y pura `groupMatchesByRoundNumber(List<ChampionshipMatch> matches)`:
  - Ordena las jornadas por `roundNumber` ascendente.
  - Para cada jornada, agrupa sus partidos ordenados por fecha/hora programada (o pendientes al final).
  - Retorna una lista de `MatchdayFixtureGroup` (`roundNumber`, `roundName`, `matches`).
- Renderizado perezoso mediante `ListView.builder` o `CustomScrollView` con `SliverList` para garantizar 60 fps estables incluso con torneos extensos (>30 jornadas).

### 2.4 Interacción al Tocar Tarjetas de Partido (FR-013)
- Cada partido se representa mediante el componente estandarizado `MatchCenterCard`.
- Al pulsar `MatchCenterCard`, se invoca `showMatchDetailSheet(context, match: match, homeTeam: homeTeam, awayTeam: awayTeam)` que despliega una hoja modal inferior (`KickPulseCard` / `showModalBottomSheet`) con el resumen del encuentro, sede, árbitro designado y estado oficial.

---

## 3. Manejo de Estados y Resiliencia Móvil (`docs/MOBILE_GUIDELINES.md`)

- **Estado Vacío**: Si `tournamentMatches.isEmpty`, la pestaña de partidos despliega `KickPulseStateView` con icono `Icons.event_busy_outlined`, título localizado `l10n.fixtureEmptyMatchesTitle` y subtítulo `l10n.fixtureEmptyMatchesMessage`.
- **Modo Offline**: Los datos se cargan desde los repositorios locales hidratados (`LocalTournamentMatchesRepository` y `LocalTournamentsRepository`), garantizando disponibilidad inmediata sin conexión.
- **Viewport Compacto (320x640 @ 130% texto)**:
  - Nombres de torneos largos truncados en el AppBar.
  - El encabezado de jornada y la insignia de estado usan envolturas flexibles para evitar `RenderFlex` overflow.
