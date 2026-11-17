# Quickstart Validation Guide: Planilla, Solicitudes y Habilitación (HU 20.1)

**Feature**: `044-coach-roster-eligibility`

## Prerequisites

1. Base de datos Supabase DEV (`vifutboldev`) migrada con `supabase/migrations/202611170001_team_join_requests.sql` y caché PostgREST recargada (`NOTIFY pgrst, 'reload schema'`).
2. Localizaciones regeneradas tras actualizar `lib/l10n/app_es.arb` (`flutter gen-l10n`).
3. Al menos un usuario `coach` con un equipo y al menos un usuario con rol `player` registrado en `user_accounts`.

## Validation Scenarios

### 1. Navegación desde Panel Técnico
1. Iniciar sesión con rol `coach` y al menos un club asignado.
2. En el Panel Técnico, pulsar **"Gestionar Planilla"**.
3. **Resultado esperado**: Navega inmediatamente a `TeamRosterDetailScreen` (`/tournaments/teams/detail`) mostrando el nombre, escudo, estado y conteo de jugadores del equipo seleccionado (sin SnackBar provisional).

### 2. Envío de Solicitud y Aceptación por Jugador (`player`)
1. En `TeamRosterDetailScreen`, pulsar **"Agregar Jugador"**.
2. Buscar un jugador registrado con rol `player`, elegir dorsal disponible (1-99) y posición, y enviar la solicitud.
3. Verificar que la solicitud aparece como **"Solicitud enviada (Pendiente)"** y que el contador hacia los 11 jugadores **aún no incrementa**.
4. Cambiar o iniciar sesión con la cuenta del jugador (`UserRole.player`), abrir la pestaña/sección **Perfil** -> **"Solicitudes de Equipos"** y pulsar **"Aceptar"**.
5. **Resultado esperado**: La solicitud pasa a `accepted`, el jugador aparece en la nómina del equipo y el contador incrementa (`+1`).

### 3. Validación de Cuota Mínima (`< 11`) y Habilitación (`>= 11`)
1. Con menos de 11 jugadores aceptados en plantilla (ej. 8), revisar la tarjeta de estado en `TeamRosterDetailScreen`.
2. **Resultado esperado**: Se muestra `"No elegible / Faltan jugadores"` (`8/11 jugadores mínimos`) y la acción **"Habilitar para Competiciones"** está bloqueada.
3. Con 11 o más jugadores aceptados, pulsar **"Habilitar para Competiciones"**.
4. **Resultado esperado**: El equipo transiciona a estado `eligible`, persiste localmente y en Supabase, y queda apto para el fixture.

## Automated Checks

```bash
flutter analyze
flutter test test/unit/application/coach_roster_eligibility_test.dart test/presentation/teams/team_roster_detail_screen_test.dart test/presentation/shell/profile_team_requests_test.dart
```
