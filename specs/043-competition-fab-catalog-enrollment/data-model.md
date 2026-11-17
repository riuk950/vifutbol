# Data Model: Carga y Selección de Equipos del Catálogo Global en Competición (HU 18.5)

**Feature**: `043-competition-fab-catalog-enrollment`  
**Schema**: `vifutboldev` (Supabase PostgreSQL) + Caché local Hive

## 1. Entidades de Base de Datos Consultadas (`vifutboldev`)

No se requieren nuevas migraciones DDL; se reutilizan las tablas existentes en `vifutboldev`:
- **`vifutboldev.teams`**: Catálogo maestro de clubes (`id`, `coach_id`, `name`, `normalized_name`, `short_code`, `crest_shape`, `primary_color_hex`, `secondary_color_hex`, `updated_at`).
- **`vifutboldev.user_accounts`**: Vinculada por `teams.coach_id -> user_accounts.id` para resolver `full_name` del entrenador responsable.
- **`vifutboldev.tournament_teams`**: Vínculo de inscripción por torneo (`id`, `tournament_id`, `team_id`, `group_name`, `eligibility_status`, `updated_at`).
- **`vifutboldev.tournaments`**: Provee `category` y `name` para enriquecer `categoryLabel` de clubes previamente inscritos.
- **`vifutboldev.players`**: Plantilla de futbolistas asociada a cada equipo (`tournament_team_id`).

---

## 2. Entidades de Dominio y Presentación (Dart / Flutter)

### 2.1 `TournamentTeam` (`lib/domain/entities/tournament_team.dart` — Extendido)
| Campo | Tipo | Regla / Descripción |
|-------|------|---------------------|
| `id` | `String` | Identificador único del registro |
| `tournamentId` | `String` | ID del torneo (`''` cuando es un club autónomo del catálogo global aún no inscrito en ningún torneo) |
| `name` | `String` | Nombre oficial del club |
| `shortCode` | `String` | Código / sigla del club (2–4 caracteres) |
| `crestShape` | `TeamCrestShape` | Forma geométrica del escudo |
| `primaryColorHex` | `int` | Color primario del escudo |
| `secondaryColorHex` | `int` | Color secundario del escudo |
| `eligibilityStatus` | `TeamEligibilityStatus` | Estado reglamentario (`pendingVerification` al inscribirse) |
| `players` | `List<RegisteredPlayer>` | Plantilla de jugadores preservada al inscribir |
| `groupName` | `String?` | Grupo asignado en torneos mixtos |
| `coachId` | `String?` | ID de cuenta del entrenador responsable |
| `coachName` | `String?` | **Nuevo (opcional)**: Nombre completo del entrenador resuelto desde `user_accounts.full_name` |
| `categoryLabel` | `String?` | **Nuevo (opcional)**: Categoría asociada al club (o `null` si aún no tiene categoría de torneo previa) |
| `updatedAt` | `DateTime` | Fecha de última actualización |

### 2.2 `CatalogTeamEntry` (`lib/presentation/tournaments/widgets/add_teams_to_competition_modal.dart`)
| Campo | Tipo | Regla / Descripción |
|-------|------|---------------------|
| `sourceTeam` | `TournamentTeam` | Instancia representativa del club (priorizando mayor plantilla / actualización más reciente y fusionando `categoryLabel` y `coachName` conocidos) |
| `normalizedKey` | `String` | Nombre normalizado sin tildes ni mayúsculas (`normalizeSearchText(name)`) |
| `isEnrolledInCurrentTournament` | `bool` | `true` si el club ya está vinculado a `tournament.id` |

---

## 3. Reglas de Visualización y Transición de Estado

1. **Categoría mostrada en tarjeta**:
   - Si `sourceTeam.categoryLabel` tiene texto no vacío -> se muestra ese valor.
   - Si `sourceTeam.categoryLabel` es `null` o vacío -> se muestra `l10n.addTeamsDefaultCategoryLabel` (`"Categoría libre"`).
2. **Entrenador mostrado en tarjeta**:
   - Si `sourceTeam.coachName` tiene texto no vacío -> se muestra `l10n.addTeamsCoachMeta(sourceTeam.coachName!)` (`"DT: <Nombre>"`).
   - Si `sourceTeam.coachName` es `null` o vacío -> no se renderiza texto ni etiqueta de entrenador.
3. **Transición al inscribir (`_handleEnrollTeam`)**:
   - `isEnrolledInCurrentTournament == false` -> Botón `"Inscribir"` activo.
   - Clic en `"Inscribir"` -> `enrollExistingTeamFromCatalog` crea vínculo en `tournament.id` con `eligibilityStatus = TeamEligibilityStatus.pendingVerification` copiando la plantilla no conflictiva -> `teamsControllerProvider` recarga estado -> `isEnrolledInCurrentTournament` pasa a `true` (badge `"Inscrito"` + botón deshabilitado) y `CompetitionTeamsTabView` muestra inmediatamente el nuevo club.
