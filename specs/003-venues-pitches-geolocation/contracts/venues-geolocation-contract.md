# UI, Map & Authorization Contracts: HU 3.1 — Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva

**Feature**: `003-venues-pitches-geolocation`  
**Date**: 2026-11-03

---

## 1. Navigation & Views Contract (`FR-001`, `FR-004`, `FR-008`)

| View / Component | Access Rule | Purpose |
|------------------|-------------|---------|
| `VenuesTabView` (`lib/presentation/shell/tabs/venues_tab_view.dart`) | Todos los roles (Lectura); `Organizador` (Acciones de creación/edición) | Vista principal de la pestaña *Sedes*: buscador, filtros por superficie/iluminación, botón *just-in-time* de cercanía, lienzo *KickPulse Urban Map*, tarjetas de sedes con distancia (`tabular-nums`) y acceso al formulario para el `Organizador`. |
| `KickPulseUrbanMapCanvas` (`lib/presentation/venues/widgets/kick_pulse_urban_map_canvas.dart`) | Todos los roles (Modo exploración); `Organizador` (Modo selector por toque) | Lienzo interactivo *offline-ready* estilizado bajo `DESIGN.md` (`#080B11`, `#0E1422`, `#22C55E`, `#38BDF8`) que renderiza la cuadrícula urbana, marcadores de sedes, posición relativa del usuario (si concedió permiso) y permite seleccionar coordenadas al tocar. |
| `VenueDetailSheet` (`lib/presentation/venues/venue_detail_sheet.dart`) | Todos los roles (Lectura); `Organizador` (Editar / Cambiar estado) | Ficha detallada de una sede deportiva con dirección física, referencia urbana, coordenadas, botón de indicaciones/copia de dirección y listado de todas sus canchas internas (`VenuePitch`). |
| `VenueFormScreen` (`lib/presentation/venues/venue_form_screen.dart`) | Exclusivo `Organizador` (`RoleCapability.manageVenues` + `KickPulseRoleGuard`) | Formulario de creación y edición de sedes deportivas y sus canchas internas con selector en mapa, validación de coordenadas, bloqueo *single-flight*, conservación de borrador en segundo plano y `PopScope` de confirmación al descartar. |

---

## 2. Visual Badges & Surface Tokens Contract (`DESIGN.md` — `FR-001`, `FR-003`)

| Element / State | Spanish Label (`app_es.arb`) | `KickPulseBadgeVariant` | Semantic Accent |
|-----------------|------------------------------|-------------------------|-----------------|
| `VenueOperationalStatus.active` | `Activa` | `dev` / `info` | `#22C55E` / `#38BDF8` (Habilitada para partidos) |
| `VenueOperationalStatus.maintenance` | `En mantenimiento` | `warning` | `#F59E0B` (Bloqueada para nuevas asignaciones) |
| `PitchSurfaceType.syntheticGrass` | `Césped Sintético` | `info` | `#38BDF8` |
| `PitchSurfaceType.naturalGrass` | `Césped Natural` | `neutral` | `#22C55E` |
| `PitchSurfaceType.dirtOrSand` | `Tierra / Arena` | `warning` | `#F59E0B` |
| `PitchSurfaceType.hardCourt` | `Cemento / Futsal` | `neutral` | `#94A3B8` |

---

## 3. Location Permission & Fallback Contract (`FR-005`, `FR-006`, `FR-009`)

1. **Solicitud en Contexto (*Just-in-Time*)**:
   - Al abrir la pestaña *Sedes*, el mapa se centra inicialmente en el centro urbano o primera sede activa sin disparar diálogos intrusivos del sistema operativo.
   - Cuando el usuario pulsa *"Mi ubicación / Cercanía"*, se invoca `LocationPermissionRepository.requestPermissionAndLocation()`.
2. **Permiso Concedido (`granted`)**:
   - Muestra el indicador del usuario en `KickPulseUrbanMapCanvas`, calcula la distancia en km (`GeoCoordinate.distanceInKilometersTo`) con `tabular-nums` (ej. `2.4 km`) en cada tarjeta y ordena las sedes de menor a mayor distancia.
3. **Permiso Denegado o Revocado (`denied` / `permanentlyDenied` / `serviceDisabled`)**:
   - Cero bloqueos: mantiene visible el mapa centrado en la sede/ciudad y el listado completo de sedes con su dirección textual y referencia urbana.
   - Muestra un banner discreto en español (*"Ubicación desactivada: mostrando sedes por referencia urbana"*) con botón de `>= 44x44px` para reintentar o habilitar permisos.
4. **Simulador de Permisos en Entorno `DEV`**:
   - Cuando `EnvironmentConfig.environment == AppEnvironment.development`, se muestra una barra compacta de prueba que permite alternar instantáneamente entre `Concedido`, `Denegado` y `Revocado` para verificar la resiliencia móvil en vivo.
