# Implementation Plan: Pantalla de Detalle de Equipo con Pestañas y Resumen (Último y Próximo Partido) (HU 14.1)

**Branch**: `021-team-detail-summary` | **Date**: 2026-11-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/021-team-detail-summary/spec.md`

---

## Summary

Implementar la pantalla dedicada de Detalle de Equipo en la ruta `/teams/:id` (`TeamDetailScreen`), accesible al seleccionar un equipo en `TeamsDirectoryScreen` o al tocar la zona táctil del escudo/nombre del equipo local o visitante en `MatchCenterCard`. La pantalla presenta un `AppBar` estilizado con la identidad visual del club (`KickPulseTeamCrest`, nombre oficial, código corto, insignia de elegibilidad y competición asociada) y una barra fija de 3 pestañas horizontales ("Información", "Partidos" y "Plantilla") con "Información" seleccionada por defecto. En la pestaña "Información" (`TeamInfoTabView`), se despliegan la Tarjeta de Ficha del Club (con acentos de color primario y secundario) y las tarjetas destacadas de "Último Partido" (con marcador final `FT`, rival, fecha y sede, o estado vacío *"Sin partidos previos disputados"*) y "Próximo Partido" (con rival, fecha, hora y cancha/sede, o estado vacío *"Sin próximos partidos agendados"*), derivadas eficientemente mediante un selector/modelo determinista sobre el catálogo de partidos.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x  
**Primary Dependencies**: Flutter Riverpod (`flutter_riverpod`), Fluro Router (`fluro`), Intl (`intl`)  
**Storage**: Almacenamiento local offline-first a través de repositorios desacoplados (`LocalTeamsRepository`, `LocalTournamentsRepository`, `LocalTournamentMatchesRepository`)  
**Testing**: `flutter test` (Unit tests para cálculo de resumen de equipo, Widget tests para `TeamDetailScreen`, `TeamInfoTabView`, `MatchCenterCard` y `TeamsDirectoryScreen`, y pruebas responsivas en `320x640` con texto al `130%`)  
**Target Platform**: Mobile (Android / iOS) con diseño responsive adaptativo  
**Project Type**: Mobile App (Flutter)  
**Performance Goals**: Carga y renderizado de la pantalla de detalle en `< 500 ms`; desplazamiento fluido a `60 fps`  
**Constraints**: 100% offline-first, 0 desbordamientos de `RenderFlex` en `320x640 px` con escalado tipográfico al `130%`, áreas táctiles mínimas de `48x48 dp`  
**Scale/Scope**: 1 nueva pantalla de detalle (`TeamDetailScreen`), modelo/selector determinista `TeamMatchSummary`, subwidgets para las 3 pestañas (`TeamInfoTabView` y estados de preparación para "Partidos" y "Plantilla"), actualización de `AppRouter`, `TeamsDirectoryScreen` y `MatchCenterCard`, localización en `app_es.arb` y pruebas automatizadas  

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. La Spec Manda (Spec-Driven Development)**: ✅ Cumple. La especificación en `spec.md` define exhaustivamente los requisitos (`FR-001` a `FR-013`) y documenta las 3 decisiones de clarificación de la sesión.
- **II. Integridad de Datos y Fuente de Verdad Transparente**: ✅ Cumple. El resumen de último y próximo partido se deriva determinísticamente de las entidades oficiales (`TournamentTeam`, `ChampionshipTournament`, `ChampionshipMatch`) sin duplicar estado mutable.
- **III. Pruebas Automatizadas como Puerta de Calidad**: ✅ Cumple. Se contemplan pruebas unitarias del selector de partidos del equipo y pruebas de widget de navegación, pestañas, resumen, estados vacíos y responsividad.
- **IV. Arquitectura Limpia y Separación de Responsabilidades**: ✅ Cumple. Separación clara entre entidades del dominio, proyección/selector en aplicación/presentación y componentes visuales desacoplados.
- **V. Segregación de Roles y Fidelidad al Sistema de Diseño**: ✅ Cumple. Consulta pública accesible para todos los roles manteniendo intacta la ruta administrativa `/tournaments/teams/detail` (`TeamRosterDetailScreen`); uso estricto de `KickPulseColors`, `KickPulseTypography` y `KickPulseRadiiSpacing` con acentos sutiles de los colores del club.
- **VI. Convenciones de Idioma y Nomenclatura**: ✅ Cumple. Todo el código técnico, identificadores y tests en **inglés**; todos los textos visibles en **español** centralizados en `lib/l10n/app_es.arb`.
- **VII. Resiliencia y Experiencia Móvil (`docs/MOBILE_GUIDELINES.md`)**: ✅ Cumple. Soporta consulta offline-first, conservación de pestaña activa, manejo de equipos no encontrados, estados vacíos claros y adaptación a `320x640 px` @ `130%` texto.

---

## Project Structure

### Documentation (this feature)

```text
specs/021-team-detail-summary/
├── plan.md              # Plan de implementación (/speckit-plan)
├── research.md          # Investigación técnica y decisiones de diseño (Fase 0)
├── data-model.md        # Modelos de datos y proyección TeamMatchSummary (Fase 1)
├── quickstart.md        # Guía de validación manual y automatizada (Fase 1)
├── contracts/           # Contratos de UI, claves de widgets y l10n (Fase 1)
│   └── ui-team-detail-contracts.md
└── checklists/
    └── requirements.md  # Checklist de calidad de requerimientos
```

### Source Code (repository root)

```text
lib/
├── application/
│   └── providers/
│       └── teams_providers.dart                         # Selector/provider de resumen de equipo (teamDetailSummaryProvider)
├── l10n/
│   ├── app_es.arb                                       # Nuevas claves l10n en español para HU 14.1
│   ├── app_localizations.dart
│   └── app_localizations_es.dart
├── presentation/
│   ├── directories/
│   │   └── teams_directory_screen.dart                  # Navegación a TeamDetailScreen (/teams/:id)
│   ├── matches/
│   │   └── widgets/
│   │       └── match_center_card.dart                   # Zonas táctiles por equipo hacia /teams/:id
│   ├── navigation/
│   │   └── app_router.dart                              # Registro de ruta /teams/:id
│   └── teams/
│       ├── team_detail_screen.dart                      # Pantalla principal con AppBar de identidad y TabBar (3 pestañas)
│       ├── models/
│       │   └── team_match_summary.dart                  # Modelo inmutable y cálculo determinista de último/próximo partido
│       └── widgets/
│           └── team_info_tab_view.dart                  # Pestaña "Información" (Ficha del Club, Último y Próximo Partido)

test/
├── presentation/
│   ├── directories_responsive_widget_test.dart          # Validación responsiva 320x640 @ 130%
│   ├── teams_directory_screen_test.dart                 # Actualización de prueba de navegación a TeamDetailScreen
│   ├── matches/
│   │   └── widgets/
│   │       └── match_center_card_test.dart              # Pruebas de toque en equipo local/visitante vs centro
│   └── teams/
│       ├── team_match_summary_test.dart                 # Pruebas unitarias de derivación determinista
│       └── team_detail_screen_test.dart                 # Pruebas integrales de widget para HU 14.1
```

**Structure Decision**: Se sigue la arquitectura modular existente en `lib/presentation/teams/` (análoga a `lib/presentation/tournaments/` creada en la Épica 13), ubicando `TeamDetailScreen` en `lib/presentation/teams/team_detail_screen.dart`, el modelo determinista en `lib/presentation/teams/models/team_match_summary.dart` y la vista de la pestaña de información en `lib/presentation/teams/widgets/team_info_tab_view.dart`.

---

## Complexity Tracking

*No se detectan violaciones a la constitución ni complejidades adicionales.*
