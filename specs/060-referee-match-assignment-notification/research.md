# Phase 0 Research: Notificación en el AppBar al Árbitro al Asignarle un Partido

**Feature**: `060-referee-match-assignment-notification` (HU 26.2)
**Date**: 2026-11-25

## Decision 1: Extender `vifutboldev.match_live_alerts` con `recipient_user_id` y Trigger SQL `SECURITY DEFINER`

- **Decision**: Agregar la columna nullable `recipient_user_id uuid REFERENCES vifutboldev.user_accounts(id) ON DELETE CASCADE` a `vifutboldev.match_live_alerts`, ampliar el `CHECK` de `alert_type` para incluir `'refereeMatchAssigned'`, configurar RLS para que cada usuario lea/marque únicamente alertas globales (`recipient_user_id IS NULL`) o propias (`recipient_user_id = current_account_id`), y crear un trigger `AFTER INSERT OR UPDATE OF referee_id ON vifutboldev.matches` (`SECURITY DEFINER`) que genere la notificación cuando `NEW.referee_id` sea no nulo y cambie frente a `OLD.referee_id`.
- **Rationale**:
  - Un organizador que programa un partido no necesita permisos RLS de inserción sobre las notificaciones privadas de otro usuario; el trigger `SECURITY DEFINER` resuelve automáticamente `match_referees.user_account_id`, los nombres reales de los equipos (`tournament_teams`), el nombre del torneo (`tournaments`), la hora en `America/Bogota` y `pitch_name`.
  - Si el organizador edita fecha/hora/cancha sin cambiar `referee_id`, el trigger NO se dispara (`OLD.referee_id IS DISTINCT FROM NEW.referee_id`), garantizando idempotencia absoluta en nube (`FR-002`).
  - Si `match_referees.user_account_id IS NULL`, el trigger retorna `NEW` sin error ni alerta huérfana (`FR-003`).
- **Alternatives considered**:
  - Crear una tabla separada `referee_notifications`: rechazado porque fragmentaría la bandeja de la campana del AppBar y duplicaría repositorios híbridos y outbox de sincronización.

## Decision 2: Emisión local complementaria en `FixtureSchedulingUseCase` (modo local/offline y pruebas)

- **Decision**: Crear el servicio puro `RefereeAssignmentNotificationService` con `shouldNotify(previousRefereeId:, newRefereeId:)` y `buildAlert(...)`, e inyectar opcionalmente `MatchAlertsRepository? matchAlertsRepository` (solo para persistencia local cuando no hay sync remoto o en pruebas unitarias) en `FixtureSchedulingUseCase` manteniendo retrocompatibilidad total con constructores existentes.
- **Rationale**:
  - Garantiza que en modo 100% local (sin Supabase) y en pruebas unitarias la lógica de generación, formato en español (hora Colombia) e idempotencia sea directamente verificable sin requerir base de datos remota.
  - Cuando Supabase está activo, el trigger SQL genera la notificación autoritativa en la nube (y el árbitro la recibe al sincronizar/cargar `HybridMatchAlertsRepository.loadAlerts`).
- **Alternatives considered**:
  - Emitir siempre desde el cliente hacia Supabase: rechazado porque obligaría a abrir políticas RLS de `INSERT` entre usuarios distintos y fallaría si el organizador no tuviera en memoria `userAccountId`.

## Decision 3: Corrección de `userId` en `AppShellScreen` y navegación directa con respaldo al Panel

- **Decision**:
  - En `AppShellScreen`, pasar `userId: authState.session?.user.id ?? 'user-active-current'` a `FanAlertsBellAction` (reemplazando el literal hardcoded `'user-active-current'`).
  - En `FanAlertsBellAction`, implementar `didUpdateWidget` para reinicializar el controlador cuando cambie `widget.userId`, mostrar `'99+'` cuando `unread > 99`, proteger el tap contra doble ejecución (`_isNavigating`), y para `MatchAlertType.refereeMatchAssigned` resolver el partido en `matchesCatalogControllerProvider.matches` (o cargándolo con `tournamentMatchesRepositoryProvider.loadMatchesForTournament(alert.tournamentId)`) para abrir directamente `DigitalMatchReportScreen(initialMatch: match)`, con respaldo automático a `AppShellSection.panel` si no se encuentra.
- **Rationale**:
  - Cumple la Clarificación Q1 (`2026-11-25`) y corrige el defecto preexistente donde todas las sesiones compartían `'user-active-current'` en `AppShellScreen`.
- **Alternatives considered**:
  - Navegar siempre a `AppShellSection.matches`: descartado porque el flujo operativo del árbitro requiere abrir directamente el acta del partido asignado (o su Panel Arbitral como respaldo).
