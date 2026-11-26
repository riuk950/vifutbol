# Tasks: Nueva Página de Registro Detallado de Equipo (HU 27.2)

**Input**: Documentos de diseño en `/specs/062-team-registration-screen/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/team-registration-contracts.md`, `quickstart.md`

**Tests**: Incluidos explícitamente según el checklist técnico de HU 27.2 (pruebas unitarias y pruebas de widget para `CreateTeamScreen`, navegación desde Panel/Directorio y `TeamInfoTabView`).

**Organization**: Las tareas están organizadas por fase y por Historia de Usuario (US1–US4) para permitir implementación y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencia de tareas incompletas).
- **[Story]**: Historia de usuario asociada (`[US1]`, `[US2]`, `[US3]`, `[US4]`).
- Todas las tareas incluyen la ruta exacta del archivo objetivo.

---

## Phase 1: Setup (Localización en Español)

**Purpose**: Centralizar todos los textos visibles en español para la nueva página de registro de equipo, validaciones, selectores y ficha de detalle.

- [X] T001 Add Spanish localization keys for `CreateTeamScreen` (screen title, subtitle, identity preview header, delegate label/hint/required error, founded date label/hint/required/future-date errors, distinctive colors section title/primary/secondary/same-color error, short code helper, unsaved changes dialog, unauthorized role banner, submit action) and `TeamInfoTabView` (delegate label, founded date label, not-registered fallback) in `lib/l10n/app_es.arb`
- [X] T002 Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` (depends on T001)

---

## Phase 2: Foundational (Base de Datos, Dominio, Aplicación e Infraestructura Offline-First)

**Purpose**: Prerrequisitos bloqueantes que habilitan la persistencia local (Hive) y remota (Supabase) de `delegateName`, `foundedDate`, `primaryColorHex` y `secondaryColorHex`, junto con las validaciones de dominio.

**⚠️ CRITICAL**: Completar esta fase antes de iniciar las historias de usuario.

- [X] T003 Create idempotent SQL migration in `supabase/migrations/202611260002_teams_delegate_and_founded_date.sql` adding nullable columns `delegate_name text` and `founded_date date` to `vifutboldev.teams` and ending with `NOTIFY pgrst, 'reload schema'`
- [X] T004 [P] Add optional `delegateName` (`String?`) and `foundedDate` (`DateTime?`) fields with `copyWith`, `toJson`, and `fromJson` support to `TournamentTeam` in `lib/domain/entities/tournament_team.dart` and `TeamDirectoryItem` in `lib/domain/entities/team_directory_item.dart`
- [X] T005 [P] Add `invalidFoundedDate` and `duplicateTeamColors` error codes (if not already present) to `TeamEligibilityErrorCode` in `lib/domain/failures/app_failure.dart`
- [X] T006 Update `ManageTeamsEligibilityUseCase` in `lib/application/use_cases/manage_teams_eligibility_use_case.dart` to compare duplicate names via `normalizeSearchText` (case-, diacritic-, and whitespace-insensitive), validate that `foundedDate` (when provided) is not after today, validate `primaryColorHex != secondaryColorHex`, trim `delegateName`, and propagate `delegateName` and `foundedDate` during registration and tournament enrollment
- [X] T007 [P] Update `TeamsController.createTeam` in `lib/application/controllers/teams_controller.dart` and team projections in `lib/application/providers/teams_providers.dart` to accept and propagate `delegateName`, `foundedDate`, `primaryColorHex`, and `secondaryColorHex` while remaining backwards-compatible
- [X] T008 [P] Update `LocalTeamsRepository` in `lib/infrastructure/repositories/local_teams_repository.dart` and `HybridTeamsRepository` in `lib/infrastructure/repositories/hybrid_teams_repository.dart` to persist (`upsert` `'delegate_name'` and `'founded_date'` as `YYYY-MM-DD`) and hydrate `delegate_name` and `founded_date` across Hive local cache and Supabase `vifutboldev.teams`
- [X] T009 [P] Create unit tests in `test/unit/team_registration_detailed_test.dart` covering `TournamentTeam` and `TeamDirectoryItem` JSON roundtrip with/without `delegateName` and `foundedDate`, `ManageTeamsEligibilityUseCase` rejection of future `foundedDate`, identical primary/secondary colors, duplicate normalized name, and unauthorized roles, plus valid autonomous and tournament-enrolled creation

**Checkpoint**: Esquema SQL, dominio, validaciones y persistencia offline-first listos y verificados con pruebas unitarias.

---

## Phase 3: User Story 1 — Página Dedicada de Registro Detallado de Equipo (Priority: P1) 🎯 MVP

**Goal**: Reemplazar el diálogo modal básico por una página dedicada a pantalla completa (`/teams/create`) con scroll cómodo, manejo de teclado, auto-sugerencia editable de sigla (2–4 caracteres), delegado obligatorio (≥ 1 carácter, iniciando vacío), fecha de creación (DatePicker en español ≤ hoy), torneo opcional y confirmación `PopScope` de cambios sin guardar.

**Independent Test**: Iniciar sesión como Entrenador u Organizador, pulsar `Crear equipo` en el Panel o Directorio, comprobar navegación a `/teams/create`, auto-sugerencia de sigla editable, selector de fecha en español, selector opcional de torneo y confirmación al salir con cambios sin guardar.

### Implementation for User Story 1

- [X] T010 [US1] Create `CreateTeamScreen` in `lib/presentation/teams/create_team_screen.dart` with KickPulse full-screen scrollable form (`Key('create_team_screen')`), role guard for `UserRole.coach`/`UserRole.organizer`, team name field (`Key('create_team_name_input')`, ≥ 3 chars) with automatic `shortCode` suggestion (2–4 uppercase chars while untouched manually), editable `shortCode` field (`Key('create_team_short_code_input')`), mandatory empty-start `delegateName` field (`Key('create_team_delegate_input')`, ≥ 1 non-space char), mandatory Spanish `showDatePicker` `foundedDate` field (`Key('create_team_founded_date_field')`, `lastDate: DateTime.now()`), optional open-registration tournament selector (`Key('create_team_tournament_dropdown')`), and `PopScope` unsaved-changes confirmation dialog in Spanish
- [X] T011 [P] [US1] Register `/teams/create` route handler pointing to `CreateTeamScreen` in `lib/presentation/navigation/app_router.dart`
- [X] T012 [US1] Update entry points in `lib/presentation/panel/widgets/coach_panel_content.dart` and `lib/presentation/directories/teams_directory_screen.dart` to navigate to `/teams/create` instead of opening `CreateTeamDialog`

**Checkpoint**: Entrenadores y Organizadores navegan a la nueva página dedicada desde el Panel y el Directorio.

---

## Phase 4: User Story 2 — Selector Visual de Colores Distintivos con Vista Previa en Vivo (Priority: P1)

**Goal**: Integrar el selector visual de paleta deportiva curada (primario ≠ secundario) y la tarjeta de vista previa en vivo de la identidad del club en la parte superior de `CreateTeamScreen`.

**Independent Test**: En `CreateTeamScreen`, cambiar el color primario y el color secundario desde la paleta curada y verificar que la vista previa superior (`KickPulseTeamCrest` + nombre + sigla) se actualiza inmediatamente y que no permite seleccionar el mismo color en ambos.

### Implementation for User Story 2

- [X] T013 [US2] Add live club identity preview card (`Key('create_team_identity_preview')` using `KickPulseTeamCrest`, live team name, short code, and chosen colors) and curated 12-color sports palette selectors (`Key('create_team_primary_color_<hex>')` and `Key('create_team_secondary_color_<hex>')`) enforcing `primaryColorHex != secondaryColorHex` with clear Spanish feedback in `lib/presentation/teams/create_team_screen.dart`

**Checkpoint**: Vista previa en vivo y selección contrastada de colores distintivos completamente funcionales.

---

## Phase 5: User Story 3 — Validaciones, Control de Roles y Guardado Offline-First sin Duplicados (Priority: P1)

**Goal**: Conectar el envío del formulario con `TeamsController.createTeam` protegiendo contra doble envío (`single-flight`), mostrando errores de validación/conflicto en español sin perder los datos, y regresando con mensaje de éxito al guardar local y remotamente.

**Independent Test**: Probar validaciones de campos vacíos/inválidos, nombre duplicado normalizado, rol no autorizado, doble toque rápido en `Registrar equipo` (`single-flight`) y guardado exitoso offline/online regresando con SnackBar en español.

### Implementation for User Story 3

- [X] T014 [US3] Implement submit pipeline in `lib/presentation/teams/create_team_screen.dart`: validate all required fields (name ≥ 3, shortCode 2–4, delegate ≥ 1, foundedDate ≤ today, primary ≠ secondary), enforce single-flight `_isSubmitting` / `TeamsCatalogState.isSaving` loading state on `Key('create_team_submit_button')`, invoke `teamsControllerProvider.notifier.createTeam(...)` with all detailed fields, display inline/SnackBar Spanish error preserving inputs on failure, and pop with success SnackBar on completion
- [X] T015 [P] [US3] Create widget tests in `test/widget/create_team_screen_test.dart` covering US1, US2, and US3: full-screen form rendering, auto-suggested and manually editable short code, live identity preview updates when selecting primary/secondary colors, preventing identical primary/secondary colors, blocking empty/invalid fields and future dates with Spanish messages, role guard for unauthorized roles, single-flight double-tap prevention, successful submit forwarding all fields, error preservation, and `PopScope` unsaved-changes confirmation

**Checkpoint**: Registro detallado de equipo end-to-end funcionando y cubierto por pruebas de widget.

---

## Phase 6: User Story 4 — Visualización de Delegado, Fecha de Creación y Colores en la Ficha del Equipo (Priority: P2)

**Goal**: Mostrar el nombre del delegado, la fecha de creación formateada en español y los colores distintivos en `TeamInfoTabView`, manteniendo respaldo elegante para equipos previos.

**Independent Test**: Renderizar `TeamInfoTabView` para un equipo con delegado, fecha de creación y colores distintivos, y para un equipo legado sin delegado ni fecha, verificando presentación correcta sin errores; además verificar que `CoachPanelContent` y `TeamsDirectoryScreen` navegan a `/teams/create`.

### Implementation for User Story 4

- [X] T016 [US4] Update `_buildClubProfileCard` in `lib/presentation/teams/widgets/team_info_tab_view.dart` to display Delegate (`Key('team_info_delegate_row')`) and Founded Date (`Key('team_info_founded_date_row')`, formatted in Spanish) alongside the existing primary/secondary color swatches, showing localized `"No registrado"` / `"No registrada"` fallback for legacy teams without those fields
- [X] T017 [P] [US4] Create widget tests in `test/widget/team_info_tab_view_detailed_test.dart` verifying `TeamInfoTabView` renders delegate name, Spanish formatted founded date, and club colors for detailed teams, renders graceful fallbacks for legacy teams, and verifying navigation to `/teams/create` from `CoachPanelContent` and `TeamsDirectoryScreen`

**Checkpoint**: Ficha institucional completa visible en el detalle del equipo y puntos de entrada actualizados.

---

## Phase 7: Polish & Cross-Cutting Verification

**Purpose**: Verificación integral con análisis estático, suite global de pruebas y auditoría de directrices móviles.

- [X] T018 Run `flutter analyze` and execute targeted and global `flutter test` suites (`test/unit/team_registration_detailed_test.dart`, `test/widget/create_team_screen_test.dart`, `test/widget/team_info_tab_view_detailed_test.dart`, plus global `flutter test`), updating any legacy tests that previously asserted `CreateTeamDialog` opening instead of `/teams/create`
- [X] T019 Audit Spanish-only UI copy in `lib/l10n/app_es.arb`, keyboard scroll behavior, and large text-scale rendering across `lib/presentation/teams/create_team_screen.dart` and `lib/presentation/teams/widgets/team_info_tab_view.dart`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Inicia de inmediato (`T001` → `T002`).
- **Phase 2 (Foundational)**: Depende de Phase 1 para l10n/compilación; **bloquea** Phases 3–6. `T003`, `T004`, `T005` en paralelo → `T006`, `T007`, `T008`, `T009`.
- **Phase 3 (US1)** → **Phase 4 (US2)** → **Phase 5 (US3)**: Secuenciales sobre `create_team_screen.dart` (`T010` → `T013` → `T014`), con `T011`, `T012` y `T015` paralelizables.
- **Phase 6 (US4)**: Puede ejecutarse en paralelo tras Phase 2 (`T016` → `T017`).
- **Phase 7 (Polish)**: Depende de Phases 1–6 (`T018`, `T019`).

### Implementation Strategy
- **MVP (Phases 1–5)**: Entrega la nueva página dedicada `/teams/create` con vista previa en vivo, paleta contrastada, validaciones, control de roles y persistencia offline-first local + Supabase.
- **Incremento Final (Phases 6–7)**: Añade visualización en `TeamInfoTabView`, pruebas completas y verificación global con `flutter analyze` y `flutter test`.
