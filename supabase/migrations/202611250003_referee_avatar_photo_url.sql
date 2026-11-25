-- =============================================================================
-- HU 25.2 - Migration: Referee Avatar Photo URL
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

-- 1. Add photo_url column to vifutboldev.match_referees
ALTER TABLE IF EXISTS vifutboldev.match_referees
  ADD COLUMN IF NOT EXISTS photo_url text;

-- 2. Update vifutboldev.complete_role_profile (28 parameters) to persist and
--    hydrate match_referees.photo_url alongside user_accounts.photo_url
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
    INSERT INTO vifutboldev.coach_profiles (user_account_id, club_name, license_level, phone, updated_at)
    VALUES (
      v_account.id,
      NULLIF(trim(p_club_name), ''),
      NULLIF(trim(p_license_level), ''),
      v_clean_phone,
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      club_name = COALESCE(NULLIF(trim(EXCLUDED.club_name), ''), coach_profiles.club_name),
      license_level = COALESCE(NULLIF(trim(EXCLUDED.license_level), ''), coach_profiles.license_level),
      phone = COALESCE(NULLIF(trim(EXCLUDED.phone), ''), coach_profiles.phone),
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
      'first_name', COALESCE(v_player_row.first_name, v_referee_row.first_name),
      'second_name', COALESCE(v_player_row.second_name, v_referee_row.second_name),
      'first_surname', COALESCE(v_player_row.first_surname, v_referee_row.first_surname),
      'second_surname', COALESCE(v_player_row.second_surname, v_referee_row.second_surname),
      'sex', COALESCE(v_player_row.sex, v_referee_row.sex),
      'birth_date', COALESCE(v_player_row.birth_date, v_referee_row.birth_date),
      'blood_type', COALESCE(v_player_row.blood_type, v_referee_row.blood_type),
      'department', COALESCE(v_player_row.department, v_referee_row.department),
      'municipality', COALESCE(v_player_row.municipality, v_referee_row.municipality),
      'primary_position', v_player_row.position,
      'secondary_positions', COALESCE(v_player_row.secondary_positions, '{}'::text[]),
      'document_front_url', COALESCE(v_player_row.document_front_url, v_referee_row.document_front_url),
      'document_back_url', COALESCE(v_player_row.document_back_url, v_referee_row.document_back_url),
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

-- 3. Update vifutboldev.delete_my_account() so referee photo_url is also cleared
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
    UPDATE vifutboldev.players
    SET
      user_account_id = NULL,
      phone = NULL,
      photo_url = NULL,
      document_front_url = NULL,
      document_back_url = NULL
    WHERE user_account_id = v_account_id
      AND tournament_id IS NOT NULL;

    DELETE FROM vifutboldev.players
    WHERE user_account_id = v_account_id
      AND tournament_id IS NULL;

    UPDATE vifutboldev.match_referees
    SET
      user_account_id = NULL,
      phone = NULL,
      photo_url = NULL,
      document_front_url = NULL,
      document_back_url = NULL,
      certification_document_url = NULL
    WHERE user_account_id = v_account_id;

    DELETE FROM vifutboldev.user_accounts
    WHERE id = v_account_id;
  END IF;

  DELETE FROM storage.objects
  WHERE bucket_id IN ('player-avatars', 'player-documents')
    AND (
      owner = v_auth_uid
      OR name LIKE v_auth_uid::text || '/%'
    );

  DELETE FROM auth.users
  WHERE id = v_auth_uid;
END;
$$;

COMMIT;

NOTIFY pgrst, 'reload schema';
