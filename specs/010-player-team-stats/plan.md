# Implementation Plan: Perfil Personal de Rendimiento del Jugador y Estadísticas Detalladas del Equipo (HU 8.2)

**Branch**: `010-player-team-stats` | **Date**: 2026-11-04 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/010-player-team-stats/spec.md)
**Input**: Feature specification from `/specs/010-player-team-stats/spec.md`

## Summary

Implementar el Perfil Personal de Rendimiento del Jugador (`PlayerPerformanceProfile`) y la Ficha de Estadísticas Detalladas del Equipo (`TeamDetailedStats`) dentro del módulo competitivo de campeonatos (`HU 8.2`). El sistema calcula de forma determinista a partir de las actas oficiales cerradas (`DigitalMatchReport`), las convocatorias/alineaciones (`MatchLineupConvocation`) y los planteles inscritos (`TournamentTeam` / `RegisteredPlayer`) las métricas individuales (`PJ`, `Titularidades`, `Goles`, `Asistencias`, `Promedio de Gol` con protección contra división por cero `0.00`, `Tarjetas Amarillas`, `Tarjetas Rojas`, estado disciplinario `Habilitado`/`Suspendido` y desglose partido por partido), así como las estadísticas consolidadas del equipo (posición actual, racha de los últimos 5 partidos `V`/`E`/`D`, historial de resultados, próximos rivales y aporte individual de toda la plantilla), con navegación *drill-down* contextual desde `StandingsTabView` y caché local offline para consulta inmediata sin conexión.

## Technical Context

**Language/Version**: Dart `3.11.1` / Flutter `3.41.4`  
**Primary Dependencies**: `flutter`, `flutter_localizations`, `flutter_riverpod` (`^2.6.1`), `intl` (`^0.20.2`), `google_fonts` (`^6.2.1`)  
**Storage**: Almacenamiento local en dispositivo mediante `LocalStorageRepository` (`cached_player_performance_profile_v1`), `MatchReportsRepository`, `LineupsTrackingRepository`, `TeamsRepository`, `TournamentMatchesRepository` y `TournamentsRepository`  
**Testing**: `flutter_test` (pruebas unitarias de servicios de dominio, casos de uso y pruebas de widgets con verificación a `130%` de escala de texto y pantallas de `320px`)  
**Target Platform**: iOS & Android (Mobile-First, orientación vertical, soporte offline en cancha)  
**Project Type**: Mobile App (Flutter Clean Architecture + DDD ligero)  
**Performance Goals**: `< 50 ms` para el cálculo de perfiles de jugadores y fichas detalladas de equipos (`SC-001`), `60 fps` constantes y `0` desbordamientos visuales (`SC-004`)  
**Constraints**: Cifras numéricas con alineación tabular (`FontFeature.tabularFigures()` / `KickPulseTypography.statMetric`), estado vacío exacto `"Aún no registras participaciones en partidos oficiales de este torneo."`, máximo 5 pestañas en barra inferior (usando *drill-down* contextual en `StandingsTabView`), sin `LayoutBuilder` dentro de `SliverFillRemaining(hasScrollBody: false)`  
**Scale/Scope**: Torneos de hasta 32 equipos y ~600 jugadores inscritos con consulta instantánea `O(1)` en memoria y respaldo offline en `LocalStorageRepository`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. DDD & Clean Architecture**: **PASS**. Nuevas entidades inmutables (`PlayerPerformanceProfile`, `PlayerMatchParticipation`, `TeamDetailedStats`) y el servicio puro `PlayerTeamStatsCalculatorService` residen en `lib/domain/` sin dependencias de Flutter ni de infraestructura.
- **II. Mobile-First Craftsmanship (`docs/MOBILE_GUIDELINES.md`)**: **PASS**. Navegación contextual mediante *bottom sheets* / vistas modales desde `StandingsTabView` respetando las 5 pestañas inferiores, áreas táctiles `>= 48x48dp`, y adaptación fluida sin truncar nombres ni desbordar a `130%` de escala de texto.
- **III. Offline-First & Field Reliability**: **PASS**. Todos los cálculos operan sobre datos locales ya sincronizados y el perfil del jugador autenticado/consultado se guarda en caché local (`LocalStorageRepository`) para disponibilidad inmediata en modo sin conexión (`FR-009`, `SC-005`).
- **IV. Deterministic Competition Engine**: **PASS**. Reglas deterministas para `PJ`, `Titularidades`, `Promedio de Gol` (`0.00` cuando `PJ == 0`), estado disciplinario (`Habilitado` / `Suspendido`) y racha de 5 partidos (`V`, `E`, `D`).
- **V. "Kick & Pulse" High-Craft Dark UI & Design System (`DESIGN.md`)**: **PASS**. Uso exclusivo de `KickPulseColors`, `KickPulseRadiiSpacing` y `KickPulseTypography.statMetric` (`tabular-nums`) para todas las métricas de jugador y equipo.
- **VI. Language & Localization Discipline**: **PASS**. Código, identificadores y pruebas 100% en inglés; textos visibles para el usuario 100% en español centralizados en `lib/l10n/app_es.arb`.
- **VII. Testing & Quality Gates**: **PASS**. Pruebas unitarias exhaustivas para `PlayerTeamStatsCalculatorService` y el caso de uso, más pruebas de widgets verificando estados vacíos, navegación *drill-down* y escalado de texto al `130%`.

## Project Structure

### Documentation (this feature)

```text
specs/010-player-team-stats/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── player-team-stats-contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   └── app_es.arb
├── domain/
│   ├── entities/
│   │   ├── player_performance_profile.dart
│   │   └── team_detailed_stats.dart
│   └── services/
│       └── player_team_stats_calculator_service.dart
├── application/
│   ├── use_cases/
│   │   └── calculate_tournament_standings_and_rankings_use_case.dart
│   └── controllers/
│       └── standings_and_rankings_controller.dart
└── presentation/
    ├── shell/
    │   └── tabs/
    │       └── standings_tab_view.dart
    └── standings/
        └── widgets/
            ├── standings_table_card.dart
            ├── tournament_rankings_card.dart
            ├── player_performance_profile_card.dart
            └── team_detailed_stats_card.dart

test/
├── unit/
│   ├── domain/
│   │   └── player_team_stats_calculator_service_test.dart
│   └── application/
│       └── calculate_tournament_standings_and_rankings_use_case_test.dart
└── widget/
    └── player_team_stats_widget_test.dart
```

**Structure Decision**: Se extiende la estructura modular de `lib/domain/`, `lib/application/` y `lib/presentation/standings/widgets/` creada en `HU 8.1`, integrando el cálculo de perfiles de jugadores y fichas detalladas de equipos en el snapshot competitivo del torneo y exponiendo vistas/hojas modales interactivas desde `StandingsTabView`, `StandingsTableCard` y `TournamentRankingsCard`.

## Complexity Tracking

No existe ninguna violación a la Constitución del proyecto.
