# Phase 0 Research: HU 3.1 — Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva

**Feature**: `003-venues-pitches-geolocation`  
**Date**: 2026-11-03

---

## 1. Lienzo Interactivo *KickPulse Urban Map* y Cálculo Geodésico Determinista (`FR-002`, `FR-004`, `FR-005`)

- **Decision**: Implementar el mapa urbano y selector de coordenadas mediante un componente nativo en Flutter (`KickPulseUrbanMapCanvas` con `CustomPainter` táctico de alto contraste adherido a `DESIGN.md`) y una entidad de valor pura `GeoCoordinate` en `lib/domain/entities/geo_coordinate.dart` que valida rangos (`latitud` en `[-90, 90]`, `longitud` en `[-180, 180]`) y calcula la distancia exacta en kilómetros mediante la fórmula geodésica de Haversine.
- **Rationale**:
  - Funciona al 100% tanto en línea como sin conexión (*offline*) sin depender de llaves de API comerciales sujetas a cuotas de facturación ni requerir configuración nativa propietaria en simuladores o pipelines de pruebas automatizadas (`flutter test`).
  - Permite a cualquier usuario tocar los marcadores de las sedes sobre el radar urbano de la ciudad, ver su posición relativa cuando concede el permiso de ubicación y permite al `Organizador` seleccionar coordenadas con un toque sobre el mapa o ingresándolas numéricamente.
- **Alternatives considered**:
  - *Integrar un SDK de mapas propietario con llaves de facturación externas*: Descartado porque rompe la capacidad 100% *offline* sin precarga de teselas externas y bloquea la ejecución determinista en entornos de pruebas sin llaves de API.

---

## 2. Gestión Resiliente de Permisos de Ubicación (*Just-in-Time*) y Simulador en `dev` (`FR-005`, `FR-006`, `FR-009`)

- **Decision**: Abstraer la consulta de localización tras el contrato de dominio `LocationPermissionRepository` (`lib/domain/repositories/location_permission_repository.dart`) que gestiona los estados `notRequested`, `granted`, `denied`, `permanentlyDenied` y `serviceDisabled`.
- **Rationale**:
  - Solicita el permiso únicamente en contexto (*just-in-time*) cuando el usuario pulsa *"Mi ubicación"* / *"Ordenar por cercanía"*.
  - Si el permiso es rechazado, revocado o el GPS está apagado, la aplicación jamás se bloquea: centra el mapa en las coordenadas urbanas de referencia (`4.6097, -74.0817`), muestra el listado completo con direcciones físicas y referencias urbanas, y presenta un banner discreto en español para habilitar o reintentar el permiso.
  - En `AppEnvironment.development`, expone un conmutador rápido para simular en tiempo real los estados *Concedido*, *Denegado* y *Revocado*, facilitando la validación móvil completa.
  - Cumple `FR-009`: la coordenada del usuario solo vive en memoria volátil del controlador para calcular distancias y nunca se escribe en disco ni en logs.
- **Alternatives considered**:
  - *Exigir permiso de GPS al arrancar la aplicación*: Descartado por infringir `docs/MOBILE_GUIDELINES.md` (solicitar permisos solo en contexto y proveer alternativa funcional).

---

## 3. Baja Lógica (*Activa* / *Mantenimiento*) y Catálogo Semilla Aislado por Entorno (`FR-001`, `FR-003`, `FR-007`)

- **Decision**: Persistir el catálogo de sedes (`SportsVenue`) y sus canchas internas (`VenuePitch`) en `LocalStorageRepository` bajo la clave aislada `venues_catalog` (separada entre `vifutbol_dev` y `vifutbol_prod`), aplicando baja lógica mediante `VenueOperationalStatus` (`active`, `maintenance`) y precargando `3` sedes urbanas semilla con múltiples canchas cuando `vifutbol_dev` se inicializa por primera vez.
- **Rationale**:
  - Protege la integridad referencial e histórica del campeonato (Principio II de la Constitución): ninguna sede o cancha vinculada a partidos se elimina físicamente; al pasar a `maintenance`, muestra una insignia de advertencia (`KickPulseBadgeVariant.warning`) y queda bloqueada para nuevas asignaciones de calendario.
  - Garantiza carga offline en `< 2s` (`SC-003`) y permite probar de inmediato en `dev` la búsqueda, el filtro por superficie/iluminación y la vista geográfica.
- **Alternatives considered**:
  - *Eliminación física (Hard Delete) de sedes*: Descartado porque dejaría huérfanos los partidos históricos o programados en dicha sede.

---

## 4. Segregación RBAC (`manageVenues`) y Conservación de Borradores en Ciclo de Vida (`FR-001`, `FR-008`)

- **Decision**: Proteger todas las acciones y formularios de creación, edición y cambio de estado operativo mediante `RoleCapability.manageVenues` (tanto en `ManageVenuesUseCase` como en la UI con `KickPulseRoleGuard`), y conservar el borrador del formulario de sede en `VenuesController` junto con confirmación en `PopScope` ante salidas con cambios sin guardar.
- **Rationale**:
  - Asegura que únicamente el rol `Organizador` pueda crear o modificar sedes y canchas (`SC-004`), mientras que `Entrenador`, `Árbitro`, `Jugador` y `Aficionado` acceden en modo consulta pública.
  - Evita pérdida de datos si el organizador recibe una llamada o cambia de aplicación mientras registra una sede con varias canchas internas.
- **Alternatives considered**:
  - *Validar el rol únicamente ocultando el botón en la UI*: Descartado porque el caso de uso y el repositorio también deben validar o integrarse con la matriz de permisos del dominio.
