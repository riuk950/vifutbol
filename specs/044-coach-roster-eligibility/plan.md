# Implementation Plan: Gestión Integral de Planilla y Habilitación de Equipo desde el Panel Técnico (HU 20.1)

**Branch**: `044-coach-roster-eligibility` | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/044-coach-roster-eligibility/spec.md)

**Input**: Feature specification from `/specs/044-coach-roster-eligibility/spec.md`

## Summary

Implementar el flujo integral de gestión de planilla y habilitación de equipo para el Entrenador (`UserRole.coach`) desde el Panel Técnico (`CoachPanelContent`), conectando el botón **"Gestionar Planilla"** hacia `TeamRosterDetailScreen`, incorporando un sistema de **solicitudes de incorporación** (`TeamJoinRequest`) hacia jugadores registrados con rol `player` (sin registro manual directo), una vista dedicada en **Perfil** para que el jugador acepte o rechace invitaciones, y la validación estricta de cuota mínima (`>= 11` jugadores) que permite al entrenador habilitar su equipo a estado `eligible` para competiciones.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (Null-safe)  
**Primary Dependencies**: `flutter_riverpod` (gestión de estado), `supabase_flutter` (PostgREST & RPCs en esquema `vifutboldev`), `hive` / `LocalStorageRepository` (persistencia offline-first), `uuid`, `flutter_localizations` (`l10n`)  
**Storage**: Local (`LocalStorageRepository` / Hive) + Remoto (PostgreSQL en Supabase self-hosted Oracle Cloud, esquema `vifutboldev` con tabla nueva `team_join_requests` y RPCs `search_registered_players` y `respond_team_join_request`)  
**Testing**: `flutter_test`, `mocktail` (pruebas unitarias de casos de uso/repositorios y pruebas de widgets para Panel Técnico, Planilla y Solicitudes en Perfil)  
**Target Platform**: Android & iOS (móvil responsive, soporte de accesibilidad y escalado de texto)  
**Project Type**: Aplicación móvil Flutter con arquitectura limpia por capas (`domain`, `application`, `infrastructure`, `presentation`)  
**Performance Goals**: Navegación desde Panel Técnico < 300 ms, búsqueda reactiva en catálogo de jugadores < 100 ms, 60 fps en listas  
**Constraints**: Offline-first con manejo de conflictos/duplicados, bloqueo de doble pulsación, zero textos hardcoded (100% `l10n` en español), soporte para clubes base sin torneo (`tournamentId == ''`) y clubes inscritos en torneos  
**Scale/Scope**: Soporte para cientos de jugadores registrados (`players` / `user_accounts`), ~15 archivos modificados/creados más migración SQL en `vifutboldev`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

1. **I. La Spec Manda**: Especificación y clarificaciones completadas antes de diseño/implementación; incorpora `docs/MOBILE_GUIDELINES.md` (estados vacío/carga/error, protección contra doble tap, persistencia offline). ✅ **PASS**
2. **II. Integridad de Datos y Fuente de Verdad**: Índices únicos en `vifutboldev.team_join_requests` (única solicitud `pending` por jugador/equipo y dorsal reservado único) + RPC transaccional `respond_team_join_request` previenen duplicidad y huérfanos. ✅ **PASS**
3. **III. Pruebas Automatizadas como Puerta de Calidad**: Plan incluye pruebas unitarias (cuota `>= 11`, autorización `coach`, envío/aceptación/rechazo de solicitudes, duplicados) y pruebas de widgets (navegación, diálogo de invitación, vista en Perfil, habilitación). ✅ **PASS**
4. **IV. Arquitectura Limpia y Separación de Responsabilidades**: Entidades e interfaces de repositorio en `domain/`, lógica en `application/use_cases` y `controllers`, adaptadores PostgREST/Hive en `infrastructure/`, UI en `presentation/`. ✅ **PASS**
5. **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: Solo `coach` muta plantilla/envía solicitudes y habilita su equipo (`>= 11`); solo `player` acepta/rechaza sus propias invitaciones desde su Perfil; tokens `KickPulse*` respetados. ✅ **PASS**
6. **VI. Convenciones de Idioma y Nomenclatura**: Identificadores/archivos/tests/commits en inglés; textos de interfaz 100% en español vía `lib/l10n/app_es.arb`. ✅ **PASS**
7. **VII. Resiliencia y Experiencia Móvil**: Estados explícitos, single-flight en envío/aceptación/habilitación, soporte offline y layouts responsivos sin overflow. ✅ **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/044-coach-roster-eligibility/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── roster_join_requests_contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Generado por /speckit-tasks
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611170001_team_join_requests.sql

lib/
├── l10n/
│   └── app_es.arb (+ generados)
├── domain/
│   ├── entities/
│   │   ├── team_join_request.dart
│   │   └── available_player_candidate.dart
│   └── repositories/
│       └── team_join_requests_repository.dart
├── application/
│   ├── use_cases/
│   │   ├── manage_teams_eligibility_use_case.dart
│   │   └── manage_team_join_requests_use_case.dart
│   ├── controllers/
│   │   ├── teams_controller.dart
│   │   └── team_join_requests_controller.dart
│   └── providers/
│       └── team_join_requests_providers.dart
├── infrastructure/
│   └── repositories/
│       ├── local_team_join_requests_repository.dart
│       ├── hybrid_team_join_requests_repository.dart
│       └── hybrid_teams_repository.dart
└── presentation/
    ├── navigation/
    │   └── app_router.dart
    ├── panel/widgets/
    │   └── coach_panel_content.dart
    ├── teams/
    │   ├── team_roster_detail_screen.dart
    │   └── widgets/
    │       └── invite_player_to_team_modal.dart
    └── shell/tabs/
        ├── profile_tab_view.dart
        └── player_team_requests_screen.dart

test/
├── unit/application/
│   └── coach_roster_eligibility_test.dart
└── presentation/
    ├── panel/
    │   └── coach_panel_content_test.dart
    ├── teams/
    │   └── team_roster_detail_screen_test.dart
    └── shell/
        └── profile_team_requests_test.dart
```

**Structure Decision**: Se mantiene la arquitectura limpia en capas del proyecto `vifutbol` agregando el subdominio `team_join_requests` en `domain`, `application`, `infrastructure` y `presentation`, además de la migración SQL idempotente en `supabase/migrations/`.

## Complexity Tracking

No existen violaciones a la Constitución; no se requiere justificación adicional.
