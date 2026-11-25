# Quickstart Validation Guide: HU 26.2 Referee Match Assignment Notification

**Feature**: `060-referee-match-assignment-notification`
**Contracts**: [referee_assignment_notification_contract.md](contracts/referee_assignment_notification_contract.md)
**Data Model**: [data-model.md](data-model.md)

## Prerequisites

- Flutter SDK configurado en `/Volumes/DATA/Development/FlutterProjects/vifutbol`.
- Migración SQL `supabase/migrations/202611250005_referee_match_assignment_notifications.sql` lista (y aplicada en `supabase-db` para pruebas contra nube).

## Automated Validation Commands

1. Regenerar localizaciones tras actualizar `lib/l10n/app_es.arb`:
   ```bash
   flutter gen-l10n
   ```
2. Ejecutar análisis estático sobre los archivos modificados y nuevos:
   ```bash
   flutter analyze lib/domain/entities/match_alert_type.dart \
     lib/domain/entities/match_live_alert.dart \
     lib/domain/entities/match_referee.dart \
     lib/domain/services/referee_assignment_notification_service.dart \
     lib/infrastructure/repositories/local_match_alerts_repository.dart \
     lib/infrastructure/repositories/hybrid_match_alerts_repository.dart \
     lib/infrastructure/repositories/hybrid_tournament_matches_repository.dart \
     lib/presentation/shell/app_shell_screen.dart \
     lib/presentation/alerts/widgets/fan_alerts_bell_action.dart \
     lib/presentation/alerts/widgets/fan_alerts_tray_sheet.dart \
     test/domain/services/referee_assignment_notification_service_test.dart \
     test/infrastructure/repositories/local_match_alerts_repository_test.dart \
     test/presentation/alerts/referee_alerts_bell_and_tray_test.dart
   ```
   **Resultado esperado**: `No issues found!`.
3. Ejecutar la suite de pruebas unitarias y de widget:
   ```bash
   flutter test test/domain/services/referee_assignment_notification_service_test.dart \
     test/infrastructure/repositories/local_match_alerts_repository_test.dart \
     test/presentation/alerts/referee_alerts_bell_and_tray_test.dart
   ```
   **Resultado esperado**: 100% de pruebas aprobadas.

## End-to-End Verification Scenarios

1. **Generación idempotente de alerta**:
   - Asignar un partido al árbitro A → genera notificación `'Nuevo partido asignado'` dirigida a `A.userAccountId`.
   - Editar fecha/cancha sin cambiar árbitro → 0 notificaciones nuevas.
   - Reasignar al árbitro B → genera notificación solo para B.
2. **Campana del AppBar y bandeja**:
   - Iniciar sesión como árbitro → ver badge con conteo de no leídas (y `99+` si >99).
   - Abrir bandeja → ver título `"Nuevo partido asignado"` con equipos, torneo, fecha/hora Colombia y cancha.
3. **Navegación directa y respaldo**:
   - Tocar la notificación cuando el partido existe → marca como leída, decrementa badge y abre `DigitalMatchReportScreen`.
   - Tocar la notificación cuando el partido no está disponible → marca como leída y navega al Panel del Árbitro (`AppShellSection.panel`).
4. **Privacidad y modo offline**:
   - Otro árbitro no ve las notificaciones dirigidas al árbitro A.
   - Marcar como leída funciona localmente offline y persiste tras recarga.
