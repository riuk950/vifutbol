# Implementation Plan: Perfil Completo del Árbitro: Cédula Colombiana por Ambos Lados y Documento de Certificación Arbitral

**Branch**: `057-referee-profile-id-certification` | **Date**: 2026-11-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/057-referee-profile-id-certification/spec.md`

## Summary

Implementar el flujo completo de acreditación de identidad y certificación para el rol `Árbitro` (`UserRole.referee`) en paridad con el formulario de cédula colombiana de jugador, añadiendo la captura obligatoria de la imagen del documento de certificación arbitral (`certificationDocumentUrl`). En base de datos (Supabase `vifutboldev`), se crea la migración `202611250002_referee_profile_and_certification_doc.sql` que amplía `vifutboldev.match_referees` con los campos demográficos colombianos, `document_front_url`, `document_back_url` y `certification_document_url`, actualiza `vifutboldev.complete_role_profile` (28 parámetros) y asegura que `delete_my_account()` limpie estas nuevas columnas PII. En Flutter, se extiende `RoleProfileData`, `UserAccount.isProfileCompleteForActiveRole`, `DocumentStorageRepository` (`SupabaseDocumentStorageRepository` / `LocalDocumentStorageRepository`), `SupabaseAuthRepository`, `AppRouter`, `ProfileTabView`, `lib/l10n/app_es.arb` y se crea la pantalla dedicada `RefereePersonalDataScreen` reutilizando `MlkitColombianIdScannerService`, `IdDocumentCaptureCard` y `SearchableLocationPickerSheet`.

## Technical Context

**Language/Version**: Dart SDK `^3.12.0` / Flutter + PostgreSQL (Supabase SQL migrations)

**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `supabase_flutter: ^2.18.3`, `google_mlkit_barcode_scanning: ^0.13.0`, `google_mlkit_text_recognition: ^0.14.0`, `image_picker: ^1.1.2`, `permission_handler: ^11.3.1`, `fluro: ^2.0.5`, `material_ui: ^1.2.0`

**Storage**: Supabase PostgreSQL (`vifutboldev.match_referees` + `vifutboldev.user_accounts`), Supabase Storage privado (`player-documents` con RLS por propietario `auth.uid()`), Hive local cache

**Testing**: `flutter_test`, `mocktail: ^1.0.4`

**Target Platform**: Android (API 21+) e iOS (entornos `dev` y `prod`)

**Project Type**: Mobile app (Flutter Clean Architecture + Supabase SQL migrations)

**Performance Goals**: Escaneo ML Kit en dispositivo sin bloquear UI; subida selectiva (solo imágenes nuevas o reemplazadas); guardado atómico en una sola invocación RPC

**Constraints**: Solo imagen (`JPEG`/`PNG`/`WEBP`) para documento arbitral; almacenamiento privado restringido a `auth.uid()`; bloqueo `single-flight`; permisos cámara/galería en español; diálogo de cambios sin guardar; UI en español vía `l10n`, código y pruebas en inglés; fuera de alcance avatar/resumen del árbitro (HU 25.2)

**Scale/Scope**: 1 migración SQL, actualización de 2 entidades de dominio, 1 contrato + 2 implementaciones de storage, hidratación en `SupabaseAuthRepository`, 1 pantalla dedicada (`RefereePersonalDataScreen`), integración en `ProfileTabView` y `AppRouter`, llaves `l10n` y pruebas unitarias + widget

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Evaluación Pre-Diseño | Evaluación Post-Diseño | Evidencia |
|---|---|---|---|
| **I. La Spec Manda (SDD)** | PASS | PASS | `spec.md` clarificado (`Q1=A`, solo imagen) con 16/16 checks y criterios de `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | PASS | `complete_role_profile` enlaza `match_referees` por `user_account_id` o `normalized_document_id` sin duplicar registros; `delete_my_account()` limpia las nuevas columnas PII preservando historial de actas. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | PASS | Pruebas unitarias (`user_account_test.dart`, storage repository) y pruebas de widget (`referee_personal_data_screen_test.dart`, `profile_tab_view_test.dart`). |
| **IV. Arquitectura Limpia** | PASS | PASS | Dominio (`RoleProfileData`, `UserAccount`, `DocumentStorageRepository`), Infraestructura (`SupabaseDocumentStorageRepository`, `SupabaseAuthRepository`) y Presentación (`RefereePersonalDataScreen`, `ProfileTabView`) estrictamente desacoplados. |
| **V. Segregación de Roles y Fidelidad a DESIGN.md** | PASS | PASS | Flujo exclusivo para `UserRole.referee` (sin alterar completitud de otros roles); reutiliza `IdDocumentCaptureCard`, `SearchableLocationPickerSheet` y tokens `KickPulse`. |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | PASS | Código, migraciones, identificadores y pruebas en inglés; 100% de textos visibles en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | PASS | PASS | Permisos cámara/galería con recuperación en español, confirmación de salida con cambios sin guardar, `single-flight`, retención de datos ante fallo offline y escalado `1.5x`. |

**Gate Status**: PASS (0 violaciones).

## Project Structure

### Documentation (this feature)

```text
specs/057-referee-profile-id-certification/
├── plan.md                                  # Este archivo (/speckit-plan)
├── research.md                              # Fase 0: reutilización de escáner, bucket y RPC
├── data-model.md                            # Fase 1: columnas match_referees y criterios de completitud
├── quickstart.md                            # Fase 1: guía de validación ejecutable
├── contracts/
│   └── referee_profile_contract.md          # Fase 1: contrato SQL RPC, Storage y UI
├── checklists/
│   └── requirements.md                      # Checklist de calidad de especificación
└── tasks.md                                 # Fase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
supabase/
└── migrations/
    └── 202611250002_referee_profile_and_certification_doc.sql # Columnas match_referees + RPC complete_role_profile (28 params) + delete_my_account PII

lib/
├── domain/
│   ├── entities/
│   │   ├── role_profile_data.dart           # Agregar certificationDocumentUrl
│   │   └── user_account.dart                # Actualizar isProfileCompleteForActiveRole para UserRole.referee
│   └── repositories/
│       └── document_storage_repository.dart # Agregar uploadRefereeCertificationDocument()
├── infrastructure/
│   ├── storage/
│   │   └── supabase_document_storage_repository.dart # Implementar uploadRefereeCertificationDocument en Supabase y Local
│   └── auth/
│       └── supabase_auth_repository.dart    # Pasar p_certification_document_url en RPC e hidratar campos de match_referees
├── l10n/
│   ├── app_es.arb                           # Llaves en español para formulario y certificación arbitral
│   ├── app_localizations.dart               # Regenerado con flutter gen-l10n
│   └── app_localizations_es.dart            # Regenerado con flutter gen-l10n
└── presentation/
    ├── navigation/
    │   └── app_router.dart                  # Registrar /profile/referee-personal-data
    └── shell/
        └── tabs/
            ├── profile_tab_view.dart        # Navegar a /profile/referee-personal-data desde Completar perfil y tile dedicado
            └── referee_personal_data_screen.dart # Pantalla dedicada de perfil y certificación arbitral

test/
├── domain/
│   └── entities/
│       └── user_account_test.dart           # Actualizar/ampliar pruebas de isProfileCompleteForActiveRole para UserRole.referee
└── presentation/
    └── shell/
        ├── profile_tab_view_test.dart       # Verificar navegación de árbitro hacia /profile/referee-personal-data
        └── referee_personal_data_screen_test.dart # Pruebas de widget del formulario arbitral (escaneo, validaciones, captura, single-flight, guardado)
```

**Structure Decision**: Se crea `RefereePersonalDataScreen` en `lib/presentation/shell/tabs/` en paridad directa con `PlayerPersonalDataScreen`, reutilizando `IdDocumentCaptureCard`, `SearchableLocationPickerSheet`, `MlkitColombianIdScannerService` y `ColombiaLocationCatalog` sin duplicar lógica de escaneo ni catálogos.

## Complexity Tracking

No aplica — 0 violaciones a la Constitución del proyecto.
