# Feature Specification: Reactive Organizer Panel Summary with Cloud-Synchronized Data

**Feature Branch**: `052-organizer-panel-reactive-summary`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "de Notion HU 22.4 en curso — [Épica 22] HU 22.4: Actualización Reactiva del Resumen General en el Panel del Organizador con Datos Sincronizados"

## Clarifications

### Session 2026-11-19

- Q: ¿Qué estados de competición deben contabilizarse en los contadores de "Torneos Activos" y "Torneos sin Fixture" del Resumen General? → A: Option A — Inscripciones abiertas + En curso (excluyendo únicamente `Finalizado`) para ambos contadores: un torneo recién creado suma inmediatamente en "Torneos Activos" y en "Torneos sin Fixture" hasta que se genera su fixture o finaliza.
- Q: ¿Cómo debe refrescarse el Resumen General del Panel del Organizador cuando el usuario navega de regreso desde el detalle de una competición o cuando finaliza una sincronización en la nube? → A: Option A — Reactividad instantánea en memoria ante cambios locales, más hidratación automática desde la nube al iniciar sesión/abrir el panel, al completarse una sincronización en segundo plano y mediante *pull-to-refresh*.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Immediate Summary Updates After Generating Fixtures and Scheduling Matches (Priority: P1)

As a tournament organizer, I want the General Summary counters in my Organizer Panel—specifically "Torneos sin Fixture" and "Partidos por Programar"—to recalculate and update immediately after I generate a competition fixture or schedule matches, so that I always see an accurate operational overview without restarting the app.

**Why this priority**: Generating fixtures and scheduling matches are the most frequent operational tasks for an organizer; stale counters mislead organizers into double-checking or re-running scheduling workflows.

**Independent Test**: Can be fully tested by starting with an organizer who has a competition with no fixture, generating its fixture and returning to the Organizer Panel to verify "Torneos sin Fixture" drops by 1 and "Partidos por Programar" rises by the exact number of newly generated matches, then scheduling 2 matches and returning to confirm "Partidos por Programar" drops by 2 immediately.

**Acceptance Scenarios**:

1. **Given** an organizer has 1 active competition without a generated fixture in the Organizer Panel, **When** the organizer opens that competition, generates its fixture (synchronized to the cloud), and returns to the Organizer Panel, **Then** the "Torneos sin Fixture" counter immediately decreases by 1 and the "Partidos por Programar" counter immediately increases by the exact count of newly generated pending matches for that competition.
2. **Given** an organizer has 6 matches pending schedule across their competitions, **When** the organizer schedules the date, time, venue, and pitch for 2 of those matches and returns to the Organizer Panel, **Then** the "Partidos por Programar" counter automatically decreases from 6 to 4 without restarting the app.
3. **Given** an organizer regenerates a fixture for a competition whose matches have not started yet, **When** the organizer returns to the Organizer Panel, **Then** the "Partidos por Programar" counter reflects the exact new count of unscheduled matches.

---

### User Story 2 - Reactive Summary Updates on Competition Lifecycle and Team Changes (Priority: P1)

As a tournament organizer, I want the "Torneos Activos" counter, the "Mis Competiciones" cards, and per-competition team/status summaries in the Organizer Panel to update immediately whenever I create a competition, edit its details, change its lifecycle status (e.g., to "Finalizado"), enroll/withdraw teams, or delete a competition, so that my dashboard always matches the true state of every competition I manage.

**Why this priority**: Competition creation, status transitions, and team enrollments directly determine active workload; any mismatch between the top summary cards and the competition list undermines trust in the organizer dashboard.

**Independent Test**: Can be fully tested by creating a new competition, enrolling teams into it, transitioning another competition to "Finalizado", and deleting a draft/open competition while observing that "Torneos Activos", "Torneos sin Fixture", and each card in "Mis Competiciones" recalculate immediately with 100% consistency.

**Acceptance Scenarios**:

1. **Given** an organizer creates a new competition, **When** the creation completes and the organizer views the Organizer Panel, **Then** "Torneos Activos" and "Torneos sin Fixture" each increase by 1 immediately and the new competition appears in "Mis Competiciones".
2. **Given** an organizer transitions an active competition to "Finalizado" or deletes an unstarted competition, **When** the action completes, **Then** "Torneos Activos" immediately decreases by 1, any pending counters exclude finished/deleted competitions as applicable, and "Mis Competiciones" reflects the updated status or removal immediately.
3. **Given** an organizer enrolls, approves, or withdraws teams inside a competition, **When** the organizer returns to the Organizer Panel, **Then** the team count and summary badges shown on that competition's card match the exact enrolled team count inside the competition detail view.

---

### User Story 3 - Automatic Cloud Hydration and Strict Organizer Isolation on Sign-In and Sync (Priority: P1)

As a tournament organizer, I want the Organizer Panel's General Summary and "Mis Competiciones" list to automatically hydrate and recalculate whenever I sign in, return to the panel, manually pull to refresh, or when background cloud synchronization completes—always filtering strictly to competitions I own—so that my metrics are accurate across devices and never leak or mix data from other organizers.

**Why this priority**: Multi-device organizers and fresh logins start with empty or stale local caches; without automatic cloud hydration and strict organizer-ownership filtering, counters would display zeros or include other organizers' tournaments.

**Independent Test**: Can be fully tested by signing in as Organizer A on a fresh session (while Organizer B also has competitions and pending matches in the cloud), letting initial cloud sync complete, and verifying Organizer A's General Summary displays exact consolidated metrics exclusively for Organizer A's competitions (`organizerId == currentUserId`).

**Acceptance Scenarios**:

1. **Given** an organizer signs in on a device with empty local cache or triggers a cloud synchronization, **When** the cloud download of competitions, teams, and matches completes, **Then** the Organizer Panel automatically refreshes its reactive state and renders consolidated metrics exclusively for competitions owned by the signed-in organizer.
2. **Given** multiple organizers have competitions, teams, and pending matches in the central cloud service, **When** Organizer A opens the Organizer Panel, **Then** every summary metric ("Torneos Activos", "Partidos por Programar", "Torneos sin Fixture") and every card in "Mis Competiciones" counts only competitions where the owner matches Organizer A.
3. **Given** an organizer switches accounts (signs out as Organizer A and signs in as Organizer B), **When** Organizer B opens the Organizer Panel, **Then** no stale counters or competition cards from Organizer A remain visible; only Organizer B's synchronized data is shown.

---

### Edge Cases

- **Offline Operation with Local Mutations**: When an organizer creates a competition, generates a fixture, or schedules matches while offline, the General Summary counters MUST still update immediately from the locally persisted reactive state without waiting for cloud confirmation, and remain accurate once background sync completes upon reconnect.
- **Zero-Data / New Organizer State**: When a newly registered organizer has 0 competitions, all summary counters display `0` cleanly (never null/NaN) and "Mis Competiciones" shows a clear Spanish empty state with guidance to create a competition.
- **Transient Network Error During Refresh**: If a cloud refresh fails due to intermittent connectivity while cached data already exists, the Organizer Panel MUST retain the last known summary counters and competition cards without crashing or resetting counters to zero, showing a non-destructive Spanish retry/offline indicator.
- **Multiple Matches Across Mixed Competition States**: Pending matches belonging to competitions owned by other organizers or competitions that have been deleted MUST NEVER be counted in "Partidos por Programar".
- **Duplicate Rapid Refresh / Navigation Re-entry**: Navigating rapidly back and forth between competition detail screens and the Organizer Panel, or pulling to refresh repeatedly, MUST guard against overlapping redundant refreshes and never produce flickering or inconsistent counts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST compute and render all General Summary metrics in the Organizer Panel—"Torneos Activos" (owned competitions in `openRegistration` or `inProgress`, excluding `finished`), "Partidos por Programar" (unscheduled `pendingSchedule` matches belonging to owned competitions), and "Torneos sin Fixture" (owned `openRegistration` or `inProgress` competitions with zero associated matches)—reactively from live state so that any mutation to competitions, teams, or matches updates the counters immediately without restarting the application.
- **FR-002**: System MUST strictly isolate all Organizer Panel metrics and "Mis Competiciones" cards to competitions owned by the currently authenticated organizer (`organizerId == currentUserId`), and only aggregate matches and teams belonging to those owned competitions.
- **FR-003**: System MUST immediately decrement "Torneos sin Fixture" and increment "Partidos por Programar" by the exact count of newly generated unscheduled matches when an organizer generates a fixture for one of their competitions.
- **FR-004**: System MUST immediately decrement "Partidos por Programar" when an organizer schedules a pending match (assigning date, time, venue, and pitch) and immediately recalculate counters when a fixture is regenerated.
- **FR-005**: System MUST immediately recalculate "Torneos Activos", "Torneos sin Fixture", and "Mis Competiciones" cards whenever an organizer creates, edits, changes the lifecycle status of (including to "Finalizado"), or deletes a competition, or enrolls/withdraws teams.
- **FR-006**: System MUST react instantaneously to in-memory local mutations when returning to the Organizer Panel, and automatically trigger cloud hydration of competitions, teams, and matches upon sign-in/panel initialization, upon background cloud synchronization completion, and upon manual pull-to-refresh.
- **FR-007**: System MUST guarantee 100% visual consistency between the General Summary counters and the per-competition details shown when opening any competition in "Mis Competiciones".
- **FR-008**: System MUST preserve cached Organizer Panel metrics and competition cards non-destructively when offline or during transient network failures, displaying clear Spanish loading, empty, and error states with retry capability and guarding against overlapping concurrent refreshes.
- **FR-009**: System MUST restrict Organizer Panel access and all competition management actions exclusively to authenticated users with the Organizer role.

### Key Entities

- **Organizer Summary Snapshot**: A derived, reactive aggregation scoped to the authenticated organizer containing `activeTournamentsCount`, `pendingScheduleMatchesCount`, `tournamentsWithoutFixtureCount`, and per-competition team/match summaries.
- **Owned Competition**: A competition whose owner identifier matches the authenticated organizer, including its lifecycle status (`openRegistration`, `inProgress`, `finished`), enrolled team count, and associated fixture matches.
- **Pending Schedule Match**: A match belonging to an owned competition whose scheduling status requires date, time, venue, or pitch assignment (`pendingSchedule`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Organizer Panel General Summary counters ("Torneos Activos", "Partidos por Programar", "Torneos sin Fixture") update within 1 second of completing any competition creation, edit, status change, deletion, team enrollment, fixture generation, or match scheduling action—with zero app restarts required.
- **SC-002**: 100% of Organizer Panel metrics and competition cards strictly reflect only the authenticated organizer's owned competitions (0 cross-organizer data leakage across multi-organizer test datasets).
- **SC-003**: 100% parity between top-level General Summary counts and the sum of individual competition details when inspecting each item in "Mis Competiciones".
- **SC-004**: Fresh sign-in or post-sync hydration populates accurate cloud-backed Organizer Panel metrics within 5 seconds under normal mobile connectivity, while offline mutations remain immediately reflected locally with zero crashes.

## Assumptions

- **Existing Cloud Sync Foundation**: Cloud persistence and synchronization for fixtures/schedules (HU 22.1), Colombia UTC-5 time formatting (HU 22.2), and competition info/teams/standings with dependency-ordered outbox replay (HU 22.3) are already implemented and reused by this feature.
- **Active Competition Definition**: "Torneos Activos" counts owned competitions in active/non-finished states (`openRegistration` and `inProgress`, excluding `finished`), and "Torneos sin Fixture" counts owned active competitions that currently have zero associated matches.
- **Single-Session Ownership Scope**: An authenticated organizer views only competitions whose `organizerId` matches their active user identifier (per HU 19.3).
