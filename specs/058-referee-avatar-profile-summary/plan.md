# Implementation Plan: Foto de Avatar del Árbitro, Visualización en Perfil y Pantalla Resumen

**Branch**: `058-referee-avatar-profile-summary` | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/058-referee-avatar-profile-summary/spec.md`

## Summary

Extender el flujo de perfil arbitral (construido en HU 25.1) para incorporar:
1. Captura y vista previa circular de la fotografía de avatar del árbitro desde cámara o galería en `RefereePersonalDataScreen`, con subida al bucket público `player-avatars` (reutilizando `DocumentStorageRepository.uploadPlayerAvatar` con cache-buster `?t=<timestamp>`) y persistencia atómica en `vifutboldev.user_accounts.photo_url` y `vifutboldev.match_referees.photo_url`.
2. Visualización reactiva del avatar y del estado `Perfil completo` en `ProfileTabView` (sin exigir avatar como requisito obligatorio para `isProfileCompleteForActiveRole`), y enrutamiento condicional del tile `profile_referee_personal_data_tile` hacia la pantalla resumen cuando el perfil arbitral está completo o hacia el formulario cuando está incompleto.
3. Nueva pantalla de solo lectura `RefereePersonalDataSummaryScreen` (`/profile/referee-personal-data/summary`) en paridad con `PlayerPersonalDataSummaryScreen`, mostrando avatar circular, datos personales y ubicación, nivel de certificación arbitral, vistas previas de ambos lados de la cédula y del documento de certificación arbitral (con diálogo de zoom y fallback visual resiliente), más acción `Editar` en el `AppBar`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (Mobile iOS & Android) + PostgreSQL 17 (Supabase `vifutboldev` schema)

**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `image_picker`, `permission_handler` (vía `ColombianIdScannerService.openCameraSettings`), `flutter_localizations` (`l10n` en `lib/l10n/app_es.arb`), `KickPulse` Design System (`DESIGN.md`)

**Storage**:
- Remoto: PostgreSQL (`vifutboldev.user_accounts.photo_url`, `vifutboldev.match_referees.photo_url`), Supabase Storage público (`player-avatars/$userId/avatar.jpg`) y privado (`player-documents/$userId/*` vía signed URLs).
- Local: Hive (`LocalAuthRepository` / sesión `UserAccount.photoUrl` + caché local de `RoleProfileData`).

**Testing**: `flutter test` (pruebas unitarias y de widget con fakes de `DocumentStorageRepository`, `AuthRepository` e inyección de selector de imagen en `RefereePersonalDataScreen`) y `flutter analyze`.

**Target Platform**: Android & iOS (Flutter mobile app).

**Project Type**: Mobile app (Clean Architecture por capas: `domain`, `application`, `infrastructure`, `presentation`).

**Performance Goals**: Renderizado a 60 fps en formulario y resumen; redimensionamiento/compresión de avatar (`maxWidth: 1024, imageQuality: 85`) previo a subida; carga no bloqueante de URLs firmadas para documentos privados.

**Constraints**:
- Guardado de avatar en nube requiere conectividad (si está offline, muestra error claro en español y conserva formulario/vista previa local para reintento); consulta del resumen y avatar ya guardado funciona offline con fallback visual.
- Avatar es opcional respecto a `UserAccount.isProfileCompleteForActiveRole` para `UserRole.referee`.
- Bloqueo `single-flight` en guardado y confirmación de salida con cambios sin guardar (`PopScope`).
- Todo código técnico y pruebas en inglés; todos los textos visibles en español en `lib/l10n/app_es.arb`.

**Scale/Scope**: 1 migración SQL idempotente, 1 pantalla nueva (`RefereePersonalDataSummaryScreen`), actualización de 3 pantallas/rutas (`RefereePersonalDataScreen`, `ProfileTabView`, `AppRouter`), ~15 claves nuevas en `app_es.arb` y pruebas de widget/regresión.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (SDD)**: PASS — `spec.md` y clarificaciones (`2026-11-25`) cerradas y validadas (16/16 en `checklists/requirements.md`) antes de diseñar e implementar.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: PASS — `vifutboldev.complete_role_profile` actualiza atómicamente `user_accounts.photo_url` y `match_referees.photo_url`, y `delete_my_account()` limpia también `match_referees.photo_url` al desvincular PII.
- **III. Pruebas Automatizadas como Puerta de Calidad**: PASS — Plan incluye pruebas de widget para captura/preview/permisos/offline del avatar en `RefereePersonalDataScreen`, navegación y renderizado de avatar en `ProfileTabView`, y visualización/edición/fallback en `RefereePersonalDataSummaryScreen`.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: PASS — Presentación delega subida a `DocumentStorageRepository` y persistencia a `AuthController` / `AuthRepository`; sin acoplamiento a Supabase desde widgets.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: PASS — Flujo restringido a `UserRole.referee` autenticado; usa tokens `KickPulseColors`, `KickPulseTypography`, `KickPulseRadiiSpacing`, `KickPulseCard` y `KickPulseBadge`.
- **VI. Convenciones de Idioma y Nomenclatura**: PASS — Identificadores, archivos y pruebas en inglés; UI 100% en español vía `AppLocalizations` (`lib/l10n/app_es.arb`).
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: PASS — Cubre permisos denegados/permanentes, cancelación sin error, `PopScope` con `_isDirty` al cambiar avatar, `single-flight`, cache-busting `?t=`, fallback visual offline/error y sin exposición de datos sensibles.

**Post-Design Re-check**: PASS — Ninguna violación introducida; no se requiere entrada en `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/058-referee-avatar-profile-summary/
├── plan.md                                  # Este archivo
├── research.md                              # Decisiones técnicas y alternativas evaluadas
├── data-model.md                            # Esquema de datos y transiciones de estado
├── quickstart.md                            # Guía de verificación end-to-end
├── contracts/
│   └── referee_avatar_summary_contract.md   # Contratos de RPC, storage, rutas y UI keys
└── checklists/
    └── requirements.md                      # Checklist de calidad de especificación
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611250003_referee_avatar_photo_url.sql          # Nueva migración SQL idempotente

lib/
├── infrastructure/
│   └── auth/
│       ├── supabase_auth_repository.dart              # Verificación de hidratación/persistencia de photoUrl para árbitro
│       └── local_auth_repository.dart                 # Verificación de persistencia local de photoUrl para árbitro
├── l10n/
│   ├── app_es.arb                                     # Nuevas claves en español para avatar/resumen árbitro
│   ├── app_localizations.dart                         # Generado por flutter gen-l10n
│   └── app_localizations_es.dart                      # Generado por flutter gen-l10n
└── presentation/
    ├── navigation/
    │   └── app_router.dart                            # Registro de /profile/referee-personal-data/summary
    └── shell/tabs/
        ├── profile_tab_view.dart                      # Tile condicional a summary vs form + avatar reactivo
        ├── referee_personal_data_screen.dart          # Sección de avatar circular + subida + permisos
        └── referee_personal_data_summary_screen.dart  # Nueva pantalla resumen de solo lectura + botón Editar

test/presentation/shell/
├── profile_tab_view_test.dart                         # Pruebas de avatar árbitro y navegación a summary/form
├── referee_personal_data_screen_test.dart             # Pruebas de captura, preview, permisos y guardado de avatar
└── referee_personal_data_summary_screen_test.dart     # Nueva suite para pantalla resumen y edición
```

**Structure Decision**: Se mantiene la arquitectura limpia existente del proyecto Flutter en `lib/` y migraciones versionadas en `supabase/migrations/`, reutilizando los contratos ya existentes de `DocumentStorageRepository.uploadPlayerAvatar` y `AuthController.completeRoleProfile` sin introducir capas ni dependencias adicionales.

## Complexity Tracking

Sin violaciones a la Constitución; no se requieren excepciones.
