# Interface Contracts: HU 25.2 Referee Avatar & Profile Summary

**Feature**: `058-referee-avatar-profile-summary`
**Date**: 2026-11-25

## 1. Navigation & Routes Contract (`AppRouter`)

| Route | Screen | Access Condition |
|-------|--------|------------------|
| `/profile/referee-personal-data` | `RefereePersonalDataScreen` | Usuario autenticado con rol `referee` (edición / completar perfil). |
| `/profile/referee-personal-data/summary` *(new)* | `RefereePersonalDataSummaryScreen` | Usuario autenticado con rol `referee` y perfil completo (consulta de solo lectura + botón Editar). |

### Routing Rules in `ProfileTabView`
- `ValueKey('profile_complete_action_button')` (solo visible si `!user.isProfileCompleteForActiveRole`):
  - Para `UserRole.referee` → navega a `/profile/referee-personal-data`.
- `Key('profile_referee_personal_data_tile')` (visible para usuarios autenticados con rol `referee`):
  - Si `user.isProfileCompleteForActiveRole == true` → navega a `/profile/referee-personal-data/summary` y muestra subtítulo de resumen (`refereePersonalDataSummarySubtitle`).
  - Si `user.isProfileCompleteForActiveRole == false` → navega a `/profile/referee-personal-data` y muestra subtítulo de completar perfil (`refereePersonalDataSubtitle`).

## 2. Storage & Repository Contract (Reused)

- **Upload Avatar**: `DocumentStorageRepository.uploadPlayerAvatar({required String userId, required String localPath, String? existingPhotoUrl})`
  - Bucket: `player-avatars` (público con RLS por `auth.uid()`).
  - Path: `$userId/avatar.jpg` (`upsert: true`, `contentType: 'image/jpeg'`).
  - Return: `https://<host>/storage/v1/object/public/player-avatars/$userId/avatar.jpg?t=<epochMs>`.
  - Offline error: throws `OfflineAuthOperationFailure`.
- **Private Document Previews (Summary Screen)**:
  - `DocumentStorageRepository.getDocumentSignedUrl(String storagePath)` para `documentFrontUrl`, `documentBackUrl` y `certificationDocumentUrl` cuando la ruta no es un archivo local existente ni una URL HTTP(S).

## 3. UI Widget Keys Contract (Testability)

### `RefereePersonalDataScreen`
- `ValueKey('referee_form_profile_avatar')`: `CircleAvatar` de vista previa del avatar en el formulario.
- `ValueKey('referee_avatar_camera_button')`: botón "Tomar foto de perfil".
- `ValueKey('referee_avatar_gallery_button')`: botón "Seleccionar de galería".
- `ValueKey('referee_avatar_permission_banner')`: banner de permiso denegado para cámara/galería con botón a ajustes.

### `ProfileTabView`
- `ValueKey('profile_identity_avatar')`: `CircleAvatar` reactivo con `user.photoUrl` (existente).
- `ValueKey('profile_completeness_badge')`: badge `Perfil completo` / `Perfil incompleto` (existente).
- `Key('profile_referee_personal_data_tile')`: acceso directo a resumen (si completo) o formulario (si incompleto).

### `RefereePersonalDataSummaryScreen`
- `ValueKey('referee_summary_edit_action')`: botón "Editar" en AppBar → `/profile/referee-personal-data`.
- `ValueKey('referee_summary_header_card')`: tarjeta superior de identidad.
- `ValueKey('referee_summary_avatar')`: `CircleAvatar` con `user.photoUrl` o fallback.
- `ValueKey('referee_summary_full_name')`: nombre completo del árbitro.
- `ValueKey('referee_summary_document_id')`: número de documento (`CC: ...`).
- `ValueKey('referee_summary_age')`: edad calculada desde `birthDate`.
- `ValueKey('referee_summary_demographics_card')`: tarjeta de datos personales y ubicación (sexo, fecha de nacimiento, tipo de sangre, teléfono, departamento, municipio).
- `ValueKey('referee_summary_certification_card')`: tarjeta de nivel de certificación arbitral y vista previa del documento de certificación (`ValueKey('referee_summary_certification_doc_preview')`).
- `ValueKey('referee_summary_documentation_card')`: tarjeta con vistas previas de ambos lados de la cédula (`ValueKey('referee_summary_doc_front_preview')`, `ValueKey('referee_summary_doc_back_preview')`).

## 4. Localization Keys Contract (`lib/l10n/app_es.arb`)

Nuevas claves en español requeridas:
- `refereeAvatarSectionTitle`: `"Foto de perfil"`
- `refereeAvatarSectionSubtitle`: `"Esta fotografía se mostrará en tu tarjeta de perfil arbitral."`
- `refereeAvatarCameraButton`: `"Tomar foto de perfil"`
- `refereeAvatarGalleryButton`: `"Seleccionar de galería"`
- `refereeAvatarChangeButton`: `"Cambiar foto"`
- `refereeAvatarPermissionDeniedError`: `"Permiso de cámara o galería denegado. Habilítalo en los ajustes del dispositivo o usa la opción alternativa."`
- `refereeAvatarGalleryPermissionDeniedError`: `"No tenemos permiso para acceder a tu galería. Habilítalo en ajustes o usa la cámara."`
- `refereeAvatarLoadError`: `"No se pudo cargar la imagen seleccionada. Intenta con otra fotografía."`
- `refereePersonalDataSummaryTitle`: `"Perfil Arbitral"`
- `refereePersonalDataSummarySubtitle`: `"Consulta tu avatar, datos personales y documentos"`
- `refereeSummaryCertificationTitle`: `"Certificación Arbitral"`
- `refereeSummaryCertificationSubtitle`: `"Categoría oficial y soporte documental"`
- `refereeSummaryPhoneLabel`: `"Teléfono"`
- `refereeSummaryCertificationDocLabel`: `"Documento de certificación"`
- `refereeSummaryDocLoadFallback`: `"Vista previa no disponible"`
