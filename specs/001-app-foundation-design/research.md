# Phase 0 Research: HU 1.1 — Fundación de la Aplicación, Aislamiento de Entornos, Localización y Sistema de Diseño

**Feature**: `001-app-foundation-design`  
**Date**: 2026-11-03

---

## 1. Aislamiento de Entornos (`dev` y `prod`)

- **Decision**: Utilizar puntos de entrada dedicados (`lib/env/main.dev.dart` y `lib/env/main.prod.dart`, además de `lib/main.dart` apuntando por defecto a desarrollo para ejecución rápida en pruebas locales) que construyen una instancia inmutable de `EnvironmentConfig` y delegan en un `bootstrapApp(EnvironmentConfig)` compartido.
- **Rationale**: Cumple con los comandos definidos en `README.md` (`flutter run --flavor dev --target lib/env/main.dev.dart` y `flutter run --flavor prod --target lib/env/main.prod.dart`) y garantiza que las cajas de almacenamiento local (`Hive`) utilicen prefijos aislados (`vifutbol_dev_` vs `vifutbol_prod_`) y que las credenciales remotas nunca se mezclen.
- **Alternatives considered**:
  - *Variables `--dart-define` únicamente en un solo `main.dart`*: Rechazado porque `README.md` especifica explícitamente los targets `lib/env/main.dev.dart` y `lib/env/main.prod.dart`. Combinar entrypoints con `--dart-define` opcional para URLs/keys ofrece lo mejor de ambos enfoques.

---

## 2. Arquitectura por Capas y Gestión de Estado

- **Decision**: Estructurar el proyecto en cuatro capas desacopladas (`domain`, `application`, `infrastructure`, `presentation`) apoyadas por `flutter_riverpod` para inyección de dependencias y estado reactivo, y `fluro` para navegación declarativa.
- **Rationale**:
  - La capa `domain` contiene entidades inmutables (`EnvironmentConfig`, `ConnectivityStatus`, `AppSection`), fallos tipados (`AppFailure`) y contratos de repositorios sin depender de paquetes externos ni de `flutter/material.dart`.
  - La capa `application` contiene casos de uso y controladores de estado (`ConnectivityController`, `NavigationShellController`).
  - La capa `infrastructure` implementa los adaptadores concretos (monitoreo de conectividad, inicialización resiliente de almacenamiento local `Hive` con fallback en memoria si el disco falla).
  - La capa `presentation` contiene el tema *KickPulse Mobile* (`DESIGN.md`), la localización generada (`l10n`), los 5 contenedores de estado (`Carga`, `Contenido`, `Vacío`, `Error`, `Éxito`) y el `AppShellScreen`.
- **Alternatives considered**:
  - *Acoplar lógica directamente en `StatefulWidget`*: Rechazado por violar el Principio IV de la Constitución (Arquitectura Limpia y Separación de Responsabilidades) y dificultar pruebas unitarias aisladas.

---

## 3. Internacionalización (`l10n`) 100% en Español con Código en Inglés

- **Decision**: Configurar `flutter_localizations` e `intl` con generación automática (`generate: true` en `pubspec.yaml` y `l10n.yaml` en la raíz) usando `lib/l10n/app_es.arb` como plantilla principal y bloqueando `supportedLocales: [Locale('es')]`.
- **Rationale**: Cumple el Principio VI de la Constitución: todos los identificadores de código y llaves `.arb` se nombran en inglés (ej. `navMatchday`, `connectivityOfflineBanner`, `connectivityRestoredBanner`, `retryAction`), mientras que el 100% de los valores renderizados al usuario están en español.
- **Alternatives considered**:
  - *Constantes estáticas en un archivo `.dart` manual*: Rechazado porque `l10n` oficial con `.arb` provee validación en tiempo de compilación, soporte nativo de plurales/formatos de fecha y delegación estándar para widgets del sistema.

---

## 4. Sistema de Diseño *KickPulse Mobile* (`DESIGN.md`) y Números Tabulares

- **Decision**: Implementar un módulo de sistema de diseño en `lib/presentation/design_system/` con tokens exactos de `DESIGN.md`:
  - **Colores**: `canvasBackground (#080B11)`, `surfaceBase (#0E1422)`, `surfaceElevated (#161F33)`, `surfaceSubtle (#1D2840)`, `borderSubtle (#1F2C44)`, `borderStrong (#2D3F60)`, `accentPrimary (#22C55E)`, `accentLive (#EF4444)`, `accentWarning (#F59E0B)`, `accentElectric (#38BDF8)`, `textPrimary (#F8FAFC)`, `textSecondary (#94A3B8)`, `textTertiary (#64748B)`.
  - **Tipografía**: Escala completa (`displayLg`, `headlineLg`, `headlineMd`, `headlineSm`, `titleMd`, `bodyLg`, `bodyMd`, `bodySm`, `labelMd`, `labelSm`, `statMetric`) con `fontFeatures: [FontFeature.tabularFigures(), FontFeature.liningFigures()]`.
  - **Geometría y Áreas Táctiles**: Tarjetas con radio `16px`, chips `12px`, badges `9999px`, grilla `8pt` (`4px` micro-step) y restricción mínima de `44x44px` en todos los botones e íconos interactivos, además de bloqueo de doble pulsación (`AsyncActionGuard` / botón con estado `isBusy`).
- **Rationale**: Garantiza cumplimiento verificable de `SC-002` y `FR-003`/`FR-004`/`FR-005` en pruebas de widgets.
- **Alternatives considered**:
  - *Usar `ThemeData.dark()` por defecto con `ColorScheme.fromSeed`*: Rechazado porque altera los tonos exactos de superficie (`#080B11` y `#0E1422`) definidos en `DESIGN.md`.

---

## 5. Resiliencia Móvil: Banner Reactivo de Conectividad y Ciclo de Vida (`docs/MOBILE_GUIDELINES.md`)

- **Decision**:
  - **Orientación**: Fijar `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` durante el arranque antes de montar la interfaz (`FR-008`).
  - **Conectividad Reactiva**: Implementar un servicio/repositorio de conectividad que exponga tres estados de presentación en el banner superior (`Hidden` cuando está conectado de forma estable, `OfflinePersistent` cuando no hay red, y `RestoredTransient` en verde durante exactamente 3 segundos al pasar de `Offline` a `Online`).
  - **Conservación de Estado**: Usar `IndexedStack` (y soporte de restauración de índice/estado) en el `AppShellScreen` junto con un observador de ciclo de vida (`AppLifecycleListener`) para preservar la pestaña activa y el estado de las 4 vistas (*Jornada*, *Posiciones*, *Sedes*, *Perfil*) al pasar a segundo plano y regresar.
- **Rationale**: Satisface las tres decisiones confirmadas en `/speckit-clarify` y los criterios de `docs/MOBILE_GUIDELINES.md`.
- **Alternatives considered**:
  - *Recrear la vista de cada pestaña desde cero al cambiar de tab*: Rechazado porque pierde la posición de desplazamiento y el estado temporal de la pestaña activa.
