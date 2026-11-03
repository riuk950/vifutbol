# Quickstart & Validation Guide: HU 2.1 — Autenticación, Onboarding y Control de Acceso Basado en Roles (RBAC)

**Feature**: `002-auth-onboarding-rbac`  
**Date**: 2026-11-03

---

## 1. Prerequisites

- Fundación de la **HU 1.1** instalada y operativa (`flutter pub get` y `flutter gen-l10n`).
- Dispositivo físico, emulador Android o simulador iOS en orientación vertical (*Portrait*).

---

## 2. Setup & Code Generation

Actualizar el catálogo de localización (`lib/l10n/app_es.arb`) y regenerar las clases de traducción:

```bash
flutter gen-l10n
```

---

## 3. Running & Validating User Flows

### 3.1 Entorno de Desarrollo (`dev` — 5 roles habilitados)
```bash
flutter run -t lib/env/main.dev.dart
```
**Escenarios verificables**:
1. **Puerta de Bienvenida**: Al abrir sin sesión activa, muestra `WelcomeAuthScreen` con pestañas *Iniciar sesión* / *Crear cuenta* y el botón rápido *"Continuar como Aficionado"*.
2. **Registro y Onboarding de Rol**: Crear una cuenta nueva redirige a `RoleOnboardingScreen` para elegir cualquiera de los 5 roles deportivos y acceder al *App Shell*.
3. **Cambio de Rol y RBAC en Perfil**: En la pestaña *Perfil*, cambiar entre `Organizador`, `Entrenador`, `Árbitro`, `Jugador` y `Aficionado` actualiza inmediatamente las capacidades habilitadas/denegadas según [data-model.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/002-auth-onboarding-rbac/data-model.md).
4. **Rehidratación Offline y Cierre de Sesión**: Cerrar y reabrir la aplicación sin red conserva la sesión activa; presionar *"Cerrar sesión"* limpia las credenciales y regresa a `WelcomeAuthScreen`.

### 3.2 Entorno de Producción (`prod` — código de autorización para roles oficiales)
```bash
flutter run -t lib/env/main.prod.dart
```
**Escenarios verificables**:
- Durante el *Onboarding*, los roles `Aficionado`, `Jugador` y `Entrenador` son de selección directa, mientras que `Organizador` y `Árbitro` solicitan código de autorización del torneo.

---

## 4. Verification of Quality Gates (`Constitution Check`)

### 4.1 Análisis Estático (0 errores, 0 advertencias)
```bash
flutter analyze
```

### 4.2 Suite de Pruebas Automatizadas y Cobertura
```bash
flutter test --coverage
```

**Escenarios validados por las pruebas automatizadas**:
1. **Matriz RBAC (`role_permission_matrix_test.dart`)**: Verifica las permisos exactos de los 5 roles (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`, `Aficionado`) y la restricción de códigos en `prod` vs `dev`.
2. **Repositorio y Rehidratación Offline (`local_auth_repository_test.dart`)**: Verifica persistencia de sesión aislada por entorno, sanitización de tokens/contraseñas en `toString()`, limpieza al cerrar sesión y funcionamiento offline para sesiones activas.
3. **Controlador de Autenticación y Bloqueo por Fuerza Bruta (`auth_controller_test.dart`)**: Verifica login, registro, modo `Aficionado`, exigencia de red para nuevo login/registro, bloqueo de `60s` tras `5` intentos fallidos consecutivos y cambio de rol activo.
4. **Widgets de Autenticación, Onboarding y Perfil (`auth_flow_widget_test.dart`)**: Verifica localización 100% en español, áreas táctiles `>= 44x44px`, bloqueo *single-flight*, resiliencia a `130%` de escala de texto y visualización de permisos por rol en *Perfil*.
