# Implementation Plan: Formulario de Datos Personales, Ubicación en Colombia y Posiciones Múltiples del Jugador (HU 21.1)

**Branch**: `046-player-personal-data-form` | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/046-player-personal-data-form/spec.md)

**Input**: Feature specification from `/specs/046-player-personal-data-form/spec.md`

## Summary

Implementar la pantalla dedicada de **Datos Personales del Jugador** (`/profile/personal-data`) accesible desde `"Completar mi perfil"` y `"Datos Personales"` en la pestaña Perfil para el rol `UserRole.player`. La solución introduce:
1. Un catálogo local síncrono completo con los 32 departamentos de Colombia más Bogotá D.C. y sus ~1.122 municipios oficiales del DANE con selectores buscables en cascada.
2. El catálogo de 15 demarcaciones tácticas reales del fútbol (`DetailedFootballPosition`) con selección múltiple y derivación determinista a `PlayerPosition`.
3. Cálculo exacto y reactivo de edad en años cumplidos y concatenación armonizada de `fullName` sin espacios dobles.
4. Extensión del modelo `RoleProfileData`, de la regla `UserAccount.isProfileCompleteForActiveRole` para `player` (incluyendo teléfono obligatorio + campos personales/tácticos), de `AuthRepository` / `AuthController`, y migración idempotente de `vifutboldev.players` y del RPC atómico `complete_role_profile` en Supabase.

## Technical Context

**Language/Version**: Dart ^3.12.0 / Flutter (Material 3 + KickPulse Design System)  
**Primary Dependencies**: `flutter_riverpod`, `fluro`, `supabase_flutter`, `intl`, `clock`, `flutter_localizations`  
**Storage**: PostgreSQL (`vifutboldev` schema en Supabase Self-Hosted DEV) + almacenamiento local (`LocalStorageRepository` / Hive) para caché de sesión y modo local  
**Testing**: `flutter_test`, `mocktail` (pruebas unitarias de dominio, infraestructura y widget/responsivas)  
**Target Platform**: Android / iOS (móvil, validado desde 320px/360px hasta 130% de escalado de texto)  
**Project Type**: Mobile app (Clean Architecture en 4 capas: `domain`, `application`, `infrastructure`, `presentation`)  
**Performance Goals**: Cálculo reactivo de edad < 100 ms; filtrado de departamentos y municipios de Colombia 100% síncrono local (< 16 ms)  
**Constraints**: Cero textos hardcodeados en UI (`AppLocalizations` español); identificadores/código/tests en inglés; validación remota de unicidad de `document_id` cuando Supabase está activo (conservando estado del formulario si está offline); sin desbordamientos (`RenderFlex overflow`) en 320px/360px  
**Scale/Scope**: 33 entidades territoriales (32 departamentos + Bogotá D.C.), ~1.122 municipios oficiales del DANE, 15 demarcaciones tácticas, 1 pantalla dedicada + 1 selector modal buscable + 1 migración SQL

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Estado | Evaluación |
|-----------|--------|------------|
| **I. La Spec Manda** | ✓ PASS | `spec.md` completado, clarificado (4 decisiones integradas) y validado 16/16 en `checklists/requirements.md`. |
| **II. Integridad de Datos y Fuente de Verdad Transparente** | ✓ PASS | Vinculación atómica por `normalized_document_id` en `complete_role_profile` RPC impide duplicados y rechaza secuestro de cédula ajena (`DOCUMENT_ALREADY_LINKED`). |
| **III. Pruebas Automatizadas como Puerta de Calidad** | ✓ PASS | Plan incluye pruebas unitarias (edad, nombres, catálogo Colombia, posiciones, completitud), infraestructura (local/Supabase) y widgets (formulario, cascada, multi-selección, responsividad 320px/130%). |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | ✓ PASS | Catálogo geográfico, enums y utilidades puras viven en `lib/domain/`; persistencia en `lib/infrastructure/auth/`; orquestación en `lib/application/`; UI en `lib/presentation/`. |
| **V. Segregación de Roles y Fidelidad al Sistema de Diseño** | ✓ PASS | Flujo exclusivo para `UserRole.player` (demás roles conservan `CompleteProfileDialog`). Componentes usan tokens KickPulse (`KickPulseColors`, `KickPulseTypography`, `KickPulseButton`, `KickPulseCard`). |
| **VI. Convenciones de Idioma y Nomenclatura** | ✓ PASS | Código, enums, rutas, tests y migraciones en inglés; todas las etiquetas, validaciones y nombres de posiciones en pantalla vía `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | ✓ PASS | Cubre protección contra salida con cambios sin guardar (`PopScope`), bloqueo anti-doble envío (`_isSaving`), conservación de formulario ante fallo de red, accesibilidad y 320px a 130% de texto. |

**Post-Design Re-Check**: ✓ Todos los 7 principios se mantienen en estado PASS sin excepciones ni violaciones.

## Project Structure

### Documentation (this feature)

```text
specs/046-player-personal-data-form/
├── plan.md                                      # This file
├── research.md                                  # Phase 0 technical decisions
├── data-model.md                                # Phase 1 domain & SQL schema model
├── quickstart.md                                # Phase 1 validation guide
├── contracts/
│   └── player_personal_data_contract.md         # UI, routes, repository & RPC contracts
├── checklists/
│   └── requirements.md                          # Spec quality checklist
└── tasks.md                                     # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── domain/
│   ├── data/
│   │   └── colombia_municipalities_data.dart          # Complete DANE 32 departments + Bogotá D.C. (~1,122 municipalities)
│   ├── entities/
│   │   ├── colombia_location_catalog.dart             # Search & cascade helpers over Colombian geography
│   │   ├── detailed_football_position.dart            # 15 tactical positions + mapping to PlayerPosition
│   │   ├── player_personal_enums.dart                 # PlayerSex & BloodType enums + tolerant parsers
│   │   ├── role_profile_data.dart                     # Extended with player personal & tactical fields
│   │   └── user_account.dart                          # Updated isProfileCompleteForActiveRole for UserRole.player
│   ├── repositories/
│   │   └── auth_repository.dart                       # Optional fullName param in updateRoleProfile
│   └── services/
│       └── player_personal_data_utils.dart            # Exact age calculator, fullName harmonizer, position derivation
├── application/
│   └── controllers/
│       └── auth_controller.dart                       # Optional fullName forwarding in updateRoleProfile
├── infrastructure/
│   └── auth/
│       ├── local_auth_repository.dart                 # Persists fullName + extended player RoleProfileData
│       └── supabase_auth_repository.dart              # Passes new player fields to complete_role_profile & hydrates from players
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                            # Registers /profile/personal-data
│   └── shell/
│       ├── tabs/
│       │   ├── player_personal_data_screen.dart       # Dedicated full-screen player personal data form
│       │   └── profile_tab_view.dart                  # Routes player banner & "Datos Personales" tile to /profile/personal-data
│       └── widgets/
│           └── searchable_location_picker_sheet.dart  # Reusable searchable modal sheet for department/municipality
└── l10n/
    └── app_es.arb                                     # All Spanish labels, position names, validation & feedback messages

supabase/
└── migrations/
    └── 202611170002_player_personal_profile_fields.sql # Extends vifutboldev.players & updates complete_role_profile RPC

test/
├── unit/
│   ├── domain/
│   │   ├── colombia_location_catalog_test.dart
│   │   ├── detailed_football_position_test.dart
│   │   ├── player_personal_data_utils_test.dart
│   │   └── user_account_role_profile_test.dart
│   └── infrastructure/
│       ├── local_auth_repository_test.dart
│       └── supabase_auth_repository_test.dart
└── presentation/
    └── shell/
        ├── player_personal_data_screen_test.dart
        └── profile_tab_completeness_test.dart
```

**Structure Decision**: Se mantiene la arquitectura limpia en 4 capas del monorepo Flutter (`lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation`) junto con `supabase/migrations/` y `test/` espejando la estructura existente. No se crean paquetes ni módulos externos adicionales.

## Complexity Tracking

> No hay violaciones a la Constitución que requieran justificación.
