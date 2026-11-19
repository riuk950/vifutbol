# Feature Specification: Fixture Generation, Match Scheduling Cloud Synchronization, and Daily Matches Visibility

**Feature Branch**: `049-fixture-schedule-cloud-sync`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "de Notion HU 22,1 en curso — [Épica 22] HU 22.1: Sincronización Cloud del Fixture Generado, Programaciones de Partidos y Visualización en Partidos"

## Clarifications

### Session 2026-11-19

- Q: ¿Qué debe ocurrir en la nube y en el dispositivo cuando un organizador vuelve a presionar "Generar Fixture" en una competición que ya tiene un fixture generado previamente? → A: Option A — Permitir regenerar el fixture únicamente si ningún partido ha iniciado o finalizado, solicitando confirmación y reemplazando limpiamente los partidos anteriores (eliminando los previos y subiendo los nuevos) en local y en la nube.
- Q: Al programar un partido desde una jornada, ¿qué campos deben ser obligatorios para permitir guardar la programación y que el partido aparezca en la pantalla principal de Partidos? → A: Option A — Solo fecha y hora son obligatorias para guardar y mostrar el partido en Partidos; sede, cancha y árbitro son opcionales (mostrando un texto de estado como "Por definir" si no están asignados).
- Q: ¿Cómo debe actualizarse la lista de partidos en la pantalla principal de "Partidos" para reflejar programaciones recientes realizadas desde otros dispositivos? → A: Option A — Mostrar caché local de inmediato y refrescar automáticamente desde la nube al abrir/volver a la pestaña "Partidos" y al cambiar de fecha, además de soportar refresco manual (pull-to-refresh).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cloud Persistence and Synchronization of Generated Competition Fixture (Priority: P1)

As a tournament organizer, I want the complete match schedule (fixture) generated for my competition to be saved immediately on my device and synchronized to the central cloud service so that every round and matchup is preserved reliably and accessible from any device without data loss.

**Why this priority**: Generating the fixture is the foundational step that creates all competition matches; if generated matches are not persisted remotely and idempotently, no downstream scheduling, officiating, or public match viewing can function across devices.

**Independent Test**: Can be fully tested by having an organizer with at least 2 eligible teams in an active competition trigger fixture generation while online, then reloading the application or signing in on a second device and verifying that all generated rounds and matches appear intact with no duplicates.

**Acceptance Scenarios**:

1. **Given** an organizer has a competition with at least 2 eligible teams and an active internet connection, **When** the organizer triggers "Generar Fixture" from the competition's action menu, **Then** all generated matches across all rounds are saved locally on the device and synchronized in a batch to the central cloud service.
2. **Given** a competition fixture has been generated and synchronized to the cloud, **When** the organizer or any other user reloads the application or opens the competition on another device, **Then** the complete fixture (every round, round name, home team, away team, and initial status) is displayed identically to what was generated.
3. **Given** an organizer triggers fixture generation, **When** the organizer taps the generate action repeatedly while the operation is already in progress, **Then** the system prevents duplicate submissions and ensures each generated match retains a single unique identifier without creating duplicate match records.

---

### User Story 2 - Cloud Synchronization of Individual Match Scheduling (Priority: P1)

As a tournament organizer, I want each individual match schedule (date, time, venue, pitch, and assigned referee) to be persisted locally and synchronized to the central cloud service immediately upon confirmation, with clear visual feedback on synchronization status.

**Why this priority**: Scheduling individual matches converts abstract round pairings into real-world playable fixtures; coaches, referees, players, and fans depend on accurate, up-to-date scheduling logistics.

**Independent Test**: Can be fully tested by selecting an unscheduled match within a competition round, assigning a date, start time, venue, pitch, and referee, confirming the save, and verifying both the top-bar synchronization indicator and the persisted match details after reloading the app.

**Acceptance Scenarios**:

1. **Given** an organizer selects a match inside a competition round while online, **When** the organizer assigns a date, start time, venue, pitch, and referee and confirms saving, **Then** the match is updated locally and synchronized immediately to the central cloud service with all assigned scheduling details preserved.
2. **Given** the organizer confirms a match schedule change, **When** the synchronization completes, **Then** the top-bar synchronization status indicator reflects that data is up to date, and the user receives clear confirmation feedback.
3. **Given** a non-organizer user (coach, referee, player, or fan) views a competition round, **When** they inspect any match, **Then** they cannot create fixtures or modify match scheduling details.

---

### User Story 3 - Automatic Visibility of Scheduled Matches in the Matches Screen (Priority: P1)

As any platform user (organizer, coach, referee, player, or fan), I want every match scheduled by an organizer for a specific date to appear automatically in the main Matches screen when I select that date on the calendar, displaying its competition, teams, start time, venue, pitch, and current status from synchronized cloud data.

**Why this priority**: The main Matches screen is the primary daily hub for all five user roles to discover and follow scheduled games; synchronizing schedules without surfacing them there leaves users blind to official match logistics.

**Independent Test**: Can be fully tested by scheduling a match for a specific calendar date as an organizer, then switching to the main Matches screen (or signing in as another role such as fan, player, coach, or referee), selecting that date in the calendar, and confirming the match card displays accurate competition, team, time, venue, pitch, and status information.

**Acceptance Scenarios**:

1. **Given** an organizer has scheduled a match for a specific date and time, **When** any user (organizer, coach, referee, player, or fan) opens the main "Partidos" tab and selects that date in the calendar, **Then** the scheduled match appears in the daily list showing its competition name, home and away teams, scheduled time, venue, pitch, and current status loaded from synchronized cloud data.
2. **Given** a competition has matches in its fixture that do not yet have a scheduled date and time, **When** a user views the main "Partidos" tab for any date, **Then** unscheduled matches do not appear in the daily calendar list, while remaining visible inside their respective rounds in the Competition Detail screen.
3. **Given** an organizer updates an already scheduled match to a different date or time, **When** a user checks the main "Partidos" tab, **Then** the match no longer appears under the previous date and appears under the newly scheduled date with updated details.

---

### User Story 4 - Offline Fixture Generation, Scheduling, and Automatic Recovery (Priority: P2)

As a tournament organizer working at a sports venue with unreliable or unavailable internet connectivity, I want to generate fixtures and schedule matches offline and have the system automatically synchronize all pending changes to the cloud once connectivity returns, without losing data or creating duplicates.

**Why this priority**: Amateur and regional football venues frequently have poor mobile signal; offline-first resilience ensures organizers can continue managing competitions without interruption.

**Independent Test**: Can be fully tested by disconnecting the device from the network, generating a fixture or scheduling a match, verifying that changes persist locally and the top-bar indicator shows pending synchronization, then restoring connectivity and verifying that all pending records synchronize cleanly to the cloud without duplicating matches.

**Acceptance Scenarios**:

1. **Given** an organizer has no internet connection, **When** the organizer generates a fixture or schedules a match (date, time, venue, pitch, referee), **Then** the changes are saved immediately on the device, queued for later synchronization, and the top-bar status indicator communicates that changes are pending upload.
2. **Given** there are queued fixture generations or match schedule updates pending synchronization, **When** the device regains internet connectivity (including after the app returns from background or is reopened), **Then** the system automatically uploads all pending matches and scheduling updates to the central cloud service in order, without creating duplicate matches.
3. **Given** a network interruption occurs mid-synchronization during a batch fixture upload or individual match update, **When** synchronization retries automatically upon reconnection, **Then** previously uploaded matches are updated idempotently by their unique identifier rather than duplicated, and any error state provides clear, non-technical feedback with a recovery path.

---

### Edge Cases

- **Referential Integrity Before Sync**: What happens if an organizer schedules a match referencing a venue, pitch, referee, or team that has not yet been synchronized to the cloud? The system must ensure parent references (competition, teams, venue, pitch, referee) exist or are synchronized in dependency order before syncing the match so remote saves do not fail due to missing references.
- **Re-generating or Updating an Existing Fixture**: What happens if an organizer triggers fixture generation for a competition that already has synchronized matches? If any match in the competition has already started or finished, regeneration must be blocked. If no match has started or finished, the system must ask for organizer confirmation and then cleanly replace the previous fixture (removing previous matches and saving/syncing the new matches) in both local storage and the cloud so no orphaned or duplicate matches remain. Retries of a failed batch sync must still update matches idempotently by their unique identifier.
- **Unscheduled Matches vs. Scheduled Matches**: What happens when a match has a venue or referee assigned but no scheduled date/time? Only matches with a confirmed scheduled date and time appear in the daily Matches calendar; unscheduled matches remain exclusively inside the Competition Detail rounds view.
- **App Backgrounding / Process Interruption During Save**: What happens if the app is moved to the background or interrupted while saving a fixture or match schedule? Local persistence completes safely or the pending sync queue retains the unconfirmed operation so it resumes cleanly upon reopening without leaving partial or duplicate records.
- **Empty & Error States on Matches Screen**: What happens when a user selects a date with no scheduled matches, or opens the Matches screen while offline with no previously cached matches? The screen displays a clear empty state for dates without matches, or displays cached matches with a clear offline indicator and retry option if remote refresh fails.
- **Repeated Taps on Save/Generate**: What happens if the user taps "Generar Fixture" or "Guardar" multiple times rapidly? The action control enters a busy/disabled state until the current operation settles, preventing duplicate operations.
- **Time Zone / Date Boundary Consistency**: What happens when a match is scheduled late at night or early morning? The date bucket in the Matches calendar and the displayed start time must consistently match the user's regional date/time representation without shifting a match to the wrong day.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST persist all matches generated by an organizer during competition fixture creation locally on the device and synchronize them as a batch to the central cloud service.
- **FR-002**: System MUST assign each generated match a stable unique identifier so that repeated synchronizations, retries, or updates overwrite the same match record idempotently without creating duplicates.
- **FR-002a**: System MUST allow regenerating a competition fixture only when no match in that competition has started or finished, requiring explicit organizer confirmation and cleanly replacing previous matches (deleting prior fixture records and uploading the new batch) in both local storage and the central cloud service.
- **FR-003**: System MUST persist and synchronize all match attributes required for competition rounds and daily scheduling, including competition reference, home team, away team, round number, round name, match status, scheduled start date/time, venue, pitch, and assigned referee.
- **FR-004**: System MUST update local storage and synchronize immediately to the central cloud service whenever an organizer assigns or modifies a match's scheduling details; only scheduled start date and time are mandatory to save a schedule, while venue, pitch, and referee are optional and may be added or updated independently later.
- **FR-005**: System MUST enforce referential integrity so that every synchronized match references valid, synchronized competition, home team, away team, and (when assigned) venue, pitch, and referee records.
- **FR-006**: System MUST queue fixture generation and match scheduling mutations locally when the device is offline or experiences a transient network failure, and automatically upload queued mutations upon regaining connectivity without duplicating matches.
- **FR-007**: System MUST update the top-bar synchronization status indicator accurately to reflect synced, syncing, offline/pending, and error states during fixture generation and match scheduling.
- **FR-008**: System MUST display all cloud-synchronized matches that have a scheduled start date and time in the main "Partidos" screen filtered by the user-selected calendar date, showing competition name, home and away teams, start time, match status, and assigned venue, pitch, and referee (or clear Spanish placeholders such as "Por definir" when optional logistics are not yet assigned).
- **FR-009**: System MUST exclude unscheduled matches (those without a scheduled start date and time) from the daily calendar view in the main "Partidos" screen while keeping them visible within their respective rounds in the Competition Detail view.
- **FR-010**: System MUST reflect newly scheduled or rescheduled matches in the main "Partidos" screen for all five user roles (organizer, coach, referee, player, and fan) by rendering locally cached matches immediately while automatically refreshing from the central cloud service upon entering/returning to the "Partidos" screen, upon changing the selected calendar date, and upon manual pull-to-refresh.
- **FR-011**: System MUST restrict fixture generation and match scheduling mutations exclusively to authenticated users holding the organizer role, while allowing read-only visibility of synchronized matches to all authorized roles.
- **FR-012**: System MUST handle loading, content, empty, error, and success UI states cleanly in both the Competition Detail fixture view and the main "Partidos" screen, and disable duplicate submissions while a save or generation action is in progress.
- **FR-013**: System MUST present all user-facing messages, status labels, validation errors, and confirmation feedback in Spanish without exposing technical error details or sensitive system data.

### Key Entities

- **Competition**: The parent tournament containing eligible teams, rounds, and rules; owns the generated fixture.
- **Fixture / Round**: The structured sequence of matchdays (numbered and named rounds) grouping matches within a competition.
- **Match**: An individual game between a home team and an away team within a competition round. Key attributes: unique identifier, competition reference, home team reference, away team reference, round number, round name, match status, optional scheduled start date/time, optional venue reference, optional pitch reference, and optional referee reference.
- **Venue & Pitch**: The physical location and specific playing field assigned to a scheduled match.
- **Referee**: The match official assigned to officiate a scheduled match.
- **Pending Sync Operation**: A locally stored, ordered record representing an unsynchronized fixture batch or individual match schedule update awaiting upload when connectivity is restored.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of matches generated in a competition fixture are persisted to the cloud and visible intact across a full application reload or a second device with zero missing or duplicated matches.
- **SC-002**: 100% of match scheduling updates (date, time, venue, pitch, referee) saved by an organizer while online are reflected in the main "Partidos" screen under the corresponding calendar date within 5 seconds of saving or immediately upon screen refresh.
- **SC-003**: 0 unscheduled matches appear in the daily calendar of the main "Partidos" screen, while 100% of unscheduled matches remain visible in their corresponding rounds inside Competition Detail.
- **SC-004**: 100% of fixtures generated or match schedules saved while offline synchronize automatically to the cloud upon reconnection with zero duplicate match records created across repeated retry attempts.
- **SC-005**: 100% of users across all five roles (organizer, coach, referee, player, fan) view identical synchronized match details (competition, teams, time, venue, pitch, status) for any scheduled date in the main "Partidos" screen.

## Assumptions

- **Existing Competition & Eligible Teams**: Competitions, eligible enrolled teams, venues, pitches, and referees are already managed and persisted through the platform's existing synchronization mechanisms prior to fixture generation and scheduling.
- **Scope Boundary**: This specification covers cloud persistence, offline synchronization, and cross-screen visibility of generated fixtures and individual match schedules (HU 22.1). Calendar date-picker enhancements with free future dates and Colombia AM/PM formatting (HU 22.2), standings/teams/info sync (HU 22.3), and organizer panel reactive metrics (HU 22.4) are tracked in their own separate specifications.
- **Authentication & Role Enforcement**: Existing role-based access control already identifies the authenticated user's active role and restricts organizer-only controls in the competition management workflow.
- **Conflict Resolution Policy**: Since only the competition's organizer can generate fixtures and edit match scheduling, last-write-wins ordered by operation timestamp (FIFO queue replay for offline mutations) is sufficient and unambiguous.
