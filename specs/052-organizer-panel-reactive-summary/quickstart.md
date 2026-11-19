# Quickstart & Verification Guide: HU 22.4 Reactive Organizer Panel Summary

**Feature**: `052-organizer-panel-reactive-summary`  
**Date**: 2026-11-19

---

## 1. Automated Verification Commands

Run targeted unit and widget tests for HU 22.4:

```bash
flutter test \
  test/unit/application/organizer_panel_metrics_test.dart \
  test/presentation/panel/organizer_panel_widget_test.dart \
  test/presentation/panel/organizer_competitions_addition_verification_test.dart \
  test/presentation/panel/panel_screen_test.dart
```

Run static analysis (must report **0 issues**):

```bash
flutter analyze
```

---

## 2. Manual E2E Validation Scenarios

### Scenario A — Fixture Generation & Match Scheduling Reactivity (US1, SC-001)
1. Sign in as Organizer on DEV (`vifutboldev`).
2. Open **Panel del Organizador** and note "Torneos sin Fixture" and "Partidos por Programar".
3. Open a tournament with no fixture, generate its fixture, and press Back.
4. **Expected**: "Torneos sin Fixture" immediately drops by 1 and "Partidos por Programar" immediately rises by the exact number of generated matches.
5. Schedule 2 matches (date, time, venue, pitch) and press Back.
6. **Expected**: "Partidos por Programar" immediately drops by 2 without restarting the app.

### Scenario B — Competition Lifecycle & Team Count Parity (US2, SC-003)
1. Create a new competition from the Organizer Panel → "Torneos Activos" and "Torneos sin Fixture" immediately increment by 1.
2. Enroll 2 teams into that competition and return to the panel → the competition card immediately shows `2 equipos`.
3. Transition an active competition to "Finalizado" → "Torneos Activos" immediately decrements by 1 and its pending matches are excluded from "Partidos por Programar".

### Scenario C — Cold-Start Hydration & Multi-Organizer Isolation (US3, SC-002, SC-004)
1. Clear local cache and sign in as Organizer A (while Organizer B also owns competitions and matches in `vifutboldev`).
2. Open **Panel del Organizador**.
3. **Expected**: Within 5 seconds, General Summary counters and "Mis Competiciones" hydrate from Supabase showing exclusively Organizer A's competitions, teams, and pending matches.
4. Pull to refresh while offline → cached counters remain intact without crashing.
