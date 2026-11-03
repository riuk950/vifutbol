# Quickstart & Validation Guide: HU 3.1 — Gestión de Sedes, Canchas Urbanas y Geolocalización Deportiva

**Feature**: `003-venues-pitches-geolocation`  
**Date**: 2026-11-03

---

## 1. Prerequisites

- Flutter SDK `>=3.11.0` y Dart `^3.12.0`
- Fundación **HU 1.1** y sistema de autenticación/RBAC **HU 2.1** activos en el repositorio

---

## 2. Generate Localization & Run Analysis

```bash
flutter gen-l10n
flutter analyze
dart format --output=none --set-exit-if-changed lib test
```

---

## 3. Run Automated Test Suite (Quality Gate)

```bash
# 1. Pruebas unitarias de dominio (GeoCoordinate, Haversine, SportsVenue, VenuePitch)
flutter test test/domain/sports_venue_geolocation_test.dart

# 2. Pruebas unitarias de infraestructura (persistencia aislada, 3 sedes semilla en dev, baja lógica)
flutter test test/infrastructure/local_venues_repository_test.dart

# 3. Pruebas unitarias de aplicación (VenuesController, permisos just-in-time, filtros, borradores)
flutter test test/application/venues_controller_test.dart

# 4. Pruebas de widgets (VenuesTabView, KickPulseUrbanMapCanvas, VenueFormScreen, RBAC, 130% text scale)
flutter test test/presentation/venues_geolocation_widget_test.dart

# 5. Suite completa del proyecto con cobertura
flutter test --coverage
```

---

## 4. End-to-End Verification Scenarios

1. **Catálogo Semilla y Consulta Geolocalizada (`US2` & `US3`)**:
   - Ejecutar `flutter run -t lib/env/main.dev.dart`.
   - Ingresar como `Aficionado` o cualquier rol y abrir la pestaña **Sedes**.
   - Verificar que se visualiza el lienzo interactivo *KickPulse Urban Map* y las `3` sedes urbanas semilla con sus canchas internas, tipos de superficie, aforo e iluminación.
   - Pulsar *"Mi ubicación / Cercanía"* y alternar el simulador `DEV` entre **Concedido**, **Denegado** y **Revocado** para comprobar que:
     - En **Concedido**, se muestra la distancia en `km` (`tabular-nums`) y se ordena por cercanía.
     - En **Denegado / Revocado**, el mapa permanece centrado en la sede/ciudad sin bloqueos, con dirección completa y aviso discreto en español.
2. **Creación, Edición y Baja Lógica por el Organizador (`US1`)**:
   - Desde la pestaña **Perfil**, cambiar el rol activo a **Organizador**.
   - Volver a **Sedes**, pulsar *"Nueva sede"*, ingresar nombre, dirección urbana, tocar un punto en el mapa (o escribir coordenadas), agregar una cancha interna y guardar.
   - Cambiar el estado de una sede o cancha a **En mantenimiento** y verificar su insignia de advertencia (`#F59E0B`).
   - Cambiar el rol activo a `Jugador` o `Aficionado` y comprobar que los botones de creación/edición quedan protegidos.
