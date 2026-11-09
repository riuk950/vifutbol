# Quickstart & Validation Guide: Refactorización de Noticias (HU 15.1)

**Feature**: `024-news-filter-menu-panel`  
**Date**: 2026-11-09

---

## 1. Prerequisites

- Flutter SDK (stable) & Dart 3.11+
- Dependencias instaladas (`flutter pub get`)
- Clases de localización generadas (`flutter gen-l10n`)

---

## 2. Verification Scenarios

### Scenario 1: Publicación de Noticia Exclusiva desde el Panel (`/panel`) (US1)
1. Abrir `NewsTabView` o `TournamentNewsFeedView` con rol `UserRole.organizer`.
2. Verificar que **no** se renderiza `Key('create_news_button')` ni barras horizontales de chips en el feed.
3. Navegar a `/panel` (`OrganizerPanelContent`) y pulsar el botón `"Publicar Noticia"` (`Key('organizer_action_publish_news')`).
4. En `CreateNewsDialog`, seleccionar la competición activa en `Key('create_news_tournament_dropdown')`, elegir categoría, ingresar título y contenido, y pulsar `"Publicar Comunicado"` (`Key('create_news_submit_button')`).
5. Verificar que aparece el `SnackBar` de éxito y el comunicado queda registrado en el torneo seleccionado.

### Scenario 2: Menú de 3 Puntos (`more_vert`) en el AppBar de Noticias (US2)
1. En `AppShellScreen`, cambiar a la pestaña `"Noticias"` (`AppShellSection.news`).
2. Verificar que el `AppBar` exhibe el botón `Key('app_bar_news_filter_action')` (`Icons.more_vert`).
3. Cambiar a `"Partidos"` o `"Perfil"` y verificar que `Key('app_bar_news_filter_action')` desaparece.
4. Volver a `"Noticias"`, tocar `Key('app_bar_news_filter_action')` y verificar que se abre `NewsFilterBottomSheet` (`Key('news_filter_bottom_sheet')`).
5. Tocar un chip de torneo (`Key('news_filter_tournament_chip_<id>')`) o de categoría (`Key('news_filter_category_chip_disciplinary')`) y verificar que el feed se actualiza inmediatamente en tiempo real mientras el modal permanece abierto.

### Scenario 3: Subtítulo del Torneo e Indicador de Filtro Activo (US3)
1. En `NewsTabView`, verificar que siempre se muestra el nombre del torneo activo en `Key('news_active_tournament_subtitle')`.
2. Con una categoría específica filtrada, verificar que se muestra `Key('news_active_filter_chip')`.
3. Tocar el botón de limpieza del chip y verificar que `categoryFilter` vuelve a `null` ("Todas") y el chip desaparece.

---

## 3. Automated Test & Quality Commands

```bash
# Regenerate localization files
flutter gen-l10n

# Run static analysis
flutter analyze

# Verify formatting
dart format --output=none --set-exit-if-changed .

# Run feature widget tests
flutter test test/widget/tournament_news_feed_widget_test.dart test/presentation/panel/organizer_panel_widget_test.dart test/presentation/app_shell_widget_test.dart test/widget/season_closure_honor_roll_widget_test.dart
```
