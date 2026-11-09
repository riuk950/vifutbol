# Implementation Plan: Refactorización de Noticias (Filtros en Menú de 3 Puntos del AppBar y Creación de Noticia desde el Panel) (HU 15.1)

**Branch**: `024-news-filter-menu-panel` | **Date**: 2026-11-09 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/024-news-filter-menu-panel/spec.md`

---

## Summary

Refactorizar la experiencia de noticias de ViFutbol para:
1. **Separar la administración de la lectura pública (US1 - P1)**: Remover el botón `"Nueva Noticia"` (`create_news_button`) del feed público (`TournamentNewsFeedView`) e incorporar la acción rápida `"Publicar Noticia"` (`organizer_action_publish_news`) en el Panel Administrativo del Organizador (`OrganizerPanelContent`), integrando un selector desplegable de competición editable dentro de `CreateNewsDialog` (`create_news_tournament_dropdown`).
2. **Centralizar el filtrado en el AppBar (US2 - P2)**: Renderizar un icono contextual de 3 puntos (`Icons.more_vert`, `app_bar_news_filter_action`) en el `AppBar` de `AppShellScreen` cuando la sección activa sea `"Noticias"` (`AppShellSection.news`), desplegando una hoja modal inferior (`NewsFilterBottomSheet`, `news_filter_bottom_sheet`) que permite elegir torneo y categoría en tiempo real.
3. **Limpiar el feed y mostrar indicador de filtro activo (US3 - P3)**: Retirar las barras horizontales de chips de torneo y categoría del cuerpo del feed, mantener siempre visible el subtítulo del torneo activo (`news_active_tournament_subtitle`) y exhibir un chip removible de filtro activo (`news_active_filter_chip`) cuando se seleccione una categoría distinta de `"Todas"`.

---

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter Stable  
**Primary Dependencies**: `flutter_riverpod`, `flutter_localizations`, `intl` (Existing stack — zero new dependencies)  
**Storage**: Local offline-first persistence via `LocalTournamentNewsRepository` and `LocalTournamentsRepository`  
**Testing**: `flutter_test` (Widget tests covering `NewsTabView`, `TournamentNewsFeedView`, `NewsFilterBottomSheet`, `AppShellScreen`, `OrganizerPanelContent`, and `CreateNewsDialog`, plus compact viewport $320\times 640\text{ px}$ @ $130\%$ text scaling)  
**Target Platform**: iOS & Android (Mobile-first dark tactical *KickPulse* UI)  
**Project Type**: Mobile application (Clean Architecture: Domain, Application, Infrastructure, Presentation)  
**Performance Goals**: Instantaneous reactive filter updates ($<16\text{ ms}$ frame budget, 60 fps scroll without inline chip bars clutter)  
**Constraints**: Offline-capable, zero `RenderFlex` overflows at $320\times 640\text{ px}$ with $130\%$ text scaling, 100% Spanish UI via `l10n`, 100% English technical codebase  
**Scale/Scope**: 1 new widget (`NewsFilterBottomSheet`), 4 updated presentation files (`app_shell_screen.dart`, `news_tab_view.dart`, `tournament_news_feed_view.dart`, `create_news_dialog.dart`, `organizer_panel_content.dart`), 10 new localization keys in `app_es.arb`, and updated/new widget tests.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pre-Research Status | Post-Design Status | Verification Notes |
|-----------|---------------------|--------------------|--------------------|
| **I. La Spec Manda (Spec-Driven Development)** | ✅ PASS | ✅ PASS | Basado en `spec.md` con 6 clarificaciones confirmadas y criterios móviles definidos. |
| **II. Integridad de Datos y Fuente de Verdad Transparente** | ✅ PASS | ✅ PASS | `TournamentNewsItem` conserva integridad referencial con `ChampionshipTournament` y respeta el bloqueo histórico de torneos `finished`. |
| **III. Pruebas Automatizadas como Puerta de Calidad** | ✅ PASS | ✅ PASS | Pruebas de widgets para `NewsTabView`, `NewsFilterBottomSheet`, `AppShellScreen` y `OrganizerPanelContent`. |
| **IV. Arquitectura Limpia y Separación de Responsabilidades** | ✅ PASS | ✅ PASS | Sincronización desacoplada a través de `tournamentsControllerProvider` y `tournamentNewsControllerProvider`. |
| **V. Segregación de Roles y Fidelidad al Sistema de Diseño** | ✅ PASS | ✅ PASS | Creación de noticias restringida exclusivamente a `UserRole.organizer` en `/panel`; tokens *KickPulse* aplicados en modal y chips. |
| **VI. Convenciones de Idioma y Nomenclatura** | ✅ PASS | ✅ PASS | Identificadores técnicos en inglés; 10 nuevas claves en español en `lib/l10n/app_es.arb`. |
| **VII. Resiliencia y Experiencia Móvil (`MOBILE_GUIDELINES.md`)** | ✅ PASS | ✅ PASS | `Wrap` responsivo en modal de filtros y cabecera, touch targets $\ge 48\times 48\text{ dp}$, cero overflows en $320\times 640\text{ px}$ @ $130\%$. |

---

## Project Structure

### Documentation (this feature)

```text
specs/024-news-filter-menu-panel/
├── plan.md                                      # This file (/speckit-plan output)
├── research.md                                  # Phase 0 output
├── data-model.md                                # Phase 1 output
├── quickstart.md                                # Phase 1 output
├── contracts/
│   └── ui-news-filter-panel-contracts.md        # Phase 1 UI & l10n contracts
├── checklists/
│   └── requirements.md                          # Spec quality checklist (16/16 passing)
└── tasks.md                                     # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── l10n/
│   ├── app_es.arb                               # +10 Spanish localization keys
│   ├── app_localizations.dart                   # Generated
│   └── app_localizations_es.dart                # Generated
└── presentation/
    ├── news/
    │   ├── tournament_news_feed_view.dart       # Remove inline filter bar & create button; add empty category filter state
    │   └── widgets/
    │       ├── create_news_dialog.dart          # Add optional availableTournaments dropdown selector
    │       └── news_filter_bottom_sheet.dart    # NEW: Modal bottom sheet for tournament & category filtering
    ├── panel/
    │   └── widgets/
    │       └── organizer_panel_content.dart     # Add "Publicar Noticia" quick action button & handler
    └── shell/
        ├── app_shell_screen.dart                # Add contextual more_vert action when activeSection == AppShellSection.news
        └── tabs/
            └── news_tab_view.dart               # Remove horizontal tournament chips; show active tournament subtitle & active category chip

test/
├── presentation/
│   ├── app_shell_widget_test.dart               # Verify more_vert action visibility on News tab vs other tabs
│   └── panel/
│       └── organizer_panel_widget_test.dart     # Verify "Publicar Noticia" quick action & CreateNewsDialog tournament dropdown
└── widget/
    └── tournament_news_feed_widget_test.dart    # Verify clean feed (no create button), NewsFilterBottomSheet, active filter chip & clear action
```

**Structure Decision**: Se mantiene la estructura modular por capas de `lib/presentation/` (`news`, `panel`, `shell`), añadiendo únicamente `news_filter_bottom_sheet.dart` y actualizando los widgets existentes sin introducir dependencias externas.

---

## Complexity Tracking

> **No Constitution Check violations.** Zero complexity exceptions required.
