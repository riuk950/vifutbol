# Interface Contracts: HU 26.1 Referee Panel & Full Match Management

**Feature**: `059-referee-panel-match-management`
**Date**: 2026-11-25

## 1. Domain Service Contract (`RefereeAssignedMatchesService`)

```dart
enum RefereeMatchFilter { all, inProgress, scheduled, completed }

class RefereeAssignedMatchesService {
  static bool isAssignedToReferee(
    ChampionshipMatch match, {
    String? userId,
    String? linkedRefereeId,
  });

  static List<ChampionshipMatch> filterAndSort(
    List<ChampionshipMatch> matches, {
    String? userId,
    String? linkedRefereeId,
    RefereeMatchFilter filter = RefereeMatchFilter.all,
  });
}
```

## 2. UI Widget Keys Contract (Testability)

### `RefereePanelContent` (`lib/presentation/panel/widgets/referee_panel_content.dart`)
- `Key('referee_panel_content')`: contenedor principal desplazable dentro de `RefreshIndicator`.
- `Key('referee_matches_filter_bar')`: barra horizontal de chips de filtro (`referee_filter_all`, `referee_filter_in_progress`, `referee_filter_scheduled`, `referee_filter_completed`).
- `Key('referee_assigned_matches_list')`: lista de tarjetas de partidos asignados.
- `Key('referee_empty_matches_state')`: estado vacío cuando no hay partidos asignados (o para el filtro seleccionado).
- `Key('referee_match_item_<matchId>')`: tarjeta de cada partido (tappable para abrir el acta).
- `Key('referee_open_match_report_<matchId>')`: botón CTA principal de la tarjeta ("Iniciar / Gestionar Acta" o "Ver Acta Finalizada").

### `DigitalMatchReportScreen` (`lib/presentation/matches/digital_match_report_screen.dart`)
- `Key('digital_match_report_unauthorized_banner')`: banner de solo lectura cuando un árbitro no asignado abre el partido.
- `Key('digital_match_report_unconfirmed_convocation_banner')`: aviso informativo no bloqueante cuando algún equipo usa la plantilla inscrita como respaldo.
- `Key('digital_match_report_observations_card')`: tarjeta de observaciones arbitrales.
- `Key('digital_match_report_observations_field')`: campo de texto de observaciones (editable mientras `!isClosed && canEdit`).
- `Key('digital_match_report_save_observations_button')`: botón para guardar observaciones arbitrales.

## 3. Localization Keys Contract (`lib/l10n/app_es.arb`)

Nuevas claves en español requeridas:
- `refereeFilterAll`: `"Todos"`
- `refereeFilterInProgress`: `"En juego"`
- `refereeFilterScheduled`: `"Programados"`
- `refereeFilterCompleted`: `"Finalizados"`
- `refereeEmptyFilterMessage`: `"No tienes partidos en esta categoría."`
- `refereeMatchStatusScheduled`: `"Programado"`
- `refereeMatchStatusInProgress`: `"En juego"`
- `refereeMatchStatusCompleted`: `"Finalizado"`
- `refereeMatchStatusPending`: `"Pendiente"`
- `refereeMatchStatusCancelled`: `"Cancelado"`
- `refereeMatchDateUnscheduled`: `"Fecha por definir"`
- `refereeMatchActionManage`: `"Gestionar Acta"`
- `refereeMatchActionViewClosed`: `"Ver Acta Finalizada"`
- `refereeMatchUnauthorizedBanner`: `"Solo el árbitro asignado a este partido o un organizador puede modificar el acta."`
- `refereeMatchUnconfirmedConvocationBanner`: `"Uno o ambos equipos no han confirmado convocatoria oficial; se cargó la plantilla inscrita como respaldo."`
- `refereeObservationsTitle`: `"Observaciones arbitrales"`
- `refereeObservationsHint`: `"Registra incidencias, estado de la cancha o notas oficiales del encuentro..."`
- `refereeObservationsSaveAction`: `"Guardar observaciones"`
- `refereeObservationsSavedMessage`: `"Observaciones guardadas en el acta"`
- `refereeObservationsEmpty`: `"Sin observaciones registradas."`
