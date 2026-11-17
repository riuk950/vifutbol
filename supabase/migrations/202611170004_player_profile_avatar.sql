-- Migration: 202611170004_player_profile_avatar.sql
-- Description: Add photo_url to vifutboldev.players and vifutboldev.user_accounts,
--              configure public-read/owner-write storage bucket 'player-avatars',
--              and update complete_role_profile RPC to 27 parameters persisting photo_url atomically.

-- 1. Add photo_url column to vifutboldev.players and vifutboldev.user_accounts
ALTER TABLE vifutboldev.players
  ADD COLUMN IF NOT EXISTS photo_url text;

ALTER TABLE vifutboldev.user_accounts
  ADD COLUMN IF NOT EXISTS photo_url text;

-- 2. Configure public-read storage bucket 'player-avatars'
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'player-avatars',
  'player-avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 3. Storage RLS policies for 'player-avatars' bucket
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'player_avatars_public_select'
  ) THEN
    CREATE POLICY player_avatars_public_select
    ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'player-avatars');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'player_avatars_owner_insert'
  ) THEN
    CREATE POLICY player_avatars_owner_insert
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'player-avatars'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'player_avatars_owner_update'
  ) THEN
    CREATE POLICY player_avatars_owner_update
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
      bucket_id = 'player-avatars'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    )
    WITH CHECK (
      bucket_id = 'player-avatars'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'player_avatars_owner_delete'
  ) THEN
    CREATE POLICY player_avatars_owner_delete
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
      bucket_id = 'player-avatars'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    );
  END IF;
END $$;

-- 4. Drop previous 26-parameter complete_role_profile RPC to prevent overload collisions
DROP FUNCTION IF EXISTS vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[], text, text
);

-- 5. Create extended 27-parameter complete_role_profile RPC
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
  p_photo_url text DEFAULT NULL
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

  v_roles := COALESCE(p_authorized_roles, v_account.authorized_roles);
  IF NOT (p_active_role = ANY(v_roles)) THEN
    v_roles := array_append(v_roles, p_active_role);
  END IF;

  -- Player and Referee linking validations
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
        certification_level
      )
      VALUES (
        v_account.id,
        v_clean_name,
        v_clean_doc,
        v_norm_doc,
        v_clean_phone,
        COALESCE(NULLIF(trim(p_certification_level), ''), 'local')
      )
      RETURNING id INTO v_linked_referee_id;
    END IF;
  END IF;

  -- Update user_accounts row (including photo_url)
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
    INSERT INTO vifutboldev.coach_profiles (user_account_id, club_name, license_level, updated_at)
    VALUES (
      v_account.id,
      NULLIF(trim(p_club_name), ''),
      NULLIF(trim(p_license_level), ''),
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      club_name = COALESCE(EXCLUDED.club_name, coach_profiles.club_name),
      license_level = COALESCE(EXCLUDED.license_level, coach_profiles.license_level),
      updated_at = timezone('utc', now())
    RETURNING * INTO v_coach_row;
  ELSIF p_active_role = 'organizer' THEN
    INSERT INTO vifutboldev.organizer_profiles (user_account_id, organization_name, base_city, updated_at)
    VALUES (
      v_account.id,
      NULLIF(trim(p_organization_name), ''),
      NULLIF(trim(p_base_city), ''),
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      organization_name = COALESCE(EXCLUDED.organization_name, organizer_profiles.organization_name),
      base_city = COALESCE(EXCLUDED.base_city, organizer_profiles.base_city),
      updated_at = timezone('utc', now())
    RETURNING * INTO v_organizer_row;
  ELSIF p_active_role = 'fan' THEN
    INSERT INTO vifutboldev.fan_profiles (user_account_id, city, preferences, updated_at)
    VALUES (
      v_account.id,
      NULLIF(trim(p_city), ''),
      NULLIF(trim(p_preferences), ''),
      timezone('utc', now())
    )
    ON CONFLICT (user_account_id) DO UPDATE SET
      city = COALESCE(EXCLUDED.city, fan_profiles.city),
      preferences = COALESCE(EXCLUDED.preferences, fan_profiles.preferences),
      updated_at = timezone('utc', now())
    RETURNING * INTO v_fan_row;
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
    'photo_url', v_account.photo_url,
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
      'secondary_positions', COALESCE(v_player_row.secondary_positions, '{}'::text[]),
      'document_front_url', v_player_row.document_front_url,
      'document_back_url', v_player_row.document_back_url,
      'photo_url', v_player_row.photo_url
    )
  );
END;
$$;

-- 6. Set function permissions
REVOKE ALL ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[], text, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION vifutboldev.complete_role_profile(
  text, text[], boolean, text, text, text, text, text, text, text, text, text, text,
  text, text, text, text, text, date, text, text, text, text, text[], text, text, text
) TO authenticated, service_role;
