# Implementation Plan: Navegación a Detalles de la Competición desde "Mis Competiciones" en el Panel (HU 18.3)

**Branch**: `develop` | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)  
**Feature Directory**: `specs/034-organizer-competition-navigation`  
**Notion Target Card**: `[Épica 18] HU 18.3` (`4158442e-3f49-81ba-bf7e-c0f320eb8990`)  

---

## Summary

Implementar la capacidad de navegación directa desde cualquier tarjeta de torneo dentro de la sección "Mis Competiciones" en el Panel de Organización (`OrganizerCompetitionsSection`) hacia la pantalla de detalle de la competición (`CompetitionDetailScreen` en la ruta `/competitions/:id`). Al hacer tap en la superficie de la tarjeta, se sincroniza el torneo seleccionado en el controlador global (`tournamentsController.selectTournament(id)`), se navega transfiriendo el contexto correspondiente y se aísla por completo el menú secundario de tres puntos (`PopupMenuButton`) para evitar disparos accidentales. Adicionalmente, se incluye guarda de protección contra pulsaciones dobles o repetidas (debouncing < 500 ms) para garantizar una experiencia móvil resiliente según el Principio VII de la Constitución.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x)  
**Primary Dependencies**: Flutter SDK, `flutter_riverpod` (v2.6.1), `fluro` (AppRouter)  
**Storage**: Local storage (`shared_preferences` / in-memory fallback)  
**Testing**: `flutter_test`, `flutter_localizations`  
**Target Platform**: Android, iOS (Mobile-first)  
**Project Type**: Mobile Application (`vifutbol`)  
**Performance Goals**: Transición visual inmediata (<100 ms perceptivos) tras toque en tarjeta  
**Constraints**: 
- Aislamiento total de hit testing para el menú de opciones secundarias (tres puntos).
- Debounce de 500 ms para descartar toques duplicados rápidos.
- Cero regresiones en la navegación de regreso (`Navigator.pop()`) manteniendo el estado del panel.
**Scale/Scope**: Sección "Mis Competiciones" en el Panel de Organización y navegación a `/competitions/:id`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Plan Compliance | Status |
|---|---|---|---|
| **I. La Spec Manda** | Basado en especificación completa, plan y tareas; sin desviaciones. | Todas las decisiones derivan directamente de `spec.md` y Notion HU 18.3. | **PASS** |
| **II. Integridad de Datos** | Fuente de verdad transparente e identificadores inmutables. | Se preserva la entidad `ChampionshipTournament.id` inmutable transferida a `CompetitionDetailScreen`. | **PASS** |
| **III. Pruebas como Puerta** | TDD: Pruebas automatizadas de widget e integración previas al cierre. | Se definen pruebas completas en `test/presentation/panel/organizer_competitions_section_test.dart`. | **PASS** |
| **IV. Arquitectura Limpia** | Separación por capas (Dominio, Aplicación, Presentación). | Se respeta la separación: controladores de aplicación (`TournamentsController`) vs componentes de presentación (`OrganizerCompetitionsSection`). | **PASS** |
| **V. Segregación de Roles y Diseño** | Tokens de `DESIGN.md` y rol de Organizador. | `KickPulseCard` con bordes de 16px, efectos `InkWell`, colores de diseño y permisos activos de organizador. | **PASS** |
| **VI. Convenciones de Idioma** | Código técnico en inglés, textos visibles en español vía `l10n`. | Código, variables y pruebas 100% en inglés; textos de UI centralizados en `l10n`. | **PASS** |
| **VII. Resiliencia Móvil** | `docs/MOBILE_GUIDELINES.md`: debouncing, hit testing, navegación limpia. | Debounce de 500 ms para toques repetidos, hit testing aislado para el menú de 3 puntos y retorno suave sin pérdida de estado. | **PASS** |

**Gate Result**: **7 / 7 PASSED**. Ninguna violación arquitectónica detectada.

---

## Project Structure

### Documentation (this feature)

```text
specs/034-organizer-competition-navigation/
├── plan.md              # Este plan de implementación
├── research.md          # Investigación técnica y decisiones (Phase 0)
├── data-model.md        # Modelo de estado y flujo de navegación (Phase 1)
├── contracts/           # Contratos de componentes y rutas (Phase 1)
│   └── competition-navigation-contracts.md
├── quickstart.md        # Guía de validación y recetas de prueba (Phase 1)
├── checklists/          # Checklist de calidad de requisitos
│   └── requirements.md
└── tasks.md             # Desglose detallado de tareas (Phase 2 - generado por /speckit-tasks)
```

### Source Code

```text
lib/
├── presentation/
│   ├── panel/
│   │   └── widgets/
│   │       ├── organizer_competitions_section.dart  # Sección de competiciones (se agrega onTap + debounce)
│   │       └── organizer_panel_content.dart         # Integración del panel
│   ├── tournaments/
│   │   └── competition_detail_screen.dart           # Pantalla destino (/competitions/:id)
│   └── navigation/
│       └── app_router.dart                          # Ruta /competitions/:id
test/
└── presentation/
    └── panel/
        └── organizer_competitions_section_test.dart # Pruebas de widget de navegación, menú y debounce
```

---

## Implementation Details

### 1. `OrganizerCompetitionsSection` (`organizer_competitions_section.dart`)
- Convertir o mantener como `ConsumerStatefulWidget` para retener la marca de tiempo `DateTime? _lastNavigationTap`.
- Incorporar parámetro opcional `final ValueChanged<ChampionshipTournament>? onTapTournament;` en el constructor para inyección y pruebas directas.
- En `_handleTournamentTap`:
  ```dart
  void _handleTournamentTap(
    BuildContext context,
    ChampionshipTournament tournament,
  ) {
    final now = DateTime.now();
    if (_lastNavigationTap != null &&
        now.difference(_lastNavigationTap!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastNavigationTap = now;

    ref.read(tournamentsControllerProvider.notifier).selectTournament(tournament.id);

    if (widget.onTapTournament != null) {
      widget.onTapTournament!(tournament);
    } else {
      Navigator.of(context).pushNamed('/competitions/${tournament.id}');
    }
  }
  ```
- Pasar `onTap: () => _handleTournamentTap(context, tournament)` a `KickPulseCard`.

### 2. Aislamiento del Menú Contextual (3 puntos)
- El widget `PopupMenuButton<String>` continúa residiendo dentro de la fila de la tarjeta con su `Key('organizer_competition_menu_button_${tournament.id}')`.
- Al pulsar el menú de tres puntos, Flutter maneja el evento de toque de forma independiente, asegurando que `_handleTournamentTap` no se invoque.

### 3. Suite de Pruebas Automatizadas (`organizer_competitions_section_test.dart`)
- **Test 1**: Tapping card invokes `selectTournament` and pushes `/competitions/:id`.
- **Test 2**: Back button in `CompetitionDetailScreen` pops cleanly back to `PanelScreen`.
- **Test 3**: Tapping 3-dots popup menu opens action menu items without triggering card navigation.
- **Test 4**: Tapping card twice within 500 ms triggers navigation exactly once (debouncing).

---

## Complexity Tracking

*No hay violaciones constitucionales ni sobrecostos arquitectónicos injustificados.*
