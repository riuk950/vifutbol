# Quickstart & Verification Guide: Gestión Integral (CRUD) y Ciclo de Vida de Competiciones en Panel del Organizador (HU 16.1)

**Feature**: `028-organizer-competitions-crud`
**Date**: 2026-11-10

## 1. Prerequisites & Setup

Ensure the project dependencies and local environment are properly initialized:
```bash
flutter pub get
flutter gen-l10n
```

---

## 2. Running Automated Tests

Run the test suite verifying domain use cases, repositories, providers, and widget tests:

```bash
# Run unit & repository tests
flutter test test/domain/tournaments_crud_test.dart
flutter test test/infrastructure/repositories/local_tournaments_repository_test.dart
flutter test test/application/controllers/tournaments_controller_test.dart

# Run widget tests for organizer panel competitions section
flutter test test/presentation/panel/organizer_competitions_section_test.dart
flutter test test/presentation/panel/competition_edit_dialog_test.dart
flutter test test/presentation/panel/competition_lifecycle_dialog_test.dart
flutter test test/presentation/panel/competition_delete_dialog_test.dart
```

---

## 3. Manual Verification Workflow in App / Simulator

### Scenario 1: Empty State & Creation
1. Launch app with an organizer user that has zero tournaments.
2. Navigate to Panel -> Tab Organizador.
3. Verify that the "Mis Competiciones" section shows the empty state card (`organizer_competitions_empty_state`) with message and "Crear mi primera competición".
4. Tap the create button, fill out the tournament creation flow, and verify that upon saving, the empty state disappears and the new tournament card is immediately visible.

### Scenario 2: Edit Metadata
1. On an existing tournament card, tap the more options button (`organizer_competition_menu_button_<id>`).
2. Select "Editar metadatos".
3. Verify the dialog opens with pre-populated name and category.
4. Modify the name (e.g., append " - Edición Oro 2026") and tap "Guardar cambios".
5. Verify the snackbar indicates success and the card in the list immediately reflects the updated name.

### Scenario 3: Controlled Lifecycle Transitions
1. Select a tournament in `openRegistration` with < 2 teams or without fixture.
2. Tap more options -> "Cambiar estado de competición".
3. Select `inProgress` and tap confirm.
4. Verify an error message is displayed indicating that at least 2 teams and a generated fixture are required.
5. Inscribe at least 2 teams and generate fixture.
6. Attempt transition again; verify the tournament transitions to `inProgress` and the badge updates to live/inProgress.
7. Attempt to revert to `openRegistration`; verify that the UI prevents reverting to previous states.
8. Transition from `inProgress` to `finished`; verify it updates to `finished` and cannot be edited or reverted.

### Scenario 4: Safe Deletion with Blocking Safeguards
1. Select a tournament in `inProgress` or `finished`.
2. Open more options -> "Eliminar competición".
3. Verify the dialog informs that tournaments in progress or finished cannot be deleted, and the confirm button is disabled/hidden.
4. Select a tournament in `openRegistration` with matches already played. Verify deletion is blocked with the message explaining that played matches exist.
5. Select a tournament in `openRegistration` with no played matches. Tap "Eliminar definitivamente" in the confirmation dialog.
6. Verify the tournament is removed from storage and immediately disappears from the organizer panel.

---

## 4. Visual & Responsiveness Verification
- Verify layout on standard phone screen ($360 \times 800\text{ dp}$).
- Verify layout on narrow screen ($320 \times 640\text{ dp}$) with **130% text scaling**.
- Ensure zero `RenderFlex` overflow errors.
