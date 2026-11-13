# Data Model: Panel de Organización — Métricas Exclusivas por Organizador (HU 19.3)

**Feature**: `041-organizer-panel-metrics`  
**Date**: 2026-11-13

## Models

### `OrganizerPanelData` (`lib/presentation/panel/models/panel_presentation_models.dart`)

Modelo inmutable ya existente reutilizado por `organizerPanelMetricsProvider` y `OrganizerPanelContent`:

| Field | Type | Calculation Rule |
|-------|------|------------------|
| `activeTournamentsCount` | `int` | Cantidad de torneos en `organizerTournaments` donde `status == openRegistration \|\| status == inProgress`. |
| `pendingScheduleMatchesCount` | `int` | Cantidad de partidos en `allMatches` donde `organizerTournamentIds.contains(match.tournamentId)` y `match.scheduledStartTime == null`. |
| `unseededTournamentsCount` | `int` | Cantidad de torneos en `organizerTournaments` donde `(status == openRegistration \|\| status == inProgress)` y `!allMatches.any((m) => m.tournamentId == tournament.id)`. |

## Isolation Rule (`organizerTournamentsProvider`)

Sea `sessionUserId = authControllerProvider.session?.user.id`:
- `effectiveUserId = (sessionUserId != null && sessionUserId.trim().isNotEmpty) ? sessionUserId : 'org-seed-1'`
- Predicado de inclusión: `(tournament.organizerId ?? 'org-seed-1') == effectiveUserId`
