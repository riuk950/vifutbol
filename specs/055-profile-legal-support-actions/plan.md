# Implementation Plan: Botones de Quitar Anuncios, Términos, Políticas de Datos y Preguntas Frecuentes en Perfil

**Branch**: `055-profile-legal-support-actions` | **Date**: 2026-11-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/055-profile-legal-support-actions/spec.md`

## Summary

Agregar debajo de la tarjeta "Permisos y capacidades del rol" (y antes del botón de cierre/inicio de sesión) en `ProfileTabView` una nueva sección `ProfileLegalSupportSection` con cuatro accesos ordenados: **Quitar anuncios**, **Términos y condiciones**, **Políticas de tratamiento de datos** y **Preguntas frecuentes**. Al pulsar los tres accesos legales/soporte se navega a pantallas dedicadas de lectura offline (`ProfileLegalDocumentScreen` y `ProfileFaqScreen`) con barra superior y retorno al Perfil; al pulsar **Quitar anuncios** se abre un diálogo modal informativo (`RemoveAdsDialog`) explicando el beneficio y su disponibilidad "Próximamente" sin cobros ni persistencia. Todas las etiquetas y contenidos se centralizan en español mediante `lib/l10n/app_es.arb` (`AppLocalizations`), respetando los tokens de `DESIGN.md` (`KickPulse`) y protegiendo las cuatro acciones contra pulsaciones duplicadas (doble tap).

## Technical Context

**Language/Version**: Dart SDK `^3.12.0` / Flutter (Material UI via `package:material_ui/material_ui.dart`)

**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `fluro: ^2.0.5`, `material_ui: ^1.2.0`, `flutter_localizations` (`AppLocalizations` generado con `flutter gen-l10n` desde `lib/l10n/app_es.arb`)

**Storage**: N/A (contenido legal, FAQ e información de remoción de anuncios 100% local/estático offline; sin persistencia Hive ni Supabase)

**Testing**: `flutter_test`, `mocktail: ^1.0.4`

**Target Platform**: Android (API 21+) e iOS (entornos `dev` y `prod`)

**Project Type**: Mobile app (Flutter Clean Architecture: `domain/`, `application/`, `infrastructure/`, `presentation/`)

**Performance Goals**: Apertura instantánea (<16 ms por frame, 60 fps) sin peticiones de red ni bloqueos de UI

**Constraints**: 100% operativo offline, prevención de doble tap, áreas táctiles ≥ 44 px, escalado de texto `1.5x` sin overflow, UI 100% en español vía `l10n`, código y tests 100% en inglés

**Scale/Scope**: 1 sección reutilizable en Perfil, 2 pantallas dedicadas de lectura/FAQ, 1 diálogo modal informativo, 3 rutas registradas en `AppRouter`, llaves `l10n` en `app_es.arb` y cobertura completa de pruebas de widget

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación Pre-Diseño | Evaluación Post-Diseño | Evidencia |
|---|---|---|---|
| **I. La Spec Manda (SDD)** | PASS | PASS | `spec.md` clarificado (Q1=B, Q2=A) con 16/16 checks en `checklists/requirements.md` y criterios de `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | PASS | Sin mutaciones sobre entidades deportivas ni de sesión; solo contenido informativo de solo lectura. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | PASS | Pruebas de widget para orden exacto debajo de permisos, 5 roles + visitante, apertura de pantallas/modal, protección doble tap, escalado `1.5x` y no-regresión. |
| **IV. Arquitectura Limpia** | PASS | PASS | Componentes estrictamente encapsulados en `lib/presentation/shell/tabs/` y `lib/presentation/navigation/`; cero acoplamiento con dominio o infraestructura. |
| **V. Segregación de Roles y Fidelidad a DESIGN.md** | PASS | PASS | Visible para todos los roles y visitantes; usa `KickPulseCard`, `KickPulseColors`, `KickPulseTypography`, `KickPulseRadiiSpacing`, `KickPulseBadge` y `KickPulseButton`. |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | PASS | Archivos, clases, métodos, claves y pruebas en inglés; 100% de textos visibles en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | PASS | PASS | Lectura 100% offline, protección contra doble tap, áreas táctiles ≥ 44 px, scroll vertical, soporte a botón atrás y escalado `1.5x`. |

**Gate Status**: PASS (0 violaciones).

## Project Structure

### Documentation (this feature)

```text
specs/055-profile-legal-support-actions/
├── plan.md                                      # Este archivo (/speckit-plan)
├── research.md                                  # Fase 0: decisiones de navegación, doble tap y l10n
├── data-model.md                                # Fase 1: modelos inmutables de documentos legales/FAQ
├── quickstart.md                                # Fase 1: guía de validación ejecutable
├── contracts/
│   └── profile_legal_support_contract.md        # Fase 1: contrato visual, rutas y comportamiento
├── checklists/
│   └── requirements.md                          # Checklist de calidad de especificación
└── tasks.md                                     # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                               # Llaves en español para botones, documentos legales, FAQ y modal Quitar anuncios
│   ├── app_localizations.dart                   # Regenerado por flutter gen-l10n
│   └── app_localizations_es.dart                # Regenerado por flutter gen-l10n
└── presentation/
    ├── navigation/
    │   └── app_router.dart                      # Registrar rutas /profile/terms, /profile/privacy-policy, /profile/faq
    └── shell/
        └── tabs/
            ├── profile_tab_view.dart            # Insertar ProfileLegalSupportSection debajo de permisos y antes de cerrar sesión
            ├── profile_legal_document_screen.dart # Pantalla dedicada de lectura para Términos y Políticas de datos
            ├── profile_faq_screen.dart          # Pantalla dedicada de Preguntas frecuentes (acordeón / lista legible)
            └── widgets/
                ├── profile_legal_support_section.dart # Tarjeta con los 4 botones ordenados y guarda contra doble tap
                └── remove_ads_dialog.dart       # Diálogo modal informativo "Próximamente" para Quitar anuncios

test/
└── presentation/
    └── shell/
        └── profile_tab_view_test.dart           # Pruebas de orden, posición, navegación, modal, doble tap, roles y escalado 1.5x
```

**Structure Decision**: Se encapsulan los cuatro botones y la guarda contra doble tap en `ProfileLegalSupportSection` (`widgets/profile_legal_support_section.dart`) para mantener `ProfileTabView` limpio y cohesivo, reutilizando el patrón ya establecido en `lib/presentation/shell/tabs/` (`player_personal_data_screen.dart`, `complete_profile_dialog.dart`).

## Complexity Tracking

No aplica — 0 violaciones a la Constitución del proyecto.
