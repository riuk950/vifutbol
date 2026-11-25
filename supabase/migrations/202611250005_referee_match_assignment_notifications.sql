-- =============================================================================
-- HU 26.2 - Migration: Targeted Referee Match Assignment Notifications
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

-- 1. Add recipient_user_id to vifutboldev.match_live_alerts (NULL = global alert)
ALTER TABLE IF EXISTS vifutboldev.match_live_alerts
  ADD COLUMN IF NOT EXISTS recipient_user_id uuid
  REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_match_live_alerts_recipient_ts
  ON vifutboldev.match_live_alerts (recipient_user_id, alert_timestamp DESC);

-- 2. Extend alert_type check constraint to allow refereeMatchAssigned
ALTER TABLE IF EXISTS vifutboldev.match_live_alerts
  DROP CONSTRAINT IF EXISTS match_live_alerts_alert_type_check;

ALTER TABLE IF EXISTS vifutboldev.match_live_alerts
  ADD CONSTRAINT match_live_alerts_alert_type_check
  CHECK (
    alert_type IN (
      'kickoff',
      'goal',
      'fullTime',
      'rescheduling',
      'refereeMatchAssigned'
    )
  );

-- 3. Recipient-scoped RLS policies on vifutboldev.match_live_alerts
ALTER TABLE IF EXISTS vifutboldev.match_live_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS match_live_alerts_select_recipient_or_global
  ON vifutboldev.match_live_alerts;
CREATE POLICY match_live_alerts_select_recipient_or_global
  ON vifutboldev.match_live_alerts
  FOR SELECT
  TO authenticated
  USING (
    recipient_user_id IS NULL
    OR recipient_user_id IN (
      SELECT id FROM vifutboldev.user_accounts WHERE auth_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS match_live_alerts_update_recipient_or_global
  ON vifutboldev.match_live_alerts;
CREATE POLICY match_live_alerts_update_recipient_or_global
  ON vifutboldev.match_live_alerts
  FOR UPDATE
  TO authenticated
  USING (
    recipient_user_id IS NULL
    OR recipient_user_id IN (
      SELECT id FROM vifutboldev.user_accounts WHERE auth_user_id = auth.uid()
    )
  )
  WITH CHECK (
    recipient_user_id IS NULL
    OR recipient_user_id IN (
      SELECT id FROM vifutboldev.user_accounts WHERE auth_user_id = auth.uid()
    )
  );

-- 4. Idempotent trigger on vifutboldev.matches when referee_id is assigned/changed
CREATE OR REPLACE FUNCTION vifutboldev.notify_referee_match_assigned()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_recipient_user_id uuid;
  v_home_name text;
  v_away_name text;
  v_tournament_name text;
  v_schedule_text text;
  v_message text;
BEGIN
  IF NEW.referee_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.referee_id IS NOT DISTINCT FROM NEW.referee_id THEN
    RETURN NEW;
  END IF;

  SELECT user_account_id
  INTO v_recipient_user_id
  FROM vifutboldev.match_referees
  WHERE id = NEW.referee_id
  LIMIT 1;

  IF v_recipient_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT t.name INTO v_home_name
  FROM vifutboldev.tournament_teams tt
  JOIN vifutboldev.teams t ON t.id = tt.team_id
  WHERE tt.id = NEW.home_tournament_team_id
  LIMIT 1;

  SELECT t.name INTO v_away_name
  FROM vifutboldev.tournament_teams tt
  JOIN vifutboldev.teams t ON t.id = tt.team_id
  WHERE tt.id = NEW.away_tournament_team_id
  LIMIT 1;

  SELECT name INTO v_tournament_name
  FROM vifutboldev.tournaments
  WHERE id = NEW.tournament_id
  LIMIT 1;

  IF NEW.scheduled_at IS NOT NULL THEN
    v_schedule_text := to_char(
      NEW.scheduled_at AT TIME ZONE 'America/Bogota',
      'DD/MM/YYYY HH12:MI AM'
    );
  ELSE
    v_schedule_text := 'Fecha por definir';
  END IF;

  v_message :=
    COALESCE(NULLIF(trim(v_home_name), ''), 'Equipo Local')
    || ' vs '
    || COALESCE(NULLIF(trim(v_away_name), ''), 'Equipo Visitante')
    || COALESCE(' · ' || NULLIF(trim(v_tournament_name), ''), '')
    || ' · '
    || v_schedule_text
    || COALESCE(' · ' || NULLIF(trim(NEW.pitch_name), ''), '');

  INSERT INTO vifutboldev.match_live_alerts (
    id,
    match_id,
    tournament_id,
    recipient_user_id,
    alert_type,
    title,
    message,
    alert_timestamp,
    is_read,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    NEW.id,
    NEW.tournament_id,
    v_recipient_user_id,
    'refereeMatchAssigned',
    'Nuevo partido asignado',
    v_message,
    timezone('utc', now()),
    false,
    timezone('utc', now())
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_referee_match_assigned
  ON vifutboldev.matches;

CREATE TRIGGER trg_notify_referee_match_assigned
  AFTER INSERT OR UPDATE OF referee_id
  ON vifutboldev.matches
  FOR EACH ROW
  EXECUTE FUNCTION vifutboldev.notify_referee_match_assigned();

COMMIT;

NOTIFY pgrst, 'reload schema';
