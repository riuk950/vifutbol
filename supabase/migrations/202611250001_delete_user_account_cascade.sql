-- =============================================================================
-- HU 24.3 - Migration: Cascade Account Deletion RPC (Cloud + Storage + Auth)
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

CREATE OR REPLACE FUNCTION vifutboldev.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = vifutboldev, public, auth, storage
AS $$
DECLARE
  v_auth_uid uuid := auth.uid();
  v_account_id uuid;
BEGIN
  IF v_auth_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING ERRCODE = '42501';
  END IF;

  SELECT id
  INTO v_account_id
  FROM vifutboldev.user_accounts
  WHERE auth_user_id = v_auth_uid
  LIMIT 1;

  IF v_account_id IS NOT NULL THEN
    -- 1. Preserve shared tournament history while stripping personal data/links
    UPDATE vifutboldev.players
    SET
      user_account_id = NULL,
      phone = NULL,
      photo_url = NULL,
      document_front_url = NULL,
      document_back_url = NULL
    WHERE user_account_id = v_account_id
      AND tournament_id IS NOT NULL;

    -- 2. Delete free-agent player profiles with no tournament participation
    DELETE FROM vifutboldev.players
    WHERE user_account_id = v_account_id
      AND tournament_id IS NULL;

    -- 3. Unlink referee records while preserving historical match reports
    UPDATE vifutboldev.match_referees
    SET
      user_account_id = NULL,
      phone = NULL
    WHERE user_account_id = v_account_id;

    -- 4. Delete user_accounts (cascades coach/organizer/fan profiles,
    --    fan_favorite_teams, team_join_requests; sets NULL on tournaments,
    --    teams, sports_venues, tournament_news, and digital_match_reports)
    DELETE FROM vifutboldev.user_accounts
    WHERE id = v_account_id;
  END IF;

  -- 5. Delete personal media objects from Supabase Storage buckets
  DELETE FROM storage.objects
  WHERE bucket_id IN ('player-avatars', 'player-documents')
    AND (
      owner = v_auth_uid
      OR name LIKE v_auth_uid::text || '/%'
    );

  -- 6. Delete authentication identity from auth.users
  DELETE FROM auth.users
  WHERE id = v_auth_uid;
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.delete_my_account()
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION vifutboldev.delete_my_account()
TO authenticated, service_role;
