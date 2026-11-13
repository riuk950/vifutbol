# Implementation Plan: Arquitectura Offline-First, Sincronización en la Nube (vifutboldev) e Indicador de Estado de Datos en el AppBar

**Branch**: `038-offline-first-cloud-sync` | **Date**: 2026-11-11 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/spec.md)

**Input**: Feature specification from [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/038-offline-first-cloud-sync/spec.md)

## Summary

Implementar arquitectura híbrida **Offline-First** conectada al esquema `vifutboldev` en Supabase (entorno DEV) para los 10 repositorios de dominio existentes (`TournamentsRepository`, `VenuesRepository`, `TeamsRepository`, `TournamentMatchesRepository`, `LineupsTrackingRepository`, `MatchReportsRepository`, `MatchAlertsRepository`, `TournamentNewsRepository`, `SeasonHonorRollRepository` y `FanFavoritesRepository`), respaldada por caché local en Hive, una cola persistente FIFO (`HiveSyncOutboxRepository`) aislada por `ownerUserId`, y un servicio centralizado idempotente (`CloudSyncService`) con mutex *single-flight*. En presencia de red (`NetworkConnectionStatus.connected`), las escrituras de usuarios autenticados ejecutan primero Supabase (remote-first) y actualizan la caché local sin encolar ítems innecesarios; ante pérdida de red o error transitorio guardan inmediatamente en Hive y encolan en el outbox. Rechazos no transitorios 4xx marcan únicamente el ítem afectado en estado `error` sin bloquear el resto de la cola FIFO. En presentación, `AppShellScreen` incorpora `SyncStatusAppBarAction` + `SyncStatusBottomSheet` visibles exclusivamente para los roles operativos `{organizer, coach, referee}`, además de un diálogo de protección de salida en `ProfileTabView` cuando existen cambios pendientes (`pendingSyncCount > 0`).

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter (Material 3)  
**Primary Dependencies**: `flutter_riverpod ^2.6.1`, `supabase_flutter ^2.18.3`, `hive ^2.2.3`, `hive_flutter ^1.1.0`, `connectivity_plus ^6.1.4`, `uuid ^4.5.1`, `clock ^1.1.2`, `intl`, `flutter_localizations`  
**Storage**: Hive (`LocalStorageRepository`, prefijo de entorno `vifutbol_dev_*`) + Supabase PostgreSQL (`vifutboldev` schema, 18 tablas con RLS y FKs indexadas)  
**Testing**: `flutter test`, `mocktail ^1.0.4`, `fake_async ^1.3.1`, `flutter analyze`, `dart format`  
**Target Platform**: Android / iOS (probado en emulador Android `emulator-5554` contra Supabase DEV self-hosted)  
**Project Type**: Mobile app (Flutter Clean Architecture: `domain/`, `infrastructure/`, `application/`, `presentation/`)  
**Performance Goals**: Escritura local inmediata offline (`< 100ms` perceived latency), reconexión con drenaje automático FIFO en `<= 5s` (`SC-004`), UI a 60 fps sin bloquear el hilo principal durante sincronización masiva  
**Constraints**: Pureza de `domain/` (sin imports de `supabase_flutter` o `hive`), targets táctiles `>= 48x48` (`>= 44px`), soporte `textScaler` `130%`, cues de estado accesibles más allá del color, textos UI 100% vía `lib/l10n/app_es.arb`, invitados (`isGuestFan`) estrictamente locales  
**Scale/Scope**: 10 repositorios de dominio híbridos sobre 18 tablas `vifutboldev`, 1 servicio central de sincronización + outbox Hive, 1 controlador reactivo + barra superior + bottom sheet + guard de cierre de sesión, 100% cobertura de tests unitarios y de widget

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación Pre-Research | Evaluación Post-Design | Estado |
| :--- | :--- | :--- | :--- |
| **I. La Spec Manda** | Todos los requisitos `FR-001`–`FR-011`, `SC-001`–`SC-004` y clarificaciones Q1–Q3 trazados desde `spec.md`. | Contratos, entidades y flujos cubren 1:1 cada FR y clarificación Q1–Q3 sin alcance huérfano. | **PASS** |
| **II. Integridad de Datos** | UUID v4 determinístico e idempotencia (`upsert` `onConflict: 'id'` + `updated_at` LWW); orden padre->hijo en agregados compuestos. | `SyncOutboxItem` exige `ownerUserId`, `entityId` determinístico, UTC `updated_at` y limpieza FIFO sin duplicados (`SC-002`). | **PASS** |
| **III. Pruebas Automatizadas** | Plan de tests unitarios (outbox FIFO, mutex, Q1–Q3, 10 híbridos) y widget (`AppBar` roles, bottom sheet, sign-out dialog). | Suites ubicadas en `test/unit/` y `test/widget/`; `quickstart.md` define comandos y E2E DEV. | **PASS** |
| **IV. Arquitectura Limpia** | Contratos en `lib/domain/`; Hive/Supabase aislados en `lib/infrastructure/`; Riverpod en `lib/application/`. | Cero dependencias externas en `domain/`; adaptadores híbridos implementan las 10 interfaces sin romper firmas. | **PASS** |
| **V. Segregación de Roles y DESIGN.md** | `RolePermissionMatrix` gobierna visibilidad (`organizer`, `coach`, `referee`) y excluye `player`/`fan`/`guestFan`; paleta KickPulse Dark. | Nuevo `RoleCapability.viewCloudSyncIndicator` + tokens KickPulse (`#00E676`, `#FFB300`, `#FF3D71`) + targets `48x48`. | **PASS** |
| **VI. Inglés técnico / Español UI** | Código/clases/tests en inglés; cadenas UI en `lib/l10n/app_es.arb`. | Todos los símbolos técnicos definidos en inglés y cadenas UI parametrizadas para `app_es.arb`. | **PASS** |
| **VII. Resiliencia y Experiencia Móvil** | Manejo offline-first sin crasheos, fallback silencioso en lecturas/escrituras sin red, cues icono+badge+texto, escalado 130%. | Cero pérdida de datos ante cierre frío (`FR-004`), cierre de sesión protegido (`Q3`) y cola no bloqueante ante errores (`Q2`). | **PASS** |

## Project Structure

### Documentation (this feature)

```text
specs/038-offline-first-cloud-sync/
├── spec.md                              # Especificación funcional y clarificaciones Q1–Q3
├── checklists/
│   └── requirements.md                  # Checklist de calidad de spec (16/16 PASS)
├── plan.md                              # Este archivo (/speckit-plan output)
├── research.md                          # Decisiones arquitectónicas Fase 0
├── data-model.md                        # Entidades de sincronización, estados y claves Hive/vifutboldev
├── quickstart.md                        # Comandos de validación automatizada y guía E2E DEV
├── contracts/
│   └── offline-sync-contracts.md        # Contratos Dart de outbox, CloudSyncService, híbridos y UI
└── tasks.md                             # Output futuro de /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── entities/
│   │   ├── role_permission_matrix.dart          # + RoleCapability.viewCloudSyncIndicator
│   │   ├── sync_status.dart                     # SyncStatus, SyncOutboxOperation, SyncOutboxEntityType, SyncOutboxItemStatus
│   │   └── sync_outbox_item.dart                # SyncOutboxItem, SyncSummaryState, SyncFlushResult
│   ├── repositories/
│   │   └── sync_outbox_repository.dart          # SyncOutboxRepository contract (scoped by ownerUserId)
│   └── services/
│       └── cloud_sync_service.dart              # CloudSyncService contract
├── infrastructure/
│   ├── sync/
│   │   ├── hive_sync_outbox_repository.dart     # Persistent FIFO outbox backed by LocalStorageRepository
│   │   ├── supabase_cloud_sync_service.dart     # Single-flight mutex, reactive reconnect flush, non-blocking 4xx handling
│   │   └── supabase_error_classifier.dart       # Transient vs non-transient 4xx classifier + Spanish error mapper
│   ├── repositories/
│   │   ├── hybrid_tournaments_repository.dart   # + remote data source (tournaments + rule_audit_entries)
│   │   ├── hybrid_teams_repository.dart         # + remote data source (teams + tournament_teams + players)
│   │   ├── hybrid_tournament_matches_repository.dart  # + remote data source (matches + match_referees)
│   │   ├── hybrid_lineups_tracking_repository.dart    # + remote data source (player_internal_trackings + match_lineup_convocations)
│   │   ├── hybrid_match_reports_repository.dart       # + remote data source (digital_match_reports + match_events)
│   │   ├── hybrid_match_alerts_repository.dart        # + remote data source (match_live_alerts)
│   │   ├── hybrid_tournament_news_repository.dart     # + remote data source (tournament_news)
│   │   ├── hybrid_season_honor_roll_repository.dart   # + remote data source (season_honor_rolls)
│   │   └── hybrid_fan_favorites_repository.dart       # + remote data source (fan_favorite_teams)
│   └── venues/
│       └── hybrid_venues_repository.dart        # + remote data source (sports_venues + venue_pitches)
├── application/
│   ├── controllers/
│   │   └── sync_status_controller.dart          # StateNotifier combining auth, connectivity, outbox & flush lock
│   └── providers/
│       ├── sync_providers.dart                  # syncOutboxRepositoryProvider, cloudSyncServiceProvider, syncStatusControllerProvider
│       ├── tournaments_providers.dart           # Conditional Hybrid vs Local selector
│       ├── venues_providers.dart                # Conditional Hybrid vs Local selector
│       ├── teams_providers.dart                 # Conditional Hybrid vs Local selector
│       ├── matches_catalog_providers.dart       # Conditional Hybrid vs Local selector
│       ├── lineups_tracking_providers.dart      # Conditional Hybrid vs Local selector
│       ├── digital_match_report_providers.dart  # Conditional Hybrid vs Local selector
│       ├── tournament_news_providers.dart       # Conditional Hybrid vs Local selector
│       ├── fan_alerts_and_favorites_providers.dart # Conditional Hybrid vs Local selector
│       └── backup_and_season_closure_providers.dart  # Conditional Hybrid vs Local selector
├── l10n/
│   └── app_es.arb                               # Spanish strings for indicator, bottom sheet, error reasons & logout guard
└── presentation/
    ├── shell/
    │   ├── app_shell_screen.dart                # Wire SyncStatusAppBarAction into AppBar.actions
    │   └── tabs/
    │       └── profile_tab_view.dart            # Guard signOut() when pendingSyncCount > 0 (Clarification Q3)
    └── sync/
        ├── sync_status_app_bar_action.dart      # Role-gated AppBar action icon + badge + semantics
        ├── sync_status_bottom_sheet.dart        # Detailed sync tray with retry, discard & manual sync CTA
        └── sign_out_pending_sync_dialog.dart    # 3-option sign-out guard dialog in Spanish

test/
├── unit/
│   ├── domain/
│   │   └── role_permission_matrix_sync_test.dart
│   ├── infrastructure/sync/
│   │   ├── hive_sync_outbox_repository_test.dart
│   │   ├── supabase_cloud_sync_service_test.dart
│   │   └── hybrid_repositories_offline_first_test.dart
│   └── application/
│       └── sync_status_controller_test.dart
└── widget/
    ├── shell/
    │   └── app_bar_sync_indicator_test.dart
    └── sync/
        ├── sync_status_bottom_sheet_test.dart
        └── sign_out_pending_sync_dialog_test.dart
```

**Structure Decision**: Se mantiene la arquitectura limpia en capas por dominio técnico existente (`lib/domain/`, `lib/infrastructure/`, `lib/application/`, `lib/presentation/`), encapsulando los nuevos adaptadores de sincronización y componentes de UI bajo subdirectorios cohesivos (`sync/`) sin romper compatibilidad con repositorios y pruebas locales existentes.

## Complexity Tracking

> Sin violaciones a la Constitución; no se requieren justificaciones de complejidad excepcional.
