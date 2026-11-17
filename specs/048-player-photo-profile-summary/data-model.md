# Data Model: Player Photo Capture, Profile Avatar, and Personal Data Summary Page

**Feature**: `048-player-photo-profile-summary`  
**Date**: 2026-11-17

## 1. Database Schema (`vifutboldev`)

### Table `vifutboldev.players` (Extension)
- `photo_url` (`text`, nullable): Public/resolved URL of the player's profile portrait stored in `player-avatars`.

### Table `vifutboldev.user_accounts` (Extension)
- `photo_url` (`text`, nullable): Cached/primary avatar URL for quick session hydration across roles.

### Storage Bucket `player-avatars`
- `id`: `'player-avatars'`
- `name`: `'player-avatars'`
- `public`: `true` (direct read for avatar display)
- `file_size_limit`: `5242880` (5 MB)
- `allowed_mime_types`: `ARRAY['image/jpeg', 'image/png', 'image/webp']`
- **RLS Policies (`storage.objects`)**:
  - `player_avatars_public_select`: `FOR SELECT TO public USING (bucket_id = 'player-avatars')`
  - `player_avatars_owner_insert`: `FOR INSERT TO authenticated WITH CHECK (bucket_id = 'player-avatars' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)`
  - `player_avatars_owner_update`: `FOR UPDATE TO authenticated USING (bucket_id = 'player-avatars' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)`
  - `player_avatars_owner_delete`: `FOR DELETE TO authenticated USING (bucket_id = 'player-avatars' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)`

### RPC `vifutboldev.complete_role_profile`
- Extended from 26 to **27 parameters**, adding `p_photo_url text DEFAULT NULL`.
- When `p_active_role = 'player'`, persists `photo_url = COALESCE(NULLIF(trim(p_photo_url), ''), photo_url)` on `vifutboldev.players` and `vifutboldev.user_accounts`.
- Returns `'photo_url'` inside both the top-level JSONB object and `'role_profile'` JSONB object.

---

## 2. Domain Entities (`lib/domain/entities/`)

### `RoleProfileData`
- Added field: `final String? photoUrl;`
  - Holds either an HTTP(S) public URL from `player-avatars` or a local file path (when saved offline pending upload).
- Updated `copyWith`, `toJson`, `fromJson` (reading `'photoUrl'` / `'photo_url'`), `==`, and `hashCode`.

### `UserAccount`
- Added convenience getter `String? get avatarUrl => roleProfile?.photoUrl;` (or top-level `photoUrl` if added).
- Updated `isProfileCompleteForActiveRole` for `UserRole.player`:
  - Now also requires `_hasText(roleProfile?.photoUrl)` in addition to `hasPhone`, `hasDoc`, `firstName`, `firstSurname`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `secondaryPositions.isNotEmpty`, `documentFrontUrl`, `documentBackUrl`.

---

## 3. State & Age Calculation Helpers

- **Age calculation**: Computed deterministically from `birthDate` relative to `DateTime.now()`:
  - `age = now.year - birthDate.year - ((now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) ? 1 : 0)`
  - Handled safely when `birthDate == null` (omitted or fallback).
