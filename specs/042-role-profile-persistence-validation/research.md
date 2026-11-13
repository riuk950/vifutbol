# Research: Persistencia de Roles, Perfiles Extensibles en Nube y Validación de Datos Incompletos

**Feature**: `042-role-profile-persistence-validation`  
**Date**: 2026-11-13  
**Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/042-role-profile-persistence-validation/spec.md)

## Research Decisions

### 1. Atomic Role Persistence & Document-Based Linking Strategy
- **Decision**: Implement an idempotent PostgreSQL RPC function `vifutboldev.complete_role_profile(...)` (`SECURITY DEFINER`, `SET search_path = ''`) invoked via Supabase PostgREST RPC, complemented by an updated `completeRoleOnboarding` / `saveRoleProfile` flow in `SupabaseAuthRepository` and `SupabaseUserProfileDataSource`.
- **Rationale**:
  - `completeRoleOnboarding` previously only updated `user_accounts` (`active_role`, `authorized_roles`, `onboarding_completed`), leaving role-specific tables unpopulated.
  - Linking an unlinked row in `vifutboldev.players` or `vifutboldev.match_referees` by `normalized_document_id` cannot be safely done via direct client-side `UPDATE` without opening overly broad RLS update policies on unlinked rows. Performing the lookup, conflict check (`user_account_id IS NOT NULL AND user_account_id <> v_user_account_id`), link/insert, and `user_accounts` update inside a single database transaction guarantees atomicity (FR-001) and strict security.
- **Alternatives Considered**:
  - *Multiple sequential PostgREST calls from Flutter*: Rejected because partial failure leaves `user_accounts` updated without its satellite profile or player/referee link, and requires relaxing RLS on unlinked `players` rows.

### 2. Extending `vifutboldev.players` for Free-Agent Players Without Duplication
- **Decision**: Alter `vifutboldev.players` to:
  - Allow `tournament_team_id`, `tournament_id`, `shirt_number`, and `position` to be nullable (while preserving check constraints when non-null).
  - Add `phone text` column.
  - Add partial unique index `ux_players_user_account_id` on `(user_account_id) WHERE user_account_id IS NOT NULL`.
  - Add partial unique index `ux_players_free_agent_doc` on `(normalized_document_id) WHERE tournament_id IS NULL` (and keep `UNIQUE (tournament_id, normalized_document_id)` for tournament rosters).
- **Rationale**:
  - Existing migration `202611110002_create_vifutboldev_tables_and_indexes.sql` defines `players` with `NOT NULL` on `tournament_team_id`, `tournament_id`, `shirt_number`, and `position`. A self-registered free-agent player (`team_id = NULL`) could not be inserted without relaxing those columns, while existing tournament roster constraints remain intact.
- **Alternatives Considered**:
  - *Creating a separate `player_profiles` table*: Explicitly rejected by Business Rule 1 & FR-002 ("No Duplicidad de Futbolistas: `vifutboldev.players` es la única fuente de verdad").

### 3. Extending `vifutboldev.match_referees` and `vifutboldev.user_accounts`
- **Decision**:
  - Extend `vifutboldev.user_accounts` with `phone text`, `document_id text`, `normalized_document_id text`.
  - Extend `vifutboldev.match_referees` with `document_id text`, `normalized_document_id text`, `phone text`, plus partial unique indexes on `user_account_id` (`WHERE user_account_id IS NOT NULL`) and `normalized_document_id` (`WHERE normalized_document_id IS NOT NULL`).
- **Rationale**:
  - Storing `phone` and `document_id` on `user_accounts` allows instant completeness evaluation across all roles (including when switching `active_role` in Profile) and pre-filling `CompleteProfileDialog` without extra roundtrips.
  - Adding `document_id` and `normalized_document_id` to `match_referees` enables the exact same non-duplication linking rule as `players` (FR-004).
- **Alternatives Considered**:
  - *Querying all 5 profile tables on every Profile tab build*: Rejected due to unnecessary latency and offline complexity; `UserAccount` + lightweight `RoleProfileDetails` cached in `AuthSession` / `LocalStorageRepository` keeps UI evaluation instantaneous.

### 4. Dedicated Satellite Tables (`coach_profiles`, `organizer_profiles`, `fan_profiles`)
- **Decision**: Create three 1:1 satellite tables in `vifutboldev` keyed by `user_account_id uuid PRIMARY KEY REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE`, with RLS enabled and `SELECT, INSERT, UPDATE` policies scoped to `(SELECT auth.uid()) = user_account_id` (matching `handle_new_auth_user` where `user_accounts.id = auth.users.id`, or via `vifutboldev.current_user_account_id()`).
- **Rationale**:
  - Cleanly isolates role-specific attributes (`club_name`, `license_level` for `coach`; `organization_name`, `base_city` for `organizer`; `city`, `preferences` for `fan`) and `phone` without bloating `user_accounts` or `players`.
- **Alternatives Considered**:
  - *Single JSONB `profile_metadata` column on `user_accounts`*: Rejected because HU 19.4 explicitly requires dedicated relational satellite tables with RLS.

### 5. Profile Completeness Evaluation & Adaptive UI Flow
- **Decision**:
  - Add pure domain completeness evaluator (`RoleProfileCompleteness` / `UserAccount.isProfileCompleteForActiveRole(RoleProfileData?)`) following the clarified rule:
    - `guest` (`isGuestFan == true`): always excluded (never shows incomplete banner/badge).
    - `player` & `referee`: requires non-empty `phone` and `document_id`.
    - `coach`: requires non-empty `phone`, `document_id`, `club_name`, `license_level`.
    - `organizer`: requires non-empty `phone`, `document_id`, `organization_name`, `base_city`.
    - `fan` (authenticated): requires non-empty `phone` and `city` (`document_id` NOT required).
  - Display an amber `KickPulseBadge` (`"Datos incompletos"`) + warning banner with `"Completar mi perfil"` CTA in `ProfileTabView` when incomplete, and green `KickPulseBadge` (`"Perfil completo"`) when complete.
  - Present `CompleteProfileDialog` adaptive modal requiring active connectivity on submit (preserving entered values on offline/error so user can retry without false positives).
- **Rationale**:
  - Matches all clarified requirements (FR-007 through FR-012) and `docs/MOBILE_GUIDELINES.md` resilience rules.
- **Alternatives Considered**:
  - *Offline queuing for profile completion*: Rejected in clarification because `document_id` linking requires real-time cloud conflict verification.
