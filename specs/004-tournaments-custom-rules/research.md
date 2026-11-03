# Phase 0 Research: Creación de Campeonatos (Ligas y Copas Eliminatorias) y Reglas Personalizadas (HU 4.1)

**Feature**: `004-tournaments-custom-rules`  
**Date**: 2026-04-17

## 1. Modelado de Formatos de Campeonato y Reglas Personalizadas (`ChampionshipTournament` & `TournamentRulesConfig`)

- **Decision**: Modelar un agregado de dominio inmutable `ChampionshipTournament` acompañado de un objeto de valor `TournamentRulesConfig` que encapsula:
  - Sistema de puntuación (`pointsForWin`, `pointsForDraw`, `pointsForLoss`, con invariante `pointsForWin > pointsForDraw >= pointsForLoss >= 0` y valores por defecto `3 / 1 / 0`).
  - Lista ordenada y sin duplicados de criterios de desempate `List<TiebreakerCriterion>` (`goalDifference`, `goalsFor`, `headToHead`, `fairPlay`).
  - Reglas disciplinarias y operativas (`yellowCardSuspensionLimit` en rango `2..10`, `minPlayersPerTeam` y `maxPlayersPerTeam` en rango `5 <= min <= max <= 35`, `halfDurationMinutes` en rango `10..60`).
  - Configuración específica según `TournamentFormat`:
    - `league`: `leagueRounds` (`1` o `2` vueltas).
    - `knockoutCup`: `KnockoutStageConfig` (`startingRound`: `roundOf16`, `quarterFinals`, `semiFinals`, `finalMatch`; `twoLeggedTies`: `bool`; `directPenaltyShootoutOnDraw`: `bool`).
    - `mixedGroupsAndKnockout`: `GroupStageConfig` (`groupCount` en `2..8`, `advancingPerGroup` en `1..4` de forma independiente según la clarificación `FR-002`) + `KnockoutStageConfig`.
- **Rationale**: Mantiene todas las invariantes de negocio de HU 4.1 en la capa de dominio pura (Dart sin dependencias de Flutter ni de almacenamiento), permitiendo que épicas posteriores (inscripción de equipos, fixture, tabla de posiciones y sanciones) consuman `TournamentRulesConfig` como única fuente de verdad determinista.
- **Alternatives considered**:
  - Guardar las reglas como un mapa JSON libre sin tipado fuerte: descartado por violar el Principio II de la Constitución (*Integridad de Datos y Fuente de Verdad Transparente*).

## 2. Máquina de Estados del Campeonato e Inmutabilidad Auditada en Estado `En Curso` (`FR-004`, `FR-005`)

- **Decision**: Definir `TournamentStatus` con tres estados ordenados (`openRegistration`, `inProgress`, `finished`).
  - Todo campeonato nuevo nace en `TournamentStatus.openRegistration` (`"Inscripciones Abiertas"`).
  - Cuando un campeonato se encuentra en `TournamentStatus.inProgress` (`"En Curso"`), la validación del caso de uso `ManageTournamentsUseCase.saveTournament` compara el formato (`format`) y los puntos (`pointsForWin`, `pointsForDraw`, `pointsForLoss`) contra la versión persistida. Si alguno de estos campos críticos cambia y no se provee confirmación administrativa explícita (`confirmCriticalRuleOverride: true`) junto con un motivo no vacío (`auditReason`), lanza un `TournamentValidationFailure` (`criticalRulesImmutableWithoutAudit`).
  - Si la confirmación y el motivo están presentes, el caso de uso anexa automáticamente una entrada `RuleAuditEntry` (`recordedAt`, `summary` describiendo el cambio de valores anteriores → nuevos, `reason`, `recalculationConfirmed: true`) a `auditTrail` del campeonato.
  - Cuando un campeonato está en `TournamentStatus.finished` (`"Finalizado"`), no se permiten mutaciones de reglas ni de formato.
- **Rationale**: Satisface de forma determinista y verificable mediante tests unitarios la Regla de Negocio 3 de Notion y la clarificación acordada para `FR-005`.
- **Alternatives considered**:
  - Validar la inmutabilidad únicamente ocultando campos en la UI: descartado porque la capa de dominio/aplicación debe hacer cumplir las reglas críticas independientemente de la vista.

## 3. Conservación Local de Borrador Móvil y Protección de Salida (`FR-006`)

- **Decision**: Implementar persistencia de borrador en `TournamentsRepository` (`saveDraft`, `loadDraft`, `clearDraft`) respaldada por `LocalStorageRepository` bajo la clave `vifutbol.tournaments.creation_draft.v1`.
  - En `TournamentFormScreen` (modo creación), escuchar cambios de campos y `AppLifecycleListener` (`onStateChange` hacia `inactive`/`paused`/`hidden`) para autoguardar silenciosamente el borrador cuando existan cambios (`isDirty == true`).
  - Envolver `TournamentFormScreen` (tanto en creación como en edición) con `PopScope(canPop: false)` para interceptar el retroceso cuando `isDirty == true` y presentar el diálogo oficial `"¿Deseas descartar los cambios o guardar como borrador?"` con acciones explícitas.
  - Al publicar un campeonato nuevo o elegir `"Descartar cambios"`, limpiar el borrador almacenado.
- **Rationale**: Cumple el Principio VII de la Constitución (`docs/MOBILE_GUIDELINES.md`) y el Escenario Gherkin 3 de Notion sin requerir dependencias externas nuevas.
- **Alternatives considered**:
  - Mantener el borrador solo en memoria de Riverpod: descartado porque se perdería si el sistema operativo cierra el proceso en segundo plano.

## 4. Integración Visual en `StandingsTabView` y Sistema de Diseño `Kick Pulse`

- **Decision**: Evolucionar `StandingsTabView` (pestaña `Posiciones` del `AppShellScreen`) para presentar el Centro de Campeonatos y Normativa Oficial bajo la estética `Kick Pulse` (`DESIGN.md`):
  - Selector horizontal de campeonatos activos/abiertos con chips de formato y estado (`Inscripciones Abiertas` en `#00E676`, `En Curso` en `#D0FF00`, `Finalizado` en `#8E95A9`).
  - Vista estructurada del campeonato seleccionado: resumen de formato y fechas, tarjeta de sistema de puntuación (`3 / 1 / 0`), lista numerada de criterios de desempate, tarjeta de reglas disciplinarias/operativas (límite de amarillas, cupo de jugadores, duración por tiempo), vista previa de estructura de llaves eliminatorias (`Octavos`, `Cuartos`, `Semifinal`, `Final` con indicador de penales directos) o fase de grupos, e historial de auditoría (`RuleAuditEntry`) si existen recálculos auditados.
  - Controles exclusivos para `Organizador` (`RoleCapability.manageTournaments`): botón `"Crear Campeonato"`, acción `"Editar Reglas"` y selector de transición de estado (`"Iniciar Campeonato (En Curso)"` / `"Finalizar Campeonato"`).
- **Rationale**: Reutiliza la estructura de 4 pestañas existente sin alterar la barra inferior del shell y prepara `StandingsTabView` para mostrar tanto la normativa oficial como las tablas/llaves de los torneos.
- **Alternatives considered**:
  - Añadir una quinta pestaña al `BottomNavigationBar`: descartado porque el shell de `vifutbol` está estandarizado en 4 secciones (`Jornada`, `Posiciones`, `Sedes`, `Perfil`).
