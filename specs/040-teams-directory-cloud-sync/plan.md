# Implementation Plan: Directorio de Equipos — Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.2)

**Branch**: `040-teams-directory-cloud-sync` | **Date**: 2026-11-13 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/040-teams-directory-cloud-sync/spec.md)

**Input**: Feature specification from `/specs/040-teams-directory-cloud-sync/spec.md`

## Summary

Eliminar los `ChoiceChip` horizontales de filtro por torneo en `TeamsDirectoryScreen` y conectar el Directorio de Equipos directamente al catálogo global de clubes en Supabase DEV (`vifutboldev.teams`) mediante `TeamsRepository.loadAllTeams()`. Cada club se presenta de forma única (incluidos clubes creados por entrenadores sin torneo asignado) mostrando su nombre, escudo, categoría/estado y total consolidado de jugadores, con sincronización en caché local Hive (Offline-First), ordenamiento alfabético A-Z, búsqueda reactiva multi-campo, Pull-to-Refresh con degradación elegante offline (`SnackBar`) y navegación segura hacia `TeamDetailScreen`.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter SDK 3.x  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `hive_flutter`, `flutter_localizations` (l10n)  
**Storage**: Supabase PostgreSQL (`vifutboldev.teams` con joins a `tournament_teams`, `tournaments`, `players`) + Hive local cache (`LocalTeamsRepository`)  
**Testing**: `flutter_test` (pruebas unitarias de repositorio y controlador, pruebas de widget y responsividad)  
**Target Platform**: Android / iOS (Flutter mobile)  
**Project Type**: Mobile application (Clean Architecture: Domain, Application, Infrastructure, Presentation)  
**Performance Goals**: Renderizado desde caché offline < 1 s; filtrado de búsqueda reactivo en < 500 ms (debounce 300 ms); 60 fps en scroll  
**Constraints**: Offline-First estricto; separación estricta de idiomas (código en inglés, UI en español vía `app_es.arb`); cero importaciones de Supabase/Hive en `lib/domain/`  
**Scale/Scope**: 1 entidad de dominio nueva (`TeamDirectoryItem`), 1 contrato de repositorio extendido (`TeamsRepository`), 1 controlador refactorizado (`TeamsDirectoryController`), 1 pantalla principal (`TeamsDirectoryScreen`) + soporte en `TeamDetailScreen` para clubes sin torneo

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pre-Design Status | Post-Design Status | Verification |
|-----------|-------------------|--------------------|--------------|
| I. La Spec Manda | PASS | PASS | Todo el alcance deriva directamente de `spec.md` y sus clarificaciones Q1-Q3. |
| II. Integridad de Datos y Fuente de Verdad | PASS | PASS | Unicidad por `teams.id` en `vifutboldev.teams`, consolidación determinista de jugadores e hidratación consistente en Hive. |
| III. Pruebas Automatizadas como Puerta de Calidad | PASS | PASS | Cobertura planificada en unidad (`hybrid_teams_repository_teams_test.dart`, `teams_directory_controller_test.dart`) y widget (`teams_directory_screen_test.dart`). |
| IV. Arquitectura Limpia | PASS | PASS | `TeamDirectoryItem` reside en `lib/domain/entities/` sin dependencias de Supabase, Hive o Flutter UI. |
| V. Segregación de Roles y Sistema de Diseño | PASS | PASS | Botón `create_team_from_directory_button` mantiene control por rol (`coach`/`organizer`); UI usa tokens `KickPulse*`. |
| VI. Convenciones de Idioma | PASS | PASS | Símbolos/archivos/tests en inglés; etiquetas UI (`teamsDirectoryOfflineRefreshWarning`, `teamsDirectoryNoTournamentAssigned`, `teamsDirectoryMultipleTournaments`) en `lib/l10n/app_es.arb`. |
| VII. Resiliencia y Experiencia Móvil | PASS | PASS | Cubre estados `loading`/`content`/`empty`/`error`, Pull-to-Refresh con advertencia offline no intrusiva, soporte sin torneo en detalle y adaptabilidad responsiva. |

## Project Structure

### Documentation (this feature)

```text
specs/040-teams-directory-cloud-sync/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── teams-directory-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   └── app_es.arb                                      # Nuevas etiquetas localizadas en español
├── domain/
│   ├── entities/
│   │   └── team_directory_item.dart                    # Entidad pura de club global
│   └── repositories/
│       └── teams_repository.dart                       # Contrato loadAllTeams()
├── infrastructure/
│   └── repositories/
│       ├── local_teams_repository.dart                 # Caché Hive para TeamDirectoryItem
│       └── hybrid_teams_repository.dart                # fetchAllTeams() desde vifutboldev.teams + sync Hive
├── application/
│   ├── controllers/
│   │   └── teams_directory_controller.dart             # Refactor sin filtros de torneo + loadTeams/refreshTeams + A-Z
│   └── providers/
│       └── directory_providers.dart                    # Conexión teamsDirectoryControllerProvider con teamsRepositoryProvider
└── presentation/
    ├── directories/
    │   └── teams_directory_screen.dart                 # Remoción ChoiceChip + RefreshIndicator + tarjetas globales
    └── teams/
        └── team_detail_screen.dart                     # Fallback seguro para clubes sin inscripción en torneo

test/
├── unit/
│   ├── infrastructure/sync/
│   │   └── hybrid_teams_repository_teams_test.dart     # Tests de fetchAllTeams, hidratación Hive y fallback offline
│   └── application/
│       └── teams_directory_controller_test.dart        # Tests de carga, refresh, búsqueda multi-campo y orden A-Z
└── presentation/
    └── teams_directory_screen_test.dart                # Tests de remoción de chips, Pull-to-Refresh y tarjetas globales
```

**Structure Decision**: Se sigue la arquitectura por capas existente del proyecto (`domain`, `application`, `infrastructure`, `presentation`), replicando la separación limpia establecida en `039-players-directory-cloud-sync` (HU 19.1) para mantener uniformidad técnica en toda la Épica 19.

## Complexity Tracking

No existen violaciones a la Constitución que requieran justificación.
