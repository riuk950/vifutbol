# Modelo de Datos (Phase 1): Carga de Foto del Escudo del Equipo con Visualización Circular (HU 27.3)

**Funcionalidad**: `specs/063-team-crest-circular-photo`  
**Fecha**: 2026-11-26

## 1. Esquema Relacional (`vifutboldev.teams`) y Storage (`team-crests`)

- **Tabla `vifutboldev.teams`**:
  - Nueva columna idempotente: `crest_url text NULL` (URL pública remota en `team-crests`; `NULL` permitido para equipos sin foto o históricos).
- **Bucket `storage.buckets`**:
  - `id = 'team-crests'`, `name = 'team-crests'`, `public = true`, `file_size_limit = 5242880` (5 MB), `allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']`.
- **Políticas RLS (`storage.objects`)**:
  - `team_crests_public_select`: `SELECT TO public USING (bucket_id = 'team-crests')`.
  - `team_crests_owner_insert`: `INSERT TO authenticated WITH CHECK (bucket_id = 'team-crests' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)`.
  - `team_crests_owner_update`: `UPDATE TO authenticated` (mismo filtro propietario).
  - `team_crests_owner_delete`: `DELETE TO authenticated` (mismo filtro propietario).

## 2. Entidades de Dominio (Dart)

| Entidad | Archivo | Campo Añadido | Reglas |
|---------|---------|---------------|--------|
| `TournamentTeam` | `lib/domain/entities/tournament_team.dart` | `final String? crestUrl;` | Opcional, serializado como `'crestUrl'`, soporte en `copyWith` (`clearCrestUrl`), `toJson`, `fromJson`. |
| `TeamDirectoryItem` | `lib/domain/entities/team_directory_item.dart` | `final String? crestUrl;` | Opcional, serializado como `'crestUrl'`, incluido en `==` y `hashCode`. |
| `StandingsRow` | `lib/domain/entities/standings_table.dart` | `final String? crestUrl;` | Opcional, propagado por `StandingsCalculatorService` para renderizar escudos en la tabla de posiciones. |

## 3. Reglas de Validación de Imagen del Escudo

1. **Opcionalidad**: El equipo puede registrarse con o sin foto de escudo.
2. **Formatos permitidos**: `image/jpeg` (`.jpg`, `.jpeg`), `image/png` (`.png`), `image/webp` (`.webp`).
3. **Tamaño máximo**: `5 MB` (`5,242,880` bytes).
4. **Continuidad offline-first**: Si la imagen local es válida y no se puede subir en el momento por falta de red o error temporal, se persiste localmente la ruta local en `crestUrl` para visualización inmediata y sincronización posterior.
5. **Renderizado circular**: `KickPulseTeamCrest` renderiza **siempre** en circunferencia (imagen recortada con `ClipOval` + `BoxFit.cover` + borde en colores distintivos, o fallback circular `TeamCrestShape.circle` con monograma).
