# Research & Architectural Decisions: Refactorización de Noticias (HU 15.1)

**Feature**: `024-news-filter-menu-panel`  
**Date**: 2026-11-09

---

## Decision 1: Reubicación de Creación de Noticias al Panel Administrativo (`/panel`)

- **Decision**:
  - Remover el botón `"Nueva Noticia"` (`Key('create_news_button')`) y el método `_onCreateNews` de `TournamentNewsFeedView` (`lib/presentation/news/tournament_news_feed_view.dart`), manteniendo el feed público de lectura completamente limpio para todos los roles (incluyendo `UserRole.organizer`).
  - Incorporar en `OrganizerPanelContent` (`lib/presentation/panel/widgets/organizer_panel_content.dart`) dentro de la sección de "Acciones Rápidas" un nuevo `KickPulseButton` con `Key('organizer_action_publish_news')` y etiqueta localizada `"Publicar Noticia"`.
  - Extender `CreateNewsDialog` (`lib/presentation/news/widgets/create_news_dialog.dart`) con un parámetro opcional `availableTournaments: List<ChampionshipTournament>?`. Cuando se provee (p. ej., al abrirse desde `/panel`), el diálogo renderiza un `DropdownButtonFormField<String>` (`Key('create_news_tournament_dropdown')`) en la parte superior del formulario con los torneos editables (`status != TournamentStatus.finished`), preseleccionando el `tournamentId` inicial. Si también se actualiza el torneo elegido, el `TournamentNewsItem` devuelto al confirmar tendrá el `tournamentId` seleccionado, y `OrganizerPanelContent` sincronizará el torneo activo y publicará la noticia mediante `tournamentNewsControllerProvider.notifier.publishNews`.
- **Rationale**:
  - Preserva retrocompatibilidad con cualquier llamada existente a `CreateNewsDialog.show(tournamentId: ...)` al tiempo que permite al organizador elegir el torneo destino en un único paso desde `/panel` sin pantallas intermedias.
  - Si no existen torneos editables (0 torneos o todos en estado `finished`), pulsar `"Publicar Noticia"` muestra un `SnackBar` informativo localizado indicando que no hay competiciones activas disponibles para publicar comunicados.
- **Alternatives Considered**:
  - *Abrir un Bottom Sheet previo para elegir torneo antes de abrir `CreateNewsDialog`*: Descartado en la clarificación Q3 porque añade un paso modal extra innecesario.
  - *Mantener el botón de crear noticia oculto para aficionados pero visible para organizadores en el feed*: Descartado porque contradice directamente el objetivo central de la HU 15.1 de trasladar las herramientas de publicación al Panel Administrativo.

---

## Decision 2: Menú Contextual de 3 Puntos (`more_vert`) en `AppShellScreen` y Hoja Modal de Filtros

- **Decision**:
  - En `AppShellScreen` (`lib/presentation/shell/app_shell_screen.dart`), dentro de `AppBar.actions`, evaluar `final isNewsSection = shellState.activeSection == AppShellSection.news;`.
  - Cuando `isNewsSection == true`, renderizar un `IconButton` con `Key('app_bar_news_filter_action')`, icono `Icons.more_vert` y `tooltip: l10n.newsFilterMenuTooltip` junto a `FanAlertsBellAction`.
  - Al pulsarlo, invocar `NewsFilterBottomSheet.show(context)` (`lib/presentation/news/widgets/news_filter_bottom_sheet.dart`), un `ConsumerWidget` presentado mediante `showModalBottomSheet` con `Key('news_filter_bottom_sheet')`, `isScrollControlled: true` y estética *KickPulse* (`KickPulseColors.surfaceElevated`).
  - Dentro de `NewsFilterBottomSheet`:
    1. **Cabecera**: Título `"Filtrar Noticias"`, botón de restablecer (`Key('news_filter_reset_button')`) y botón de cierre (`Key('news_filter_close_button')`).
    2. **Sección Competición**: Lista de `ChoiceChip` (`Wrap`) con `Key('news_filter_tournament_chip_${tournament.id}')` para cada torneo en `tournamentsControllerProvider`. Al tocar un chip, invoca `tournamentsControllerProvider.notifier.selectTournament(tournament.id)` de inmediato en tiempo real sin cerrar el modal.
    3. **Sección Categoría de Comunicado**: Lista de `ChoiceChip` (`Wrap`) con `Key('news_filter_category_chip_all')` y `Key('news_filter_category_chip_${category.name}')` para `TournamentNewsCategory.values`. Al tocar un chip, invoca `tournamentNewsControllerProvider.notifier.setCategoryFilter(category)` de inmediato en tiempo real sin cerrar el modal.
- **Rationale**:
  - Cumple con las decisiones Q1 y Q3 de clarificación: hoja modal inferior ergonómica que permite combinar selección de torneo y categoría en una misma sesión con actualización reactiva instantánea.
- **Alternatives Considered**:
  - *`PopupMenuButton` clásico*: Descartado en Q1 porque dificulta combinar dos dimensiones de filtrado (torneo + categoría) en pantallas móviles compactas.

---

## Decision 3: Limpieza de Barras Horizontales en el Feed e Indicador de Filtro Activo

- **Decision**:
  - En `NewsTabView` (`lib/presentation/shell/tabs/news_tab_view.dart`), retirar la barra horizontal `news_tournament_selector` de `ChoiceChip`s y mostrar de forma permanente bajo la fila del título `"Noticias"` el subtítulo del torneo activo (`Key('news_active_tournament_subtitle')`).
  - Cuando `newsState.categoryFilter != null`, renderizar bajo el subtítulo del torneo un chip compacto e interactivo (`Key('news_active_filter_chip')`) que muestra la etiqueta localizada de la categoría activa y un botón/icono de limpieza (`onDeleted` / `onTap`) que invoca `ref.read(tournamentNewsControllerProvider.notifier).setCategoryFilter(null)`.
  - En `TournamentNewsFeedView` (`lib/presentation/news/tournament_news_feed_view.dart`), retirar la fila superior que contenía `TournamentNewsFilterBar` y `create_news_button`, dejando únicamente la insignia de solo lectura histórica (`news_readonly_badge`, si el torneo está finalizado) y el listado de comunicados (o un estado vacío claro con botón para limpiar filtro si `categoryFilter != null` y `filteredNews.isEmpty`).
- **Rationale**:
  - Cumple con la clarificación Q2: elimina las dos barras horizontales del cuerpo del feed para maximizar el área de lectura vertical, conservando siempre visible el nombre del torneo activo y el chip removible cuando hay una categoría filtrada.
- **Alternatives Considered**:
  - *Conservar los chips de categoría en el feed además del modal*: Descartado en Q2 por redundancia visual.
