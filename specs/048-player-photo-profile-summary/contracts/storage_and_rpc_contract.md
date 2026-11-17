# Contracts: Storage & RPC Contract for Player Profile Avatar

**Feature**: `048-player-photo-profile-summary`  
**Date**: 2026-11-17

## 1. Repository Contract (`DocumentStorageRepository`)

Extend `DocumentStorageRepository` (or add dedicated avatar upload/signed-URL methods on it) to support:

1. `Future<String> uploadPlayerAvatar({required String userId, required String localPath, String? existingPhotoUrl})`
   - Checks connectivity; throws `OfflineAuthOperationFailure` if disconnected.
   - Uploads `$userId/avatar.jpg` to bucket `player-avatars` with `upsert: true`, `contentType: 'image/jpeg'`.
   - Returns the public URL (with cache-busting query param `?t=<epochMs>` or clean URL) for immediate reactive display.

2. `Future<String?> getSignedDocumentUrl({required String storagePath, int expiresInSeconds = 300})`
   - Given a private storage path in `player-documents` (e.g., `<uid>/document_front.jpg`), returns a signed URL for display in `PlayerPersonalDataSummaryScreen` when online, or `null` when offline / unavailable.

## 2. Supabase RPC Contract (`vifutboldev.complete_role_profile`)

- **Signature**: 27 parameters (existing 26 parameters + `p_photo_url text DEFAULT NULL`).
- **Response JSONB**:
  - Top-level includes `'photo_url': v_account.photo_url`
  - `'role_profile'` includes `'photo_url': v_player_row.photo_url`

## 3. Presentation Route & Widget Contract

- Route `/profile/personal-data` -> `PlayerPersonalDataScreen` (Edit/Capture Form)
  - Includes circular avatar preview + *"Tomar Foto de Perfil"* action (Camera / Gallery).
  - Form submission saves even without a profile photo (Option A).
- Route `/profile/personal-data/summary` -> `PlayerPersonalDataSummaryScreen` (Read-Only Summary)
  - AppBar action: *"Editar Datos"* -> pushes `/profile/personal-data`.
  - Section 1: Header (circular avatar, full name, document ID, calculated age in years).
  - Section 2: Demographics (Sex, Birth Date, Blood Type, Department, Municipality).
  - Section 3: Tactical Profile (chips for primary and secondary positions).
  - Section 4: Documentation (thumbnails for front & back ID card; tapping opens interactive full-screen zoom viewer).
- `ProfileTabView`:
  - Identity Card `CircleAvatar`: renders local file (`FileImage`) if `photoUrl` is a local path, `NetworkImage` if HTTP(S) URL, with error fallback to role icon.
  - Completeness badge: *"Perfil completo"* vs *"Datos incompletos"*.
  - Action button/tile:
    - Incomplete -> *"Completar Datos Personales"* -> `/profile/personal-data`
    - Complete -> *"Datos Personales"* -> `/profile/personal-data/summary`
