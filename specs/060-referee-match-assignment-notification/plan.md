# Implementation Plan: Notificación en el AppBar al Árbitro al Asignarle un Partido

**Branch**: `060-referee-match-assignment-notification` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/060-referee-match-assignment-notification/spec.md`

## Summary

Implementar de extremo a extremo la notificación in-app en la campana del AppBar cuando un organizador asigna o reasigna un partido a un árbitro:
1. **Base de datos y trigger idempotente en Supabase (`202611250005_referee_match_assignment_notifications.sql`)**:
   - Extender `vifutboldev.match_live_alerts` con `recipient_user_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE` (nullable para alertas globales de aficionados) y permitir el valor `'refereeMatchAssigned'` en `alert_type`.
   - Configurar políticas RLS de lectura/actualización para que cada usuario autenticado solo lea y marque como leídas alertas globales (`recipient_user_id IS NULL`) o sus propias alertas dirigidas (`recipient_user_id = current_user_account_id`).
   - Crear trigger `AFTER INSERT OR UPDATE OF referee_id ON vifutboldev.matches` (`SECURITY DEFINER`) que, únicamente cuando `NEW.referee_id IS NOT NULL` y cambie respecto a `OLD.referee_id`, resuelva `match_referees.user_account_id`, nombres reales de equipos, torneo, fecha/hora en Colombia (`America/Bogota`) y cancha, e inserte la notificación `'Nuevo partido asignado'` dirigida al nuevo árbitro (omitiendo silenciosamente si `user_account_id IS NULL`).
2. **Dominio, Caso de Uso y Repositorios (Offline-First + Local)**:
   - Agregar `MatchAlertType.refereeMatchAssigned` y campo opcional `recipientUserId` en `MatchLiveAlert` (serializado en JSON local y PostgREST `recipient_user_id`).
   - Agregar campo opcional `userAccountId` en `MatchReferee` (hidratado desde `match_referees.user_account_id`).
   - Filtrar alertas en `LocalMatchAlertsRepository` por `recipientUserId == null || recipientUserId == userId` para garantizar aislamiento por usuario también en caché local.
   - Crear servicio puro `RefereeAssignmentNotificationService` para construir notificaciones de asignación de forma determinista e idempotente (sin duplicados cuando no cambia `refereeId`) y emitir la alerta localmente en `FixtureSchedulingUseCase` cuando `matchAlertsRepository` esté disponible en entornos locales/pruebas.
3. **AppBar y Bandeja (`AppShellScreen`, `FanAlertsBellAction`, `FanAlertsTraySheet`)**:
   - Pasar el `userId` real del usuario autenticado (`authState.session?.user.id`) a `FanAlertsBellAction` en `AppShellScreen` (reemplazando el placeholder `'user-active-current'`) y recargar la bandeja en `didUpdateWidget` cuando cambie `userId`.
   - Mostrar badge numérico compacto (`99+` si supera 99) en `FanAlertsBellAction` y renderizar `MatchAlertType.refereeMatchAssigned` en `FanAlertsTraySheet`.
   - Al tocar una notificación de tipo `refereeMatchAssigned`: marcarla como leída con protección `single-flight`, cerrar la bandeja y abrir directamente `DigitalMatchReportScreen(initialMatch: match)` cuando el partido esté disponible (con respaldo seguro a `AppShellSection.panel` si no se encuentra).

## Technical Context

**Language/Version**: Dart 3.x / Flutter (Mobile iOS & Android) + PostgreSQL 17 (Supabase `vifutboldev` schema)

**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `hive`, `flutter_localizations` (`lib/l10n/app_es.arb`), `KickPulse` Design System (`DESIGN.md`)

**Storage**:
- Remoto: Supabase (`vifutboldev.match_live_alerts` con `recipient_user_id` + trigger en `vifutboldev.matches` + RLS por destinatario).
- Local: Hive (`LocalMatchAlertsRepository` filtrado por `userId` + `HybridMatchAlertsRepository` con `SyncOutbox` para `markAsRead` / `markAllAsRead` offline).

**Testing**: `flutter test` (pruebas unitarias para `RefereeAssignmentNotificationService`, `LocalMatchAlertsRepository` aislamiento por usuario y `FixtureSchedulingUseCase` idempotencia; pruebas de widget para `FanAlertsBellAction` y `FanAlertsTraySheet`) y `flutter analyze`.

**Target Platform**: Android & iOS (Flutter mobile app).

**Project Type**: Mobile app (Clean Architecture).

**Performance Goals**: Renderizado a 60 fps; badge reactivo instantáneo desde stream local; trigger SQL ligero sin bloquear `matches` upsert.

**Constraints**:
- Idempotencia estricta: editar fecha/hora/cancha sin cambiar `refereeId` genera 0 notificaciones nuevas.
- Privacidad: cada usuario solo lee/marca como leídas sus propias notificaciones dirigidas.
- Offline-first: notificaciones recibidas permanecen consultables y marcables como leídas sin conexión.
- Código técnico y pruebas en inglés; UI en español vía `lib/l10n/app_es.arb`.

**Scale/Scope**: 1 migración SQL idempotente, 1 servicio puro de dominio, actualización de entidades/repositorios de alertas, `FixtureSchedulingUseCase`, `AppShellScreen`, `FanAlertsBellAction`, `FanAlertsTraySheet`, ~4 claves en `app_es.arb` y pruebas unitarias/widget.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (SDD)**: PASS — `spec.md` y clarificaciones (`2026-11-25`) aprobadas (16/16 en `checklists/requirements.md`).
- **II. Integridad de Datos y Fuente de Verdad Transparente**: PASS — Trigger SQL y aislamiento `recipient_user_id` garantizan consistencia entre `matches`, `match_referees` y `match_live_alerts`.
- **III. Pruebas Automatizadas como Puerta de Calidad**: PASS — Pruebas unitarias de creación idempotente, aislamiento y lectura, más pruebas de widget de campana, badge `99+`, bandeja y navegación directa/respaldo.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: PASS — Lógica de construcción/idempotencia en servicio de dominio; persistencia en repositorios híbridos; presentación reactiva vía Riverpod.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: PASS — RLS en Supabase + filtro por `recipientUserId` local; tokens `KickPulse*` en badge y bandeja.
- **VI. Convenciones de Idioma y Nomenclatura**: PASS — Código en inglés, textos visibles en español vía `AppLocalizations`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: PASS — Offline-first, `single-flight` en tap de alerta, badge `99+`, `Semantics` accesibles y respaldo seguro al Panel si el partido no existe.

**Post-Design Re-check**: PASS — Sin violaciones ni excepciones de complejidad.

## Project Structure

### Documentation (this feature)

```text
specs/060-referee-match-assignment-notification/
├── plan.md                                         # Este archivo
├── research.md                                     # Decisiones técnicas y alternativas
├── data-model.md                                   # Esquema SQL, RLS, trigger y entidades
├── quickstart.md                                   # Guía de verificación end-to-end
├── contracts/
│   └── referee_assignment_notification_contract.md # Contratos de servicio, UI keys y l10n
└── checklists/
    └── requirements.md                             # Checklist de calidad
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611250005_referee_match_assignment_notifications.sql

lib/
├── l10n/
│   ├── app_es.arb                                            # Nuevas claves en español para alerta arbitral
│   ├── app_localizations.dart                                # Generado por flutter gen-l10n
│   └── app_localizations_es.dart                             # Generado por flutter gen-l10n
├── domain/
│   ├── entities/
│   │   ├── match_alert_type.dart                             # Nuevo valor refereeMatchAssigned
│   │   ├── match_live_alert.dart                             # Campo opcional recipientUserId
│   │   └── match_referee.dart                                # Campo opcional userAccountId
│   └── services/
│       └── referee_assignment_notification_service.dart      # Construcción determinista e idempotente de alerta arbitral
├── application/
│   └── use_cases/
│       └── fixture_scheduling_use_case.dart                  # Emisión local/idempotente al asignar/reasignar árbitro
├── infrastructure/
│   └── repositories/
│       ├── local_match_alerts_repository.dart                # Filtrado estricto por recipientUserId == null || == userId
│       ├── hybrid_match_alerts_repository.dart               # Mapeo de refereeMatchAssigned y recipient_user_id
│       └── hybrid_tournament_matches_repository.dart         # Hidratación de user_account_id en fetchOfficialReferees
└── presentation/
    ├── shell/
    │   └── app_shell_screen.dart                             # Pasar userId real a FanAlertsBellAction
    └── alerts/widgets/
        ├── fan_alerts_bell_action.dart                       # Badge 99+, didUpdateWidget, deep link directo a acta con fallback a Panel, single-flight
        └── fan_alerts_tray_sheet.dart                        # Renderizado de refereeMatchAssigned + protección doble tap

test/
├── domain/services/
│   └── referee_assignment_notification_service_test.dart
├── infrastructure/repositories/
│   └── local_match_alerts_repository_test.dart
└── presentation/alerts/
    └── referee_alerts_bell_and_tray_test.dart
```

**Structure Decision**: Se extiende el sistema existente de `MatchLiveAlert` / `FanAlertsBellAction` / `FanAlertsTraySheet` con direccionamiento por usuario (`recipient_user_id`) y trigger SQL idempotente, evitando crear una segunda bandeja o tabla duplicada de notificaciones.

## Complexity Tracking

Sin violaciones a la Constitución; no se requieren excepciones.
