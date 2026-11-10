# Quickstart & Validation Guide: Gestión de Equipos Inscritos en Competición (HU 15.4)

**Feature**: `027-competition-teams-management`  
**Date**: 2026-11-10

## Prerequisites

- Flutter SDK `^3.11.0`
- Dependencias instaladas (`flutter pub get`)
- Clases de localización generadas (`flutter gen-l10n`)

## Validation Scenarios

### 1. Inscripción de Equipo desde el FAB Menu (`US1`)
1. Iniciar sesión con rol `Organizador` y abrir el detalle de una competición editable (`/competitions/:id`).
2. Tocar `Key('competition_detail_fab_menu')` y verificar que aparece `Key('competition_detail_fab_add_team')` ("Agregar Equipo").
3. Tocar `Key('competition_detail_fab_add_team')`, completar el nombre y sigla en `CompetitionEnrollTeamDialog` (y grupo si el formato es `mixedGroupsAndKnockout`) y pulsar `Key('enroll_team_submit_button')`.
4. Verificar que aparece el `SnackBar` de confirmación y que el equipo aparece listado en la pestaña **"Equipos"** (`Key('competition_detail_tab_teams')`).

### 2. Consulta de Equipos Inscritos y Traslado de Grupo (`US2` & `US3`)
1. En una competición con formato `TournamentFormat.mixedGroupsAndKnockout`, abrir la pestaña **"Equipos"** (`Key('competition_detail_tab_teams')`).
2. Verificar que cada equipo muestra su insignia de grupo (`Key('competition_team_group_badge_<id>')`).
3. Como `Organizador`, pulsar `Key('competition_team_move_group_<id>')` en un equipo del `"Grupo A"` y seleccionar `"Grupo B"` (`Key('competition_move_group_option_Grupo B')`).
4. Verificar que la insignia del equipo cambia a `"Grupo B"` y que en la pestaña **"Clasificación"** el equipo aparece ubicado en la tabla del **Grupo B**.

### 3. Retiro de Equipo de la Competición (`US3`)
1. En la pestaña **"Equipos"**, como `Organizador`, pulsar `Key('competition_team_remove_<id>')`.
2. Confirmar en el diálogo `Key('competition_remove_team_confirm_dialog')` tocando `Key('competition_remove_team_confirm_button')`.
3. Verificar que el equipo desaparece de la pestaña **"Equipos"** de la competición.

## Automated Verification Commands

```bash
# 1. Regenerar localizaciones
flutter gen-l10n

# 2. Ejecutar tests unitarios de dominio, casos de uso y controlador
flutter test test/unit/domain/standings_calculator_service_test.dart \
  test/unit/application/manage_teams_eligibility_use_case_test.dart \
  test/unit/application/teams_controller_test.dart

# 3. Ejecutar tests de widgets de Competición, Pestaña Equipos y Responsividad (320x640 @ 130%)
flutter test test/presentation/tournaments/competition_detail_screen_test.dart \
  test/presentation/tournaments/competition_teams_tab_view_test.dart \
  test/presentation/directories_responsive_widget_test.dart

# 4. Puertas de calidad estática y formato
flutter analyze
dart format --output=none --set-exit-if-changed .
```
