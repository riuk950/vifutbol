# Implementation Plan: Pestaña de Plantilla y Jugadores del Equipo (HU 14.3)

**Branch**: `023-team-squad-roster` | **Date**: 2026-11-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/023-team-squad-roster/spec.md`

---

## Summary

Implementar la pestaña **"Plantilla"** (`TeamSquadTabView`) dentro de `TeamDetailScreen` (`/teams/:id`), sustituyendo la vista de preparación actual por la nómina oficial completa del equipo en modo de consulta deportiva. La vista consume directamente los jugadores inscritos en `team.players` (`RegisteredPlayer`), los estructura verticalmente en **4 bloques fijos por posición táctica** (**Porteros**, **Defensas**, **Centrocampistas** y **Delanteros**) con sus respectivos encabezados de sección y los ordena de forma ascendente según su número de camiseta (`shirtNumber`) dentro de cada bloque. Cada tarjeta de jugador exhibe su dorsal con tipografía tabular (`tabular-nums`), nombre completo, badge de posición en español (*Portero*, *Defensa*, *Centrocampista*, *Delantero*) y badge semántico de elegibilidad (**Habilitado** en verde con `KickPulseBadgeVariant.success` o **Suspendido** en rojo con `KickPulseBadgeVariant.live`), con área táctil mínima de `48x48 dp` y lectura semántica accesible. Al tocar cualquier jugador se abre la hoja modal de perfil de rendimiento (`showPlayerPerformanceProfileSheet` / `PlayerPerformanceProfileCard`) permitiendo alternar entre compañeros de plantilla.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Flutter Riverpod (`flutter_riverpod`), Fluro Router (`fluro`), Intl (`intl`)  
**Storage**: Almacenamiento local offline-first a través de repositorios desacoplados (`LocalTeamsRepository`, `LocalTournamentsRepository`)  
**Testing**: `flutter test` (Unit tests para `TeamSquadRoster`, Widget tests para `TeamSquadTabView` y `TeamDetailScreen`, y pruebas responsivas en `320x640` con texto al `130%`)  
**Target Platform**: Mobile (Android / iOS) con diseño responsive adaptativo  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: Renderizado de la pestaña "Plantilla" (hasta 18 jugadores en 4 bloques tácticos) en `< 100 ms`; desplazamiento fluido a `60 fps`  
**Constraints**: 100% offline-first, 0 desbordamientos de `RenderFlex` en `320x640 px` con escalado tipográfico al `130%`, áreas táctiles mínimas de `48x48 dp` y lectura semántica accesible  
**Scale/Scope**: Modelo determinista inmutable `TeamSquadRoster` (`TeamSquadPlayerItem`), provider reactivo `teamSquadRosterProvider`, widget `TeamSquadTabView`, integración en la 3ra pestaña de `TeamDetailScreen`, localización en `app_es.arb` y suite de pruebas automatizadas  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: ✅ Cumple. La especificación en `spec.md` define los requisitos `FR-001` a `FR-009` y las 3 decisiones de clarificación de la sesión.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: ✅ Cumple. La plantilla del equipo se deriva de forma determinista e inmutable directamente desde `team.players` (`RegisteredPlayer`) en el catálogo local de equipos sin duplicar ni mutar estado.
- **III. Pruebas Automatizadas como Puerta de Calidad**: ✅ Cumple. Se incluyen pruebas unitarias para `TeamSquadRoster.fromCatalog`, pruebas de widgets para `TeamSquadTabView` (4 bloques tácticos, orden por dorsal, badges de elegibilidad, modal de rendimiento y estados vacíos) y pruebas de responsividad (`320x640` @ `130%`).
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: ✅ Cumple. Separación estricta entre entidades de dominio (`TournamentTeam`, `RegisteredPlayer`, `PlayerPosition`, `PlayerPerformanceProfile`), modelo/provider de presentación (`TeamSquadRoster`, `teamSquadRosterProvider`) y widgets de interfaz (`TeamSquadTabView`).
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: ✅ Cumple. La pestaña "Plantilla" en `/teams/:id` es de consulta deportiva para todos los roles manteniendo la edición administrativa en `/tournaments/teams/detail`; emplea `KickPulseColors`, `KickPulseTypography`, `KickPulseCard`, `KickPulseBadge` y reutiliza `PlayerPerformanceProfileCard`.
- **VI. Convenciones de Idioma y Nomenclatura**: ✅ Cumple. Código técnico, modelos y tests en **inglés**; textos visibles en **español** centralizados en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: ✅ Cumple. Consulta 100% offline, preservación de scroll con `PageStorageKey`, manejo de estados vacíos globales y por línea táctica, áreas táctiles $\ge 48 \times 48\text{ dp}$, `Semantics` con dorsal/nombre/posición/estado y diseño adaptativo en `320x640 px` @ `130%`.

---

## Project Structure

### Documentation (this feature)

```text
specs/023-team-squad-roster/
├── plan.md              # Plan de implementación (/speckit-plan)
├── research.md          # Investigación técnica y decisiones de diseño (Fase 0)
├── data-model.md        # Modelos de datos: TeamSquadRoster y TeamSquadPlayerItem (Fase 1)
├── quickstart.md        # Guía de validación manual y automatizada (Fase 1)
├── contracts/           # Contratos de UI, claves de widgets y l10n (Fase 1)
│   └── ui-team-squad-contracts.md
└── checklists/
    └── requirements.md  # Checklist de calidad de requerimientos
```

### Source Code (repository root)

```text
lib/
├── application/
│   └── providers/
│       └── teams_providers.dart                         # Nuevo provider reactivo teamSquadRosterProvider
├── l10n/
│   ├── app_es.arb                                       # Nuevas claves l10n en español para HU 14.3
│   ├── app_localizations.dart
│   └── app_localizations_es.dart
├── presentation/
│   └── teams/
│       ├── team_detail_screen.dart                      # Conexión de TeamSquadTabView en la 3ra pestaña ("Plantilla")
│       ├── models/
│       │   ├── team_match_summary.dart                  # Modelo existente de HU 14.1
│       │   ├── team_matches_schedule.dart               # Modelo existente de HU 14.2
│       │   └── team_squad_roster.dart                   # Modelo inmutable TeamSquadRoster y TeamSquadPlayerItem
│       └── widgets/
│           ├── team_info_tab_view.dart                  # Vista existente de HU 14.1
│           ├── team_matches_tab_view.dart               # Vista existente de HU 14.2
│           └── team_squad_tab_view.dart                 # Nueva vista de la pestaña "Plantilla" (4 bloques + modal)

test/
├── presentation/
│   ├── directories_responsive_widget_test.dart          # Validación responsiva 320x640 @ 130% incluyendo pestaña "Plantilla"
│   └── teams/
│       ├── team_squad_roster_test.dart                  # Pruebas unitarias de agrupación táctica y orden por dorsal
│       └── team_detail_screen_test.dart                 # Pruebas de widget para TeamSquadTabView, badges, modal y estados vacíos
```

**Structure Decision**: Se mantiene la estructura modular en `lib/presentation/teams/` consolidada en las HU 14.1 y 14.2, añadiendo `team_squad_roster.dart` en `models/` y `team_squad_tab_view.dart` en `widgets/`, e integrándolo directamente en la tercera pestaña del `TabBarView` de `TeamDetailScreen` para cerrar la Épica 14.

---

## Complexity Tracking

*No se detectan violaciones a la constitución ni complejidades adicionales.*
