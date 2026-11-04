# Phase 0 Research: Acta Digital del Árbitro: Registro en Tiempo Real de Goles, Asistencias, Tarjetas y Soporte Offline (HU 7.1)

**Date**: 2026-11-04  
**Feature**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/008-referee-digital-match-report/spec.md)

## 1. Cronómetro Resiliente al Ciclo de Vida y Segundo Plano

- **Decision**: Calcular el tiempo transcurrido y el minuto oficial del partido mediante diferencias deterministas de marcas de tiempo (`DateTime.now().difference(periodStartedAt).inSeconds + elapsedSecondsBeforeCurrentPeriod`), en lugar de depender de contadores incrementales en memoria (`Timer.periodic` sumando `+1`).
- **Rationale**: Si el árbitro bloquea la pantalla del teléfono, recibe una llamada o cambia de aplicación en cancha, el sistema operativo pausa o ralentiza los *timers* de UI en segundo plano. Al persistir `periodStartedAt` (UTC ISO-8601) y `elapsedSecondsBeforeCurrentPeriod` en `DigitalMatchReport`, cualquier reconstrucción de widget o retorno desde segundo plano muestra el segundo y minuto exactos con 0 segundos de desfase (`SC-004`). El minuto oficial de una incidencia se calcula como `((totalElapsedSeconds ~/ 60) + 1).clamp(1, 120)` o el minuto indicado manualmente por el árbitro en el formulario de evento.
- **Alternatives considered**:
  - Incrementar un entero `elapsedSeconds++` dentro de un `Timer.periodic`: descartado porque pierde tiempo real cuando la app entra en estado `paused` o `inactive`.
  - Mantener un servicio nativo en primer plano (*foreground service*) de Android/iOS: innecesario y costoso en batería cuando el cálculo algebraico por marcas de tiempo persistidas resuelve el problema con exactitud matemática.

## 2. Regla de Doble Amarilla y Bloqueo Automático del Jugador Expulsado

- **Decision**: Encapsular en el dominio y en `ManageDigitalMatchReportUseCase` la evaluación disciplinaria del partido: al registrar un evento `MatchEventType.yellowCard` para un `primaryPlayerId` que ya posee una tarjeta amarilla previa activa en el mismo encuentro, el caso de uso registra la segunda amarilla y genera atómicamente el evento consecutivo `MatchEventType.secondYellowRedCard` (expulsión por doble amarilla) en el mismo minuto, añadiendo al jugador al conjunto computado `expelledPlayerIds` del acta.
- **Rationale**: Cumple de manera determinista con el escenario Gherkin de la Fase 1 (jugador con dorsal `"5"` en el minuto 68) y con `FR-004` / `FR-005`. Además, al calcular `expelledPlayerIds` dinámicamente a partir de la lista de eventos activos del acta (`directRedCard` o `secondYellowRedCard`), si el árbitro anula por error la segunda amarilla mientras el partido sigue `"En Juego"` (`FR-008`), se revierte automáticamente la expulsión asociada sin dejar estados huérfanos.
- **Alternatives considered**:
  - Exigir que el árbitro registre manualmente una tarjeta roja después de registrar la segunda amarilla: descartado porque contradice la regla de negocio #2 y el escenario Gherkin de expulsión automática.
  - Guardar un booleano mutable separado en la entidad del jugador: descartado porque derivar el estado de expulsión del partido directamente desde `DigitalMatchReport.events` garantiza consistencia total ante anulaciones en vivo.

## 3. Operación Offline-First, Cola Local e Idempotencia sin Duplicados

- **Decision**: Implementar `LocalMatchReportsRepository` sobre `LocalStorageRepository` (claves `'vifutbol.match_reports.v1'` y `'vifutbol.match_events_sync_queue.v1'`). Cada `MatchEvent` recibe un identificador único determinista/UUID al crearse y un flag `isSynced`. Cuando el acta opera en modo sin conexión (`isOfflineMode == true`), los eventos se guardan inmediatamente en el acta local con `isSynced: false` y se encolan en la cola de sincronización pendiente, mostrando el banner `"Modo sin conexión: cambios guardados en el dispositivo"`. Al recuperar la conexión (`synchronizePendingEvents`), el repositorio procesa la cola deduplicando por `event.id` (idempotencia estricta) y marca todos los eventos del acta con `isSynced: true` y `pendingSyncCount: 0`.
- **Rationale**: Satisface el principio II y las restricciones Offline-First de la Constitución, así como el escenario Gherkin de Fase 2 (`FR-007`, `SC-003`). Incluir un conmutador reactivo de conectividad en la barra superior del acta digital permite tanto reaccionar al estado de red del dispositivo como simular y verificar en pruebas de widget e inspección en cancha la transición offline → online sin pérdida ni duplicidad de datos.
- **Alternatives considered**:
  - Bloquear los botones de registro cuando no hay red: descartado porque impide el arbitraje en canchas sin cobertura móvil.
  - Sincronizar por posición de lista en vez de `event.id` único: descartado por riesgo de duplicar goles si se reintenta un lote parcial.

## 4. Cierre Inmutable del Acta y Propagación a Partidos y Estadísticas

- **Decision**: Al ejecutar `closeOfficialMatchReport` (`"Cerrar Acta Oficial"`), el caso de uso valida que el usuario sea `Árbitro` (`RoleCapability.closeMatchReport`) u `Organizador` (`RoleCapability.manageTournaments`), sella el `DigitalMatchReport` con `currentPeriod: MatchPeriod.closed`, `closedAt`, `closedByUserId`, sincroniza o marca el estado final en `TournamentMatchesRepository` cambiando el `ChampionshipMatch.status` a `MatchStatus.completed` (guardando además `homeScore` y `awayScore` en el partido para visualización directa en `MatchCard`), y actualiza las métricas acumuladas de goles, asistencias, tarjetas amarillas, tarjetas rojas y fechas de suspensión en `LineupsTrackingRepository` (`PlayerInternalTracking`).
- **Rationale**: Conecta de extremo a extremo la Épica 5 (seguimiento disciplinario y suspensiones), la Épica 6 (estado `"Finalizado"` y marcador en el calendario de jornadas) y la Épica 7 (inmutabilidad del acta cerrada), dejando listos los datos oficiales para el cálculo de tablas de posiciones en la Épica 8.
- **Alternatives considered**:
  - No reflejar el marcador en `ChampionshipMatch`: descartado porque las tarjetas de partido en `MatchdayTabView` necesitan mostrar el resultado en vivo y final (`homeScore - awayScore`) de forma inmediata.
