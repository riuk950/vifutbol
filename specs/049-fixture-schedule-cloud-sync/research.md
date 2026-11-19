# Research & Technical Decisions: Fixture Generation, Match Scheduling Cloud Sync, and Daily Matches Visibility

**Feature**: `049-fixture-schedule-cloud-sync` (HU 22.1)
**Date**: 2026-11-19

## 1. Root-Cause Audit of Existing Codebase & Cloud Schema

An audit of `vifutboldev.matches` in Supabase DEV and the Flutter codebase (`lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart`, `lib/application/controllers/matches_catalog_controller.dart`, `lib/application/controllers/daily_matches_feed_controller.dart`, `lib/presentation/shell/tabs/matchday_tab_view.dart`, `lib/presentation/matches/widgets/schedule_match_dialog.dart`, `lib/domain/services/round_robin_generator.dart`) revealed five concrete gaps:

1. **Missing Remote Pruning on Fixture Replacement (`replaceMatchesForTournament`)**:
   - `HybridTournamentMatchesRepository.replaceMatchesForTournament` and `replayOutboxItem` (`SyncOutboxOperation.replaceBatch`) currently only call `remote.upsertBatch(matches)`. They never delete stale remote rows in `vifutboldev.matches` belonging to the tournament when a fixture is regenerated or cleared.
   - **Decision**: Add `replaceForTournament(String tournamentId, List<ChampionshipMatch> matches)` to `TournamentMatchesRemoteDataSource` (`PostgrestTournamentMatchesRemoteDataSource`). It prunes stale rows for `tournament_id = safeTournamentId` whose `id` is not in the incoming batch (or deletes all rows for the tournament when `matches` is empty) and then executes `upsert(..., onConflict: 'id')` for the incoming batch.
   - **Rationale**: Ensures clean replacement upon regeneration (Clarification Q1 / FR-002a) while remaining 100% idempotent on outbox retries and partial network interruptions.
   - **Alternatives considered**: Deleting all rows unconditionally before inserting — rejected because a network drop between `delete` and `insert` could temporarily wipe remote matches before retry; pruning only IDs not in the new batch + upserting the new batch is safer and idempotent.

2. **Non-UUID Local Match IDs vs. Remote UUIDs**:
   - `RoundRobinGenerator` generates human-readable IDs (`match-$tournamentId-r$round-$counter`), whereas `PostgrestTournamentMatchesRemoteDataSource._toRow` converts them to deterministic UUIDv5 via `HybridRepositorySupport.ensureUuid(m.id, 'match')`. This causes local Hive IDs to diverge from Supabase UUIDs until a remote reload occurs, risking duplicate or unmatched records when scheduling immediately after generating.
   - **Decision**: Normalize generated match IDs to deterministic UUIDv5 via `HybridRepositorySupport.ensureUuid` (or a pure deterministic UUIDv5 helper in domain/repository) when persisting/replacing fixtures so local Hive IDs and `vifutboldev.matches.id` are always identical 1:1.
   - **Rationale**: Eliminates local/remote ID drift, guarantees idempotency across offline outbox replays, and avoids duplicate entries in `LocalTournamentMatchesRepository` when hydrating from Supabase.
   - **Alternatives considered**: Keeping string IDs locally and translating only at the PostgREST boundary — rejected because `scheduleMatch` and `loadMatchesForTournament` compare `match.id` directly against remote rows.

3. **`DailyMatchesFeedController` & `MatchdayTabView` Not Hydrating Cloud Matches**:
   - `MatchesCatalogController` lacks a `loadAllMatches()` method, and `loadTournamentMatches(tournamentId)` replaces `state.matches` with only a single tournament's matches.
   - `MatchdayTabView._initData()` and `RefreshIndicator.onRefresh` never invoke `loadAllMatches()`, and `DailyMatchesFeedController` never listens to `matchesCatalogControllerProvider` or `tournamentsControllerProvider`, nor triggers background cloud refresh on tab focus or date selection.
   - **Decision**:
     - Add `loadAllMatches({bool silent = false})` to `MatchesCatalogController` that calls `matchesRepository.loadAllMatches()` (which is cache-first + remote sync via `HybridTournamentMatchesRepository`) without wiping multi-tournament state, and merge tournament-scoped updates in `loadTournamentMatches` rather than discarding other tournaments' matches.
     - Update `DailyMatchesFeedController` to: (a) reactively subscribe (`ref.listen`) to `matchesCatalogControllerProvider` and `tournamentsControllerProvider` so the daily feed automatically recomputes whenever cloud data arrives; (b) expose an async `refreshFromCloud({bool showLoading = false})` method that renders cached matches immediately and fetches fresh tournaments, teams, and matches from Supabase in parallel; (c) invoke `refreshFromCloud()` on tab initialization/return, on `selectQuickTab` / `selectCustomDate`, and on pull-to-refresh.
   - **Rationale**: Directly fulfills Clarification Q3 (FR-010) and SC-002/SC-005 while keeping mobile UI instantaneous and battery-friendly.
   - **Alternatives considered**: Supabase Realtime Postgres Changes subscription — rejected per Clarification Q3 due to battery/network overhead and unnecessary complexity for organizer-authored schedules.

4. **Optional Venue, Pitch, and Referee During Match Scheduling**:
   - `FixtureSchedulingUseCase.scheduleMatch`, `MatchesCatalogController.scheduleMatch`, and `ScheduleMatchDialog` currently require non-null `venue`, `pitch`, and `referee`.
   - **Decision**: Make `venue`, `pitch`, and `referee` nullable (`SportsVenue?`, `VenuePitch?`, `MatchReferee?`) across `FixtureSchedulingUseCase.scheduleMatch`, `MatchesCatalogController.scheduleMatch`, and `ScheduleMatchDialog`. Only `scheduledStartTime` (date & time, not in the past) is mandatory. Update `detectCollisions` to skip pitch collision checks when `pitchId == null` and skip referee collision checks when `refereeId == null`, while always checking home/away team collisions. Render localized `"Por definir"` fallbacks on match cards when optional fields are null.
   - **Rationale**: Directly fulfills Clarification Q2 (FR-004, FR-008) and aligns with `vifutboldev.matches` where `venue_id`, `pitch_id`, `pitch_name`, `referee_id`, and `referee_name` are already nullable columns.
   - **Alternatives considered**: Requiring all logistics upfront — rejected by user in Clarification Q2.

5. **Database Schema & RLS Verification (`vifutboldev.matches`)**:
   - Live inspection of `vifutboldev.matches` on Oracle Cloud DEV confirmed all required columns exist and match `PostgrestTournamentMatchesRemoteDataSource._toRow`/`_fromRow`:
     - `id` (uuid PK), `tournament_id` (uuid FK -> `tournaments`), `round_number` (int >= 1), `round_name` (text), `home_tournament_team_id` (uuid FK -> `tournament_teams`), `away_tournament_team_id` (uuid FK -> `tournament_teams`), `scheduled_at` (timestamptz, nullable), `scheduled_end_at` (timestamptz, nullable), `venue_id` (uuid FK -> `sports_venues`, nullable), `pitch_id` (uuid FK -> `venue_pitches`, nullable), `pitch_name` (text, nullable), `referee_id` (uuid FK -> `match_referees`, nullable), `referee_name` (text, nullable), `status` (text CHECK `pendingSchedule|scheduled|inProgress|completed|postponed|cancelled`), `home_score`, `away_score`, `home_penalty_score`, `away_penalty_score`, `group_name`, `created_at`, `updated_at`.
   - RLS policies are already active: `matches_select_public` (anon/authenticated SELECT), `matches_insert_organizer`, `matches_update_organizer_or_referee`, `matches_delete_organizer`.
   - **Decision**: No destructive schema migration is needed for `vifutboldev.matches`. All columns, constraints, indexes (`idx_matches_scheduled_at`, `idx_matches_tournament_id`), and RLS policies already support HU 22.1.
   - **Rationale**: Minimizes risk and keeps DEV database schema clean.

6. **Duplicate-Tap Prevention & Regeneration Confirmation UX**:
   - **Decision**: Guard `ScheduleMatchDialog._submit()` and the Competition Detail `"Generar Fixture"` action with `isSaving` / local submitting state so repeated taps cannot trigger duplicate mutations. When a competition already has matches (and none are `inProgress` or `completed`), prompt the organizer with a localized confirmation dialog before calling `generateFixture`.
   - **Rationale**: Satisfies `FR-002a`, `FR-012`, and `docs/MOBILE_GUIDELINES.md`.
