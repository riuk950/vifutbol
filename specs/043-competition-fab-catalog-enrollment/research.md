# Research: Carga y Selección de Equipos del Catálogo Global en Competición (HU 18.5)

**Feature**: `043-competition-fab-catalog-enrollment`  
**Date**: 2026-11-17  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/043-competition-fab-catalog-enrollment/spec.md)

## Research Decisions

### 1. Carga Completa del Catálogo Global (`vifutboldev.teams` + `tournament_teams`)
- **Decision**:
  - Extender `PostgrestTeamsRemoteDataSource.fetchAll()` en `lib/infrastructure/repositories/hybrid_teams_repository.dart` para que además de consultar `vifutboldev.tournament_teams` (equipos ya inscritos en algún torneo con su plantilla `players(*)` y `tournaments(category)`), consulte también `vifutboldev.teams` incluyendo `user_accounts(full_name)` (vía `coach_id`) y agregue cualquier club autónomo del catálogo global (`teams` sin filas en `tournament_teams`) como un `TournamentTeam` con `tournamentId: ''`, `categoryLabel` y `coachName`.
  - Disparar `ref.read(teamsControllerProvider.notifier).loadTeams()` en `AddTeamsToCompetitionModal.initState()` (mediante `Future.microtask`) para garantizar que cada vez que el organizador abra `"Agregar Equipos"` desde el FAB Menu se refresque el catálogo global completo desde el repositorio híbrido (`teamsRepository.loadTeams()`).
- **Rationale**:
  - Anteriormente `PostgrestTeamsRemoteDataSource.fetchAll()` solo consultaba `from('tournament_teams')`. Como consecuencia, los clubes creados por entrenadores en `vifutboldev.teams` que aún no estaban inscritos en ningún torneo nunca aparecían en `teamsControllerProvider.state.teams` ni en `AddTeamsToCompetitionModal`.
  - Al combinar `teams` + `tournament_teams` en `fetchAll()` y refrescar al abrir el modal, el 100% del universo de clubes registrados en la plataforma (en nube y caché local) queda disponible para inscripción sin duplicar fuentes de estado.
- **Alternatives Considered**:
  - *Consumir `teamsDirectoryControllerProvider` por separado*: Descartado porque `TeamDirectoryItem` no contiene la lista completa de `RegisteredPlayer` necesaria para clonar/preservar la plantilla al inscribir el club mediante `enrollExistingTeamFromCatalog`. Enriquecer `TournamentTeam` con `categoryLabel` y `coachName` e incluir clubes autónomos en `fetchAll()` unifica ambos mundos limpiamente.

### 2. Metadatos de Categoría y Entrenador Responsable en `TournamentTeam` y `CatalogTeamEntry`
- **Decision**:
  - Agregar los campos opcionales `categoryLabel` (`String?`) y `coachName` (`String?`) a `TournamentTeam` (con soporte retrocompatible en `copyWith`, `toJson` y `fromJson`).
  - Al construir `CatalogTeamEntry` en `buildGlobalCatalogEntries`:
    - Preservar `categoryLabel` (si existe en alguna instancia del club o del torneo asociado; si es nulo o vacío, la UI muestra `"Categoría libre"`, según la Clarificación Q1).
    - Preservar `coachName` cuando esté resuelto desde `user_accounts.full_name` (o metadato local); si `coachName` es nulo o vacío, ocultar el dato de entrenador en la tarjeta sin mostrar UUIDs ni etiquetas vacías (según la Clarificación Q2).
- **Rationale**:
  - Satisface `FR-001` y `FR-002` y las decisiones de `/speckit-clarify` sin romper ningún test existente de `TournamentTeam`.
- **Alternatives Considered**:
  - *Hacer consultas individuales por cada fila en el modal*: Descartado por latencia y complejidad N+1.

### 3. Restricción Estricta de Creación de Equipos para el Rol Organizador
- **Decision**:
  - Garantizar que `AddTeamsToCompetitionModal` no renderice ningún botón, enlace ni formulario de creación de clubes en ningún estado (cargando, con datos, búsqueda vacía o catálogo vacío).
  - Actualizar el texto `addTeamsEmptyCatalogMessage` en `lib/l10n/app_es.arb` al mensaje exacto de la HU 18.5: `"No hay equipos registrados en la plataforma. Los entrenadores deben registrar sus clubes antes de poder inscribirlos en el campeonato."`
  - Reemplazar la invocación legada de `CompetitionEnrollTeamDialog.show` en `lib/presentation/panel/widgets/organizer_panel_content.dart` por `AddTeamsToCompetitionModal.show` para que ningún punto de entrada del organizador abra formularios de creación manual de equipos.
- **Rationale**:
  - Cumple la matriz de permisos de gobernanza deportiva (HU 16.2 y `FR-003` / `SC-002`).
- **Alternatives Considered**:
  - *Ocultar el botón solo mediante bandera condicional*: Descartado; el modal de competición es por definición un selector/inscriptor de catálogo.

### 4. Flujo de Inscripción Múltiple Sin Cerrar el Modal
- **Decision**:
  - Mantener abierto `AddTeamsToCompetitionModal` tras cada inscripción exitosa (`enrollExistingTeamFromCatalog`), actualizando reactivamente el botón de la fila a `"Inscrito"` (deshabilitado), mostrando el banner de confirmación en línea y refrescando instantáneamente `CompetitionTeamsTabView` mediante `teamsControllerProvider`.
- **Rationale**:
  - Confirmado en la Clarificación Q3 (`FR-007`), permitiendo inscribir múltiples clubes en una sola sesión.
