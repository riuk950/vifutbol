# Implementation Plan: Eliminación de Cuenta con Borrado en Cascada (Local y Nube)

**Branch**: `056-account-cascade-deletion` | **Date**: 2026-11-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/056-account-cascade-deletion/spec.md`

## Summary

Implementar el flujo completo de **Eliminación de cuenta con borrado en cascada (local y nube)** para usuarios autenticados desde `ProfileTabView`. En la nube (Supabase `vifutboldev`), se crea una migración SQL con un procedimiento RPC `SECURITY DEFINER` (`vifutboldev.delete_my_account()`) que valida `auth.uid()`, elimina en cascada los registros personales (`user_accounts`, `coach_profiles`, `organizer_profiles`, `fan_profiles`, `fan_favorite_teams`, `team_join_requests`, perfiles de jugador agente libre y archivos en los buckets `player-avatars` y `player-documents`), desvincula (`NULL`) las referencias en registros históricos compartidos (torneos, equipos, sedes, actas oficiales, jugadores inscritos en torneos y árbitros) y finalmente elimina al usuario de `auth.users`. En el cliente Flutter, se expone `deleteAccount` en `AuthRepository` (`SupabaseAuthRepository` y `LocalAuthRepository`), `DeleteAccountUseCase` y `AuthController` con verificación previa de conectividad, bloqueo `single-flight`, aborto seguro ante fallos remotos, limpieza completa del namespace Hive (`storage.clearNamespace()` + borrado de archivos locales temporales) únicamente tras éxito remoto, y diálogo destructivo `DeleteAccountDialog` visible solo para usuarios autenticados en `ProfileTabView`.

## Technical Context

**Language/Version**: Dart SDK `^3.12.0` / Flutter + PostgreSQL (Supabase SQL migrations)

**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `supabase_flutter: ^2.18.3`, `hive_flutter: ^1.1.0`, `connectivity_plus: ^6.1.4`, `material_ui: ^1.2.0`, `flutter_localizations`

**Storage**: Supabase PostgreSQL (`vifutboldev` + `auth.users`) + Supabase Storage (`player-avatars`, `player-documents`) + Hive (`HiveLocalStorageRepository` namespace + `HiveSyncOutboxRepository`)

**Testing**: `flutter_test`, `mocktail: ^1.0.4`

**Target Platform**: Android (API 21+) e iOS (entornos `dev` y `prod`)

**Project Type**: Mobile app (Flutter Clean Architecture + Supabase backend SQL migrations)

**Performance Goals**: Validación offline inmediata (<50 ms); eliminación remota atómica en una sola transacción RPC; limpieza local completa en <100 ms

**Constraints**: Conectividad obligatoria en modo nube; fallo remoto aborta borrado local; bloqueo `single-flight` contra envíos duplicados; preservación de integridad referencial de torneos/actas históricas (`SET NULL`); cero exposición de tokens/errores técnicos; UI en español vía `l10n`, código y pruebas en inglés

**Scale/Scope**: 1 migración SQL RPC, 1 caso de uso (`DeleteAccountUseCase`), extensión de `AuthRepository`/`SupabaseAuthRepository`/`LocalAuthRepository`/`AuthController`, 1 diálogo modal destructivo (`DeleteAccountDialog`), integración en `ProfileTabView`, llaves `l10n`, y pruebas unitarias + widget

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación Pre-Diseño | Evaluación Post-Diseño | Evidencia |
|---|---|---|---|
| **I. La Spec Manda (SDD)** | PASS | PASS | `spec.md` clarificado (`Q1=A`, `Q2=A`) con 16/16 checks y criterios de `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | PASS | El RPC elimina datos personales en cascada y desvincula (`NULL`) referencias en torneos, equipos, sedes, actas oficiales y jugadores inscritos, manteniendo determinismo de tablas de posiciones. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | PASS | Pruebas unitarias para `DeleteAccountUseCase`, `SupabaseAuthRepository.deleteAccount`, `LocalAuthRepository.deleteAccount`, `AuthController.deleteAccount` (éxito, offline, error remoto, single-flight) y pruebas de widget en `ProfileTabView`. |
| **IV. Arquitectura Limpia** | PASS | PASS | Separación estricta: contrato en `domain/`, caso de uso y controlador en `application/`, adaptadores Supabase/Local en `infrastructure/`, UI en `presentation/`. |
| **V. Segregación de Roles y Fidelidad a DESIGN.md** | PASS | PASS | Botón visible solo para usuarios autenticados (oculto a visitantes); RPC valida `auth.uid()`; estilo destructivo conforme a `KickPulseColors.accentLive` y tokens de `DESIGN.md`. |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | PASS | Código, migraciones, identificadores y pruebas en inglés; 100% de textos visibles en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | PASS | PASS | Bloqueo offline previo, aborto seguro ante fallo remoto, `single-flight`, `PopScope` durante ejecución, limpieza de outbox y archivos locales, y accesibilidad `≥ 44 px`. |

**Gate Status**: PASS (0 violaciones).

## Project Structure

### Documentation (this feature)

```text
specs/056-account-cascade-deletion/
├── plan.md                                  # Este archivo (/speckit-plan)
├── research.md                              # Fase 0: análisis de FKs, Storage, Hive y single-flight
├── data-model.md                            # Fase 1: mapa de cascada (DELETE vs SET NULL)
├── quickstart.md                            # Fase 1: guía de validación ejecutable
├── contracts/
│   └── delete_account_contract.md           # Fase 1: contrato RPC, repositorio y UI
├── checklists/
│   └── requirements.md                      # Checklist de calidad de especificación
└── tasks.md                                 # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
supabase/
└── migrations/
    └── 202611250001_delete_user_account_cascade.sql  # RPC SECURITY DEFINER vifutboldev.delete_my_account()

lib/
├── domain/
│   └── repositories/
│       └── auth_repository.dart                      # Agregar Future<void> deleteAccount({required String userId})
├── application/
│   ├── use_cases/
│   │   └── delete_account_use_case.dart              # Caso de uso dedicado con validación de sesión autenticada
│   ├── providers/
│   │   └── auth_providers.dart                       # Exponer deleteAccountUseCaseProvider
│   └── controllers/
│       └── auth_controller.dart                      # Método deleteAccount() con bloqueo single-flight
├── infrastructure/
│   └── auth/
│       ├── supabase_auth_repository.dart             # deleteAccount() + método deleteAccount en data source RPC + limpieza local
│       └── local_auth_repository.dart                # deleteAccount() con limpieza total del namespace Hive y archivos locales
├── l10n/
│   ├── app_es.arb                                    # Llaves en español para botón, diálogo, carga, offline y error
│   ├── app_localizations.dart                        # Regenerado con flutter gen-l10n
│   └── app_localizations_es.dart                     # Regenerado con flutter gen-l10n
└── presentation/
    └── shell/
        └── tabs/
            ├── profile_tab_view.dart                 # Botón destructivo Eliminar cuenta (solo autenticados)
            └── widgets/
                └── delete_account_dialog.dart        # Diálogo de confirmación irreversible con estado de carga

test/
├── application/
│   └── auth_controller_test.dart                     # Pruebas de AuthController.deleteAccount (éxito, offline, error, single-flight)
├── infrastructure/
│   ├── local_auth_repository_test.dart               # Pruebas de borrado en cascada local (sesión, cuentas, outbox, namespace)
│   └── supabase_auth_repository_test.dart            # Pruebas de borrado remoto + local, bloqueo offline y aborto ante error remoto
└── presentation/
    └── shell/
        └── profile_tab_view_test.dart                # Pruebas de widget (visibilidad autenticado vs visitante, confirmación, cancelación, error y éxito)
```

**Structure Decision**: Se sigue la arquitectura limpia en 4 capas del repositorio y la convención de migraciones SQL de `supabase/migrations/`. `storage.clearNamespace()` en `HiveLocalStorageRepository` purga de manera atómica toda la caja del entorno activo (`auth_session`, `auth_accounts`, `auth_passwords`, `sync_outbox_items_v1` y cachés de repositorios locales), evitando dejar claves huérfanas.

## Complexity Tracking

No aplica — 0 violaciones a la Constitución del proyecto.
