# Implementation Plan: Deshabilitar Cambio de Rol Activo en el Perfil para Todos los Roles

**Branch**: `054-disable-profile-role-switch` | **Date**: 2026-11-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/054-disable-profile-role-switch/spec.md`

## Summary

Eliminar por completo la sección interactiva de cambio de rol activo (`ChoiceChip` y textos de entorno `dev`/`prod`) de `ProfileTabView` para todos los roles del sistema (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y usuarios invitados, en ambos entornos (`dev` y `prod`). El perfil conservará únicamente la insignia de solo lectura del rol activo en la tarjeta de identidad superior (`KickPulseBadge`), garantizará 0 invocaciones a `AuthController.switchActiveRole` desde la vista de Perfil, y mantendrá intactas todas las demás funciones de la pantalla (completitud de perfil, datos personales de jugador, matriz de permisos y cierre de sesión).

## Technical Context

**Language/Version**: Dart SDK `^3.12.0` / Flutter (Material UI via `package:material_ui/material_ui.dart`)

**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `material_ui: ^1.2.0`, `flutter_localizations` (`AppLocalizations` generado desde `lib/l10n/app_es.arb`)

**Storage**: Hive local storage + Supabase (sin cambios de esquema ni mutaciones desde esta funcionalidad)

**Testing**: `flutter_test`, `mocktail: ^1.0.4`

**Target Platform**: Android (API 21+) e iOS (entornos `dev` y `prod`)

**Project Type**: Mobile app (Flutter Clean Architecture: `domain/`, `application/`, `infrastructure/`, `presentation/`)

**Performance Goals**: Renderizado instantáneo a 60 fps sin reconstrucciones innecesarias; 0 llamadas de red o persistencia asociadas al rol desde Perfil

**Constraints**: Offline-first (comportamiento idéntico sin conexión), RBAC estricto en `dev` y `prod`, accesibilidad con lector de pantalla y escalado de texto, UI 100% en español vía `l10n`, código y tests 100% en inglés

**Scale/Scope**: Cambio acotado a la pantalla de Perfil (`ProfileTabView`), limpieza de imports/variables no usadas, y cobertura de pruebas de widget para los 5 roles + modo visitante en `dev` y `prod`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación Pre-Diseño | Evaluación Post-Diseño | Evidencia |
|---|---|---|---|
| **I. La Spec Manda (SDD)** | PASS | PASS | `spec.md` clarificado (Opción B) con 16/16 checks en `checklists/requirements.md` y criterios de `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | PASS | 0 mutaciones de `activeRole` desde Perfil; no se alteran entidades ni sincronización. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | PASS | Pruebas de widget actualizadas (`auth_flow_widget_test.dart`) y nuevas pruebas exhaustivas (`profile_tab_view_test.dart`) cubriendo los 5 roles + invitado en `dev` y `prod`. |
| **IV. Arquitectura Limpia** | PASS | PASS | Cambio estrictamente contenido en la capa `presentation/`; dominio (`UserRole`, `UserAccount`), casos de uso y repositorios permanecen desacoplados e intactos. |
| **V. Segregación de Roles y Fidelidad a DESIGN.md** | PASS | PASS | Bloquea cambios de rol no autorizados en Perfil para los 5 roles; conserva tokens `KickPulseColors`, `KickPulseTypography`, `KickPulseBadge` y `KickPulseCard`. |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | PASS | Código, claves de widget y pruebas en inglés; textos visibles al usuario en español mediante `AppLocalizations` (`lib/l10n/app_es.arb`). |
| **VII. Resiliencia y Experiencia Móvil** | PASS | PASS | Sin dependencias de conectividad, estado inmutable en ciclo de vida/reanudación, semántica de solo lectura en `KickPulseBadge` y verificación con escalado de texto. |

**Gate Status**: PASS (0 violaciones).

## Project Structure

### Documentation (this feature)

```text
specs/054-disable-profile-role-switch/
├── plan.md                                  # Este archivo (/speckit-plan)
├── research.md                              # Fase 0: hallazgos e impacto en código y pruebas
├── data-model.md                            # Fase 1: entidades relevantes en solo lectura
├── quickstart.md                            # Fase 1: guía de validación ejecutable
├── contracts/
│   └── profile_role_display_contract.md     # Fase 1: contrato de UI/interacción de Perfil
├── checklists/
│   └── requirements.md                      # Checklist de calidad de especificación
└── tasks.md                                 # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── presentation/
│   └── shell/
│       └── tabs/
│           └── profile_tab_view.dart        # Eliminar sección de cambio de rol y referencias a switchActiveRole
└── l10n/
    └── app_es.arb                           # Evaluar/mantener claves l10n sin textos hardcoded en UI

test/
└── presentation/
    ├── auth_flow_widget_test.dart           # Actualizar prueba heredada que esperaba ChoiceChip de cambio de rol
    └── shell/
        └── profile_tab_view_test.dart       # Agregar pruebas para los 5 roles + invitado en dev y prod, accesibilidad y no-mutación
```

**Structure Decision**: Se mantiene la arquitectura limpia existente del proyecto Flutter (`lib/presentation/` y `test/presentation/`). No se requieren archivos nuevos en `domain/`, `application/` ni `infrastructure/`, ya que el bloqueo es una eliminación de interfaz en `ProfileTabView` mientras `AuthController.switchActiveRole` y los repositorios se conservan intactos para no romper pruebas de dominio/infraestructura existentes.

## Complexity Tracking

No aplica — 0 violaciones a la Constitución del proyecto.
