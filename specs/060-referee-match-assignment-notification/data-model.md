# Data Model: Notificación en el AppBar al Árbitro al Asignarle un Partido

**Feature**: `060-referee-match-assignment-notification` (HU 26.2)
**Date**: 2026-11-25

## 1. Relational Schema Changes (`vifutboldev`)

### Table: `vifutboldev.match_live_alerts`

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `recipient_user_id` *(new)* | `uuid` (FK `vifutboldev.user_accounts(id) ON DELETE CASCADE`) | YES | `NULL` | Identificador de la cuenta destinataria. `NULL` para alertas globales de partidos/torneos; poblado para notificaciones privadas dirigidas a un usuario específico (e.g. árbitro asignado). |

- **Constraint `alert_type`**: se actualiza de forma idempotente para incluir `'refereeMatchAssigned'` además de los valores existentes (`'kickoff'`, `'goal'`, `'fullTime'`, `'rescheduling'`).
- **Index**: `CREATE INDEX IF NOT EXISTS idx_match_live_alerts_recipient_ts ON vifutboldev.match_live_alerts (recipient_user_id, alert_timestamp DESC);`.
- **RLS Policies (`vifutboldev.match_live_alerts`)**:
  - `SELECT`: permitido si `recipient_user_id IS NULL` O `recipient_user_id = (SELECT id FROM vifutboldev.user_accounts WHERE auth_user_id = auth.uid() LIMIT 1)`.
  - `UPDATE`: permitido sobre alertas globales o cuando `recipient_user_id` coincide con el `user_accounts.id` del usuario autenticado.
- **Trigger `trg_notify_referee_match_assigned` (`AFTER INSERT OR UPDATE OF referee_id ON vifutboldev.matches`)**:
  - Condición de disparo: `NEW.referee_id IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.referee_id IS DISTINCT FROM NEW.referee_id)`.
  - Busca `user_account_id` en `vifutboldev.match_referees WHERE id = NEW.referee_id`. Si es `NULL`, termina sin error.
  - Resuelve `home_team.name`, `away_team.name`, `tournaments.name`, fecha/hora Colombia (`NEW.scheduled_at AT TIME ZONE 'America/Bogota'`) y `NEW.pitch_name`.
  - Inserta en `vifutboldev.match_live_alerts` (`alert_type = 'refereeMatchAssigned'`, `recipient_user_id = v_user_account_id`, `title = 'Nuevo partido asignado'`, `message = ...`, `is_read = false`).

## 2. Domain Entities Updates

### `MatchAlertType` (`lib/domain/entities/match_alert_type.dart`)
- Nuevo valor: `refereeMatchAssigned`.

### `MatchLiveAlert` (`lib/domain/entities/match_live_alert.dart`)
- Nuevo campo opcional: `final String? recipientUserId;`
- Incluido en constructor (`this.recipientUserId`), `copyWith`, `toJson()` (`'recipientUserId': recipientUserId`) y `fromJson(Map<String, dynamic>)` (`(json['recipientUserId'] ?? json['recipient_user_id']) as String?`).

### `MatchReferee` (`lib/domain/entities/match_referee.dart`)
- Nuevo campo opcional: `final String? userAccountId;`
- Hidratado desde `match_referees.user_account_id` en `PostgrestTournamentMatchesRemoteDataSource.fetchOfficialReferees()`.

## 3. Local Isolation & Sync Rules

1. **Aislamiento local (`LocalMatchAlertsRepository`)**:
   - `loadAlerts(userId, tournamentId: ...)` y `watchAlerts(userId, tournamentId: ...)`: incluyen una alerta solo si `a.recipientUserId == null || a.recipientUserId == userId`.
   - `markAllAsRead(userId, tournamentId: ...)`: marca como leídas solo las alertas visibles para `userId` (`a.recipientUserId == null || a.recipientUserId == userId`).
2. **Mapeo remoto (`PostgrestMatchAlertsRemoteDataSource`)**:
   - `_toDbAlertType(MatchAlertType.refereeMatchAssigned) => 'refereeMatchAssigned'`
   - `_fromDbAlertType('refereeMatchAssigned') => MatchAlertType.refereeMatchAssigned`
   - `_fromRow` lee `recipient_user_id` y `upsertAlert` envía `recipient_user_id`.
3. **Offline-first**:
   - `markAsRead` y `markAllAsRead` escriben inmediatamente en `LocalMatchAlertsRepository` y encolan sincronización en `SyncOutbox` vía `HybridMatchAlertsRepository`.
