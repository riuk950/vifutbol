# Contracts: Role Profile Persistence & Document Linking

**Feature**: `042-role-profile-persistence-validation`  
**Date**: 2026-11-13

## 1. Database RPC Contract: `vifutboldev.complete_role_profile`

Called via Supabase RPC (`client.schema('vifutboldev').rpc('complete_role_profile', params: ...)`).

### Request Parameters
```json
{
  "p_active_role": "player | referee | coach | organizer | fan",
  "p_authorized_roles": ["player", "fan"],
  "p_onboarding_completed": true,
  "p_full_name": "string (optional, non-empty)",
  "p_phone": "string (optional)",
  "p_document_id": "string (optional)",
  "p_club_name": "string (optional, coach)",
  "p_license_level": "string (optional, coach)",
  "p_organization_name": "string (optional, organizer)",
  "p_base_city": "string (optional, organizer)",
  "p_city": "string (optional, fan)",
  "p_preferences": "string (optional, fan)",
  "p_certification_level": "string (optional, referee)"
}
```

### Server-Side Atomic Behavior
1. Authenticate caller via `auth.uid()`; resolve `v_user_account_id` from `vifutboldev.user_accounts WHERE auth_user_id = auth.uid()`. Raise `AUTH_USER_NOT_FOUND` if missing.
2. Update `vifutboldev.user_accounts`:
   - `active_role = p_active_role`
   - `authorized_roles = p_authorized_roles`
   - `onboarding_completed = p_onboarding_completed`
   - `full_name = COALESCE(NULLIF(trim(p_full_name), ''), full_name)`
   - `phone = COALESCE(NULLIF(trim(p_phone), ''), phone)`
   - `document_id = COALESCE(NULLIF(trim(p_document_id), ''), document_id)`
   - `normalized_document_id = normalized(document_id)`
3. Branch by `p_active_role`:
   - **`player`** (when `v_norm_doc` is present):
     - Search `vifutboldev.players` by `normalized_document_id = v_norm_doc` (prioritizing existing tournament row if any, else free-agent row).
     - If found and `user_account_id IS NOT NULL AND user_account_id <> v_user_account_id`: `RAISE EXCEPTION 'DOCUMENT_ALREADY_LINKED' USING ERRCODE = 'P0001'`.
     - If found and (`user_account_id IS NULL OR user_account_id = v_user_account_id`): `UPDATE` `user_account_id = v_user_account_id`, `phone = COALESCE(NULLIF(trim(p_phone), ''), phone)`, `full_name = CASE WHEN char_length(trim(full_name)) = 0 THEN v_full_name ELSE full_name END` (preserving `tournament_team_id`, `tournament_id`, `shirt_number`, `position`, `is_eligible`, goals, match history).
     - If not found: `INSERT INTO vifutboldev.players (user_account_id, full_name, document_id, normalized_document_id, phone)` (free agent: `tournament_team_id = NULL`, `tournament_id = NULL`).
   - **`referee`** (when `v_norm_doc` is present):
     - Search `vifutboldev.match_referees` by `normalized_document_id = v_norm_doc`.
     - If found and `user_account_id IS NOT NULL AND user_account_id <> v_user_account_id`: `RAISE EXCEPTION 'DOCUMENT_ALREADY_LINKED' USING ERRCODE = 'P0001'`.
     - If found and unlinked/self: `UPDATE` `user_account_id = v_user_account_id`, `phone = COALESCE(NULLIF(trim(p_phone), ''), phone)`, `full_name = CASE WHEN char_length(trim(full_name)) = 0 THEN v_full_name ELSE full_name END`.
     - If not found: `INSERT INTO vifutboldev.match_referees (user_account_id, full_name, document_id, normalized_document_id, phone, certification_level, is_active)`.
   - **`coach`**: `INSERT ... ON CONFLICT (user_account_id) DO UPDATE` into `vifutboldev.coach_profiles`.
   - **`organizer`**: `INSERT ... ON CONFLICT (user_account_id) DO UPDATE` into `vifutboldev.organizer_profiles`.
   - **`fan`**: `INSERT ... ON CONFLICT (user_account_id) DO UPDATE` into `vifutboldev.fan_profiles`.
4. Return merged JSON payload of the updated `user_accounts` row + active `role_profile` fields.

---

## 2. Repository Contract: `AuthRepository`

New method added to `AuthRepository` (implemented by `SupabaseAuthRepository` and `LocalAuthRepository`):

```dart
Future<UserAccount> updateRoleProfile({
  required String userId,
  required UserRole role,
  String? phone,
  String? documentId,
  RoleProfileData? roleProfile,
});
```

### Error Mapping
- Offline (`!await connectivity.isConnected`): throws `NetworkFailure` with clear Spanish message; caller keeps form inputs intact.
- `DOCUMENT_ALREADY_LINKED` from RPC: throws `DocumentAlreadyLinkedFailure` (`El documento ingresado ya está vinculado a otra cuenta de usuario.`).
- Any other failure: throws `ServerFailure` / `AppFailure` with localized Spanish message.

---

## 3. UI Contract: `ProfileTabView` & `CompleteProfileDialog`

- **`ProfileTabView`**:
  - Evaluates `user.isProfileCompleteForActiveRole` (always `true` for `isGuestFan`).
  - Displays `KickPulseBadge` in identity card:
    - Incomplete: amber badge (`"Datos incompletos"`) + warning banner with button `"Completar mi perfil"`.
    - Complete: green badge (`"Perfil completo"`), banner hidden.
- **`CompleteProfileDialog`**:
  - Adaptive fields by `user.activeRole`:
    - Common: `phone` (all 5 roles), `documentId` (`player`, `referee`, `coach`, `organizer`; hidden/optional for `fan`).
    - `coach`: `clubName`, `licenseLevel`.
    - `organizer`: `organizationName`, `baseCity`.
    - `fan`: `city`, `preferences` (optional).
  - Pre-fills existing `user.phone`, `user.documentId`, and `user.roleProfile` values.
  - Inline validation in Spanish; loading spinner on save button; keeps modal open and preserves input on error/offline.
