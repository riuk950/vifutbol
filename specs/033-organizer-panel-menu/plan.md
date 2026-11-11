# Implementation Plan: Reorganización del Panel de Organización: Menú en AppBar y Depuración de Acciones Rápidas (HU 18.2)

**Branch**: `033-organizer-panel-menu` | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/033-organizer-panel-menu/spec.md`

---

## Summary

Esta funcionalidad reorganiza el Panel Administrativo del Organizador (`UserRole.organizer`) para maximizar la limpieza visual y eliminar redundancias operativas:
1. Retira definitivamente el bloque de tarjetas de "Acciones Rápidas" del cuerpo de `OrganizerPanelContent`.
2. Traslada las acciones administrativas globales indispensables a un menú contextual (`PopupMenuButton`) en el `AppBar` de `PanelScreen`, conservando únicamente "Publicar Noticia" y "Copia de Seguridad" (cada una con ícono alusivo y etiqueta de texto descriptivo conforme a la clarificación Q1).
3. Asegura que la acción de publicar noticias admita comunicados generales si no existen competiciones registradas (clarificación Q2).
4. Suprime definitivamente las acciones de "Generar Fixture" y "Programar Partido" de este menú general, dado que pertenecen al contexto específico de cada competición.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Flutter Material 3, Riverpod (`flutter_riverpod`), KickPulse Design System (`KickPulseColors`, `KickPulseRadiiSpacing`, `KickPulseTypography`)  
**Storage**: N/A (Consumo de repositorios y controladores existentes: `tournamentsControllerProvider`, `tournamentNewsControllerProvider`)  
**Testing**: Flutter Widget Tests (`flutter_test`), Mocktail  
**Target Platform**: Mobile (Android, iOS)  
**Project Type**: Mobile Application (Flutter)  
**Performance Goals**: Renderizado inmediato a 60 fps; apertura instantánea del menú contextual sin latencia perceptiva (< 16 ms)  
**Constraints**: Segregación estricta por rol (`UserRole.organizer`), diseño oscuro KickPulse Dark-first, cero cadenas de texto *hardcoded* (100% `l10n`)  
**Scale/Scope**: 2 archivos de presentación modificados (`panel_screen.dart`, `organizer_panel_content.dart`), 1 archivo de widget de menú nuevo o integrado, y actualización de suites de prueba de widgets  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Criterio Constitucional | Evaluación | Estado |
|---|---|---|---|
| **I. La Spec Manda** | Basado en `spec.md`, sin desviaciones de alcance y respetando `docs/MOBILE_GUIDELINES.md` | El plan cubre estrictamente lo estipulado en HU 18.2 sin agregar widgets ajenos. | ✓ PASS |
| **II. Integridad de Datos** | La fuente de verdad y entidades permanecen coherentes | No modifica el modelo relacional subyacente; reutiliza controladores existentes. | ✓ PASS |
| **III. Pruebas Automatizadas** | Toda UI y flujo debe contar con tests automatizados | Se actualiza `organizer_panel_widget_test.dart` y se agregan pruebas del menú contextual. | ✓ PASS |
| **IV. Arquitectura Limpia** | Separación por capas; la presentación solo invoca controladores y casos de uso | El menú contextual se implementa en la capa de presentación consumiendo Riverpod. | ✓ PASS |
| **V. Segregación de Roles & Diseño** | Acceso exclusivo para `UserRole.organizer` y adhesión a tokens `DESIGN.md` | El menú contextual solo se renderiza si `activeRole == UserRole.organizer`; usa tokens KickPulse. | ✓ PASS |
| **VI. Convenciones de Idioma** | Código técnico en inglés; UI localizada en español (`l10n`) | Clases, métodos y tests en inglés; etiquetas en español reutilizando `app_es.arb`. | ✓ PASS |
| **VII. Resiliencia Móvil** | Área táctil $\ge 44$ pt, accesibilidad, manejo de estados vacíos | Tooltip accesible, área mínima de tap respetada, fallback para noticias sin torneos. | ✓ PASS |

---

## Project Structure

### Documentation (this feature)

```text
specs/033-organizer-panel-menu/
├── spec.md              # Especificación funcional con clarificaciones Q1 y Q2
├── plan.md              # Este plan de implementación
├── research.md          # Decisiones técnicas y justificaciones arquitectónicas
├── data-model.md        # Arquitectura de presentación y jerarquía de componentes
├── quickstart.md        # Guía de verificación manual y automatizada
├── contracts/
│   └── panel-menu-contracts.md # Contratos de widgets, claves e integración
└── checklists/
    └── requirements.md  # Checklist de calidad de la especificación
```

### Source Code Impacted

```text
lib/
└── presentation/
    └── panel/
        ├── panel_screen.dart                     # Añade actions en AppBar para UserRole.organizer
        └── widgets/
            ├── organizer_panel_appbar_menu.dart  # Menú contextual PopupMenuButton (o integrado en panel)
            └── organizer_panel_content.dart      # Retiro de sección y tarjetas de "Acciones Rápidas"

test/
└── presentation/
    └── panel/
        ├── organizer_panel_widget_test.dart      # Actualización de tests de widgets del panel
        └── organizer_panel_menu_test.dart        # Tests específicos del menú contextual y acciones
```

---

## Design Artifacts Summary

1. **[research.md](./research.md)**: Justificación del uso de `PopupMenuButton` en `PanelScreen.appBar.actions`, retiro de métodos obsoletos de `OrganizerPanelContent` y estrategia de fallback para noticias generales.
2. **[data-model.md](./data-model.md)**: Enumeración `OrganizerMenuAction`, diagrama de flujo de acciones y matriz comparativa del layout antes vs. después.
3. **[contracts/panel-menu-contracts.md](./contracts/panel-menu-contracts.md)**: Contratos detallados de `OrganizerPanelAppBarMenu`, limpieza de `OrganizerPanelContent` y mapeo de claves `l10n`.
4. **[quickstart.md](./quickstart.md)**: Guía de comandos de prueba (`flutter test`, `flutter analyze`) y escenarios de prueba manual de verificación de limpieza y navegación.
