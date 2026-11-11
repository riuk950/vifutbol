# Contracts: Aprovisionamiento `vifutboldev` y Cliente DEV Flutter (HU 17.2)

**Feature**: `036-supabase-vifutboldev-schema`  
**Date**: 2026-11-11  

---

## 1. Contrato de Migraciones SQL Versionadas (`supabase/migrations/`)

| Orden | Archivo | Responsabilidad e Idempotencia |
|-------|---------|--------------------------------|
| 1 | `supabase/migrations/202611110001_create_vifutboldev_schema.sql` | `CREATE SCHEMA IF NOT EXISTS vifutboldev`, `pgcrypto`, función trigger `vifutboldev.set_updated_at()`, función helper `SECURITY DEFINER` `vifutboldev.current_user_has_role(text[])` (`SET search_path = ''`, solo ejecutable por `authenticated`), y `GRANT USAGE ON SCHEMA vifutboldev TO anon, authenticated, service_role`. |
| 2 | `supabase/migrations/202611110002_create_vifutboldev_tables_and_indexes.sql` | `CREATE TABLE IF NOT EXISTS vifutboldev.<tabla>` para las 18 entidades, `CREATE INDEX IF NOT EXISTS` en todas las FKs y columnas de RLS/consulta frecuente, y creación idempotente de triggers `BEFORE UPDATE`. |
| 3 | `supabase/migrations/202611110003_enable_rls_and_policies.sql` | `GRANT`s de tabla y `ALTER DEFAULT PRIVILEGES IN SCHEMA vifutboldev`, `ENABLE ROW LEVEL SECURITY` en las 18 tablas, y `DROP POLICY IF EXISTS` + `CREATE POLICY` por rol (`(select auth.uid())`, `(select vifutboldev.current_user_has_role(...))`). |
| 4 | `supabase/migrations/202611110004_seed_vifutboldev_dev_data.sql` | Datos semilla mínimos deterministas para DEV (`INSERT ... ON CONFLICT DO NOTHING`) para pruebas de lectura pública y referencia en Studio/Flutter DEV. |

---

## 2. Matriz de Políticas RLS por Tabla

| Tabla | `anon` (`SELECT`) | `authenticated` (`SELECT`) | Escritura (`INSERT` / `UPDATE` / `DELETE`) |
|-------|-------------------|----------------------------|---------------------------------------------|
| `user_accounts` | Denegado | Propio perfil (`auth_user_id = (select auth.uid())`) o `organizer` | Propio perfil (`authenticated`) u `organizer` |
| `fan_favorite_teams` | Denegado | Dueño (`user_id` vinculado a `(select auth.uid())`) | Dueño autenticado |
| `sports_venues`, `venue_pitches` | Permitido | Permitido | Solo `organizer` |
| `tournaments`, `rule_audit_entries`, `season_honor_rolls`, `tournament_news` | Permitido | Permitido | Solo `organizer` |
| `teams` | Permitido | Permitido | `coach` propietario (`coach_id`) u `organizer` |
| `tournament_teams` | Permitido | Permitido | `organizer` (inscripción, traslado grupo, elegibilidad) o `coach` del club en inscripción abierta |
| `players` | Permitido | Permitido | `coach` dueño del club participante u `organizer` |
| `player_internal_trackings` | Denegado | Solo `coach` dueño o el propio jugador (`user_account_id`) o `organizer` | `coach` dueño u `organizer` |
| `match_referees` | Permitido | Permitido | Solo `organizer` |
| `matches` | Permitido | Permitido | `organizer` (fixture/programación), `referee`/`organizer` (estado/marcador en juego) |
| `match_lineup_convocations` | Denegado | `coach` dueño (borrador/confirmado); `organizer`/`referee` si `status = 'confirmed'` | Solo `coach` dueño de la inscripción del equipo |
| `digital_match_reports`, `match_events` | Permitido | Permitido | `referee` o `organizer` |
| `match_live_alerts` | Permitido | Permitido | `organizer` o `referee` |

---

## 3. Contrato del Cliente Flutter (`SupabaseConfig`, `bootstrapApp`, `SupabaseHealthClient`)

### 3.1 `SupabaseConfig` (`lib/domain/entities/app_environment.dart`)
```dart
class SupabaseConfig {
  final String url;
  final String anonKey;
  final String schema;

  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.schema = 'public',
  });

  const SupabaseConfig.empty()
      : url = '',
        anonKey = '',
        schema = 'public';
}
```
- `EnvironmentConfig.development()` resuelve `SUPABASE_SCHEMA` con default `'vifutboldev'`.
- `EnvironmentConfig.production()` resuelve `SUPABASE_SCHEMA` con default `'public'`.
- `toSafeDiagnosticMap()` expone `'schema': schema` manteniendo `'anonKey': '[REDACTED]'`.

### 3.2 `bootstrapApp` (`lib/app_bootstrap.dart`)
```dart
await Supabase.initialize(
  url: config.supabase.url,
  anonKey: config.supabase.anonKey,
  postgrestOptions: PostgrestClientOptions(schema: config.supabase.schema),
);
```

### 3.3 `SupabaseHealthClient.checkHealth` (`lib/infrastructure/network/supabase_health_client.dart`)
- Cuando `config.schema == 'public'`: mantiene compatibilidad regresiva con `GET <url>/rest/v1/` y cabeceras `apikey` + `Accept: application/openapi+json, application/json`.
- Cuando `config.schema != 'public'` (DEV `'vifutboldev'`): consulta `GET <url>/rest/v1/tournaments?select=id&limit=1` con cabeceras:
  - `'apikey': config.anonKey`
  - `'Authorization': 'Bearer ${config.anonKey}'`
  - `'Accept-Profile': config.schema`
  - `'Accept': 'application/json'`
  Esto valida en una sola petición Kong ACL (`rest-v1`), exposición de `PGRST_DB_SCHEMAS`, esquema `vifutboldev`, Postgres y política RLS de lectura pública.

---

## 4. Contrato de Servidor Docker en Oracle Cloud DEV

- Archivo `/home/ubuntu/supabase/docker/.env`: agregar `,vifutboldev` a `PGRST_DB_SCHEMAS` (pasando de `public,graphql_public` a incluir `vifutboldev`).
- Reiniciar contenedor `supabase-rest` (`sudo docker compose up -d rest`) manteniendo `public`, `app_futboleros`, `app_vihome` y la política de seguridad de `rest-v1-openapi` intactas.
