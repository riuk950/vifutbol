# Research & Technical Decisions: Gestión de Convocatorias, Alineaciones y Seguimiento Interno por el Entrenador (HU 5.2)

**Feature**: `006-coach-lineups-tracking`  
**Date**: 2026-11-04

## 1. Integración de Navegación y Experiencia por Rol (`FR-001`, `FR-005`)

- **Decision**: Incorporar en `TeamRosterDetailScreen` (`/tournaments/teams/detail`) un acceso directo (`"Convocatoria y Seguimiento"` / `"Nómina Oficial del Partido"`) que navegue hacia `CoachLineupTrackingScreen` (`/tournaments/teams/lineup`), organizada en 3 secciones/pestañas internas adaptadas al rol activo:
  1. **Convocatoria del Partido**: Disponible para `Entrenador` (`RoleCapability.manageLineups`) y `Organizador` (`RoleCapability.manageTournaments`), permitiendo clasificar a cada jugador habilitado en `Titular`, `Suplente` o `No convocado`, designar al `Capitán` entre los titulares y publicar/reconfirmar la alineación oficial.
  2. **Seguimiento Interno**: Disponible para `Entrenador` y `Organizador` (y consulta para `Jugador`/`Árbitro`), mostrando las métricas acumuladas del plantel (`partidos`, `goles`, `asistencias`, `amarillas`, `rojas` y `estado disciplinario`) con la posibilidad de que el `Entrenador`/`Organizador` actualice el registro interno de un jugador.
  3. **Acta Arbitral Sincronizada**: Disponible para el `Árbitro` (`RoleCapability.recordMatchEvents` / `RoleCapability.closeMatchReport`), `Entrenador` y `Organizador`, mostrando en tiempo real los titulares (con insignia de capitán) y suplentes habilitados de la última convocatoria oficial confirmada.
- **Rationale**: Preserva intactas las 4 pestañas principales de `AppShellScreen` y mantiene un flujo natural desde el campeonato → equipo → convocatoria/seguimiento/acta arbitral.
- **Alternatives considered**:
  - Añadir una 5ª pestaña inferior en `AppShellScreen`: descartado porque rompe la arquitectura de navegación de 4 destinos definida en `DESIGN.md`.

## 2. Evaluación Determinista de Sanciones y Reglas de Convocatoria (`FR-002`, `FR-003`)

- **Decision**: Crear una entidad `PlayerInternalTracking` y un método determinista de evaluación disciplinaria en función de `TournamentRulesConfig.yellowCardSuspensionLimit`:
  - Un jugador se considera **Suspendido** (`PlayerDisciplinaryStatus.suspended`) si `pendingSuspensionMatches > 0` o si `yellowCards >= yellowCardSuspensionLimit` (cuando las amarillas acumuladas alcanzan el umbral de suspensión del torneo, equivale al menos a `1` fecha de suspensión pendiente).
  - Un jugador se considera en **Riesgo de Amarillas / En Capilla** (`PlayerDisciplinaryStatus.warningAccumulation`) si no está suspendido y `yellowCards == yellowCardSuspensionLimit - 1` (con `yellowCardSuspensionLimit > 1`).
  - La cantidad reglamentaria de titulares en cancha (`requiredStarters`) se calcula como `min(tournament.rules.minPlayersPerTeam, 11)` (por ejemplo, `7` titulares para Fútbol 7).
  - En entorno `dev`, el equipo semilla `'team-seed-atletico-norte'` contará con `10` jugadores inscritos (`7` posibles titulares + `2` suplentes + `1` jugador suspendido por `1 fecha`), garantizando que el `Entrenador` pueda completar y confirmar inmediatamente una convocatoria reglamentaria de `7` titulares y suplentes mientras verifica el bloqueo del jugador sancionado `"Suspendido (1 fecha)"`.
- **Rationale**: Conecta las reglas personalizadas del torneo (`HU 4.1`) y las plantillas de equipos (`HU 5.1`) con los escenarios Gherkin de Fase 1 y Fase 2 de la `HU 5.2`.
- **Alternatives considered**:
  - Dejar solo 7 jugadores en el equipo semilla con 1 suspendido: descartado porque dejaría solo 6 jugadores elegibles, impidiendo completar los 7 titulares requeridos sin antes inscribir otro jugador manualmente.

## 3. Conservación del Borrador ante Interrupciones Móviles (`FR-006`)

- **Decision**: Persistir de forma inmediata en `LocalStorageRepository` cada cambio en la selección de titulares, suplentes o capitán como borrador (`MatchLineupConvocation` con `status: ConvocationStatus.draft` o `hasUnsavedChanges: true` junto a la última versión confirmada) y suscribir `CoachLineupTrackingScreen` a `WidgetsBindingObserver` (`didChangeAppLifecycleState`) para garantizar que al pasar a `paused`/`inactive` y regresar a `resumed`, o al reabrir la pantalla, la selección parcial permanezca intacta.
- **Rationale**: Satisface el escenario Gherkin de Fase 3 (*"Conservación de la selección de convocatoria al pasar la app a segundo plano"*) y `docs/MOBILE_GUIDELINES.md`.
- **Alternatives considered**:
  - Mantener la selección únicamente en un `State` efímero de widget sin respaldo en controlador/almacenamiento local: descartado porque se perdería al recrear la ruta o reiniciar el árbol de widgets tras una interrupción del sistema operativo.
