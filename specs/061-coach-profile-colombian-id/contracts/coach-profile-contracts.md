# Contratos de Interfaz (Phase 1): Perfil Completo del Entrenador (HU 27.1)

**Funcionalidad**: `specs/061-coach-profile-colombian-id`  
**Fecha**: 2026-11-26

## 1. Contrato SQL RPC: `vifutboldev.complete_role_profile`

- **Firma**: Se conserva exactamente la firma vigente de 28 parámetros (sin cambios disruptivos).
- **Parámetros relevantes para `p_active_role = 'coach'`**:
  - `p_active_role`: `'coach'`
  - `p_full_name`, `p_phone`, `p_document_id`
  - `p_club_name`, `p_license_level`
  - `p_first_name`, `p_second_name`, `p_first_surname`, `p_second_surname`
  - `p_sex`, `p_birth_date`, `p_blood_type`
  - `p_department`, `p_municipality`
  - `p_document_front_url`, `p_document_back_url`
- **Garantía de atomicidad**: Actualiza `vifutboldev.user_accounts` y realiza `INSERT ... ON CONFLICT (user_account_id) DO UPDATE` sobre `vifutboldev.coach_profiles` en una única transacción `SECURITY DEFINER`.
- **Contrato de retorno (`jsonb`)**: Incluye en `role_profile` los valores hidratados de `v_coach_row` (`club_name`, `license_level`, `first_name`, `second_name`, `first_surname`, `second_surname`, `sex`, `birth_date`, `blood_type`, `department`, `municipality`, `document_front_url`, `document_back_url`), priorizando `v_coach_row` cuando `p_active_role = 'coach'`.
- **Nota de actualización de campos opcionales**: Al editar un perfil de entrenador existente, si `p_second_name` o `p_second_surname` se envía como cadena vacía (`''`), el `ON CONFLICT DO UPDATE` actualiza la columna a `NULL` (limpieza explícita); si se envía `NULL` (parámetro omitido), conserva el valor existente.

## 2. Contrato de Almacenamiento Privado (`player-documents`)

- **Bucket**: `player-documents` (privado, RLS restringido a `auth.uid()`).
- **Subida**: `DocumentStorageRepository.uploadDocumentImage(userId, localFilePath, side: 'front' | 'back')` → retorna la ruta privada persistida en `document_front_url` / `document_back_url`.
- **Lectura en pantalla resumen y edición**: `DocumentStorageRepository.createSignedUrl(storagePath)` → genera URL firmada temporal para mostrar miniaturas en línea y visor ampliado a pantalla completa únicamente al propietario autenticado.
- **Reemplazo selectivo**: Si el entrenador en modo edición no selecciona una nueva imagen local para una cara (`front` o `back`), se conserva la referencia remota existente sin re-subir ni borrar la imagen previa.

## 3. Contrato de Rutas de Navegación (`AppRouter`)

| Ruta | Pantalla | Acceso |
|------|----------|--------|
| `/profile/coach-personal-data` | `CoachPersonalDataScreen` | Desde botón "Completar perfil" en `ProfileTabView`, desde la tarjeta de datos personales cuando el perfil está incompleto, o desde el botón "Editar" en `CoachPersonalDataSummaryScreen`. |
| `/profile/coach-personal-data/summary` | `CoachPersonalDataSummaryScreen` | Desde la tarjeta de datos personales en `ProfileTabView` cuando `user.isProfileCompleteForActiveRole == true` para `UserRole.coach`. |

## 4. Contrato de UI y Claves de Widget (para Pruebas y Accesibilidad)

- **`ProfileTabView`**:
  - Tarjeta de datos personales del entrenador: `Key('profile_coach_personal_data_tile')` (visible solo para usuarios autenticados con rol `coach`).
  - Botón `ValueKey('profile_complete_action_button')`: cuando `activeRole == UserRole.coach`, navega a `/profile/coach-personal-data`.
- **`CoachPersonalDataScreen`**:
  - Escaneo dual de cédula (`MlkitColombianIdScannerService`) con autocompletado y feedback en español.
  - Captura frontal y posterior (`IdDocumentCaptureCard`).
  - Validación de mayoría de edad (≥ 18 años), campos obligatorios (incluyendo `clubName` y `licenseLevel` con soporte para `"Independiente"` / `"Sin licencia"`), bloqueo `single-flight` durante guardado, y confirmación de cambios sin guardar (`PopScope`).
- **`CoachPersonalDataSummaryScreen`**:
  - Botón de edición `ValueKey('coach_summary_edit_action')`.
  - Tarjetas: cabecera (`coach_summary_header_card`), demografía y ubicación (`coach_summary_demographics_card`), datos técnicos (`coach_summary_technical_card`), y documentación (`coach_summary_documentation_card`) con miniaturas en línea y toque para ampliar.
