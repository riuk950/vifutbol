# UI Contracts: Refactorización de Noticias (HU 15.1)

**Feature**: `024-news-filter-menu-panel`  
**Date**: 2026-11-09

---

## 1. Widget Key Contracts

### `AppShellScreen` (`lib/presentation/shell/app_shell_screen.dart`)
| Key | Widget | Condition / Behavior |
|-----|--------|----------------------|
| `Key('app_bar_news_filter_action')` | `IconButton(icon: Icon(Icons.more_vert))` | Renderizado únicamente cuando `shellState.activeSection == AppShellSection.news`. Al pulsarse abre `NewsFilterBottomSheet`. |

### `NewsFilterBottomSheet` (`lib/presentation/news/widgets/news_filter_bottom_sheet.dart`)
| Key | Widget | Condition / Behavior |
|-----|--------|----------------------|
| `Key('news_filter_bottom_sheet')` | `SafeArea` / Container | Contenedor raíz de la hoja modal inferior de filtrado. |
| `Key('news_filter_reset_button')` | `TextButton` | Restablece `categoryFilter` a `null` ("Todas"). |
| `Key('news_filter_close_button')` | `IconButton` | Cierra la hoja modal (`Navigator.pop`). |
| `Key('news_filter_tournament_chip_${tournament.id}')` | `ChoiceChip` | Selecciona el torneo activo en `tournamentsControllerProvider` de forma reactiva sin cerrar el modal. |
| `Key('news_filter_category_chip_all')` | `ChoiceChip` | Selecciona `"Todas"` (`categoryFilter = null`) de forma reactiva sin cerrar el modal. |
| `Key('news_filter_category_chip_${category.name}')` | `ChoiceChip` | Selecciona la categoría (`general`, `disciplinary`, `rescheduling`) de forma reactiva sin cerrar el modal. |

### `NewsTabView` & `TournamentNewsFeedView` (`lib/presentation/shell/tabs/news_tab_view.dart`, `lib/presentation/news/tournament_news_feed_view.dart`)
| Key | Widget | Condition / Behavior |
|-----|--------|----------------------|
| `Key('news_tab_header')` | `Row` | Encabezado principal `"Noticias"` con badge `"OFICIAL"`. |
| `Key('news_active_tournament_subtitle')` | `Text` | Muestra permanentemente el nombre del torneo activo bajo el encabezado. |
| `Key('news_active_filter_chip')` | `InputChip` / `Chip` | Visible únicamente cuando `newsState.categoryFilter != null`. Muestra la categoría activa y permite limpiarla con un toque (`onDeleted` / `onPressed`). |
| `Key('news_active_filter_clear_button')` | `InkWell` / deleteIcon | Acción para restablecer `categoryFilter` a `null`. |
| `Key('create_news_button')` | *(Removido)* | **NO DEBE** renderizarse en `NewsTabView` ni en `TournamentNewsFeedView` para ningún rol. |
| `Key('news_tournament_selector')` | *(Removido)* | **NO DEBE** renderizarse la barra horizontal de torneos en `NewsTabView`. |

### `OrganizerPanelContent` & `CreateNewsDialog` (`lib/presentation/panel/widgets/organizer_panel_content.dart`, `lib/presentation/news/widgets/create_news_dialog.dart`)
| Key | Widget | Condition / Behavior |
|-----|--------|----------------------|
| `Key('organizer_action_publish_news')` | `KickPulseButton` | Botón en "Acciones Rápidas" del Panel del Organizador (`/panel`). Abre `CreateNewsDialog` con la lista de torneos editables (`status != TournamentStatus.finished`). |
| `Key('create_news_tournament_dropdown')` | `DropdownButtonFormField<String>` | Desplegable de competición dentro de `CreateNewsDialog` cuando se proveen `availableTournaments`. |
| `Key('create_news_title_field')` | `TextFormField` | Campo de título ($3\text{–}120$ caracteres). |
| `Key('create_news_category_dropdown')` | `DropdownButtonFormField<TournamentNewsCategory>` | Selector de categoría de la noticia. |
| `Key('create_news_body_field')` | `TextFormField` | Campo de cuerpo ($5\text{–}3000$ caracteres). |
| `Key('create_news_submit_button')` | `ElevatedButton` | Confirma y devuelve el `TournamentNewsItem` con el `tournamentId` seleccionado. |

---

## 2. Localization Contracts (`lib/l10n/app_es.arb`)

| Key | Spanish Value (`app_es.arb`) | Usage |
|-----|------------------------------|-------|
| `organizerActionPublishNews` | `"Publicar Noticia"` | Botón de acción rápida en `OrganizerPanelContent` |
| `organizerNoEditableTournamentsForNews` | `"No hay competiciones activas disponibles para publicar comunicados"` | `SnackBar` cuando no hay torneos editables |
| `newsTournamentField` | `"Competición"` | Etiqueta del desplegable de torneo en `CreateNewsDialog` |
| `newsFilterMenuTooltip` | `"Filtrar noticias"` | Tooltip del botón `more_vert` en el `AppBar` |
| `newsFilterSheetTitle` | `"Filtrar Noticias"` | Título de `NewsFilterBottomSheet` |
| `newsFilterTournamentSectionTitle` | `"Competición"` | Subtítulo de sección de torneos en `NewsFilterBottomSheet` |
| `newsFilterCategorySectionTitle` | `"Categoría de Comunicado"` | Subtítulo de sección de categorías en `NewsFilterBottomSheet` |
| `newsFilterResetButton` | `"Restablecer"` | Botón para limpiar filtro en `NewsFilterBottomSheet` |
| `newsActiveFilterClearSemantics` | `"Quitar filtro de categoría"` | Etiqueta semántica / tooltip para limpiar el chip activo |
| `newsFeedEmptyCategoryFilter` | `"No hay comunicados publicados en esta categoría para el torneo seleccionado."` | Estado vacío cuando el filtro de categoría no arroja resultados |
