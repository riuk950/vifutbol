---

description: "Task list for HU 17.2: Creación y Aprovisionamiento del Esquema vifutboldev en Supabase Self-Hosted (SSH / Docker)"
---

# Tasks: Creación y Aprovisionamiento del Esquema `vifutboldev` en Backend DEV (HU 17.2)

**Input**: Design documents from `/specs/036-supabase-vifutboldev-schema/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/vifutboldev-schema-contracts.md`, `quickstart.md`

**Tests**: Automated Dart/Flutter unit tests (TDD per Constitution Principle III) plus idempotent PostgreSQL DDL/RLS checks and DEV REST/GoTrue E2E verification.

**Organization**: Tasks are grouped by user story (`US1`–`US4`) so each layer can be implemented, executed, and validated incrementally.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`US1`, `US2`, `US3`, `US4`)
- Every task includes exact file paths

---

## Phase 1: Setup (Migrations Directory & Environment Templates)

**Purpose**: Establish versioned SQL migration structure and document the `SUPABASE_SCHEMA` environment variable without exposing secrets.

- [X] T001 Create `supabase/migrations/` directory structure and document `SUPABASE_SCHEMA=vifutboldev` in .env.dev.example and .env.example

---

## Phase 2: User Story 1 - Aislamiento e Idempotencia del Esquema Relacional `vifutboldev` (Priority: P1) 🎯 MVP

**Goal**: Create the isolated `vifutboldev` PostgreSQL schema, `updated_at` trigger function, cached `SECURITY DEFINER` role helper, and schema-level grants cleanly separated from `public`.

**Independent Test**: Apply `202611110001_create_vifutboldev_schema.sql` twice consecutively via SSH against `supabase-db` (`supabase_admin`), confirming `vifutboldev` exists, zero new objects exist in `public`, and `GRANT USAGE` is applied for `anon`, `authenticated`, and `service_role`.

- [X] T002 [US1] Author idempotent schema bootstrap migration (`CREATE SCHEMA IF NOT EXISTS vifutboldev`, `pgcrypto`, `vifutboldev.set_updated_at()`, `SECURITY DEFINER` helper `vifutboldev.current_user_has_role(text[])` with `SET search_path = ''`, and schema `GRANT USAGE` to `anon`, `authenticated`, `service_role`) in supabase/migrations/202611110001_create_vifutboldev_schema.sql (depends on T001)
- [X] T003 [US1] Execute `supabase/migrations/202611110001_create_vifutboldev_schema.sql` against DEV `supabase-db` (`ubuntu@157.137.227.250`) and re-run a second time to verify idempotency and zero changes in `public`

---

## Phase 3: User Story 2 - Modelo Relacional Completo de Entidades Deportivas (Priority: P1) 🎯 MVP

**Goal**: Provision all 18 domain tables under `vifutboldev.*` (`user_accounts`, `fan_favorite_teams`, `sports_venues`, `venue_pitches`, `tournaments`, `rule_audit_entries`, `season_honor_rolls`, `tournament_news`, `teams`, `tournament_teams`, `players`, `player_internal_trackings`, `match_referees`, `matches`, `match_lineup_convocations`, `digital_match_reports`, `match_events`, `match_live_alerts`), FK constraints, normalized `tournament_team_id` linkage, B-Tree indexes, and DEV seed data.

**Independent Test**: Run `202611110002_create_vifutboldev_tables_and_indexes.sql` and `202611110004_seed_vifutboldev_dev_data.sql` twice consecutively on DEV `supabase-db`, verifying 18 tables in `vifutboldev`, all FKs indexed, all constraints active, and deterministic DEV seed records present without duplication.

- [X] T004 [US2] Author idempotent DDL migration defining all 18 `vifutboldev.*` tables (`id uuid PRIMARY KEY DEFAULT gen_random_uuid()`, `created_at`/`updated_at` `timestamptz`, `teams` + `tournament_teams` + `tournament_team_id` linkage, `UNIQUE`/`CHECK` constraints, B-Tree indexes on every FK and hot filter column, and idempotent `BEFORE UPDATE` triggers) in supabase/migrations/202611110002_create_vifutboldev_tables_and_indexes.sql (depends on T002)
- [X] T005 [P] [US2] Author idempotent DEV seed script (`INSERT ... ON CONFLICT DO NOTHING` for organizer/coach/referee `user_accounts`, `sports_venues`, `venue_pitches`, `tournaments`, `teams`, `tournament_teams`, `match_referees`, `tournament_news`) in supabase/migrations/202611110004_seed_vifutboldev_dev_data.sql (depends on T004)
- [X] T006 [US2] Execute `supabase/migrations/202611110002_create_vifutboldev_tables_and_indexes.sql` and `supabase/migrations/202611110004_seed_vifutboldev_dev_data.sql` twice consecutively on DEV `supabase-db` and assert 18 tables, FK indexes, and zero errors (depends on T003, T004, T005)

---

## Phase 4: User Story 3 - Seguridad de Acceso por Roles (RLS) (Priority: P2)

**Goal**: Enforce least-privilege table grants, default privileges, and strict Row-Level Security policies across all 18 `vifutboldev` tables aligned with the 5 system roles (`organizer`, `coach`, `referee`, `player`, `fan`) and `(select auth.uid())` caching.

**Independent Test**: Apply `202611110003_enable_rls_and_policies.sql` twice consecutively on DEV `supabase-db`, confirm `pg_tables` reports `rowsecurity = true` (`0` missing RLS) across all 18 tables, and verify via `psql` role impersonation (`SET LOCAL ROLE anon` vs `authenticated`) that private tables reject `anon` and unauthorized writes fail.

- [X] T007 [US3] Author idempotent RLS & privileges migration (`GRANT`s, `ALTER DEFAULT PRIVILEGES`, `ENABLE ROW LEVEL SECURITY` on all 18 tables, and `DROP POLICY IF EXISTS` + `CREATE POLICY` enforcing role/ownership rules with `(select auth.uid())` and `(select vifutboldev.current_user_has_role(...))`) in supabase/migrations/202611110003_enable_rls_and_policies.sql (depends on T004)
- [X] T008 [US3] Execute `supabase/migrations/202611110003_enable_rls_and_policies.sql` twice consecutively on DEV `supabase-db` and run SQL verification confirming `rowsecurity = true` on all 18 tables and RLS enforcement for `anon` vs `authenticated` (depends on T006, T007)

---

## Phase 5: User Story 4 - Exposición de API en DEV, Vinculación del Cliente y Prueba End-to-End (Priority: P2)

**Goal**: Expose `vifutboldev` in PostgREST (`PGRST_DB_SCHEMAS`) on Oracle Cloud DEV without weakening Kong's OpenAPI protection, configure Flutter DEV client (`SupabaseConfig.schema`, `PostgrestClientOptions`, `SupabaseHealthClient`), and validate live DEV public read (`HTTP 200`) plus authenticated write+cleanup E2E.

**Independent Test**: Update tests first (`supabase_providers_test.dart`, `check_supabase_backend_health_use_case_test.dart`), update Flutter config/bootstrap/health client to target `vifutboldev` in DEV, expose `vifutboldev` on `supabase-rest`, confirm `GET /rest/v1/tournaments?select=id&limit=1` (`Accept-Profile: vifutboldev`) returns `200 OK`, and validate an authenticated GoTrue write+read+delete cycle on `vifutboldev`.

### Tests for User Story 4 (TDD First)

- [X] T009 [P] [US4] Add unit tests verifying `SupabaseConfig.schema` (`'vifutboldev'` in `EnvironmentConfig.development()`, `'public'` in `EnvironmentConfig.production()`, `toSafeDiagnosticMap()`, equality) in test/unit/application/supabase_providers_test.dart
- [X] T010 [P] [US4] Extend unit tests verifying `SupabaseHealthClient.checkHealth` probes `/rest/v1/` when `schema == 'public'` and `/rest/v1/tournaments?select=id&limit=1` with `Accept-Profile: vifutboldev` and `Authorization: Bearer ...` when `schema == 'vifutboldev'` in test/unit/application/check_supabase_backend_health_use_case_test.dart

### Server Exposure & Flutter Client Implementation

- [X] T011 [US4] Add `schema` field (`String schema = 'public'`) to `SupabaseConfig`, default `'vifutboldev'` in `EnvironmentConfig.development()` and `'public'` in `EnvironmentConfig.production()` with `SUPABASE_SCHEMA` env override in lib/domain/entities/app_environment.dart (depends on T009)
- [X] T012 [US4] Configure `postgrestOptions: PostgrestClientOptions(schema: config.supabase.schema)` inside `Supabase.initialize` in lib/app_bootstrap.dart (depends on T011)
- [X] T013 [US4] Update `SupabaseHealthClient.checkHealth` to probe `/rest/v1/tournaments?select=id&limit=1` with `Accept-Profile` and `Authorization` headers whenever `config.schema != 'public'` while keeping `/rest/v1/` backward compatibility for `'public'` in lib/infrastructure/network/supabase_health_client.dart (depends on T010, T011)
- [X] T014 [US4] Append `,vifutboldev` to `PGRST_DB_SCHEMAS` in `/home/ubuntu/supabase/docker/.env` via SSH on `ubuntu@157.137.227.250`, restart `supabase-rest` (`docker compose up -d rest`), and verify `supabase-meta` / Studio sees `vifutboldev` (depends on T008)
- [X] T015 [US4] Validate live REST public read (`GET https://supabase.artbusinesstechnology.com/rest/v1/tournaments?select=id,name&limit=5` with `Accept-Profile: vifutboldev` -> `200 OK`) and authenticated GoTrue write+read+cleanup cycle against `vifutboldev` (without modifying `public` or `.env.prod`) (depends on T013, T014)

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Run final formatting, static analysis, and unit/resilience test suite across all modified Flutter code.

- [X] T016 [P] Run `dart format --output=none --set-exit-if-changed lib/ test/` and `flutter analyze` verifying zero issues
- [X] T017 Execute `flutter test test/unit/application/supabase_providers_test.dart test/unit/application/check_supabase_backend_health_use_case_test.dart test/unit/application/supabase_bootstrap_resilience_test.dart` verifying 100% pass rate (depends on T016)

---

## Dependencies & Execution Order

- **Phase 1 (`T001`)**: Starts immediately.
- **Phase 2 (`US1`, `T002`–`T003`)**: Depends on `T001`.
- **Phase 3 (`US2`, `T004`–`T006`)**: Depends on `T002`/`T003` (`T005` seed file can be drafted in parallel once `T004` table contracts are fixed).
- **Phase 4 (`US3`, `T007`–`T008`)**: Depends on `T004`/`T006`.
- **Phase 5 (`US4`, `T009`–`T015`)**: Flutter TDD tests (`T009`, `T010`) and client updates (`T011`–`T013`) can execute in parallel with Phases 2–4; server exposure (`T014`) depends on `T008`; live E2E verification (`T015`) depends on `T013` and `T014`.
- **Phase 6 (`T016`–`T017`)**: Depends on all code tasks complete.

## Parallel Opportunities

- `T009` (`supabase_providers_test.dart`) and `T010` (`check_supabase_backend_health_use_case_test.dart`) can run in parallel with SQL authoring (`T002`, `T004`, `T007`).
- Within Flutter implementation, `T012` (`app_bootstrap.dart`) and `T013` (`supabase_health_client.dart`) modify separate files and can run in parallel once `T011` (`app_environment.dart`) completes.

## Implementation Strategy

- **MVP**: Complete `Phase 1` + `Phase 2 (US1)` + `Phase 3 (US2)` to have the isolated `vifutboldev` schema, all 18 tables, indexes, and DEV seed live in PostgreSQL.
- **Full Delivery**: Complete `Phase 4 (US3)` for strict role-based RLS, `Phase 5 (US4)` for PostgREST exposure + Flutter DEV client + live read/write E2E check, and `Phase 6` for static & unit gates.
