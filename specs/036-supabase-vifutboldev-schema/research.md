# Research: Creación y Aprovisionamiento del Esquema `vifutboldev` en Supabase Self-Hosted (HU 17.2)

**Feature**: `036-supabase-vifutboldev-schema`  
**Date**: 2026-11-11  
**Branch**: `develop`

---

## 1. Diagnóstico Real del Servidor Self-Hosted en Oracle Cloud (`157.137.227.250`)

- **Decision**: Aprovisionar el esquema `vifutboldev` directamente sobre `supabase-db` vía SSH/Docker, actualizar `PGRST_DB_SCHEMAS` en `/home/ubuntu/supabase/docker/.env`, reiniciar `supabase-rest`, y dirigir las consultas de salud y cliente Flutter en DEV hacia recursos de `vifutboldev` (ej. `/rest/v1/tournaments?select=id&limit=1` con `Accept-Profile: vifutboldev`) sin debilitar el ACL administrativo de Kong sobre la raíz OpenAPI `/rest/v1/`.
- **Rationale**:
  - Inspección de solo lectura realizada sobre `ubuntu@157.137.227.250` (`/home/ubuntu/supabase/docker`):
    - Todos los servicios Supabase (`supabase-db`, `supabase-kong`, `supabase-rest`, `supabase-auth`, `supabase-meta`, `supabase-studio`, `supabase-pooler`, `supabase-storage`) están saludables.
    - La BD `postgres` ya contiene otros proyectos aislados por esquema (`public`, `app_futboleros`, `app_vihome`), con privilegios de superusuario disponibles vía `supabase_admin` (`rolsuper = t`, `rolcreatedb = t`).
    - En `supabase-rest`, actualmente `PGRST_DB_SCHEMAS=public,graphql_public`. Por ello `vifutboldev` debe agregarse explícitamente y reiniciarse `supabase-rest`.
    - En `/home/kong/temp.yml`, la ruta `rest-v1-openapi` (`http.path == "/rest/v1/"`) permite solo `admin` (medida oficial de Supabase self-hosted para no exponer el esquema OpenAPI completo a usuarios anónimos), mientras la ruta `rest-v1` (`/rest/v1/*`) **ya permite `anon` y `admin`**. Comprobado en vivo: `GET /rest/v1/sutekh?limit=1` con la `anonKey` de `.env.dev` responde **`HTTP 200 OK`**.
- **Alternatives Considered**:
  - *Abrir `rest-v1-openapi` (`/rest/v1/`) al rol `anon` en Kong*: Descartado por debilitar la postura de seguridad por defecto de Supabase y exponer el catálogo OpenAPI completo de todos los esquemas a Internet.
  - *Crear una base de datos PostgreSQL separada para `vifutboldev`*: Descartado como BD principal de la pila porque Kong/GoTrue/PostgREST/Studio de la instancia Docker apuntan a la BD `postgres`, donde el patrón establecido para proyectos aislados es crear esquemas dedicados (`app_futboleros`, `app_vihome`).

---

## 2. Arquitectura de Seguridad RLS y Rendimiento en PostgreSQL 17

- **Decision**: Aplicar RLS estricto al 100% de las 18 tablas de `vifutboldev` desde el primer despliegue, utilizando:
  - Función auxiliar `SECURITY DEFINER` `vifutboldev.current_user_has_role(allowed_roles text[])` con `SET search_path = ''`, consultando `vifutboldev.user_accounts` mediante `(select auth.uid())`, revocando `EXECUTE` a `PUBLIC`/`anon` y otorgándolo solo a `authenticated`.
  - Wrapping `(select auth.uid())` y `(select vifutboldev.current_user_has_role(...))` en políticas RLS para evaluación una sola vez por sentencia (`initPlan`), evitando llamadas por fila.
  - Índices B-Tree dedicados sobre todas las columnas de clave foránea, columnas usadas en políticas RLS (`auth_user_id`, `organizer_id`, `coach_id`, `user_id`) y campos frecuentes de filtro/agenda (`scheduled_at`, `tournament_id`, `tournament_team_id`).
- **Rationale**:
  - Alineado directamente con `supabase-postgres-best-practices` (`security-rls-performance.md`, `security-privileges.md`, `schema-foreign-key-indexes.md`) y la Clarificación Q1.
  - Lectura pública controlada (`anon, authenticated`) solo para datos deportivos públicos (torneos, sedes/canchas, equipos, jugadores públicos, partidos, actas/eventos públicos, cuadro de honor, noticias y alertas públicas); bloqueo total de `anon` y aislamiento por dueño/rol para datos sensibles (`user_accounts`, `fan_favorite_teams`, `player_internal_trackings`, `match_lineup_convocations` en borrador).
- **Alternatives Considered**:
  - *Políticas permisivas para `anon` en DEV*: Rechazado explícitamente en Clarificación Q1 por riesgo de olvidar endurecer permisos antes de producción.

---

## 3. Modelo Normalizado por Inscripción (`teams` + `tournament_teams`)

- **Decision**: Separar `vifutboldev.teams` (identidad maestra del club y titularidad `coach_id`) de `vifutboldev.tournament_teams` (participación `(tournament_id, team_id)` con `group_name` y `eligibility_status`), vinculando `players`, `matches`, `match_lineup_convocations`, `digital_match_reports`, `match_events`, `player_internal_trackings` y `season_honor_rolls` al `tournament_team_id` (y/o `team_id` en favoritos).
- **Rationale**:
  - Cumple la Clarificación Q2, refleja la semántica real actual del dominio Flutter (`TournamentTeam` independiente por campeonato) y permite reutilizar clubes maestros entre múltiples torneos sin mezclar nóminas, dorsales ni estados `pendingVerification`/`eligible`.
- **Alternatives Considered**:
  - *Modelo club-céntrico o tabla única plana*: Descartado en Clarificación Q2 por acoplar plantillas de distintos campeonatos o perder el catálogo maestro de clubes.

---

## 4. Configuración del Cliente Flutter y Sonda E2E en DEV

- **Decision**:
  1. Extender `SupabaseConfig` (`lib/domain/entities/app_environment.dart`) con `final String schema` (default `'public'`, configurado por defecto a `'vifutboldev'` en `EnvironmentConfig.development()` y `'public'` en `EnvironmentConfig.production()`, con override opcional `SUPABASE_SCHEMA`).
  2. Configurar `Supabase.initialize(..., postgrestOptions: PostgrestClientOptions(schema: config.supabase.schema))` en `lib/app_bootstrap.dart`.
  3. Mantener compatibilidad regresiva de `SupabaseHealthClient.checkHealth` cuando `config.schema == 'public'` (`/rest/v1/`) y cuando `config.schema != 'public'` (DEV `vifutboldev`) realizar el sondeo contra `'/rest/v1/tournaments?select=id&limit=1'` con `Accept-Profile: ${config.schema}` y `Authorization: Bearer ${config.anonKey}`.
  4. Probar lectura pública real con `anon key` y ciclo real de escritura + lectura + limpieza con usuario de prueba autenticado en GoTrue (`authenticated`), preservando el fallback local Hive si no hay red.
- **Rationale**:
  - Mantiene intactas las pruebas unitarias existentes de HU 17.1 y resuelve el `403` de Kong `/rest/v1/` en DEV al apuntar a una ruta de recurso real del esquema `vifutboldev`.
- **Alternatives Considered**:
  - *Crear una tabla técnica anónima para ping de escritura*: Rechazado en Clarificación Q3 para validar exactamente el flujo de seguridad RLS real con GoTrue.
