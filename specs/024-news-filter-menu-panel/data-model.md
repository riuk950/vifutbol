# Data Model: Refactorización de Noticias (HU 15.1)

**Feature**: `024-news-filter-menu-panel`  
**Date**: 2026-11-09

---

## 1. Domain Entities (Existing & Reused)

### `TournamentNewsItem` (`lib/domain/entities/tournament_news_item.dart`)

Entidad inmutable de comunicado oficial publicado en una competición.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Identificador único inmutable del comunicado (`news-<timestamp>`). |
| `tournamentId` | `String` | Identificador del `ChampionshipTournament` al que pertenece la noticia. |
| `title` | `String` | Título del comunicado ($3\text{–}120$ caracteres). |
| `body` | `String` | Contenido del comunicado ($5\text{–}3000$ caracteres). |
| `category` | `TournamentNewsCategory` | Categoría del comunicado (`general`, `disciplinary`, `rescheduling`). |
| `publishedAt` | `DateTime` | Fecha y hora de publicación. |
| `authorUserId` | `String` | ID del usuario organizador que publicó el comunicado. |
| `authorName` | `String` | Nombre visible del autor o comité organizador. |
| `isPinned` | `bool` | Indica si el comunicado está fijado en la parte superior del feed. |

---

### `TournamentNewsCategory` (`lib/domain/entities/tournament_news_category.dart`)

Enumeración de categorías oficiales de comunicados:
- `general`: Avisos Generales
- `disciplinary`: Boletines Disciplinarios
- `rescheduling`: Reprogramación de Partidos
- *(Nota: `null` representa "Todas las categorías" en el estado de filtrado).*

---

### `ChampionshipTournament` (`lib/domain/entities/championship_tournament.dart`)

Entidad inmutable del torneo.
- Para la publicación de noticias desde `/panel`, son elegibles únicamente los torneos cuyo `status != TournamentStatus.finished` (`draft`, `openRegistration`, `inProgress`).
- Para la consulta y filtrado desde el menú de 3 puntos del `AppBar` (`NewsFilterBottomSheet`), son seleccionables todos los torneos del catálogo (incluyendo los finalizados en modo lectura histórica).

---

## 2. State Management & Reactive Synchronization

### `TournamentsCatalogState` (`tournamentsControllerProvider`)
- `tournaments`: Lista completa de competiciones registradas.
- `selectedTournamentId`: ID de la competición activa globalmente.
- **Acción desde `NewsFilterBottomSheet`**: `selectTournament(tournamentId)` cambia la competición activa; `NewsTabView` observa `tournamentsControllerProvider` y reconstruye `TournamentNewsFeedView(tournamentId: currentTournament.id)`, lo cual dispara `loadNews(currentTournament.id)`.

### `TournamentNewsState` (`tournamentNewsControllerProvider`)
- `news`: Lista de comunicados del torneo cargado ordenados con fijados (`isPinned`) primero y por `publishedAt` descendente.
- `categoryFilter`: `TournamentNewsCategory?` (`null` = Todas).
- `filteredNews`: Getter calculado que filtra `news` según `categoryFilter`.
- **Acciones**:
  - `setCategoryFilter(TournamentNewsCategory? category)`: Actualiza el filtro en tiempo real desde `NewsFilterBottomSheet` o lo limpia (`null`) desde `news_active_filter_chip`.
  - `publishNews({required TournamentNewsItem item, required UserRole userRole})`: Persiste la nueva noticia creada desde `OrganizerPanelContent` (`/panel`) tras validar rol `UserRole.organizer`.
