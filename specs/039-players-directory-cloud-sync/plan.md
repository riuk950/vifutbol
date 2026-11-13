# Implementation Plan: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Branch**: `039-players-directory-cloud-sync` | **Date**: 2026-11-13 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/spec.md)

**Input**: Feature specification from [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/039-players-directory-cloud-sync/spec.md)

## Summary

Refactorizar la pantalla de Directorio de Jugadores (`PlayersDirectoryScreen`) y su controlador (`PlayersDirectoryController`) para eliminar la fila horizontal de chips de filtrado por torneo (`ChoiceChip`), optimizando el espacio visual en favor de la barra de búsqueda reactiva multi-campo con debounce de 300 ms. Conectar la obtención de la nómina global de futbolistas directamente con la tabla `vifutboldev.players` en Supabase DEV a través de `HybridTeamsRepository.loadAllPlayers()`, garantizando la hidratación continua de la caché local en Hive (`vifutbol_dev_teams_box`) para disponibilidad offline inmediata sin errores de red. Añadir soporte para recarga manual bajo demanda (Pull-to-Refresh) con degradación elegante a datos locales y notificación informativa en caso de desconexión.

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter (Material 3)  
**Primary Dependencies**: `flutter_riverpod ^2.6.1`, `supabase_flutter ^2.18.3`, `hive ^2.2.3`, `hive_flutter ^1.1.0`, `connectivity_plus ^6.1.4`, `intl`, `flutter_localizations`  
**Storage**: Hive (`LocalTeamsRepository`, caja `vifutbol_dev_teams_box`) + Supabase PostgreSQL (`vifutboldev.players`, `tournament_teams`, `teams`, `tournaments`)  
**Testing**: `flutter test`, `mocktail ^1.0.4`, `flutter analyze`, `dart format`  
**Target Platform**: Android / iOS (validado en emulador Android `emulator-5554` contra Supabase DEV)  
**Project Type**: Mobile app (Flutter Clean Architecture: `domain/`, `infrastructure/`, `application/`, `presentation/`)  
**Performance Goals**: Filtrado reactivo en `< 300ms` con debounce, carga remota cloud `< 1.5s`, recuperación offline local desde Hive `< 50ms` (`SC-002`, `SC-003`)  
**Constraints**: Preservar pureza de `domain/`, textos de interfaz 100% en español vía `lib/l10n/app_es.arb`, código técnico en inglés, targets táctiles `>= 48x48`, cumplimiento de `docs/MOBILE_GUIDELINES.md`  
**Scale/Scope**: 1 pantalla (`PlayersDirectoryScreen`), 1 controlador (`PlayersDirectoryController`), 1 estado (`PlayersDirectoryState`), 1 repositorio híbrido (`HybridTeamsRepository`), tests unitarios y de widgets actualizados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación Pre-Research | Evaluación Post-Design | Estado |
| :--- | :--- | :--- | :--- |
| **I. La Spec Manda** | Requisitos `FR-001`–`FR-008`, `SC-001`–`SC-005` y clarificaciones Q1–Q4 derivados de Notion `4178442e-3f49-81da-8859-d9017ca47306`. | Documentos de diseño (`data-model.md`, `contracts/`, `quickstart.md`) cubren 100% de los requerimientos funcionales y criterios de aceptación. | **PASS** |
| **II. Integridad de Datos** | Consulta relacional a `vifutboldev.players` manteniendo integridad referencial con torneos y equipos; hidratación en Hive. | `PlayerDirectoryItem` garantiza referencias inmutables de IDs y nombres proyectados; caché local actualizada en cada lectura remota. | **PASS** |
| **III. Pruebas Automatizadas** | Plan de pruebas unitarias para controlador y repositorio híbrido, más pruebas de widgets para ausencia de chips y presencia de buscador. | Suites en `test/unit/` y `test/presentation/` definidas con comandos de ejecución en `quickstart.md`. | **PASS** |
| **IV. Arquitectura Limpia** | Separación en capas: Dominio (`TeamsRepository`), Infraestructura (`HybridTeamsRepository`), Aplicación (`PlayersDirectoryController`), Presentación (`PlayersDirectoryScreen`). | Ninguna dependencia externa en el dominio; contratos definidos en `contracts/players-directory-contracts.md`. | **PASS** |
| **V. Segregación de Roles y DESIGN.md** | Acción de inscribir jugadores restringida al rol con permiso `manageTeamRoster`; tokens visuales de KickPulse Dark. | Se mantiene `RoleCapability.manageTeamRoster` para el botón contextual; paleta y componentes de `DESIGN.md` respetados. | **PASS** |
| **VI. Inglés técnico / Español UI** | Código, nombres de métodos y tests en inglés; cadenas de UI en español centralizadas en `app_es.arb`. | Contratos en inglés técnico; mensajes de SnackBar y etiquetas de búsqueda centralizados en `l10n`. | **PASS** |
| **VII. Resiliencia y Experiencia Móvil** | Capacidad offline-first con respaldo en Hive; Pull-to-Refresh que no destruye datos ante caída de red. | `FR-004` y `FR-006` especifican resiliencia transparente y SnackBar no intrusivo ante falta de internet. | **PASS** |

## Project Structure

### Documentation (this feature)

```text
specs/039-players-directory-cloud-sync/
├── spec.md                              # Especificación funcional y clarificaciones Q1–Q4
├── checklists/
│   └── requirements.md                  # Checklist de calidad de spec (16/16 PASS)
├── plan.md                              # Este archivo (/speckit-plan output)
├── research.md                          # Decisiones arquitectónicas Fase 0
├── data-model.md                        # Entidades de datos, proyecciones y estado
├── quickstart.md                        # Comandos de validación automatizada y guía E2E
├── contracts/
│   └── players-directory-contracts.md   # Contratos Dart de repositorio, controlador y UI
└── tasks.md                             # Output futuro de /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── domain/
│   └── repositories/
│       └── teams_repository.dart                # + loadAllPlayers()
├── infrastructure/
│   └── repositories/
│       ├── local_teams_repository.dart          # + loadAllPlayers() desde Hive
│       └── hybrid_teams_repository.dart         # + loadAllPlayers() desde Supabase + fallback Hive
├── application/
│   ├── controllers/
│   │   └── players_directory_controller.dart    # Estado limpio sin torneos + loadPlayers() + refreshPlayers()
│   └── providers/
│       └── directory_providers.dart             # Inyección simplificada con teamsRepositoryProvider
├── presentation/
│   └── directories/
│       └── players_directory_screen.dart        # Remoción ChoiceChips + RefreshIndicator + búsqueda
└── l10n/
    └── app_es.arb                               # Cadenas de UI en español para recarga y fallback

test/
├── unit/
│   ├── application/
│   │   └── players_directory_controller_test.dart
│   └── infrastructure/
│       └── sync/
│           └── hybrid_teams_repository_players_test.dart
└── presentation/
    ├── players_directory_screen_test.dart
    └── directories/
        └── players_directory_role_visibility_test.dart
```
