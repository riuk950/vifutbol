# UI & Localization Contracts: Pestaña de Calendario de Partidos del Equipo (HU 14.2)

**Feature**: `022-team-matches-schedule`  
**Date**: 2026-11-09

---

## 1. Widget Key Contracts (`Key`)

Para garantizar trazabilidad y pruebas deterministas de widgets, los componentes de la pestaña **"Partidos"** (`TeamMatchesTabView`) DEBEN exponer las siguientes claves (`Key`):

| Componente / Elemento | Key | Descripción |
|-----------------------|-----|-------------|
| Vista de Pestaña "Partidos" | `PageStorageKey('team_matches_tab_view')` | Raíz con preservación de scroll dentro del `TabBarView` de `TeamDetailScreen`. |
| Estado Vacío Global de Partidos | `Key('team_matches_empty_state')` | `KickPulseStateView` cuando el equipo no tiene ni próximos partidos ni resultados anteriores. |
| Encabezado "Próximos Partidos" | `Key('team_upcoming_matches_header')` | Encabezado de la sección de partidos futuros. |
| Estado Vacío de Próximos Partidos | `Key('team_upcoming_matches_empty_state')` | Mensaje contextual cuando el equipo tiene resultados previos pero no tiene próximos partidos. |
| Contenedor de Partido Próximo | `Key('team_upcoming_match_item_${match.id}')` | Contenedor del partido futuro (franja de metadatos + badge Local/Visitante + `MatchCenterCard`). |
| Encabezado "Resultados Anteriores" | `Key('team_completed_matches_header')` | Encabezado de la sección de historial de partidos disputados. |
| Estado Vacío de Resultados Anteriores | `Key('team_completed_matches_empty_state')` | Mensaje contextual cuando el equipo tiene próximos partidos pero aún no ha disputado ninguno. |
| Contenedor de Partido Finalizado | `Key('team_completed_match_item_${match.id}')` | Contenedor del partido finalizado (franja de metadatos + badge semántico V/E/D + `MatchCenterCard`). |
| Badge de Resultado Semántico | `Key('team_match_outcome_badge_${match.id}')` | `KickPulseBadge` que muestra "Victoria" (`success`), "Empate" (`warning`) o "Derrota" (`live`). |
| Modal de Detalle del Partido | `Key('team_match_detail_modal')` | Hoja modal informativa (`ModalBottomSheet`) abierta al tocar un partido de la lista. |

---

## 2. Contratos de Localización (`lib/l10n/app_es.arb`)

Todas las etiquetas visibles nuevas para la pestaña **"Partidos"** DEBEN declararse en `lib/l10n/app_es.arb`:

| Clave `l10n` | Valor en Español (`app_es.arb`) | Uso |
|--------------|---------------------------------|-----|
| `teamMatchesUpcomingSectionTitle` | `"Próximos Partidos"` | Título de la sección de próximos encuentros |
| `teamMatchesCompletedSectionTitle` | `"Resultados Anteriores"` | Título de la sección de historial de partidos finalizados |
| `teamMatchesEmptyGlobalTitle` | `"Sin partidos en el calendario"` | Título del estado vacío global cuando no hay partidos próximos ni finalizados |
| `teamMatchesEmptyGlobalMessage` | `"Este equipo aún no tiene encuentros programados ni resultados registrados en la competición."` | Descripción del estado vacío global |
| `teamMatchesUpcomingEmpty` | `"Sin próximos partidos agendados"` | Mensaje contextual cuando la sección de próximos partidos está vacía |
| `teamMatchesCompletedEmpty` | `"Sin partidos finalizados registrados"` | Mensaje contextual cuando la sección de resultados anteriores está vacía |
| `teamMatchOutcomeWin` | `"Victoria"` | Etiqueta del badge semántico para partido ganado (`KickPulseBadgeVariant.success`) |
| `teamMatchOutcomeDraw` | `"Empate"` | Etiqueta del badge semántico para partido empatado (`KickPulseBadgeVariant.warning`) |
| `teamMatchOutcomeLoss` | `"Derrota"` | Etiqueta del badge semántico para partido perdido (`KickPulseBadgeVariant.live`) |
| `teamMatchDetailModalRefereeLabel` | `"Árbitro designado"` | Etiqueta informativa en el modal de detalle del partido |
| `teamMatchDetailModalUnassignedReferee` | `"Árbitro sin asignar"` | Fallback cuando `match.refereeName` es nulo |
| `teamMatchDetailModalUnassignedVenue` | `"Cancha por asignar"` | Fallback cuando `match.pitchName` es nulo o vacío |
| `teamMatchDetailModalPendingSchedule` | `"Horario pendiente"` | Fallback cuando `match.scheduledStartTime` es nulo |

---

## 3. Contrato de Interacción y Navegación

1. **Toque sobre Partido (`MatchCenterCard.onTap`)**:
   - Invoca la apertura del `ModalBottomSheet` (`Key('team_match_detail_modal')`) exhibiendo:
     - Nombre de la jornada (`match.roundName`).
     - Enfrentamiento (`Local vs Visitante`) y marcador final (si está completado o en curso).
     - Badge semántico de resultado (**Victoria**, **Empate**, **Derrota**) si el partido está completado, o estado actual si está próximo/en juego.
     - Fecha y hora programada (o *"Horario pendiente"*).
     - Cancha/sede (`match.pitchName` o *"Cancha por asignar"*).
     - Árbitro (`match.refereeName` o *"Árbitro sin asignar"*).
2. **Toque sobre Escudo o Nombre de Equipo Rival (`MatchCenterCard` zonas laterales)**:
   - Navega hacia `/teams/:rivalId` (`TeamDetailScreen(teamId: rivalId)`).
   - Si el usuario toca el bloque del mismo equipo cuyo detalle ya está abierto (`/teams/$teamId`), la navegación se ignora para evitar duplicar la ruta en la pila.
