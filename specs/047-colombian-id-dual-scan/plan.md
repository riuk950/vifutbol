# Implementation Plan: Escaneo Dual de Cédula Colombiana, Autocompletado y Captura por Ambos Lados (HU 21.2)

**Branch**: `047-colombian-id-dual-scan` | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/047-colombian-id-dual-scan/spec.md)

**Input**: Feature specification from `/specs/047-colombian-id-dual-scan/spec.md`

## Summary

Integrar el escaneo dual de cédula colombiana (cédula amarilla vía `PDF417` y cédula digital/policarbonato vía `MRZ TD1` + `OCR`) y captura obligatoria por ambos lados (frontal y posterior) directamente en `PlayerPersonalDataScreen` (HU 21.1). La arquitectura separa los analizadores puros (`ColombianIdParser`) en `domain`, las interfaces de escaneo y almacenamiento en `domain/repositories`, los adaptadores concretos de `google_mlkit_barcode_scanning` / `google_mlkit_text_recognition` / `image_picker` (solo cámara en vivo) / `Supabase Storage` (bucket privado con RLS) en `infrastructure`, y los componentes UI reactivos (`IdDocumentCaptureCard`) en `presentation`.

## Technical Context

**Language/Version**: Dart ^3.12.0 / Flutter (Material 3 + KickPulse Design System)  
**Primary Dependencies**: `flutter_riverpod`, `supabase_flutter`, `google_mlkit_barcode_scanning`, `google_mlkit_text_recognition`, `image_picker`, `permission_handler`, `flutter_localizations`  
**Storage**: PostgreSQL (`vifutboldev.players`: `document_front_url`, `document_back_url`) + Supabase Storage privado (`player-documents` con RLS por `auth.uid()`) + caché local  
**Testing**: `flutter_test`, `mocktail` (unitarias para parsers PDF417/MRZ/OCR, repositorio/storage, y widget/responsivas)  
**Target Platform**: Android / iOS (cámara física trasera en vivo; validado en 320px/360px y 130% de escala de texto)  
**Project Type**: Mobile app (Clean Architecture en 4 capas: `domain`, `application`, `infrastructure`, `presentation`)  
**Performance Goals**: Procesamiento local on-device ML Kit < 2 segundos tras capturar ambas caras; cálculo reactivo de edad < 100 ms  
**Constraints**: Captura exclusiva por cámara en vivo (sin galería); ambas caras obligatorias para completar perfil de jugador; bucket privado con RLS; cero textos hardcodeados en UI; cero datos sensibles de cédula en logs  
**Scale/Scope**: 1 servicio de parser puro + 2 adaptadores de infraestructura (ML Kit + Storage) + 1 widget de captura dual integrado en `PlayerPersonalDataScreen` + 1 migración SQL/Storage

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Estado | Evaluación |
|-----------|--------|------------|
| **I. La Spec Manda** | ✓ PASS | `spec.md` completado, clarificado (3 decisiones integradas: ambas caras obligatorias, solo cámara en vivo, bucket privado RLS + conexión requerida) y validado 16/16 en `checklists/requirements.md`. |
| **II. Integridad de Datos y Fuente de Verdad Transparente** | ✓ PASS | `document_front_url` y `document_back_url` persisten atómicamente en `vifutboldev.players` mediante `complete_role_profile` y se hidratan en caché local. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | ✓ PASS | Incluye pruebas unitarias exhaustivas de `ColombianIdParser` (PDF417 y MRZ TD1/OCR), pruebas de `RoleProfileData` / `UserAccount`, pruebas de `SupabaseAuthRepository` + Storage, y pruebas de widget de flujo de captura, autocompletado, permisos y 320px/130%. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | ✓ PASS | Parsers puros y contratos viven en `lib/domain/`; ML Kit, `image_picker` y Supabase Storage viven en `lib/infrastructure/`; UI en `lib/presentation/`. |
| **V. Segregación de Roles y Fidelidad al Sistema de Diseño** | ✓ PASS | Exclusivo para `UserRole.player` en `PlayerPersonalDataScreen`; tarjeta y botones usan tokens `KickPulseColors`, `KickPulseTypography`, `KickPulseRadiiSpacing` y `KickPulseButton`. |
| **VI. Convenciones de Idioma y Nomenclatura** | ✓ PASS | Código, entidades, métodos y tests en inglés; todas las etiquetas, guías de captura frontal/posterior y mensajes de error/permisos en español vía `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil** | ✓ PASS | Maneja permisos de cámara denegados con acceso a configuración, anti-doble pulsación al capturar/escanear/guardar, conservación de fotos y formulario ante error de red, y privacidad (sin logs de tramas crudas). |

**Post-Design Re-Check**: ✓ Todos los 7 principios en estado PASS.

## Project Structure

### Documentation (this feature)

```text
specs/047-colombian-id-dual-scan/
├── plan.md                                      # This file
├── research.md                                  # Phase 0 technical decisions
├── data-model.md                                # Phase 1 domain & SQL/Storage model
├── quickstart.md                                # Phase 1 validation guide
├── contracts/
│   └── colombian_id_dual_scan_contract.md       # Parser, service, storage & UI contracts
├── checklists/
│   └── requirements.md                          # Spec quality checklist (16/16 PASS)
└── tasks.md                                     # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
pubspec.yaml                                         # Add google_mlkit_barcode_scanning, google_mlkit_text_recognition, image_picker, permission_handler
android/app/src/main/AndroidManifest.xml             # Ensure CAMERA permission
ios/Runner/Info.plist                                # Ensure NSCameraUsageDescription

lib/
├── domain/
│   ├── entities/
│   │   ├── colombian_id_scan_result.dart            # ColombianIdScanSource, ColombianIdScanResult, PlayerDocumentCapture
│   │   ├── role_profile_data.dart                   # Add documentFrontUrl & documentBackUrl
│   │   └── user_account.dart                        # Require documentFrontUrl & documentBackUrl for UserRole.player completeness
│   ├── failures/
│   │   └── app_failure.dart                         # CameraPermissionDeniedFailure & DocumentUploadFailure
│   ├── repositories/
│   │   ├── colombian_id_scanner_service.dart        # Port for camera capture & dual ML Kit scanning
│   │   └── document_storage_repository.dart         # Port for private document upload
│   └── services/
│       └── colombian_id_parser.dart                 # Pure PDF417 + ICAO 9303 TD1 MRZ + OCR heuristic parsers
├── application/
│   └── providers/
│       └── document_scanner_providers.dart          # Riverpod providers for scanner service & document storage
├── infrastructure/
│   ├── auth/
│   │   ├── local_auth_repository.dart               # Merge documentFrontUrl & documentBackUrl
│   │   └── supabase_auth_repository.dart            # Pass p_document_front_url & p_document_back_url to RPC & hydrate from players
│   ├── scanner/
│   │   └── mlkit_colombian_id_scanner_service.dart  # image_picker (camera-only) + ML Kit PDF417 & Latin OCR + permission_handler
│   └── storage/
│       └── supabase_document_storage_repository.dart # Private 'player-documents' bucket upload
├── presentation/
│   └── shell/
│       ├── tabs/
│       │   └── player_personal_data_screen.dart     # Integrate IdDocumentCaptureCard, mandatory dual-photo check, upload-before-save
│       └── widgets/
│           └── id_document_capture_card.dart        # Guided front/back capture card, thumbnails, recapture, permission & scan feedback
└── l10n/
    └── app_es.arb                                   # Spanish labels for dual capture, camera permissions, scan feedback & validation

supabase/
└── migrations/
    └── 202611170003_player_document_images.sql      # Add document_front_url/back_url, private bucket & RLS policies, update RPC

test/
├── unit/
│   └── domain/
│       └── colombian_id_parser_test.dart            # Unit tests for PDF417, MRZ TD1, OCR heuristics & mergeResults
├── domain/
│   └── entities/
│       └── user_account_test.dart                   # Updated player completeness requiring front/back document URLs
├── infrastructure/
│   └── auth/
│       └── supabase_auth_repository_test.dart       # Verify document URL forwarding & hydration
└── presentation/
    └── shell/
        └── player_personal_data_screen_test.dart    # Widget tests for capture flow, autocomplete, permissions, validation & 320px/130%
```
