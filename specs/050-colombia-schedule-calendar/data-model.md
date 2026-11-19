# Data Model: Colombia Time Normalization & Match Schedule Representation

**Feature**: `050-colombia-schedule-calendar` (HU 22.2)
**Date**: 2026-11-19

## 1. Temporal Representation Rules

### 1.1 Storage Format (UTC Instant)
- **Cloud (`vifutboldev.matches`)**: `scheduled_at` (`timestamptz`), `scheduled_end_at` (`timestamptz`) stored as ISO-8601 UTC (`YYYY-MM-DDTHH:mm:ss.sssZ`).
- **Local Hive (`ChampionshipMatch.toJson()`)**: `scheduledStartTime`, `scheduledEndTime` stored as ISO-8601 UTC (`toUtc().toIso8601String()`).
- **Domain Entity (`ChampionshipMatch`)**: `scheduledStartTime` and `scheduledEndTime` represent exact instants in time (normalized to UTC when constructed via `ColombiaTimeUtils.fromColombiaWallClock` or deserialized from remote/local storage).

### 1.2 Colombia Business Time Projection (Fixed UTC-5)
- Offset: `UTC-5` (`Duration(hours: -5)`), permanent year-round (no DST).
- **Conversion UTC → Colombia Wall-Clock**:
  - `utcInstant.toUtc().add(const Duration(hours: -5))` → extract `(year, month, day, hour, minute)`.
  - Example: `2026-11-20T02:00:00Z` → `2026-11-19 21:00` → Date `19/11/2026`, Time `09:00 PM`.
- **Conversion Colombia Wall-Clock → UTC Instant**:
  - `DateTime.utc(year, month, day, hour, minute).add(const Duration(hours: 5))`.
  - Example: `2027-05-10 03:30 PM` (`hour = 15, minute = 30`) → `2027-05-10T20:30:00.000Z`.
  - Example: `2027-05-10 09:00 PM` (`hour = 21, minute = 0`) → `2027-05-11T02:00:00.000Z`.

### 1.3 12-Hour Canonical Formatting (`FR-004`, Clarification Q2)
| 24h Colombia Hour | Minute | Canonical Formatted Output |
|---|---|---|
| `0` | `0` | `12:00 AM` |
| `0` | `30` | `12:30 AM` |
| `8` | `5` | `08:05 AM` |
| `11` | `59` | `11:59 AM` |
| `12` | `0` | `12:00 PM` |
| `12` | `45` | `12:45 PM` |
| `16` | `0` | `04:00 PM` |
| `21` | `0` | `09:00 PM` |
| `23` | `59` | `11:59 PM` |

## 2. Calendar Boundaries (`FR-006`, `FR-008`, Clarification Q1)

| Surface | `firstDate` | `lastDate` | Initial Date |
|---|---|---|---|
| **Match Scheduling (`ScheduleMatchDialog`)** | `ColombiaTimeUtils.todayColombia()` | `DateTime(2100, 12, 31)` | Match's Colombia date (if `>= todayColombia`), otherwise `todayColombia + 1 day` |
| **Matches Calendar (`AppShellScreen`)** | `DateTime(2000, 1, 1)` | `DateTime(2100, 12, 31)` | Currently selected Colombia date in `DailyMatchesFeedController` |
| **Quick Tabs (`MatchdayTabView`)** | `Ayer = todayColombia - 1d` | `Mañana = todayColombia + 1d` | `Hoy = todayColombia` |
