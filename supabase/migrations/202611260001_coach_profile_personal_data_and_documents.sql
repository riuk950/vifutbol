-- =============================================================================
-- HU 27.1 - Migration: Coach Profile Personal Data & Dual-Side ID Documents
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

-- 1. Add Colombian ID & location columns to vifutboldev.coach_profiles
ALTER TABLE IF EXISTS vifutboldev.coach_profiles
  ADD COLUMN IF NOT EXISTS first_name text,
  ADD COLUMN IF NOT EXISTS second_name text,
  ADD COLUMN IF NOT EXISTS first_surname text,
  ADD COLUMN IF NOT EXISTS second_surname text,
  ADD COLUMN IF NOT EXISTS sex text,
  ADD COLUMN IF NOT EXISTS birth_date date,
  ADD COLUMN IF NOT EXISTS blood_type text,
  ADD COLUMN IF NOT EXISTS department text,
  ADD COLUMN IF NOT EXISTS municipality text,
  ADD COLUMN IF NOT EXISTS document_front_url text,
  ADD COLUMN IF NOT EXISTS document_back_url text;

-- 2. Update vifutboldev.complete_role_profile (preserving 28-parameter signature)
--    to persist all coach fields atomically and hydrate them in role_profile.
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
  p_secondary_positions text[] DEFAULT NULL,
  p_document_front_url text DEFAULT NULL,
  p_document_back_url text DEFAULT NULL,
  p_photo_url text DEFAULT NULL,
  p_certification_document_url text DEFAULT NULL
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
  v_referee_row vifutboldev.match_referees%ROWTYPE;
  v_coach_row vifutboldev.coach_profiles%ROWTYPE;
  v_organizer_row vifutboldev.organizer_profiles%ROWTYPE;
  v_fan_row vifutboldev.fan_profiles%ROWTYPE;
BEGIN
  v_auth_uid := auth.uid();
  IF v_auth_uid IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_account
  FROM vifutboldev.user_accounts
  WHERE auth_user_id = v_auth_uid
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'USER_ACCOUNT_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  IF p_active_role IS NULL OR p_active_role NOT IN ('player', 'coach', 'organizer', 'fan', 'referee') THEN
    RAISE EXCEPTION 'INVALID_ACTIVE_ROLE' USING ERRCODE = '22023';
  END IF;

  v_composed_name := concat_ws(' ',
    NULLIF(trim(p_first_name), ''),
    NULLIF(trim(p_second_name), ''),
    NULLIF(trim(p_first_surname), ''),
    NULLIF(trim(p_second_surname), '')
  );

  v_clean_name := COALESCE(
    NULLIF(trim(p_full_name), ''),
    NULLIF(trim(v_composed_name), ''),
    v_account.full_name
  );

  v_clean_phone := COALESCE(NULLIF(trim(p_phone), ''), v_account.phone);
  v_clean_doc := COALESCE(NULLIF(trim(p_document_id), ''), v_account.document_id);

  IF v_clean_doc IS NOT NULL THEN
    v_norm_doc := regexp_replace(upper(trim(v_clean_doc)), '[^0-9A-Z]', '', 'g');
  ELSE
    v_norm_doc := v_account.normalized_document_id;
  END IF;

  SELECT array_agg(DISTINCT r)
  INTO v_roles
  FROM unnest(
    COALESCE(p_authorized_roles, v_account.authorized_roles) || ARRAY[p_active_role, 'fan']::text[]
  ) AS r
  WHERE r IN ('player', 'coach', 'organizer', 'fan', 'referee');

  -- Player or Referee linking by normalized document
  IF p_active_role = 'player' AND v_norm_doc IS NOT NULL THEN
    SELECT id, user_account_id
    INTO v_existing_player_id, v_existing_player_user_id
    FROM vifutboldev.players
    WHERE normalized_document_id = v_norm_doc
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_existing_player_id IS NOT NULL THEN
      IF v_existing_player_user_id IS NOT NULL AND v_existing_player_user_id <> v_account.id THEN
        RAISE EXCEPTION 'DOCUMENT_ALREADY_LINKED' USING ERRCODE = 'P0001';
      END IF;

      UPDATE vifutboldev.players
      SET
        user_account_id = v_account.id,
        phone = COALESCE(v_clean_phone, phone),
        full_name = COALESCE(v_clean_name, full_name),
        document_id = COALESCE(v_clean_doc, document_id),
        normalized_document_id = v_norm_doc,
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
        document_front_url = COALESCE(NULLIF(trim(p_document_front_url), ''), document_front_url),
        document_back_url = COALESCE(NULLIF(trim(p_document_back_url), ''), document_back_url),
        photo_url = COALESCE(NULLIF(trim(p_photo_url), ''), photo_url),
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
        secondary_positions,
        document_front_url,
        document_back_url,
        photo_url
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
        COALESCE(p_secondary_positions, '{}'::text[]),
        NULLIF(trim(p_document_front_url), ''),
        NULLIF(trim(p_document_back_url), ''),
        NULLIF(trim(p_photo_url), '')
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
        full_name = COALESCE(v_clean_name, full_name),
        document_id = COALESCE(v_clean_doc, document_id),
        normalized_document_id = v_norm_doc,
        certification_level = COALESCE(NULLIF(trim(p_certification_level), ''), certification_level),
        first_name = COALESCE(NULLIF(trim(p_first_name), ''), first_name),
        second_name = COALESCE(NULLIF(trim(p_second_name), ''), second_name),
        first_surname = COALESCE(NULLIF(trim(p_first_surname), ''), first_surname),
        second_surname = COALESCE(NULLIF(trim(p_second_surname), ''), second_surname),
        sex = COALESCE(NULLIF(trim(p_sex), ''), sex),
        birth_date = COALESCE(p_birth_date, birth_date),
        blood_type = COALESCE(NULLIF(trim(p_blood_type), ''), blood_type),
        department = COALESCE(NULLIF(trim(p_department), ''), department),
        municipality = COALESCE(NULLIF(trim(p_municipality), ''), municipality),
        document_front_url = COALESCE(NULLIF(trim(p_document_front_url), ''), document_front_url),
        document_back_url = COALESCE(NULLIF(trim(p_document_back_url), ''), document_back_url),
        certification_document_url = COALESCE(NULLIF(trim(p_certification_document_url), ''), certification_document_url),
        photo_url = COALESCE(NULLIF(trim(p_photo_url), ''), photo_url),
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
        first_name,
        second_name,
        first_surname,
        second_surname,
        sex,
        birth_date,
        blood_type,
        department,
        municipality,
        document_front_url,
        document_back_url,
        certification_document_url,
        photo_url
      )
      VALUES (
        v_account.id,
        v_clean_name,
        v_clean_doc,
        v_norm_doc,
        v_clean_phone,
        COALESCE(NULLIF(trim(p_certification_level), ''), 'local'),
        NULLIF(trim(p_first_name), ''),
        NULLIF(trim(p_second_name), ''),
        NULLIF(trim(p_first_surname), ''),
        NULLIF(trim(p_second_surname), ''),
        NULLIF(trim(p_sex), ''),
        p_birth_date,
        NULLIF(trim(p_blood_type), ''),
        NULLIF(trim(p_department), ''),
        NULLIF(trim(p_municipality), ''),
        NULLIF(trim(p_document_front_url), ''),
        NULLIF(trim(p_document_back_url), ''),
        NULLIF(trim(p_certification_document_url), ''),
        NULLIF(trim(p_photo_url), '')
      )
      RETURNING id INTO v_linked_referee_id;
    END IF;
  END IF;

  -- Update user_accounts row
  UPDATE vifutboldev.user_accounts
  SET
    active_role = p_active_role,
    authorized_roles = v_roles,
    onboarding_completed = COALESCE(p_onboarding_completed, true),
    full_name = v_clean_name,
    phone = v_clean_phone,
    document_id = v_clean_doc,
    normalized_document_id = v_norm_doc,
    photo_url = COALESCE(NULLIF(trim(p_photo_url), ''), photo_url),
    is_guest_fan = CASE WHEN p_active_role = 'fan' THEN v_account.is_guest_fan ELSE false END,
    updated_at = timezone('utc', now())
  WHERE id = v_account.id
  RETURNING * INTO v_account;

  -- Upsert role-specific profiles
  IF p_active_role = 'coach' THEN
    INSERT INTO vifutboldev.coach_profiles (
      user_account_id,
      club_name,
      license_level,
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
      document_front_url,
      document_back_url,
      updated_at
    )
    VALUES (
      v_account.id,
      NULLIF(trim(p_club_name), ''),
      NULLIF(trim(p_license_level), ''),
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
      NULLIF(trim(p_document_front_url), ''),
      NULLIF(trim(p_document_back_url), ''),
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      club_name = COALESCE(NULLIF(trim(EXCLUDED.club_name), ''), coach_profiles.club_name),
      license_level = COALESCE(NULLIF(trim(EXCLUDED.license_level), ''), coach_profiles.license_level),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), coach_profiles.phone),
      first_name = COALESCE(NULLIF(trim(EXCLUDED.first_name), ''), coach_profiles.first_name),
      second_name = CASE
        WHEN p_second_name IS NULL THEN coach_profiles.second_name
        ELSE NULLIF(trim(p_second_name), '')
      END,
      first_surname = COALESCE(NULLIF(trim(EXCLUDED.first_surname), ''), coach_profiles.first_surname),
      second_surname = CASE
        WHEN p_second_surname IS NULL THEN coach_profiles.second_surname
        ELSE NULLIF(trim(p_second_surname), '')
      END,
      sex = COALESCE(NULLIF(trim(EXCLUDED.sex), ''), coach_profiles.sex),
      birth_date = COALESCE(EXCLUDED.birth_date, coach_profiles.birth_date),
      blood_type = COALESCE(NULLIF(trim(EXCLUDED.blood_type), ''), coach_profiles.blood_type),
      department = COALESCE(NULLIF(trim(EXCLUDED.department), ''), coach_profiles.department),
      municipality = COALESCE(NULLIF(trim(EXCLUDED.municipality), ''), coach_profiles.municipality),
      document_front_url = COALESCE(NULLIF(trim(EXCLUDED.document_front_url), ''), coach_profiles.document_front_url),
      document_back_url = COALESCE(NULLIF(trim(EXCLUDED.document_back_url), ''), coach_profiles.document_back_url),
      updated_at = timezone('utc', now())
    RETURNING * INTO v_coach_row;
  ELSIF p_active_role = 'organizer' THEN
    INSERT INTO vifutboldev.organizer_profiles (user_account_id, organization_name, base_city, phone, updated_at)
    VALUES (
      v_account.id,
      NULLIF(trim(p_organization_name), ''),
      NULLIF(trim(p_base_city), ''),
      v_clean_phone,
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      organization_name = COALESCE(NULLIF(trim(EXCLUDED.organization_name), ''), organizer_profiles.organization_name),
      base_city = COALESCE(NULLIF(trim(EXCLUDED.base_city), ''), organizer_profiles.base_city),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), organizer_profiles.phone),
      updated_at = timezone('utc', now())
    RETURNING * INTO v_organizer_row;
  ELSIF p_active_role = 'fan' THEN
    INSERT INTO vifutboldev.fan_profiles (user_account_id, city, phone, preferences, updated_at)
    VALUES (
      v_account.id,
      NULLIF(trim(p_city), ''),
      v_clean_phone,
      NULLIF(trim(p_preferences), ''),
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      city = COALESCE(NULLIF(trim(EXCLUDED.city), ''), fan_profiles.city),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), fan_profiles.phone),
      preferences = COALESCE(NULLIF(trim(EXCLUDED.preferences), ''), fan_profiles.preferences),
      updated_at = timezone('utc', now())
    RETURNING * INTO v_fan_row;
  END IF;

  -- Preserve existing satellite profile rows for response hydration
  IF v_coach_row.user_account_id IS NULL THEN
    SELECT * INTO v_coach_row FROM vifutboldev.coach_profiles WHERE user_account_id = v_account.id;
  END IF;
  IF v_organizer_row.user_account_id IS NULL THEN
    SELECT * INTO v_organizer_row FROM vifutboldev.organizer_profiles WHERE user_account_id = v_account.id;
  END IF;
  IF v_fan_row.user_account_id IS NULL THEN
    SELECT * INTO v_fan_row FROM vifutboldev.fan_profiles WHERE user_account_id = v_account.id;
  END IF;

  IF v_linked_player_id IS NULL THEN
    SELECT id INTO v_linked_player_id FROM vifutboldev.players WHERE user_account_id = v_account.id LIMIT 1;
  END IF;
  IF v_linked_referee_id IS NULL THEN
    SELECT id INTO v_linked_referee_id FROM vifutboldev.match_referees WHERE user_account_id = v_account.id LIMIT 1;
  END IF;

  IF v_linked_player_id IS NOT NULL THEN
    SELECT * INTO v_player_row FROM vifutboldev.players WHERE id = v_linked_player_id;
  END IF;
  IF v_linked_referee_id IS NOT NULL THEN
    SELECT * INTO v_referee_row FROM vifutboldev.match_referees WHERE id = v_linked_referee_id;
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
    'photo_url', v_account.photo_url,
    'role_profile', jsonb_build_object(
      'club_name', v_coach_row.club_name,
      'license_level', v_coach_row.license_level,
      'organization_name', v_organizer_row.organization_name,
      'base_city', v_organizer_row.base_city,
      'city', v_fan_row.city,
      'preferences', v_fan_row.preferences,
      'certification_level', v_referee_row.certification_level,
      'certification_document_url', v_referee_row.certification_document_url,
      'linked_player_id', v_linked_player_id,
      'linked_referee_id', v_linked_referee_id,
      'first_name', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.first_name, v_player_row.first_name, v_referee_row.first_name) ELSE COALESCE(v_player_row.first_name, v_referee_row.first_name, v_coach_row.first_name) END,
      'second_name', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.second_name, v_player_row.second_name, v_referee_row.second_name) ELSE COALESCE(v_player_row.second_name, v_referee_row.second_name, v_coach_row.second_name) END,
      'first_surname', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.first_surname, v_player_row.first_surname, v_referee_row.first_surname) ELSE COALESCE(v_player_row.first_surname, v_referee_row.first_surname, v_coach_row.first_surname) END,
      'second_surname', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.second_surname, v_player_row.second_surname, v_referee_row.second_surname) ELSE COALESCE(v_player_row.second_surname, v_referee_row.second_surname, v_coach_row.second_surname) END,
      'sex', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.sex, v_player_row.sex, v_referee_row.sex) ELSE COALESCE(v_player_row.sex, v_referee_row.sex, v_coach_row.sex) END,
      'birth_date', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.birth_date, v_player_row.birth_date, v_referee_row.birth_date) ELSE COALESCE(v_player_row.birth_date, v_referee_row.birth_date, v_coach_row.birth_date) END,
      'blood_type', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.blood_type, v_player_row.blood_type, v_referee_row.blood_type) ELSE COALESCE(v_player_row.blood_type, v_referee_row.blood_type, v_coach_row.blood_type) END,
      'department', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.department, v_player_row.department, v_referee_row.department) ELSE COALESCE(v_player_row.department, v_referee_row.department, v_coach_row.department) END,
      'municipality', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.municipality, v_player_row.municipality, v_referee_row.municipality) ELSE COALESCE(v_player_row.municipality, v_referee_row.municipality, v_coach_row.municipality) END,
      'primary_position', v_player_row.position,
      'secondary_positions', COALESCE(v_player_row.secondary_positions, '{}'::text[]),
      'document_front_url', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.document_front_url, v_player_row.document_front_url, v_referee_row.document_front_url) ELSE COALESCE(v_player_row.document_front_url, v_referee_row.document_front_url, v_coach_row.document_front_url) END,
      'document_back_url', CASE WHEN p_active_role = 'coach' THEN COALESCE(v_coach_row.document_back_url, v_player_row.document_back_url, v_referee_row.document_back_url) ELSE COALESCE(v_player_row.document_back_url, v_referee_row.document_back_url, v_coach_row.document_back_url) END,
      'photo_url', COALESCE(v_player_row.photo_url, v_referee_row.photo_url)
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[], text, text, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[], text, text, text, text
) TO authenticated, service_role;

COMMIT;

NOTIFY pgrst, 'reload schema';
