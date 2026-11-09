# Phase 0 Research: Programación Integral de Partido al Seleccionarlo en la Jornada (HU 15.3)

**Feature**: `026-matchday-integrated-scheduling`  
**Date**: 2026-11-09

---

## Decision 1: Interacción por Rol al Tocar un Partido en `CompetitionFixtureTabView`

- **Decision**: En `CompetitionFixtureTabView` (`lib/presentation/tournaments/widgets/competition_fixture_tab_view.dart`), evaluar el rol activo (`activeUserRoleProvider`), el estado del torneo (`tournamentsControllerProvider`) y el estado del partido (`match.status`). Cuando el usuario tiene capacidad `RoleCapability.manageTournaments` (`UserRole.organizer`), el torneo es editable (`openRegistration` o `inProgress`) y el partido está en estado `MatchStatus.pendingSchedule` o `MatchStatus.scheduled`, tocar la tarjeta abre directamente `ScheduleMatchDialog.show(context: context, match: match, tournament: tournament)`. En cualquier otro caso (otros roles, torneo finalizado o partido en `inProgress`/`completed`/`cancelled`), se abre la hoja modal de resumen de solo lectura (`_openMatchDetailModal`).
- **Rationale**: Satisface de manera directa (1 toque) el escenario Gherkin Fase 1 de la HU 15.3 y la clarificación `Q1: A`, preservando a la vez la consulta informativa para aficionados, jugadores, entrenadores, árbitros y partidos ya disputados.
- **Alternatives Considered**:
  - *Abrir siempre el modal informativo con un botón secundario de edición*: Rechazado en `Q1: A` porque introduce un paso adicional innecesario para el organizador al programar jornadas completas.

---

## Decision 2: Visualización del Pie de Metadatos Logísticos en la Tarjeta de Jornada

- **Decision**: Incorporar un contenedor/fila de metadatos logísticos (`Key('fixture_match_logistics_${match.id}')`) debajo o integrado en el ítem de cada partido dentro de `CompetitionFixtureTabView`:
  - Cuando el partido tiene programación asignada (`match.scheduledStartTime != null` o `match.status == MatchStatus.scheduled`): mostrar en una fila adaptable (`Wrap`) la **Fecha y Hora** (`dd/MM/yyyy HH:mm`), **Sede y Cancha** (`match.pitchName`) y **Árbitro** (`match.refereeName`), utilizando un texto resumido formateado para no colisionar con selectores exactos de pruebas existentes en el modal de detalle.
  - Cuando el partido está en `MatchStatus.pendingSchedule`: mostrar el indicador localizado *"Por programar"* (`l10n.matchPendingScheduleBadge` / `l10n.fixtureMatchPendingLogistics`).
- **Rationale**: Cumple con `FR-008` y el escenario Gherkin Fase 2 (*"Y en la jornada se visualiza la fecha, hora, sede, cancha y árbitro asignados"*), asegurando cero desbordamientos (`Wrap`) en pantallas de $320 \times 640\text{ px}$ al $130\%$ de escala de texto.
- **Alternatives Considered**:
  - *Modificar directamente el bloque central de 94px de `MatchCenterCard`*: Rechazado porque `MatchCenterCard` se comparte en múltiples vistas compactas y un bloque de 94px no puede alojar sede, cancha y árbitro sin truncamiento severo.

---

## Decision 3: Validación Global de Colisiones entre Competiciones y Preservación del Catálogo en Memoria

- **Decision**:
  1. Exponer `Future<List<ChampionshipMatch>> loadAllMatches()` en `TournamentMatchesRepository` y su implementación `LocalTournamentMatchesRepository` (que ya cuenta internamente con `_loadAllMatches()`).
  2. En `FixtureSchedulingUseCase.scheduleMatch`, cargar todos los partidos del catálogo (`loadAllMatches()`) para evaluar `detectCollisions`, garantizando que ningún otro partido programado (del mismo o de otro torneo activo) ocupe la misma cancha (`pitchId`) o el mismo árbitro (`refereeId`) en un intervalo superpuesto (`[startTime, endTime]`), excluyendo el propio `matchId`.
  3. Al guardar en `FixtureSchedulingUseCase.scheduleMatch`, formatear `pitchName` como `'${venue.name} - ${pitch.name}'` (si `pitch.name` no incluye ya el nombre de la sede) para que tanto la sede como la cancha queden persistidas y visibles en las tarjetas.
  4. En `MatchesCatalogController.scheduleMatch`, fusionar los partidos actualizados del torneo con los partidos de otros torneos en memoria (`[...otherTournamentMatches, ...updatedMatches]`) e invocar `dailyMatchesFeedControllerProvider.notifier.refresh()` tras programar exitosamente desde la jornada.
- **Rationale**: Resuelve la clarificación de sesión (`FR-005`) evitando dobles reservas físicas entre torneos simultáneos y mantiene la integridad del feed diario (`DailyMatchesFeedController`).
- **Alternatives Considered**:
  - *Validar colisiones solo dentro del mismo `tournament.id`*: Rechazado en la sesión de clarificación porque permitiría asignar la misma cancha y árbitro a la misma hora en dos competiciones distintas.

---

## Decision 4: Acotación Segura del `DatePicker` al Rango del Campeonato

- **Decision**: En `ScheduleMatchDialog`:
  - Inicializar `_selectedDate` tomando `widget.match.scheduledStartTime` si existe; si es `null` (`pendingSchedule`), usar la fecha actual (`DateTime.now().add(const Duration(days: 1))`) ajustada (*clamped*) dentro del intervalo `[widget.tournament.startDate, widget.tournament.endDate]`.
  - En `_pickDate()`, definir `firstDate` como el menor entre `widget.tournament.startDate` y `_selectedDate`, y `lastDate` como el mayor entre `widget.tournament.endDate` y `_selectedDate`.
- **Rationale**: Cumple con la regla de negocio (*"dentro del rango válido del campeonato"*) y la clarificación `FR-003`/`FR-004`, previniendo cualquier excepción de aserción de Flutter (`!initialDate.isBefore(firstDate) && !initialDate.isAfter(lastDate)`) cuando los tests o el usuario operan con fechas fuera del calendario nominal del torneo.
- **Alternatives Considered**:
  - *Usar `tournament.startDate` y `tournament.endDate` sin margen seguro*: Provocaría un crash de Flutter si un partido tiene una fecha previa o si `DateTime.now()` en un test unitario/widget cae fuera de las fechas estáticas del torneo de prueba.
