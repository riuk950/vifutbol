# Implementation Plan: Panel del Árbitro — Lista de Partidos Asignados y Gestión Completa hasta el Cierre

**Branch**: `059-referee-panel-match-management` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/059-referee-panel-match-management/spec.md`

## Summary

Completar e integrar de extremo a extremo la operación arbitral desde el Panel del Árbitro hasta el cierre oficial del acta digital:
1. **Resolución multi-torneo y presentación rica en `RefereePanelContent`**: Convertir `RefereePanelContent` en un panel reactivo con carga inicial y `RefreshIndicator` que invoca `MatchesCatalogController.loadAllMatches()` y carga metadatos de torneos/equipos/sedes (con caché local offline-first). Emparejar designaciones usando `{user.roleProfile?.linkedRefereeId, user.id}` (resolviendo también por coincidencia de `MatchReferee` si es necesario). Mostrar en cada tarjeta nombres reales de equipos, torneo, jornada, fecha/hora formateada en zona horaria de Colombia (`ColombiaTimeUtils`), sede/cancha, marcador cuando aplique y badge en español (`Programado`, `En juego`, `Finalizado`). Aplicar ordenamiento operativo (`En juego` → `Programado` ascendente → `Finalizado` descendente) y chips de filtro (`Todos`, `En juego`, `Programados`, `Finalizados`). Al regresar de `DigitalMatchReportScreen`, refrescar automáticamente el catálogo de partidos.
2. **Gestión completa del acta digital (`DigitalMatchReportScreen`, `DigitalMatchReportController`, `ManageDigitalMatchReportUseCase`)**:
   - Cumplir la propiedad de acceso (`FR-009`): permitir edición/cierre únicamente al árbitro asignado al partido (`match.refereeId == actorRefereeId || match.refereeId == actorUserId`) o a un `Organizador` autorizado; mostrar aviso claro en español en modo solo lectura si otro árbitro abre el partido.
   - Soportar respaldo de plantilla inscrita sin bloquear el inicio del partido (`FR-005` / Clarificación Q2): exponer indicadores de convocatoria no confirmada (`homeConvocationConfirmed`, `awayConvocationConfirmed`) en `DigitalMatchReportState` y mostrar un banner informativo no bloqueante cuando algún equipo use la plantilla inscrita como respaldo.
   - Agregar soporte de **observaciones arbitrales del partido** (`refereeObservations` en `DigitalMatchReport` + persistencia local/remota) editable mientras el acta no esté cerrada y visible en solo lectura tras el cierre.
   - Reforzar bloqueo `single-flight` (`if (state.isSubmitting) return false;`) en todas las mutaciones del controlador (`transitionPeriod`, `recordGoal`, `recordCard`, `recordSubstitution`, `removeEvent`, `updateObservations`, `closeReport`, `synchronizeOfflineQueue`) y persistir los cambios del partido tanto en local como en Supabase (via `HybridTournamentMatchesRepository` / `HybridMatchReportsRepository` + `SyncOutbox`).

## Technical Context

**Language/Version**: Dart 3.x / Flutter (Mobile iOS & Android) + PostgreSQL 17 (Supabase `vifutboldev` schema)

**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `hive`, `flutter_localizations` (`lib/l10n/app_es.arb`), `KickPulse` Design System (`DESIGN.md`)

**Storage**:
- Remoto: Supabase (`vifutboldev.matches`, `vifutboldev.match_reports`, `vifutboldev.match_events`, `vifutboldev.match_referees`, `vifutboldev.tournaments`, `vifutboldev.tournament_teams`).
- Local: Hive (`LocalTournamentMatchesRepository`, `LocalMatchReportsRepository`, `HiveSyncOutboxRepository`) con sincronización híbrida offline-first (`HybridTournamentMatchesRepository`, `HybridMatchReportsRepository`).

**Testing**: `flutter test` (pruebas unitarias para filtrado/ordenamiento por `linkedRefereeId`, propiedad arbitral, observaciones, transiciones y cierre; pruebas de widget para `RefereePanelContent` y `DigitalMatchReportScreen`) y `flutter analyze`.

**Target Platform**: Android & iOS (Flutter mobile app).

**Project Type**: Mobile app (Clean Architecture: `domain`, `application`, `infrastructure`, `presentation`).

**Performance Goals**: Renderizado a 60 fps; carga de partidos asignados <2s online y lectura inmediata desde caché local offline.

**Constraints**:
- Offline-first real: inicio, eventos, observaciones y cierre se guardan localmente de inmediato y se sincronizan vía outbox al recuperar conectividad sin duplicados.
- `single-flight` en todas las acciones críticas.
- Código técnico y pruebas en inglés; UI 100% en español centralizado en `lib/l10n/app_es.arb`.

**Scale/Scope**: 1 migración SQL opcional/idempotente para columna `referee_observations text` en `vifutboldev.match_reports`, actualización de entidad/repositorios de actas, actualización de `RefereePanelContent`, `DigitalMatchReportController`, `ManageDigitalMatchReportUseCase` y `DigitalMatchReportScreen`, ~16 claves nuevas en `app_es.arb`, y cobertura con pruebas unitarias y de widget.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (SDD)**: PASS — `spec.md` y clarificaciones (`2026-11-25`) cerradas y validadas (16/16 en `checklists/requirements.md`).
- **II. Integridad de Datos y Fuente de Verdad Transparente**: PASS — Eventos, marcador, observaciones y cierre se persisten consistentemente en `match_reports` y `matches` (local + nube), disparando actualización de tabla/llaves al cierre.
- **III. Pruebas Automatizadas como Puerta de Calidad**: PASS — Plan cubre pruebas unitarias (emparejamiento `linkedRefereeId`, ordenamiento, propiedad arbitral, observaciones, transiciones y cierre) y de widget (`RefereePanelContent`, `DigitalMatchReportScreen`).
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: PASS — Reglas de emparejamiento, ordenamiento y autorización residen en dominio/casos de uso; widgets consumen estado Riverpod sin acceso directo a Supabase.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: PASS — Validación estricta de árbitro asignado u organizador; uso de tokens `KickPulse*`.
- **VI. Convenciones de Idioma y Nomenclatura**: PASS — Código y pruebas en inglés; textos visibles en español vía `AppLocalizations`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: PASS — Offline-first, pull-to-refresh con caché preservada ante error, `single-flight`, preservación de estado en segundo plano, accesibilidad y formato de hora Colombia.

**Post-Design Re-check**: PASS — Sin violaciones ni excepciones de complejidad.

## Project Structure

### Documentation (this feature)

```text
specs/059-referee-panel-match-management/
├── plan.md                                  # Este archivo
├── research.md                              # Decisiones técnicas y hallazgos del código base
├── data-model.md                            # Esquema de datos, ordenamiento y transiciones
├── quickstart.md                            # Guía de verificación end-to-end
├── contracts/
│   └── referee_panel_match_contract.md      # Contratos de filtrado, autorización, UI keys y l10n
└── checklists/
    └── requirements.md                      # Checklist de calidad de especificación
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611250004_match_report_referee_observations.sql      # Columna idempotente referee_observations en match_reports

lib/
├── l10n/
│   ├── app_es.arb                                          # Claves en español para Panel del Árbitro y acta
│   ├── app_localizations.dart                              # Generado por flutter gen-l10n
│   └── app_localizations_es.dart                           # Generado por flutter gen-l10n
├── domain/
│   ├── entities/
│   │   ├── digital_match_report.dart                       # Campo refereeObservations + JSON/copyWith
│   │   └── digital_match_report_state.dart                 # Flags homeConvocationConfirmed / awayConvocationConfirmed
│   └── services/
│       └── referee_assigned_matches_service.dart           # Servicio puro de emparejamiento (linkedRefereeId/userId), ordenamiento y filtro
├── application/
│   ├── use_cases/
│   │   └── manage_digital_match_report_use_case.dart       # Propiedad arbitral (assigned referee / organizer) + updateObservations
│   └── controllers/
│       └── digital_match_report_controller.dart            # Single-flight en mutaciones, flags de convocatoria, updateObservations, ownership
├── infrastructure/
│   └── repositories/
│       └── hybrid_match_reports_repository.dart            # Mapeo de referee_observations en PostgREST
└── presentation/
    ├── panel/widgets/
    │   └── referee_panel_content.dart                      # Carga multi-torneo, nombres reales, hora Colombia, filtros, ordenamiento, RefreshIndicator
    └── matches/
        └── digital_match_report_screen.dart                # Banner de propiedad, aviso convocatoria respaldo, sección observaciones arbitrales

test/
├── domain/services/
│   └── referee_assigned_matches_service_test.dart          # Pruebas unitarias de emparejamiento, ordenamiento y filtros
├── application/use_cases/
│   └── manage_digital_match_report_use_case_test.dart      # Pruebas de propiedad arbitral, observaciones y ciclo completo
└── presentation/
    ├── panel/
    │   └── referee_panel_content_test.dart                 # Pruebas de widget del Panel del Árbitro
    └── matches/
        └── digital_match_report_screen_test.dart           # Pruebas de widget de inicio, eventos, observaciones, cierre, offline y propiedad
```

**Structure Decision**: Se añade un servicio de dominio puro (`RefereeAssignedMatchesService`) para aislar y probar unitariamente el emparejamiento por `linkedRefereeId`/`userId`, el ordenamiento operativo y el filtrado por estado, reutilizando los repositorios híbridos offline-first y el acta digital existentes.

## Complexity Tracking

Sin violaciones a la Constitución; no se requieren excepciones.
