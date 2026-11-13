# Feature Specification: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (HU 19.1)

**Feature Branch**: `develop`  
**Feature Directory**: `specs/039-players-directory-cloud-sync`  
**Created**: 2026-11-13  
**Status**: Draft  
**Input**: User description: "HU 19.1: Directorio de Jugadores: Remoción de Filter Chips y Carga Dinámica desde Supabase Cloud (vifutboldev)" (Notion ID: `4178442e-3f49-81da-8859-d9017ca47306`)

---

## Clarifications

### Session 2026-11-13

- Q: ¿Cómo debe estructurarse la consulta y el acceso a los datos de `vifutboldev.players` para alimentar el directorio de jugadores? → A: Incorporar en `TeamsRepository` / `HybridTeamsRepository` un método explícito `loadAllPlayers()` que consulte `vifutboldev.players` (con sus relaciones de equipo y torneo) y actualice la caché local de Hive.
- Q: ¿Cómo deben tratarse las propiedades y métodos de filtrado por torneo en `PlayersDirectoryState` y `PlayersDirectoryController` tras la eliminación de los chips en la interfaz? → A: Eliminar por completo `selectedTournamentId`, `availableTournaments` y `selectTournament()`, dejando el controlador enfocado únicamente en la nómina global y la búsqueda reactiva.
- Q: ¿Cuál debe ser el criterio de ordenamiento por defecto de la nómina global de jugadores en el directorio? → A: Orden alfabético ascendente (A-Z) por nombre completo (`fullName`) insensible a mayúsculas y acentos.
- Q: ¿Cómo debe responder la interfaz del directorio si el usuario ejecuta un gesto de recarga (Pull-to-Refresh) mientras el dispositivo se encuentra sin conexión a internet? → A: Mantener los datos locales en pantalla y emitir un SnackBar informativo no intrusivo indicando la ausencia de conexión a la nube.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Remoción de Filter Chips Horizontales y Vista Centralizada (Priority: P1) 🎯 MVP

Como usuario de la aplicación (`organizer`, `coach`, `referee`, `player`, `fan`), quiero ingresar a la pantalla de Directorio de Jugadores y visualizar una vista limpia sin chips de filtro horizontal por torneo, de modo que el espacio superior quede dedicado a la búsqueda y pueda explorar toda la nómina de jugadores sin segmentación obligada.

**Why this priority**: Elimina fricción visual y cognitiva en la pantalla, permitiendo búsquedas instantáneas y transversales en todos los torneos.

**Independent Test**: Abrir la pantalla de "Directorio de Jugadores" y verificar que no existen `ChoiceChip`s ni scroll horizontal de torneos, manteniendo la barra de búsqueda reactiva en la cabecera.

**Acceptance Scenarios**:

1. **Given** que el usuario navega a la pantalla "Directorio de Jugadores", **When** la pantalla se renderiza, **Then** ya no se visualiza la fila horizontal de chips ("Todos", torneo A, torneo B) y el espacio superior queda dedicado a la barra de búsqueda reactiva.
2. **Given** la pantalla de directorio de jugadores sin chips, **When** el usuario interactúa con la barra de búsqueda, **Then** el campo de texto filtra de forma instantánea sobre todos los futbolistas cargados.

---

### User Story 2 - Carga Dinámica desde Supabase Cloud (`vifutboldev.players`) con Caché Hive (Priority: P1) 🎯 MVP

Como usuario de la aplicación, quiero que el directorio de jugadores obtenga la nómina en tiempo real desde la nube (`vifutboldev.players` en Supabase DEV) con sus relaciones (equipo y posición), respaldando la información en Hive para consultas offline inmediatas y sin errores de red.

**Why this priority**: Garantiza que el directorio refleje exactamente los futbolistas registrados en la base de datos cloud centralizada y mantenga la capacidad offline-first requerida por la constitución.

**Independent Test**: Con conexión a internet en DEV, abrir el directorio y confirmar que los futbolistas provienen de Supabase; desconectar la red y verificar que la nómina local en Hive se presenta sin fallos ni bloqueos.

**Acceptance Scenarios**:

1. **Given** que el dispositivo cuenta con conexión a internet en entorno DEV, **When** se inicializa o refresca el directorio de jugadores, **Then** el sistema consulta la tabla `vifutboldev.players` en Supabase DEV y puebla la lista reflejando los futbolistas existentes en la base de datos remota.
2. **Given** que el dispositivo no tiene internet al abrir el directorio, **When** el controlador solicita la lista de jugadores, **Then** recupera transparentemente la última nómina persistida en la caché local de Hive sin arrojar errores fatales.
3. **Given** una carga remota exitosa desde Supabase, **When** finaliza la consulta, **Then** la caché local de Hive queda automáticamente actualizada con la última nómina.

---

### User Story 3 - Búsqueda Reactiva Multi-campo Insensible a Acentos (Priority: P2)

Como usuario, quiero buscar jugadores por nombre, apellido, dorsal, nombre de equipo, código corto o posición con debounce y sin distinguir mayúsculas ni acentos, para ubicar rápidamente a cualquier futbolista del campeonato.

**Why this priority**: Facilita la localización rápida de jugadores en torneos con cientos de inscritos.

**Independent Test**: Escribir en la barra de búsqueda un término con tilde o minúsculas (ej. "gonzález", "10", "delantero") y verificar que los resultados se filtran en menos de 300 ms sin reiniciar la pantalla.

**Acceptance Scenarios**:

1. **Given** la lista de jugadores cargada, **When** el usuario escribe en la barra de búsqueda, **Then** el filtrado se ejecuta con debounce de 300 ms y búsqueda insensible a mayúsculas y acentos sobre nombre, dorsal, equipo y posición.
2. **Given** un texto de búsqueda sin coincidencias, **When** concluye la búsqueda, **Then** la vista muestra el estado vacío informativo correspondiente de KickPulse sin errores.

---

## Edge Cases

- **Sin conexión inicial y caché vacía**: Muestra estado vacío con mensaje amigable invitando a sincronizar o conectar a red.
- **Tiempos de espera o caída de Supabase**: Degrada silenciosamente a la caché de Hive; si falla la red y no hay caché, muestra vista de reintento controlada.
- **Pull-to-Refresh sin conexión**: Mantiene la nómina de futbolistas locales previamente renderizada y despliega un SnackBar informativo no intrusivo notificando la falta de conectividad sin bloquear la UI.
- **Jugadores sin equipo o torneo asignado**: Se renderizan con etiquetas de respaldo sin provocar excepciones de valor nulo.
- **Caracteres especiales en búsqueda**: Normalización Unicode para tildes y caracteres diacríticos (`á` = `a`, `ñ` preservada).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: La pantalla `PlayersDirectoryScreen` DEBE eliminar completamente la fila horizontal de `ChoiceChip`s y el widget de selección de torneo (`Key('players_tournament_selector')`).
- **FR-002**: `TeamsRepository` y `HybridTeamsRepository` DEBEN proveer un método `loadAllPlayers()` que consulte la tabla remota `vifutboldev.players` en Supabase DEV (incluyendo datos de equipo y torneo) e hidrate la caché local de respaldo en Hive.
- **FR-003**: Toda consulta remota exitosa de jugadores DEBE actualizar la caché local en Hive para soporte offline.
- **FR-004**: Ante ausencia de conectividad o falla remota, `loadAllPlayers()` DEBE servir los jugadores almacenados en la caché de Hive sin interrumpir la experiencia de usuario ni generar excepciones no controladas.
- **FR-005**: La barra de búsqueda DEBE mantener debounce de 300 ms y comparación insensible a acentos/mayúsculas abarcando nombre, dorsal, equipo y posición.
- **FR-006**: Se DEBE proveer mecanismo de recarga (Pull-to-Refresh) en la pantalla para refrescar la nómina desde la nube; si la recarga falla por falta de conexión, se DEBEN mantener los datos locales y mostrar un SnackBar informativo.
- **FR-007**: Se DEBEN eliminar de `PlayersDirectoryState` y `PlayersDirectoryController` las propiedades y métodos `selectedTournamentId`, `availableTournaments` y `selectTournament()`, eliminando el acoplamiento con `tournamentsControllerProvider`.
- **FR-008**: La nómina de jugadores en el directorio DEBE ordenarse por defecto de forma alfabética ascendente (A-Z) por nombre completo (`fullName`) insensible a mayúsculas y acentos.

### Key Entities

- **PlayerDirectoryItem**: Proyección de presentación que encapsula el jugador (`RegisteredPlayer`), ID de equipo, nombre de equipo, código corto y torneo asociado.
- **RegisteredPlayer**: Entidad del dominio con `id`, `tournamentTeamId`, `tournamentId`, `fullName`, `documentId`, `shirtNumber`, `position`, `isEligible`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 0 `ChoiceChip`s de torneo presentes en `PlayersDirectoryScreen` verificado mediante pruebas de widget.
- **SC-002**: Carga remota de jugadores completada y almacenada en caché local en menos de 1.5 segundos con conexión estándar.
- **SC-003**: Disponibilidad de datos offline inmediata (latencia < 50 ms) recuperando desde Hive en modo avión.
- **SC-004**: 100% de pruebas unitarias y de widgets del directorio de jugadores pasando satisfactoriamente.
- **SC-005**: Cero errores de análisis estático (`flutter analyze`).

---

## Assumptions

- La tabla `vifutboldev.players` y sus claves foráneas a `vifutboldev.tournament_teams` y `vifutboldev.tournaments` están operativas en Supabase DEV.
- Los permisos de lectura de `vifutboldev.players` y `vifutboldev.tournament_teams` son públicos para usuarios autenticados según las políticas RLS existentes.
