# Implementation Plan: Visualización de Plantilla Agrupada por Posición en el Panel Técnico (HU 20.2)

**Branch**: `045-coach-positional-roster` | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///Volumes/DATA/Development/FlutterProjects/vifutbol/specs/045-coach-positional-roster/spec.md)

**Input**: Feature specification from `/specs/045-coach-positional-roster/spec.md`

## Summary

Integrar en el Panel Técnico del entrenador (`CoachPanelContent`) una sección dedicada que visualiza la nómina del equipo activo agrupada estrictamente en las cuatro líneas tácticas estándar (`Porteros`, `Defensas`, `Mediocampistas`, `Delanteros`), reutilizando y reactivando el modelo determinista `TeamSquadRoster` y el provider `teamSquadRosterProvider(team.id)`. Cada bloque muestra un encabezado con el conteo dinámico de futbolistas, orden interno ascendente por número de dorsal (`shirtNumber`), tarjeta/fila por futbolista con dorsal destacado, nombre completo y badge de elegibilidad (`"Elegible"` / `"Inactivo / Sancionado"`), estado vacío sutil (`"Sin jugadores en esta posición"`) cuando una línea no tiene integrantes, y una alerta táctica preventiva cuando el equipo no cuente con al menos 1 portero.

## Technical Context

**Language/Version**: Dart 3.8+ / Flutter 3.x  
**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, Design System `KickPulse` (`KickPulseColors`, `KickPulseTypography`, `KickPulseRadiiSpacing`, `KickPulseCard`, `KickPulseBadge`)  
**Storage**: N/A (lectura reactiva en memoria desde `teamsControllerProvider` respaldado por Hive y Supabase DEV `vifutboldev`)  
**Testing**: `flutter_test` (unit tests de agrupación/ordenamiento en `TeamSquadRoster` + widget tests de `CoachPanelContent` y `CoachPositionalRosterSection`)  
**Target Platform**: iOS / Android (Mobile responsive desde 320px)  
**Project Type**: Mobile app (Flutter Clean Architecture)  
**Performance Goals**: Renderizado instantáneo O(N log N) sobre plantillas de hasta ~35 jugadores sin bloqueos de UI  
**Constraints**: Cero textos hardcodeados en UI (todo centralizado en `lib/l10n/app_es.arb`); cero desbordamiento en pantallas estrechas (320px-360px); cumplimiento estricto de `DESIGN.md` y accesibilidad (no depender solo del color)  
**Scale/Scope**: 1 componente visual nuevo (`CoachPositionalRosterSection`), actualización de `CoachPanelContent`, claves `l10n` en `app_es.arb` y pruebas unitarias + widget tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda**: Cumplido — `spec.md` aprobada sin `[NEEDS CLARIFICATION]`.
- **II. Integridad de Datos y Fuente de Verdad**: Cumplido — reutiliza `teamSquadRosterProvider(team.id)` conectado a `teamsControllerProvider`, evitando lógica duplicada o estados paralelos.
- **III. Pruebas Automatizadas como Puerta de Calidad**: Cumplido — incluye pruebas unitarias de agrupación/ordenamiento posicional y pruebas de widgets del panel técnico.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: Cumplido — modelo de presentación puro (`TeamSquadRoster`), provider reactivo en capa de aplicación (`teamSquadRosterProvider`), y widget desacoplado en presentación (`CoachPositionalRosterSection`).
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: Cumplido — exclusivo de `CoachPanelContent` (`UserRole.coach`) y adherido a tokens `KickPulse`.
- **VI. Convenciones de Idioma y Nomenclatura**: Cumplido — identificadores y pruebas en inglés; UI en español vía `AppLocalizations` (`app_es.arb`).
- **VII. Resiliencia y Experiencia Móvil**: Cumplido — soporta 0 jugadores, posiciones vacías, nombres extensos con elipsis, contraste y lectura offline-first.

## Project Structure

### Documentation (this feature)

```text
specs/045-coach-positional-roster/
├── spec.md                                     # Especificación funcional HU 20.2
├── plan.md                                     # Este plan técnico
├── research.md                                 # Hallazgos y decisiones técnicas
├── data-model.md                               # Modelo de agrupación posicional
├── quickstart.md                               # Guía de validación rápida
├── checklists/
│   └── requirements.md                         # Checklist de calidad
└── contracts/
    └── positional_roster_contract.md           # Contrato visual y de claves
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   └── app_es.arb                              # Nuevas claves para sección posicional y alertas
└── presentation/
    ├── panel/
    │   └── widgets/
    │       ├── coach_panel_content.dart        # Integración de CoachPositionalRosterSection
    │       └── coach_positional_roster_section.dart # Widget de plantilla agrupada por posición
    └── teams/
        └── models/
            └── team_squad_roster.dart          # Modelo existente reutilizado (ya ordena y agrupa)

test/
├── unit/
│   └── presentation/
│       └── team_squad_roster_test.dart         # Pruebas unitarias de agrupación y ordenamiento
└── presentation/
    └── panel/
        └── coach_positional_roster_test.dart   # Pruebas de widget para los 4 grupos, alerta y estado vacío
```

**Structure Decision**: Se mantiene la arquitectura existente de Flutter por capas (`domain` / `application` / `presentation`), reutilizando `TeamSquadRoster` y `teamSquadRosterProvider` para no duplicar lógica de agrupación ni ordenamiento.

## Complexity Tracking

No existen violaciones a la Constitución; no se requieren excepciones.
