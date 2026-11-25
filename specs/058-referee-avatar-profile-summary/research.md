# Phase 0 Research: Foto de Avatar del Árbitro, Visualización en Perfil y Pantalla Resumen

**Feature**: `058-referee-avatar-profile-summary` (HU 25.2)
**Date**: 2026-11-25

## Decision 1: Reutilización de `DocumentStorageRepository.uploadPlayerAvatar` y bucket `player-avatars`

- **Decision**: Reutilizar `DocumentStorageRepository.uploadPlayerAvatar(userId: ..., localPath: ..., existingPhotoUrl: ...)` y el bucket público `player-avatars` (`$userId/avatar.jpg` con `upsert: true` y query `?t=<epochMs>`).
- **Rationale**:
  - `SupabaseDocumentStorageRepository.uploadPlayerAvatar` ya implementa validación de conectividad previa (`OfflineAuthOperationFailure`), subida autenticada con política RLS por `auth.uid()` (carpeta `$userId/avatar.jpg`), `upsert: true`, `contentType: 'image/jpeg'` y cache-busting automático con timestamp `?t=`.
  - Evita cambios disruptivos en la interfaz `DocumentStorageRepository` y en todos los fakes/mocks existentes en la suite de pruebas del repositorio.
  - `delete_my_account()` ya limpia `storage.objects` en `bucket_id IN ('player-avatars', 'player-documents')` por prefijo `$auth_uid/%`, por lo que el avatar del árbitro queda cubierto automáticamente por el borrado en cascada de HU 24.3.
- **Alternatives considered**:
  - Crear un nuevo método `uploadRefereeAvatar` o un bucket separado `referee-avatars`: rechazado porque duplicaría lógica idéntica, exigiría nuevas políticas RLS de bucket y rompería mocks de pruebas existentes sin beneficio funcional.

## Decision 2: Persistencia atómica de `photo_url` en `vifutboldev.match_referees` y `vifutboldev.user_accounts`

- **Decision**: Crear la migración idempotente `supabase/migrations/202611250003_referee_avatar_photo_url.sql` que agrega `photo_url text` a `vifutboldev.match_referees`, actualiza la rama `p_active_role = 'referee'` de `vifutboldev.complete_role_profile` para persistir `photo_url` (tanto en `UPDATE` como en `INSERT`) y actualiza `vifutboldev.delete_my_account()` para limpiar `photo_url = NULL` en `match_referees`.
- **Rationale**:
  - `vifutboldev.complete_role_profile` ya recibe `p_photo_url` (parámetro 27) y lo guarda en `user_accounts.photo_url` y `players.photo_url`, pero en HU 25.1 no se agregó la columna `photo_url` a `match_referees`.
  - Mantener `photo_url` sincronizado en ambas tablas garantiza consistencia cuando otros módulos (como listados de árbitros o designaciones de partidos) consulten `match_referees` directamente.
- **Alternatives considered**:
  - Guardar `photo_url` únicamente en `user_accounts`: rechazado porque HU 25.2 requiere explícitamente persistirlo tanto en `user_accounts` como en `match_referees`.

## Decision 3: Estrategia de permisos y selección de avatar en `RefereePersonalDataScreen`

- **Decision**: Integrar una tarjeta/sección de avatar circular en la parte superior de `RefereePersonalDataScreen` con opciones de cámara y galería usando `ImagePicker` (`maxWidth: 1024`, `maxHeight: 1024`, `imageQuality: 85`), inyectable vía un callback opcional `Future<String?> Function(ImageSource source)? avatarPickerOverride` para pruebas deterministas, y manejo explícito de `PlatformException` (`camera_access_denied`, `photo_access_denied`) mostrando banner/SnackBar en español con acceso a `openCameraSettings()` o alternativa de galería sin perder datos del formulario.
- **Rationale**:
  - Mantiene la misma ergonomía probada en `PlayerPersonalDataScreen` y permite probar los flujos de cámara, galería, cancelación y permiso denegado en `flutter test` sin depender de canales nativos reales.
  - Cambiar únicamente el avatar marca `_isDirty = true`, activando la protección `PopScope` ante salida accidental.
- **Alternatives considered**:
  - Usar un paquete nuevo de recorte de imagen (`image_cropper`): fuera de alcance según `spec.md` (`Assumptions`) y añadiría complejidad nativa innecesaria.

## Decision 4: Paridad visual y de navegación para `RefereePersonalDataSummaryScreen`

- **Decision**: Crear `RefereePersonalDataSummaryScreen` en `lib/presentation/shell/tabs/referee_personal_data_summary_screen.dart` siguiendo la estructura visual de `PlayerPersonalDataSummaryScreen`:
  - Ruta: `/profile/referee-personal-data/summary`.
  - En `ProfileTabView`, el tile `Key('profile_referee_personal_data_tile')` navegará a `/profile/referee-personal-data/summary` cuando `user?.isProfileCompleteForActiveRole == true`, y a `/profile/referee-personal-data` cuando esté incompleto (idéntico al patrón de `profile_personal_data_tile` para jugador).
  - La pantalla resumen carga vistas previas de los 3 documentos privados (`documentFrontUrl`, `documentBackUrl`, `certificationDocumentUrl`) resolviendo URLs firmadas vía `documentStorageRepositoryProvider.getDocumentSignedUrl(...)` (o `FileImage` para rutas locales existentes), con soporte de diálogo de zoom y fallback visual cuando falle la carga o no haya conexión.
- **Rationale**:
  - Ofrece una experiencia consistente entre los roles `player` y `referee` usando los mismos tokens de `DESIGN.md` (`KickPulseCard`, `KickPulseColors`, `KickPulseTypography`).
  - Al escuchar `ref.watch(authControllerProvider)`, cualquier edición guardada desde `RefereePersonalDataScreen` se refleja inmediatamente al regresar a `RefereePersonalDataSummaryScreen` y a `ProfileTabView`.
- **Alternatives considered**:
  - Reutilizar `PlayerPersonalDataSummaryScreen` con condicionales de rol: rechazado porque el jugador muestra sección táctica (`PrimaryPosition`, `SecondaryPositions`) mientras el árbitro muestra sección de certificación arbitral (`certificationLevel` + documento de certificación arbitral); separar la pantalla mantiene alta cohesión y claridad.
