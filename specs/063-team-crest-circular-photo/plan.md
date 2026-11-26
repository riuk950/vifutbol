# Plan de Implementación: Carga de Foto del Escudo del Equipo con Visualización Circular en Toda la App (HU 27.3)

**Branch**: `063-team-crest-circular-photo` | **Fecha**: 2026-11-26 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/063-team-crest-circular-photo/spec.md)

**Input**: Especificación funcional desde `/specs/063-team-crest-circular-photo/spec.md` (Notion HU 27.3).

## Summary

Implementar la carga/captura opcional de fotografía del escudo del equipo con validación de formato (`JPEG`, `PNG`, `WebP`) y tamaño (≤ 5 MB), almacenamiento en Supabase Storage (`team-crests`, lectura pública y escritura por propietario autenticado), persistencia en `vifutboldev.teams.crest_url` y cache local Hive con continuidad offline-first (si falla la subida temporalmente o sin red, guarda la ruta local para visualización inmediata y reintento al sincronizar), y unificación 100% circular en `KickPulseTeamCrest` (recorte circular `ClipOval` + `BoxFit.cover` + borde en colores distintivos, y fallback circular `TeamCrestShape.circle` con monograma) propagada a todas las pantallas de la app.

## Technical Context

**Language/Version**: Dart 3.x / Flutter SDK + PostgreSQL (Supabase SQL migrations & Storage RLS)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `image_picker`, `hive_flutter`, `flutter_localizations` (`app_es.arb`), Design System `KickPulse`  
**Storage**: Supabase PostgreSQL (`vifutboldev.teams.crest_url`), Supabase Storage bucket `team-crests` (público en lectura, RLS por `auth.uid()` en escritura, límite 5 MB), cache local Hive  
**Testing**: `flutter_test` + `mocktail` (unit tests de entidad/storage y widget tests de `KickPulseTeamCrest` y `CreateTeamScreen`)  
**Target Platform**: Android e iOS (Flutter mobile)  
**Project Type**: Mobile app (Clean Architecture: `domain`, `application`, `infrastructure`, `presentation`)  
**Performance Goals**: Renderizado circular a 60 fps sin distorsión; validación de tamaño/formato instantánea antes de subir  
**Constraints**: UI 100% en español (`lib/l10n/app_es.arb`), formato circular unificado en toda la app (nuevos y existentes), continuidad offline-first ante fallas temporales de subida, manejo resiliente de permisos cámara/galería sin perder datos del formulario, bloqueo `single-flight`  
**Scale/Scope**: 1 migración SQL idempotente (`crest_url` + bucket `team-crests` + políticas RLS), extensión de `DocumentStorageRepository`/`SupabaseDocumentStorageRepository`, propagación de `crestUrl` en entidades/repositorios/calculadores, actualización de `KickPulseTeamCrest` y sus puntos de uso en la app, integración del selector circular en `CreateTeamScreen`, localización en `app_es.arb` y 3 suites de pruebas.

## Constitution Check

*GATE: Verificado previo a Phase 0 y revalidado tras Phase 1.*

- **Clean Architecture & Separación de Capas**: Cumple. Contrato de storage y entidades en `domain`, orquestación en `application`, adaptadores Supabase/Hive en `infrastructure` y widgets en `presentation`.
- **Idioma (Código en inglés / UI 100% en español)**: Cumple. Identificadores y pruebas en inglés; textos visibles centralizados en `lib/l10n/app_es.arb`.
- **Seguridad (RLS en Storage)**: Cumple. `team-crests` restringe `INSERT`/`UPDATE`/`DELETE` al propietario autenticado (`auth.uid()`) y limita tamaño a 5 MB y MIME types a JPEG/PNG/WebP.
- **Directrices Móviles (`docs/MOBILE_GUIDELINES.md`)**: Cumple. Continuidad offline-first, manejo resiliente de permisos, prevención `single-flight`, fallback sin errores visuales y accesibilidad.
- **Sin violaciones detectadas**: No se requiere entrada en `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/063-team-crest-circular-photo/
├── plan.md                             # Este archivo (/speckit-plan)
├── research.md                         # Decisiones técnicas (Phase 0)
├── data-model.md                       # Esquema crest_url, bucket team-crests y entidades (Phase 1)
├── quickstart.md                       # Guía de validación automatizada y manual (Phase 1)
├── contracts/
│   └── team-crest-contracts.md         # Contratos Storage, repositorios y UI keys (Phase 1)
├── checklists/
│   └── requirements.md                 # Checklist de calidad de spec (16/16)
└── tasks.md                            # Generado por /speckit-tasks (Phase 2)
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611260003_team_crest_url_and_bucket.sql                     # [NEW] crest_url en teams + bucket team-crests + RLS

lib/
├── domain/
│   ├── entities/
│   │   ├── tournament_team.dart                                   # [MODIFY] Agregar crestUrl
│   │   ├── team_directory_item.dart                               # [MODIFY] Agregar crestUrl
│   │   └── standings_table.dart                                   # [MODIFY] Agregar crestUrl en StandingsRow
│   ├── repositories/
│   │   └── document_storage_repository.dart                       # [MODIFY] Agregar uploadTeamCrest(...)
│   └── services/
│       └── standings_calculator_service.dart                      # [MODIFY] Propagar team.crestUrl a StandingsRow
├── application/
│   ├── controllers/
│   │   └── teams_controller.dart                                  # [MODIFY] Aceptar crestUrl en createTeam
│   ├── providers/
│   │   └── teams_providers.dart                                   # [MODIFY] Propagar crestUrl
│   └── use_cases/
│       └── manage_teams_eligibility_use_case.dart                 # [MODIFY] Propagar crestUrl al inscribir/guardar
├── infrastructure/
│   ├── storage/
│   │   └── supabase_document_storage_repository.dart              # [MODIFY] Implementar uploadTeamCrest con validación ≤5 MB y MIME
│   └── repositories/
│       ├── local_teams_repository.dart                            # [MODIFY] Propagar crestUrl en directorio/Hive
│       └── hybrid_teams_repository.dart                           # [MODIFY] Persistir/hidratar crest_url + subida offline-first
├── presentation/
│   ├── teams/
│   │   ├── create_team_screen.dart                                # [MODIFY] Selector circular Subir/Cambiar/Quitar escudo + permisos + offline-first
│   │   ├── team_detail_screen.dart                                # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │   ├── team_roster_detail_screen.dart                         # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │   ├── coach_lineup_tracking_screen.dart                      # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │   └── widgets/
│   │       ├── kick_pulse_team_crest.dart                         # [MODIFY] Renderizado 100% circular (foto ClipOval + fallback circle)
│   │       ├── team_info_tab_view.dart                            # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │       └── tournament_teams_section.dart                      # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   ├── directories/
│   │   └── teams_directory_screen.dart                            # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   ├── tournaments/widgets/
│   │   ├── competition_teams_tab_view.dart                        # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │   └── add_teams_to_competition_modal.dart                    # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   ├── matches/
│   │   ├── digital_match_report_screen.dart                       # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │   └── widgets/
│   │       ├── match_card.dart                                    # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   │       └── match_center_card.dart                             # [MODIFY] Pasar crestUrl a KickPulseTeamCrest
│   └── standings/                                                 # [MODIFY] Propagar crestUrl en tabla de posiciones si muestra escudo
└── l10n/
    └── app_es.arb                                                 # [MODIFY] Textos en español para escudo del equipo

test/
├── unit/
│   └── team_crest_storage_test.dart                               # [NEW] Pruebas unitarias de entidad crestUrl y validación/uploadTeamCrest
└── widget/
    ├── kick_pulse_team_crest_test.dart                            # [NEW] Pruebas de widget de renderizado circular (foto local/remota y fallback circular)
    └── create_team_screen_test.dart                               # [MODIFY] Ampliar con subida/cambio/eliminación de escudo, permisos, archivo inválido y offline-first
```

**Structure Decision**: Se reutiliza integralmente `KickPulseTeamCrest` como punto único de renderizado circular en toda la app y `SupabaseDocumentStorageRepository` para gestionar la subida al bucket público `team-crests`.

## Complexity Tracking

*Sin violaciones a la Constitución; no se requieren excepciones.*
