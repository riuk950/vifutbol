-- =============================================================================
-- HU 17.3 - Migration 0005: Automatic user_accounts profile creation on auth.users
-- Target schema: vifutboldev (requires HU 17.2 migrations 0001-0004 applied)
-- Idempotent: safe to run repeatedly
-- =============================================================================

CREATE OR REPLACE FUNCTION vifutboldev.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_email text;
  v_raw_name text;
  v_full_name text;
BEGIN
  v_email := lower(trim(COALESCE(NEW.email, '')));
  v_raw_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
    NULLIF(split_part(v_email, '@', 1), ''),
    'Usuario KickPulse'
  );
  v_full_name := CASE
    WHEN char_length(v_raw_name) >= 2 THEN v_raw_name
    ELSE 'Usuario KickPulse'
  END;

  INSERT INTO vifutboldev.user_accounts (
    id,
    auth_user_id,
    full_name,
    email,
    active_role,
    authorized_roles,
    is_guest_fan,
    onboarding_completed
  )
  VALUES (
    NEW.id,
    NEW.id,
    v_full_name,
    v_email,
    'fan',
    ARRAY['fan']::text[],
    false,
    false
  )
  ON CONFLICT (auth_user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.handle_new_auth_user()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created_vifutboldev ON auth.users;
CREATE TRIGGER on_auth_user_created_vifutboldev
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION vifutboldev.handle_new_auth_user();
