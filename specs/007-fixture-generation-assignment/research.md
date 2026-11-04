# Research & Technical Decisions: Generación de Calendario (Fixture), Asignación de Canchas y Designación de Árbitros (HU 6.1)

**Feature**: `007-fixture-generation-assignment`  
**Date**: 2026-11-04

## 1. Algoritmo de Generación de Fixture (`FR-001`)

- **Decision**: Implementar dos generadores deterministas en la capa de dominio:
  1. **Algoritmo Round-Robin (Liga)**:
     - Si el número de equipos $N$ es impar, se añade un equipo ficticio (*"Fecha Libre"* / *Bye*), convirtiendo el total a $N + 1$.
     - Se fijan las posiciones rotando $N - 1$ elementos cíclicamente alrededor del primer elemento para generar $N - 1$ jornadas de ida.
     - En cada jornada, cada equipo juega exactamente un partido, o descansa si su rival es el elemento *bye*.
     - Para torneos con `leagueRounds > 1` (p. ej. ida y vuelta), se invierten las localías en las rondas pares.
  2. **Árbol de Llaves (Copa Eliminatoria)**:
     - A partir de la ronda inicial configurada (`KnockoutRound.quarterFinals`, `semiFinals`, etc.) y los equipos clasificados/habilitados, se generan los emparejamientos deterministas de la primera fase.
- **Rationale**: Garantiza que el 100% de los enfrentamientos se creen sin repeticiones de equipos en la misma jornada y sin duplicar cruces de forma desbalanceada.
- **Alternatives considered**:
  - Generación aleatoria pura con reintentos: descartada por riesgo de bloqueos infinitos, falta de determinismo en pruebas automatizadas y distribución desigual de localías.

## 2. Detección y Prevención Determinista de Colisiones Logísticas (`FR-003`, `FR-004`)

- **Decision**: Modelar cada partido con un intervalo cerrado de tiempo $[T_{start}, T_{end}]$ donde:
  $$T_{end} = T_{start} + (2 \times \text{halfDurationMinutes} + 15 \text{ min descanso})$$
  Se define que dos partidos $A$ y $B$ colisionan si:
  $$\max(A.start, B.start) < \min(A.end, B.end)$$
  Al programar o reprogramar un partido, el caso de uso verifica tres tipos de colisión:
  1. **Colisión de Cancha**: Mismo `pitchId` en el mismo intervalo.
  2. **Colisión de Árbitro**: Mismo `refereeId` en el mismo intervalo.
  3. **Colisión de Equipos**: Mismo `homeTeamId` o `awayTeamId` disputando otro partido en el mismo intervalo.
  Si se detecta cualquier colisión, se lanza `ScheduleCollisionFailure` con código semántico y mensaje explícito en español.
- **Rationale**: Resuelve fielmente el escenario Gherkin de Fase 2 (*"Bloqueo por cruce de horario en la misma cancha o para el mismo árbitro"*).

## 3. Catálogo de Árbitros Oficiales y Sedes (`FR-002`)

- **Decision**: Crear un catálogo de árbitros con rol `UserRole.referee`:
  - En entorno `dev`, precargar al menos 3 árbitros oficiales semilla (`'ref-seed-1'` `"Nicolás Gallo"`, `'ref-seed-2'` `"Wilmar Roldán"`, `'ref-seed-3'` `"Andrés Rojas"`).
  - Reutilizar el catálogo existente de sedes y canchas de `LocalVenuesRepository` (`SportsVenue` y `VenuePitch`).
- **Rationale**: Ofrece una experiencia deportiva realista en campo y mantiene integridad referencial con el sistema de permisos RBAC.

## 4. Integración en la Pestaña de Jornada (`MatchdayTabView`) (`FR-005`)

- **Decision**: Evolucionar `MatchdayTabView` (primera pestaña del `AppShellScreen`) reemplazando el selector de estados de demostración por la experiencia deportiva real:
  - Selector horizontal de jornadas con chips (`Jornada 1`, `Jornada 2`...).
  - Filtros rápidos por estado de partido (`Todos`, `Pendiente`, `Programado`, `Finalizado`).
  - Tarjetas de partido con diseño `16px` mostrando los escudos vectoriales de ambos equipos, fecha, hora, cancha y árbitro designado.
  - Para el `Organizador` (`RoleCapability.manageTournaments`): Botón `"Generar Fixture"` (cuando no hay partidos creados) y acción de `"Programar"` en cada tarjeta de partido pendiente.
- **Rationale**: Cumple el lineamiento de `DESIGN.md` y centraliza la experiencia deportiva de partidos en la pestaña natural de `Jornada`.
