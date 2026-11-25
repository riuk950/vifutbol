# Interface Contracts: HU 26.2 Referee Match Assignment Notification

**Feature**: `060-referee-match-assignment-notification`
**Date**: 2026-11-25

## 1. Domain Service Contract (`RefereeAssignmentNotificationService`)

```dart
class RefereeAssignmentNotificationService {
  static bool shouldNotify({
    required String? previousRefereeId,
    required String? newRefereeId,
  });

  static MatchLiveAlert? buildAssignmentAlert({
    required ChampionshipMatch match,
    required String? recipientUserId,
    required String homeTeamName,
    required String awayTeamName,
    required String tournamentName,
    DateTime? now,
  });
}
```

- `shouldNotify`: retorna `true` solo si `newRefereeId` (trim) no es vacío y es distinto de `previousRefereeId` (trim).
- `buildAssignmentAlert`: retorna `null` si `recipientUserId` es nulo/vacío; construye `MatchLiveAlert` con `type: MatchAlertType.refereeMatchAssigned`, `recipientUserId: recipientUserId`, `title: 'Nuevo partido asignado'`, y `message` con `$homeTeamName vs $awayTeamName · $tournamentName · <fecha/hora Colombia> · <cancha>`.

## 2. UI Widget Keys Contract (Testability)

### `FanAlertsBellAction` (`lib/presentation/alerts/widgets/fan_alerts_bell_action.dart`)
- `Key('fan_alerts_bell_button')`: botón de campana en el AppBar con `Badge` (`unread > 99 ? '99+' : '$unread'`) y `Semantics` en español.

### `FanAlertsTraySheet` (`lib/presentation/alerts/widgets/fan_alerts_tray_sheet.dart`)
- `Key('mark_all_alerts_read_button')`: botón "Marcar todas como leídas".
- `Key('alert_tile_<alertId>')`: tarjeta de cada alerta (incluye badge `Asignación de partido` e ícono `Icons.sports` para `MatchAlertType.refereeMatchAssigned`).

## 3. Localization Keys Contract (`lib/l10n/app_es.arb`)

Nuevas claves en español requeridas:
- `alertTypeRefereeAssigned`: `"Asignación arbitral"`
- `refereeMatchAssignedAlertTitle`: `"Nuevo partido asignado"`
