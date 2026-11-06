# Implementation Plan: Pantalla de Panel Administrativo Dinámico por Rol (HU 12.2)

**Branch**: `017-role-dynamic-panel` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-role-dynamic-panel/spec.md`

---

## Summary

Implementar la pantalla centralizada y adaptativa de `/panel` (`PanelScreen`), renderizando dinámicamente títulos de `AppBar` y subwidgets desacoplados según el rol activo (`OrganizerPanelContent`, `CoachPanelContent`, `RefereePanelContent`, `PlayerPanelContent`), además de una vista restrictiva amigable (`FanPanelRestrictedContent`) para aficionados con botón de retorno a `/matches`. Se reutilizan los repositorios y controladores preexistentes (`tournamentsControllerProvider`, `matchesCatalogControllerProvider`, `teamsControllerProvider`, `authControllerProvider`), garantizando un diseño 100% en español (`l10n`), área táctil mínima de $48 \times 48\text{ dp}$ y cero desbordamientos en viewports de $320 \times 640\text{ px}$ con texto al $130\%$.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `flutter_riverpod`, `fluro`, `flutter_localizations`

**Storage**: Local storage (`LocalStorageRepository` offline-first) persistiendo torneos, equipos, jugadores y partidos.

**Testing**: `flutter_test` (pruebas de widgets por rol, tests de navegación, responsividad a $320 \times 640\text{ px}$ con escalado de texto al $130\%$).

**Target Platform**: Android & iOS (mobile-first, responsive portrait layout).

**Project Type**: Mobile application (Flutter client).

**Performance Goals**: Renderizado reactivo en $<200\text{ ms}$ al ingresar a `/panel`, 60 fps en transiciones y desplazamiento de listas.

**Constraints**: $100\%$ textos en español vía `app_es.arb` (`l10n`), área táctil mínima de $48 \times 48\text{ dp}$, compatibilidad con tokens de `DESIGN.md`.

**Scale/Scope**: 5 roles de usuario (`organizer`, `coach`, `referee`, `player`, `fan`), 5 subpaneles modulares, 1 pantalla anfitriona `/panel`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio de la Constitución | Estado | Justificación / Mecanismo de Cumplimiento |
| :--- | :---: | :--- |
| **I. La Spec Manda** | **PASS** | Plan derivado estrictamente de `spec.md`, HU 12.2 de Notion y directrices de `MOBILE_GUIDELINES.md`. |
| **II. Integridad de Datos** | **PASS** | Se consumen métricas y estados directamente de la fuente de verdad determinista sin alterar entidades de dominio. |
| **III. Pruebas Automatizadas** | **PASS** | Se diseñan pruebas de widget exhaustivas para cada rol, verificando títulos, métricas, acciones y estados vacíos. |
| **IV. Arquitectura Limpia** | **PASS** | Subpaneles modulares (`OrganizerPanelContent`, `CoachPanelContent`, etc.) desacoplados del scaffold anfitrión. |
| **V. Segregación de Roles** | **PASS** | Cada perfil visualiza exclusivamente sus métricas y herramientas operativas; `Aficionado` es restringido con mensaje explicativo. |
| **VI. Convenciones de Idioma** | **PASS** | Código y pruebas en inglés; 100% de títulos, etiquetas de métricas y mensajes en español centralizados en `app_es.arb`. |
| **VII. Resiliencia Móvil** | **PASS** | Soportado en viewports de $320 \times 640\text{ px}$ al $130\%$ de texto, bloqueo de toques duplicados y navegación segura de retorno. |

---

## Project Structure

### Documentation (this feature)

```text
specs/017-role-dynamic-panel/
├── plan.md              # Este archivo (plan de implementación)
├── research.md          # Investigación técnica y decisiones arquitectónicas
├── data-model.md        # Modelos de datos de presentación y matriz por rol
├── contracts/
│   └── ui-panel-contracts.md # Contratos de widgets, keys y títulos dinámicos
├── quickstart.md        # Guía de verificación rápida y comandos
└── checklists/
    └── requirements.md  # Checklist de calidad de requisitos
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                                 # Nuevas claves de localización (panelTitle*, metrics, actions)
│   ├── app_localizations.dart                     # Generado automáticamente
│   └── app_localizations_es.dart                  # Generado automáticamente
└── presentation/
    └── panel/
        ├── panel_screen.dart                      # Scaffold anfitrión con AppBar dinámico y enrutador por rol
        └── widgets/
            ├── organizer_panel_content.dart       # Subpanel del Organizador
            ├── coach_panel_content.dart           # Subpanel del Entrenador
            ├── referee_panel_content.dart         # Subpanel del Árbitro
            ├── player_panel_content.dart          # Subpanel del Jugador
            └── fan_panel_restricted_content.dart  # Vista restrictiva para Aficionados
test/
└── presentation/
    └── panel/
        └── panel_screen_test.dart                 # Pruebas de widgets para los 5 roles y navegación
```

**Structure Decision**: Se mantiene la arquitectura por capas existente en `lib/presentation/panel/`, modularizando los subwidgets dentro de `lib/presentation/panel/widgets/` y agrupando sus pruebas en `test/presentation/panel/`.

---

## Complexity Tracking

*No violaciones a la Constitución detectadas.*
