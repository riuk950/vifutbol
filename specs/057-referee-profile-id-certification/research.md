# Research Findings: Perfil Completo del Árbitro y Certificación Arbitral (HU 25.1)

**Feature**: `057-referee-profile-id-certification`  
**Date**: 2026-11-25

## Decision 1: Reutilización del bucket privado `player-documents` con ruta `$userId/referee_certification.jpg`

- **Decision**: Almacenar las dos caras de la cédula (`$userId/document_front.jpg`, `$userId/document_back.jpg`) y el documento de certificación arbitral (`$userId/referee_certification.jpg`) dentro del bucket privado existente `player-documents` (ya configurado con `public = false`, límite 5 MB, MIME `image/jpeg`, `image/png`, `image/webp` y políticas RLS restringidas a `(storage.foldername(name))[1] = auth.uid()::text`).
- **Rationale**:
  - Cumple al 100% con la clarificación Q1=A (solo imagen `JPEG`/`PNG`/`WEBP`) y la regla de almacenamiento privado restringido al propietario (`auth.uid()`).
  - Reutiliza `getSignedDocumentUrl` sin cambios y queda automáticamente cubierto por el borrado en cascada de `vifutboldev.delete_my_account()` implementado en HU 24.3.
- **Alternatives considered**:
  - *Crear un bucket separado `referee-certifications`*: Duplicaría 4 políticas RLS, obligaría a parametrizar `getSignedDocumentUrl` por bucket y requeriría modificar `delete_my_account()` en Storage.

## Decision 2: Evolución compatible del RPC `vifutboldev.complete_role_profile` (28 parámetros)

- **Decision**: En `supabase/migrations/202611250002_referee_profile_and_certification_doc.sql`, agregar las columnas demográficas y documentales a `vifutboldev.match_referees`, añadir el parámetro opcional `p_certification_document_url text DEFAULT NULL` a `vifutboldev.complete_role_profile`, persistir todos los atributos en `match_referees` cuando `p_active_role = 'referee'` (manteniendo el enlazado sin duplicados por `user_account_id` o `normalized_document_id`), e incluir `certification_document_url` y los demás campos en el `role_profile` JSONB devuelto. También actualizar `vifutboldev.delete_my_account()` para limpiar `document_front_url`, `document_back_url` y `certification_document_url` al desvincular `match_referees`.
- **Rationale**: Mantiene 100% de compatibilidad con el rol `player` y los demás roles que ya invocan `complete_role_profile`.
- **Alternatives considered**:
  - *Crear un RPC separado `complete_referee_profile`*: Fragmentaría la persistencia de roles y duplicaría la lógica de actualización atómica de `user_accounts`.

## Decision 3: Pantalla dedicada `RefereePersonalDataScreen` reutilizando componentes de Jugador

- **Decision**: Crear `lib/presentation/shell/tabs/referee_personal_data_screen.dart` reutilizando directamente:
  - `MlkitColombianIdScannerService` (vía `colombianIdScannerServiceProvider`) para escaneo dual PDF417 + MRZ OCR.
  - `IdDocumentCaptureCard` para captura, vista previa y reemplazo de frente y reverso de la cédula.
  - `SearchableLocationPickerSheet` y `ColombiaLocationCatalog` para Departamento y Municipio de Colombia.
  - `PlayerSex` y `PlayerPersonalDataUtils` para sexo, fecha de nacimiento, cálculo de edad y tipos de sangre RH.
  - Nueva sección de **Certificación Arbitral** con campo de texto `certificationLevel` y tarjeta de captura/vista previa/reemplazo para la imagen del documento de certificación arbitral (cámara o galería).
- **Rationale**: Garantiza paridad exacta con el flujo de cédula de jugador sin código duplicado de escáner ni catálogos, y deja lista la estructura para que HU 25.2 agregue foto de avatar y pantalla resumen del árbitro sin refactorizar el formulario.
- **Alternatives considered**:
  - *Reutilizar `PlayerPersonalDataScreen` con múltiples `if (isReferee)`*: Mezclaría responsabilidades de posiciones tácticas y avatar de jugador con certificación arbitral, dificultando mantenimiento y pruebas aisladas.

## Decision 4: Actualización de pruebas existentes de `UserAccount.isProfileCompleteForActiveRole`

- **Decision**: Revisar y actualizar `test/domain/entities/user_account_test.dart` (y cualquier test que construya un `UserAccount` con `activeRole: UserRole.referee` esperando `isProfileCompleteForActiveRole == true`) para reflejar el nuevo criterio completo de HU 25.1 (datos personales + ubicación + categoría + 2 caras de cédula + documento de certificación arbitral).
- **Rationale**: Evita regresiones inesperadas en la suite de dominio al endurecer el criterio de completitud de `UserRole.referee`.
