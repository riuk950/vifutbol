# Phase 1 Data Model: HU 3.1 — Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva

**Feature**: `003-venues-pitches-geolocation`  
**Date**: 2026-11-03

---

## 1. Domain Entities & Value Objects (`lib/domain/entities/`)

### 1.1 `GeoCoordinate` (`lib/domain/entities/geo_coordinate.dart`)
Objeto de valor inmutable que encapsula coordenadas geográficas validadas y cálculo geodésico (`FR-002`, `FR-005`):

| Field | Type | Required | Validation / Description |
|-------|------|----------|--------------------------|
| `latitude` | `double` | Yes | Latitud en grados decimales dentro del rango `[-90.0, 90.0]` (no `NaN` ni infinito). |
| `longitude` | `double` | Yes | Longitud en grados decimales dentro del rango `[-180.0, 180.0]` (no `NaN` ni infinito). |

**Methods & Invariants**:
- `static bool isValidCoordinate(double lat, double lng)`: Verifica que `lat >= -90.0 && lat <= 90.0` y `lng >= -180.0 && lng <= 180.0`.
- `double distanceInKilometersTo(GeoCoordinate other)`: Calcula la distancia en kilómetros utilizando la fórmula geodésica de Haversine con radio terrestre medio `R = 6371.0 km`.
- `static const GeoCoordinate defaultCityCenter = GeoCoordinate(latitude: 4.6097, longitude: -74.0817)`: Coordenada urbana por defecto del campeonato.

---

### 1.2 `PitchSurfaceType`, `PitchFormat` & `VenueOperationalStatus` (`lib/domain/entities/venue_enums.dart`)
Enumeraciones del dominio para caracterizar las sedes y canchas (`FR-001`, `FR-003`):

- **`PitchSurfaceType`**:
  - `syntheticGrass` (*Césped Sintético*)
  - `naturalGrass` (*Césped Natural*)
  - `dirtOrSand` (*Tierra / Arena*)
  - `hardCourt` (*Cemento / Futsal*)
- **`PitchFormat`**:
  - `football5` (*Fútbol 5*)
  - `football7` (*Fútbol 7*)
  - `football8` (*Fútbol 8*)
  - `football11` (*Fútbol 11*)
- **`VenueOperationalStatus`**:
  - `active` (*Activa* — disponible para programación de partidos)
  - `maintenance` (*Mantenimiento* — visible en consulta pero bloqueada para nuevas asignaciones)

---

### 1.3 `VenuePitch` (`lib/domain/entities/venue_pitch.dart`)
Representa una cancha individual dentro de una sede deportiva (`FR-003`):

| Field | Type | Required | Validation / Description |
|-------|------|----------|--------------------------|
| `id` | `String` | Yes | Identificador único inmutable (`UUID`). |
| `name` | `String` | Yes | Nombre de la cancha (`>= 2` caracteres, ej. *"Cancha Norte"*, *"Cancha Sintética 1"*). |
| `surfaceType` | `PitchSurfaceType` | Yes | Tipo de superficie del terreno de juego. |
| `format` | `PitchFormat` | Yes | Formato o modalidad deportiva (`Fútbol 5/7/8/11`). |
| `capacity` | `int` | Yes | Capacidad aproximada de espectadores (`>= 0`). |
| `hasLighting` | `bool` | Yes | `true` si cuenta con iluminación artificial para partidos nocturnos. |
| `status` | `VenueOperationalStatus` | Yes | Estado operativo (`active` o `maintenance`). |

---

### 1.4 `SportsVenue` (`lib/domain/entities/sports_venue.dart`)
Representa el complejo o sede deportiva urbana (`FR-001`, `FR-002`, `FR-007`):

| Field | Type | Required | Validation / Description |
|-------|------|----------|--------------------------|
| `id` | `String` | Yes | Identificador único inmutable (`UUID`). |
| `name` | `String` | Yes | Nombre oficial de la sede (`>= 3` caracteres). |
| `address` | `String` | Yes | Dirección física urbana (`>= 5` caracteres). |
| `urbanReference` | `String` | Yes | Referencia urbana o indicaciones de llegada (puede ser vacía o descriptiva). |
| `coordinate` | `GeoCoordinate` | Yes | Coordenadas geográficas validadas de la sede. |
| `pitches` | `List<VenuePitch>` | Yes | Lista no vacía (`>= 1` cancha) de canchas asociadas a la sede. |
| `status` | `VenueOperationalStatus` | Yes | Estado operativo general de la sede (`active` o `maintenance`). |
| `updatedAt` | `DateTime` | Yes | Marca de tiempo de última actualización. |

**Computed Helpers**:
- `int get activePitchesCount`: Cantidad de canchas en estado `VenueOperationalStatus.active`.
- `bool get isEligibleForFixtures`: `status == VenueOperationalStatus.active && activePitchesCount > 0`.
- `bool get hasNightLighting`: `true` si al menos una cancha interna tiene `hasLighting == true`.

---

### 1.5 `LocationPermissionState` (`lib/domain/entities/location_permission_state.dart`)
Modela el estado del permiso de ubicación del dispositivo y la coordenada actual en memoria (`FR-005`, `FR-006`, `FR-009`):

- **`LocationPermissionStatus` (Enum)**:
  - `notRequested`: Aún no solicitado; se pedirá *just-in-time*.
  - `granted`: Permiso concedido; `userCoordinate` disponible para calcular distancias.
  - `denied`: Rechazado temporalmente; permite reintentar en contexto.
  - `permanentlyDenied`: Revocado en ajustes del sistema; ofrece guía discreta y opera con centro urbano por defecto.
  - `serviceDisabled`: Servicio GPS desactivado en el dispositivo.
- **Fields**:
  - `status`: `LocationPermissionStatus`
  - `userCoordinate`: `GeoCoordinate?` (solo en memoria; jamás se serializa ni escribe en logs)

**Invariants**:
- `toString()` NUNCA expone `userCoordinate` en texto plano (`[REDACTED_USER_LOCATION]`) para cumplir `FR-009`.

---

### 1.6 `VenuesCatalogState` (`lib/domain/entities/venues_catalog_state.dart`)
Estado inmutable gestionado por `VenuesController`:
- `viewState`: `UiViewState` (`loading`, `content`, `empty`, `error`, `success`)
- `venues`: `List<SportsVenue>`
- `selectedVenueId`: `String?`
- `searchQuery`: `String`
- `surfaceFilter`: `PitchSurfaceType?`
- `onlyWithLighting`: `bool`
- `sortByProximity`: `bool`
- `locationState`: `LocationPermissionState`
- `isSubmitting`: `bool` (bloqueo *single-flight*)
- `draftVenueName`: `String`
- `draftAddress`: `String`
- `draftUrbanReference`: `String`
- `lastFailure`: `AppFailure?`

**State Transitions**:
```text
[Tab Sedes Open] ──> loading ──(read local/seed catalog)──> content (or empty if 0 venues)
content ──(User taps "Mi ubicación" / "Cercanía")──> Request Permission Just-in-Time
  ├──(granted)──> Calculate Haversine distance (km) & sort by proximity
  └──(denied / permanentlyDenied)──> Keep map centered on defaultCityCenter + show non-intrusive Spanish banner
content ──(Organizer opens Venue Form & submits valid venue + >=1 pitch)──> isSubmitting=true ──> Persist & emit success/content
content ──(Organizer toggles status Active <-> Maintenance)──> Persist logical status update
```
