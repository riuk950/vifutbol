-- =============================================================================
-- HU 17.2 - Migration 0002: 18 domain tables, constraints, B-Tree FK indexes
--           and updated_at triggers in vifutboldev
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

-- 1. user_accounts (UserAccount)
CREATE TABLE IF NOT EXISTS vifutboldev.user_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
  full_name text NOT NULL CHECK (char_length(trim(full_name)) >= 2),
  email text NOT NULL UNIQUE,
  active_role text NOT NULL DEFAULT 'fan'
    CHECK (active_role IN ('organizer', 'coach', 'referee', 'player', 'fan')),
  authorized_roles text[] NOT NULL DEFAULT ARRAY['fan']::text[],
  is_guest_fan boolean NOT NULL DEFAULT false,
  onboarding_completed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_user_accounts_auth_user_id
  ON vifutboldev.user_accounts (auth_user_id);
CREATE INDEX IF NOT EXISTS idx_user_accounts_active_role
  ON vifutboldev.user_accounts (active_role);

-- 2. sports_venues (SportsVenue)
CREATE TABLE IF NOT EXISTS vifutboldev.sports_venues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  name text NOT NULL CHECK (char_length(trim(name)) >= 3),
  address text NOT NULL CHECK (char_length(trim(address)) >= 5),
  urban_reference text NOT NULL DEFAULT '',
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'maintenance', 'inactive')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_sports_venues_organizer_id
  ON vifutboldev.sports_venues (organizer_id);
CREATE INDEX IF NOT EXISTS idx_sports_venues_status
  ON vifutboldev.sports_venues (status);

-- 3. venue_pitches (VenuePitch)
CREATE TABLE IF NOT EXISTS vifutboldev.venue_pitches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES vifutboldev.sports_venues(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(trim(name)) >= 2),
  surface_type text NOT NULL
    CHECK (surface_type IN ('naturalGrass', 'syntheticGrass', 'hybrid', 'indoorCourt', 'dirt')),
  format text NOT NULL
    CHECK (format IN ('football11', 'football9', 'football7', 'football5')),
  capacity integer NOT NULL DEFAULT 0 CHECK (capacity >= 0),
  has_lighting boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'maintenance', 'inactive')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_venue_pitches_venue_id
  ON vifutboldev.venue_pitches (venue_id);
CREATE INDEX IF NOT EXISTS idx_venue_pitches_status
  ON vifutboldev.venue_pitches (status);

-- 4. tournaments (ChampionshipTournament)
CREATE TABLE IF NOT EXISTS vifutboldev.tournaments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  name text NOT NULL CHECK (char_length(trim(name)) >= 3),
  category text NOT NULL,
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  format text NOT NULL
    CHECK (format IN ('league', 'knockoutCup', 'mixedGroupsAndKnockout')),
  status text NOT NULL DEFAULT 'openRegistration'
    CHECK (status IN ('openRegistration', 'inProgress', 'finished')),
  rules_config jsonb NOT NULL DEFAULT '{}'::jsonb,
  venue_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_tournaments_organizer_id
  ON vifutboldev.tournaments (organizer_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_status
  ON vifutboldev.tournaments (status);
CREATE INDEX IF NOT EXISTS idx_tournaments_start_date
  ON vifutboldev.tournaments (start_date);

-- 5. rule_audit_entries (RuleAuditEntry)
CREATE TABLE IF NOT EXISTS vifutboldev.rule_audit_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  recorded_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  summary text NOT NULL,
  reason text NOT NULL,
  recalculation_confirmed boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_rule_audit_entries_tournament_id
  ON vifutboldev.rule_audit_entries (tournament_id);
CREATE INDEX IF NOT EXISTS idx_rule_audit_entries_recorded_at
  ON vifutboldev.rule_audit_entries (recorded_at);

-- 6. tournament_news (TournamentNewsItem)
CREATE TABLE IF NOT EXISTS vifutboldev.tournament_news (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(trim(title)) BETWEEN 3 AND 120),
  body text NOT NULL CHECK (char_length(trim(body)) BETWEEN 5 AND 3000),
  category text NOT NULL
    CHECK (category IN ('generalAnnouncement', 'disciplinaryBulletin', 'reschedulingNotice')),
  published_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  author_user_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  author_name text NOT NULL,
  is_pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_tournament_news_tournament_id
  ON vifutboldev.tournament_news (tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_news_author_user_id
  ON vifutboldev.tournament_news (author_user_id);
CREATE INDEX IF NOT EXISTS idx_tournament_news_published_at
  ON vifutboldev.tournament_news (published_at DESC);

-- 7. teams (Master Team club entity)
CREATE TABLE IF NOT EXISTS vifutboldev.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  name text NOT NULL CHECK (char_length(trim(name)) >= 3),
  normalized_name text NOT NULL UNIQUE,
  short_code text NOT NULL CHECK (char_length(trim(short_code)) BETWEEN 2 AND 4),
  crest_shape text NOT NULL DEFAULT 'shield'
    CHECK (crest_shape IN ('shield', 'circle', 'diamond', 'hexagon')),
  primary_color_hex bigint NOT NULL DEFAULT 4278249078,
  secondary_color_hex bigint NOT NULL DEFAULT 4278849047,
  category text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

ALTER TABLE vifutboldev.teams
  ALTER COLUMN primary_color_hex TYPE bigint,
  ALTER COLUMN secondary_color_hex TYPE bigint;

CREATE INDEX IF NOT EXISTS idx_teams_coach_id
  ON vifutboldev.teams (coach_id);
CREATE INDEX IF NOT EXISTS idx_teams_normalized_name
  ON vifutboldev.teams (normalized_name);

-- 8. tournament_teams (TournamentTeam enrollment)
CREATE TABLE IF NOT EXISTS vifutboldev.tournament_teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  team_id uuid NOT NULL REFERENCES vifutboldev.teams(id) ON DELETE CASCADE,
  group_name text,
  eligibility_status text NOT NULL DEFAULT 'pendingVerification'
    CHECK (eligibility_status IN ('pendingVerification', 'eligible')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (tournament_id, team_id)
);

CREATE INDEX IF NOT EXISTS idx_tournament_teams_tournament_id
  ON vifutboldev.tournament_teams (tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_teams_team_id
  ON vifutboldev.tournament_teams (team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_teams_eligibility_status
  ON vifutboldev.tournament_teams (eligibility_status);

-- 9. fan_favorite_teams (FanFavoriteTeam)
CREATE TABLE IF NOT EXISTS vifutboldev.fan_favorite_teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE,
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  team_id uuid NOT NULL REFERENCES vifutboldev.teams(id) ON DELETE CASCADE,
  team_name text NOT NULL,
  notifications_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (user_id, tournament_id, team_id)
);

CREATE INDEX IF NOT EXISTS idx_fan_favorite_teams_user_id
  ON vifutboldev.fan_favorite_teams (user_id);
CREATE INDEX IF NOT EXISTS idx_fan_favorite_teams_tournament_id
  ON vifutboldev.fan_favorite_teams (tournament_id);
CREATE INDEX IF NOT EXISTS idx_fan_favorite_teams_team_id
  ON vifutboldev.fan_favorite_teams (team_id);

-- 10. players (RegisteredPlayer)
CREATE TABLE IF NOT EXISTS vifutboldev.players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id) ON DELETE CASCADE,
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  user_account_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  full_name text NOT NULL CHECK (char_length(trim(full_name)) >= 3),
  document_id text NOT NULL CHECK (char_length(trim(document_id)) >= 5),
  normalized_document_id text NOT NULL,
  shirt_number integer NOT NULL CHECK (shirt_number BETWEEN 1 AND 99),
  position text NOT NULL
    CHECK (position IN ('goalkeeper', 'defender', 'midfielder', 'forward')),
  is_eligible boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (tournament_team_id, shirt_number),
  UNIQUE (tournament_id, normalized_document_id)
);

CREATE INDEX IF NOT EXISTS idx_players_tournament_team_id
  ON vifutboldev.players (tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_players_tournament_id
  ON vifutboldev.players (tournament_id);
CREATE INDEX IF NOT EXISTS idx_players_user_account_id
  ON vifutboldev.players (user_account_id);

-- 11. player_internal_trackings (PlayerInternalTracking)
CREATE TABLE IF NOT EXISTS vifutboldev.player_internal_trackings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id uuid NOT NULL REFERENCES vifutboldev.players(id) ON DELETE CASCADE,
  tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id) ON DELETE CASCADE,
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  coach_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  matches_played integer NOT NULL DEFAULT 0 CHECK (matches_played >= 0),
  goals integer NOT NULL DEFAULT 0 CHECK (goals >= 0),
  assists integer NOT NULL DEFAULT 0 CHECK (assists >= 0),
  yellow_cards integer NOT NULL DEFAULT 0 CHECK (yellow_cards >= 0),
  red_cards integer NOT NULL DEFAULT 0 CHECK (red_cards >= 0),
  pending_suspension_matches integer NOT NULL DEFAULT 0 CHECK (pending_suspension_matches >= 0),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (player_id, tournament_team_id)
);

CREATE INDEX IF NOT EXISTS idx_player_trackings_player_id
  ON vifutboldev.player_internal_trackings (player_id);
CREATE INDEX IF NOT EXISTS idx_player_trackings_tournament_team_id
  ON vifutboldev.player_internal_trackings (tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_player_trackings_tournament_id
  ON vifutboldev.player_internal_trackings (tournament_id);
CREATE INDEX IF NOT EXISTS idx_player_trackings_coach_id
  ON vifutboldev.player_internal_trackings (coach_id);

-- 12. match_referees (MatchReferee)
CREATE TABLE IF NOT EXISTS vifutboldev.match_referees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_account_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  full_name text NOT NULL CHECK (char_length(trim(full_name)) >= 3),
  certification_level text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_match_referees_user_account_id
  ON vifutboldev.match_referees (user_account_id);
CREATE INDEX IF NOT EXISTS idx_match_referees_is_active
  ON vifutboldev.match_referees (is_active);

-- 13. matches (ChampionshipMatch)
CREATE TABLE IF NOT EXISTS vifutboldev.matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  round_number integer NOT NULL CHECK (round_number >= 1),
  round_name text NOT NULL,
  home_tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  away_tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  scheduled_at timestamptz,
  scheduled_end_at timestamptz,
  venue_id uuid REFERENCES vifutboldev.sports_venues(id) ON DELETE SET NULL,
  pitch_id uuid REFERENCES vifutboldev.venue_pitches(id) ON DELETE SET NULL,
  pitch_name text,
  referee_id uuid REFERENCES vifutboldev.match_referees(id) ON DELETE SET NULL,
  referee_name text,
  status text NOT NULL DEFAULT 'pendingSchedule'
    CHECK (status IN ('pendingSchedule', 'scheduled', 'inProgress', 'completed', 'postponed', 'cancelled')),
  home_score integer CHECK (home_score IS NULL OR home_score >= 0),
  away_score integer CHECK (away_score IS NULL OR away_score >= 0),
  home_penalty_score integer CHECK (home_penalty_score IS NULL OR home_penalty_score >= 0),
  away_penalty_score integer CHECK (away_penalty_score IS NULL OR away_penalty_score >= 0),
  group_name text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (home_tournament_team_id <> away_tournament_team_id)
);

CREATE INDEX IF NOT EXISTS idx_matches_tournament_id
  ON vifutboldev.matches (tournament_id);
CREATE INDEX IF NOT EXISTS idx_matches_home_team_id
  ON vifutboldev.matches (home_tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_matches_away_team_id
  ON vifutboldev.matches (away_tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_matches_venue_id
  ON vifutboldev.matches (venue_id);
CREATE INDEX IF NOT EXISTS idx_matches_pitch_id
  ON vifutboldev.matches (pitch_id);
CREATE INDEX IF NOT EXISTS idx_matches_referee_id
  ON vifutboldev.matches (referee_id);
CREATE INDEX IF NOT EXISTS idx_matches_scheduled_at
  ON vifutboldev.matches (scheduled_at);
CREATE INDEX IF NOT EXISTS idx_matches_status
  ON vifutboldev.matches (status);

-- 14. match_lineup_convocations (MatchLineupConvocation)
CREATE TABLE IF NOT EXISTS vifutboldev.match_lineup_convocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id) ON DELETE CASCADE,
  match_id uuid REFERENCES vifutboldev.matches(id) ON DELETE SET NULL,
  match_label text NOT NULL DEFAULT 'Próximo Partido Oficial',
  starter_player_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  substitute_player_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  captain_player_id uuid REFERENCES vifutboldev.players(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'confirmed')),
  confirmed_starter_player_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  confirmed_substitute_player_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  confirmed_captain_player_id uuid REFERENCES vifutboldev.players(id) ON DELETE SET NULL,
  confirmed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_convocations_tournament_id
  ON vifutboldev.match_lineup_convocations (tournament_id);
CREATE INDEX IF NOT EXISTS idx_convocations_tournament_team_id
  ON vifutboldev.match_lineup_convocations (tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_convocations_match_id
  ON vifutboldev.match_lineup_convocations (match_id);
CREATE INDEX IF NOT EXISTS idx_convocations_captain_player_id
  ON vifutboldev.match_lineup_convocations (captain_player_id);
CREATE INDEX IF NOT EXISTS idx_convocations_confirmed_captain_player_id
  ON vifutboldev.match_lineup_convocations (confirmed_captain_player_id);

-- 15. digital_match_reports (DigitalMatchReport)
CREATE TABLE IF NOT EXISTS vifutboldev.digital_match_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL UNIQUE REFERENCES vifutboldev.matches(id) ON DELETE CASCADE,
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  home_tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  away_tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  home_score integer NOT NULL DEFAULT 0 CHECK (home_score >= 0),
  away_score integer NOT NULL DEFAULT 0 CHECK (away_score >= 0),
  home_penalty_score integer CHECK (home_penalty_score IS NULL OR home_penalty_score >= 0),
  away_penalty_score integer CHECK (away_penalty_score IS NULL OR away_penalty_score >= 0),
  current_period text NOT NULL DEFAULT 'notStarted'
    CHECK (current_period IN ('notStarted', 'firstHalf', 'halftime', 'secondHalf', 'extraTime', 'penalties', 'closed')),
  period_started_at timestamptz,
  elapsed_seconds_before_current_period integer NOT NULL DEFAULT 0
    CHECK (elapsed_seconds_before_current_period >= 0),
  closed_at timestamptz,
  closed_by_user_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE SET NULL,
  observations text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (home_tournament_team_id <> away_tournament_team_id)
);

CREATE INDEX IF NOT EXISTS idx_digital_match_reports_tournament_id
  ON vifutboldev.digital_match_reports (tournament_id);
CREATE INDEX IF NOT EXISTS idx_digital_match_reports_home_team_id
  ON vifutboldev.digital_match_reports (home_tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_digital_match_reports_away_team_id
  ON vifutboldev.digital_match_reports (away_tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_digital_match_reports_closed_by_user_id
  ON vifutboldev.digital_match_reports (closed_by_user_id);

-- 16. match_events (MatchEvent)
CREATE TABLE IF NOT EXISTS vifutboldev.match_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL REFERENCES vifutboldev.digital_match_reports(id) ON DELETE CASCADE,
  match_id uuid NOT NULL REFERENCES vifutboldev.matches(id) ON DELETE CASCADE,
  event_type text NOT NULL
    CHECK (event_type IN ('goal', 'assist', 'yellowCard', 'redCard', 'substitution')),
  minute integer NOT NULL CHECK (minute BETWEEN 1 AND 130),
  tournament_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  primary_player_id uuid REFERENCES vifutboldev.players(id) ON DELETE SET NULL,
  primary_player_name text,
  primary_player_shirt_number integer,
  secondary_player_id uuid REFERENCES vifutboldev.players(id) ON DELETE SET NULL,
  secondary_player_name text,
  secondary_player_shirt_number integer,
  linked_parent_event_id uuid REFERENCES vifutboldev.match_events(id) ON DELETE SET NULL,
  description text,
  is_synced boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_match_events_report_id
  ON vifutboldev.match_events (report_id);
CREATE INDEX IF NOT EXISTS idx_match_events_match_id
  ON vifutboldev.match_events (match_id);
CREATE INDEX IF NOT EXISTS idx_match_events_tournament_team_id
  ON vifutboldev.match_events (tournament_team_id);
CREATE INDEX IF NOT EXISTS idx_match_events_primary_player_id
  ON vifutboldev.match_events (primary_player_id);
CREATE INDEX IF NOT EXISTS idx_match_events_secondary_player_id
  ON vifutboldev.match_events (secondary_player_id);
CREATE INDEX IF NOT EXISTS idx_match_events_linked_parent_event_id
  ON vifutboldev.match_events (linked_parent_event_id);

-- 17. match_live_alerts (MatchLiveAlert)
CREATE TABLE IF NOT EXISTS vifutboldev.match_live_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL REFERENCES vifutboldev.matches(id) ON DELETE CASCADE,
  tournament_id uuid NOT NULL REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  alert_type text NOT NULL
    CHECK (alert_type IN ('kickoff', 'goal', 'fullTime', 'rescheduling')),
  title text NOT NULL,
  message text NOT NULL,
  alert_timestamp timestamptz NOT NULL DEFAULT timezone('utc', now()),
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_match_live_alerts_match_id
  ON vifutboldev.match_live_alerts (match_id);
CREATE INDEX IF NOT EXISTS idx_match_live_alerts_tournament_id
  ON vifutboldev.match_live_alerts (tournament_id);
CREATE INDEX IF NOT EXISTS idx_match_live_alerts_timestamp
  ON vifutboldev.match_live_alerts (alert_timestamp DESC);

-- 18. season_honor_rolls (SeasonHonorRoll)
CREATE TABLE IF NOT EXISTS vifutboldev.season_honor_rolls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id uuid NOT NULL UNIQUE REFERENCES vifutboldev.tournaments(id) ON DELETE CASCADE,
  tournament_name text NOT NULL,
  closed_at timestamptz NOT NULL,
  champion_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  champion_team_name text NOT NULL,
  champion_short_code text NOT NULL,
  runner_up_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  runner_up_team_name text NOT NULL,
  runner_up_short_code text NOT NULL,
  top_scorer_player_id uuid REFERENCES vifutboldev.players(id) ON DELETE SET NULL,
  top_scorer_player_name text,
  top_scorer_team_name text,
  top_scorer_goals integer NOT NULL DEFAULT 0 CHECK (top_scorer_goals >= 0),
  best_defense_team_id uuid NOT NULL REFERENCES vifutboldev.tournament_teams(id),
  best_defense_team_name text NOT NULL,
  best_defense_short_code text NOT NULL,
  best_defense_goals_against integer NOT NULL CHECK (best_defense_goals_against >= 0),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CHECK (champion_team_id <> runner_up_team_id)
);

CREATE INDEX IF NOT EXISTS idx_season_honor_rolls_champion_team_id
  ON vifutboldev.season_honor_rolls (champion_team_id);
CREATE INDEX IF NOT EXISTS idx_season_honor_rolls_runner_up_team_id
  ON vifutboldev.season_honor_rolls (runner_up_team_id);
CREATE INDEX IF NOT EXISTS idx_season_honor_rolls_top_scorer_player_id
  ON vifutboldev.season_honor_rolls (top_scorer_player_id);
CREATE INDEX IF NOT EXISTS idx_season_honor_rolls_best_defense_team_id
  ON vifutboldev.season_honor_rolls (best_defense_team_id);

-- Idempotent updated_at triggers across all 18 tables
DO $$
DECLARE
  v_table text;
  v_tables text[] := ARRAY[
    'user_accounts',
    'sports_venues',
    'venue_pitches',
    'tournaments',
    'rule_audit_entries',
    'tournament_news',
    'teams',
    'tournament_teams',
    'fan_favorite_teams',
    'players',
    'player_internal_trackings',
    'match_referees',
    'matches',
    'match_lineup_convocations',
    'digital_match_reports',
    'match_events',
    'match_live_alerts',
    'season_honor_rolls'
  ];
BEGIN
  FOREACH v_table IN ARRAY v_tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%I_updated_at ON vifutboldev.%I;',
      v_table,
      v_table
    );
    EXECUTE format(
      'CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON vifutboldev.%I FOR EACH ROW EXECUTE FUNCTION vifutboldev.set_updated_at();',
      v_table,
      v_table
    );
  END LOOP;
END;
$$;
