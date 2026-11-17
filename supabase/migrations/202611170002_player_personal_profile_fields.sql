-- Migration: 202611170002_player_personal_profile_fields.sql
-- Description: Add player personal data, Colombian location, and multiple positions to vifutboldev.players
--              and update vifutboldev.complete_role_profile RPC to persist them atomically.

-- 1. Add player personal and geographic columns to vifutboldev.players
ALTER TABLE vifutboldev.players
  ADD COLUMN IF NOT EXISTS first_name text,
  ADD COLUMN IF NOT EXISTS second_name text,
  ADD COLUMN IF NOT EXISTS first_surname text,
  ADD COLUMN IF NOT EXISTS second_surname text,
  ADD COLUMN IF NOT EXISTS sex text,
  ADD COLUMN IF NOT EXISTS birth_date date,
  ADD COLUMN IF NOT EXISTS blood_type text,
  ADD COLUMN IF NOT EXISTS department text,
  ADD COLUMN IF NOT EXISTS municipality text,
  ADD COLUMN IF NOT EXISTS secondary_positions text[] NOT NULL DEFAULT '{}'::text[];

-- 2. Idempotently add check constraints for sex and blood_type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_players_sex'
      AND conrelid = 'vifutboldev.players'::regclass
  ) THEN
    ALTER TABLE vifutboldev.players
      ADD CONSTRAINT chk_players_sex
      CHECK (sex IS NULL OR sex IN ('male', 'female', 'other'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_players_blood_type'
      AND conrelid = 'vifutboldev.players'::regclass
  ) THEN
    ALTER TABLE vifutboldev.players
      ADD CONSTRAINT chk_players_blood_type
      CHECK (blood_type IS NULL OR blood_type IN ('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'));
  END IF;
END $$;

-- 3. Drop previous 13-parameter complete_role_profile RPC to prevent PostgREST RPC overload collisions
DROP FUNCTION IF EXISTS vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text
);

-- 4. Create extended 24-parameter complete_role_profile RPC
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
  p_certification_level text DEFAULT NULL,
  p_first_name text DEFAULT NULL,
  p_second_name text DEFAULT NULL,
  p_first_surname text DEFAULT NULL,
  p_second_surname text DEFAULT NULL,
  p_sex text DEFAULT NULL,
  p_birth_date date DEFAULT NULL,
  p_blood_type text DEFAULT NULL,
  p_department text DEFAULT NULL,
  p_municipality text DEFAULT NULL,
  p_primary_position text DEFAULT NULL,
  p_secondary_positions text[] DEFAULT NULL
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
  v_composed_name text;
  v_roles text[];
  v_existing_player_id uuid;
  v_existing_player_user_id uuid;
  v_existing_referee_id uuid;
  v_existing_referee_user_id uuid;
  v_linked_player_id uuid;
  v_linked_referee_id uuid;
  v_player_row vifutboldev.players%ROWTYPE;
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

  -- Harmonize full name from discrete name parts if provided
  v_composed_name := trim(concat_ws(' ',
    NULLIF(trim(COALESCE(p_first_name, '')), ''),
    NULLIF(trim(COALESCE(p_second_name, '')), ''),
    NULLIF(trim(COALESCE(p_first_surname, '')), ''),
    NULLIF(trim(COALESCE(p_second_surname, '')), '')
  ));

  IF char_length(v_composed_name) > 0 THEN
    v_clean_name := v_composed_name;
  ELSE
    v_clean_name := COALESCE(NULLIF(trim(COALESCE(p_full_name, '')), ''), v_account.full_name);
  END IF;

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
          WHEN char_length(trim(COALESCE(v_clean_name, ''))) > 0 THEN v_clean_name
          ELSE full_name
        END,
        first_name = COALESCE(NULLIF(trim(p_first_name), ''), first_name),
        second_name = COALESCE(NULLIF(trim(p_second_name), ''), second_name),
        first_surname = COALESCE(NULLIF(trim(p_first_surname), ''), first_surname),
        second_surname = COALESCE(NULLIF(trim(p_second_surname), ''), second_surname),
        sex = COALESCE(NULLIF(trim(p_sex), ''), sex),
        birth_date = COALESCE(p_birth_date, birth_date),
        blood_type = COALESCE(NULLIF(trim(p_blood_type), ''), blood_type),
        department = COALESCE(NULLIF(trim(p_department), ''), department),
        municipality = COALESCE(NULLIF(trim(p_municipality), ''), municipality),
        position = COALESCE(NULLIF(trim(p_primary_position), ''), position),
        secondary_positions = COALESCE(p_secondary_positions, secondary_positions),
        updated_at = timezone('utc', now())
      WHERE id = v_existing_player_id;

      v_linked_player_id := v_existing_player_id;
    ELSE
      INSERT INTO vifutboldev.players (
        user_account_id,
        full_name,
        document_id,
        normalized_document_id,
        phone,
        first_name,
        second_name,
        first_surname,
        second_surname,
        sex,
        birth_date,
        blood_type,
        department,
        municipality,
        position,
        secondary_positions
      )
      VALUES (
        v_account.id,
        CASE WHEN char_length(trim(v_clean_name)) >= 3 THEN v_clean_name ELSE v_clean_name || ' Jugador' END,
        v_clean_doc,
        v_norm_doc,
        v_clean_phone,
        NULLIF(trim(p_first_name), ''),
        NULLIF(trim(p_second_name), ''),
        NULLIF(trim(p_first_surname), ''),
        NULLIF(trim(p_second_surname), ''),
        NULLIF(trim(p_sex), ''),
        p_birth_date,
        NULLIF(trim(p_blood_type), ''),
        NULLIF(trim(p_department), ''),
        NULLIF(trim(p_municipality), ''),
        COALESCE(NULLIF(trim(p_primary_position), ''), 'midfielder'),
        COALESCE(p_secondary_positions, '{}'::text[])
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

  IF v_linked_player_id IS NOT NULL THEN
    SELECT * INTO v_player_row FROM vifutboldev.players WHERE id = v_linked_player_id;
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
      'linked_referee_id', v_linked_referee_id,
      'first_name', v_player_row.first_name,
      'second_name', v_player_row.second_name,
      'first_surname', v_player_row.first_surname,
      'second_surname', v_player_row.second_surname,
      'sex', v_player_row.sex,
      'birth_date', v_player_row.birth_date,
      'blood_type', v_player_row.blood_type,
      'department', v_player_row.department,
      'municipality', v_player_row.municipality,
      'primary_position', v_player_row.position,
      'secondary_positions', COALESCE(v_player_row.secondary_positions, '{}'::text[])
    )
  );
END;
$$;

-- 5. Set function permissions
REVOKE ALL ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[]
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[]
) TO authenticated, service_role;
