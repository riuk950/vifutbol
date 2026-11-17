-- =============================================================================
-- Migration: Team Join Requests, RPCs and RLS Policies (HU 20.1)
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

-- 1. Table: team_join_requests
CREATE TABLE IF NOT EXISTS vifutboldev.team_join_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES vifutboldev.teams(id) ON DELETE CASCADE,
  tournament_team_id uuid REFERENCES vifutboldev.tournament_teams(id) ON DELETE CASCADE,
  coach_account_id uuid NOT NULL REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  player_account_id uuid NOT NULL REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  shirt_number integer NOT NULL CHECK (shirt_number BETWEEN 1 AND 99),
  position text NOT NULL CHECK (position IN ('goalkeeper', 'defender', 'midfielder', 'forward')),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- Partial unique indexes to prevent duplicate pending invitations and shirt collisions
CREATE UNIQUE INDEX IF NOT EXISTS ux_team_join_requests_pending_player
  ON vifutboldev.team_join_requests (team_id, player_account_id)
  WHERE status = 'pending';

CREATE UNIQUE INDEX IF NOT EXISTS ux_team_join_requests_pending_shirt
  ON vifutboldev.team_join_requests (team_id, shirt_number)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_team_join_requests_player
  ON vifutboldev.team_join_requests (player_account_id, status);

CREATE INDEX IF NOT EXISTS idx_team_join_requests_team
  ON vifutboldev.team_join_requests (team_id, status);

CREATE INDEX IF NOT EXISTS idx_team_join_requests_coach
  ON vifutboldev.team_join_requests (coach_account_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trg_team_join_requests_updated_at ON vifutboldev.team_join_requests;
CREATE TRIGGER trg_team_join_requests_updated_at
  BEFORE UPDATE ON vifutboldev.team_join_requests
  FOR EACH ROW EXECUTE FUNCTION vifutboldev.set_updated_at();

-- 2. Grants & RLS
ALTER TABLE vifutboldev.team_join_requests ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE ON vifutboldev.team_join_requests TO authenticated;

-- Policies for SELECT
DROP POLICY IF EXISTS team_join_requests_select ON vifutboldev.team_join_requests;
CREATE POLICY team_join_requests_select
  ON vifutboldev.team_join_requests
  FOR SELECT
  TO authenticated
  USING (
    coach_account_id = (SELECT vifutboldev.current_user_account_id())
    OR player_account_id = (SELECT vifutboldev.current_user_account_id())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  );

-- Policies for INSERT (Only coach can invite)
DROP POLICY IF EXISTS team_join_requests_insert ON vifutboldev.team_join_requests;
CREATE POLICY team_join_requests_insert
  ON vifutboldev.team_join_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (
    coach_account_id = (SELECT vifutboldev.current_user_account_id())
    AND (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
    AND EXISTS (
      SELECT 1 FROM vifutboldev.teams t
      WHERE t.id = team_id
        AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

-- Policies for UPDATE (Coach can cancel, Player can respond or update through RPC)
DROP POLICY IF EXISTS team_join_requests_update ON vifutboldev.team_join_requests;
CREATE POLICY team_join_requests_update
  ON vifutboldev.team_join_requests
  FOR UPDATE
  TO authenticated
  USING (
    coach_account_id = (SELECT vifutboldev.current_user_account_id())
    OR player_account_id = (SELECT vifutboldev.current_user_account_id())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  )
  WITH CHECK (
    coach_account_id = (SELECT vifutboldev.current_user_account_id())
    OR player_account_id = (SELECT vifutboldev.current_user_account_id())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  );

-- 3. RPC: search_registered_players (Coach only)
CREATE OR REPLACE FUNCTION vifutboldev.search_registered_players(p_query text DEFAULT '')
RETURNS TABLE (
  user_account_id uuid,
  full_name text,
  document_id text,
  normalized_document_id text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_norm_query text;
BEGIN
  IF NOT (SELECT vifutboldev.current_user_has_role(ARRAY['coach', 'organizer'])) THEN
    RAISE EXCEPTION 'UNAUTHORIZED' USING ERRCODE = '42501';
  END IF;

  v_norm_query := trim(lower(COALESCE(p_query, '')));

  RETURN QUERY
  SELECT
    ua.id AS user_account_id,
    ua.full_name,
    COALESCE(ua.document_id, '') AS document_id,
    COALESCE(ua.normalized_document_id, '') AS normalized_document_id
  FROM vifutboldev.user_accounts ua
  WHERE ('player' = ANY(ua.authorized_roles) OR ua.active_role = 'player')
    AND (
      v_norm_query = ''
      OR lower(ua.full_name) LIKE '%' || v_norm_query || '%'
      OR lower(COALESCE(ua.document_id, '')) LIKE '%' || v_norm_query || '%'
      OR lower(COALESCE(ua.normalized_document_id, '')) LIKE '%' || v_norm_query || '%'
    )
  ORDER BY ua.full_name ASC
  LIMIT 50;
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.search_registered_players(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION vifutboldev.search_registered_players(text) TO authenticated, service_role;

-- 4. RPC: respond_team_join_request (Player only)
CREATE OR REPLACE FUNCTION vifutboldev.respond_team_join_request(
  p_request_id uuid,
  p_accept boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_req vifutboldev.team_join_requests%ROWTYPE;
  v_player_account vifutboldev.user_accounts%ROWTYPE;
  v_player_id uuid;
  v_clean_doc text;
  v_norm_doc text;
BEGIN
  SELECT * INTO v_req
  FROM vifutboldev.team_join_requests
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'REQUEST_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  IF v_req.player_account_id <> (SELECT vifutboldev.current_user_account_id()) THEN
    RAISE EXCEPTION 'UNAUTHORIZED' USING ERRCODE = '42501';
  END IF;

  IF v_req.status <> 'pending' THEN
    RAISE EXCEPTION 'REQUEST_NOT_PENDING' USING ERRCODE = 'P0003';
  END IF;

  IF NOT p_accept THEN
    UPDATE vifutboldev.team_join_requests
    SET status = 'rejected', updated_at = timezone('utc', now())
    WHERE id = p_request_id;

    RETURN jsonb_build_object(
      'id', p_request_id,
      'status', 'rejected'
    );
  END IF;

  -- Player accepted
  SELECT * INTO v_player_account
  FROM vifutboldev.user_accounts
  WHERE id = v_req.player_account_id;

  v_clean_doc := COALESCE(NULLIF(trim(v_player_account.document_id), ''), 'DOC-' || substring(v_player_account.id::text from 1 for 8));
  v_norm_doc := COALESCE(NULLIF(trim(v_player_account.normalized_document_id), ''), regexp_replace(upper(v_clean_doc), '[^A-Z0-9]', '', 'g'));

  -- Check if shirt_number is already taken in the target team
  IF v_req.tournament_team_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM vifutboldev.players
      WHERE tournament_team_id = v_req.tournament_team_id
        AND shirt_number = v_req.shirt_number
    ) THEN
      RAISE EXCEPTION 'SHIRT_NUMBER_ALREADY_TAKEN' USING ERRCODE = 'P0004';
    END IF;
  END IF;

  -- Upsert player into vifutboldev.players
  INSERT INTO vifutboldev.players (
    tournament_team_id,
    tournament_id,
    user_account_id,
    full_name,
    document_id,
    normalized_document_id,
    shirt_number,
    position,
    phone,
    is_eligible
  ) VALUES (
    v_req.tournament_team_id,
    (SELECT tournament_id FROM vifutboldev.tournament_teams WHERE id = v_req.tournament_team_id),
    v_req.player_account_id,
    v_player_account.full_name,
    v_clean_doc,
    v_norm_doc,
    v_req.shirt_number,
    v_req.position,
    v_player_account.phone,
    true
  )
  RETURNING id INTO v_player_id;

  UPDATE vifutboldev.team_join_requests
  SET status = 'accepted', updated_at = timezone('utc', now())
  WHERE id = p_request_id;

  RETURN jsonb_build_object(
    'id', p_request_id,
    'status', 'accepted',
    'player_id', v_player_id
  );
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.respond_team_join_request(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION vifutboldev.respond_team_join_request(uuid, boolean) TO authenticated, service_role;
