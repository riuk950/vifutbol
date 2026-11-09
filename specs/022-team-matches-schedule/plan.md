# Implementation Plan: Pestaña de Calendario de Partidos del Equipo (Próximos e Historial) (HU 14.2)

**Branch**: `022-team-matches-schedule` | **Date**: 2026-11-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/022-team-matches-schedule/spec.md`

---

## Summary

Implementar la pestaña **"Partidos"** (`TeamMatchesTabView`) dentro de `TeamDetailScreen` (`/teams/:id`), sustituyendo la vista de preparación actual por el calendario completo del equipo. La vista filtra exclusivamente los encuentros donde el club participa como local o visitante (`homeTeamId == teamId || awayTeamId == teamId`) y los presenta en un listado vertical continuo dividido en dos secciones: **"Próximos Partidos"** (encuentros `inProgress`, `scheduled` y `pendingSchedule` ordenados cronológicamente de menor a mayor fecha) y **"Resultados Anteriores"** (encuentros `completed` ordenados del más reciente al más antiguo). Cada partido reutiliza `MatchCenterCard` envuelto en un contenedor con franja superior de metadatos (jornada, fecha y cancha/sede) y un distintivo semántico (`KickPulseBadge`): condición Local/Visitante en próximos partidos, y resultado deportivo (**Victoria** en verde, **Empate** en gris/amarillo, **Derrota** en rojo sutil) en resultados anteriores. Al tocar un partido se abre un `ModalBottomSheet` informativo con el resumen/informe del encuentro, mientras que los toques en escudo/nombre navegan al detalle del equipo rival.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Flutter Riverpod (`flutter_riverpod`), Fluro Router (`fluro`), Intl (`intl`)  
**Storage**: Almacenamiento local offline-first a través de repositorios desacoplados (`LocalTeamsRepository`, `LocalTournamentsRepository`, `LocalTournamentMatchesRepository`)  
**Testing**: `flutter test` (Unit tests para `TeamMatchesSchedule` y cálculo de `TeamMatchOutcome`, Widget tests para `TeamMatchesTabView` y `TeamDetailScreen`, y pruebas responsivas en `320x640` con texto al `130%`)  
**Target Platform**: Mobile (Android / iOS) con diseño responsive adaptativo  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: Renderizado de la pestaña "Partidos" en `< 300 ms`; desplazamiento fluido a `60 fps`  
**Constraints**: 100% offline-first, 0 desbordamientos de `RenderFlex` en `320x640 px` con escalado tipográfico al `130%`, áreas táctiles mínimas de `48x48 dp`  
**Scale/Scope**: Variante semántica `success` en `KickPulseBadge`, modelo determinista `TeamMatchesSchedule` (`TeamScheduledMatchItem` + `TeamMatchOutcome`), provider reactivo `teamMatchesScheduleProvider`, widget `TeamMatchesTabView`, integración en `TeamDetailScreen`, localización en `app_es.arb` y suite de pruebas automatizadas  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: ✅ Cumple. La especificación en `spec.md` define los requisitos `FR-001` a `FR-011` y las 3 decisiones de clarificación de la sesión.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: ✅ Cumple. El calendario del equipo y el desenlace de cada partido (`win`, `draw`, `loss`) se derivan de forma determinista desde el catálogo oficial de partidos y equipos sin duplicar ni mutar estado.
- **III. Pruebas Automatizadas como Puerta de Calidad**: ✅ Cumple. Se incluyen pruebas unitarias para `TeamMatchesSchedule.fromCatalog`, pruebas de widgets para `TeamMatchesTabView` y pruebas de responsividad (`320x640` @ `130%`).
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: ✅ Cumple. Separación estricta entre entidades de dominio, modelo/selector de presentación y widgets de interfaz.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: ✅ Cumple. El modal de informe del partido es de consulta informativa para todos los roles sin exponer edición arbitral; emplea `KickPulseColors`, `KickPulseTypography`, `KickPulseBadge` y reutiliza `MatchCenterCard`.
- **VI. Convenciones de Idioma y Nomenclatura**: ✅ Cumple. Código técnico, modelos y tests en **inglés**; textos visibles en **español** centralizados en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: ✅ Cumple. Consulta 100% offline, preservación de scroll con `PageStorageKey`, manejo de estados vacíos globales y por sección, etiquetas textuales explícitas acompañando colores semánticos y diseño adaptativo en `320x640 px` @ `130%`.

---

## Project Structure

### Documentation (this feature)

```text
specs/022-team-matches-schedule/
├── plan.md              # Plan de implementación (/speckit-plan)
├── research.md          # Investigación técnica y decisiones de diseño (Fase 0)
├── data-model.md        # Modelos de datos: TeamMatchesSchedule y TeamMatchOutcome (Fase 1)
├── quickstart.md        # Guía de validación manual y automatizada (Fase 1)
├── contracts/           # Contratos de UI, claves de widgets y l10n (Fase 1)
│   └── ui-team-matches-contracts.md
└── checklists/
    └── requirements.md  # Checklist de calidad de requerimientos
```

### Source Code (repository root)

```text
lib/
├── application/
│   └── providers/
│       └── teams_providers.dart                         # Nuevo provider reactivo teamMatchesScheduleProvider
├── l10n/
│   ├── app_es.arb                                       # Nuevas claves l10n en español para HU 14.2
│   ├── app_localizations.dart
│   └── app_localizations_es.dart
├── presentation/
│   ├── design_system/
│   │   └── widgets/
│   │       └── kick_pulse_badge.dart                    # Adición de variante semántica KickPulseBadgeVariant.success (verde)
│   └── teams/
│       ├── team_detail_screen.dart                      # Conexión de TeamMatchesTabView en la 2da pestaña ("Partidos")
│       ├── models/
│       │   ├── team_match_summary.dart                  # Modelo existente de HU 14.1
│       │   └── team_matches_schedule.dart               # Modelo inmutable TeamMatchesSchedule, TeamScheduledMatchItem y TeamMatchOutcome
│       └── widgets/
│           ├── team_info_tab_view.dart                  # Vista existente de HU 14.1
│           └── team_matches_tab_view.dart               # Nueva vista de la pestaña "Partidos" (Próximos + Historial + Modal)

test/
├── presentation/
│   ├── directories_responsive_widget_test.dart          # Validación responsiva 320x640 @ 130% incluyendo pestaña "Partidos"
│   └── teams/
│       ├── team_matches_schedule_test.dart              # Pruebas unitarias de filtrado, ordenamiento y cálculo V/E/D
│       └── team_detail_screen_test.dart                 # Pruebas de widget para TeamMatchesTabView, badges, modal y estados vacíos
```

**Structure Decision**: Se mantiene la organización modular en `lib/presentation/teams/` creada en la HU 14.1, añadiendo `team_matches_schedule.dart` en `models/` y `team_matches_tab_view.dart` en `widgets/`, e integrándolo directamente en la segunda pestaña del `TabBarView` de `TeamDetailScreen`.

---

## Complexity Tracking

*No se detectan violaciones a la constitución ni complejidades adicionales.*
