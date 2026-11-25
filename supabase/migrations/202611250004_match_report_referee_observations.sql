-- =============================================================================
-- HU 26.1 - Migration: Referee Observations on Digital Match Reports
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

ALTER TABLE IF EXISTS vifutboldev.digital_match_reports
  ADD COLUMN IF NOT EXISTS referee_observations text;

COMMIT;

NOTIFY pgrst, 'reload schema';
