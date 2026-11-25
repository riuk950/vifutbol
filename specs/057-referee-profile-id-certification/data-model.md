# Data Model: Perfil Completo del Árbitro y Certificación Arbitral (HU 25.1)

**Feature**: `057-referee-profile-id-certification`  
**Date**: 2026-11-25

## Database Schema Extensions (`vifutboldev.match_referees`)

Columnas agregadas de forma idempotente (`ADD COLUMN IF NOT EXISTS`) en `202611250002_referee_profile_and_certification_doc.sql`:

| Columna | Tipo PostgreSQL | Nullable | Descripción |
|---|---|---|---|
| `first_name` | `text` | Sí | Primer nombre del árbitro |
| `second_name` | `text` | Sí | Segundo nombre (opcional) |
| `first_surname` | `text` | Sí | Primer apellido |
| `second_surname` | `text` | Sí | Segundo apellido (opcional) |
| `sex` | `text` | Sí | Sexo (`M` / `F`) |
| `birth_date` | `date` | Sí | Fecha de nacimiento |
| `blood_type` | `text` | Sí | Grupo sanguíneo y factor RH |
| `department` | `text` | Sí | Departamento de Colombia |
| `municipality` | `text` | Sí | Municipio de Colombia |
| `document_front_url` | `text` | Sí | Ruta privada en `player-documents` (`<auth_uid>/document_front.jpg`) |
| `document_back_url` | `text` | Sí | Ruta privada en `player-documents` (`<auth_uid>/document_back.jpg`) |
| `certification_document_url` | `text` | Sí | Ruta privada en `player-documents` (`<auth_uid>/referee_certification.jpg`) |

## Domain Entity Updates

### 1. `RoleProfileData` (`lib/domain/entities/role_profile_data.dart`)
- Nuevo campo: `final String? certificationDocumentUrl;`
- Serialización: `'certificationDocumentUrl'` (JSON local) y `'certification_document_url'` (PostgREST / RPC).

### 2. `UserAccount.isProfileCompleteForActiveRole` (`lib/domain/entities/user_account.dart`)
Para `UserRole.referee`, retorna `true` **únicamente** cuando:
- `phone` no vacío
- `documentId` no vacío
- `roleProfile?.firstName` no vacío
- `roleProfile?.firstSurname` no vacío
- `roleProfile?.sex` no vacío
- `roleProfile?.birthDate != null`
- `roleProfile?.bloodType` no vacío
- `roleProfile?.department` no vacío
- `roleProfile?.municipality` no vacío
- `roleProfile?.certificationLevel` no vacío
- `roleProfile?.documentFrontUrl` no vacío
- `roleProfile?.documentBackUrl` no vacío
- `roleProfile?.certificationDocumentUrl` no vacío

*(Los criterios de `player`, `coach`, `organizer` y `fan` permanecen sin cambios).*
