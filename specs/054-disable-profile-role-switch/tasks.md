---

description: "Actionable task list for HU 24.1 — Deshabilitar Cambio de Rol Activo en el Perfil para Todos los Roles"
---

# Tasks: Deshabilitar Cambio de Rol Activo en el Perfil para Todos los Roles

**Input**: Design documents from `/specs/054-disable-profile-role-switch/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/profile_role_display_contract.md`, `quickstart.md`

**Tests**: Incluidas de forma obligatoria según Principio III de la Constitución y checklist técnico de HU 24.1.

**Organization**: Las tareas están agrupadas por historia de usuario (`US1`, `US2`, `US3`) para permitir implementación y validación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias sobre tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (`[US1]`, `[US2]`, `[US3]`)
- Todas las tareas incluyen rutas exactas de archivo relativas al repositorio

---

## Phase 1: Setup (Baseline Verification)

**Purpose**: Confirmar el estado inicial limpio antes de modificar la vista de Perfil y sus pruebas

- [X] T001 Verify baseline tests and static analysis pass before edits by running `flutter analyze lib/presentation/shell/tabs/profile_tab_view.dart` and checking existing tests in `test/presentation/shell/profile_tab_view_test.dart` and `test/presentation/auth_flow_widget_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No se requieren cambios en dominio, esquemas Hive/Supabase ni repositorios (según `data-model.md` y `research.md`). Fase sin tareas bloqueantes adicionales; las historias de usuario pueden iniciar inmediatamente tras T001.

**Checkpoint**: Base verificada — la implementación de historias de usuario puede comenzar.

---

## Phase 3: User Story 1 - Eliminación Universal del Selector de Cambio de Rol en el Perfil (Priority: P1) 🎯 MVP

**Goal**: Eliminar por completo la sección interactiva de cambio de rol (`ChoiceChip`, encabezado `Cambiar rol activo` y textos condicionales `dev`/`prod`) de `ProfileTabView` para los cinco roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y modo visitante en ambos entornos (`dev` y `prod`), garantizando 0 invocaciones a `switchActiveRole`.

**Independent Test**: Renderizar `ProfileTabView` con los 5 roles + invitado tanto en `AppEnvironment.development` como en `AppEnvironment.production`, incluyendo usuarios con múltiples `authorizedRoles`, confirmando ausencia total de `ChoiceChip`, ausencia de `Cambiar rol activo` y `verifyNever(() => authRepository.switchActiveRole(...))`.

### Implementation for User Story 1

- [X] T002 [US1] Remove the entire Role Switcher section (`l10n.profileSwitchRole` header, `KickPulseCard`, `dev`/`prod` helper copy, `Wrap` of `ChoiceChip`, and `switchActiveRole` call) and clean up unused `config`, `isDev`, `availableRoles` variables and unused imports (`foundation_providers.dart`, `app_environment.dart`) in `lib/presentation/shell/tabs/profile_tab_view.dart`

### Tests for User Story 1

- [X] T003 [P] [US1] Update legacy role-switching widget test (`ProfileTabView displays active role badge and allows switching`) to assert read-only active role badge visibility, absence of `ChoiceChip` and `Cambiar rol activo`, and `verifyNever` on `mockAuthRepository.switchActiveRole` in `test/presentation/auth_flow_widget_test.dart`
- [X] T004 [P] [US1] Add matrix widget tests verifying all 5 roles (`UserRole.organizer`, `UserRole.coach`, `UserRole.referee`, `UserRole.player`, `UserRole.fan`), multi-role `authorizedRoles`, and guest fan render without `ChoiceChip`, without `Cambiar rol activo`, without `Entorno DEV activo`, and trigger 0 calls to `switchActiveRole` in both `AppEnvironment.development` and `AppEnvironment.production` in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: User Story 1 (MVP) completamente implementada y verificable de forma independiente.

---

## Phase 4: User Story 2 - Visualización del Rol Activo en Solo Lectura en la Tarjeta de Identidad (Priority: P2)

**Goal**: Garantizar que la insignia de rol activo en la tarjeta de identidad superior permanezca visible en modo solo lectura con identificador estable, semántica accesible para lectores de pantalla (`readOnly: true`) y legibilidad sin desbordamiento bajo escalado de texto ampliado en español.

**Independent Test**: Renderizar `ProfileTabView` con escalado de texto ampliado (`TextScaler.linear(1.5)`) y verificar `ValueKey('profile_active_role_badge')`, semántica de solo lectura (`readOnly: true`), texto en español vía `AppLocalizations` y cero errores de overflow.

### Implementation for User Story 2

- [X] T005 [US2] Add `ValueKey('profile_active_role_badge')` and explicit read-only accessibility semantics (`Semantics(readOnly: true, ...)`) to the active role `KickPulseBadge` in the top identity card and update the class doc comment to remove role-switching wording in `lib/presentation/shell/tabs/profile_tab_view.dart`

### Tests for User Story 2

- [X] T006 [US2] Add widget tests verifying `ValueKey('profile_active_role_badge')` displays localized Spanish role labels, exposes read-only semantics, and renders without overflow under enlarged text scaling (`TextScaler.linear(1.5)`) in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: User Stories 1 y 2 completas y verificables de forma independiente.

---

## Phase 5: User Story 3 - Conservación de Integridad de Sesión y Permisos al Reanudar o Operar Sin Conexión (Priority: P3)

**Goal**: Confirmar que pulsaciones repetidas sobre la insignia de rol activo y la reconstrucción de la vista no alteran `activeRole` ni disparan mutaciones, y que las demás secciones existentes del perfil (completitud, datos personales de jugador, matriz de permisos y cierre de sesión) operan sin regresiones.

**Independent Test**: Ejecutar pulsaciones repetidas sobre `profile_active_role_badge`, recrear/re-bombear `ProfileTabView` y verificar que el estado de sesión permanece inmutable, `switchActiveRole` tiene 0 llamadas y las secciones preservadas del perfil responden normalmente.

### Tests for User Story 3

- [X] T007 [US3] Add widget tests verifying repeated taps on `ValueKey('profile_active_role_badge')` and recreating/re-pumping `ProfileTabView` keep `activeRole` unchanged with 0 calls to `switchActiveRole`, and verify preserved sections (role permissions card, player personal data tile, completeness CTA, and logout button) remain functional in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: Todas las historias de usuario (US1, US2, US3) verificadas de forma independiente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validación final de calidad, análisis estático y regresión completa según `quickstart.md`

- [X] T008 Run static analysis (`flutter analyze lib/presentation/shell/tabs/profile_tab_view.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart`) and ensure 0 errors and 0 warnings
- [X] T009 Run full validation suite per `specs/054-disable-profile-role-switch/quickstart.md` (`flutter test test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart test/infrastructure/supabase_auth_repository_test.dart`) and confirm 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sin dependencias — inicia de inmediato (`T001`).
- **Phase 2 (Foundational)**: Sin tareas bloqueantes adicionales.
- **Phase 3 (US1 - P1 MVP)**: Depende de `T001`; `T002` habilita `T003` y `T004` (paralelizables entre sí).
- **Phase 4 (US2 - P2)**: `T005` edita el mismo archivo que `T002` (`profile_tab_view.dart`), por lo que se ejecuta secuencialmente después de `T002`; `T006` depende de `T005`.
- **Phase 5 (US3 - P3)**: `T007` depende de `T005` (usa `ValueKey('profile_active_role_badge')`).
- **Phase 6 (Polish)**: `T008` y `T009` se ejecutan al finalizar `T001`–`T007`.

### Parallel Opportunities

- Dentro de **US1**: `T003` (`test/presentation/auth_flow_widget_test.dart`) y `T004` (`test/presentation/shell/profile_tab_view_test.dart`) modifican archivos distintos y pueden ejecutarse en paralelo tras `T002`.

---

## Parallel Example: User Story 1

```text
# After T002 completes in lib/presentation/shell/tabs/profile_tab_view.dart:
Parallel Task A (T003): Update legacy test in test/presentation/auth_flow_widget_test.dart
Parallel Task B (T004): Add 5-role + guest dev/prod matrix tests in test/presentation/shell/profile_tab_view_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar `T001` (verificación base).
2. Completar `T002`–`T004` (eliminación del selector de rol en `dev`/`prod` + pruebas de los 5 roles e invitado).
3. Validar el MVP con `flutter test test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart`.

### Incremental Delivery

1. MVP (`US1`: `T002`–`T004`) → Bloqueo universal efectivo en `dev` y `prod`.
2. Incremento 2 (`US2`: `T005`–`T006`) → Semántica de accesibilidad de solo lectura y prueba de escalado de texto.
3. Incremento 3 (`US3`: `T007`) → Pruebas de pulsaciones repetidas y no-regresión de secciones preservadas.
4. Cierre (`T008`–`T009`) → Análisis estático y suite de validación completa según `quickstart.md`.
