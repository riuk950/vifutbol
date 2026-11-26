# Plan de Implementación: Nueva Página de Registro Detallado de Equipo (HU 27.2)

**Branch**: `062-team-registration-screen` | **Fecha**: 2026-11-26 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/062-team-registration-screen/spec.md)

**Input**: Especificación funcional desde `/specs/062-team-registration-screen/spec.md` (Notion HU 27.2).

## Summary

Migrar la creación de equipos del diálogo modal básico (`CreateTeamDialog`) a una página dedicada a pantalla completa (`CreateTeamScreen` en `/teams/create`) con vista previa en vivo del club, auto-sugerencia editable de sigla (2–4 caracteres), delegado obligatorio (≥ 1 carácter, iniciando vacío), fecha de creación obligatoria (DatePicker en español ≤ hoy), selector visual de paleta curada con colores primario y secundario distintos entre sí, inscripción opcional a torneo, bloqueo `single-flight`, control de roles (`Entrenador`/`Organizador`) y confirmación `PopScope` de cambios sin guardar. Ampliar `vifutboldev.teams` (`delegate_name`, `founded_date`), entidades (`TournamentTeam`, `TeamDirectoryItem`), caso de uso, controlador y repositorios (`LocalTeamsRepository` + `HybridTeamsRepository` offline-first), y mostrar los nuevos campos institucionales en `TeamInfoTabView` con respaldo elegante para equipos previos.

## Technical Context

**Language/Version**: Dart 3.x / Flutter SDK + PostgreSQL (Supabase SQL migrations)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `hive_flutter`, `fluro` (`AppRouter`), `flutter_localizations` (`app_es.arb`), Design System `KickPulse` (`KickPulseTeamCrest`, `KickPulseCard`, `KickPulseButton`)  
**Storage**: Supabase PostgreSQL (`vifutboldev.teams`, `vifutboldev.tournament_teams`) + cache/cola local Hive (`LocalTeamsRepository` / `HybridTeamsRepository`)  
**Testing**: `flutter_test` + `mocktail` (pruebas unitarias de entidad/use-case/repositorio y pruebas de widget para `CreateTeamScreen`, navegación desde Panel/Directorio y `TeamInfoTabView`)  
**Target Platform**: Android e iOS (Flutter mobile)  
**Project Type**: Mobile app (Clean Architecture: `domain`, `application`, `infrastructure`, `presentation`)  
**Performance Goals**: Actualización en vivo de vista previa de identidad en < 16 ms (60 fps); guardado local offline-first inmediato  
**Constraints**: UI 100% en español (`lib/l10n/app_es.arb`), `single-flight` en guardado, acceso restringido a Entrenador/Organizador, compatibilidad total con equipos históricos sin `delegate_name`/`founded_date`, manejo de teclado y accesibilidad con escalado de fuente  
**Scale/Scope**: 1 migración SQL idempotente, actualización de entidades/use-case/controller/repositorios, 1 nueva pantalla dedicada (`CreateTeamScreen`), actualización de ruta y 2 puntos de entrada (`CoachPanelContent`, `TeamsDirectoryScreen`), actualización de `TeamInfoTabView`, localización en `app_es.arb` y 3 suites de pruebas.

## Constitution Check

*GATE: Verificado previo a Phase 0 y revalidado tras Phase 1.*

- **Clean Architecture & Separación de Capas**: Cumple. Entidades en `domain`, validación de negocio en `application` (`ManageTeamsEligibilityUseCase`, `TeamsController`), persistencia offline-first en `infrastructure` (`LocalTeamsRepository`, `HybridTeamsRepository`) y UI en `presentation`.
- **Idioma (Código en inglés / UI 100% en español)**: Cumple. Identificadores y pruebas en inglés; todos los textos visibles centralizados en `lib/l10n/app_es.arb`.
- **Seguridad y Control de Roles**: Cumple. Restringido a `UserRole.coach` y `UserRole.organizer` en UI y dominio.
- **Directrices Móviles (`docs/MOBILE_GUIDELINES.md`)**: Cumple. Scroll cómodo con teclado, confirmación de cambios sin guardar (`PopScope`), bloqueo `single-flight`, soporte offline-first y accesibilidad.
- **Sin violaciones detectadas**: No se requiere entrada en `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/062-team-registration-screen/
├── plan.md                                # Este archivo (/speckit-plan)
├── research.md                            # Decisiones técnicas (Phase 0)
├── data-model.md                          # Esquema teams, entidades y validaciones (Phase 1)
├── quickstart.md                          # Guía de validación automatizada y manual (Phase 1)
├── contracts/
│   └── team-registration-contracts.md     # Contratos persistencia, controlador, rutas y UI keys (Phase 1)
├── checklists/
│   └── requirements.md                    # Checklist de calidad de spec (16/16)
└── tasks.md                               # Generado por /speckit-tasks (Phase 2)
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611260002_teams_delegate_and_founded_date.sql       # [NEW] Columnas delegate_name y founded_date en vifutboldev.teams

lib/
├── domain/
│   ├── entities/
│   │   ├── tournament_team.dart                           # [MODIFY] Agregar delegateName y foundedDate
│   │   └── team_directory_item.dart                       # [MODIFY] Agregar delegateName y foundedDate
│   └── failures/
│       └── app_failure.dart                               # [MODIFY] Códigos de validación para fecha futura / colores iguales si aplica
├── application/
│   ├── controllers/
│   │   └── teams_controller.dart                          # [MODIFY] Extender createTeam con delegateName, foundedDate, primaryColorHex, secondaryColorHex
│   ├── providers/
│   │   └── teams_providers.dart                           # [MODIFY] Propagar delegateName y foundedDate en proyecciones
│   └── use_cases/
│       └── manage_teams_eligibility_use_case.dart         # [MODIFY] Validar fecha ≤ hoy, primario ≠ secundario, recortar delegateName y propagar en inscripción
├── infrastructure/repositories/
│   ├── local_teams_repository.dart                        # [MODIFY] Persistir/proyectar delegateName y foundedDate en Hive
│   └── hybrid_teams_repository.dart                       # [MODIFY] Persistir/leer delegate_name y founded_date en Supabase + offline-first
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                                # [MODIFY] Registrar ruta /teams/create → CreateTeamScreen
│   ├── panel/widgets/
│   │   └── coach_panel_content.dart                       # [MODIFY] Navegar a /teams/create en lugar de CreateTeamDialog
│   ├── directories/
│   │   └── teams_directory_screen.dart                    # [MODIFY] Navegar a /teams/create en lugar de CreateTeamDialog
│   └── teams/
│       ├── create_team_screen.dart                        # [NEW] Página dedicada de registro detallado de equipo
│       └── widgets/
│           └── team_info_tab_view.dart                    # [MODIFY] Mostrar Delegado y Fecha de creación en ficha del club
└── l10n/
    └── app_es.arb                                         # [MODIFY] Claves localizadas en español

test/
├── unit/
│   └── team_registration_detailed_test.dart               # [NEW] Pruebas unitarias de entidades, validaciones y serialización
└── widget/
    ├── create_team_screen_test.dart                       # [NEW] Pruebas de widget de CreateTeamScreen (preview en vivo, paleta, validaciones, single-flight, PopScope, roles)
    └── team_info_tab_view_detailed_test.dart              # [NEW] Pruebas de widget de TeamInfoTabView (delegado, fecha, colores, equipos legados) y navegación desde Panel/Directorio
```

**Structure Decision**: Se mantiene la arquitectura Clean existente del repositorio Flutter + Supabase + Hive, integrando `CreateTeamScreen` en `lib/presentation/teams/` y actualizando los flujos existentes de forma retrocompatible.

## Complexity Tracking

*Sin violaciones a la Constitución; no se requieren excepciones.*
