# Implementation Plan: HU 1.1 — Fundación de la Aplicación, Aislamiento de Entornos, Localización y Sistema de Diseño

**Branch**: `001-app-foundation-design` | **Date**: 2026-11-03 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/001-app-foundation-design/spec.md)

**Input**: Feature specification from `/specs/001-app-foundation-design/spec.md`

## Summary

Establecer la fundación arquitectónica y visual de **vifutbol** cumpliendo la Constitución v2.0.0:
1. Aislamiento operativo entre entornos de Desarrollo (`lib/env/main.dev.dart`) y Producción (`lib/env/main.prod.dart`) con espacios de almacenamiento local independientes y protección de credenciales en logs.
2. Estructura en capas desacopladas (`domain`, `application`, `infrastructure`, `presentation`) con código 100% en inglés e interfaz de usuario 100% en español mediante localización centralizada (`l10n`).
3. Implementación íntegra del sistema de diseño *KickPulse Mobile* (`DESIGN.md`), incluyendo paleta oscura deportiva (`#080B11` / `#0E1422` / `#22C55E`), números tabulares (`tabular-nums`), radios de componentes y objetivos táctiles mínimos de `44x44px` con protección contra doble pulsación.
4. Contenedor raíz (*App Shell*) bloqueado en orientación vertical (*Portrait*) con barra de navegación inferior de 4 secciones (*Jornada*, *Posiciones*, *Sedes*, *Perfil*), banner superior reactivo de conectividad (oculto en línea, persistente sin conexión, y verde durante 3s al restaurar red), preservación de estado en el ciclo de vida móvil y componentes reutilizables para los 5 estados de interfaz (`Carga`, `Contenido`, `Vacío`, `Error`, `Éxito`).

## Technical Context

**Language/Version**: Dart `^3.12.0` / Flutter `>=3.11.0`

**Primary Dependencies**: `flutter_localizations` (SDK), `intl`, `flutter_riverpod`, `fluro`, `hive` + `hive_flutter`, `uuid`

**Storage**: Almacenamiento local offline con `Hive` aislado por prefijo de entorno (`vifutbol_dev` / `vifutbol_prod`) y fallback resiliente en memoria si el sistema de archivos falla.

**Testing**: `flutter_test` (SDK) y `mocktail` para pruebas unitarias de dominio, casos de uso, controladores de estado, adaptadores de infraestructura y pruebas de widgets.

**Target Platform**: iOS y Android (Smartphones en orientación vertical *Portrait*).

**Project Type**: `mobile-app` (Aplicación móvil deportiva *Offline-First*).

**Performance Goals**: Arranque inicial hasta interfaz interactiva `< 2s` (online y offline); reacción visual del banner de conectividad `< 2s`; renderizado a `60 fps`.

**Constraints**: Capacidad *Offline-First*, bloqueo de orientación vertical (*Portrait*), objetivos táctiles mínimos de `44x44px`, 0 textos *hardcoded* fuera de `l10n`, 0 exposición de credenciales en logs.

**Scale/Scope**: Fundación transversal para las 9 Épicas del proyecto; incluye el *App Shell* de 4 secciones y el sistema de diseño completo *KickPulse Mobile*.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Gate | Status | Verification Evidence |
|------------------|--------|-----------------------|
| **I. La Spec Manda (Spec-Driven Development)** | PASS | `spec.md` completado, clarificado (`/speckit-clarify`) y validado (`16/16` en `requirements.md`) incorporando `docs/MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos y Fuente de Verdad** | PASS | `EnvironmentConfig` y `LocalStorageService` aíslan estrictamente los datos de `dev` y `prod` con fallback seguro en memoria. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | PASS | El plan incluye pruebas unitarias y de widgets para entidades de dominio, controladores, adaptadores, tokens de diseño y estados del *App Shell*. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | PASS | Separación estricta en `domain/`, `application/`, `infrastructure/` y `presentation/`. `domain/` no depende de Flutter ni de paquetes de infraestructura. |
| **V. Segregación de Roles y Fidelidad a `DESIGN.md`** | PASS | Todos los tokens de color, tipografía `Inter` (`tabular-nums`), radios (`16px`, `12px`, `9999px`) y áreas táctiles (`44x44px`) de `DESIGN.md` están formalizados en `contracts/ui-foundation-contract.md`. |
| **VI. Convenciones de Idioma y Nomenclatura** | PASS | Todos los archivos, clases, métodos y tests están en inglés; toda cadena de UI proviene de `lib/l10n/app_es.arb` en español. |
| **VII. Resiliencia y Experiencia Móvil (`MOBILE_GUIDELINES.md`)** | PASS | Cubre bloqueo vertical (*Portrait*), conservación de estado en segundo plano, banner reactivo de conectividad, prevención de doble tap y los 5 estados de UI. |

## Project Structure

### Documentation (this feature)

```text
specs/001-app-foundation-design/
├── plan.md              # Este archivo (plan de implementación técnica)
├── research.md          # Decisiones de arquitectura y tecnología (Fase 0)
├── data-model.md        # Entidades de dominio y máquina de estados (Fase 1)
├── quickstart.md        # Guía de ejecución por flavors y validación (Fase 1)
├── contracts/
│   └── ui-foundation-contract.md  # Contrato de tokens, entrypoints y App Shell (Fase 1)
└── tasks.md             # Lista de tareas ordenadas por dependencias (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── main.dart                                      # Punto de entrada por defecto (delega a dev)
├── app_bootstrap.dart                             # Inicialización resiliente (orientación, almacenamiento, App)
├── env/
│   ├── main.dev.dart                              # Entrypoint para flavor dev
│   └── main.prod.dart                             # Entrypoint para flavor prod
├── l10n/
│   ├── app_es.arb                                 # Catálogo oficial de textos en español
│   └── app_localizations*.dart                    # Clases generadas por flutter gen-l10n
├── domain/
│   ├── entities/
│   │   ├── app_environment.dart                   # Enum AppEnvironment y entidad EnvironmentConfig
│   │   ├── app_shell_section.dart                 # Enum de las 4 secciones del App Shell
│   │   ├── connectivity_status.dart               # Estados de conectividad y visibilidad del banner
│   │   ├── local_storage_status.dart              # Estado de salud del almacenamiento local
│   │   └── ui_view_state.dart                     # Contrato sellado para Carga, Contenido, Vacío, Error, Éxito
│   ├── failures/
│   │   └── app_failure.dart                       # Fallos de dominio seguros sin exposición de datos sensibles
│   └── repositories/
│       ├── connectivity_repository.dart           # Contrato de monitoreo de red
│       └── local_storage_repository.dart          # Contrato de almacenamiento local aislado por entorno
├── application/
│   ├── controllers/
│   │   ├── app_shell_controller.dart              # Gestión de pestaña activa, ciclo de vida y estados demostrativos
│   │   └── connectivity_banner_controller.dart    # Máquina de estados del banner reactivo con temporizador de 3s
│   ├── providers/
│   │   └── foundation_providers.dart              # Providers de Riverpod para configuración, red y navegación
│   └── use_cases/
│       ├── initialize_app_foundation_use_case.dart# Caso de uso de arranque resiliente
│       └── watch_connectivity_use_case.dart       # Caso de uso de observación de conectividad
├── infrastructure/
│   ├── connectivity/
│   │   └── platform_connectivity_repository.dart  # Adaptador de conectividad con soporte de simulación/streams
│   └── storage/
│       └── hive_local_storage_repository.dart     # Adaptador Hive con prefijo por entorno y fallback en memoria
└── presentation/
    ├── app.dart                                   # MaterialApp configurado con l10n, Fluro y KickPulseTheme
    ├── design_system/
    │   ├── kick_pulse_colors.dart                 # Paleta exacta de DESIGN.md
    │   ├── kick_pulse_radii_spacing.dart          # Radios (16, 12, 9999) y grilla de 8pt
    │   ├── kick_pulse_theme.dart                  # ThemeData oscuro KickPulse Mobile
    │   ├── kick_pulse_typography.dart             # Escala tipográfica con tabular-nums
    │   └── widgets/
    │       ├── kick_pulse_badge.dart              # Insignias semánticas (Live, Warning, Dev)
    │       ├── kick_pulse_button.dart             # Botón >= 44x44px con protección anti-doble tap
    │       ├── kick_pulse_card.dart               # Tarjeta base de 16px con borde #1F2C44
    │       └── kick_pulse_state_view.dart         # Renderizador de los 5 estados (Carga, Contenido, Vacío, Error, Éxito)
    ├── navigation/
    │   └── app_router.dart                        # Configuración de rutas con Fluro
    └── shell/
        ├── app_shell_screen.dart                  # Contenedor raíz con BottomNavigationBar y conservación de estado
        └── widgets/
            └── connectivity_banner.dart           # Banner superior reactivo (Offline / Conexión restaurada 3s)

test/
├── domain/
│   └── environment_config_test.dart               # Pruebas de aislamiento de entornos y sanitización de credenciales
├── application/
│   ├── app_shell_controller_test.dart             # Pruebas de navegación, ciclo de vida y cambio de estados UI
│   └── connectivity_banner_controller_test.dart   # Pruebas del temporizador de 3s y transiciones Online/Offline
├── infrastructure/
│   └── hive_local_storage_repository_test.dart    # Pruebas de prefijos por entorno y fallback en memoria
└── presentation/
    ├── design_system_tokens_test.dart             # Verificación de colores, tabular-nums y áreas táctiles >= 44x44px
    └── app_shell_widget_test.dart                 # Pruebas de widgets para l10n en español, 4 tabs, 5 estados y banner
```

**Structure Decision**: Se selecciona una arquitectura limpia de proyecto móvil único (`lib/` y `test/`) dividida en cuatro capas explícitas (`domain`, `application`, `infrastructure`, `presentation`) más el módulo de puntos de entrada por entorno (`lib/env/`) y localización (`lib/l10n/`).

## Complexity Tracking

> **No hay violaciones a la Constitución.** Todas las puertas de verificación (`Constitution Check` pre-investigación y post-diseño) se cumplen al 100%.
