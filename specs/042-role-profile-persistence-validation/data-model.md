# Data Model: Persistencia de Roles, Perfiles Extensibles en Nube y Validación de Datos Incompletos

**Feature**: `042-role-profile-persistence-validation`  
**Schema**: `vifutboldev` (PostgreSQL / Supabase)

## 1. Relational Schema Changes

### 1.1 `vifutboldev.user_accounts` (Extended)
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `phone` | `text` | nullable | Personal phone number |
| `document_id` | `text` | nullable | Raw identity document entered by user |
| `normalized_document_id` | `text` | nullable | Uppercase trimmed alphanumeric document for matching |

### 1.2 `vifutboldev.players` (Extended — Single Source of Truth)
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `tournament_team_id` | `uuid` | nullable (`DROP NOT NULL`), FK -> `tournament_teams(id)` | `NULL` when free agent |
| `tournament_id` | `uuid` | nullable (`DROP NOT NULL`), FK -> `tournaments(id)` | `NULL` when free agent |
| `shirt_number` | `integer` | nullable (`DROP NOT NULL`), `CHECK (shirt_number IS NULL OR shirt_number BETWEEN 1 AND 99)` | `NULL` when free agent |
| `position` | `text` | nullable (`DROP NOT NULL`), `CHECK (position IS NULL OR position IN ('goalkeeper','defender','midfielder','forward'))` | `NULL` when free agent |
| `phone` | `text` | nullable | Added for contact sync |
| `user_account_id` | `uuid` | FK -> `user_accounts(id) ON DELETE SET NULL` | Unique partial index `WHERE user_account_id IS NOT NULL` |

**Indexes**:
- `ux_players_user_account_id`: `UNIQUE (user_account_id) WHERE user_account_id IS NOT NULL`
- `ux_players_free_agent_doc`: `UNIQUE (normalized_document_id) WHERE tournament_id IS NULL`

### 1.3 `vifutboldev.match_referees` (Extended — Single Source of Truth)
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `document_id` | `text` | nullable | Raw identity document |
| `normalized_document_id` | `text` | nullable | Normalized document for matching |
| `phone` | `text` | nullable | Referee contact phone |
| `user_account_id` | `uuid` | FK -> `user_accounts(id) ON DELETE SET NULL` | Unique partial index `WHERE user_account_id IS NOT NULL` |

**Indexes**:
- `ux_match_referees_user_account_id`: `UNIQUE (user_account_id) WHERE user_account_id IS NOT NULL`
- `ux_match_referees_normalized_doc`: `UNIQUE (normalized_document_id) WHERE normalized_document_id IS NOT NULL`

### 1.4 `vifutboldev.coach_profiles` (New)
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `user_account_id` | `uuid` | `PRIMARY KEY`, FK -> `user_accounts(id) ON DELETE CASCADE` | 1:1 with user account |
| `club_name` | `text` | `NOT NULL DEFAULT ''` | Club o escuela de formación |
| `license_level` | `text` | `NOT NULL DEFAULT ''` | Nivel de licencia técnica |
| `phone` | `text` | `NOT NULL DEFAULT ''` | Teléfono de contacto |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT timezone('utc', now())` | |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT timezone('utc', now())` | |

### 1.5 `vifutboldev.organizer_profiles` (New)
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `user_account_id` | `uuid` | `PRIMARY KEY`, FK -> `user_accounts(id) ON DELETE CASCADE` | 1:1 with user account |
| `organization_name` | `text` | `NOT NULL DEFAULT ''` | Entidad / liga organizadora |
| `base_city` | `text` | `NOT NULL DEFAULT ''` | Ciudad base |
| `phone` | `text` | `NOT NULL DEFAULT ''` | Teléfono de contacto |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT timezone('utc', now())` | |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT timezone('utc', now())` | |

### 1.6 `vifutboldev.fan_profiles` (New)
| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `user_account_id` | `uuid` | `PRIMARY KEY`, FK -> `user_accounts(id) ON DELETE CASCADE` | 1:1 with user account |
| `city` | `text` | `NOT NULL DEFAULT ''` | Ciudad de residencia |
| `phone` | `text` | `NOT NULL DEFAULT ''` | Teléfono de contacto |
| `preferences` | `text` | `NOT NULL DEFAULT ''` | Preferencias de seguimiento |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT timezone('utc', now())` | |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT timezone('utc', now())` | |

---

## 2. Domain Entities (Dart / Flutter)

### 2.1 `UserAccount` (Extended)
- Existing: `id`, `fullName`, `email`, `activeRole`, `authorizedRoles`, `isGuestFan`, `onboardingCompleted`
- Added (nullable, backward-compatible JSON serialization):
  - `phone`: `String?`
  - `documentId`: `String?`
  - `roleProfile`: `RoleProfileData?` (holds role-specific fields for the active/saved profiles)

### 2.2 `RoleProfileData` (New Value Object in `lib/domain/entities/role_profile_data.dart`)
- `clubName`: `String?` (for `coach`)
- `licenseLevel`: `String?` (for `coach`)
- `organizationName`: `String?` (for `organizer`)
- `baseCity`: `String?` (for `organizer`)
- `city`: `String?` (for `fan`)
- `preferences`: `String?` (for `fan`)
- `certificationLevel`: `String?` (for `referee`, optional/default `'Regional'`)
- `linkedPlayerId`: `String?` (populated when `player` is linked/created)
- `linkedRefereeId`: `String?` (populated when `referee` is linked/created)

### 2.3 Completeness Evaluation Rules
`ProfileCompletenessStatus` evaluated from `UserAccount`:
- If `isGuestFan`: `isComplete = true` (banner & badge suppressed for guest mode).
- If `activeRole == UserRole.player || activeRole == UserRole.referee`:
  - Complete iff `phone` is non-empty AND `documentId` is non-empty.
- If `activeRole == UserRole.coach`:
  - Complete iff `phone`, `documentId`, `roleProfile?.clubName`, and `roleProfile?.licenseLevel` are all non-empty.
- If `activeRole == UserRole.organizer`:
  - Complete iff `phone`, `documentId`, `roleProfile?.organizationName`, and `roleProfile?.baseCity` are all non-empty.
- If `activeRole == UserRole.fan`:
  - Complete iff `phone` and `roleProfile?.city` are non-empty (`documentId` not required).

## 3. State Transitions

1. **New Registration + Role Onboarding**:
   - `auth.users` created -> trigger inserts `user_accounts` (`active_role = 'fan'`, `onboarding_completed = false`).
   - `completeRoleOnboarding` invokes `complete_role_profile` RPC -> atomically sets `active_role`, `authorized_roles`, `onboarding_completed = true` and initializes the corresponding role record (`players` / `match_referees` / `coach_profiles` / `organizer_profiles` / `fan_profiles`).
2. **Incomplete Profile -> Complete Profile**:
   - User opens `ProfileTabView` -> `isComplete == false` -> displays amber `"Datos incompletos"` badge + banner `"Completar mi perfil"`.
   - User submits `CompleteProfileDialog` (online required) -> `completeRoleProfile` RPC runs -> updates `user_accounts` + links/creates `players`/`match_referees` or upserts satellite table -> updates local `AuthSession` -> `ProfileTabView` immediately renders green `"Perfil completo"` badge and hides banner.
3. **Document Conflict**:
   - RPC detects `players.user_account_id IS NOT NULL AND players.user_account_id != v_user_account_id` (same for `match_referees`) -> raises `DOCUMENT_ALREADY_LINKED` -> repository throws `DocumentAlreadyLinkedFailure` -> UI shows localized Spanish error without closing dialog or altering data.
