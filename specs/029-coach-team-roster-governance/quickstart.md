# Quickstart & Verification Guide: Coach Team & Roster Governance

**Feature Branch**: `029-coach-team-roster-governance` | **Date**: 2026-11-10

## 1. Prerequisites

- Flutter 3.x / Dart 3.x installed.
- Dependencies fetched via `flutter pub get`.

## 2. Automated Test Verification

Run the dedicated test suite for coach governance and role segregation:

```bash
# 1. Run domain authorization & use case tests
flutter test test/application/use_cases/manage_teams_eligibility_use_case_test.dart test/domain/role_permission_matrix_test.dart

# 2. Run presentation directory visibility tests
flutter test test/presentation/teams_directory_screen_test.dart test/presentation/players_directory_screen_test.dart

# 3. Run Coach Panel empty state and creation tests
flutter test test/presentation/panel/coach_panel_widget_test.dart

# 4. Run Competition Detail FAB simplification tests
flutter test test/presentation/tournaments/competition_detail_screen_test.dart
```

## 3. Manual Inspection Steps

1. **Coach Experience**:
   - Log in or switch role to `coach`.
   - Open Teams Directory: verify the `+` button is visible in the AppBar. Tap to open `CreateTeamDialog`.
   - Open Coach Panel: if no team is created, verify `coach_no_team_card` is visible with "Registrar mi Equipo".
   - Create a team: verify that the team appears in the Coach Panel and squad actions become active.
2. **Organizer Experience**:
   - Switch role to `organizer`.
   - Open Teams Directory: verify the `+` button is hidden.
   - Open Players Directory: verify the player registration button is hidden.
   - Open Competition Detail: verify that only "Generar Fixture" FAB is visible (no speed dial, no "Inscribir equipo").
3. **Referee / Fan / Player Experience**:
   - Switch role to `fan`, `player`, or `referee`.
   - Verify that all team creation and player registration buttons remain hidden across all screens.
