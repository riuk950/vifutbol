# Feature Specification: Unrestricted Future Match Calendar and Colombia Time Zone (12-Hour AM/PM) Standardization

**Feature Branch**: `050-colombia-schedule-calendar`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "de Notion HU 22.2 en curso — [Épica 22] HU 22.2: Calendario de Programación con Fechas Futuras Libres y Zona Horaria Colombia (AM/PM)"

## Clarifications

### Session 2026-11-19

- Q: Al programar un partido en una competición cuya fecha de inicio configurada es futura, ¿desde qué fecha mínima debe permitir seleccionar el calendario de programación? → A: Option A — Desde hoy en hora Colombia (UTC-5) hasta el 31 de diciembre de 2100, sin limitar por la fecha de inicio ni por la fecha de fin de la competición.
- Q: ¿Qué formato exacto de hora en 12 horas (AM/PM) debe usarse de forma uniforme en las tarjetas de partidos, jornadas y selector de hora? → A: Option A — Con cero inicial en horas de un dígito y sufijo en mayúsculas (`08:00 AM`, `04:30 PM`, `12:00 PM`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unrestricted Future Date Selection When Scheduling Matches (Priority: P1)

As a tournament organizer, I want to navigate and pick any future calendar date (months or years ahead, without artificial short-term caps) when scheduling or rescheduling a match so that I can plan long-running championships and upcoming seasons freely.

**Why this priority**: Artificial upper date caps (such as tournament end dates or short 30/90-day windows) block organizers from scheduling matches for future months or long seasons, directly preventing fixture planning.

**Independent Test**: Can be fully tested by opening the match scheduling flow for a competition, opening the date selector, navigating several months or years into the future (up to the year 2100), selecting a future date, and confirming the match saves cleanly.

**Acceptance Scenarios**:

1. **Given** an organizer opens the match scheduling form for any competition match, **When** the organizer opens the calendar date selector, **Then** the organizer can navigate freely to any future date up to December 31, 2100 without being blocked by short artificial caps or restrictive tournament end-date cutoffs.
2. **Given** an organizer opens the match scheduling form for an unscheduled match, **When** the date selector is presented, **Then** the earliest selectable date is today's date in Colombia time (UTC-5), preventing new scheduling on past dates while allowing the current day and any future date.
3. **Given** an organizer opens the match scheduling form for a match that already has a scheduled date, **When** the date selector is presented, **Then** the selector opens focused on that match's date (or today in Colombia time if the previous date has passed) and allows moving it to any valid future date.

---

### User Story 2 - 12-Hour AM/PM Time Selection Interpreted in Colombia Time (UTC-5) (Priority: P1)

As a tournament organizer, I want the time selector to always present times in 12-hour format with explicit AM/PM indicators and interpret every chosen date and time as official Colombia time (UTC-5) before storing it in standard universal time, so that match times are unambiguous regardless of my device's regional settings.

**Why this priority**: In Colombia, users expect 12-hour AM/PM schedules; interpreting input in the device's arbitrary time zone or showing 24-hour pickers causes scheduling errors and off-by-one-day shifts when organizers travel or use devices configured in other locales/time zones.

**Independent Test**: Can be fully tested on a device configured in a different time zone or 24-hour clock format by opening the time selector, confirming 12-hour AM/PM controls appear, choosing "3:30 PM" (or "9:00 PM"), saving, and verifying the persisted universal timestamp corresponds to 20:30 UTC (or 02:00 UTC next day).

**Acceptance Scenarios**:

1. **Given** an organizer is scheduling a match on a device configured in either 12-hour or 24-hour mode, **When** the organizer opens the time selector, **Then** the selector explicitly operates in 12-hour format with clear AM / PM selection.
2. **Given** an organizer selects a date and time (for example, May 10, 2027 at 3:30 PM) and confirms saving, **When** the match schedule is persisted, **Then** the system interprets the input as Colombia time (UTC-5, with no daylight saving adjustments) and stores the normalized universal timestamp (May 10, 2027 at 20:30 UTC).
3. **Given** an organizer attempts to schedule a match for a time earlier than the current minute in Colombia time, **When** the organizer confirms saving, **Then** the system rejects the past schedule with a clear Spanish validation message.

---

### User Story 3 - Consistent Colombia Time (AM/PM) Display and Calendar Grouping Across All Views (Priority: P1)

As any platform user (organizer, coach, referee, player, or fan), I want all scheduled match times across the Matches screen, competition rounds, and team schedules to be grouped by their Colombia calendar day and displayed in 12-hour AM/PM format (for example, "4:00 PM" or "09:00 PM") regardless of my device's time zone or 24-hour clock setting.

**Why this priority**: Late-evening matches in Colombia (such as 8:00 PM or 9:00 PM Colombia time, which fall at 01:00 AM or 02:00 AM UTC the following day) must never jump to the wrong calendar day or display confusing 24-hour times for users checking when their team plays.

**Independent Test**: Can be fully tested by storing a match scheduled at 9:00 PM Colombia time (02:00 AM UTC the next day), opening the Matches screen, Competition Detail rounds, and Team Schedule views on a device set to a non-Colombia time zone, and confirming the match appears on the exact Colombia calendar date with "9:00 PM" (or "09:00 PM") formatted in 12-hour AM/PM.

**Acceptance Scenarios**:

1. **Given** a match is scheduled for 4:00 PM Colombia time (21:00 UTC), **When** any user views the main Matches screen, the competition rounds list, or a team's schedule, **Then** the match is grouped under the corresponding Colombia calendar day and its time is displayed as `04:00 PM`.
2. **Given** a match is scheduled for 9:00 PM Colombia time (02:00 AM UTC on the next calendar day), **When** a user selects that evening's Colombia date in the Matches screen calendar, **Then** the match appears under that evening's Colombia date (not the next day) and displays `09:00 PM`, regardless of the device's system time zone.
3. **Given** a user views match cards on a compact mobile screen or with enlarged accessibility text scaling, **When** 12-hour AM/PM times are rendered, **Then** the AM/PM indicator remains fully readable without text clipping or layout overflow.

---

### User Story 4 - Unrestricted Future and Historical Date Navigation in the Matches Screen Calendar (Priority: P2)

As any platform user, I want the calendar date picker in the main Matches screen to let me jump to any past or future date (without short 2-year or 90-day limits) and immediately display all matches scheduled for that Colombia calendar day.

**Why this priority**: Once organizers can schedule matches far into the future, players, coaches, referees, and fans must be able to navigate to those same future dates in the Matches screen calendar to view them.

**Independent Test**: Can be fully tested by opening the main Matches screen, tapping the top-bar calendar action, selecting a future date several years ahead (where a match has been scheduled), and verifying the Matches screen loads and displays that day's matches in Colombia time.

**Acceptance Scenarios**:

1. **Given** any user is on the main Matches screen, **When** the user opens the top-bar calendar date picker, **Then** the user can navigate freely across historical dates and any future date up to December 31, 2100.
2. **Given** a match is scheduled on a future date (e.g., 3 years from today), **When** the user selects that future date in the Matches screen calendar, **Then** the screen selects that date, updates the date indicator, and displays the scheduled match(es) grouped for that Colombia calendar day.
3. **Given** a user uses the quick tabs ("Ayer", "Hoy", "Mañana") on the Matches screen, **When** the user switches between quick tabs, **Then** "Hoy", "Ayer", and "Mañana" are always anchored to the current date in Colombia time (UTC-5).

---

### Edge Cases

- **Midnight UTC Boundary (7:00 PM – 11:59 PM Colombia Time)**: Matches scheduled between 7:00 PM and 11:59 PM Colombia time correspond to 00:00 – 04:59 UTC of the next day. Date grouping, quick-tab matching ("Ayer"/"Hoy"/"Mañana"), and past-time validation must always convert to Colombia (UTC-5) before extracting year/month/day so no evening match shifts to the next day.
- **Midnight & Noon 12-Hour Edge Cases**: 00:00 Colombia time must format as `12:00 AM` and 12:00 Colombia time must format as `12:00 PM` (never `00:00 AM` or `24:00`).
- **Device in Foreign Time Zone or 24-Hour Mode**: If a user's device is set to Europe (UTC+1/+2), US Pacific (UTC-8), or 24-hour clock format, the app must still interpret scheduled inputs in Colombia time (UTC-5), show AM/PM in the time picker, and render all match times in Colombia AM/PM.
- **No Daylight Saving Time (DST) in Colombia**: Colombia observes permanent UTC-5 year-round; dates in June and December must both apply an exact -5 hour offset from UTC without DST drift.
- **Offline / Cached Match Consistency**: Matches stored locally for offline viewing must preserve their normalized universal timestamps and render identically in Colombia AM/PM both offline and after cloud refresh.
- **Compact Screens & Large Text Scaling**: Match time badges and time ranges (e.g., `03:30 PM - 05:15 PM`) must remain legible without truncation or overflow on narrow screens and elevated font scales.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST use Colombia standard time (`America/Bogota`, fixed UTC-5 with no daylight saving time) as the single canonical business time zone for interpreting, validating, grouping, and displaying all match dates and times.
- **FR-002**: System MUST convert all organizer-selected match dates and times from Colombia time (UTC-5) to normalized universal time (UTC) when persisting to local and cloud storage, and convert stored timestamps back to Colombia time (UTC-5) whenever reading or displaying them.
- **FR-003**: System MUST group matches by calendar day in the Matches screen and compute relative quick tabs ("Ayer", "Hoy", "Mañana") using the Colombia (UTC-5) calendar date so that late-evening matches (7:00 PM – 11:59 PM Colombia) never shift to the following day.
- **FR-004**: System MUST format all displayed match times across the Matches screen, competition fixture rounds, match detail cards, and team schedules in zero-padded 12-hour format with an explicit uppercase `AM` / `PM` suffix (e.g., `08:00 AM`, `12:00 PM`, `04:30 PM`, `12:00 AM`).
- **FR-005**: System MUST configure the match scheduling time selector explicitly in 12-hour AM/PM mode regardless of the user's device 24-hour clock preference.
- **FR-006**: System MUST allow organizers to select any date from today in Colombia time (UTC-5) through December 31, 2100 when scheduling or rescheduling a match, without clamping to the competition's start or end dates or imposing artificial short-term caps (preserving an already-scheduled match's existing date as initial focus when it is not in the past).
- **FR-007**: System MUST validate that a newly scheduled match start time is not earlier than the current minute in Colombia time (UTC-5), displaying a clear Spanish validation message when rejected.
- **FR-008**: System MUST allow any user navigating the Matches screen calendar picker to select both historical dates and any future date up to December 31, 2100 without restrictive short-term caps.
- **FR-009**: System MUST ensure all 12-hour AM/PM time displays and time selectors remain visually clean, accessible, and free of overflow on compact mobile screens and with accessibility text scaling enabled.

### Key Entities

- **Canonical Business Time (Colombia UTC-5)**: The standardized representation of match dates and times anchored to fixed UTC-5, providing bidirectional conversion to/from UTC, Colombia calendar-day extraction, and 12-hour AM/PM formatting.
- **Scheduled Match Window**: A match's start and end instants stored in UTC and evaluated/displayed in Colombia time (UTC-5) for calendar day grouping, past-time validation, collision checks, and user presentation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of matches scheduled between 7:00 PM and 11:59 PM Colombia time appear under the exact Colombia calendar date (0 day-shift errors across midnight UTC boundaries) regardless of the device's system time zone.
- **SC-002**: 100% of match times rendered across the Matches screen, competition fixture rounds, match cards, and team schedules display in 12-hour format with explicit `AM` / `PM` indicators (0 remaining 24-hour time displays in match scheduling/viewing flows).
- **SC-003**: Organizers can select and save any future match date up to the year 2100 in 100% of scheduling flows without encountering artificial short-term date limits.
- **SC-004**: Any user can navigate to any future date up to the year 2100 in the Matches screen calendar picker and view scheduled matches for that Colombia day on the first attempt.
- **SC-005**: 100% of scheduled match round-trips (save in Colombia time → persist in UTC → reload on another device/time zone) preserve the exact same Colombia date and AM/PM time with zero minute or day drift.

## Assumptions

- **Permanent UTC-5 Offset**: Colombia (`America/Bogota`) does not observe daylight saving time and has remained permanently on UTC-5; a fixed `-5 hours` offset from UTC is accurate for all historical and future dates through 2100.
- **Scope Boundary**: This specification covers the unrestricted future calendar horizon, Colombia (UTC-5) time zone normalization, and 12-hour AM/PM selection and display across match scheduling and viewing screens (HU 22.2). Cloud persistence mechanics for fixtures (HU 22.1) are already implemented; standings/teams/info sync (HU 22.3) and organizer panel metrics (HU 22.4) remain in their own specifications.
- **Spanish UI Locale**: All user-facing calendar labels, validation messages, and AM/PM displays follow the application's Spanish localization rules.
