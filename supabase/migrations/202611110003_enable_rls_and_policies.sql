-- =============================================================================
-- HU 17.2 - Migration 0003: Least-privilege grants, default privileges & RLS
-- Target schema: vifutboldev
-- Idempotent: safe to run repeatedly
-- =============================================================================

-- 1. Revoke broad defaults and enforce least-privilege grants
REVOKE ALL ON ALL TABLES IN SCHEMA vifutboldev FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA vifutboldev
  REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated;

GRANT ALL ON ALL TABLES IN SCHEMA vifutboldev TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vifutboldev
  GRANT ALL ON TABLES TO service_role;

-- Public-read sports tables allow SELECT for anon & authenticated
GRANT SELECT ON
  vifutboldev.sports_venues,
  vifutboldev.venue_pitches,
  vifutboldev.tournaments,
  vifutboldev.rule_audit_entries,
  vifutboldev.season_honor_rolls,
  vifutboldev.tournament_news,
  vifutboldev.teams,
  vifutboldev.tournament_teams,
  vifutboldev.players,
  vifutboldev.match_referees,
  vifutboldev.matches,
  vifutboldev.digital_match_reports,
  vifutboldev.match_events,
  vifutboldev.match_live_alerts
TO anon, authenticated;

-- Private tables have ZERO privileges for anon
GRANT SELECT, INSERT, UPDATE, DELETE ON
  vifutboldev.user_accounts,
  vifutboldev.fan_favorite_teams,
  vifutboldev.player_internal_trackings,
  vifutboldev.match_lineup_convocations
TO authenticated;

-- Write privileges for authenticated (strictly gated by RLS below)
GRANT INSERT, UPDATE, DELETE ON
  vifutboldev.sports_venues,
  vifutboldev.venue_pitches,
  vifutboldev.tournaments,
  vifutboldev.rule_audit_entries,
  vifutboldev.season_honor_rolls,
  vifutboldev.tournament_news,
  vifutboldev.teams,
  vifutboldev.tournament_teams,
  vifutboldev.players,
  vifutboldev.match_referees,
  vifutboldev.matches,
  vifutboldev.digital_match_reports,
  vifutboldev.match_events,
  vifutboldev.match_live_alerts
TO authenticated;

-- 2. Enable Row-Level Security on ALL 18 tables
ALTER TABLE vifutboldev.user_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.fan_favorite_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.sports_venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.venue_pitches ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.rule_audit_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.season_honor_rolls ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.tournament_news ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.tournament_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.player_internal_trackings ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.match_referees ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.match_lineup_convocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.digital_match_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.match_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE vifutboldev.match_live_alerts ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 3. RLS Policies (1 policy per command/role, cached auth.uid() & role helpers)
-- =============================================================================

-- --- 3.1 user_accounts ---
DROP POLICY IF EXISTS user_accounts_select_own_or_organizer ON vifutboldev.user_accounts;
CREATE POLICY user_accounts_select_own_or_organizer
  ON vifutboldev.user_accounts
  FOR SELECT
  TO authenticated
  USING (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  );

DROP POLICY IF EXISTS user_accounts_insert_own_or_organizer ON vifutboldev.user_accounts;
CREATE POLICY user_accounts_insert_own_or_organizer
  ON vifutboldev.user_accounts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  );

DROP POLICY IF EXISTS user_accounts_update_own_or_organizer ON vifutboldev.user_accounts;
CREATE POLICY user_accounts_update_own_or_organizer
  ON vifutboldev.user_accounts
  FOR UPDATE
  TO authenticated
  USING (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  )
  WITH CHECK (
    auth_user_id = (SELECT auth.uid())
    OR (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
  );

DROP POLICY IF EXISTS user_accounts_delete_organizer_only ON vifutboldev.user_accounts;
CREATE POLICY user_accounts_delete_organizer_only
  ON vifutboldev.user_accounts
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.2 fan_favorite_teams ---
DROP POLICY IF EXISTS fan_favorite_teams_select_owner ON vifutboldev.fan_favorite_teams;
CREATE POLICY fan_favorite_teams_select_owner
  ON vifutboldev.fan_favorite_teams
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT vifutboldev.current_user_account_id()));

DROP POLICY IF EXISTS fan_favorite_teams_insert_owner ON vifutboldev.fan_favorite_teams;
CREATE POLICY fan_favorite_teams_insert_owner
  ON vifutboldev.fan_favorite_teams
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT vifutboldev.current_user_account_id()));

DROP POLICY IF EXISTS fan_favorite_teams_update_owner ON vifutboldev.fan_favorite_teams;
CREATE POLICY fan_favorite_teams_update_owner
  ON vifutboldev.fan_favorite_teams
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT vifutboldev.current_user_account_id()))
  WITH CHECK (user_id = (SELECT vifutboldev.current_user_account_id()));

DROP POLICY IF EXISTS fan_favorite_teams_delete_owner ON vifutboldev.fan_favorite_teams;
CREATE POLICY fan_favorite_teams_delete_owner
  ON vifutboldev.fan_favorite_teams
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT vifutboldev.current_user_account_id()));

-- --- 3.3 sports_venues ---
DROP POLICY IF EXISTS sports_venues_select_public ON vifutboldev.sports_venues;
CREATE POLICY sports_venues_select_public
  ON vifutboldev.sports_venues
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS sports_venues_insert_organizer ON vifutboldev.sports_venues;
CREATE POLICY sports_venues_insert_organizer
  ON vifutboldev.sports_venues
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS sports_venues_update_organizer ON vifutboldev.sports_venues;
CREATE POLICY sports_venues_update_organizer
  ON vifutboldev.sports_venues
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS sports_venues_delete_organizer ON vifutboldev.sports_venues;
CREATE POLICY sports_venues_delete_organizer
  ON vifutboldev.sports_venues
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.4 venue_pitches ---
DROP POLICY IF EXISTS venue_pitches_select_public ON vifutboldev.venue_pitches;
CREATE POLICY venue_pitches_select_public
  ON vifutboldev.venue_pitches
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS venue_pitches_insert_organizer ON vifutboldev.venue_pitches;
CREATE POLICY venue_pitches_insert_organizer
  ON vifutboldev.venue_pitches
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS venue_pitches_update_organizer ON vifutboldev.venue_pitches;
CREATE POLICY venue_pitches_update_organizer
  ON vifutboldev.venue_pitches
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS venue_pitches_delete_organizer ON vifutboldev.venue_pitches;
CREATE POLICY venue_pitches_delete_organizer
  ON vifutboldev.venue_pitches
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.5 tournaments ---
DROP POLICY IF EXISTS tournaments_select_public ON vifutboldev.tournaments;
CREATE POLICY tournaments_select_public
  ON vifutboldev.tournaments
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS tournaments_insert_organizer ON vifutboldev.tournaments;
CREATE POLICY tournaments_insert_organizer
  ON vifutboldev.tournaments
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS tournaments_update_organizer ON vifutboldev.tournaments;
CREATE POLICY tournaments_update_organizer
  ON vifutboldev.tournaments
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS tournaments_delete_organizer ON vifutboldev.tournaments;
CREATE POLICY tournaments_delete_organizer
  ON vifutboldev.tournaments
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.6 rule_audit_entries ---
DROP POLICY IF EXISTS rule_audit_entries_select_public ON vifutboldev.rule_audit_entries;
CREATE POLICY rule_audit_entries_select_public
  ON vifutboldev.rule_audit_entries
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS rule_audit_entries_insert_organizer ON vifutboldev.rule_audit_entries;
CREATE POLICY rule_audit_entries_insert_organizer
  ON vifutboldev.rule_audit_entries
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS rule_audit_entries_update_organizer ON vifutboldev.rule_audit_entries;
CREATE POLICY rule_audit_entries_update_organizer
  ON vifutboldev.rule_audit_entries
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS rule_audit_entries_delete_organizer ON vifutboldev.rule_audit_entries;
CREATE POLICY rule_audit_entries_delete_organizer
  ON vifutboldev.rule_audit_entries
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.7 season_honor_rolls ---
DROP POLICY IF EXISTS season_honor_rolls_select_public ON vifutboldev.season_honor_rolls;
CREATE POLICY season_honor_rolls_select_public
  ON vifutboldev.season_honor_rolls
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS season_honor_rolls_insert_organizer ON vifutboldev.season_honor_rolls;
CREATE POLICY season_honor_rolls_insert_organizer
  ON vifutboldev.season_honor_rolls
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS season_honor_rolls_update_organizer ON vifutboldev.season_honor_rolls;
CREATE POLICY season_honor_rolls_update_organizer
  ON vifutboldev.season_honor_rolls
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS season_honor_rolls_delete_organizer ON vifutboldev.season_honor_rolls;
CREATE POLICY season_honor_rolls_delete_organizer
  ON vifutboldev.season_honor_rolls
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.8 tournament_news ---
DROP POLICY IF EXISTS tournament_news_select_public ON vifutboldev.tournament_news;
CREATE POLICY tournament_news_select_public
  ON vifutboldev.tournament_news
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS tournament_news_insert_organizer ON vifutboldev.tournament_news;
CREATE POLICY tournament_news_insert_organizer
  ON vifutboldev.tournament_news
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS tournament_news_update_organizer ON vifutboldev.tournament_news;
CREATE POLICY tournament_news_update_organizer
  ON vifutboldev.tournament_news
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS tournament_news_delete_organizer ON vifutboldev.tournament_news;
CREATE POLICY tournament_news_delete_organizer
  ON vifutboldev.tournament_news
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.9 teams ---
DROP POLICY IF EXISTS teams_select_public ON vifutboldev.teams;
CREATE POLICY teams_select_public
  ON vifutboldev.teams
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS teams_insert_coach_or_organizer ON vifutboldev.teams;
CREATE POLICY teams_insert_coach_or_organizer
  ON vifutboldev.teams
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND (coach_id = (SELECT vifutboldev.current_user_account_id()) OR coach_id IS NULL)
    )
  );

DROP POLICY IF EXISTS teams_update_coach_or_organizer ON vifutboldev.teams;
CREATE POLICY teams_update_coach_or_organizer
  ON vifutboldev.teams
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  )
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

DROP POLICY IF EXISTS teams_delete_coach_or_organizer ON vifutboldev.teams;
CREATE POLICY teams_delete_coach_or_organizer
  ON vifutboldev.teams
  FOR DELETE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

-- --- 3.10 tournament_teams ---
DROP POLICY IF EXISTS tournament_teams_select_public ON vifutboldev.tournament_teams;
CREATE POLICY tournament_teams_select_public
  ON vifutboldev.tournament_teams
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS tournament_teams_insert_organizer_or_coach ON vifutboldev.tournament_teams;
CREATE POLICY tournament_teams_insert_organizer_or_coach
  ON vifutboldev.tournament_teams
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.teams AS t
        WHERE t.id = team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournaments AS tr
        WHERE tr.id = tournament_id
          AND tr.status = 'openRegistration'
      )
    )
  );

DROP POLICY IF EXISTS tournament_teams_update_organizer_or_coach ON vifutboldev.tournament_teams;
CREATE POLICY tournament_teams_update_organizer_or_coach
  ON vifutboldev.tournament_teams
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.teams AS t
        WHERE t.id = team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournaments AS tr
        WHERE tr.id = tournament_id
          AND tr.status = 'openRegistration'
      )
    )
  )
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.teams AS t
        WHERE t.id = team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournaments AS tr
        WHERE tr.id = tournament_id
          AND tr.status = 'openRegistration'
      )
    )
  );

DROP POLICY IF EXISTS tournament_teams_delete_organizer_or_coach ON vifutboldev.tournament_teams;
CREATE POLICY tournament_teams_delete_organizer_or_coach
  ON vifutboldev.tournament_teams
  FOR DELETE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.teams AS t
        WHERE t.id = team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournaments AS tr
        WHERE tr.id = tournament_id
          AND tr.status = 'openRegistration'
      )
    )
  );

-- --- 3.11 players ---
DROP POLICY IF EXISTS players_select_public ON vifutboldev.players;
CREATE POLICY players_select_public
  ON vifutboldev.players
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS players_insert_coach_or_organizer ON vifutboldev.players;
CREATE POLICY players_insert_coach_or_organizer
  ON vifutboldev.players
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  );

DROP POLICY IF EXISTS players_update_coach_or_organizer ON vifutboldev.players;
CREATE POLICY players_update_coach_or_organizer
  ON vifutboldev.players
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  )
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  );

DROP POLICY IF EXISTS players_delete_coach_or_organizer ON vifutboldev.players;
CREATE POLICY players_delete_coach_or_organizer
  ON vifutboldev.players
  FOR DELETE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  );

-- --- 3.12 player_internal_trackings ---
DROP POLICY IF EXISTS player_trackings_select_coach_player_or_organizer ON vifutboldev.player_internal_trackings;
CREATE POLICY player_trackings_select_coach_player_or_organizer
  ON vifutboldev.player_internal_trackings
  FOR SELECT
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
    OR EXISTS (
      SELECT 1
      FROM vifutboldev.players AS p
      WHERE p.id = player_id
        AND p.user_account_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

DROP POLICY IF EXISTS player_trackings_insert_coach_or_organizer ON vifutboldev.player_internal_trackings;
CREATE POLICY player_trackings_insert_coach_or_organizer
  ON vifutboldev.player_internal_trackings
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  );

DROP POLICY IF EXISTS player_trackings_update_coach_or_organizer ON vifutboldev.player_internal_trackings;
CREATE POLICY player_trackings_update_coach_or_organizer
  ON vifutboldev.player_internal_trackings
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  )
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  );

DROP POLICY IF EXISTS player_trackings_delete_coach_or_organizer ON vifutboldev.player_internal_trackings;
CREATE POLICY player_trackings_delete_coach_or_organizer
  ON vifutboldev.player_internal_trackings
  FOR DELETE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['organizer']))
    OR (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
  );

-- --- 3.13 match_referees ---
DROP POLICY IF EXISTS match_referees_select_public ON vifutboldev.match_referees;
CREATE POLICY match_referees_select_public
  ON vifutboldev.match_referees
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS match_referees_insert_organizer ON vifutboldev.match_referees;
CREATE POLICY match_referees_insert_organizer
  ON vifutboldev.match_referees
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS match_referees_update_organizer ON vifutboldev.match_referees;
CREATE POLICY match_referees_update_organizer
  ON vifutboldev.match_referees
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS match_referees_delete_organizer ON vifutboldev.match_referees;
CREATE POLICY match_referees_delete_organizer
  ON vifutboldev.match_referees
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.14 matches ---
DROP POLICY IF EXISTS matches_select_public ON vifutboldev.matches;
CREATE POLICY matches_select_public
  ON vifutboldev.matches
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS matches_insert_organizer ON vifutboldev.matches;
CREATE POLICY matches_insert_organizer
  ON vifutboldev.matches
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

DROP POLICY IF EXISTS matches_update_organizer_or_referee ON vifutboldev.matches;
CREATE POLICY matches_update_organizer_or_referee
  ON vifutboldev.matches
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS matches_delete_organizer ON vifutboldev.matches;
CREATE POLICY matches_delete_organizer
  ON vifutboldev.matches
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer'])));

-- --- 3.15 match_lineup_convocations ---
DROP POLICY IF EXISTS convocations_select_coach_or_confirmed_official ON vifutboldev.match_lineup_convocations;
CREATE POLICY convocations_select_coach_or_confirmed_official
  ON vifutboldev.match_lineup_convocations
  FOR SELECT
  TO authenticated
  USING (
    (
      (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
      AND EXISTS (
        SELECT 1
        FROM vifutboldev.tournament_teams AS tt
        JOIN vifutboldev.teams AS t ON t.id = tt.team_id
        WHERE tt.id = tournament_team_id
          AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
      )
    )
    OR (
      status = 'confirmed'
      AND (SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee']))
    )
  );

DROP POLICY IF EXISTS convocations_insert_coach_owner ON vifutboldev.match_lineup_convocations;
CREATE POLICY convocations_insert_coach_owner
  ON vifutboldev.match_lineup_convocations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
    AND EXISTS (
      SELECT 1
      FROM vifutboldev.tournament_teams AS tt
      JOIN vifutboldev.teams AS t ON t.id = tt.team_id
      WHERE tt.id = tournament_team_id
        AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

DROP POLICY IF EXISTS convocations_update_coach_owner ON vifutboldev.match_lineup_convocations;
CREATE POLICY convocations_update_coach_owner
  ON vifutboldev.match_lineup_convocations
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
    AND EXISTS (
      SELECT 1
      FROM vifutboldev.tournament_teams AS tt
      JOIN vifutboldev.teams AS t ON t.id = tt.team_id
      WHERE tt.id = tournament_team_id
        AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  )
  WITH CHECK (
    (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
    AND EXISTS (
      SELECT 1
      FROM vifutboldev.tournament_teams AS tt
      JOIN vifutboldev.teams AS t ON t.id = tt.team_id
      WHERE tt.id = tournament_team_id
        AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

DROP POLICY IF EXISTS convocations_delete_coach_owner ON vifutboldev.match_lineup_convocations;
CREATE POLICY convocations_delete_coach_owner
  ON vifutboldev.match_lineup_convocations
  FOR DELETE
  TO authenticated
  USING (
    (SELECT vifutboldev.current_user_has_role(ARRAY['coach']))
    AND EXISTS (
      SELECT 1
      FROM vifutboldev.tournament_teams AS tt
      JOIN vifutboldev.teams AS t ON t.id = tt.team_id
      WHERE tt.id = tournament_team_id
        AND t.coach_id = (SELECT vifutboldev.current_user_account_id())
    )
  );

-- --- 3.16 digital_match_reports ---
DROP POLICY IF EXISTS digital_match_reports_select_public ON vifutboldev.digital_match_reports;
CREATE POLICY digital_match_reports_select_public
  ON vifutboldev.digital_match_reports
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS digital_match_reports_insert_referee_or_organizer ON vifutboldev.digital_match_reports;
CREATE POLICY digital_match_reports_insert_referee_or_organizer
  ON vifutboldev.digital_match_reports
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS digital_match_reports_update_referee_or_organizer ON vifutboldev.digital_match_reports;
CREATE POLICY digital_match_reports_update_referee_or_organizer
  ON vifutboldev.digital_match_reports
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS digital_match_reports_delete_referee_or_organizer ON vifutboldev.digital_match_reports;
CREATE POLICY digital_match_reports_delete_referee_or_organizer
  ON vifutboldev.digital_match_reports
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

-- --- 3.17 match_events ---
DROP POLICY IF EXISTS match_events_select_public ON vifutboldev.match_events;
CREATE POLICY match_events_select_public
  ON vifutboldev.match_events
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS match_events_insert_referee_or_organizer ON vifutboldev.match_events;
CREATE POLICY match_events_insert_referee_or_organizer
  ON vifutboldev.match_events
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS match_events_update_referee_or_organizer ON vifutboldev.match_events;
CREATE POLICY match_events_update_referee_or_organizer
  ON vifutboldev.match_events
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS match_events_delete_referee_or_organizer ON vifutboldev.match_events;
CREATE POLICY match_events_delete_referee_or_organizer
  ON vifutboldev.match_events
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

-- --- 3.18 match_live_alerts ---
DROP POLICY IF EXISTS match_live_alerts_select_public ON vifutboldev.match_live_alerts;
CREATE POLICY match_live_alerts_select_public
  ON vifutboldev.match_live_alerts
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS match_live_alerts_insert_referee_or_organizer ON vifutboldev.match_live_alerts;
CREATE POLICY match_live_alerts_insert_referee_or_organizer
  ON vifutboldev.match_live_alerts
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS match_live_alerts_update_referee_or_organizer ON vifutboldev.match_live_alerts;
CREATE POLICY match_live_alerts_update_referee_or_organizer
  ON vifutboldev.match_live_alerts
  FOR UPDATE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])))
  WITH CHECK ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));

DROP POLICY IF EXISTS match_live_alerts_delete_referee_or_organizer ON vifutboldev.match_live_alerts;
CREATE POLICY match_live_alerts_delete_referee_or_organizer
  ON vifutboldev.match_live_alerts
  FOR DELETE
  TO authenticated
  USING ((SELECT vifutboldev.current_user_has_role(ARRAY['organizer', 'referee'])));
