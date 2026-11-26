# Modelo de Datos (Phase 1): Perfil Completo del Entrenador (HU 27.1)

**Funcionalidad**: `specs/061-coach-profile-colombian-id`  
**Fecha**: 2026-11-26

## 1. Esquema Relacional (`vifutboldev.coach_profiles`)

La tabla `vifutboldev.coach_profiles` se amplía de forma idempotente (`ADD COLUMN IF NOT EXISTS`) conservando todas las columnas y llaves existentes:

| Columna | Tipo | Nulabilidad | Regla / Descripción |
|---------|------|-------------|---------------------|
| `user_account_id` | `uuid` | `PRIMARY KEY`, `NOT NULL` | FK → `vifutboldev.user_accounts(id) ON DELETE CASCADE` (existente). |
| `club_name` | `text` | `NULL` / `''` | Nombre del club o `"Independiente"` (obligatorio en flujo de perfil completo). |
| `license_level` | `text` | `NULL` / `''` | Nivel de licencia técnica o `"Sin licencia"` (obligatorio en flujo de perfil completo). |
| `phone` | `text` | `NULL` / `''` | Teléfono de contacto sincronizado con `user_accounts.phone` (existente). |
| `first_name` | `text` | `NULL` | Primer nombre (obligatorio en app). |
| `second_name` | `text` | `NULL` | Segundo nombre (opcional). |
| `first_surname` | `text` | `NULL` | Primer apellido (obligatorio en app). |
| `second_surname` | `text` | `NULL` | Segundo apellido (opcional). |
| `sex` | `text` | `NULL` | Sexo (`M` / `F` o valor normalizado de `PlayerSex`, obligatorio en app). |
| `birth_date` | `date` | `NULL` | Fecha de nacimiento (obligatorio, edad ≥ 18 años validada en formulario). |
| `blood_type` | `text` | `NULL` | Grupo sanguíneo y factor RH (`O+`, `O-`, `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`). |
| `department` | `text` | `NULL` | Departamento de Colombia del catálogo `ColombiaLocationCatalog`. |
| `municipality` | `text` | `NULL` | Municipio de Colombia dependiente de `department`. |
| `document_front_url` | `text` | `NULL` | Ruta relativa/referencia en bucket privado `player-documents` del frente de la cédula. |
| `document_back_url` | `text` | `NULL` | Ruta relativa/referencia en bucket privado `player-documents` del reverso de la cédula. |
| `created_at` | `timestamptz` | `NOT NULL` | Marca de creación UTC (existente). |
| `updated_at` | `timestamptz` | `NOT NULL` | Marca de actualización UTC (existente). |

> **Nota sobre nulabilidad en BD**: Las nuevas columnas se agregan como `NULL` para no romper registros preexistentes de entrenadores que solo habían completado `club_name` y `license_level`. La completitud obligatoria se evalúa en dominio (`UserAccount.isProfileCompleteForActiveRole`) y en la validación de `CoachPersonalDataScreen`.

## 2. Sincronización con `vifutboldev.user_accounts`

En `vifutboldev.complete_role_profile` cuando `p_active_role = 'coach'`:
- `user_accounts.full_name` se compone a partir de `first_name`, `second_name`, `first_surname`, `second_surname` (o `p_full_name` si se provee explícitamente).
- `user_accounts.document_id` y `user_accounts.normalized_document_id` se actualizan con el número de documento limpiado y normalizado.
- `user_accounts.phone` se actualiza con el teléfono limpiado.
- `coach_profiles` realiza `INSERT ... ON CONFLICT (user_account_id) DO UPDATE` de forma atómica dentro de la misma transacción del RPC.

## 3. Entidades de Dominio (Dart)

### `RoleProfileData` (`lib/domain/entities/role_profile_data.dart`)
Sin cambios estructurales requeridos; ya modela todos los campos necesarios:
- Identidad: `firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `bloodType`.
- Ubicación: `department`, `municipality`.
- Entrenador: `clubName`, `licenseLevel`.
- Documentos: `documentFrontUrl`, `documentBackUrl`.

### `UserAccount.isProfileCompleteForActiveRole` (`lib/domain/entities/user_account.dart`)
Para `UserRole.coach`, retorna `true` únicamente si se cumplen **todas** las condiciones siguientes:
1. `phone` no vacío.
2. `documentId` no vacío.
3. `roleProfile.firstName` no vacío.
4. `roleProfile.firstSurname` no vacío.
5. `roleProfile.sex` no vacío.
6. `roleProfile.birthDate != null`.
7. `roleProfile.bloodType` no vacío.
8. `roleProfile.department` no vacío.
9. `roleProfile.municipality` no vacío.
10. `roleProfile.clubName` no vacío.
11. `roleProfile.licenseLevel` no vacío.
12. `roleProfile.documentFrontUrl` no vacío.
13. `roleProfile.documentBackUrl` no vacío.

*(Campos opcionales: `secondName`, `secondSurname`.)*

## 4. Transiciones de Estado del Perfil del Entrenador

```text
[Perfil Incompleto]
   ├── Entrenador nuevo sin datos en coach_profiles
   └── Entrenador previo con solo club_name / license_level (precargados al abrir formulario)
          │
          │  Completa formulario (≥ 18 años) + escaneo/captura frontal y posterior
          │  + subida privada exitosa + complete_role_profile atómico
          ▼
[Perfil Completo]
   ├── Pestaña Perfil muestra badge "Perfil completo"
   ├── Tap en tarjeta "Datos Personales" → CoachPersonalDataSummaryScreen
   └── Tap en "Editar" → CoachPersonalDataScreen (precargado; fotos existentes preservadas si no se reemplazan)
```
