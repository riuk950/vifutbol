-- =============================================================================
-- HU 27.3 - Migration: Team Crest Photo URL & Public-Read Storage Bucket
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

BEGIN;

-- 1. Add crest_url column to vifutboldev.teams
ALTER TABLE IF EXISTS vifutboldev.teams
  ADD COLUMN IF NOT EXISTS crest_url text;

-- 2. Configure public-read / owner-write storage bucket 'team-crests' (5 MB max)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'team-crests',
  'team-crests',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 3. Storage RLS policies for 'team-crests' bucket
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'team_crests_public_select'
  ) THEN
    CREATE POLICY team_crests_public_select
    ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'team-crests');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'team_crests_owner_insert'
  ) THEN
    CREATE POLICY team_crests_owner_insert
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'team-crests'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'team_crests_owner_update'
  ) THEN
    CREATE POLICY team_crests_owner_update
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
      bucket_id = 'team-crests'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    )
    WITH CHECK (
      bucket_id = 'team-crests'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'team_crests_owner_delete'
  ) THEN
    CREATE POLICY team_crests_owner_delete
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
      bucket_id = 'team-crests'
      AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    );
  END IF;
END $$;

COMMIT;

NOTIFY pgrst, 'reload schema';
