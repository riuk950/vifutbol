-- =============================================================================
-- HU 17.2 - Migration 0001: Isolated DEV schema, triggers & RLS role helpers
-- Target schema: vifutboldev (never touches public or sibling schemas)
-- Idempotent: safe to run repeatedly
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS vifutboldev;

-- Restrict default public access and grant explicit schema usage only
REVOKE ALL ON SCHEMA vifutboldev FROM PUBLIC;
GRANT USAGE ON SCHEMA vifutboldev TO anon, authenticated, service_role;

-- Audit timestamp trigger helper
CREATE OR REPLACE FUNCTION vifutboldev.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at := timezone('utc', now());
  RETURN NEW;
END;
$$;

-- Cached lookup returning the current authenticated user's profile ID
CREATE OR REPLACE FUNCTION vifutboldev.current_user_account_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_account_id uuid;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT ua.id
  INTO v_account_id
  FROM vifutboldev.user_accounts AS ua
  WHERE ua.auth_user_id = v_uid
  LIMIT 1;

  RETURN v_account_id;
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.current_user_account_id() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION vifutboldev.current_user_account_id() TO authenticated, service_role;

-- Cached role check evaluating active_role for the current authenticated user
CREATE OR REPLACE FUNCTION vifutboldev.current_user_has_role(allowed_roles text[])
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid;
  v_matched boolean;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR allowed_roles IS NULL OR array_length(allowed_roles, 1) IS NULL THEN
    RETURN false;
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM vifutboldev.user_accounts AS ua
    WHERE ua.auth_user_id = v_uid
      AND ua.active_role = ANY (allowed_roles)
  )
  INTO v_matched;

  RETURN COALESCE(v_matched, false);
END;
$$;

REVOKE ALL ON FUNCTION vifutboldev.current_user_has_role(text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION vifutboldev.current_user_has_role(text[]) TO authenticated, service_role;
