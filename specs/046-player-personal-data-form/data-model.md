# Data Model: Formulario de Datos Personales del Jugador (HU 21.1)

**Feature**: `046-player-personal-data-form`  
**Date**: 2026-11-17

## 1. Domain Enums & Value Objects

### `DetailedFootballPosition` (`lib/domain/entities/detailed_football_position.dart`)

| Enum Value | Code | Spanish Display Name (via l10n) | Mapped `PlayerPosition` |
|------------|------|---------------------------------|-------------------------|
| `goalkeeper` | `POR` | Portero | `PlayerPosition.goalkeeper` |
| `centerBack` | `DFC` | Defensa Central | `PlayerPosition.defender` |
| `rightBack` | `LD` | Lateral Derecho | `PlayerPosition.defender` |
| `leftBack` | `LI` | Lateral Izquierdo | `PlayerPosition.defender` |
| `rightWingBack` | `CAD` | Carrilero Derecho | `PlayerPosition.defender` |
| `leftWingBack` | `CAI` | Carrilero Izquierdo | `PlayerPosition.defender` |
| `defensiveMidfielder` | `MCD` | Mediocentro Defensivo | `PlayerPosition.midfielder` |
| `centralMidfielder` | `MC` | Mediocentro | `PlayerPosition.midfielder` |
| `attackingMidfielder` | `MCO` | Mediocampista Ofensivo | `PlayerPosition.midfielder` |
| `rightMidfielder` | `MD` | Interior Derecho | `PlayerPosition.midfielder` |
| `leftMidfielder` | `MI` | Interior Izquierdo | `PlayerPosition.midfielder` |
| `rightWinger` | `ED` | Extremo Derecho | `PlayerPosition.forward` |
| `leftWinger` | `EI` | Extremo Izquierdo | `PlayerPosition.forward` |
| `secondStriker` | `MP` | Mediapunta | `PlayerPosition.forward` |
| `centerForward` | `DC` | Delantero Centro | `PlayerPosition.forward` |

- `static DetailedFootballPosition? fromCode(String? raw)`: case-insensitive lookup by `code` or enum `name`.

### `PlayerSex` (`lib/domain/entities/player_personal_enums.dart`)

| Enum Value | Canonical Stored Value | Spanish Display Label (via l10n) | Accepted Parser Aliases |
|------------|------------------------|----------------------------------|-------------------------|
| `male` | `'male'` | Masculino | `'male'`, `'m'`, `'masculino'` |
| `female` | `'female'` | Femenino | `'female'`, `'f'`, `'femenino'` |
| `other` | `'other'` | Otro | `'other'`, `'o'`, `'otro'` |

### `BloodType` (`lib/domain/entities/player_personal_enums.dart`)

Values: `oPositive` (`'O+'`), `oNegative` (`'O-'`), `aPositive` (`'A+'`), `aNegative` (`'A-'`), `bPositive` (`'B+'`), `bNegative` (`'B-'`), `abPositive` (`'AB+'`), `abNegative` (`'AB-'`).

### `ColombiaLocationCatalog` (`lib/domain/entities/colombia_location_catalog.dart`)

- `static List<String> get departments`: 33 entries sorted alphabetically (32 departments + `'Bogotá, D.C.'`).
- `static List<String> municipalitiesFor(String department)`: unmodifiable sorted list of all official DANE municipalities for `department` (empty list if department not found).
- `static List<String> searchDepartments(String query)`: accent-insensitive, case-insensitive substring filter.
- `static List<String> searchMunicipalities(String department, String query)`: accent-insensitive, case-insensitive substring filter within the given department.
- `static bool isValidPair(String? department, String? municipality)`: verifies `municipality` belongs to `department`.

### `PlayerPersonalDataUtils` (`lib/domain/services/player_personal_data_utils.dart`)

- `static int calculateAge(DateTime birthDate, {DateTime? referenceDate})`:
  - `today = referenceDate ?? DateTime.now()`
  - `age = today.year - birthDate.year`
  - If `today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)`, `age -= 1`.
  - Clamps minimum at `0`.
- `static String composeFullName({required String firstName, String? secondName, required String firstSurname, String? secondSurname})`:
  - Trims each non-null part, collapses internal whitespace, filters out empty strings, joins with `' '`.
- `static PlayerPosition derivePrimaryPosition(List<DetailedFootballPosition> positions)`:
  - Returns `positions.first.tacticalLine` (defaults to `PlayerPosition.midfielder` if empty).

## 2. Extended Domain Entities

### `RoleProfileData` (`lib/domain/entities/role_profile_data.dart`)

Existing fields preserved (`clubName`, `licenseLevel`, `organizationName`, `baseCity`, `city`, `preferences`, `certificationLevel`, `linkedPlayerId`, `linkedRefereeId`), plus new player personal/tactical fields:

| Field | Dart Type | JSON Keys (`camel` / `snake`) | Validation / Notes |
|-------|-----------|-------------------------------|--------------------|
| `firstName` | `String?` | `firstName` / `first_name` | Required for `player` completeness |
| `secondName` | `String?` | `secondName` / `second_name` | Optional |
| `firstSurname` | `String?` | `firstSurname` / `first_surname` | Required for `player` completeness |
| `secondSurname` | `String?` | `secondSurname` / `second_surname` | Optional |
| `sex` | `String?` | `sex` / `sex` | `'male'`, `'female'`, `'other'` |
| `birthDate` | `DateTime?` | `birthDate` / `birth_date` | Date-only (`YYYY-MM-DD`) |
| `bloodType` | `String?` | `bloodType` / `blood_type` | One of 8 ABO/Rh labels |
| `department` | `String?` | `department` / `department` | Must exist in `ColombiaLocationCatalog.departments` |
| `municipality` | `String?` | `municipality` / `municipality` | Must belong to `department` |
| `primaryPosition` | `PlayerPosition?` | `primaryPosition` / `position` | Derived from `secondaryPositions.first` |
| `secondaryPositions` | `List<String>` | `secondaryPositions` / `secondary_positions` | Default `const []`; codes from `DetailedFootballPosition` |

### `UserAccount.isProfileCompleteForActiveRole` (`lib/domain/entities/user_account.dart`)

Updated rule for `UserRole.player`:
```dart
case UserRole.player:
  return hasPhone &&
      hasDoc &&
      _hasText(roleProfile?.firstName) &&
      _hasText(roleProfile?.firstSurname) &&
      _hasText(roleProfile?.sex) &&
      roleProfile?.birthDate != null &&
      _hasText(roleProfile?.bloodType) &&
      _hasText(roleProfile?.department) &&
      _hasText(roleProfile?.municipality) &&
      (roleProfile?.secondaryPositions.isNotEmpty ?? false);
```

All other roles (`referee`, `coach`, `organizer`, `fan`) retain their existing completeness rules untouched.

## 3. Database Schema Migration (`supabase/migrations/202611170002_player_personal_profile_fields.sql`)

### Columns Added to `vifutboldev.players`

```sql
ALTER TABLE vifutboldev.players
  ADD COLUMN IF NOT EXISTS first_name text,
  ADD COLUMN IF NOT EXISTS second_name text,
  ADD COLUMN IF NOT EXISTS first_surname text,
  ADD COLUMN IF NOT EXISTS second_surname text,
  ADD COLUMN IF NOT EXISTS sex text,
  ADD COLUMN IF NOT EXISTS birth_date date,
  ADD COLUMN IF NOT EXISTS blood_type text,
  ADD COLUMN IF NOT EXISTS department text,
  ADD COLUMN IF NOT EXISTS municipality text,
  ADD COLUMN IF NOT EXISTS secondary_positions text[] NOT NULL DEFAULT '{}'::text[];
```

Constraints (added idempotently via `DO $$ ... END $$` guards):
- `chk_players_sex`: `sex IS NULL OR sex IN ('male', 'female', 'other')`
- `chk_players_blood_type`: `blood_type IS NULL OR blood_type IN ('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-')`

### Updated RPC `vifutboldev.complete_role_profile`

- Accepts all previous 13 parameters plus 11 optional player parameters (all `DEFAULT NULL`):
  - `p_first_name text`
  - `p_second_name text`
  - `p_first_surname text`
  - `p_second_surname text`
  - `p_sex text`
  - `p_birth_date date`
  - `p_blood_type text`
  - `p_department text`
  - `p_municipality text`
  - `p_primary_position text`
  - `p_secondary_positions text[]`
- Computes harmonized `full_name` when `p_first_name` & `p_first_surname` are supplied, updates both `vifutboldev.user_accounts.full_name` and `vifutboldev.players.full_name`.
- Preserves non-duplicating `normalized_document_id` linking (`DOCUMENT_ALREADY_LINKED` error if linked to a different `user_account_id`).
- Returns hydrated `role_profile` JSONB including all player personal & tactical fields.
