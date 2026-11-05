# Implementation Plan: Navigation Drawer y Páginas de Directorio con Buscador

**Branch**: `014-navigation-drawer-directories` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/014-navigation-drawer-directories/spec.md`

## Summary

Implementar un menú lateral universal (`NavigationDrawer`) en `AppShellScreen` accesible para todos los roles (`Organizador`, `Árbitro`, `Entrenador / Capitán`, `Jugador`, `Aficionado`), que ofrece navegación directa hacia cuatro destinos: **Competiciones**, **Equipos**, **Jugadores** y **Sedes**. Las tres nuevas pantallas de directorio (`CompetitionsDirectoryScreen`, `TeamsDirectoryScreen`, `PlayersDirectoryScreen`) cuentan con un buscador superior en tiempo real insensible a mayúsculas y acentos (`KickPulseSearchBar`), selectores horizontales de torneos para acotar el catálogo, estado vacío informativo (`KickPulseStateView`) y acciones de creación contextuales según las capacidades del rol activo.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `fluro`, `flutter_localizations`
**Storage**: `LocalStorageRepository` (persistencia local offline de torneos, equipos y jugadores en memoria y disco)
**Testing**: `flutter_test` (pruebas unitarias de controladores y utilidades de normalización, pruebas de widgets de drawer y pantallas de directorio con viewport `320x640` y escala de texto `1.3`)
**Target Platform**: Mobile (Android / iOS)
**Project Type**: Mobile Application
**Performance Goals**: Búsqueda y filtrado en tiempo real en menos de 100 ms sin bloqueo de UI; transición fluida del Drawer a 60 fps
**Constraints**: Diseño KickPulse con tema `Obsidian Pitch`, 100% de textos en español mediante `l10n`, cero desbordamientos `RenderFlex` a 320x640 @ 130% texto
**Scale/Scope**: 4 destinos de navegación en el Drawer, 3 nuevas pantallas de directorio (`CompetitionsDirectoryScreen`, `TeamsDirectoryScreen`, `PlayersDirectoryScreen`), 1 componente de búsqueda reutilizable (`KickPulseSearchBar`), 3 controladores Riverpod

## Constitution Check

*GATE: Evaluado antes y después del diseño.*

| Principio Constitucional | Estado | Justificación y Validación |
|--------------------------|--------|----------------------------|
| **I. La Spec Manda (Spec-Driven Development)** | **PASS** | Todo el diseño se deriva estrictamente de `spec.md`, `research.md`, `data-model.md` y `contracts/ui-navigation-contracts.md`. No se añade lógica fuera de alcance. |
| **II. Integridad de Datos y Fuente de Verdad** | **PASS** | Los directorios consumen las fuentes de verdad existentes de torneos, equipos y jugadores sin duplicar entidades ni corromper estados de persistencia. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | **PASS** | Cobertura planificada para utilidades de búsqueda, controladores de directorio y pruebas de widgets para los 5 roles y pantallas compactas. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | **PASS** | Controladores en `application/`, componentes visuales y pantallas en `presentation/`, entidades sin dependencias externas en `domain/`. |
| **V. Segregación de Roles y Fidelidad al Sistema de Diseño** | **PASS** | Menú accesible para todos los roles; acciones de creación condicionadas por `RoleCapability` (`manageTournaments`, `registerTeams`, `manageRoster`). Tokens KickPulse respetados. |
| **VI. Convenciones de Idioma y Nomenclatura** | **PASS** | Código, identificadores, archivos y tests en **inglés**; interfaz de usuario 100% en **español** a través de `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil (`MOBILE_GUIDELINES.md`)** | **PASS** | Cierre automático del drawer antes de navegar, teclado ocultado al desplazar (`onDrag`), botón de limpieza rápida (`X`), estado vacío y soporte para `320x640` @ 130% texto. |

## Project Structure

### Documentation (this feature)

```text
specs/014-navigation-drawer-directories/
├── plan.md              # Este archivo (plan de implementación)
├── research.md          # Decisiones arquitectónicas y de búsqueda
├── data-model.md        # Modelos de estado de los directorios
├── quickstart.md        # Guía ejecutable de validación de pruebas
├── contracts/           # Contratos de UI y navegación
│   └── ui-navigation-contracts.md
├── checklists/
│   └── requirements.md  # Checklist de calidad validado
└── tasks.md             # Tareas de implementación (generadas por /speckit-tasks)
```

### Source Code (repository layout)

```text
lib/
├── application/
│   ├── controllers/
│   │   ├── competitions_directory_controller.dart
│   │   ├── teams_directory_controller.dart
│   │   └── players_directory_controller.dart
│   ├── providers/
│   │   └── directory_providers.dart
│   └── utils/
│       └── search_utils.dart
├── l10n/
│   ├── app_es.arb
│   ├── app_localizations.dart
│   └── app_localizations_es.dart
├── presentation/
│   ├── design_system/
│   │   └── widgets/
│   │       └── kick_pulse_search_bar.dart
│   ├── directories/
│   │   ├── competitions_directory_screen.dart
│   │   ├── teams_directory_screen.dart
│   │   └── players_directory_screen.dart
│   ├── navigation/
│   │   └── app_router.dart
│   └── shell/
│       ├── app_shell_screen.dart
│       └── widgets/
│           └── app_navigation_drawer.dart

test/
├── unit/
│   └── application/
│       ├── search_utils_test.dart
│       └── directories_controllers_test.dart
└── presentation/
    ├── app_drawer_widget_test.dart
    └── directories_screens_widget_test.dart
```

**Structure Decision**: Se mantiene la arquitectura por capas limpia del proyecto. Las pantallas de directorio se ubican en `lib/presentation/directories/`, el drawer en `lib/presentation/shell/widgets/`, el buscador reutilizable en `lib/presentation/design_system/widgets/`, y la lógica de filtrado y estado en `lib/application/`.

## Complexity Tracking

> **Sin violaciones a la Constitución.**

| Elemento | Justificación de Necesidad | Alternativa más Simple Descartada |
|----------|----------------------------|-----------------------------------|
| `KickPulseSearchBar` reutilizable | Centraliza el comportamiento de búsqueda, foco, limpieza y debounce en las 3 pantallas de directorio. | Duplicar el `TextField` y la lógica de limpieza en cada pantalla de directorio generaría redundancia y riesgo de inconsistencias de UX. |
| `search_utils.dart` | Normalización de acentos pura y testeable aisladamente. | Realizar `.toLowerCase()` básico sin remoción de tildes generaría falsos negativos en búsquedas con nombres hispanos. |
