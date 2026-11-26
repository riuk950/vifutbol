# Investigación Técnica (Phase 0): Perfil Completo del Entrenador (HU 27.1)

**Funcionalidad**: `specs/061-coach-profile-colombian-id`  
**Fecha**: 2026-11-26

## Decisiones Técnicas Consolidadas

### 1. Reutilización de `RoleProfileData` y RPC `complete_role_profile`
- **Decisión**: Reutilizar la entidad existente `RoleProfileData` (que ya cuenta con `firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `clubName`, `licenseLevel`, `documentFrontUrl`, `documentBackUrl`) y mantener la firma actual de 28 parámetros de `vifutboldev.complete_role_profile`.
- **Justificación**: `RoleProfileData` y `SupabaseAuthRemoteDataSource.completeRoleProfile(...)` ya envían los 28 parámetros al RPC. Mantener la firma intacta evita cualquier cambio disruptivo en los flujos de jugador, árbitro, organizador y aficionado, reduciendo el cambio SQL a ampliar `vifutboldev.coach_profiles`, actualizar el `INSERT ... ON CONFLICT` de `p_active_role = 'coach'` y la hidratación `jsonb_build_object` de retorno.
- **Alternativas consideradas**:
  - Crear un RPC nuevo `complete_coach_profile`: descartado porque duplica lógica de autenticación, normalización de documento, actualización atómica de `user_accounts` e hidratación de sesión.

### 2. Almacenamiento Privado de Fotografías de Cédula
- **Decisión**: Reutilizar el bucket privado `player-documents` en Supabase Storage y `SupabaseDocumentStorageRepository` (`documentStorageServiceProvider`), que ya implementa políticas RLS estrictas por propietario (`auth.uid()`), subida de cara frontal/posterior (`uploadDocumentImage`) y generación de URLs firmadas temporales (`createSignedUrl`).
- **Justificación**:
  - Cumple con la regla de seguridad RLS restringida al propietario (`auth.uid()`) sin crear infraestructura redundante.
  - La función `vifutboldev.delete_my_account()` ya elimina automáticamente los objetos bajo `bucket_id IN ('player-avatars', 'player-documents')` pertenecientes a `v_auth_uid`, y el borrado de `user_accounts` elimina `coach_profiles` vía `ON DELETE CASCADE`.
  - Mantiene paridad total con los roles `player` y `referee` (que ya almacenan sus cédulas en `player-documents` y las visualizan en resumen con URLs firmadas temporales).
- **Alternativas consideradas**:
  - Crear un bucket separado `coach-documents`: descartado por duplicar políticas RLS y obligar a modificar `delete_my_account()` y el repositorio de almacenamiento sin beneficio funcional.

### 3. Escaneo Dual de Cédula Colombiana y Captura de Ambos Lados
- **Decisión**: Reutilizar directamente `MlkitColombianIdScannerService` (vía `colombianIdScannerProvider`) para escaneo PDF417 + MRZ OCR y el widget `IdDocumentCaptureCard` con `PlayerDocumentCapture` para la captura, previsualización y reemplazo selectivo de cara frontal y posterior.
- **Justificación**: Cumple literalmente la regla de paridad con el rol jugador y la HU 27.1, garantizando consistencia de UX, permisos de cámara/galería en español y pruebas preexistentes del escáner.
- **Alternativas consideradas**:
  - Construir un componente de captura específico para entrenadores: descartado por violar DRY y riesgo de divergencia de UX.

### 4. Validación de Edad Mínima (≥ 18 años) y Campos Técnicos (Club / Licencia)
- **Decisión**:
  - Edad mínima: validar en `CoachPersonalDataScreen` que `PlayerPersonalDataUtils.calculateAge(birthDate) >= 18` y que la fecha no sea futura.
  - Club (`clubName`): campo de texto obligatorio con texto de ayuda en español sugiriendo indicar `"Independiente"` si no pertenece a un club.
  - Nivel de licencia (`licenseLevel`): selector con opciones estándar en español (`Sin licencia`, `Licencia C`, `Licencia B`, `Licencia A`, `Licencia PRO`, `Otra`) con compatibilidad hacia atrás si un entrenador previo tenía un valor textual distinto almacenado en `coach_profiles.license_level`.
- **Justificación**: Refleja exactamente las clarificaciones acordadas (Q1 y Q2) y preserva datos precargados de entrenadores preexistentes sin romper formularios con valores heredados.
- **Alternativas consideradas**:
  - Permitir `clubName` o `licenseLevel` vacíos: rechazado porque contradice Q1 y el criterio estricto de `Perfil completo`.

### 5. Pantalla Resumen del Entrenador y Visualización de Miniaturas
- **Decisión**: Implementar `CoachPersonalDataSummaryScreen` siguiendo el patrón visual de `RefereePersonalDataSummaryScreen` y `PlayerPersonalDataSummaryScreen`, mostrando:
  - Tarjeta de cabecera (nombre completo, documento `CC`, edad calculada).
  - Tarjeta demográfica y de ubicación (sexo, fecha de nacimiento, RH, teléfono, departamento, municipio).
  - Tarjeta de acreditación técnica (club y nivel de licencia).
  - Tarjeta de documentación con miniaturas en línea de ambos lados de la cédula cargadas mediante URLs firmadas temporales (`createSignedUrl`) y visor a pantalla completa al tocar cada miniatura.
  - Botón `Editar` en la barra superior que navega a `/profile/coach-personal-data`.
- **Justificación**: Cumple exactamente Q3 y mantiene coherencia total con el Design System `KickPulse`.
- **Alternativas consideradas**:
  - Ocultar las imágenes detrás de un badge sin miniatura: descartado tras confirmación de Q3 (Opción A).

### 6. Hidratación de `fetchRoleProfileDetails` y Prioridad Multi-Rol
- **Decisión**: Actualizar `SupabaseAuthRemoteDataSource.fetchRoleProfileDetails` en `lib/infrastructure/auth/supabase_auth_repository.dart` para consultar las 11 nuevas columnas de `coach_profiles` y fusionarlas en el mapa `role_profile`, y actualizar el `COALESCE` en `complete_role_profile` para incluir `v_coach_row` (priorizando `v_coach_row` cuando `p_active_role = 'coach'`).
- **Justificación**: Garantiza que tanto al guardar (`complete_role_profile`) como al restaurar sesión (`fetchRoleProfileDetails`) el entrenador siempre hidrate completamente sus datos personales y URLs de cédula.
