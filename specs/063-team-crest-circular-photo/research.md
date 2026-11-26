# Investigación Técnica (Phase 0): Carga de Foto del Escudo del Equipo con Visualización Circular (HU 27.3)

**Funcionalidad**: `specs/063-team-crest-circular-photo`  
**Fecha**: 2026-11-26

## Decisiones Técnicas Consolidadas

### 1. Bucket Público con Escritura por Propietario (`team-crests`)
- **Decisión**: Replicar exactamente el patrón probado de `player-avatars` (`202611170004_player_profile_avatar.sql`) creando el bucket `team-crests` en `storage.buckets` (`public = true`, `file_size_limit = 5242880` [5 MB], `allowed_mime_types = ['image/jpeg', 'image/png', 'image/webp']`) con 4 políticas RLS idempotentes en `storage.objects`: lectura pública (`SELECT TO public`) y escritura/actualización/borrado restringida a usuarios autenticados propietarios (`(storage.foldername(name))[1] = (SELECT auth.uid())::text`).
- **Justificación**: Permite que aficionados, jugadores, árbitros y tablas de posiciones visualicen los escudos sin requerir URLs firmadas temporales, manteniendo control estricto de escritura por propietario.
- **Alternativas consideradas**:
  - Bucket privado con URLs firmadas: descartado porque los escudos de equipos son activos públicos deportivos visibles en tablas y partidos para invitados y todos los roles.

### 2. Renderizado 100% Circular Unificado en `KickPulseTeamCrest`
- **Decisión**: Actualizar `KickPulseTeamCrest` para aceptar `String? crestUrl` y renderizar **siempre** en circunferencia perfecta (per Q2):
  - Cuando `crestUrl` está presente (URL `http(s)://` o archivo local existente): enmarcar la imagen dentro de un círculo con borde en los colores distintivos del equipo y `ClipOval` + `BoxFit.cover`.
  - Cuando `crestUrl` es nulo/vacío o falla la carga de la imagen (`errorBuilder`): renderizar automáticamente el monograma (`shortCode`) con los colores distintivos del equipo usando `TeamCrestShape.circle`.
- **Justificación**: Cumple 100% la clarificación Q2 y unifica visualmente todas las pantallas de la app (directorio, detalle, tabla de posiciones, tarjetas de partidos, actas, panel y registro) sin romper firmas existentes al mantener `crestShape` como parámetro opcional compatible hacia atrás.
- **Alternativas consideradas**:
  - Mantener formas `shield`/`diamond`/`hexagon` para equipos sin foto: descartado en Q2 (Opción A).

### 3. Validación Local de Archivo y Continuidad Offline-First
- **Decisión**:
  - Validar localmente antes de subir que la extensión pertenezca a `{jpg, jpeg, png, webp}` y el tamaño del archivo sea ≤ 5 MB (`5 * 1024 * 1024` bytes), rechazando archivos inválidos con mensajes claros en español sin perder los campos del formulario.
  - Durante el guardado en `CreateTeamScreen` (per Q1): si el usuario eligió una imagen local, intentar subirla vía `documentStorageRepositoryProvider.uploadTeamCrest(...)`; si el dispositivo está offline o ocurre un fallo temporal de red/subida, conservar la ruta local en `crestUrl`, persistir el equipo localmente (offline-first) y mostrar aviso en español de sincronización pendiente. Además, `HybridTeamsRepository` puede reintentar subir una ruta local de `crestUrl` al sincronizar con la nube cuando haya conectividad.
- **Justificación**: Garantiza experiencia continua en cancha sin bloquear al entrenador cuando hay señal inestable.
- **Alternativas consideradas**:
  - Bloquear la creación del equipo si falla la subida de la imagen: descartado en Q1 (Opción A).

### 4. Propagación Global de `crestUrl`
- **Decisión**: Añadir `String? crestUrl` a `TournamentTeam`, `TeamDirectoryItem`, `StandingsRow` (tabla de posiciones) y `TeamDetailedStats` (cuando aplique), propagándolo desde `HybridTeamsRepository`, `LocalTeamsRepository`, `StandingsCalculatorService` y todas las instancias de `KickPulseTeamCrest` en la app (directorio, detalle, info, plantilla, alineaciones, tarjetas de partido, acta digital y tabla de posiciones).
- **Justificación**: Asegura que la fotografía circular aparezca consistentemente en cada punto donde se muestra el escudo de un club.
