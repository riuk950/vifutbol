# Implementation Plan: Rediseño de Vista Partidos (Match Center Stitch, Selector de Fecha por Calendario y Pestañas Ayer/Hoy/Mañana)

**Branch**: `015-matches-daily-feed` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/015-matches-daily-feed/spec.md` (HU 11.1 Notion En curso)

## Summary

Transformar la vista de Partidos (`MatchdayTabView`) en un **Feed Diario Multi-Competición** inspirado fielmente en el diseño `vifutbol - Partidos` de StitchMCP. Incorpora un selector de fecha vía calendario en el `AppBar` junto a notificaciones, una barra fija inferior con tres pestañas rápidas (**Ayer**, **Hoy**, **Mañana**), arrancando siempre con la fecha de hoy, y agrupando los partidos por cada competición activa en tarjetas simétricas con resultados en vivo, programación y gestión contextual para el Organizador.

## Technical Context

**Language/Version**: Dart ^3.12.0 / Flutter SDK  
**Primary Dependencies**: `flutter_riverpod: ^2.6.1`, `intl: any`, `flutter_localizations`, `fluro: ^2.0.5`, `hive: ^2.2.3`  
**Storage**: Hive local storage (reutilización de repositorios existentes: `LocalTournamentMatchesRepository`, `LocalTournamentsRepository`, `LocalTeamsRepository`)  
**Testing**: `flutter_test`, `package:test`  
**Target Platform**: iOS & Android (Mobile Handheld 360px - 480px, responsive)  
**Project Type**: Mobile Application  
**Performance Goals**: Renderizado fluido a 60 fps; cambio de día y filtrado de partidos en < 200 ms; actualización de marcador en vivo en < 5 s  
**Constraints**: Operación offline-first; tokens de diseño KickPulse (`DESIGN.md`); localización obligatoria en español (`l10n`)  
**Scale/Scope**: Múltiples torneos activos simultáneos, hasta 60 partidos por día agrupados dinámicamente  

## Constitution Check

*GATE: Evaluado y verificado contra `.specify/memory/constitution.md`*

- [x] **I. La Spec Manda**: Alcance, historias y casos de borde definidos estrictamente en `spec.md` antes de codificar.
- [x] **II. Integridad de Datos y Fuente de Verdad**: Los partidos y torneos mantienen su modelo de datos inmutable; el agrupamiento diario es una proyección reactiva pura.
- [x] **III. Pruebas Automatizadas como Puerta de Calidad**: Pruebas unitarias de controladores y pruebas de widgets con `WidgetTester` para las pestañas y tarjetas Match Center.
- [x] **IV. Arquitectura Limpia**: Separación estricta entre Dominio (`DailyMatchesGroup`), Aplicación (`DailyMatchesFeedController`) y Presentación (`MatchdayTabView`, `DailyMatchesTabBar`, `MatchCenterCard`).
- [x] **V. Segregación de Roles y Sistema de Diseño**: El banner de gestión de pendientes es exclusivo del `Organizador`. La UI utiliza los tokens de `KickPulseColors`, `KickPulseTypography` y `KickPulseRadiiSpacing`.
- [x] **VI. Convenciones de Idioma**: Código en inglés (controladores, tests, entidades); interfaz de usuario 100% en español a través de `AppLocalizations`.
- [x] **VII. Resiliencia Móvil**: Conservación de estado temporal, soporte offline, manejo de estados vacíos y áreas táctiles mínimas de 48x48 dp.

## Project Structure

### Documentation (this feature)

```text
specs/015-matches-daily-feed/
├── plan.md              # This file
├── research.md          # Technical research & decisions (Phase 0)
├── data-model.md        # Entities, view states and lifecycle (Phase 1)
├── quickstart.md        # Automated & manual testing guide (Phase 1)
├── contracts/
│   └── ui_contracts.md  # Provider interfaces, widget props & l10n keys (Phase 1)
├── checklists/
│   └── requirements.md  # Spec quality checklist (16/16 verified)
└── spec.md              # Feature specification (HU 11.1)
```

### Source Code Changes

```text
lib/
├── application/
│   ├── controllers/
│   │   └── daily_matches_feed_controller.dart          # NUEVO: Gestión de fecha activa y agrupamiento diario
│   └── providers/
│       └── matches_catalog_providers.dart              # ACTUALIZADO: Exporta dailyMatchesFeedControllerProvider
├── domain/
│   └── entities/
│       └── daily_matches_group.dart                    # NUEVO: Value Object TournamentMatchesGroup & MatchesDailyTab
├── l10n/
│   ├── app_localizations.dart                          # ACTUALIZADO: Claves para pestañas y estados de partido
│   └── app_localizations_es.dart                       # ACTUALIZADO: Traducciones en español
└── presentation/
    ├── matches/
    │   └── widgets/
    │       ├── daily_matches_tab_bar.dart              # NUEVO: Barra horizontal Ayer / Hoy / Mañana
    │       ├── match_center_card.dart                  # NUEVO: Tarjeta de partido simétrica (Stitch)
    │       ├── tournament_matches_group_card.dart      # NUEVO: Contenedor de torneo con encabezado y partidos
    │       └── organizer_pending_matches_banner.dart   # NUEVO: Banner destacado para Organizador
    └── shell/
        ├── app_shell_screen.dart                       # ACTUALIZADO: Icono de calendario en AppBar condicional
        └── tabs/
            └── matchday_tab_view.dart                  # ACTUALIZADO: Feed diario por torneos activos
```

---

## Phases & Execution Order

### Phase 0: Outline & Research
- Generación de [`research.md`](research.md) resolviendo modelado temporal, agrupamiento reactivo y patrones visuales de Stitch.

### Phase 1: Design & Contracts
- Generación de [`data-model.md`](data-model.md), [`contracts/ui_contracts.md`](contracts/ui_contracts.md) y [`quickstart.md`](quickstart.md).

### Phase 2: Implementation (Scheduled for `/speckit-implement`)
1. **Core Domain & State**: Crear `daily_matches_group.dart` y `daily_matches_feed_controller.dart` con pruebas unitarias.
2. **Localization**: Incorporar claves en español para Ayer, Hoy, Mañana, estado vacío y tooltips de calendario.
3. **UI Components**: Construir `DailyMatchesTabBar`, `MatchCenterCard`, `TournamentMatchesGroupCard` y `OrganizerPendingMatchesBanner`.
4. **Integration**: Conectar el selector de calendario en `AppShellScreen` y reemplazar el cuerpo de `MatchdayTabView` por el feed diario multi-torneo.
5. **Quality Gate**: Ejecutar suite completa de tests y validación estática `flutter analyze`.
