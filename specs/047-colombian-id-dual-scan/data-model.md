# Data Model: Escaneo Dual de Cédula Colombiana (HU 21.2)

**Feature**: `047-colombian-id-dual-scan`  
**Date**: 2026-11-17

## 1. Domain Value Objects & Entities

### `ColombianIdScanSource` (`lib/domain/entities/colombian_id_scan_result.dart`)
- `pdf417` — Datos extraídos principalmente del código bidimensional PDF417 (cédula amarilla).
- `mrzOcr` — Datos extraídos mediante bloque MRZ TD1 e inferencia OCR (cédula digital / policarbonato).
- `partial` — Lectura parcial o combinada donde algunos campos no pudieron extraerse.
- `none` — Ningún dato estructurado pudo leerse; solo se conservan las imágenes capturadas.

### `ColombianIdScanResult` (`lib/domain/entities/colombian_id_scan_result.dart`)
| Field | Dart Type | Description |
|-------|-----------|-------------|
| `documentId` | `String?` | Número de cédula / NUIP limpio (solo dígitos) |
| `firstName` | `String?` | Primer nombre normalizado |
| `secondName` | `String?` | Segundo nombre normalizado (opcional) |
| `firstSurname` | `String?` | Primer apellido normalizado |
| `secondSurname` | `String?` | Segundo apellido normalizado (opcional) |
| `sex` | `PlayerSex?` | Sexo (`male`, `female`, `other`) |
| `birthDate` | `DateTime?` | Fecha de nacimiento |
| `bloodType` | `BloodType?` | Tipo de sangre / RH |
| `source` | `ColombianIdScanSource` | Fuente principal de extracción |
| `hasAnyField` | `bool` (getter) | `true` si al menos un campo fue extraído |

### `PlayerDocumentCapture` (`lib/domain/entities/colombian_id_scan_result.dart`)
| Field | Dart Type | Description |
|-------|-----------|-------------|
| `frontImagePath` | `String?` | Ruta local temporal/caché de la cara frontal recién capturada |
| `backImagePath` | `String?` | Ruta local temporal/caché de la cara posterior recién capturada |
| `frontRemoteUrl` | `String?` | URL o referencia remota persistida de la cara frontal |
| `backRemoteUrl` | `String?` | URL o referencia remota persistida de la cara posterior |
| `hasFront` | `bool` (getter) | `frontImagePath` o `frontRemoteUrl` no vacío |
| `hasBack` | `bool` (getter) | `backImagePath` o `backRemoteUrl` no vacío |
| `isComplete` | `bool` (getter) | `hasFront && hasBack` |

## 2. Extended Domain Entities

### `RoleProfileData` (`lib/domain/entities/role_profile_data.dart`)
Se agregan dos campos persistentes:
| Field | Dart Type | JSON Keys (`camel` / `snake`) | Validation / Notes |
|-------|-----------|-------------------------------|--------------------|
| `documentFrontUrl` | `String?` | `documentFrontUrl` / `document_front_url` | Obligatorio para `UserRole.player` |
| `documentBackUrl` | `String?` | `documentBackUrl` / `document_back_url` | Obligatorio para `UserRole.player` |

### `UserAccount.isProfileCompleteForActiveRole` (`lib/domain/entities/user_account.dart`)
Actualización para `UserRole.player` (incorporando Q1):
```dart
case UserRole.player:
  return hasPhone &&
      hasDoc &&
      _hasText(roleProfile?.firstName) &&
      _hasText(roleProfile?.firstSurname) &&
      _hasText(roleProfile?.sex) &&
      roleProfile?.birthDate != null &&
      _hasText(roleProfile?.bloodType) &&
      _hasText(roleProfile?.department) &&
      _hasText(roleProfile?.municipality) &&
      (roleProfile?.secondaryPositions.isNotEmpty ?? false) &&
      _hasText(roleProfile?.documentFrontUrl) &&
      _hasText(roleProfile?.documentBackUrl);
```

## 3. Database & Storage Migration (`supabase/migrations/202611170003_player_document_images.sql`)

### Columns Added to `vifutboldev.players`
```sql
ALTER TABLE vifutboldev.players
  ADD COLUMN IF NOT EXISTS document_front_url text,
  ADD COLUMN IF NOT EXISTS document_back_url text;
```

### Private Storage Bucket `player-documents` & RLS Policies
- Bucket id: `'player-documents'`, `public = false`, `file_size_limit = 5242880` (5 MB), `allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']`.
- Políticas RLS sobre `storage.objects`:
  - `SELECT`, `INSERT`, `UPDATE`, `DELETE` para rol `authenticated` únicamente cuando `bucket_id = 'player-documents'` y `(storage.foldername(name))[1] = (SELECT auth.uid())::text`.

### Updated RPC `vifutboldev.complete_role_profile`
- Agrega 2 parámetros opcionales al final (`DEFAULT NULL`):
  - `p_document_front_url text DEFAULT NULL`
  - `p_document_back_url text DEFAULT NULL`
- Persiste en `vifutboldev.players` (`UPDATE` e `INSERT`) y devuelve `'document_front_url'` y `'document_back_url'` dentro de `role_profile` JSONB.
