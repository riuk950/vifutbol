---

description: "Actionable task list for HU 24.2 — Botones de Quitar Anuncios, Términos, Políticas de Datos y Preguntas Frecuentes en Perfil"
---

# Tasks: Botones de Quitar Anuncios, Términos, Políticas de Datos y Preguntas Frecuentes en Perfil

**Input**: Design documents from `/specs/055-profile-legal-support-actions/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/profile_legal_support_contract.md`, `quickstart.md`

**Tests**: Incluidas de forma obligatoria según Principio III de la Constitución y checklist técnico de HU 24.2.

**Organization**: Las tareas están agrupadas por historia de usuario (`US1`, `US2`, `US3`) para habilitar implementación y verificación incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede ejecutarse en paralelo (archivos distintos, sin dependencias sobre tareas incompletas)
- **[Story]**: Historia de usuario a la que pertenece la tarea (`[US1]`, `[US2]`, `[US3]`)
- Todas las tareas incluyen rutas exactas de archivo relativas al repositorio

---

## Phase 1: Setup (Localization Foundation)

**Purpose**: Centralizar en español todas las llaves de interfaz, documentos legales, FAQ y modal de remoción de anuncios antes de construir las pantallas y widgets (Principio VI de la Constitución)

- [X] T001 Add Spanish localization keys for the 4 Profile buttons (`Quitar anuncios`, `Términos y condiciones`, `Políticas de tratamiento de datos`, `Preguntas frecuentes`), legal document sections (terms & privacy policy), FAQ items (questions & answers), and Remove Ads modal ("Próximamente" badge, benefit description, close CTA) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` by running `flutter gen-l10n` (depends on T001)

**Checkpoint**: Todas las llaves `AppLocalizations` generadas y disponibles para las historias de usuario.

---

## Phase 2: Foundational (Destination Screens & Modal)

**Purpose**: Crear los destinos reutilizables sin dependencias entre sí que serán enlazados desde la sección de Perfil y registrados en el router

- [X] T003 [P] Create `ProfileLegalDocumentScreen` with `ProfileLegalDocumentType` (`terms`, `privacyPolicy`), `AppBar` with back button, and scrollable `KickPulseCard` sections reading localized Spanish content offline in `lib/presentation/shell/tabs/profile_legal_document_screen.dart`
- [X] T004 [P] Create `ProfileFaqScreen` with `AppBar` with back button and scrollable expandable FAQ cards (`ExpansionTile` / `KickPulseCard`) displaying localized Spanish questions and answers offline in `lib/presentation/shell/tabs/profile_faq_screen.dart`
- [X] T005 [P] Create `RemoveAdsDialog` (`show(BuildContext context)`) with `KickPulseColors.surfaceBase`, representative icon, localized "Próximamente" `KickPulseBadge`, ad-free benefit copy, and close `KickPulseButton` (no billing, no persistence) in `lib/presentation/shell/tabs/widgets/remove_ads_dialog.dart`

**Checkpoint**: Los tres destinos (`ProfileLegalDocumentScreen`, `ProfileFaqScreen`, `RemoveAdsDialog`) listos para integrarse en Perfil y router.

---

## Phase 3: User Story 1 - Visualización Ordenada de Opciones de Suscripción, Legal y Soporte en Perfil (Priority: P1) 🎯 MVP

**Goal**: Mostrar inmediatamente debajo de "Permisos y capacidades del rol" y antes del botón de cierre/inicio de sesión los cuatro botones ordenados (`Quitar anuncios`, `Términos y condiciones`, `Políticas de tratamiento de datos`, `Preguntas frecuentes`) con ícono, etiqueta localizada, chevron y altura táctil `>= 48 px` para todos los roles y visitantes.

**Independent Test**: Renderizar `ProfileTabView` con los 5 roles + visitante en `dev` y `prod`, verificar la presencia y orden vertical exacto (`getTopLeft().dy`) debajo de `profile_capabilities_section` y arriba del botón de cierre/inicio de sesión, áreas táctiles `>= 44 px` y renderizado sin overflow a escala `1.5x`.

### Implementation for User Story 1

- [X] T006 [US1] Create `ProfileLegalSupportSection` (`StatefulWidget`) rendering a `KickPulseCard` with the 4 ordered tiles (`Key('profile_remove_ads_tile')`, `Key('profile_terms_tile')`, `Key('profile_privacy_policy_tile')`, `Key('profile_faq_tile')`), minimum `48 px` touch height, representative icons, localized Spanish labels, chevron indicators, and `_isActionInProgress` double-tap guard in `lib/presentation/shell/tabs/widgets/profile_legal_support_section.dart`
- [X] T007 [US1] Integrate `ProfileLegalSupportSection` in `ProfileTabView` immediately below the RBAC capabilities card (adding `Key('profile_capabilities_section')`) and above the logout/login `KickPulseButton` (adding `Key('profile_logout_action_button')`) in `lib/presentation/shell/tabs/profile_tab_view.dart`

### Tests for User Story 1

- [X] T008 [US1] Add widget tests verifying exact presence, vertical order (below `profile_capabilities_section` and above `profile_logout_action_button`), `>= 44 px` touch targets, visibility across all 5 roles + guest fan in both `AppEnvironment.development` and `AppEnvironment.production`, and zero overflow under `TextScaler.linear(1.5)` in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: User Story 1 (MVP) funcional y verificable de forma independiente.

---

## Phase 4: User Story 2 - Consulta Offline de Términos, Políticas de Tratamiento de Datos y Preguntas Frecuentes (Priority: P2)

**Goal**: Garantizar navegación fluida desde los tres botones legales/soporte a sus pantallas dedicadas offline (`ProfileLegalDocumentScreen` y `ProfileFaqScreen`), registrar las rutas `/profile/terms`, `/profile/privacy-policy` y `/profile/faq` en `AppRouter`, y asegurar retorno limpio al Perfil.

**Independent Test**: Pulsar `profile_terms_tile`, `profile_privacy_policy_tile` y `profile_faq_tile` en `ProfileTabView`, verificar que cada pantalla dedicada abre con contenido en español sin red y que presionar atrás regresa limpiamente a `ProfileTabView`.

### Implementation for User Story 2

- [X] T009 [US2] Register `/profile/terms`, `/profile/privacy-policy`, and `/profile/faq` routes pointing to `ProfileLegalDocumentScreen` and `ProfileFaqScreen` in `lib/presentation/navigation/app_router.dart`

### Tests for User Story 2

- [X] T010 [US2] Add widget tests verifying tapping `profile_terms_tile`, `profile_privacy_policy_tile`, and `profile_faq_tile` opens the corresponding dedicated screen with Spanish offline content and pressing back returns cleanly to `ProfileTabView` in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: User Stories 1 y 2 completas y verificables de forma independiente.

---

## Phase 5: User Story 3 - Modal Informativo de Quitar Anuncios y Protección contra Doble Tap (Priority: P3)

**Goal**: Verificar que pulsar `Quitar anuncios` abre `RemoveAdsDialog` con información en español y estado "Próximamente", y que pulsaciones rápidas consecutivas sobre cualquiera de los cuatro botones abren exactamente 1 instancia destino (0 duplicados).

**Independent Test**: Pulsar `profile_remove_ads_tile` y verificar `RemoveAdsDialog` + cierre limpio; ejecutar múltiples taps rápidos consecutivos sobre `profile_remove_ads_tile` y `profile_terms_tile` comprobando que solo se abre 1 diálogo o 1 pantalla a la vez.

### Tests for User Story 3

- [X] T011 [US3] Add widget tests verifying tapping `profile_remove_ads_tile` opens `RemoveAdsDialog` with Spanish "Próximamente" copy and closes cleanly, and verifying rapid consecutive double taps on the section tiles open at most 1 dialog or screen instance in `test/presentation/shell/profile_tab_view_test.dart`

**Checkpoint**: Todas las historias de usuario (US1, US2, US3) verificadas de forma independiente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validación final de calidad, análisis estático con cero advertencias y ejecución de la suite de `quickstart.md`

- [X] T012 Run static analysis (`flutter analyze lib/presentation/shell/tabs/ lib/presentation/navigation/app_router.dart test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart`) and resolve any issues so 0 errors and 0 warnings remain
- [X] T013 Run validation test suite per `specs/055-profile-legal-support-actions/quickstart.md` (`flutter test test/presentation/shell/profile_tab_view_test.dart test/presentation/auth_flow_widget_test.dart`) and confirm 100% pass rate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: `T001` → `T002` (bloquea todas las fases posteriores porque genera las llaves `AppLocalizations`).
- **Phase 2 (Foundational)**: `T003`, `T004`, `T005` dependen de `T002` y pueden ejecutarse **en paralelo** (archivos distintos).
- **Phase 3 (US1 - P1 MVP)**: `T006` depende de `T003`–`T005`; `T007` depende de `T006`; `T008` depende de `T007`.
- **Phase 4 (US2 - P2)**: `T009` depende de `T003`–`T004` (puede correr en paralelo con `T006`/`T007`); `T010` depende de `T007`.
- **Phase 5 (US3 - P3)**: `T011` depende de `T007`.
- **Phase 6 (Polish)**: `T012` y `T013` se ejecutan al completar `T001`–`T011`.

### Parallel Opportunities

- Tras `T002`, las tres vistas/modales (`T003`, `T004`, `T005`) pueden implementarse en paralelo en un mismo turno.
- `T009` (`app_router.dart`) puede editarse en paralelo con `T006`/`T007` (`profile_legal_support_section.dart` y `profile_tab_view.dart`).

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar `T001`–`T002` (`l10n`).
2. Completar `T003`–`T005` (destinos en paralelo).
3. Completar `T006`–`T008` (sección ordenada en Perfil + pruebas US1).

### Incremental Delivery

1. MVP (`US1`: `T001`–`T008`) → 4 botones visibles y ordenados debajo de permisos para todos los roles.
2. Incremento 2 (`US2`: `T009`–`T010`) → Rutas en `AppRouter` y verificación completa de lectura offline y retorno al Perfil.
3. Incremento 3 (`US3`: `T011`) → Verificación del modal `RemoveAdsDialog` y protección contra doble tap.
4. Cierre (`T012`–`T013`) → Análisis estático y suite completa de pruebas.
