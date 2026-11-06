# Implementation Plan: Acceso a "Panel" en Navigation Drawer y Ocultación Temporal de "Explorar"

**Branch**: `016-drawer-panel-access` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/016-drawer-panel-access/spec.md`

---

## Summary

Implementar la historia de usuario **HU 12.1** para reorganizar la navegación principal de ViFutbol mediante:
1. La ocultación temporal de la pestaña "Explorar" del `NavigationBar` inferior en `AppShellScreen`, reduciendo la barra a 3 pestañas ("Partidos", "Noticias", "Perfil") mediante un mapeo de índices en la capa de presentación que preserva intacto el modelo de dominio `AppShellSection`, junto con la redirección segura de la ruta `/explore` a `/matches`.
2. La incorporación del destino de navegación "Panel" en la primera posición de `AppNavigationDrawer`, condicionado a roles con responsabilidades de gestión o participación (`Organizador`, `Entrenador`, `Árbitro`, `Jugador`) y oculto para `Aficionado`, navegando hacia `/panel` tras cerrar fluidamente el Drawer.
3. La creación de la pantalla contenedora `PanelScreen` (`/panel`) con `AppBar`, botón de retroceso y estado informativo del rol activo, sirviendo de base para la HU 12.2.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (Clean Architecture + Riverpod)

**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, `intl`

**Storage**: Local storage existente (`LocalStorageRepository`) sin migraciones de esquema

**Testing**: `flutter_test` (pruebas de widgets aisladas con `ProviderScope`, fakes de repositorio y soporte de accesibilidad/responsividad)

**Target Platform**: Android & iOS (Mobile-first, responsive down to 320x640 logical pixels)

**Project Type**: Mobile Application (Sports tournament organizer & fan experience)

**Performance Goals**: Navegación fluida a 60 fps, tiempo de respuesta al cambio de pestaña < 100 ms, cierre y transición del Drawer < 150 ms

**Constraints**:
- Segregación estricta de permisos por rol (Principio V de la Constitución)
- Cero desbordamientos de renderizado (`RenderFlex overflow`) en 320x640 px con texto al 130%
- Textos 100% en español vía `l10n` y código técnico en inglés (Principio VI)
- Preservar compatibilidad total con la suite de 334 pruebas automatizadas existentes

**Scale/Scope**: 5 roles de usuario, 3 pestañas principales de barra inferior, 1 ítem nuevo de drawer, 1 nueva pantalla de panel

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio de la Constitución | Estado | Justificación / Mecanismo de Cumplimiento |
| :--- | :---: | :--- |
| **I. La Spec Manda** | **PASS** | Plan derivado estrictamente de `spec.md` y HU 12.1 de Notion, incorporando pautas de `MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos** | **PASS** | No se altera la persistencia de torneos ni partidos; `AppShellSection` permanece intacto. |
| **III. Pruebas Automatizadas** | **PASS** | Se diseñan pruebas de widget para visibilidad por rol en Drawer, estructura de 3 tabs y redirección de `/explore`. |
| **IV. Arquitectura Limpia** | **PASS** | El mapeo de 3 tabs se aísla en la capa de presentación; el dominio no depende de detalles visuales. |
| **V. Segregación de Roles** | **PASS** | El ítem "Panel" solo se renderiza para roles autorizados; el rol `Aficionado` no visualiza el acceso. |
| **VI. Convenciones de Idioma** | **PASS** | Código, identificadores y pruebas en inglés; textos visibles en español centralizados en `app_es.arb`. |
| **VII. Resiliencia Móvil** | **PASS** | Cierre de drawer previo a la navegación, redirección segura de rutas no activas, soporte para 320x640 px con texto al 130%. |

---

## Project Structure

### Documentation (this feature)

```text
specs/016-drawer-panel-access/
├── plan.md              # Este archivo (plan de implementación)
├── research.md          # Investigación técnica y decisiones arquitectónicas
├── data-model.md        # Modelos de presentación y matrices de visibilidad
├── contracts/
│   └── ui-navigation-contracts.md # Contratos de interfaz, rutas y keys de test
├── quickstart.md        # Guía de verificación rápida y comandos
└── checklists/
    └── requirements.md  # Checklist de calidad de requisitos
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                           # Nuevas claves de localización (drawerPanel, panelPlaceholder*)
│   ├── app_localizations.dart               # Generado automáticamente
│   └── app_localizations_es.dart            # Generado automáticamente
├── presentation/
│   ├── navigation/
│   │   └── app_router.dart                  # Ruta /panel y redirección segura de /explore
│   ├── panel/
│   │   └── panel_screen.dart                # Nueva pantalla base para /panel (HU 12.1)
│   └── shell/
│       ├── app_shell_screen.dart            # NavigationBar con 3 pestañas y mapeo a AppShellSection
│       └── widgets/
│           └── app_navigation_drawer.dart   # Ítem "Panel" en posición 0 con control por rol
test/
└── presentation/
    ├── app_drawer_widget_test.dart          # Pruebas de visibilidad de "Panel" para los 5 roles
    ├── app_shell_widget_test.dart           # Pruebas de las 3 pestañas en NavigationBar
    └── panel_screen_test.dart               # Pruebas de la nueva pantalla PanelScreen y navegación
```

**Structure Decision**: Se mantiene la arquitectura por capas existente en `lib/presentation`, ubicando la nueva pantalla en `lib/presentation/panel/panel_screen.dart` y adaptando `app_shell_screen.dart`, `app_navigation_drawer.dart` y `app_router.dart`.

---

## Complexity Tracking

> *No se registran violaciones a los principios de la Constitución.*
