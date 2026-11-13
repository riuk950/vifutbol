-- =============================================================================
-- HU 19.4 - Migration: Role Persistence, Extensible Profile Tables, and
-- Player/Referee Non-Duplicating Document Linking
-- Target schema: vifutboldev (requires HU 17.2/17.3 migrations 0001-0005)
-- Idempotent: safe to run repeatedly
-- =============================================================================

-- 1. Extend vifutboldev.user_accounts with personal contact/document attributes
ALTER TABLE vifutboldev.user_accounts
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS document_id text,
  ADD COLUMN IF NOT EXISTS normalized_document_id text;

CREATE INDEX IF NOT EXISTS idx_user_accounts_normalized_doc
  ON vifutboldev.user_accounts (normalized_document_id)
  WHERE normalized_document_id IS NOT NULL;

-- 2. Extend vifutboldev.players (single source of truth for athletes)
-- Allow free-agent players (tournament_team_id / tournament_id / shirt_number / position nullable)
ALTER TABLE vifutboldev.players
  ALTER COLUMN tournament_team_id DROP NOT NULL,
  ALTER COLUMN tournament_id DROP NOT NULL,
  ALTER COLUMN shirt_number DROP NOT NULL,
  ALTER COLUMN position DROP NOT NULL;

ALTER TABLE vifutboldev.players
  ADD COLUMN IF NOT EXISTS phone text;

CREATE UNIQUE INDEX IF NOT EXISTS ux_players_user_account_id
  ON vifutboldev.players (user_account_id)
  WHERE user_account_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_players_free_agent_doc
  ON vifutboldev.players (normalized_document_id)
  WHERE tournament_id IS NULL;

-- 3. Extend vifutboldev.match_referees (single source of truth for referees)
ALTER TABLE vifutboldev.match_referees
  ADD COLUMN IF NOT EXISTS document_id text,
  ADD COLUMN IF NOT EXISTS normalized_document_id text,
  ADD COLUMN IF NOT EXISTS phone text;

CREATE UNIQUE INDEX IF NOT EXISTS ux_match_referees_user_account_id
  ON vifutboldev.match_referees (user_account_id)
  WHERE user_account_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_match_referees_normalized_doc
  ON vifutboldev.match_referees (normalized_document_id)
  WHERE normalized_document_id IS NOT NULL;

-- 4. Dedicated satellite tables for management and fan roles (1:1 with user_accounts)
CREATE TABLE IF NOT EXISTS vifutboldev.coach_profiles (
  user_account_id uuid PRIMARY KEY REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  club_name text NOT NULL DEFAULT '',
  license_level text NOT NULL DEFAULT '',
  phone text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS vifutboldev.organizer_profiles (
  user_account_id uuid PRIMARY KEY REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  organization_name text NOT NULL DEFAULT '',
  base_city text NOT NULL DEFAULT '',
  phone text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS vifutboldev.fan_profiles (
  user_account_id uuid PRIMARY KEY REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  city text NOT NULL DEFAULT '',
  phone text NOT NULL DEFAULT '',
  preferences text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- 5. Least-privilege grants & Row Level Security on satellite tables
REVOKE ALL ON
  vifutboldev.coach_profiles,
  vifutboldev.organizer_profiles,
  vifutboldev.fan_profiles
FROM PUBLIC, anon, authenticated;

GRANT ALL ON
  vifutboldev.coach_profiles,
  vifutboldev.organizer_profiles,
  vifutboldev.fan_profiles
TO service_role;

GRANT SELECT, INSERT, UPDATE ON
  vifutboldev.coach_profiles,
  vifutboldev.organizer_profiles,
  vifutboldev.fan_profiles
TO authenticated;

ALTER TABLE vifutboldev.coach_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.organizer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.fan_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS coach_profiles_owner_select ON vifutboldev.coach_profiles;
CREATE POLICY coach_profiles_owner_select ON vifutboldev.coach_profiles
  FOR SELECT TO authenticated
  USING (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS coach_profiles_owner_insert ON vifutboldev.coach_profiles;
CREATE POLICY coach_profiles_owner_insert ON vifutboldev.coach_profiles
  FOR INSERT TO authenticated
  WITH CHECK (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS coach_profiles_owner_update ON vifutboldev.coach_profiles;
CREATE POLICY coach_profiles_owner_update ON vifutboldev.coach_profiles
  FOR UPDATE TO authenticated
  USING (user_account_id = (SELECT auth.uid()))
  WITH CHECK (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS organizer_profiles_owner_select ON vifutboldev.organizer_profiles;
CREATE POLICY organizer_profiles_owner_select ON vifutboldev.organizer_profiles
  FOR SELECT TO authenticated
  USING (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS organizer_profiles_owner_insert ON vifutboldev.organizer_profiles;
CREATE POLICY organizer_profiles_owner_insert ON vifutboldev.organizer_profiles
  FOR INSERT TO authenticated
  WITH CHECK (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS organizer_profiles_owner_update ON vifutboldev.organizer_profiles;
CREATE POLICY organizer_profiles_owner_update ON vifutboldev.organizer_profiles
  FOR UPDATE TO authenticated
  USING (user_account_id = (SELECT auth.uid()))
  WITH CHECK (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS fan_profiles_owner_select ON vifutboldev.fan_profiles;
CREATE POLICY fan_profiles_owner_select ON vifutboldev.fan_profiles
  FOR SELECT TO authenticated
  USING (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS fan_profiles_owner_insert ON vifutboldev.fan_profiles;
CREATE POLICY fan_profiles_owner_insert ON vifutboldev.fan_profiles
  FOR INSERT TO authenticated
  WITH CHECK (user_account_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS fan_profiles_owner_update ON vifutboldev.fan_profiles;
CREATE POLICY fan_profiles_owner_update ON vifutboldev.fan_profiles
  FOR UPDATE TO authenticated
  USING (user_account_id = (SELECT auth.uid()))
  WITH CHECK (user_account_id = (SELECT auth.uid()));

-- 6. Atomic RPC for role persistence, satellite profile upsert, and
--    non-duplicating player/referee document linking
CREATE OR REPLACE FUNCTION vifutboldev.complete_role_profile(
  p_active_role text,
  p_authorized_roles text[] DEFAULT NULL,
  p_onboarding_completed boolean DEFAULT true,
  p_full_name text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_document_id text DEFAULT NULL,
  p_club_name text DEFAULT NULL,
  p_license_level text DEFAULT NULL,
  p_organization_name text DEFAULT NULL,
  p_base_city text DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_preferences text DEFAULT NULL,
  p_certification_level text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_auth_uid uuid;
  v_account vifutboldev.user_accounts%ROWTYPE;
  v_clean_phone text;
  v_clean_doc text;
  v_norm_doc text;
  v_clean_name text;
  v_roles text[];
  v_existing_player_id uuid;
  v_existing_player_user_id uuid;
  v_existing_referee_id uuid;
  v_existing_referee_user_id uuid;
  v_linked_player_id uuid;
  v_linked_referee_id uuid;
  v_coach_row vifutboldev.coach_profiles%ROWTYPE;
  v_organizer_row vifutboldev.organizer_profiles%ROWTYPE;
  v_fan_row vifutboldev.fan_profiles%ROWTYPE;
BEGIN
  v_auth_uid := auth.uid();
  IF v_auth_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_SESSION_MISSING' USING ERRCODE = 'P0001';
  END IF;

  IF p_active_role NOT IN ('organizer', 'coach', 'referee', 'player', 'fan') THEN
    RAISE EXCEPTION 'INVALID_ROLE' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_account
  FROM vifutboldev.user_accounts
  WHERE auth_user_id = v_auth_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'AUTH_USER_NOT_FOUND' USING ERRCODE = 'P0001';
  END IF;

  v_clean_phone := NULLIF(trim(COALESCE(p_phone, '')), '');
  v_clean_doc := NULLIF(trim(COALESCE(p_document_id, '')), '');
  v_norm_doc := CASE
    WHEN v_clean_doc IS NOT NULL THEN upper(regexp_replace(v_clean_doc, '[^A-Za-z0-9]', '', 'g'))
    ELSE NULL
  END;
  v_clean_name := COALESCE(NULLIF(trim(COALESCE(p_full_name, '')), ''), v_account.full_name);

  v_roles := COALESCE(p_authorized_roles, v_account.authorized_roles);
  IF NOT (p_active_role = ANY(v_roles)) THEN
    v_roles := array_append(v_roles, p_active_role);
  END IF;
  IF NOT ('fan' = ANY(v_roles)) THEN
    v_roles := array_append(v_roles, 'fan');
  END IF;

  UPDATE vifutboldev.user_accounts
  SET
    active_role = p_active_role,
    authorized_roles = v_roles,
    onboarding_completed = COALESCE(p_onboarding_completed, onboarding_completed),
    full_name = v_clean_name,
    phone = COALESCE(v_clean_phone, phone),
    document_id = COALESCE(v_clean_doc, document_id),
    normalized_document_id = COALESCE(v_norm_doc, normalized_document_id),
    updated_at = timezone('utc', now())
  WHERE id = v_account.id
  RETURNING * INTO v_account;

  v_norm_doc := COALESCE(v_norm_doc, v_account.normalized_document_id);
  v_clean_doc := COALESCE(v_clean_doc, v_account.document_id);
  v_clean_phone := COALESCE(v_clean_phone, v_account.phone);

  IF p_active_role = 'player' AND v_norm_doc IS NOT NULL THEN
    SELECT id, user_account_id
    INTO v_existing_player_id, v_existing_player_user_id
    FROM vifutboldev.players
    WHERE normalized_document_id = v_norm_doc
    ORDER BY (tournament_team_id IS NOT NULL) DESC, created_at ASC
    LIMIT 1;

    IF v_existing_player_id IS NOT NULL THEN
      IF v_existing_player_user_id IS NOT NULL AND v_existing_player_user_id <> v_account.id THEN
        RAISE EXCEPTION 'DOCUMENT_ALREADY_LINKED' USING ERRCODE = 'P0001';
      END IF;

      UPDATE vifutboldev.players
      SET
        user_account_id = v_account.id,
        phone = COALESCE(v_clean_phone, phone),
        full_name = CASE
          WHEN char_length(trim(full_name)) = 0 THEN v_clean_name
          ELSE full_name
        END,
        updated_at = timezone('utc', now())
      WHERE id = v_existing_player_id;

      v_linked_player_id := v_existing_player_id;
    ELSE
      INSERT INTO vifutboldev.players (
        user_account_id,
        full_name,
        document_id,
        normalized_document_id,
        phone
      )
      VALUES (
        v_account.id,
        CASE WHEN char_length(trim(v_clean_name)) >= 3 THEN v_clean_name ELSE v_clean_name || ' Jugador' END,
        v_clean_doc,
        v_norm_doc,
        v_clean_phone
      )
      RETURNING id INTO v_linked_player_id;
    END IF;
  ELSIF p_active_role = 'referee' AND v_norm_doc IS NOT NULL THEN
    SELECT id, user_account_id
    INTO v_existing_referee_id, v_existing_referee_user_id
    FROM vifutboldev.match_referees
    WHERE normalized_document_id = v_norm_doc
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_existing_referee_id IS NOT NULL THEN
      IF v_existing_referee_user_id IS NOT NULL AND v_existing_referee_user_id <> v_account.id THEN
        RAISE EXCEPTION 'DOCUMENT_ALREADY_LINKED' USING ERRCODE = 'P0001';
      END IF;

      UPDATE vifutboldev.match_referees
      SET
        user_account_id = v_account.id,
        phone = COALESCE(v_clean_phone, phone),
        full_name = CASE
          WHEN char_length(trim(full_name)) = 0 THEN v_clean_name
          ELSE full_name
        END,
        updated_at = timezone('utc', now())
      WHERE id = v_existing_referee_id;

      v_linked_referee_id := v_existing_referee_id;
    ELSE
      INSERT INTO vifutboldev.match_referees (
        user_account_id,
        full_name,
        document_id,
        normalized_document_id,
        phone,
        certification_level,
        is_active
      )
      VALUES (
        v_account.id,
        CASE WHEN char_length(trim(v_clean_name)) >= 3 THEN v_clean_name ELSE v_clean_name || ' Árbitro' END,
        v_clean_doc,
        v_norm_doc,
        v_clean_phone,
        COALESCE(NULLIF(trim(COALESCE(p_certification_level, '')), ''), 'Regional'),
        true
      )
      RETURNING id INTO v_linked_referee_id;
    END IF;
  ELSIF p_active_role = 'coach' THEN
    INSERT INTO vifutboldev.coach_profiles (
      user_account_id,
      club_name,
      license_level,
      phone
    )
    VALUES (
      v_account.id,
      COALESCE(trim(p_club_name), ''),
      COALESCE(trim(p_license_level), ''),
      COALESCE(v_clean_phone, '')
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      club_name = COALESCE(NULLIF(trim(EXCLUDED.club_name), ''), vifutboldev.coach_profiles.club_name),
      license_level = COALESCE(NULLIF(trim(EXCLUDED.license_level), ''), vifutboldev.coach_profiles.license_level),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), vifutboldev.coach_profiles.phone),
      updated_at = timezone('utc', now());
  ELSIF p_active_role = 'organizer' THEN
    INSERT INTO vifutboldev.organizer_profiles (
      user_account_id,
      organization_name,
      base_city,
      phone
    )
    VALUES (
      v_account.id,
      COALESCE(trim(p_organization_name), ''),
      COALESCE(trim(p_base_city), ''),
      COALESCE(v_clean_phone, '')
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      organization_name = COALESCE(NULLIF(trim(EXCLUDED.organization_name), ''), vifutboldev.organizer_profiles.organization_name),
      base_city = COALESCE(NULLIF(trim(EXCLUDED.base_city), ''), vifutboldev.organizer_profiles.base_city),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), vifutboldev.organizer_profiles.phone),
      updated_at = timezone('utc', now());
  ELSIF p_active_role = 'fan' THEN
    INSERT INTO vifutboldev.fan_profiles (
      user_account_id,
      city,
      phone,
      preferences
    )
    VALUES (
      v_account.id,
      COALESCE(trim(p_city), ''),
      COALESCE(v_clean_phone, ''),
      COALESCE(trim(p_preferences), '')
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      city = COALESCE(NULLIF(trim(EXCLUDED.city), ''), vifutboldev.fan_profiles.city),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), vifutboldev.fan_profiles.phone),
      preferences = COALESCE(NULLIF(trim(EXCLUDED.preferences), ''), vifutboldev.fan_profiles.preferences),
      updated_at = timezone('utc', now());
  END IF;

  SELECT * INTO v_coach_row FROM vifutboldev.coach_profiles WHERE user_account_id = v_account.id;
  SELECT * INTO v_organizer_row FROM vifutboldev.organizer_profiles WHERE user_account_id = v_account.id;
  SELECT * INTO v_fan_row FROM vifutboldev.fan_profiles WHERE user_account_id = v_account.id;

  IF v_linked_player_id IS NULL THEN
    SELECT id INTO v_linked_player_id FROM vifutboldev.players WHERE user_account_id = v_account.id LIMIT 1;
  END IF;
  IF v_linked_referee_id IS NULL THEN
    SELECT id INTO v_linked_referee_id FROM vifutboldev.match_referees WHERE user_account_id = v_account.id LIMIT 1;
  END IF;

  RETURN jsonb_build_object(
    'id', v_account.id,
    'auth_user_id', v_account.auth_user_id,
    'full_name', v_account.full_name,
    'email', v_account.email,
    'active_role', v_account.active_role,
    'authorized_roles', v_account.authorized_roles,
    'is_guest_fan', v_account.is_guest_fan,
    'onboarding_completed', v_account.onboarding_completed,
    'phone', v_account.phone,
    'document_id', v_account.document_id,
    'role_profile', jsonb_build_object(
      'club_name', v_coach_row.club_name,
      'license_level', v_coach_row.license_level,
      'organization_name', v_organizer_row.organization_name,
      'base_city', v_organizer_row.base_city,
      'city', v_fan_row.city,
      'preferences', v_fan_row.preferences,
      'linked_player_id', v_linked_player_id,
      'linked_referee_id', v_linked_referee_id
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text
) TO authenticated, service_role;
