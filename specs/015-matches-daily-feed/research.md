# Research: Rediseño de Vista Partidos (Match Center Stitch, Selector de Fecha por Calendario y Pestañas Ayer/Hoy/Mañana)

**Feature**: `015-matches-daily-feed`  
**Date**: 2026-11-06  
**Status**: Completed

## 1. Context & Technical Drivers

La feature persigue transformar la actual pestaña de Partidos (`MatchdayTabView`), la cual estaba centrada en la selección de un único torneo y contenía sub-segmentos (Partidos / Noticias), en un **Feed Diario Global de Partidos** multi-competición inspirado en la pantalla `vifutbol - Partidos` de Stitch (`projects/9950187698528265378/screens/14e6a9cb434b4b92a9c891f53f03f14a`).

### Requerimientos clave analizados:
1. **Pestañas Ayer / Hoy / Mañana**: Barra horizontal segmentada fija justo debajo del `AppBar`. La pestaña activa por defecto en cada inicio de la app DEBE ser "Hoy".
2. **Icono de Calendario en AppBar**: Acción junto a `FanAlertsBellAction` para abrir un DatePicker y seleccionar cualquier fecha (pasada o futura).
3. **Agrupación por Competición Activa**: Mostrar los partidos del día agrupados en tarjetas/bloques por competición activa (`openRegistration` o `inProgress`). Las competiciones en borrador, finalizadas o archivadas se omiten.
4. **Tarjetas de Partido Simétricas Match Center**:
   - Izquierda: Nombre y escudo de Equipo Local (`KickPulseTeamCrest`).
   - Centro: Hora programada (ej. `18:30`) o Marcador tabular (ej. `2 - 1`) + chip semántico de estado (`EN VIVO` pulsante, `Final` FT, o `Cancelado`).
   - Derecha: Nombre y escudo de Equipo Visitante (`KickPulseTeamCrest`).
5. **Gestión para Organizador**: Banner/tarjeta superior en el feed diario cuando hay partidos pendientes de programar (`MatchStatus.pendingSchedule`) o torneos sin fixture, con acción para programar o generar fixture. Oculto para roles no autorizados y cuando no hay pendientes.
6. **Favoritos**: Excluido de esta fase (según clarificación).

---

## 2. Technical Decisions & Tradeoffs

### Decisión 1: Modelado de Estado de Navegación Temporal (Date & Feed Controller)
- **Decisión**: Crear un `dailyMatchesDateProvider` (`StateNotifierProvider` o `NotifierProvider` de Riverpod) y un `dailyMatchesFeedProvider`.
- **Estructura**:
  - `selectedDate`: Representa la fecha activa (normalizada a medianoche `DateTime(year, month, day)`).
  - `activeQuickTab`: Enum con valores `yesterday`, `today`, `tomorrow`, `customDate`.
  - Método `selectQuickTab(MatchesDailyTab tab)`: Calcula la fecha exacta relativa a `DateTime.now()`.
  - Método `selectCustomDate(DateTime date)`: Actualiza la fecha. Si coincide con ayer, hoy o mañana, marca el tab correspondiente; si es otra fecha, activa `customDate`.
- **Alternativas consideradas**:
  - *Usar solo `TabController` nativo de Flutter*: Insuficiente porque cuando el usuario elige una fecha arbitraria en el calendario (ej. dentro de 2 semanas), no existe un índice directo en un `TabController` de 3 posiciones sin romper la correspondencia visual.
- **Razón**: Permite sincronizar reactivamente el `AppBar` (icono calendario), el selector de 3 pestañas y el listado de partidos.

### Decisión 2: Agrupación y Filtrado de Partidos por Torneo Activo
- **Decisión**: Crear una función pura en la capa de aplicación/dominio `groupMatchesByActiveTournaments({required List<ChampionshipMatch> matches, required List<ChampionshipTournament> tournaments, required DateTime targetDate})`.
- **Comportamiento**:
  1. Filtra torneos por estado activo: `tournament.status == TournamentStatus.openRegistration || tournament.status == TournamentStatus.inProgress`.
  2. Filtra partidos cuya fecha programada (`match.scheduledStartTime`) coincida en año, mes y día con `targetDate`.
  3. Agrupa por `tournamentId`. Solo genera grupos para torneos que tengan al menos 1 partido en esa fecha.
  4. Ordena los grupos: Primero torneos con partidos `inProgress`, luego alfabético por nombre de torneo.
  5. Ordena partidos dentro del torneo: `inProgress` primero, luego por `scheduledStartTime` ascendente, luego `completed`, luego `cancelled`.
- **Alternativas consideradas**:
  - *Hacer múltiples consultas a Hive/repositorio por cada torneo*: Ineficiente.
- **Razón**: El catálogo de partidos y torneos ya se encuentra en memoria o repositorio local; procesar el agrupamiento en memoria tarda < 5ms para volúmenes estándar de ligas y copas urbanas.

### Decisión 3: Integración del Selector de Calendario en `AppShellScreen`
- **Decisión**: El botón de acción con icono de calendario (`Icons.calendar_month_outlined`) se integra en el `AppBar` de `AppShellScreen` de forma condicional o contextual cuando la sección activa es `AppShellSection.matchday`.
- **Flujo**:
  - Al pulsar el icono, invoca `showDatePicker` con tema adaptado a `KickPulseTheme` (superficie oscura `#10131A`, texto `#F8FAFC`, selección verde `#10B981`).
  - Al seleccionar fecha, despacha `dailyMatchesDateController.selectCustomDate(picked)`.
- **Alternativas consideradas**:
  - *Colocar el botón dentro del cuerpo del TabView*: Rompe la ergonomía y se aleja del diseño acordado donde la acción de calendario acompaña las notificaciones en el AppBar.

### Decisión 4: Diseño de Tarjetas Simétricas `MatchCenterRow` vs `MatchCard`
- **Decisión**: Crear un widget especializado `MatchCenterCard` (o evolucionar `MatchCard`) adaptado al patrón visual de Stitch:
  - Fila horizontal con 3 columnas simétricas: `[Local (Flex)] - [Centro Fijo (80dp)] - [Visitante (Flex)]`.
  - Micro-animación para el punto en vivo (`accentLive` `#EF4444`).
  - Fuente tabular para marcadores y horas (`fontFeatures: [FontFeature.tabularFigures()]`).
- **Razón**: Cumple estrictamente con el mockup `vifutbol - Partidos` y las directrices de `DESIGN.md`.

---

## 3. Architecture & Impact Analysis

- **Capa Dominio**:
  - No requiere alterar la entidad central `ChampionshipMatch` ni `ChampionshipTournament` (ya cuentan con los atributos necesarios: `scheduledStartTime`, `status`, `tournamentId`, etc.).
  - Se define un Value Object / View State `DailyMatchesGroup`:
    ```dart
    class TournamentMatchesGroup {
      final ChampionshipTournament tournament;
      final List<ChampionshipMatch> matches;
    }
    ```
- **Capa Aplicación**:
  - Nuevo State/Notifier: `daily_matches_feed_controller.dart`.
  - Proveedores: `dailyMatchesFeedProvider`, `dailyMatchesDateProvider`.
- **Capa Presentación**:
  - `AppShellScreen`: Exposición del icono de calendario en el `AppBar` cuando `activeSection == AppShellSection.matchday`.
  - `MatchdayTabView`: Rediseño completo para incorporar el ribbon de pestañas "Ayer / Hoy / Mañana", banner de partidos pendientes para Organizador, y lista sliver/scrollable con los bloques de torneos y partidos.
  - Nuevo componente `DailyMatchesTabBar`: Barra segmentada para Ayer/Hoy/Mañana + indicador de fecha personalizada.
  - Nuevo componente `TournamentMatchesGroupCard`: Contenedor de torneo con encabezado estilizado y filas de partidos.
  - `OrganizerPendingMatchesBanner`: Banner superior exclusivo para organizadores.

## 4. Verification & Testing Strategy
- Pruebas unitarias para `groupMatchesByActiveTournaments`:
  - Partidos de torneos cerrados/borrador deben ser excluidos.
  - Partidos sin `scheduledStartTime` deben ser excluidos del feed diario.
  - Partidos de fechas distintas deben ser excluidos.
  - Ordenamiento correcto (en vivo primero).
- Pruebas de widgets:
  - Verificar que al iniciar, la pestaña "Hoy" esté seleccionada y se muestren los partidos de hoy.
  - Verificar que tocar "Ayer" o "Mañana" actualice la fecha y los partidos mostrados.
  - Verificar que el selector de calendario actualice la lista y active el tab correspondiente si es ayer/hoy/mañana.
  - Verificar que el banner de organizador solo sea visible para rol `organizer`.
