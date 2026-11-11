# Implementation Plan: Creación y Aprovisionamiento del Esquema `vifutboldev` en Supabase Self-Hosted (HU 17.2)

**Branch**: `develop` | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)  
**Feature Directory**: `specs/036-supabase-vifutboldev-schema`  
**Notion Target Card**: `[Épica 17] HU 17.2` (`4158442e-3f49-81d8-8934-fb295990ac7d`)  

---

## Summary

Diseñar, versionar, aprovisionar y exponer el esquema PostgreSQL aislado `vifutboldev` dentro de la instancia self-hosted de Supabase en Oracle Cloud (`ubuntu@157.137.227.250`, contenedor `supabase-db`), separando completamente todas las tablas de `vifutbol` respecto a `public`, `app_futboleros` y `app_vihome`. Se generarán 4 scripts SQL idempotentes en `supabase/migrations/` cubriendo las 18 entidades del dominio con llaves UUID, triggers `updated_at`, índices B-Tree en todas las FKs y políticas RLS estrictas por rol optimizadas mediante `(select auth.uid())` y función `SECURITY DEFINER` cacheada. En el servidor Docker DEV se agregará `vifutboldev` a `PGRST_DB_SCHEMAS` reiniciando `supabase-rest`, y en Flutter se extenderá `SupabaseConfig`, `bootstrapApp` y `SupabaseHealthClient` para operar en DEV sobre el schema `vifutboldev` manteniendo producción (`public`) y el fallback offline (Hive) completamente aislados, validando finalmente lectura anónima pública y escritura/limpieza autenticada real contra DEV.

---

## Technical Context

**Language/Version**: PostgreSQL 17 (Supabase self-hosted) + Dart ^3.12.0 (Flutter SDK)  
**Primary Dependencies**: `supabase_flutter` (^2.18.3), `http` (^1.2.0), `flutter_riverpod` (^2.6.1), Docker Compose + Kong + PostgREST (`supabase-rest`) + GoTrue (`supabase-auth`)  
**Storage**: Esquema dedicado `vifutboldev` en `supabase-db` (DEV) + almacenamiento local Hive (offline-first fallback)  
**Testing**: `flutter_test`, `mocktail`, `psql` idempotency checks, pruebas HTTP REST (`Accept-Profile: vifutboldev`) y E2E autenticado con GoTrue  
**Target Platform**: Servidor Ubuntu OCI (Docker) + Android/iOS (`vifutbol` Flutter DEV client)  
**Project Type**: Backend Schema Provisioning + Mobile App Client Integration  
**Performance Goals**:
- Evaluación RLS optimizada mediante `(select auth.uid())` y función `SECURITY DEFINER` con `SET search_path = ''` evitando re-evaluaciones por fila.
- Índices B-Tree dedicados en 100% de las claves foráneas y filtros frecuentes (`scheduled_at`, `tournament_id`, `tournament_team_id`, `organizer_id`, `coach_id`).
**Constraints**:
- Cero tablas de negocio de `vifutbol` en `public`.
- Cero impacto en esquemas vecinos (`public`, `app_futboleros`, `app_vihome`) ni en `.env.prod`.
- Conservar `rest-v1-openapi` (`/rest/v1/`) protegido (`admin`) en Kong sin exponer OpenAPI públicamente; validar salud DEV en `/rest/v1/tournaments?select=id&limit=1` con `Accept-Profile: vifutboldev`.
- Scripts SQL 100% idempotentes (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`, `ON CONFLICT DO NOTHING`).
- Cero credenciales o secretos en el repositorio ni en logs.  
**Scale/Scope**: 4 migraciones SQL en `supabase/migrations/`, actualización de `PGRST_DB_SCHEMAS` en Oracle Cloud DEV, y configuración de schema en `SupabaseConfig` / `app_bootstrap.dart` / `SupabaseHealthClient` + pruebas unitarias.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Plan Compliance (Pre-Research & Post-Design) | Status |
|---|---|---|---|
| **I. La Spec Manda** | Basado en `spec.md`, clarificaciones y `docs/MOBILE_GUIDELINES.md`. | Todos los requisitos (`FR-001`..`FR-010`) y las 3 clarificaciones de sesión están cubiertos en diseño, contratos y migraciones. | **PASS** |
| **II. Integridad de Datos** | Integridad referencial estricta entre entidades deportivas e identificadores únicos. | Llaves primarias UUID, FKs explícitas con `ON DELETE` apropiado, restricciones `UNIQUE` (dorsal/equipo, documento/torneo, inscripción/torneo) y checks de consistencia. | **PASS** |
| **III. Pruebas como Puerta** | Pruebas automatizadas unitarias, verificación DDL/RLS idempotente y E2E DEV. | Pruebas unitarias en Flutter (`supabase_providers_test.dart`, `check_supabase_backend_health_use_case_test.dart`, `supabase_bootstrap_resilience_test.dart`), validación SQL idempotente y prueba REST/GoTrue E2E. | **PASS** |
| **IV. Arquitectura Limpia** | Separación Dominio / Aplicación / Infraestructura. | Configuración de entorno en `SupabaseConfig` (Dominio), inicialización en `app_bootstrap.dart`, sonda HTTP en `SupabaseHealthClient` (Infraestructura) sin acoplar reglas de negocio. | **PASS** |
| **V. Segregación de Roles y Diseño** | Segregación estricta de los 5 roles en lógica y seguridad. | RLS obligatorio en las 18 tablas con políticas diferenciadas para `Organizador`, `Entrenador`, `Árbitro`, `Jugador` y `Aficionado`/`anon`. | **PASS** |
| **VI. Convenciones de Idioma** | Código técnico, SQL e identificadores en inglés; textos de usuario en español. | Tablas, columnas, políticas, migraciones y pruebas en inglés; mensajes de diagnóstico/UI en español. | **PASS** |
| **VII. Resiliencia y Experiencia Móvil** | Conectividad, aislamiento de entornos y fallback offline. | Aislamiento DEV (`vifutboldev`) vs PROD (`public`), timeout de salud `<= 5s`, fallback automático a Hive sin bloqueo y sin exposición de secretos (`[REDACTED]`). | **PASS** |

**Gate Result (Pre-Research & Post-Design)**: **7 / 7 PASSED**. Sin violaciones constitucionales.

---

## Project Structure

### Documentation (this feature)

```text
specs/036-supabase-vifutboldev-schema/
├── spec.md                                           # Especificación funcional + clarificaciones
├── plan.md                                           # Este plan de implementación
├── research.md                                       # Diagnóstico Oracle Cloud / Kong / RLS (Phase 0)
├── data-model.md                                     # Modelo relacional completo de 18 tablas (Phase 1)
├── quickstart.md                                     # Comandos y checklist de validación (Phase 1)
├── contracts/
│   └── vifutboldev-schema-contracts.md               # Contratos SQL, matriz RLS y cliente Flutter (Phase 1)
├── checklists/
│   └── requirements.md                               # Checklist 16/16 aprobado
└── tasks.md                                          # Tareas ordenadas (generado por /speckit-tasks)
```

### Source Code & Infrastructure (repository root)

```text
supabase/
└── migrations/
    ├── 202611110001_create_vifutboldev_schema.sql          # [NUEVO] Esquema, helper SECURITY DEFINER, trigger updated_at
    ├── 202611110002_create_vifutboldev_tables_and_indexes.sql # [NUEVO] 18 tablas + FKs + índices B-Tree + triggers
    ├── 202611110003_enable_rls_and_policies.sql            # [NUEVO] Grants, default privileges, RLS y políticas por rol
    └── 202611110004_seed_vifutboldev_dev_data.sql          # [NUEVO] Semilla mínima idempotente DEV

.env.dev.example                                            # [ACTUALIZAR] Documentar SUPABASE_SCHEMA=vifutboldev
.env.example                                                # [ACTUALIZAR] Documentar SUPABASE_SCHEMA

lib/
├── domain/entities/app_environment.dart                    # [ACTUALIZAR] Campo schema en SupabaseConfig (DEV='vifutboldev', PROD='public')
├── app_bootstrap.dart                                      # [ACTUALIZAR] PostgrestClientOptions(schema: config.supabase.schema)
└── infrastructure/network/supabase_health_client.dart      # [ACTUALIZAR] Soporte Accept-Profile / recurso vifutboldev en DEV

test/unit/application/
├── supabase_providers_test.dart                            # [ACTUALIZAR] Pruebas de schema en DEV vs PROD y toSafeDiagnosticMap
├── check_supabase_backend_health_use_case_test.dart        # [ACTUALIZAR] Pruebas de sonda con schema 'vifutboldev' vs 'public'
└── supabase_bootstrap_resilience_test.dart                 # [VERIFICAR] Resiliencia con PostgrestClientOptions(schema: ...)
```

**Structure Decision**: Se versionan las migraciones SQL bajo la convención estándar `supabase/migrations/` en la raíz del proyecto, se configura PostgREST en `/home/ubuntu/supabase/docker/.env` vía SSH sobre Oracle Cloud sin alterar contenedores ajenos, y se parametriza `SupabaseConfig.schema` en Flutter para aislar DEV (`vifutboldev`) de PROD (`public`).

---

## Complexity Tracking

> No existen violaciones constitucionales que requieran justificación.
