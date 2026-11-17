# Research & Technical Decisions: Formulario de Datos Personales del Jugador (HU 21.1)

**Feature**: `046-player-personal-data-form`  
**Date**: 2026-11-17

## Decision 1: Catálogo Local Oficial de Colombia (32 Departamentos + Bogotá D.C.)

- **Decision**: Empaquetar el catálogo completo oficial de los 32 departamentos de Colombia más Bogotá D.C. y la totalidad de sus municipios oficiales (~1.122 municipios del DANE) como constante inmutable de Dart (`lib/domain/data/colombia_municipalities_data.dart`), envuelto por un servicio de consulta puro (`ColombiaLocationCatalog`) con búsqueda insensible a mayúsculas y tildes (normalización diacrítica).
- **Rationale**:
  - Disponibilidad síncrona (`< 1 ms`) sin latencia de carga asíncrona ni dependencia de red en canchas y sedes deportivas.
  - Tamaño reducido (~30 KB en Dart compilado AOT), sin incrementar dependencias externas ni requerir `rootBundle` en pruebas unitarias puras.
  - Búsqueda normalizada (ej. escribir `"medellin"` encuentra `"Medellín"`, `"bogota"` encuentra `"Bogotá, D.C."`) mejora drásticamente la usabilidad en departamentos extensos como Antioquia (125 municipios) o Boyacá (123 municipios).
- **Alternatives Considered**:
  - *Archivo JSON en `assets/` cargado con `rootBundle`*: Rechazado por introducir estados de carga asíncronos innecesarios y complejidad adicional en pruebas unitarias de dominio.
  - *Tabla remota en Supabase*: Rechazado porque incumpliría `SC-003` (carga instantánea sin conexión a internet).

## Decision 2: Representación Canónica de Posiciones Múltiples, Sexo y RH

- **Decision**:
  - Definir `DetailedFootballPosition` (15 valores enum en inglés siguiendo Constitución Principio VI) con propiedades `code` (`POR`, `DFC`, `LD`, `LI`, `CAD`, `CAI`, `MCD`, `MC`, `MCO`, `MD`, `MI`, `ED`, `EI`, `MP`, `DC`) y `tacticalLine` (`PlayerPosition`).
  - Definir `PlayerSex` (`male`, `female`, `other`) y `BloodType` (`oPositive`..`abNegative` con `label`: `O+`, `O-`, `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`).
  - Persistir `secondary_positions` en Postgres como `text[]` de códigos tácticos (`['LD', 'CAD']`), `position` como la línea táctica principal (`'defender'`), `sex` como identificador canónico (`'male'`, `'female'`, `'other'`) y `blood_type` como cadena estándar (`'O+'`..`'AB-'`).
  - Proveer parsers tolerantes (`PlayerSex.fromRaw`, `DetailedFootballPosition.fromCode`) que acepten tanto formatos canónicos como abreviaturas de cédula (`'M'`, `'F'`) para compatibilidad directa con HU 21.2 (escaneo PDF417 + MRZ).
- **Rationale**: Mantiene 100% de compatibilidad con `PlayerPosition` usado en HU 20.1 / HU 20.2 y cumple estrictamente con el principio de identificadores técnicos en inglés y etiquetas localizadas en español vía `AppLocalizations`.
- **Alternatives Considered**:
  - *Guardar textos localizados en español en la columna `sex`*: Rechazado para preservar uniformidad con las demás columnas enum en `vifutboldev` (`active_role`, `position`, `status`).

## Decision 3: Persistencia Unificada en `RoleProfileData` + Extensión de `complete_role_profile` RPC

- **Decision**:
  - Extender `RoleProfileData` con los 10 nuevos atributos del jugador (`firstName`, `secondName`, `firstSurname`, `secondSurname`, `sex`, `birthDate`, `bloodType`, `department`, `municipality`, `primaryPosition`, `secondaryPositions`) manteniendo todos los campos existentes intactos.
  - Agregar el parámetro opcional `String? fullName` a `AuthRepository.updateRoleProfile` y `AuthController.updateRoleProfile` para sincronizar el nombre completo concatenado (`primer_nombre + segundo_nombre + primer_apellido + segundo_apellido`) tanto en `vifutboldev.user_accounts` como en `vifutboldev.players`.
  - Crear la migración idempotente `supabase/migrations/202611170002_player_personal_profile_fields.sql` que añade las 10 columnas a `vifutboldev.players` y actualiza la función RPC atómica `vifutboldev.complete_role_profile` (reemplazando la firma anterior tras `DROP FUNCTION` para evitar sobrecargas ambiguas en PostgREST) y actualizar `_PostgrestUserProfileDataSource.fetchRoleProfileDetails` para hidratar todos los campos del jugador al restaurar sesión.
- **Rationale**: Reutiliza exactamente el mismo pipeline seguro, transaccional y probado de la HU 19.4 (incluyendo la vinculación no duplicada por `normalized_document_id` y rechazo `DOCUMENT_ALREADY_LINKED` si la cédula pertenece a otro usuario), evitando duplicar lógica de autenticación o crear endpoints paralelos.
- **Alternatives Considered**:
  - *Crear un repositorio y controlador separado `PlayerPersonalProfileRepository`*: Rechazado porque fragmentaría el estado de `UserAccount` / `AuthSession`, complicaría la evaluación reactiva de `isProfileCompleteForActiveRole` en `ProfileTabView` y duplicaría la lógica de vinculación de documento.

## Decision 4: Navegación y UX de Pantalla Dedicada para el Jugador

- **Decision**:
  - Crear `PlayerPersonalDataScreen` en `lib/presentation/shell/tabs/player_personal_data_screen.dart` y registrarla en `AppRouter` bajo `/profile/personal-data`.
  - En `ProfileTabView`:
    - Si `activeRole == UserRole.player`, el botón `"Completar mi perfil"` navega a `/profile/personal-data`.
    - Mostrar una tarjeta permanente `"Datos Personales"` (junto a `"Solicitudes de Equipos"`) para usuarios autenticados con rol `player` (activo o autorizado) para consultar o editar su ficha en cualquier momento.
    - Para los demás roles (`coach`, `organizer`, `referee`, `fan`), mantener `CompleteProfileDialog.show(...)` sin alteraciones.
  - Implementar `SearchableLocationPickerSheet` (modal bottom sheet con `TextField` de búsqueda en vivo + `ListView.builder`) para seleccionar Departamento y Municipio en cascada, garantizando fluidez en pantallas de 320px/360px a 130% de escala tipográfica.
- **Rationale**: Cumple con las clarificaciones de sesión (Opción A en Q1, Opción B en Q2, Opción B en Q3, Opción A en Q4) y deja la pantalla lista para acoplar los botones de escaneo de cédula (HU 21.2) y foto de avatar (HU 21.3).
- **Alternatives Considered**:
  - *Expandir `CompleteProfileDialog` con todos los campos*: Descartado en clarificación por saturación visual en pantallas pequeñas.
