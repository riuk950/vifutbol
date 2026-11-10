# Implementation Plan: Gestión de Equipos Inscritos en Competición (Opción en FAB Menu, Pestaña de Equipos, Retiro y Traslado de Grupo) (HU 15.4)

**Branch**: `027-competition-teams-management` | **Date**: 2026-11-10 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/027-competition-teams-management/spec.md`

## Summary

Habilitar al rol **Organizador** para gestionar integralmente los equipos inscritos de cada competición desde `CompetitionDetailScreen` (`/competitions/:id`):
1. **Opción "Agregar Equipo" en el FAB Menu** (`Key('competition_detail_fab_add_team')`), que despliega `CompetitionEnrollTeamDialog` para inscribir un nuevo club o vincular un equipo existente del catálogo al campeonato actual, asignándole opcionalmente su grupo inicial cuando el formato es `mixedGroupsAndKnockout`.
2. **Pestaña "Equipos" (`CompetitionTeamsTabView`)** en el `TabBar` de 4 pestañas (*Partidos*, *Clasificación*, *Equipos*, *Información*), mostrando los clubes inscritos con escudo, código corto, jugadores registrados, estado de elegibilidad, insignia de grupo (cuando aplica) y navegación al detalle del equipo (`/teams/:id`).
3. **Acciones del Organizador sobre equipos inscritos**: **Trasladar de Grupo** (`Key('competition_team_move_group_<id>')`) en torneos `mixedGroupsAndKnockout` —sincronizado con `StandingsCalculatorService.calculateGroupStageTables`— y **Quitar del campeonato** (`Key('competition_team_remove_<id>')`) con diálogo de confirmación (`Key('competition_remove_team_confirm_dialog')`).

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter `^3.11.0`  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `intl: ^0.20.2`, `shared_preferences: ^2.5.4`, `google_fonts: ^6.2.1`  
**Storage**: Almacenamiento local offline-first (`LocalStorageRepository` / `LocalTeamsRepository`)  
**Testing**: `flutter_test` (Unit & Widget tests)  
**Target Platform**: iOS & Android (Mobile-First, adaptable desde $320 \times 640\text{ px}$ con escalado de texto del $130\%$)  
**Project Type**: Mobile App (Flutter Clean Architecture)  
**Performance Goals**: Renderizado a 60 fps sin bloqueos de UI; inscripción, retiro y traslado de grupo con recálculo de clasificación en $<50\text{ ms}$  
**Constraints**: Offline-first, 0 errores/advertencias en `flutter analyze`, UI 100% en español vía `l10n`, código técnico en inglés  
**Scale/Scope**: Múltiples competiciones activas con hasta 32 equipos y entre 2 y 8 grupos por torneo

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: **PASS** — La especificación (`spec.md`) fue definida y validada a partir de la HU 15.4 de Notion antes de iniciar la planificación técnica.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: **PASS** — Se extiende `TournamentTeam` con `groupName` opcional retrocompatible y se sincroniza `StandingsCalculatorService.calculateGroupStageTables` para reflejar los grupos asignados de forma determinista.
- **III. Pruebas Automatizadas como Puerta de Calidad**: **PASS** — Se contemplan pruebas unitarias para `TournamentTeam`, `StandingsCalculatorService`, `ManageTeamsEligibilityUseCase` y `TeamsController`, y pruebas de widgets para `CompetitionDetailScreen`, `CompetitionTeamsTabView`, `CompetitionEnrollTeamDialog` y viewport compacto ($320 \times 640\text{ px}$ @ $130\%$).
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: **PASS** — Las entidades y cálculo de tablas permanecen en `domain/`, los casos de uso y controladores en `application/`, la persistencia en `infrastructure/` y los widgets en `presentation/`.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: **PASS** — Solo `UserRole.organizer` (`RoleCapability.manageTournaments`) en torneos editables (`status.isEditable`) puede agregar equipos desde el FAB, trasladar de grupo o retirar equipos; los demás roles visualizan la pestaña en modo lectura.
- **VI. Convenciones de Idioma y Nomenclatura**: **PASS** — Código técnico, identificadores y tests en inglés; textos de interfaz en español centralizados en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: **PASS** — Bloqueo *single-flight* (`isSaving`) durante mutaciones, diálogos de confirmación para acciones destructivas y `TabBar` compacto sin `RenderFlex overflow` a $320 \times 640\text{ px}$ con texto al $130\%$.

## Project Structure

### Documentation (this feature)

```text
specs/027-competition-teams-management/
├── plan.md                                        # Plan técnico de implementación
├── research.md                                    # Decisiones de diseño y arquitectura (Phase 0)
├── data-model.md                                  # Modelo de datos y transiciones de grupo (Phase 1)
├── quickstart.md                                  # Guía de validación funcional y comandos (Phase 1)
├── contracts/
│   └── ui-competition-teams-contracts.md          # Contratos de Widget Keys, casos de uso y l10n
└── tasks.md                                       # Lista de tareas ordenadas (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                 # Claves de localización para pestaña Equipos, FAB, diálogos y grupos
│   ├── app_localizations.dart                     # Generado por flutter gen-l10n
│   └── app_localizations_es.dart                  # Generado por flutter gen-l10n
├── domain/
│   ├── entities/
│   │   └── tournament_team.dart                   # Campo opcional groupName + serialización JSON
│   ├── repositories/
│   │   └── teams_repository.dart                  # Contrato deleteTeam(String teamId)
│   └── services/
│       └── standings_calculator_service.dart      # Respeto de team.groupName en calculateGroupStageTables
├── infrastructure/
│   └── repositories/
│       └── local_teams_repository.dart            # Implementación de deleteTeam(String teamId)
├── application/
│   ├── use_cases/
│   │   └── manage_teams_eligibility_use_case.dart # enrollTeamInCompetition, removeTeamFromCompetition, moveTeamToGroup
│   └── controllers/
│       └── teams_controller.dart                  # Acciones reactivas enrollTeamInCompetition, removeTeamFromCompetition, moveTeamToGroup
└── presentation/
    └── tournaments/
        ├── competition_detail_screen.dart         # FAB option competition_detail_fab_add_team y 4ta pestaña Equipos
        └── widgets/
            ├── competition_teams_tab_view.dart    # Pestaña de equipos inscritos con retiro y traslado de grupo
            └── competition_enroll_team_dialog.dart # Diálogo para inscribir equipo nuevo o existente con grupo

test/
├── unit/
│   ├── domain/
│   │   └── standings_calculator_service_test.dart # Tests unitarios de tablas por grupo respetando team.groupName
│   └── application/
│       ├── manage_teams_eligibility_use_case_test.dart # Tests unitarios de inscripción, retiro y traslado de grupo
│       └── teams_controller_test.dart             # Tests de estado en TeamsController
└── presentation/
    └── tournaments/
        ├── competition_detail_screen_test.dart    # Tests del FAB Menu (Agregar Equipo) y TabBar de 4 pestañas
        └── competition_teams_tab_view_test.dart   # Tests de widgets para Equipos inscritos, retiro, traslado de grupo y 320x640 @ 130%
```

**Structure Decision**: Se preserva la estructura modular por capas de `vifutbol`, añadiendo los nuevos widgets de la pestaña y diálogo bajo `lib/presentation/tournaments/widgets/` y extendiendo limpiamente `TournamentTeam`, `TeamsRepository`, `ManageTeamsEligibilityUseCase`, `TeamsController` y `StandingsCalculatorService`.

## Complexity Tracking

> No existen violaciones a la Constitución; no se requiere justificación de complejidad adicional.
