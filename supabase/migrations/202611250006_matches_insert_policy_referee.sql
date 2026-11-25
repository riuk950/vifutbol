-- =============================================================================
-- Migration: Allow referee role on vifutboldev.matches INSERT policy
-- Reason: PostgREST upsert (INSERT ... ON CONFLICT DO UPDATE) evaluates INSERT
--         RLS policy even when updating an existing match as an assigned referee.
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

DROP POLICY IF EXISTS matches_insert_organizer ON vifutboldev.matches;
DROP POLICY IF EXISTS matches_insert_organizer_or_referee ON vifutboldev.matches;

CREATE POLICY matches_insert_organizer_or_referee
  ON vifutboldev.matches
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer'::text, 'referee'::text]))
  );

COMMIT;

NOTIFY pgrst, 'reload schema';
