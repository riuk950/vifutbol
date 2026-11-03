# Phase 0 Research: Registro Oficial de Equipos, Inscripción de Jugadores y Validación de Elegibilidad (HU 5.1)

**Feature**: `005-teams-players-eligibility`  
**Date**: 2026-04-17

## 1. Integridad Deportiva Determinista: Unicidad de Equipo, Dorsal y Jugador por Campeonato (`FR-003`, `FR-004`, `FR-005`)

- **Decision**: Implementar todas las reglas de unicidad y elegibilidad en el caso de uso `ManageTeamsEligibilityUseCase` operando sobre el conjunto de equipos (`List<TournamentTeam>`) de un `ChampionshipTournament`:
  1. **Unicidad de Nombre de Equipo por Campeonato (`FR-003`)**: Normalizar `name.trim().toLowerCase()` y rechazar si otro equipo con distinto `id` pero el mismo `tournamentId` posee el mismo nombre normalizado (`TeamEligibilityErrorCode.duplicateTeamNameInTournament`).
  2. **Unicidad de Dorsal dentro del Equipo (`FR-004`)**: Validar que `shirtNumber` esté en el rango `1..99` y que ningún otro jugador en `team.players` (con distinto `id`) tenga el mismo `shirtNumber`. Si colisiona, lanzar `TeamEligibilityValidationFailure` con código `duplicateShirtNumberInTeam` y el mensaje exacto requerido por Gherkin: `"El número de camiseta $shirtNumber ya está en uso en este equipo."`.
  3. **Exclusividad de Jugador por Campeonato (`FR-005`)**: Normalizar `documentId.trim().toUpperCase()` y recorrer todos los equipos del mismo `tournamentId`. Si el documento ya pertenece a un jugador inscrito en otro equipo del mismo campeonato (o repetido en el mismo equipo), lanzar `TeamEligibilityValidationFailure` con código `playerAlreadyRegisteredInTournament` y el mensaje exacto requerido por Gherkin: `"Este jugador ya se encuentra inscrito en otro equipo de este campeonato."`.
- **Rationale**: Satisface 100% los escenarios Gherkin de la Fase 2 de Notion y el Principio II de la Constitución (*Integridad de Datos y Fuente de Verdad Transparente*) sin depender de consultas de red.
- **Alternatives considered**:
  - Validar únicamente en el widget del formulario: descartado porque la capa de dominio/aplicación debe garantizar la integridad en pruebas unitarias aisladas.

## 2. Validación de Cupos Reglamentarios y Máquina de Elegibilidad del Equipo (`FR-006`)

- **Decision**: Conectar `TournamentTeam` con `ChampionshipTournament.rules` (`minPlayersPerTeam` y `maxPlayersPerTeam`):
  - Definir `TeamEligibilityStatus`:
    - `pendingQuota`: la plantilla tiene `< minPlayersPerTeam` jugadores.
    - `readyForApproval`: la plantilla alcanza `>= minPlayersPerTeam` y `<= maxPlayersPerTeam`, pendiente de habilitación por el `Organizador`.
    - `eligible` (`"Habilitado"`): aprobado por el `Organizador` (`RoleCapability.approveRegistrations`) cumpliendo `minPlayersPerTeam <= players.length <= maxPlayersPerTeam`.
  - Cuando se agrega un jugador: si `players.length >= maxPlayersPerTeam`, se rechaza con `squadMaxQuotaReached`. Si el equipo estaba en `pendingQuota` y alcanza `minPlayersPerTeam`, pasa automáticamente a `readyForApproval`.
  - Cuando se remueve un jugador: si `players.length < minPlayersPerTeam`, incluso si el equipo estaba `eligible`, su estado revierte automáticamente a `pendingQuota` y `isEligible` de los jugadores se sincroniza con la elegibilidad del equipo.
  - Cuando el `Organizador` ejecuta `approveTeamEligibility`: verifica `RoleCapability.approveRegistrations` y que `players.length >= tournament.rules.minPlayersPerTeam`; de lo contrario lanza `insufficientPlayersForApproval`.
- **Rationale**: Garantiza coherencia automática entre las reglas personalizadas de la HU 4.1 y la nómina real de cada equipo.
- **Alternatives considered**:
  - Permitir habilitar equipos sin verificar `minPlayersPerTeam`: descartado por violar la Regla de Negocio 3 de la HU 5.1.

## 3. Escudo Vectorial Nativo Offline-First (`KickPulseTeamCrest`) (`FR-001`)

- **Decision**: Representar la identidad visual de cada equipo con:
  - `shortCode`: monograma/sigla de `2` a `4` caracteres en mayúsculas (ej. `"ATN"`, `"RSB"`).
  - `crestShape`: enumeración `TeamCrestShape` (`shield`, `circle`, `diamond`, `hexagon`).
  - `primaryColorHex` y `secondaryColorHex`: colores seleccionados desde una paleta curada de alta legibilidad sobre el tema oscuro `#0A0E17` (`KickPulseColors`).
- **Rationale**: Funciona 100% offline, se renderiza a 60 fps y cumple la clarificación acordada en `/speckit-clarify`.
- **Alternatives considered**:
  - Carga de archivos binarios externos: descartado por dependencia de red y almacenamiento pesado.

## 4. Integración en `StandingsTabView` y Vista Dedicada de Plantilla (`/tournaments/teams/detail`) (`FR-008`)

- **Decision**:
  - En `StandingsTabView`, debajo de `TournamentRulesSummaryCard` del campeonato seleccionado, mostrar la sección `"Equipos Inscritos"` con contador de equipos habilitados/totales, botón `"Inscribir Equipo"` (visible para `Organizador` y `Entrenador` cuando el campeonato está en `"Inscripciones Abiertas"`) y tarjetas por cada equipo mostrando su escudo vectorial, progreso de cupo (`X / min..max jugadores`), estado (`Pendiente de Cupo`, `Listo para Habilitar`, `Habilitado`) y acceso rápido a su plantilla.
  - Al tocar un equipo, navegar a `TeamRosterDetailScreen` (`/tournaments/teams/detail`), donde todos los roles consultan la nómina ordenada por dorsal, y `Organizador`/`Entrenador` pueden agregar/editar/remover jugadores con teclado numérico automático (`TextInputType.number`) para documento y dorsal, mientras que el `Organizador` dispone del botón `"Habilitar Equipo"`.
- **Rationale**: Flujo intuitivo de dos niveles que mantiene las 4 pestañas principales del shell y cumple todas las directrices móviles (`docs/MOBILE_GUIDELINES.md`).
- **Alternatives considered**:
  - Mostrar todos los jugadores de todos los equipos desplegados en la misma tarjeta de `StandingsTabView`: descartado por saturar el scroll vertical en pantallas móviles.
