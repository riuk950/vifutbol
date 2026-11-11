-- =============================================================================
-- HU 17.2 - Migration 0004: Idempotent minimal DEV seed dataset
-- Target schema: vifutboldev
-- Safe to run repeatedly (ON CONFLICT DO NOTHING)
-- =============================================================================

-- 1. Seed core actor profiles (no auth.users dependency needed for DEV read seeds)
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
VALUES
  (
    '10000000-0000-4000-8000-000000000001',
    NULL,
    'Carlos Mendoza (Organizador DEV)',
    'organizer.dev@vifutbol.local',
    'organizer',
    ARRAY['organizer', 'fan']::text[],
    false,
    true
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    NULL,
    'Laura Gómez (DT DEV)',
    'coach.dev@vifutbol.local',
    'coach',
    ARRAY['coach', 'fan']::text[],
    false,
    true
  ),
  (
    '10000000-0000-4000-8000-000000000003',
    NULL,
    'Andrés Rojas (Árbitro DEV)',
    'referee.dev@vifutbol.local',
    'referee',
    ARRAY['referee', 'fan']::text[],
    false,
    true
  )
ON CONFLICT (id) DO NOTHING;

-- 2. Seed DEV sports venue and pitch
INSERT INTO vifutboldev.sports_venues (
  id,
  organizer_id,
  name,
  address,
  urban_reference,
  latitude,
  longitude,
  status
)
VALUES (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'Complejo Deportivo KickPulse Norte',
  'Av. Simón Bolívar #45-120, Sector Norte',
  'Frente al Parque Metropolitano',
  4.6533,
  -74.0836,
  'active'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO vifutboldev.venue_pitches (
  id,
  venue_id,
  name,
  surface_type,
  format,
  capacity,
  has_lighting,
  status
)
VALUES (
  '21000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  'Cancha Principal Sintética 1',
  'syntheticGrass',
  'football11',
  500,
  true,
  'active'
)
ON CONFLICT (id) DO NOTHING;

-- 3. Seed DEV tournament
INSERT INTO vifutboldev.tournaments (
  id,
  organizer_id,
  name,
  category,
  start_date,
  end_date,
  format,
  status,
  rules_config,
  venue_ids
)
VALUES (
  '30000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'Copa Apertura KickPulse DEV 2026',
  'Libre Masculina',
  '2026-11-01T08:00:00Z',
  '2026-12-20T20:00:00Z',
  'league',
  'inProgress',
  '{"winPoints":3,"drawPoints":1,"lossPoints":0,"yellowCardLimit":5}'::jsonb,
  ARRAY['20000000-0000-4000-8000-000000000001']::uuid[]
)
ON CONFLICT (id) DO NOTHING;

-- 4. Seed master teams & tournament enrollments
INSERT INTO vifutboldev.teams (
  id,
  coach_id,
  name,
  normalized_name,
  short_code,
  crest_shape,
  category
)
VALUES
  (
    '40000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000002',
    'Atlético Horizonte FC',
    'atletico horizonte fc',
    'AHF',
    'shield',
    'Libre'
  ),
  (
    '40000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000002',
    'Real Metropolitano',
    'real metropolitano',
    'RME',
    'diamond',
    'Libre'
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO vifutboldev.tournament_teams (
  id,
  tournament_id,
  team_id,
  group_name,
  eligibility_status
)
VALUES
  (
    '41000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000001',
    'Grupo A',
    'eligible'
  ),
  (
    '41000000-0000-4000-8000-000000000002',
    '30000000-0000-4000-8000-000000000001',
    '40000000-0000-4000-8000-000000000002',
    'Grupo A',
    'eligible'
  )
ON CONFLICT (id) DO NOTHING;

-- 5. Seed match referee and public tournament news bulletin
INSERT INTO vifutboldev.match_referees (
  id,
  user_account_id,
  full_name,
  certification_level,
  is_active
)
VALUES (
  '50000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000003',
  'Andrés Rojas',
  'Nacional FIFA A',
  true
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO vifutboldev.tournament_news (
  id,
  tournament_id,
  title,
  body,
  category,
  author_user_id,
  author_name,
  is_pinned
)
VALUES (
  '60000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  'Inicio oficial del entorno DEV vifutboldev',
  'Bienvenidos a la Copa Apertura KickPulse DEV 2026. Toda la operación del campeonato se ejecuta en el esquema aislado vifutboldev.',
  'generalAnnouncement',
  '10000000-0000-4000-8000-000000000001',
  'Carlos Mendoza (Organizador DEV)',
  true
)
ON CONFLICT (id) DO NOTHING;
