# Quickstart & Verification Guide: Team Approval & Fixture Eligibility

**Feature Branch**: `030-team-approval-fixture-eligibility` | **Date**: 2026-11-10

## 1. Prerequisites

- Flutter SDK (3.24+) configured.
- Clean analysis: `flutter analyze` with 0 issues.

---

## 2. Test Execution Commands

### Domain & Application Use Cases
```bash
flutter test test/domain/team_eligibility_status_test.dart
flutter test test/application/use_cases/manage_teams_eligibility_approval_test.dart
flutter test test/application/use_cases/fixture_scheduling_eligibility_filter_test.dart
```

### Presentation & UI Verification
```bash
flutter test test/presentation/tournaments/competition_teams_tab_view_approval_test.dart
flutter test test/presentation/tournaments/competition_teams_tab_view_role_visibility_test.dart
flutter test test/presentation/tournaments/competition_teams_tab_view_responsive_test.dart
```

### Full Feature Verification
```bash
flutter test test/domain/ test/application/ test/presentation/
```

---

## 3. Manual Verification Scenarios

### Scenario 1: Rejection on Insufficient Roster (< 11 players)
1. Launch app with role `UserRole.organizer`.
2. Navigate to a tournament in `openRegistration` and switch to the "Equipos" tab.
3. Locate an enrolled team with 9 players.
4. Verify label displays `"9/11 jugadores - Incompleto"`.
5. Tap `"Habilitar Equipo"`.
6. Verify modal dialog appears with message:
   `"El equipo no cumple la cuota reglamentaria mínima (mínimo 11 jugadores requeridos, actual: 9)"`.
7. Tap `"Entendido"`. Verify the team status remains `"Pendiente de verificación"`.

### Scenario 2: Successful Approval (>= 11 players)
1. With `UserRole.organizer`, find a team with 11 players.
2. Verify label displays `"11 jugadores - Nómina válida"`.
3. Tap `"Habilitar Equipo"`.
4. Verify badge turns green with `"Habilitado"` / `"Habilitado para competir"`.
5. Verify button changes to `"Inhabilitar"`.

### Scenario 3: Role Segregation Check
1. Switch active role to `UserRole.coach`, `referee`, `player`, or `fan`.
2. Navigate to the same tournament "Equipos" tab.
3. Verify roster count labels and badges are visible.
4. Verify buttons `"Habilitar Equipo"` and `"Inhabilitar"` are NOT rendered.
