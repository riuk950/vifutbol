# Contract: Referee Profile & Certification Document (HU 25.1)

## 1. Supabase RPC Contract (`vifutboldev.complete_role_profile`)

- **Signature**: Existing 27 parameters + `p_certification_document_url text DEFAULT NULL` (28th parameter).
- **Behavior when `p_active_role = 'referee'`**:
  - Links existing `match_referees` row by `user_account_id` or `normalized_document_id` (or inserts a new row if absent) without duplicating records.
  - Persists `full_name`, `phone`, `document_id`, `normalized_document_id`, `certification_level`, `first_name`, `second_name`, `first_surname`, `second_surname`, `sex`, `birth_date`, `blood_type`, `department`, `municipality`, `document_front_url`, `document_back_url`, and `certification_document_url`.
  - Returns hydrated `user_accounts` JSONB including `role_profile` with all referee fields and `linked_referee_id`.
- **Cascade Delete Compatibility (`vifutboldev.delete_my_account`)**:
  - Clears `document_front_url`, `document_back_url`, and `certification_document_url` alongside `user_account_id` and `phone` on `match_referees`.

## 2. Document Storage Contract (`DocumentStorageRepository`)

```dart
Future<String> uploadRefereeCertificationDocument({
  required String userId,
  required String localPath,
  String? existingDocumentUrl,
});
```
- Checks connectivity first; throws `OfflineAuthOperationFailure` when disconnected.
- Uploads image (`JPEG`/`PNG`/`WEBP`) to `player-documents` at `$userId/referee_certification.jpg` (`upsert: true`).
- Preserves `existingDocumentUrl` if `localPath` is empty or file does not exist; throws `DocumentUploadFailure` on storage error.

## 3. Navigation & UI Contract

- **Route**: `/profile/referee-personal-data` → `RefereePersonalDataScreen`
- **Profile Entry Points (`ProfileTabView`)**:
  - Incomplete profile CTA (`profile_complete_action_button`) navigates to `/profile/referee-personal-data` when `activeRole == UserRole.referee`.
  - Dedicated tile (`Key('profile_referee_personal_data_tile')`) visible when `!isGuest && (activeRole == UserRole.referee || authorizedRoles.contains(UserRole.referee))` navigates to `/profile/referee-personal-data`.
- **Form Keys (`RefereePersonalDataScreen`)**:
  - Reuses `IdDocumentCaptureCard` for front/back Colombian ID capture + dual scanner trigger.
  - `Key('referee_certification_level_field')` for certification category/level.
  - `Key('referee_certification_capture_card')` / `Key('referee_certification_capture_button')` for capturing/replacing the certification document image.
  - `Key('referee_save_profile_button')` for single-flight submit.
