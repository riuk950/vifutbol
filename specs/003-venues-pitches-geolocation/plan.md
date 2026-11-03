# Implementation Plan: HU 3.1 — Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva

**Branch**: `003-venues-pitches-geolocation` | **Date**: 2026-11-03 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/003-venues-pitches-geolocation/spec.md)

**Input**: Feature specification from `/specs/003-venues-pitches-geolocation/spec.md`

## Summary

Implementar el módulo completo de gestión de sedes deportivas, canchas internas urbanas y geolocalización resiliente para la pestaña *Sedes* cumpliendo la Constitución v2.0.0:
1. **Administración Exclusiva por Organizador (`US1`)**: Creación, edición y baja lógica (`Activa` / `En mantenimiento`) de sedes deportivas (`SportsVenue`) y sus canchas internas (`VenuePitch`: superficie, formato `Fútbol 5/7/8/11`, capacidad e iluminación) protegidas mediante `RoleCapability.manageVenues` y `KickPulseRoleGuard`.
2. **Consulta Geolocalizada y Lienzo *KickPulse Urban Map* (`US2`)**: Mapa interactivo *offline-ready* (`KickPulseUrbanMapCanvas`) con marcadores por sede, selección de coordenadas por toque o campos numéricos, cálculo geodésico de distancia en kilómetros (fórmula de Haversine) con numerales tabulares (`tabular-nums`), solicitud de permisos *just-in-time*, alternativa completa sin bloqueos cuando el permiso es rechazado o revocado, y simulador de estados de GPS en `dev`.
3. **Persistencia Offline Aislada y Conservación de Estado (`US3`)**: Almacenamiento local aislado por entorno (`vifutbol_dev` / `vifutbol_prod`) con `3` sedes urbanas semilla en desarrollo, carga offline en `< 2s`, búsqueda/filtrado en tiempo real, conservación de borradores en segundo plano y confirmación al descartar cambios sin guardar.

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter `>=3.11.0`

**Primary Dependencies**: `flutter_localizations` (SDK), `intl`, `flutter_riverpod`, `fluro`, `hive` + `hive_flutter`, `connectivity_plus`, `uuid`, `clock`

**Storage**: Persistencia local aislada por entorno (`vifutbol_dev` / `vifutbol_prod`) mediante `LocalStorageRepository` (`HiveLocalStorageRepository`) bajo la clave `venues_catalog`, con catálogo semilla de 3 sedes urbanas en `dev`.

**Testing**: `flutter_test` (SDK), `mocktail` y `fake_async` para pruebas unitarias de dominio (validación de coordenadas, distancia Haversine y entidades de sede/canchas), infraestructura (persistencia aislada, datos semilla y baja lógica), aplicación (`VenuesController`, permisos *just-in-time*, filtros y borradores) y pruebas de widgets (`VenuesTabView`, `KickPulseUrbanMapCanvas`, `VenueFormScreen`, RBAC y escalado de texto al 130%).

**Target Platform**: iOS y Android (Smartphones en orientación vertical *Portrait*).

**Project Type**: `mobile-app` (Aplicación móvil deportiva *Offline-First*).

**Performance Goals**: Carga offline y online del catálogo de sedes `< 2s`; cálculo geodésico y filtrado instantáneo `< 16ms` (`60 fps`).

**Constraints**: Cero dependencia de llaves de API comerciales externas para renderizar el mapa; flujo alternativo 100% funcional ante permisos de ubicación denegados o revocados; objetivos táctiles `>= 44x44px` con bloqueo *single-flight*; numerales tabulares (`tabular-nums`) para distancias y capacidades; 0 textos *hardcoded* fuera de `l10n`; 0 coordenadas privadas del usuario en disco o logs (`FR-009`).

**Scale/Scope**: Cubre el catálogo de sedes urbanas, múltiples canchas por sede, buscador y filtros por superficie/iluminación/cercanía, el lienzo interactivo `KickPulseUrbanMapCanvas`, la hoja de detalle `VenueDetailSheet` y la pantalla `VenueFormScreen` para el `Organizador`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Gate | Status | Verification Evidence |
|------------------|--------|-----------------------|
| **I. La Spec Manda (Spec-Driven Development)** | PASS | `spec.md` completado, clarificado (`/speckit-clarify` con 3 decisiones) y validado (`16/16` en `requirements.md`) incorporando `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | `SportsVenue` y `VenuePitch` exigen IDs inmutables, coordenadas válidas (`[-90, 90]`, `[-180, 180]`), al menos 1 cancha por sede y baja lógica (`active` / `maintenance`) que preserva la integridad histórica. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | Plan define pruebas unitarias y de widgets para dominio, repositorio local, controlador de sedes/permisos y vistas interactivas. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | PASS | `GeoCoordinate`, `SportsVenue`, `VenuePitch`, `LocationPermissionState` y los contratos `VenuesRepository` / `LocationPermissionRepository` viven en `lib/domain/` sin dependencias de UI ni paquetes externos. |
| **V. Segregación de Roles y Fidelidad a `DESIGN.md`** | PASS | Escritura restringida a `Organizador` (`RoleCapability.manageVenues` + `KickPulseRoleGuard`); lectura pública para los 5 roles; paleta *KickPulse Mobile* y `tabular-nums`. |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | Código técnico, clases, métodos y tests 100% en inglés; textos visibles, superficies, errores y banners de permisos 100% en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil (`MOBILE_GUIDELINES.md`)** | PASS | Solicitud de GPS *just-in-time*, alternativa completa ante rechazo/revocación, lectura offline `< 2s`, 5 estados de UI, conservación de borrador en segundo plano, confirmación al descartar y privacidad de ubicación (`FR-009`). |

## Project Structure

### Documentation (this feature)

```text
specs/003-venues-pitches-geolocation/
├── plan.md              # Este archivo (plan de implementación técnica)
├── research.md          # Decisiones técnicas: mapa offline-ready, permisos GPS y baja lógica (Fase 0)
├── data-model.md        # Entidades de dominio, coordenadas Haversine y máquina de estados (Fase 1)
├── quickstart.md        # Guía de ejecución y verificación (Fase 1)
├── contracts/
│   └── venues-geolocation-contract.md  # Contratos de vistas, lienzo de mapa, insignias y permisos (Fase 1)
└── tasks.md             # Lista de tareas ordenadas por dependencias (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                     # Catálogo en español ampliado con textos de Sedes, Canchas, Superficies y Permisos GPS
│   └── app_localizations*.dart                        # Clases regeneradas por flutter gen-l10n
├── domain/
│   ├── entities/
│   │   ├── geo_coordinate.dart                        # Value Object GeoCoordinate (validación [-90,90]/[-180,180] y distancia Haversine en km)
│   │   ├── location_permission_state.dart             # Enum LocationPermissionStatus y estado LocationPermissionState con redacción en toString()
│   │   ├── sports_venue.dart                          # Entidad SportsVenue (id, name, address, urbanReference, coordinate, pitches, status)
│   │   ├── venue_enums.dart                           # Enums PitchSurfaceType, PitchFormat y VenueOperationalStatus
│   │   ├── venue_pitch.dart                           # Entidad VenuePitch (id, name, surfaceType, format, capacity, hasLighting, status)
│   │   └── venues_catalog_state.dart                  # Estado inmutable VenuesCatalogState (5 estados UI, filtros, ubicación y borradores)
│   ├── failures/
│   │   └── app_failure.dart                           # Ampliado con InvalidVenueDataFailure y LocationPermissionFailure
│   └── repositories/
│       ├── location_permission_repository.dart        # Contrato de permisos de localización just-in-time y simulación en dev
│       └── venues_repository.dart                     # Contrato de persistencia, consulta offline, guardado y baja lógica de sedes
├── application/
│   ├── controllers/
│   │   └── venues_controller.dart                     # StateNotifier gestionando catálogo, filtros, cercanía, permisos GPS y borradores
│   ├── providers/
│   │   └── venues_providers.dart                      # Providers de Riverpod para VenuesRepository, LocationPermissionRepository y VenuesController
│   └── use_cases/
│       ├── manage_venues_use_case.dart                # Caso de uso de validación, creación, edición y baja lógica (exclusivo Organizador)
│       └── query_venues_geolocation_use_case.dart     # Caso de uso de filtrado, cálculo de distancia Haversine y ordenamiento por cercanía
├── infrastructure/
│   ├── location/
│   │   └── device_location_permission_repository.dart # Adaptador de permisos de ubicación con soporte resiliente y simulador en dev
│   └── venues/
│       └── local_venues_repository.dart               # Adaptador de VenuesRepository sobre LocalStorageRepository con 3 sedes semilla en dev
└── presentation/
    ├── navigation/
    │   └── app_router.dart                            # Ampliado con ruta /venues/form
    ├── shell/
    │   └── tabs/
    │       └── venues_tab_view.dart                   # Pestaña Sedes completa con mapa urbano, filtros, banner de permisos y listado
    └── venues/
        ├── venue_detail_sheet.dart                    # Hoja modal con detalle de sede, dirección, indicaciones y canchas internas
        ├── venue_form_screen.dart                     # Pantalla de creación/edición de sede y canchas (protegida por KickPulseRoleGuard)
        └── widgets/
            └── kick_pulse_urban_map_canvas.dart       # Lienzo interactivo KickPulse Urban Map (marcadores, toque de coordenadas y distancia)

test/
├── domain/
│   └── sports_venue_geolocation_test.dart             # Pruebas unitarias de GeoCoordinate (Haversine, límites), SportsVenue y VenuePitch
├── infrastructure/
│   └── local_venues_repository_test.dart              # Pruebas de persistencia aislada, 3 sedes semilla en dev y baja lógica
├── application/
│   └── venues_controller_test.dart                    # Pruebas de filtros, permisos just-in-time (concedido/denegado/revocado), RBAC y borradores
└── presentation/
    └── venues_geolocation_widget_test.dart            # Pruebas de widgets para VenuesTabView, KickPulseUrbanMapCanvas, VenueFormScreen y escala 130%
```

**Structure Decision**: Se mantiene la arquitectura limpia en 4 capas (`domain`, `application`, `infrastructure`, `presentation`) establecida en las **HU 1.1** y **HU 2.1**, ubicando las entidades geográficas y de sedes en `lib/domain/` sin ninguna dependencia de UI ni de plugins externos.

## Complexity Tracking

> **No hay violaciones a la Constitución.** Todas las puertas de verificación (`Constitution Check` pre-investigación y post-diseño) se cumplen al 100%.
