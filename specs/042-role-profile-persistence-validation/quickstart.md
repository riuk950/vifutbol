# Quickstart Validation Guide: Persistencia de Roles y Validación de Perfil

**Feature**: `042-role-profile-persistence-validation`  
**Prerequisites**:
- Flutter SDK installed (`flutter --version`)
- Local Supabase DEV migration applied (`supabase/migrations/202611130001_role_profiles_and_player_referee_linking.sql`) when running against live DEV.

## 1. Automated Verification Commands

Run static analysis and unit/widget tests after implementation:

```bash
flutter analyze
flutter test test/domain/entities/user_account_test.dart
flutter test test/infrastructure/auth/supabase_auth_repository_test.dart
flutter test test/presentation/shell/profile_tab_view_test.dart
flutter test test/presentation/shell/complete_profile_dialog_test.dart
```

## 2. End-to-End Functional Scenarios

1. **Atomic Registration & Role Onboarding**:
   - Register a new user and select any role (`player`, `referee`, `coach`, `organizer`, `fan`).
   - Expected: `user_accounts` row has `active_role`, `authorized_roles`, `onboarding_completed = true`, and corresponding profile table row exists.
2. **Player / Referee Non-Duplication Linking**:
   - Pre-seed an unlinked row in `vifutboldev.players` (with `document_id = '10203040'`, `user_account_id = NULL`, assigned to a team).
   - Register/complete profile as `player` with `document_id = '10203040'` and `phone = '3001234567'`.
   - Expected: Existing `players` row is updated with `user_account_id`, preserving `tournament_team_id` and stats; no duplicate row is created.
   - Repeat with a second user claiming `'10203040'` -> Expected: Rejected with Spanish conflict message.
3. **Incomplete Profile Banner & Adaptive Modal**:
   - Sign in as authenticated user missing `phone` or `document_id` (or `city` for `fan`).
   - Open Perfil tab -> Expected: Amber badge `"Datos incompletos"` and banner with `"Completar mi perfil"`.
   - Tap `"Completar mi perfil"`, fill valid role-specific fields while online, and save -> Expected: Dialog closes, badge immediately turns green `"Perfil completo"`, and banner disappears.
4. **Offline Guard**:
   - Disable network and submit `CompleteProfileDialog`.
   - Expected: Clear offline error message shown, entered values preserved in dialog, and badge remains `"Datos incompletos"`.
