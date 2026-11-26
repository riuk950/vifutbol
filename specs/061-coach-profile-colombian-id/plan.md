# Plan de Implementación: Perfil Completo del Entrenador (Cédula Colombiana, Escaneo Dual y Fotos por Ambos Lados)

**Branch**: `061-coach-profile-colombian-id` | **Fecha**: 2026-11-26 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/061-coach-profile-colombian-id/spec.md)

**Input**: Especificación funcional desde `/specs/061-coach-profile-colombian-id/spec.md` (Notion HU 27.1).

## Summary

Implementar el flujo completo de perfil personal del entrenador (`UserRole.coach`) en paridad con el flujo de jugador y árbitro: ampliar `vifutboldev.coach_profiles` y el RPC atómico `vifutboldev.complete_role_profile` con los datos de cédula colombiana, ubicación en Colombia y referencias privadas de ambas caras de la cédula; actualizar la hidratación remota y el criterio `UserAccount.isProfileCompleteForActiveRole`; crear las pantallas dedicadas `CoachPersonalDataScreen` (reutilizando `MlkitColombianIdScannerService` e `IdDocumentCaptureCard`, con validación ≥ 18 años, `"Independiente"` / `"Sin licencia"` y bloqueo single-flight) y `CoachPersonalDataSummaryScreen` (con miniaturas en línea cargadas vía URL firmada temporal y zoom); integrar rutas y navegación en `ProfileTabView`; y cubrir todo con textos localizados en `app_es.arb` y pruebas unitarias y de widget.

## Technical Context

**Language/Version**: Dart 3.x / Flutter SDK (mobile app) + PostgreSQL (Supabase SQL migrations)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `image_picker`, `google_mlkit_barcode_scanning`, `google_mlkit_text_recognition`, `fluro` (`AppRouter`), `flutter_localizations` (`app_es.arb`), Design System `KickPulse`  
**Storage**: Supabase PostgreSQL (`vifutboldev.coach_profiles`, `vifutboldev.user_accounts`), Supabase Storage bucket privado `player-documents` (RLS por `auth.uid()`), cache local de sesión  
**Testing**: `flutter_test` (pruebas unitarias de entidad/repositorio y pruebas de widget para formulario, resumen y `ProfileTabView`)  
**Target Platform**: Android e iOS (Flutter mobile)  
**Project Type**: Mobile app (Clean Architecture por capas: `domain`, `application`, `infrastructure`, `presentation`)  
**Performance Goals**: Autocompletado de escaneo dual < 3 s tras lectura exitosa; UI fluida a 60 fps sin bloquear hilo principal durante subida de imágenes  
**Constraints**: 100% UI en español (`lib/l10n/app_es.arb`), ejecución `single-flight` en guardado/subida, manejo resiliente de permisos cámara/galería, preservación de estado ante pérdida de red o cambios sin guardar, acceso privado estricto a fotos de cédula  
**Scale/Scope**: 1 migración SQL idempotente, actualización de 4 archivos existentes (`user_account.dart`, `supabase_auth_repository.dart`, `profile_tab_view.dart`, `app_router.dart`), 2 nuevas pantallas dedicadas, localización en `app_es.arb` y 3 archivos de pruebas dedicados.

## Constitution Check

*GATE: Verificado previo a Phase 0 y revalidado tras Phase 1.*

- **Clean Architecture & Separación de Capas**: Cumple. La lógica de completitud reside en `domain` (`UserAccount`), el acceso remoto en `infrastructure` (`SupabaseAuthRepository`, `SupabaseDocumentStorageRepository`) y los formularios/resumen en `presentation` consumiendo providers de `application`.
- **Idioma (Código en inglés / UI 100% en español)**: Cumple. Todos los identificadores, rutas y tests están en inglés; todos los textos visibles se centralizan en `lib/l10n/app_es.arb`.
- **Seguridad y Privacidad (RLS y datos sensibles)**: Cumple. Las fotos de cédula se almacenan en el bucket privado `player-documents` con RLS por propietario (`auth.uid()`) y se muestran mediante URLs firmadas temporales; `complete_role_profile` usa `SECURITY DEFINER` validando `auth.uid()`.
- **Directrices Móviles (`docs/MOBILE_GUIDELINES.md`)**: Cumple. Bloqueo `single-flight`, confirmación de cambios sin guardar (`PopScope`), manejo resiliente de permisos cámara/galería, preservación de estado ante errores de red, desplazamiento vertical y soporte de accesibilidad/escalado de texto.
- **Sin violaciones detectadas**: No se requiere entrada en `Complexity Tracking`.

## Project Structure

### Documentation (this feature)

```text
specs/061-coach-profile-colombian-id/
├── plan.md                              # Este archivo (/speckit-plan)
├── research.md                          # Decisiones técnicas y reutilización (Phase 0)
├── data-model.md                        # Esquema coach_profiles, entidades y estados (Phase 1)
├── quickstart.md                        # Guía de validación automatizada y manual (Phase 1)
├── contracts/
│   └── coach-profile-contracts.md       # Contratos RPC, Storage, rutas y UI keys (Phase 1)
├── checklists/
│   └── requirements.md                  # Checklist de calidad de spec (16/16)
└── tasks.md                             # Generado por /speckit-tasks (Phase 2)
```

### Source Code (repository root)

```text
supabase/migrations/
└── 202611260001_coach_profile_personal_data_and_documents.sql   # [NEW] Columnas en coach_profiles + update complete_role_profile

lib/
├── domain/entities/
│   └── user_account.dart                                         # [MODIFY] Criterio completo para UserRole.coach
├── infrastructure/auth/
│   └── supabase_auth_repository.dart                             # [MODIFY] Hidratar nuevos campos de coach_profiles en fetchRoleProfileDetails
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                                       # [MODIFY] Rutas /profile/coach-personal-data y /profile/coach-personal-data/summary
│   └── shell/tabs/
│       ├── coach_personal_data_screen.dart                       # [NEW] Formulario dedicado de entrenador (escaneo dual + fotos + ≥ 18 años + club/licencia)
│       ├── coach_personal_data_summary_screen.dart               # [NEW] Resumen del entrenador con miniaturas firmadas + zoom + Editar
│       └── profile_tab_view.dart                                 # [MODIFY] Redirección de Completar perfil y tarjeta de datos personales para coach
└── l10n/
    └── app_es.arb                                                # [MODIFY] Claves localizadas en español para formulario y resumen de entrenador

test/
├── unit/
│   └── coach_profile_completeness_test.dart                      # [NEW] Pruebas unitarias de isProfileCompleteForActiveRole y serialización/hidratación
└── widget/
    ├── coach_personal_data_screen_test.dart                      # [NEW] Pruebas de widget del formulario (validaciones, ≥ 18 años, escaneo dual, fotos, single-flight)
    └── coach_personal_data_summary_screen_test.dart              # [NEW] Pruebas de widget de pantalla resumen (miniaturas, zoom, edición) y navegación desde ProfileTabView
```

**Structure Decision**: Se adopta la estructura existente del repositorio Flutter + Supabase (`lib/domain`, `lib/infrastructure`, `lib/presentation`, `supabase/migrations`, `test/unit`, `test/widget`) replicando fielmente el patrón validado de `PlayerPersonalDataScreen` y `RefereePersonalDataScreen`.

## Complexity Tracking

*Sin violaciones a la Constitución; no se requieren excepciones.*
