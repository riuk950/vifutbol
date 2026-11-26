# Contratos de Interfaz (Phase 1): Carga de Foto del Escudo del Equipo con Visualización Circular (HU 27.3)

**Funcionalidad**: `specs/063-team-crest-circular-photo`  
**Fecha**: 2026-11-26

## 1. Contrato de Almacenamiento (`DocumentStorageRepository`)

```dart
/// Uploads a team's crest photograph to the public-read `team-crests` bucket
/// (owner-scoped write under `<userId>/...`) and returns its public URL.
///
/// Validates format (jpg/jpeg/png/webp) and max size (5 MB).
/// Throws [DocumentUploadFailure] or [OfflineAuthOperationFailure] on failure.
Future<String> uploadTeamCrest({
  required String userId,
  required String teamId,
  required String localPath,
  String? existingCrestUrl,
});
```

- **Ruta en Storage**: `$userId/crest_$teamId.$ext` dentro del bucket `team-crests` (`upsert: true`).
- **Retorno**: URL pública de Supabase Storage con cache-buster (`?v=<timestamp>`) o URL limpia.

## 2. Contrato de Persistencia (`HybridTeamsRepository` ↔ `vifutboldev.teams`)

- **Upsert en `vifutboldev.teams`**:
  - Si `team.crestUrl` es una ruta de archivo local existente (no comienza con `http://` ni `https://`) y hay cliente/storage disponible al sincronizar, intenta subirlo a `team-crests` y persiste la URL pública resultante; si falla, no bloquea el guardado local.
  - Incluye `'crest_url': resolvedCrestUrl` en el `upsert` sobre `vifutboldev.teams`.
- **Select / Hidratación**:
  - `fetchAllTeamsDirectory` selecciona `crest_url` explícitamente; `_fromRow` y `_fromStandaloneTeamRow` leen `teamMap['crest_url']`.

## 3. Contrato de UI (`KickPulseTeamCrest` y `CreateTeamScreen`)

- **`KickPulseTeamCrest`**:
  ```dart
  const KickPulseTeamCrest({
    super.key,
    required this.shortCode,
    this.crestShape = TeamCrestShape.circle,
    this.primaryColorHex = 0xFF00E676,
    this.secondaryColorHex = 0xFF0A0E17,
    this.crestUrl,
    this.size = 44.0,
  });
  ```
  - Siempre renderiza en circunferencia (`ClipOval` + `BoxFit.cover` + borde circular cuando hay foto válida; `TeamCrestShape.circle` en fallback o ausencia de foto).
  - Expone `Key('kick_pulse_team_crest_photo')` cuando renderiza la imagen y `Key('kick_pulse_team_crest_fallback')` cuando renderiza el monograma circular.
- **`CreateTeamScreen`**:
  - Parámetro opcional para pruebas: `Future<String?> Function(ImageSource source)? crestPickerOverride`.
  - Botón principal de escudo: `Key('create_team_upload_crest_button')` ("Subir escudo" / "Cambiar escudo").
  - Botón quitar escudo: `Key('create_team_remove_crest_button')` (visible solo cuando hay imagen seleccionada).
  - Hoja inferior de origen: `Key('create_team_crest_source_gallery')`, `Key('create_team_crest_source_camera')`.
