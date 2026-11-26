-- =============================================================================
-- HU 27.2 - Migration: Teams Delegate Name & Founded Date
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

ALTER TABLE IF EXISTS vifutboldev.teams
  ADD COLUMN IF NOT EXISTS delegate_name text,
  ADD COLUMN IF NOT EXISTS founded_date date;

COMMIT;

NOTIFY pgrst, 'reload schema';
