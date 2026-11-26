# Tasks: Carga de Foto del Escudo del Equipo con Visualización Circular en Toda la App (HU 27.3)

**Input**: Documentos de diseño en `/specs/063-team-crest-circular-photo/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/team-crest-contracts.md`, `quickstart.md`

**Tests**: Incluidos explícitamente según el checklist técnico de HU 27.3 (pruebas unitarias de storage/entidad y pruebas de widget para `KickPulseTeamCrest` y `CreateTeamScreen`).

**Organization**: Las tareas están organizadas por fase y por Historia de Usuario (US1–US4) para permitir implementación y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencia de tareas incompletas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`, `[US4]`).
- Todas las tareas incluyen la ruta exacta del archivo objetivo.

---

## Phase 1: Setup (Localización en Español)

**Purpose**: Centralizar todos los textos visibles en español para la carga, cambio, eliminación, validaciones y permisos del escudo del equipo.

- [X] T001 Add Spanish localization keys for team crest upload (`Subir escudo`, `Cambiar escudo`, `Quitar escudo`, gallery/camera bottom sheet title & options, file size > 5 MB error, invalid format JPEG/PNG/WebP error, permission denied error, offline crest sync notice) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` (depends on T001)

---

## Phase 2: Foundational (Base de Datos, Storage, Entidades y Repositorios Offline-First)

**Purpose**: Prerrequisitos bloqueantes que habilitan el bucket `team-crests`, la columna `crest_url`, el método `uploadTeamCrest` y la propagación de `crestUrl` en entidades y repositorios.

**⚠️ CRITICAL**: Completar esta fase antes de iniciar las historias de usuario.

- [X] T003 Create idempotent SQL migration in `supabase/migrations/202611260003_team_crest_url_and_bucket.sql` adding nullable `crest_url text` to `vifutboldev.teams`, creating public-read bucket `team-crests` in `storage.buckets` (`file_size_limit = 5242880`, `allowed_mime_types = ['image/jpeg', 'image/png', 'image/webp']`) with 4 owner-scoped write / public-read RLS policies on `storage.objects`, and ending with `NOTIFY pgrst, 'reload schema'`
- [X] T004 [P] Add `uploadTeamCrest({required String userId, required String teamId, required String localPath, String? existingCrestUrl})` contract to `lib/domain/repositories/document_storage_repository.dart` and implement it in `lib/infrastructure/storage/supabase_document_storage_repository.dart` validating allowed extensions (`jpg`, `jpeg`, `png`, `webp`) and max file size (≤ 5 MB) before uploading to `team-crests` bucket
- [X] T005 [P] Add optional `crestUrl` (`String?`) with `copyWith`, `toJson`, and `fromJson` support to `TournamentTeam` in `lib/domain/entities/tournament_team.dart`, `TeamDirectoryItem` in `lib/domain/entities/team_directory_item.dart`, and `StandingsRow` in `lib/domain/entities/standings_table.dart`
- [X] T006 [P] Propagate `crestUrl` across `lib/domain/services/standings_calculator_service.dart`, `lib/application/controllers/teams_controller.dart`, `lib/application/providers/teams_providers.dart`, and `lib/application/use_cases/manage_teams_eligibility_use_case.dart` (defaulting new teams to `TeamCrestShape.circle`)
- [X] T007 [P] Update `LocalTeamsRepository` in `lib/infrastructure/repositories/local_teams_repository.dart` and `HybridTeamsRepository` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` to persist (`'crest_url'`), select/hydrate `crest_url`, and keep offline-first continuity for local crest paths
- [X] T008 [P] Create unit tests in `test/unit/team_crest_storage_test.dart` verifying `TournamentTeam` and `TeamDirectoryItem` `crestUrl` JSON roundtrip, `uploadTeamCrest` rejection of files > 5 MB or unsupported formats (e.g. `.gif`/`.pdf`), and successful upload returning a public URL

**Checkpoint**: Bucket, SQL, storage service, entidades y persistencia offline-first listos y validados con pruebas unitarias.

---

## Phase 3: User Story 3 & User Story 2 — Componente Circular Unificado `KickPulseTeamCrest` y Propagación Global (Priority: P1) 🎯 MVP

**Goal**: Unificar el renderizado 100% circular en `KickPulseTeamCrest` (recorte circular `ClipOval` + `BoxFit.cover` + borde en colores distintivos cuando hay `crestUrl`, y fallback circular `TeamCrestShape.circle` con monograma cuando no hay foto o falla la descarga) y propagar `crestUrl` en todas las vistas de la aplicación.

**Independent Test**: Renderizar `KickPulseTeamCrest` con foto local/remota, sin foto y con ruta/URL rota comprobando siempre geometría circular y fallback sin errores; verificar propagación en directorio, detalle, tabla de posiciones y tarjetas de partido.

### Implementation for User Stories 2 & 3

- [X] T009 [US3] Update `KickPulseTeamCrest` in `lib/presentation/teams/widgets/kick_pulse_team_crest.dart` to accept optional `String? crestUrl`, render valid local/remote images strictly inside a circular border (`ClipOval` + `BoxFit.cover`, `Key('kick_pulse_team_crest_photo')`) framed in the team's distinctive colors, and always fall back to `TeamCrestShape.circle` monogram (`Key('kick_pulse_team_crest_fallback')`) when `crestUrl` is null/empty or fails to load
- [X] T010 [P] [US2] Propagate `crestUrl` into `KickPulseTeamCrest` across team and directory views: `lib/presentation/directories/teams_directory_screen.dart`, `lib/presentation/teams/team_detail_screen.dart`, `lib/presentation/teams/widgets/team_info_tab_view.dart`, `lib/presentation/teams/team_roster_detail_screen.dart`, `lib/presentation/teams/coach_lineup_tracking_screen.dart`, `lib/presentation/teams/widgets/tournament_teams_section.dart`, `lib/presentation/tournaments/widgets/competition_teams_tab_view.dart`, and `lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart`
- [X] T011 [P] [US2] Propagate `crestUrl` into `KickPulseTeamCrest` across match and standings views: `lib/presentation/matches/widgets/match_card.dart`, `lib/presentation/matches/widgets/match_center_card.dart`, `lib/presentation/matches/digital_match_report_screen.dart`, and standings table widgets under `lib/presentation/standings/` (if displaying crests)
- [X] T012 [P] [US3] Create widget tests in `test/widget/kick_pulse_team_crest_test.dart` covering circular photo rendering (`ClipOval` + `BoxFit.cover` with local image file), automatic circular monogram fallback when `crestUrl` is null/empty, automatic circular fallback when image file is missing/broken, and unified circular rendering regardless of legacy `crestShape`

**Checkpoint**: Todos los escudos en toda la app se muestran siempre en circunferencia con foto o respaldo circular.

---

## Phase 4: User Story 1 & User Story 4 — Carga/Captura Circular en `CreateTeamScreen`, Permisos y Continuidad Offline-First (Priority: P1–P2)

**Goal**: Integrar en `CreateTeamScreen` el selector destacado de foto del escudo (galería/cámara) con vista previa circular en vivo, opciones de cambiar/quitar, validación de formato/5 MB, manejo resiliente de permisos en español y continuidad offline-first ante fallas temporales de subida.

**Independent Test**: En `CreateTeamScreen`, pulsar `Subir escudo`, elegir imagen desde galería/cámara (con override de prueba), comprobar vista previa circular con colores distintivos, cambiar/quitar foto, probar permiso denegado y archivo > 5 MB o formato inválido sin perder datos, y guardar con continuidad offline-first cuando falla la subida.

### Implementation for User Stories 1 & 4

- [X] T013 [US1] Add circular crest picker section (`Key('create_team_upload_crest_button')`, `Key('create_team_remove_crest_button')`, gallery/camera bottom sheet with `Key('create_team_crest_source_gallery')` / `Key('create_team_crest_source_camera')`, and optional `crestPickerOverride` for tests) to `lib/presentation/teams/create_team_screen.dart`, updating the live `KickPulseTeamCrest` preview immediately and validating format (`jpg`/`jpeg`/`png`/`webp`) and max size (≤ 5 MB) with Spanish messages while preserving all form inputs
- [X] T014 [US4] Implement resilient camera/gallery permission handling and offline-first crest upload during submit in `lib/presentation/teams/create_team_screen.dart`: attempt `documentStorageRepositoryProvider.uploadTeamCrest(...)` when a local crest is selected; on offline or temporary upload error, fall back to persisting the local crest path so the circular crest renders immediately with a Spanish sync notice, while preserving single-flight submit protection
- [X] T015 [P] [US1] Extend `test/widget/create_team_screen_test.dart` with tests for uploading, replacing, and removing a team crest photo with live circular preview, rejecting > 5 MB or invalid-format files without losing inputs, handling denied camera/gallery permissions in Spanish without losing inputs, and offline-first fallback when cloud upload fails

**Checkpoint**: Ciclo completo de subida, vista previa circular, persistencia offline-first y visualización global verificado.

---

## Phase 5: Polish & Cross-Cutting Verification

**Purpose**: Verificación integral de análisis estático, suite global de pruebas y directrices móviles.

- [X] T016 Run `flutter analyze` and execute targeted and global `flutter test` suites (`test/unit/team_crest_storage_test.dart`, `test/widget/kick_pulse_team_crest_test.dart`, `test/widget/create_team_screen_test.dart`, plus global `flutter test`) per `specs/063-team-crest-circular-photo/quickstart.md`
- [X] T017 Audit Spanish-only UI copy in `lib/l10n/app_es.arb`, touch-target accessibility, and circular clipping without overflow at 130% text scaling across `lib/presentation/teams/create_team_screen.dart` and `lib/presentation/teams/widgets/kick_pulse_team_crest.dart`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Inicia de inmediato (`T001` → `T002`).
- **Phase 2 (Foundational)**: Depende de Phase 1; **bloquea** Phases 3–4. `T003`, `T004`, `T005` en paralelo → `T006`, `T007`, `T008`.
- **Phase 3 (US2 & US3)**: `T009` (`KickPulseTeamCrest`) primero → `T010`, `T011`, `T012` en paralelo.
- **Phase 4 (US1 & US4)**: `T013` → `T014` → `T015` (puede iniciar en paralelo con `T010`/`T011` una vez listo `T009`).
- **Phase 5 (Polish)**: Depende de Phases 1–4 (`T016`, `T017`).

### Implementation Strategy
- **MVP (Phases 1–3)**: Unifica `KickPulseTeamCrest` en circunferencia perfecta en toda la aplicación con soporte de `crestUrl` y almacenamiento `team-crests`.
- **Incremento Final (Phases 4–5)**: Integra el selector de escudo con permisos y continuidad offline-first en `CreateTeamScreen` y valida la suite global.
