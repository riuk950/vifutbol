# Tasks: Notificación en el AppBar al Árbitro al Asignarle un Partido

**Input**: Design documents from `/specs/060-referee-match-assignment-notification/`

**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/referee_assignment_notification_contract.md`, `quickstart.md`

**Tests**: Included per Constitution Principle III (*Pruebas Automatizadas como Puerta de Calidad*) and HU 26.2 checklist.

**Organization**: Tasks are grouped by user story (`US1`–`US4`) so each increment can be implemented and tested independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (`US1`, `US2`, `US3`, `US4`)
- Exact repository-relative file paths included in every task description

---

## Phase 1: Setup (Localization & Database Migration)

**Purpose**: Add Spanish localization strings and idempotent SQL migration for targeted referee assignment notifications, RLS, and trigger.

- [X] T001 Add the 2 Spanish localization keys defined in `contracts/referee_assignment_notification_contract.md` (`alertTypeRefereeAssigned`, `refereeMatchAssignedAlertTitle`) in `lib/l10n/app_es.arb`
- [X] T002 Regenerate Flutter localization delegates via `flutter gen-l10n` updating `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_es.dart` (depends on T001)
- [X] T003 [P] Create idempotent SQL migration `supabase/migrations/202611250005_referee_match_assignment_notifications.sql` adding `recipient_user_id uuid` + index on `vifutboldev.match_live_alerts`, allowing `alert_type = 'refereeMatchAssigned'`, enforcing recipient-scoped RLS (`recipient_user_id IS NULL` or current `user_accounts.id`), creating `SECURITY DEFINER` trigger `trg_notify_referee_match_assigned` on `vifutboldev.matches` (`AFTER INSERT OR UPDATE OF referee_id`, firing only when `NEW.referee_id` is non-null and changed and `match_referees.user_account_id` is non-null), and executing `NOTIFY pgrst, 'reload schema'`

---

## Phase 2: Foundational (Domain Entities, Service & Repository Support)

**Purpose**: Extend alert entities, add referee assignment notification service, and support recipient-scoped persistence locally and remotely.

- [X] T004 [P] Add `refereeMatchAssigned` to `MatchAlertType` in `lib/domain/entities/match_alert_type.dart`, add optional `recipientUserId` (`copyWith`, `toJson`, `fromJson`) to `MatchLiveAlert` in `lib/domain/entities/match_live_alert.dart`, and add optional `userAccountId` to `MatchReferee` in `lib/domain/entities/match_referee.dart`
- [X] T005 [P] Create `RefereeAssignmentNotificationService` implementing `shouldNotify(previousRefereeId:, newRefereeId:)` and `buildAssignmentAlert(...)` (formatting teams, tournament, Colombia time, and pitch in Spanish, returning `null` if `recipientUserId` is empty) in `lib/domain/services/referee_assignment_notification_service.dart` (depends on T004)
- [X] T006 Update `LocalMatchAlertsRepository` in `lib/infrastructure/repositories/local_match_alerts_repository.dart` to filter `loadAlerts`, `watchAlerts`, and `markAllAsRead` strictly by `a.recipientUserId == null || a.recipientUserId == userId` (depends on T004)
- [X] T007 Update `PostgrestMatchAlertsRemoteDataSource` in `lib/infrastructure/repositories/hybrid_match_alerts_repository.dart` to map `MatchAlertType.refereeMatchAssigned` and `recipient_user_id`, and hydrate `user_account_id` in `PostgrestTournamentMatchesRemoteDataSource.fetchOfficialReferees` in `lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart` (depends on T004)

**Checkpoint**: Domain entities, notification factory, SQL trigger/RLS, and repository isolation are ready.

---

## Phase 3: User Story 1 & 4 - Generación idempotente y aislamiento por usuario (Priority: P1/P2) 🎯 MVP

**Goal**: Generate targeted referee assignment alerts idempotently on assignment/reassignment (0 duplicates when referee does not change; safe skip when referee has no `userAccountId`) and enforce strict per-user isolation locally and remotely.

**Independent Test**: Verify `RefereeAssignmentNotificationService` and `LocalMatchAlertsRepository` in isolation: assignment creates alert for recipient, editing without changing referee creates 0 alerts, reassigning notifies only the new referee, and User B never sees User A's targeted alerts.

### Implementation for User Story 1 & 4

- [X] T008 [US1] Wire optional `MatchAlertsRepository? matchAlertsRepository` into `FixtureSchedulingUseCase` in `lib/application/use_cases/fixture_scheduling_use_case.dart` to emit a local/offline `MatchLiveAlert` via `RefereeAssignmentNotificationService` when `shouldNotify` is true and `referee?.userAccountId` is present (preserving backwards compatibility when `matchAlertsRepository` is omitted) (depends on T005)

### Tests for User Story 1 & 4

- [X] T009 [P] [US1] Create unit test suite `test/domain/services/referee_assignment_notification_service_test.dart` covering initial assignment, reassignment to new referee (only new referee notified), no-op when referee is unchanged, null skip when `recipientUserId` is null, and Spanish message formatting with Colombia time (depends on T005)
- [X] T010 [P] [US4] Create unit test suite `test/infrastructure/repositories/local_match_alerts_repository_test.dart` covering strict per-user isolation (`recipientUserId`), visibility of global alerts (`recipientUserId == null`), `markAsRead`, and user-scoped `markAllAsRead` (depends on T006)

**Checkpoint**: Idempotent generation and strict recipient isolation are verified.

---

## Phase 4: User Story 2 & 3 - Campana en AppBar, Bandeja, Lectura y Navegación Directa (Priority: P1)

**Goal**: Enable the AppBar bell with real authenticated `userId`, numeric badge (`99+` cap), rich tray tile for `refereeMatchAssigned`, auto-mark-as-read with `single-flight`, and direct navigation to `DigitalMatchReportScreen` with fallback to `AppShellSection.panel`.

**Independent Test**: Render `FanAlertsBellAction` and `FanAlertsTraySheet` for an authenticated referee; verify unread badge count (`1`, `99+`), tray details, mark-as-read decrement, direct navigation to `DigitalMatchReportScreen` when match exists, fallback to `AppShellSection.panel` when missing, and double-tap protection.

### Implementation for User Story 2 & 3

- [X] T011 [US2] Update `AppShellScreen` in `lib/presentation/shell/app_shell_screen.dart` to pass the real authenticated `userId` (`authState.session?.user.id ?? 'user-active-current'`) into `FanAlertsBellAction`
- [X] T012 [US3] Update `FanAlertsBellAction` in `lib/presentation/alerts/widgets/fan_alerts_bell_action.dart` to re-initialize `fanAlertsTrayControllerProvider` in `didUpdateWidget` when `userId` changes, cap badge text at `'99+'`, add `single-flight` guard on deep-link navigation, and for `MatchAlertType.refereeMatchAssigned` resolve the match to push `DigitalMatchReportScreen(initialMatch: match)` with fallback to `AppShellSection.panel` + `loadAllMatches(silent: true)` (depends on T004, T011)
- [X] T013 [US2] Update `FanAlertsTraySheet` in `lib/presentation/alerts/widgets/fan_alerts_tray_sheet.dart` to render `MatchAlertType.refereeMatchAssigned` with `l10n.alertTypeRefereeAssigned`, `Icons.sports`, accessible `Semantics`, and double-tap guard when selecting an alert (depends on T002, T004)

### Tests for User Story 2 & 3

- [X] T014 [P] [US3] Create widget test suite `test/presentation/alerts/referee_alerts_bell_and_tray_test.dart` covering AppBar bell badge count (including `99+`), opening tray to display `"Nuevo partido asignado"` details, tapping alert to mark as read + decrement badge + open `DigitalMatchReportScreen`, fallback to `AppShellSection.panel` when match is unavailable, and `markAllAsRead` (depends on T012, T013)

**Checkpoint**: Full end-to-end AppBar notification flow for referees is complete and tested.

---

## Phase 5: Polish & Cross-Cutting Verification

**Purpose**: Final static analysis and full regression test verification per `quickstart.md`.

- [X] T015 Run `flutter analyze` across all modified and new files listed in `quickstart.md` and run `flutter test test/domain/services/referee_assignment_notification_service_test.dart test/infrastructure/repositories/local_match_alerts_repository_test.dart test/presentation/alerts/referee_alerts_bell_and_tray_test.dart` confirming zero issues and 100% pass rate

---

## Dependencies & Execution Order

- **Phase 1**: `T001` → `T002`; `T003` in parallel.
- **Phase 2**: `T004` → `T005`, `T006`, `T007` in parallel.
- **Phase 3 & Phase 4**: `T008`/`T009`/`T010` and `T011`/`T012`/`T013`/`T014` touch disjoint files and can proceed in parallel after Phase 2.
- **Phase 5**: `T015` runs after `T001`–`T014` complete.
