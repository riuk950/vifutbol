# Data Model: Foto de Avatar del Árbitro, Visualización en Perfil y Pantalla Resumen

**Feature**: `058-referee-avatar-profile-summary` (HU 25.2)
**Date**: 2026-11-25

## 1. Relational Schema Changes (`vifutboldev`)

### Table: `vifutboldev.match_referees`

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `photo_url` *(new)* | `text` | YES | `NULL` | URL pública (con cache-buster `?t=<epochMs>`) de la fotografía de avatar del árbitro en Supabase Storage (`player-avatars/$authUid/avatar.jpg`). |

*Nota*: Las demás columnas de identidad (`first_name`, `second_name`, `first_surname`, `second_surname`, `sex`, `birth_date`, `blood_type`, `department`, `municipality`, `document_front_url`, `document_back_url`, `certification_document_url`, `certification_level`) ya fueron creadas en HU 25.1 (`202611250002_referee_profile_and_certification_doc.sql`).

### Table: `vifutboldev.user_accounts` (Sin cambios DDL)

- Ya cuenta con `photo_url text` actualizado por `vifutboldev.complete_role_profile` cuando `p_photo_url` no es nulo ni vacío.

## 2. RPC Function Updates

### `vifutboldev.complete_role_profile(...)` (28 parámetros — sin cambio de firma)

- Rama `ELSIF p_active_role = 'referee' AND v_norm_doc IS NOT NULL`:
  - `UPDATE vifutboldev.match_referees`: añade `photo_url = COALESCE(NULLIF(trim(p_photo_url), ''), photo_url)`.
  - `INSERT INTO vifutboldev.match_referees`: añade columna `photo_url` con valor `NULLIF(trim(p_photo_url), '')`.
- `UPDATE vifutboldev.user_accounts`: continúa actualizando `photo_url = COALESCE(NULLIF(trim(p_photo_url), ''), photo_url)`.

### `vifutboldev.delete_my_account()`

- En el `UPDATE vifutboldev.match_referees` de desvinculación de PII, agrega `photo_url = NULL` para garantizar borrado completo de referencias de imagen al eliminar la cuenta.

## 3. Domain Entities (Sin cambios de firma)

### `UserAccount`
- `photoUrl: String?`: URL pública (con `?t=...`) o ruta local en modo offline/local.
- `isProfileCompleteForActiveRole` para `UserRole.referee`: **sin cambios** respecto a HU 25.1 (el avatar es opcional; exige datos personales obligatorios, ambas caras de la cédula y documento de certificación arbitral).

### `RoleProfileData`
- Sin campos nuevos requeridos: `certificationLevel`, `documentFrontUrl`, `documentBackUrl`, `certificationDocumentUrl` y campos personales ya existen y se hidratan desde `match_referees`.

## 4. State Transitions (Avatar & Profile Summary)

1. **Sin avatar (`photoUrl == null`)**:
   - `ProfileTabView`: muestra ícono de respaldo en `CircleAvatar`.
   - `RefereePersonalDataScreen`: muestra `CircleAvatar` con ícono de respaldo y botones "Tomar foto de perfil" / "Seleccionar de galería".
   - `RefereePersonalDataSummaryScreen`: muestra `CircleAvatar` con ícono de respaldo.
2. **Avatar seleccionado localmente (`_localAvatarPath != null`, sin guardar)**:
   - `RefereePersonalDataScreen`: muestra `FileImage(File(_localAvatarPath))` en vista previa circular, marca `_isDirty = true` (activa `PopScope`) y permite reemplazarlo antes de guardar.
3. **Guardado exitoso con conectividad**:
   - Sube archivo a `player-avatars/$userId/avatar.jpg` (`upsert: true`) → recibe `publicUrl?t=<timestamp>`.
   - Invoca `completeRoleProfile(..., photoUrl: uploadedAvatarUrl)` → actualiza atómicamente `user_accounts.photo_url`, `match_referees.photo_url` y sesión local en `AuthController`.
   - `ProfileTabView` y `RefereePersonalDataSummaryScreen` reflejan la nueva imagen inmediatamente vía `ref.watch(authControllerProvider)`.
4. **Guardado sin conectividad**:
   - `uploadPlayerAvatar` lanza `OfflineAuthOperationFailure` → `RefereePersonalDataScreen` muestra error claro en español y conserva `_localAvatarPath` y todos los campos del formulario intactos para reintento.
5. **Error de carga remota de imagen (offline o URL inaccesible en Perfil/Resumen)**:
   - `CircleAvatar.onBackgroundImageError` / `Image.errorBuilder` capturan el fallo silenciosamente y renderizan el respaldo visual sin romper la vista ni bloquear `Editar`.
