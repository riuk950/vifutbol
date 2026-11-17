# Research: Player Photo Capture, Profile Avatar, and Personal Data Summary Page

**Feature**: `048-player-photo-profile-summary`  
**Date**: 2026-11-17

## 1. Profile Photo Capture & Image Compression

- **Decision**: Reuse `image_picker` (already integrated for HU 21.2 dual-side ID capture) to offer Camera and Gallery selection for the player's profile portrait (`maxWidth: 1024`, `maxHeight: 1024`, `imageQuality: 85`), and store the resulting image locally in the app documents directory (e.g., `player_avatar.jpg`) for offline-first resilience.
- **Rationale**: Reusing `image_picker` avoids adding redundant native dependencies and guarantees identical permission handling and lifecycle stability across iOS and Android. Resizing to max 1024px at 85% JPEG quality keeps file sizes well under the 5 MB storage limit while preserving sharp circular carnet previews.
- **Alternatives considered**:
  - `camera` plugin custom viewfinder: Rejected because profile portraits do not need barcode/OCR overlays and system camera/gallery pickers handle permissions and orientation natively.

## 2. Cloud Storage & Privacy Isolation (`player-avatars` vs `player-documents`)

- **Decision**: Create a dedicated Supabase Storage bucket `player-avatars` (public read, owner-scoped authenticated insert/update/delete, 5 MB limit, `image/jpeg`, `image/png`, `image/webp`) and store the public/resolved URL in `photo_url` on both `vifutboldev.players` and `vifutboldev.user_accounts` (returned in `role_profile.photo_url` and top-level `photo_url`).
- **Rationale**: Separates public/sporting player portraits from sensitive private identity documents (`player-documents`), allowing `ProfileTabView` and future squad/matchday views to render avatars directly without generating short-lived signed URLs on every frame.
- **Alternatives considered**:
  - Reusing `player-documents`: Rejected because `player-documents` is strictly private for cédula images and would require async signed URL generation for every avatar render.

## 3. Offline-First Photo Persistence & Deferred Sync

- **Decision**: Persist a local `photoLocalPath` / `photoUrl` immediately into `RoleProfileData` and `UserAccount` inside `LocalAuthRepository` / `Hive` local storage, and enqueue remote upload + `complete_role_profile` sync via the existing `SyncQueue` / `AuthController` offline-first mechanism when `ConnectivityRepository` reports disconnected.
- **Rationale**: Ensures the avatar renders immediately in `ProfileTabView` and `PlayerPersonalDataSummaryScreen` right after saving offline, and syncs to `player-avatars` + `vifutboldev.players` once connectivity recovers.
- **Alternatives considered**:
  - Blocking form submission without internet: Rejected because it violates the project's Offline-First Constitution principle and HU 21.3 business rules.

## 4. Document Preview Rendering in Personal Data Summary (`player-documents` Private Bucket)

- **Decision**: In `PlayerPersonalDataSummaryScreen`, resolve each ID card image by checking: (1) local file existence if `localPath` is present, or (2) generating a short-lived signed URL via `client.storage.from('player-documents').createSignedUrl(path, 300)` when online (or showing a clean offline/placeholder state if disconnected and not cached locally). Tapping any thumbnail opens an interactive full-screen/modal `InteractiveViewer` dialog with zoom and close button.
- **Rationale**: `player-documents` is a private bucket with owner-scoped RLS, so signed URLs (or local cached files) are required to display the front/back ID images securely.
- **Alternatives considered**:
  - Making `player-documents` public: Rejected for security/privacy reasons (national ID cards contain sensitive PII).

## 5. Routing & Completeness Rules

- **Decision**:
  - Keep `/profile/personal-data` mapped to the personal data edit form (`PlayerPersonalDataScreen`) to preserve backward compatibility with HU 21.1/21.2 flows and tests.
  - Add `/profile/personal-data/summary` mapped to the new `PlayerPersonalDataSummaryScreen` (read-only dossier with "Editar Datos" AppBar action that pushes `/profile/personal-data`).
  - Update `UserAccount.isProfileCompleteForActiveRole` for `UserRole.player` to also require `_hasText(roleProfile?.photoUrl)` (which holds either the remote URL or local synced file path).
  - In `ProfileTabView`, when `activeRole == UserRole.player`:
    - If `!user.isProfileCompleteForActiveRole`: banner + button *"Completar Datos Personales"* navigates to `/profile/personal-data`.
    - If `user.isProfileCompleteForActiveRole`: the *"Datos Personales"* tile/button navigates to `/profile/personal-data/summary`.
- **Rationale**: Matches HU 21.3 Gherkin scenarios and business rules cleanly while keeping existing form routes and tests intact.
