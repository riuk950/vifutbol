# Modelo de Datos (Phase 1): Nueva Página de Registro Detallado de Equipo (HU 27.2)

**Funcionalidad**: `specs/062-team-registration-screen`  
**Fecha**: 2026-11-26

## 1. Esquema Relacional (`vifutboldev.teams`)

Se amplía `vifutboldev.teams` de forma idempotente conservando todas sus columnas, índices y restricciones actuales:

| Columna | Tipo | Nulabilidad | Regla / Descripción |
|---------|------|-------------|---------------------|
| `id` | `uuid` | `PRIMARY KEY` | Identificador único del club/equipo (existente). |
| `coach_id` | `uuid` | `NULL` | FK → `vifutboldev.user_accounts(id)` (existente). |
| `name` | `text` | `NOT NULL` | `char_length(trim(name)) >= 3` (existente). |
| `normalized_name` | `text` | `NOT NULL`, `UNIQUE` | Unicidad insensible a mayúsculas/espacios (existente). |
| `short_code` | `text` | `NOT NULL` | `char_length(trim(short_code)) BETWEEN 2 AND 4` (existente). |
| `primary_color_hex` | `bigint` | `NOT NULL` | Color primario ARGB (`0xFFRRGGBB`, existente). |
| `secondary_color_hex` | `bigint` | `NOT NULL` | Color secundario ARGB (`0xFFRRGGBB`, existente; debe diferir de `primary_color_hex` en registro). |
| `delegate_name` | `text` | `NULL` | **Nueva columna**. Nombre completo del delegado del equipo (obligatorio ≥ 1 carácter en `CreateTeamScreen`; `NULL` permitido para equipos históricos). |
| `founded_date` | `date` | `NULL` | **Nueva columna**. Fecha de creación del equipo (obligatoria y ≤ hoy en `CreateTeamScreen`; `NULL` permitido para equipos históricos). |
| `updated_at` | `timestamptz` | `NOT NULL` | Marca de actualización UTC (existente). |

## 2. Entidades de Dominio (Dart)

### `TournamentTeam` (`lib/domain/entities/tournament_team.dart`)
Se agregan dos campos opcionales (con soporte completo en constructor, `copyWith`, `toJson`, `fromJson`):
- `final String? delegateName;`
- `final DateTime? foundedDate;` (serializado como `YYYY-MM-DD` o ISO-8601 y parseado con `DateTime.tryParse`).

### `TeamDirectoryItem` (`lib/domain/entities/team_directory_item.dart`)
Se agregan los mismos dos campos opcionales (`delegateName`, `foundedDate`) con soporte en `fromJson`, `toJson`, `==` y `hashCode`.

## 3. Reglas de Validación

1. **Rol autorizado**: Solo `UserRole.coach` y `UserRole.organizer` (verificado mediante `RolePermissionMatrix` y guardia de pantalla).
2. **Nombre (`name`)**: Obligatorio, `trim().length >= 3`, único por `normalizedName`.
3. **Código corto (`shortCode`)**: Obligatorio, `trim().length` entre `2` y `4` (normalizado a mayúsculas); auto-sugerido desde `name` mientras el usuario no lo edite manualmente.
4. **Delegado (`delegateName`)**: Obligatorio en `CreateTeamScreen`, inicia siempre vacío, `trim().isNotEmpty` (≥ 1 carácter tras recortar espacios).
5. **Fecha de creación (`foundedDate`)**: Obligatoria en `CreateTeamScreen`, no posterior a la fecha calendario actual (`!isAfter(today)`).
6. **Colores distintivos (`primaryColorHex`, `secondaryColorHex`)**: Seleccionados de paleta deportiva curada y obligatoriamente distintos (`primaryColorHex != secondaryColorHex`).
7. **Torneo (`tournament`)**: Opcional (equipo autónomo o inscrito en un torneo con registro abierto).
